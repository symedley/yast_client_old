import 'package:flutter/material.dart';
import 'saved_app_status.dart';
import 'home_page_route.dart';
import 'timeline_panel.dart';
import 'all_projects_panel.dart';
import 'all_folders_panel.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  static const padding = EdgeInsets.all(16.0);

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Tab> myTabs = <Tab>[
    new Tab(text: 'Home'),
    new Tab(text: 'Timeline'),
    new Tab(text: 'All Projects'),
    new Tab(text: 'All Folders'),
    new Tab(text: 'Database'),
  ];

  static String tag = "my-app";

  SavedAppStatus _currentAppStatus;

  final routes = <String, WidgetBuilder>{
//    LoginPage.tag: (context) => LoginPage(),
    HomePageRoute.tag: (context) => HomePageRoute(),
  };

  @override
  Widget build(BuildContext context) {
    if (_currentAppStatus == null) {
      _currentAppStatus = new SavedAppStatus();
    }

    return new MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Yast Client',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blueGrey,
          accentColor: Colors.blueAccent,
          errorColor: Colors.red[700],
        ),
        routes: routes,
        home: DefaultTabController(
          length: myTabs.length,
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60.0),
              child: AppBar(
                primary: true,
                bottom: TabBar(tabs: myTabs),
              ),
            ),
            body: TabBarView(
                children: [
                  HomePageRoute(
                    title: 'Yast Home Page',
                    theSavedState: _currentAppStatus,
                  ),
                  TimelinePanel(
                    // key: key,
                    title: "Timeline",
                    theSavedStatus: _currentAppStatus,
                  ),
                  AllProjectsPanel(
                    // key: key,
                      title: "All my projects",
                      theSavedStatus: _currentAppStatus),
                  AllFoldersPanel(
                    // key: key,
                      theSavedStatus: _currentAppStatus),
//              DatabasePanel(
//                 key: key,
//                title: "Database panel",
//                )
                ]
            ),

          ),
        )
    );
  }
}
