import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'saved_app_status.dart';
import 'login_page.dart';
import 'yast_api.dart';
import 'main.dart';
import 'display_login_status.dart';
import 'utilities.dart' as utilities;
import 'constants.dart';
import 'Model/database_stuff.dart';
import 'Model/project.dart';
import 'Model/record.dart';

class HomePageRoute extends StatefulWidget {
  static String tag = "home-page-route";

  HomePageRoute({Key key, this.title, this.theSavedStatus}) : super(key: key);

  final String title;
  final SavedAppStatus theSavedStatus;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<HomePageRoute> {
  final _errorColor = Colors.red[800];

  void _loginButtonPressed() async {
    debugPrint('==========_loginButtonPressed');

    // Used to retrieve the current value of the TextField
    await _loginToYast();
    // If login successful, then start to retrieve categories now, too
    if (widget.theSavedStatus.sttOfApi == StatusOfApi.ApiOk) {
      await _retrieveAllProjects().then((_) {
        _retrieveAllFolders().then((_) {
          _retrieveRecords();
        });
      });
    }
    if (this.mounted == true) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Use this a s shortcut to test whatever feature I'm
  /// currently working on.
  String _sDoSomething = 'retrieve records';

  void _fabButtonPressed() async {
    debugPrint('============================');
    debugPrint('==========_fabButtonPressed');

    await _retrieveAllProjects().then((_) {
      _retrieveAllFolders().then((_) {
        _retrieveRecords();
      });
    });
    if (this.mounted == true) setState(() {});
    debugPrint('==========END _fabButtonPressed');
  }

  Future<void> _retrieveAllFolders() async {
    debugPrint('==========_retrieveAllFolders');

    YastApi api = YastApi.getApi();
    widget.theSavedStatus.counterApiCallsStarted++;

    Map<String, String> folderNameMap =
        await api.yastRetrieveFolders(widget.theSavedStatus);
    widget.theSavedStatus.folderIdToName = folderNameMap;
    widget.theSavedStatus.counterApiCallsCompleted++;
    debugPrint('==========END _retrieveAllFolders');
  }

  Future<void> _retrieveAllProjects() async {
    debugPrint('==========_retrieveAllProjects');

    YastApi api = YastApi.getApi();
    widget.theSavedStatus.counterApiCallsStarted++;
    Map<String, Project> projectMap =
        await api.yastRetrieveProjects(widget.theSavedStatus);
//    widget.theSavedStatus.projectIdToName = projectMap;
    widget.theSavedStatus.addAllProjects(projectMap);
    widget.theSavedStatus.projects = projectMap;
    widget.theSavedStatus.counterApiCallsCompleted++;
  }

  /// retrieve Records AND CREATE TIMELINE LIST from the yast API.
  /// Build a List of the records for aSavedState
  /// Also build a TimelineModel list to store in aSavedState
  Future<void> _retrieveRecords() async {
    debugPrint('==========_retrieveRecords');

    YastApi api = YastApi.getApi();
    widget.theSavedStatus.counterApiCallsStarted++;
    Map<String, Record> recs = await api.yastRetrieveRecords(
        widget.theSavedStatus.getUsername(),
        widget.theSavedStatus.hashPasswd,
        widget.theSavedStatus);
    if (recs != null) {
      widget.theSavedStatus.currentRecords = recs;
    } else {
      // get the records from the dtabaae
    }
    widget.theSavedStatus.counterApiCallsCompleted++;

    // TODO if the user is now looking at another tab, such as Timeline,
    // how to trigger that to update?
  }

  void _resetButtonPressed() {
    debugPrint('==========_resetButtonPressed');

    setState(() {
      widget.theSavedStatus.message = "State just reset";
      widget.theSavedStatus.sttOfApi = StatusOfApi.ApiLoginNeeded;
      widget.theSavedStatus.hashPasswd = null;
      widget.theSavedStatus.showValidationError = false;
    });
  }

  void _logoutButtonPressed() {
    debugPrint('==========_logoutButtonPressed');
    setState(() {
      widget.theSavedStatus.message = "Logged out.";
      widget.theSavedStatus.sttOfApi = StatusOfApi.ApiLoginNeeded;
      widget.theSavedStatus.hashPasswd = null;
      widget.theSavedStatus.showValidationError = false;
    });
  }

  void _deleteRecordsButtonPressed() async {
    debugPrint('==========_deleteDatesButtonPressed');
    YastApi api = YastApi.getApi();
    widget.theSavedStatus.counterApiCallsStarted++;
    await api.yastDeleteRecords(widget.theSavedStatus, _fromDateDelete, _toDateDelete);
//    widget.theSavedStatus.projectIdToName = projectMap;
    // TODO remove those from the local cache of records (map)
  }

  /// Use the YastApi to send an async message
  /// to the Yast.com API.
  Future<void> _loginToYast() async {
    debugPrint('==========_loginToYast');

    widget.theSavedStatus.counterApiCallsStarted++;

    var hashPasswd = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
                theSavedState: widget.theSavedStatus,
              ),
        ));

    widget.theSavedStatus.counterApiCallsCompleted++;

    if (hashPasswd != null) {
      setState(() {
        widget.theSavedStatus.message = logged_in;
        widget.theSavedStatus.sttOfApi = StatusOfApi.ApiOk;
        widget.theSavedStatus.showValidationError = false;
        widget.theSavedStatus.hashPasswd = hashPasswd;
      });
    } else {
      setState(() {
        widget.theSavedStatus.message = api_login_failure_description;
        widget.theSavedStatus.sttOfApi = StatusOfApi.ApiLoginFailure;
        widget.theSavedStatus.showValidationError = true;
        widget.theSavedStatus.hashPasswd = null;
      });
      // pass the data up to the top so it can persist
    }
  }

  int _beginDaySeconds, _endDaySeconds;
  BuildContext _scaffoldContext;

  DateTime _fromDateDelete, _toDateDelete;
  String _fromDateDeleteString = '', _toDateDeleteString = '';

  Future<DateTime> _pickDeleteFromDate() async {
   DateTime date = await _pickDate();
    if (date == null) {
      return null;
    } else {
      setState(() {
        _fromDateDelete = date;
        _fromDateDeleteString = DateFormat.Md().format(_fromDateDelete);
        _beginDaySeconds = _fromDateDelete.millisecondsSinceEpoch ~/
            utilities.dateConversionFactor;
      });
      return _fromDateDelete;
    }
  }

  Future<DateTime> _pickDeleteToDate() async {
    DateTime date = await _pickDate();
    if (date == null) {
      return null;
    } else {
      setState(() {
        _toDateDelete = date;
        _toDateDeleteString = DateFormat.Md().format(_toDateDelete);
        _beginDaySeconds = date.millisecondsSinceEpoch ~/
            utilities.dateConversionFactor;
      });
      return _toDateDelete;
    }
  }

  Future<DateTime> _pickDate() async {
    DateTime retval = _fromDateDelete;
    if (retval == null) {
      retval = DateTime.now();
      retval = DateTime(retval.year, retval.month, retval.day);
    }
    var tmpDate = await showDatePicker(
        context: _scaffoldContext,
        initialDate: retval,
        firstDate: new DateTime(2018, 1, 1),
        lastDate: new DateTime(2018, 12, 31));
    retval = (tmpDate == null) ? retval : tmpDate;
    return retval;
//    _endDaySeconds =
//        tmp.millisecondsSinceEpoch ~/ utilities.dateConversionFactor;
  }

  void mapTheProjectIdAndNames() async {
    if (widget.theSavedStatus.projects.isEmpty) {
      // build the projectidmap
      widget.theSavedStatus.projects = await getProjectIdMapFromDb();
    }
  }

  // ========================================================================================================
  // This method is rerun every time setState is called.
  @override
  Widget build(BuildContext context) {
    this._scaffoldContext = context;

    if (_fromDateDelete == null) {
      _fromDateDelete = DateTime.now();
      _fromDateDelete = DateTime(_fromDateDelete.year, _fromDateDelete.month, _fromDateDelete.day);
    }
    if (_toDateDelete == null) {
      _toDateDelete = DateTime.now();
      _toDateDelete = DateTime(_toDateDelete.year, _toDateDelete.month, _toDateDelete.day);
    }

    mapTheProjectIdAndNames();
    var loginButton =
        FlatButton(onPressed: _loginButtonPressed, child: Text("Login"));
    var resetButton =
        FlatButton(onPressed: _resetButtonPressed, child: Text("Reset"));
    var logoutButton =
        FlatButton(onPressed: _logoutButtonPressed, child: Text("Logout"));
    var deleteRecordsButton =
      Container(
        padding: EdgeInsets.only(top: 10.0),
        alignment: Alignment(0.0, -1.0),
        width: 300.0,
        height: 60.0,
        child: FlatButton(
          onPressed: _deleteRecordsButtonPressed,
          color: Constants.deleteButtonColor,
          child: Text( "Delete records from $_fromDateDeleteString...to $_toDateDeleteString",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    var body;

    var rowCountersText = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 100.0,
          margin: const EdgeInsets.all(8.0),
          child: new RichText(
            textAlign: TextAlign.right,
            softWrap: true,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              text: 'Number of API calls started:',
            ),
          ),
        ),
        Container(
          width: 100.0,
          margin: const EdgeInsets.all(8.0),
          child: new RichText(
            textAlign: TextAlign.left,
            softWrap: true,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              text: 'Number of API calls completed so far:',
            ),
          ),
        ),
      ],
    );
    var rowCounters = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 100.0,
          margin: const EdgeInsets.all(8.0),
          child: new RichText(
              textAlign: TextAlign.right,
              softWrap: true,
              text: TextSpan(
                style: Theme.of(context).textTheme.display1,
                text: '${widget.theSavedStatus.counterApiCallsStarted}',
              )),
        ),
        Container(
          width: 100.0,
          margin: const EdgeInsets.all(8.0),
          child: new RichText(
            textAlign: TextAlign.left,
            softWrap: true,
            text: TextSpan(
              style: Theme.of(context).textTheme.display1,
              text: '${widget.theSavedStatus.counterApiCallsCompleted}',
            ),
          ),
        ),
      ],
    );

    Widget deleteDatesPickers = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.only(top: 10.0),
          alignment: Alignment(0.0, -1.0),
          width: 180.0,
          height: 30.0,
          child: FlatButton(
            onPressed: _pickDeleteFromDate,
            color: Constants.dateChooserButtonColor,
            child: Text(
              (_fromDateDelete == null) ? 'From: <date>' : 'From: ' + DateFormat.yMd().format(_fromDateDelete),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 10.0),
          alignment: Alignment(0.0, -1.0),
          width: 180.0,
          height: 30.0,
          child: FlatButton(
            onPressed: _pickDeleteToDate,
            color: Constants.dateChooserButtonColor,
            child: Text(
              (_toDateDelete == null) ? 'To: <date>' : 'To: ' + DateFormat.yMd().format(_toDateDelete),
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ],
    );

    if (widget.theSavedStatus.showValidationError == true) {
      body = Center(
        child: Padding(
          padding: MyApp.padding,
          child: SingleChildScrollView(
            child: Container(
              margin: MyApp.padding,
              padding: MyApp.padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                color: _errorColor,
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.error,
                      size: 100.0,
                      color: Colors.white,
                    ),
                    Text(
                      "Oh no! An error occurred.",
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    resetButton,
                  ]),
            ),
          ),
        ),
      );
    } else {
      List<Widget> childrenOfColumnView;
      switch (widget.theSavedStatus.sttOfApi) {
        case StatusOfApi.ApiOk:
          childrenOfColumnView = [
//            buildListView(),
            new Text(
              'Status:',
              style: Theme.of(context).textTheme.headline,
            ),
            new Text(
              '${widget.theSavedStatus.message}',
              style: Theme.of(context).textTheme.subhead,
            ),
            rowCountersText,
            rowCounters,
            deleteDatesPickers,
            deleteRecordsButton ,
            logoutButton
          ];
          break;
        case StatusOfApi.ApiLoginNeeded:
          childrenOfColumnView = [
//            buildListView(),
            new Text(
              'Status:',
              style: Theme.of(context).textTheme.headline,
            ),
            new Text(
              '${widget.theSavedStatus.message}',
              style: Theme.of(context).textTheme.subhead,
            ),
            new Text(
              api_login_needed_description,
            ),
            rowCountersText,
            rowCounters,
            loginButton,
          ];
          break;
        case StatusOfApi.ApiLoginFailure:
          childrenOfColumnView = [
//            buildListView(),
            new Text(
              'Attempts to send HTTP:',
            ),
            new Text(
              '${widget.theSavedStatus.counterApiCallsCompleted}',
              style: Theme.of(context).textTheme.display1,
            ),
            new Text(
              api_login_failure_description,
            ),
            new Text(
              '${widget.theSavedStatus.message}',
            ),
            rowCountersText,
            rowCounters,
            loginButton,
          ];
          break;
        case StatusOfApi.ApiUnknownFailure:
          childrenOfColumnView = [
//            buildListView(),
            new Text(
              'Attempts to send HTTP:',
            ),
            new Text(
              '${widget.theSavedStatus.counterApiCallsCompleted}',
              style: Theme.of(context).textTheme.display1,
            ),
            new Text(
              api_unknown_failure_description,
            ),
            new Text(
              '${widget.theSavedStatus.message}',
            ),
            resetButton,
          ];
          break;
      }
      body = Center(
        child: new Column(
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: childrenOfColumnView,
        ),
      );
    }

    body = new Scaffold(
      body: new Scaffold(
        body: body,
        backgroundColor: Colors.red[50],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _fabButtonPressed,
        tooltip: _sDoSomething,
        child: new Icon(Icons.add),
      ),
    );
    return displayLoginStatus(
        savedAppStatus: widget.theSavedStatus, context: context, child: body);
  }

  Container buildListView() {
    return null;
  } // buildListView
}
