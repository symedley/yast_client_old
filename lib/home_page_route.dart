import 'dart:async';

import 'package:flutter/material.dart';
import 'saved_app_status.dart';
import 'login_page.dart';
import 'yast_api.dart';
import 'main.dart';
import 'display_login_status.dart';
import 'Model/database_stuff.dart';

//import 'main.dart:StatusOfApi' as StatusOfApi;
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
    mapTheProjectIdAndNames();
    var loginButton =
        FlatButton(onPressed: _loginButtonPressed, child: Text("Login"));
    var resetButton =
        FlatButton(onPressed: _resetButtonPressed, child: Text("Reset"));
    var logoutButton =
        FlatButton(onPressed: _logoutButtonPressed, child: Text("Logout"));
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
              style: Theme.of(context).textTheme.display1,
            ),
            rowCountersText,
            rowCounters,
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
              style: Theme.of(context).textTheme.display1,
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
