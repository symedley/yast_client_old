import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'Model/project.dart';
import 'Model/record.dart';
import 'constants.dart';
import 'package:intl/intl.dart';

enum StatusOfApi {
  ApiOk,
  ApiLoginNeeded,
  ApiLoginFailure,
  ApiUnknownFailure,
}

const String logged_in = "Logged in.";
const String api_ok_description = "Response: OK";
const String api_login_needed_description = "Login needed";
const String api_login_failure_description = "Login Failure";
const String api_unknown_failure_description = "Unknown Failure";

// SavedAppStatus class holds onto the top level basic status and info
class SavedAppStatus {
  SavedAppStatus() {
    _getSharedPrefs();
  }

  SavedAppStatus.dummy() {
    SavedAppStatus retval = new SavedAppStatus();
    retval.sttOfApi = StatusOfApi.ApiOk;
    retval.setUsername('noname');
    retval.message = 'message in the status';
    retval.hashPasswd = 'bogushashpwd';
  }

  String _username = "";

  String getUsername() => this._username;

  void setUsername(String newUsername) {
    _username = newUsername;
    _savePreferences(newUsername);
  }

  StatusOfApi sttOfApi = StatusOfApi.ApiLoginNeeded;
  bool showValidationError = false;
  int counterApiCallsCompleted = 0;
  int counterApiCallsStarted = 0;

  String message;

  String hashPasswd;

  // records will be a Map of ID string to Record object
  Map<String, Record> records = {};
  Map<DateTime, Record> startTimeToRecord = {};

  DateTime getRecordEndTime(String id) {
    try {
      return records[id].endTime;
    } on Null {
      return null;
    } on NullThrownError {
      return null;
    }
  }

  DateTime getRecordStartTime(String id) {
    try {
      return records[id].startTime;
    } on Null {
      return null;
    } on NullThrownError {
      return null;
    }
  }

  Duration durationOfRecord(String id) {
    return this.getRecordEndTime(id).difference(this.getRecordStartTime(id));
  }

  double howMuchOf24HoursForRecord(String id) {
    return min((durationOfRecord(id).inMinutes + 0.0) / 60.0, 24.0);
  }

  double howMuchOf6HoursForRecord(String id) {
    return min((durationOfRecord(id).inMinutes + 0.0) / 60.0, 6.0);
  }

  /// Map Project ID number (as string) to Project Name.
  Map<String, Project> projects = {};

  String getProjectNameFromId(String id) {
    if (projects == null) {
      projects = {};
    }
    try {
      return projects[id].name;
    } catch (e) {
      debugPrint('$e');
      return "----";
    }
  }

  String getProjectColorStringFromId(String id) {
    if (projects == null) {
      projects = {};
    }
    try {
      return projects[id].primaryColor;
    } catch (e) {
      debugPrint('$e');
      return Constants.COLORSTRING;
    }
  }

  /// Map Folder ID number (as string) to Folder Name.
  Map<String, String> folderIdToName = {};

  String getFolderNameFromId(String id) {
    if (folderIdToName == null) {
      folderIdToName = {};
    }
    try {
      return folderIdToName[id];
    } catch (e) {
      print(e);
      return '<folder>';
    }
  }

  void _getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.setUsername(prefs.getString('username'));
    try {
          String date = (prefs.getString('preferredDate'));
          if (date!= null) this.setPreferredDate( DateTime.parse(date));
    } on FormatException catch (e) {
      debugPrint(" Failed to get date from shared preferences. $e");
    }
  }

  void _savePreferences(String newUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
    if (this._preferredDate != null) await prefs.setString('preferredDate', this._preferredDate.toString());
  }

  DateTime _preferredDate;

  DateTime getPreferredDate() => _preferredDate;

  setPreferredDate(DateTime newDate) {
    _preferredDate = newDate;
    _savePreferences(this._username);
  }
}
