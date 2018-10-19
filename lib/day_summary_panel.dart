import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:intl/intl.dart';

import 'saved_app_status.dart';
import 'display_login_status.dart';
import 'Model/yast_db.dart';
import 'Model/project.dart';
import 'Model/record.dart';
import 'utilities.dart';
import 'constants.dart';
import 'date_picker.dart';

class DaySummaryPanel extends StatefulWidget {
  DaySummaryPanel({Key key, this.title, this.theSavedStatus}) : super(key: key);

  final String title;

  static const Color color =
      const Color(0xFFF9FBE7); // why can't i say Colors.lime[50]?

  @override
  _DaySummaryPanelState createState() =>
      new _DaySummaryPanelState(this.theSavedStatus);

  final SavedAppStatus theSavedStatus;
}

class _DaySummaryPanelState extends State {
  _DaySummaryPanelState(this.theSavedStatus) {
    _fromDate = new DateTime.now();
  }

  final SavedAppStatus theSavedStatus;

  String rankKeyStr = "pie";
  String segmentKeyStr = "segment";
  String entriesKeyStr = "entries";
  String stackKeyStr = "stack";

  AnimatedCircularChart pieChart;


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

  void _cyclePie(List<CircularStackEntry> chartData) {
    setState(() {
      _chartKey.currentState.updateData(chartData);
    });
  }

  void _onTap() async {}

  void _pickDate() async {
    showSnackbar(_scaffoldContext, 'flat button was clicked');
    _fromDate = await showDatePicker(
        context: _scaffoldContext,
        initialDate: _fromDate,
        firstDate: new DateTime(2018, 1, 1),
        lastDate: new DateTime(2018, 12, 31));
    setState(() {
      // this is not triggering an update TODO
    });
  }

  BuildContext _scaffoldContext;
  DateTime _fromDate;

  @override
  Widget build(BuildContext context) {
    updateProjectIdToName();
    _scaffoldContext = context;
    List<CircularStackEntry> data = <CircularStackEntry>[
      new CircularStackEntry(
        <CircularSegmentEntry>[
          new CircularSegmentEntry(500.0, Colors.red[400], rankKey: segmentKeyStr),
          new CircularSegmentEntry(1000.0, Colors.green[400], rankKey: segmentKeyStr),
          new CircularSegmentEntry(2000.0, Colors.blue[400], rankKey: segmentKeyStr),
          new CircularSegmentEntry(1000.0, Colors.yellow[400], rankKey: segmentKeyStr),
        ],
        rankKey: stackKeyStr,
      )
    ];

    return displayLoginStatus(
      savedAppStatus: theSavedStatus,
      context: context,
      child: Container(
        constraints: BoxConstraints.expand(width: 400.00),
        color: DaySummaryPanel.color,
//        constraints: BoxConstraints.loose(Size(200.0, 400.0)),
        padding:
            const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 8.0),
        child: new Scaffold(
          resizeToAvoidBottomPadding: true,
          backgroundColor: DaySummaryPanel.color,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: new StreamBuilder(
                stream: Firestore.instance
                    .collection(YastDb.DbRecordsTableName)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Loading...
                  if ((!snapshot.hasData) || (theSavedStatus.projects.isEmpty))
                    return const Text('Loading...');

                  // Records, Filter records and Pie chart
                  List<CircularSegmentEntry> circularSegmentEntries = [];
                  Set<Project> usedProjectsSet = new Set();
                  Set<Project> projectsSet = new Set();
                  List<DurationProject> durationProjects = new List();
                  List<DocumentSnapshot> dss = snapshot.data.documents;
                  List todaysRecords = new List<Record>();
                  DateTime tmpFromdate = DateTime.parse(
                      new DateFormat('y-MM-dd').format(_fromDate));
                  DateTime toDate =
                      tmpFromdate.add(new Duration(hours: 23, minutes: 59));
                  int i = 0;
                  double size;
                  dss.forEach((DocumentSnapshot ds) {
                    // TODO this really should be someplace else--pulling data from database and
                    // putting in app's model.
                    var recordFromDb = Record.fromDocumentSnapshot(ds);
                    theSavedStatus.records[recordFromDb.id] = recordFromDb;
                    theSavedStatus.startTimeToRecord[recordFromDb.startTime] =
                        recordFromDb;
//                    debugPrint(
//                        ' --- $i ---> $tmpFromdate , ${recordFromDb.startTime} $toDate');
                    i++;
                    size = 0.0;
                    if ((tmpFromdate.compareTo(recordFromDb.startTime) < 0) &&
                        (toDate.compareTo(recordFromDb.endTime) > 0)) {
                      todaysRecords.add(recordFromDb);
                      size = 0.0 +
                          theSavedStatus
                              .howMuchOf24HoursForRecord(recordFromDb.id);
                      // TODO move this into the block of
                      // for each for the usedProjects.
                      circularSegmentEntries.add(new CircularSegmentEntry(
                        size,
                        hexToColor(theSavedStatus.getProjectColorStringFromId(
                            recordFromDb.yastObjectFieldsMap["project"])),
                        rankKey: theSavedStatus.getProjectNameFromId(
                            recordFromDb.yastObjectFieldsMap['project']),
                      ));
                      durationProjects.add(new DurationProject(
                          recordFromDb.duration(),
                          theSavedStatus.projects[
                          recordFromDb.yastObjectFieldsMap["project"]]));
                      //TODO creat a getter and handle null
                      usedProjectsSet.add(theSavedStatus
                          .projects[recordFromDb.yastObjectFieldsMap["project"]]);
                    } else {
                      if (theSavedStatus.projects[recordFromDb.projectId] != null) {
                        projectsSet.add(theSavedStatus
                            .projects[recordFromDb.projectId]);
                      }
                    }

                  });
                  // Change the set of projects into a sortable list
                  // with one instance of each project and the total duration
                  List<Project> usedProjectsList = usedProjectsSet.toList();
                  List<DurationProject> orderedProjectsList = new List();
                  usedProjectsList.forEach((proj) {
                    orderedProjectsList.add(new DurationProject(
                        durationProjects.where((durProj) {
                          return proj.getIdNum() == durProj.project.getIdNum();
                        }).reduce((dur1, dur2) {
                          return DurationProject(
                              dur1.duration + dur2.duration, dur1.project);
                        }).duration,
                        proj));
                  });
                  projectsSet.removeAll(usedProjectsSet);
                  projectsSet.forEach((proj) {
                    orderedProjectsList.add( new DurationProject(
                        new Duration(days: 0) , proj));
                  });

                  orderedProjectsList.sort((a,b) => b.duration.compareTo(a.duration));

                  if (circularSegmentEntries.isEmpty) {
                    circularSegmentEntries.add(new CircularSegmentEntry(
                      100.0,
                      Colors.white,
                      rankKey: segmentKeyStr,
                    ));
                  }
                  CircularStackEntry entries = new CircularStackEntry(
                      circularSegmentEntries,
                      rankKey: stackKeyStr);
                  data = <CircularStackEntry>[entries];
                  if (pieChart == null) {
                    pieChart = new AnimatedCircularChart(
                      key: _chartKey,
                      size: const Size(300.0, 300.0),
                      initialChartData: data,
                      chartType: CircularChartType.Pie,
                    );
                  }
                  else {
                    _cyclePie(data);
                  }
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(top: 10.0),
                          alignment: Alignment(0.0, -1.0),
                          width: 300.0,
                          height: 30.0,
                          child: FlatButton(
                              onPressed: _pickDate,
                              color: Colors.grey[400],
                              child: Text(
                                DateFormat.MMMMd().format(_fromDate),
                                style: TextStyle(color: Colors.black),
                              )),
//                          new DatePickerDialog(
//                            selectedDate: _fromDate,
//                            selectDate: (DateTime date) {
//                              setState(() {
//                                _fromDate = date;
//                              });
//                            },
//                          ),
//                            Text("hello"),
                        ),
                        Center(
                          child: pieChart,
                        ),

                        // Column of project rectangles
                        Expanded(
//                        height: 200.0,
                          child: new ListView.builder(
                            itemCount: orderedProjectsList.length,
                            shrinkWrap: true,
                            itemExtent: 35.0,
                            itemBuilder: ((context, index) {
                              return Container(
                                constraints:
                                    BoxConstraints.expand(width: 400.0),
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
                                                orderedProjectsList[index].project
                                                    .primaryColor),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        " ${orderedProjectsList[index].project.name}",
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
      ),
    );
  }
}

class DurationProject {
  DurationProject(this.duration, this.project);

  Duration duration;
  Project project;
}
