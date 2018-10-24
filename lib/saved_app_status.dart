import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'Model/project.dart';
import 'Model/record.dart';
import 'constants.dart';

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
    currentDate = DateTime.now();
  }

  /// used for the developer tools to render a view without real data
  SavedAppStatus.dummy()  {
    SavedAppStatus retval = new SavedAppStatus();
    retval.sttOfApi = StatusOfApi.ApiOk;
    retval.setUsername('noname');
    retval.message = 'message in the status';
    retval.hashPasswd = 'bogushashpwd';
  }

  /// Stored Username
  String _username = "";
  String getUsername() => this._username;
  void setUsername(String newUsername) {
    _username = newUsername;
    _savePreferences(newUsername);
  }

  /// Keep track of which day the user is currently looking at
  DateTime currentDate;

  /// Status (logged in, error, whatever)
  /// and the message that goes with it.
  StatusOfApi sttOfApi = StatusOfApi.ApiLoginNeeded;
  bool showValidationError = false;
  int counterApiCallsCompleted = 0;
  int counterApiCallsStarted = 0;
  String message;

  /// Hashed password, as sent back by the yast API when logging in
  String hashPasswd;

  /// Records = timeline records. Map IdString -> Record object
  Map<String, Record> records = {};
  /// Records indexed by their start time, so you can retrieve them in order
  Map<DateTime, Record> startTimeToRecord = {};

  /// Record Times: look up starttime and endtime by recordId
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

  /// Records: find record by id and calculate the duration of that timeline record
  Duration durationOfRecord(String id) {
    return this.getRecordEndTime(id).difference(this.getRecordStartTime(id));
  }

  /// Record: duration in # hours and fraction of hours, looked up by id
  /// For purposes of displaying in a human friendly way,
  double howMuchOf24HoursForRecord(String id) {
    return min((durationOfRecord(id).inMinutes + 0.0) / 60.0, 24.0 );
  }

  /// Record: duration in # hours and fraction of hours, but cap the max displayed at 6.0
  /// so it fits in the display as a bar graph. 6 hours or more is just "a long time"
  double howMuchOf6HoursForRecord(String id) {
    return min((durationOfRecord(id).inMinutes + 0.0)/60.0, 6.0 );
  }

  /// Projects : look up by id
  /// Look up name or color and don't barf if it's not found.
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

  /// Foldernames, by id
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

  /// Shared preferences to store the last used username for the login screen
  void _getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.setUsername(prefs.getString('username'));
  }
  void _savePreferences(String newUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
  }
}
