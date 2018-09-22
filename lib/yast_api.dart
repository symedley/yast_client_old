import 'package:xml/xml.dart' as xml;
import 'YastResonse.dart';
import 'dart:async';
import 'yast_parse.dart';
import 'YastHttp.dart' as yasthttp;
import 'package:flutter/foundation.dart';

class YastApi {
  static YastApi theSingleton;

  int sendCounter;
  int responseCounter;
  String _hashPassword;

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

    if (yr != null) {
      if (yr.status == YastResponse.yastLoginfailure) {
        _hashPassword = null;
      } else {
        try {
          _hashPassword = yr.body.findAllElements("hash").first.text;
        } catch (e) {
          debugPrint("exception logging in and getting hash");
          return null;
        }
      }
      return _hashPassword;
    } else {
      debugPrint("yastResponse is null $yr");
      return null;
    }
  }

  /// Outside classes call this to retrieve all the project categories
  Future<Map<String, String>> yastRetrieveProjects(String hashPwd) async {}

  /// Outside classes call this to retrieve all the project categories
  Future<Map<String, String>> yastRetrieveFolders(String hashPwd) async {}

  /// Outside classes call this to retrieve all the project categories
  Future<Map<String, dynamic>> yastRetrieveRecords(String hashPwd) async {}

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

  /// Brute force delete all documents in a collection of the given name.
  /// A utility function.
  Future<void> _deleteAllDocsInCollection(String collectionName) async {}

  Future<void> _putRecordsInDatabase(Map<String, dynamic> recs) async {}
}
