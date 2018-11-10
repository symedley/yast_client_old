import 'dart:core';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'yast_parse.dart' as yastParse;
import 'yast_response.dart';
import 'yast_http.dart' as yasthttp;
import 'constants.dart';
import 'saved_app_status.dart';
import 'Model/project.dart';
import 'Model/record.dart';
import 'utilities.dart';
import 'debug_create_future_records.dart' as debug;

class YastApi {
  static YastApi theSingleton;

  static const int YASTRECORDWRITELIMIT = 10; // 10 is a guess

  static const String _timeFromParam = "timeFrom";
  static const String _timeToParam = "timeTo";
  static const String _data_getRecords = "data.getRecords";
  static const String _data_getFolders = "data.getFolders";
  static const String _data_getProjects = "data.getProjects";

  static const String _data_add = "data.add";

  int sendCounter;
  int responseCounter;

  YastApi() {
    sendCounter = 0;
    responseCounter = 0;
  }

  static const String _close_request_string = '</request>';

  /// the singleton. Will we really only need one of these ?
  /// will there be re-entrant issues?
  static YastApi getApi() {
    if (theSingleton == null) {
      theSingleton = new YastApi();
    }
    return theSingleton;
  }

  /// log in user and get a hash to use in subsequent requests
  Future<String> yastLogin(String username, String pw) async {
    String xmlToLogin = '''
      <user>
        <![CDATA[$username]]>
      </user>
      <password>
        <![CDATA[$pw]]>
      </password>''';
    xmlToLogin = '<request req="auth.login" id="${sendCounter.toString()}">' +
        xmlToLogin +
        _close_request_string;
    YastResponse yr = await yasthttp.sendToYastApi(xmlToLogin);

    String hashPw;
    if (yr != null) {
      if (yr.status == YastResponse.yastLoginfailure) {
        hashPw = null;
      } else {
        try {
          hashPw = yr.body.findAllElements("hash").first.text;
        } catch (e) {
          debugPrint("exception logging in and getting hash");
          return null;
        }
      }
      return hashPw;
    } else {
      debugPrint("yastResponse is null $yr");
      return null;
    }
  }

  /// Outside classes call this to retrieve all the project categories
  Future<Map<String, dynamic>> yastRetrieveProjects(
      SavedAppStatus theSavedStatus) async {
    Map<String, Project> mapIdToProjects;
    await _yastSendRetrieveRequest(theSavedStatus.getUsername(),
            theSavedStatus.hashPasswd, _data_getProjects)
        .then((yr) async {
      if (yr != null) {
        if (yr.status != YastResponse.yastSuccess) {
          debugPrint("Retrieve projects failed");
          debugPrint(yr.statusString);
          return null;
        } else {
          try {
            mapIdToProjects = await yastParse.getProjectsFrom(yr.body);
          } catch (e) {
            debugPrint("exception retrieving projects");
            debugPrint(e);
            return null;
          }
        }
      } else {
        debugPrint("yastResponse is null $yr");
        return null;
      }
    });
    return mapIdToProjects;
  } // yastRetrieveProjects

  /// Outside classes call this to retrieve all the folders
  Future<Map<String, String>> yastRetrieveFolders(
      SavedAppStatus theSavedStatus) async {
    Map<String, String> mapIdToFolders;
    await _yastSendRetrieveRequest(theSavedStatus.getUsername(),
            theSavedStatus.hashPasswd, _data_getFolders)
        .then((yr) async {
      if (yr != null) {
        if (yr.status != YastResponse.yastSuccess) {
          debugPrint("Retrieve Folders failed");
          debugPrint(yr.statusString);
          return null;
        } else {
          try {
            mapIdToFolders = await yastParse.getFoldersFrom(yr.body);
          } catch (e) {
            debugPrint("exception retrieving projects");
            return null;
          }
        }
      } else {
        debugPrint("yastResponse is null $yr");
        return null;
      }
    });
    return mapIdToFolders;
  } // yastRetrieveProjects

  /// Outside classes call this to retrieve all the records
  Future<Map<String, Record>> yastRetrieveRecords(
      String username, String hashPwd, SavedAppStatus theSavedAppStatus) async {
    debugPrint('==========yastRetrieveRcords');
    DateTime prefDate = theSavedAppStatus.currentDate;
    if (prefDate == null) {
      DateTime now = new DateTime.now();
      prefDate = new DateTime(now.year, now.month, now.day).subtract(Duration(days:1));
    }
    String retrieveDateStr = dateTimeToYastDate(prefDate);

    String optParams =
        "<" + _timeFromParam + ">$retrieveDateStr</" + _timeFromParam + ">";
    DateTime toTime = new DateTime(
         prefDate.year,
         prefDate.month,
         prefDate.day).add(Duration(days: 5));

    String toDate = dateTimeToYastDate(toTime);
    optParams += "<" + _timeToParam + ">$toDate</" + _timeToParam + ">";
    YastResponse yr = await _yastSendRetrieveRequest(
            username, hashPwd, _data_getRecords, optParams)
        .timeout(Duration(seconds: Constants.HTTP_TIMEOUT));

    Map<String, Record> retval;
    if (yr != null) {
      if (yr.status != YastResponse.yastSuccess) {
        debugPrint("Retrieve records failed");
        debugPrint(yr.statusString);
        return null;
      } else {
//        try {
        retval = await yastParse.getRecordsFrom(yr.body);
        // temporary: create some fake records, duplicating stuff from oct 24.
        await yastParse.putRecordsInDatabase(retval);
        Map<String, Record> newFakeRecords =
            await (debug.createFutureRecords(retval));
        await yastStoreNewRecords(theSavedAppStatus, newFakeRecords);
//        } catch (e) {
//          debugPrint("exception retrieving records");
//          throw (e);
//        }
      }
      return retval;
    } else {
      debugPrint("yastResponse is null $yr");
      return null;
    }
  } // yastRetrieveRecords

  /// Send a write-data message back to yast: store these records
  /// TODO there's a limit on the number of records you can do at once,
  /// so chunk this into smaller pieces. For now, i just won't store that
  /// many all at once.
  Future<YastResponse> yastStoreNewRecords(
      SavedAppStatus theSavedAppStatus, Map<String, Record> newRecords) async {
    int count = 0;
    YastResponse yr;
    if ((newRecords == null) || (newRecords.isEmpty)) {
      return null;
    }
    newRecords.forEach((k, Record record) async {
//      String optParams = '''
//      <objects>
//      <record>
//     				<project>25004070</project>
//				<variables>
//						<v>record.</v>
//						<v>150611702</v>
//						<v>some comment</v>
//						<v>0</v>
//				</variables>
//				<flags>0</flags>
//				 </record></objects> ''';
      debugPrint('storing rec: id:${record.id} comment:${record.comment}');
      var builder = new xml.XmlBuilder();
      xml.XmlNode xmlNode = record.toXml();
      builder.element('objects', nest: xmlNode.children.last);
      String optParams = builder.build().toXmlString();
       yr = await _yastSendStoreRequest(
              theSavedAppStatus.getUsername(),
              theSavedAppStatus.hashPasswd,
              _data_add,
              optParams)
          .timeout(Duration(seconds: Constants.HTTP_TIMEOUT));
//      debugPrint(yr.toString());
    });
    return yr;
  }

  // DON'T DO THIS until you're sure the records created in that Map and the database
  //  are correct.
  Future<YastResponse> _yastSendStoreRequest(
      String username, String hashPwd, String httpRequestString,
      [String optionalParams]) async {
    if ((username == null) || (username.runtimeType != String)) {
      debugPrint("Attempt to retrieve something when there is no username!");
      debugPrint("username = $username");
      return null;
    }
    if ((hashPwd == null) || (hashPwd.runtimeType != String)) {
      debugPrint(
          "Attempt to retrieve something when there is no hash password!");
      debugPrint("hashPwd = $hashPwd");
      return null;
    }
    optionalParams ??= "";
    String xmlToSend = '<request req="' +
        httpRequestString +
        //_data_getProjects +
        '" id="${sendCounter.toString()}">' +
        '<user><![CDATA[$username]]></user>' +
        '<hash><![CDATA[$hashPwd]]></hash>' +
        optionalParams +
        _close_request_string;
    sendCounter++;
    return await yasthttp.sendToYastApi(xmlToSend);
  }

  /// Form a retrieve request and post it
  Future<YastResponse> _yastSendRetrieveRequest(
      String username, String hashPwd, String httpRequestString,
      [String optionalParams]) async {
    if ((username == null) || (username.runtimeType != String)) {
      debugPrint("Attempt to retrieve something when there is no username!");
      debugPrint("username = $username");
      return null;
    }
    if ((hashPwd == null) || (hashPwd.runtimeType != String)) {
      debugPrint(
          "Attempt to retrieve something when there is no hash password!");
      debugPrint("hashPwd = $hashPwd");
      return null;
    }
    optionalParams ??= "";
    String xmlToSend = '<request req="' +
        httpRequestString +
        //_data_getProjects +
        '" id="${sendCounter.toString()}">' +
        '<user><![CDATA[$username]]></user>' +
        '<hash><![CDATA[$hashPwd]]></hash>' +
        optionalParams +
        _close_request_string;
    sendCounter++;
    return await yasthttp.sendToYastApi(xmlToSend);
  } //_yastSendRetrieveRequest

}
