import 'dart:core';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'yast_parse.dart' as yastParse;
import 'yast_response.dart';
import 'yast_http.dart' as yasthttp;
import 'constants.dart';
import 'saved_app_status.dart';
import 'Model/project.dart';
import 'Model/record.dart';

class YastApi {
  static YastApi theSingleton;

  static const String _timeFromParam = "timeFrom";
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
          hashPw = yr.body
              .findAllElements("hash")
              .first
              .text;
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
  Future<Map<String, Record>> yastRetrieveRecords(String username,
      String hashPwd, SavedAppStatus theSavedAppStatus) async {
    debugPrint('==========yastRetrieveRcords');

    String optParams = "<" + _timeFromParam + ">today</" + _timeFromParam + ">";
    YastResponse yr = await _yastSendRetrieveRequest(
        username, hashPwd, _data_getRecords, optParams)
        .timeout(Duration(seconds: Constants.HTTP_TIMEOUT));

    Map<String, dynamic> retval;
    if (yr != null) {
      if (yr.status != YastResponse.yastSuccess) {
        debugPrint("Retrieve records failed");
        debugPrint(yr.statusString);
        return null;
      } else {
        try {
          retval = await yastParse.getRecordsFrom(yr.body);
          await yastParse.putRecordsInDatabase(retval);
        } catch (e) {
          debugPrint("exception storing? records");
          throw (e);
        }
      }
      return retval;
    } else {
      debugPrint("yastResponse is null $yr");
      return null;
    }
  } // yastRetrieveRecords

  // create copies of records going out into the future.
  // plausible fakes.
  // These must go into the database and be entered using the yast api
  Map<String, Record> createFutureRecords(SavedAppStatus theSavedAppStatus) {
    DateTime targetDay = DateTime.now();
    Map<String, Record> retval = new Map<String, Record>();
    theSavedAppStatus.records.forEach((String key, Record value) {
      DateTime start = theSavedAppStatus.getRecordStartTime(key);
      DateTime end = theSavedAppStatus.getRecordEndTime(key);
      Duration delta = targetDay.difference(start) ;
      Record newRec = Record.clone(value);
      newRec.startTime = newRec.startTime.add(delta);
      newRec.endTime = newRec.endTime.add(delta);
      retval[newRec.id] = newRec;
    });
    return retval;
  } // create fake records

  /// Form a retrieve request and post it
  /// Create a batch, do the batch in batches of 500
  yastStoreNewRecords(SavedAppStatus theSavedAppStatus,
      Map<String, Record> newRecords) async {
    if ((newRecords == null) || (newRecords.isEmpty)) {
      return;
    }
    String optParams = "<" + _timeFromParam + ">today</" + _timeFromParam + ">";
    YastResponse yr = await _yastSendStoreRequest(
        theSavedAppStatus.getUsername(),
        theSavedAppStatus.hashPasswd,
        _data_add, optParams)
        .timeout(Duration(seconds: Constants.HTTP_TIMEOUT));
  }

  // DON'T DO THIS until you're sure the records created in that Map and the database
  //  are correct.
  Future<YastResponse> _yastSendStoreRequest(String username, String hashPwd,
      String httpRequestString,
      [String optionalParams]) async {
    debugPrint('++++_yastSendStoreRequest $httpRequestString');
  }

  /// Form a retrieve request and post it
  Future<YastResponse> _yastSendRetrieveRequest(String username, String hashPwd,
      String httpRequestString,
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
