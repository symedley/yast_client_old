import 'dart:core';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'yast_parse.dart' as yastParse;
import 'yast_response.dart';
import 'yast_http.dart' as yasthttp;
import 'constants.dart';
import 'saved_app_status.dart';
import 'Model/project.dart';
import 'Model/record.dart';
import 'Model/yast_db.dart';
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
  static const String _data_delete = "data.delete";

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
      String username, String hashPwd, SavedAppStatus theSavedAppStatus,
      {startTimeStr: String, endTimeStr: String}) async {
    debugPrint('==========yastRetrieveRcords');

    DateTime fromDate;
    String fromDateStr;
    if (startTimeStr == null) {
      fromDate = theSavedAppStatus.currentDate;
      if (fromDate == null) {
        DateTime now = new DateTime.now();
        fromDate = new DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 1));
        fromDateStr = localDateTimeToYastDate(fromDate);
      }
    } else {
      fromDateStr = startTimeStr;
      fromDate = yastTimetoLocalDateTime(startTimeStr);
    }

    String toDateStr;
    if (endTimeStr == null) {
      DateTime toTime;
      toTime = new DateTime(fromDate.year, fromDate.month, fromDate.day)
          .add(Duration(days: 5));
      toDateStr = localDateTimeToYastDate(toTime);
    } else {
      toDateStr = endTimeStr;
    }

    String optParams =
        "<" + _timeFromParam + ">$fromDateStr</" + _timeFromParam + ">";
    optParams += "<" + _timeToParam + ">$toDateStr</" + _timeToParam + ">";

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
//        Map<String, Record> newFakeRecords =
//            await (debug.createFutureRecords(retval));
//        await yastStoreNewRecords(theSavedAppStatus, newFakeRecords);
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

  /// Outside classes call this to delete a range of time records
  /// xml format: TODO
  /// request req="data.delete" id="133">
  //    <objects>
  //        <record>
  //            <id>8282</id>
  //        </record>
  //        <group>
  //            <id>132</id>
  //        </group>
  //    <objects>
  //</response>
  Future<YastResponse> yastDeleteRecords(
      //      String username,
      //      String hashPwd,
      SavedAppStatus theSavedStatus,
      DateTime fromDate,
      DateTime toDate) async {
    debugPrint('==========yastDeleteRcords');

    String fromDateString = localDateTimeToYastDate(
        DateTime(fromDate.year, fromDate.month, fromDate.day));
    DateTime newToDate =
        DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 0);
    String toDateString = localDateTimeToYastDate(newToDate);

    // This retrieves from yast and stores in database,
    // in case this range of records hasn't been retrieved yet.
    // That way, we can pull the ids from the database.
    Map<String, Record> recs = await yastRetrieveRecords(
        theSavedStatus.getUsername(),
        theSavedStatus.hashPasswd,
        theSavedStatus,
        startTimeStr: fromDateString,
        endTimeStr: toDateString);

    Query query = Firestore.instance
        .collection(YastDb.DbRecordsTableName)
        .where('startTime', isGreaterThanOrEqualTo: fromDateString)
        .where('startTime', isLessThanOrEqualTo: toDateString);
    QuerySnapshot qss = await query.getDocuments();
    List<String> ids = new List();
    qss.documents.forEach((docSnap) {
      docSnap.data.keys;
      int startchar = 1 + docSnap.reference.path.indexOf('/', 0);
      String id = docSnap.reference.path
          .substring(startchar, docSnap.reference.path.length);
      ids.add(id);
      debugPrint(" delete record start time: $docSnap.data");
    });

    debugPrint('ids to delete: $ids');
    YastResponse yr = await _yastSendDeleteRequest(theSavedStatus.getUsername(),
            theSavedStatus.hashPasswd, _data_delete, ids)
        .timeout(Duration(seconds: Constants.HTTP_TIMEOUT));
    theSavedStatus.message = 'Attempt to delete ${ids.length} records, response ${yr.statusString}';
    await yastParse.selectivelyDeleteFromCollection(
        YastDb.DbRecordsTableName, ids.toSet());
    theSavedStatus.currentRecords.removeWhere((String s, Record rec) {
      var result = ((rec.startTimeStr.compareTo(fromDateString) >= 0) &&
          (rec.startTimeStr.compareTo(toDateString) <= 0));
      return result;
    });

    debugPrint(
        "yastResponse for yastDeleteRecords: ${yr.status} ${yr.statusString}");
    return yr;
  } // yastDeleteRecords

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
      debugPrint('storing rec: id:${record.id} comment:${record.comment}');
      var builder = new xml.XmlBuilder();
      xml.XmlNode xmlNode = record.toXml();
      builder.element('objects', nest: xmlNode.children.last);
      String optParams = builder.build().toXmlString();
      yr = await _yastSendStoreRequest(theSavedAppStatus.getUsername(),
              theSavedAppStatus.hashPasswd, _data_add, optParams)
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
    if (_basicCheck(username, hashPwd) == false) return null;

//    if ((username == null) || (username.runtimeType != String)) {
//      debugPrint("Attempt to retrieve something when there is no username!");
//      debugPrint("username = $username");
//      return null;
//    }
//    if ((hashPwd == null) || (hashPwd.runtimeType != String)) {
//      debugPrint(
//          "Attempt to retrieve something when there is no hash password!");
//      debugPrint("hashPwd = $hashPwd");
//      return null;
//    }
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

  /// Must put each record id in an xml block and all of that in an <object> block
  Future<YastResponse> _yastSendDeleteRequest(String username, String hashPwd,
      String httpRequestString, List<String> ids) async {
    var builder = new xml.XmlBuilder();
//    builder.processing('xml', 'version="1.0"');
//    xml.XmlNode xmlNode = record.toXmlForDeletion();
    ids.forEach((id) {
      builder.element('record', nest: () {
        builder.element('id', nest: () {
          builder.text(id);
        });
      });
    });
    var builder2 = new xml.XmlBuilder();
    xml.XmlNode xmlNode = builder.build();
    builder2.element('objects', nest: xmlNode.children);
    String optParams = builder2.build().toXmlString();
    String xmlToSend = '<request req="' +
        httpRequestString +
        '" id="${sendCounter.toString()}">' +
        '<user><![CDATA[$username]]></user>' +
        '<hash><![CDATA[$hashPwd]]></hash>' +
        optParams +
        _close_request_string;
    sendCounter++;
    return await yasthttp.sendToYastApi(xmlToSend);
  } //_yastSendDeleteRequest

  bool _basicCheck(String username, String hashPwd) {
    if ((username == null) || (username.runtimeType != String)) {
      debugPrint("Attempt to retrieve something when there is no username!");
      debugPrint("username = $username");
      return false;
    }
    if ((hashPwd == null) || (hashPwd.runtimeType != String)) {
      debugPrint(
          "Attempt to retrieve something when there is no hash password!");
      debugPrint("hashPwd = $hashPwd");
      return false;
    }
    return true;
  }
}
