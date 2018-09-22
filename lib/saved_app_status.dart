import 'package:shared_preferences/shared_preferences.dart';

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

  SavedAppStatus.dummy()  {
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
  Map<String, dynamic> records;

  /// Map Project ID number (as string) to Project Name.
  Map<String, String> projectIdToName = {};

  String getProjectNameFromId(String id) {
    if (projectIdToName == null) {
      projectIdToName = {};
    } else {
      return projectIdToName[id];
    }
  }

  /// Map Folder ID number (as string) to Folder Name.
  Map<String, String> folderIdToName = {};

  String getFolderNameFromId(String id) {
    if (folderIdToName == null) {
      folderIdToName = {};
    } else {
      return folderIdToName[id];
    }
  }

  void _getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.setUsername(prefs.getString('username'));
  }

  void _savePreferences(String newUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
  }
}
