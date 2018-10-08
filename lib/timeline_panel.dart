import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';

import 'saved_app_status.dart';
import 'display_login_status.dart';
import 'Model/yast_db.dart';
import 'Model/project.dart';
import 'Model/record.dart';
import 'utilities.dart';
import 'constants.dart';

class TimelinePanel extends StatefulWidget {
  TimelinePanel({Key key, this.title, this.theSavedStatus}) : super(key: key);

  final String title;

  static const Color color =
      const Color(0xFFF9FBE7); // why can't i say Colors.lime[50]?

  @override
  _TimelinePanelState createState() =>
      new _TimelinePanelState(this.theSavedStatus);

  final SavedAppStatus theSavedStatus;
}

class _TimelinePanelState extends State {
  _TimelinePanelState(this.theSavedStatus);

  final SavedAppStatus theSavedStatus;

  void updateProjectIdToName() async {
    var idToProject = await Firestore.instance
        .collection(YastDb.DbProjectsTableName)
        .getDocuments();
    idToProject.documents.forEach((DocumentSnapshot ds) {
      var project = Project.fromDocumentSnapshot(ds);
      theSavedStatus.projects[project.id] = project;
    });
  }

  final GlobalKey<AnimatedCircularChartState> _chartKey =
      new GlobalKey<AnimatedCircularChartState>();

  void _cyclePie() {
    List<CircularStackEntry> nextData = <CircularStackEntry>[
      new CircularStackEntry(
        <CircularSegmentEntry>[
          new CircularSegmentEntry(500.0, Colors.red[400], rankKey: 'Q1'),
          new CircularSegmentEntry(1000.0, Colors.green[400], rankKey: 'Q1'),
          new CircularSegmentEntry(2000.0, Colors.blue[400], rankKey: 'Q1'),
          new CircularSegmentEntry(1000.0, Colors.yellow[400], rankKey: 'Q1'),
        ],
        rankKey: 'Pie Chart',
      )
    ];
    setState(() {
      _chartKey.currentState.updateData(nextData);
    });
  }

  void _onTap() async {}

  @override
  Widget build(BuildContext context) {
    updateProjectIdToName();
    List<CircularStackEntry> data = <CircularStackEntry>[
      new CircularStackEntry(
        <CircularSegmentEntry>[
          new CircularSegmentEntry(500.0, Colors.red[400], rankKey: 'Q1'),
          new CircularSegmentEntry(1000.0, Colors.green[400], rankKey: 'Q1'),
          new CircularSegmentEntry(2000.0, Colors.blue[400], rankKey: 'Q1'),
          new CircularSegmentEntry(1000.0, Colors.yellow[400], rankKey: 'Q1'),
        ],
        rankKey: 'Pie Chart',
      )
    ];

    return displayLoginStatus(
      savedAppStatus: theSavedStatus,
      context: context,
      child: Container(
        constraints: BoxConstraints.expand(), color: TimelinePanel.color,
//        constraints: BoxConstraints.loose(Size(200.0, 400.0)),
        padding:
            const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 8.0),
        child: new Scaffold(
          resizeToAvoidBottomPadding: true,
          backgroundColor: TimelinePanel.color,
          body: new StreamBuilder(
              stream: Firestore.instance.collection('records').snapshots(),
              builder: (context, snapshot) {
                // Loading...
                if ((!snapshot.hasData) || (theSavedStatus.projects.isEmpty))
                  return const Text('Loading...');

                // Pie chart
                List<CircularSegmentEntry> cse = [];
                Set<Project> projects = new Set();
                List<DocumentSnapshot> dss = snapshot.data.documents;
                dss.forEach((DocumentSnapshot ds) {
                  var recordFromDb = Record.fromDocumentSnapshot(ds);
                  theSavedStatus.records[recordFromDb.id] = recordFromDb;
                  double size = 0.0 +
                      theSavedStatus.howMuchOf24HoursForRecord(recordFromDb.id);
                  cse.add(new CircularSegmentEntry(
                    size,
                    hexToColor(theSavedStatus.getProjectColorStringFromId(
                        recordFromDb.yastObjectFieldsMap["project"])),
                    rankKey: theSavedStatus.getProjectNameFromId(
                        recordFromDb.yastObjectFieldsMap['project']),
                  ));
                  //TODO creat a getter and handle null
                  projects.add(theSavedStatus
                      .projects[recordFromDb.yastObjectFieldsMap["project"]]);
                });
                List<Project> projectsList = projects.toList();

                CircularStackEntry entries =
                    new CircularStackEntry(cse, rankKey: 'name');
                data = <CircularStackEntry>[entries];
                return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Center(
                        child: new AnimatedCircularChart(
                          key: _chartKey,
                          size: const Size(300.0, 300.0),
                          initialChartData: data,
                          chartType: CircularChartType.Pie,
                        ),
                      ),

                      // Column of project rectangles
                      Container(
                        height: 200.0,
                        child: new ListView.builder(
                          itemCount: projectsList.length,
                          shrinkWrap: true,
                          itemExtent: 35.0,
                          itemBuilder: ((context, index) {
                            return Container(
                              constraints: BoxConstraints.expand(width: 400.0),
                              padding: new EdgeInsets.all(2.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                    (Constants.BORDERRADIUS) / 4),
                                // TODO fix these ink splash colors
                                highlightColor: Colors.yellow,
                                splashColor: Colors.white,
                                onTap: _onTap,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 200.0,
//                                      height: 35.0,
                                      child: Container(
                                        margin: new EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                  Constants.BORDERRADIUS)),
                                          color: hexToColor(
                                              projectsList[index].primaryColor),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      " ${projectsList[index].name}",
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ]);
              }),
        ),
      ),
    );
  }
}
