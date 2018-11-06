import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_common/common.dart' as common;
import 'package:intl/intl.dart';

import 'saved_app_status.dart';
import 'display_login_status.dart';
import 'Model/yast_db.dart';
import 'Model/project.dart';
import 'Model/record.dart';
import 'utilities.dart';
import 'constants.dart';

const double barTextEdgeInsets = 12.0;
const double barEdgeInsets = 2.0;
const double barWidth = 200.0;
const double loginStatusWidth = 400.0;
const double pieChartWidth = 300.0;
const double barHeight = 30.0;
const Color dateChooserButtonColor = Color(0xff9e9e9e); //Colors.grey[300];??
//const Color dummy  = Colors.grey[400];
const String rankKeyStr = "pie";
const String segmentKeyStr = "segment";
const String entriesKeyStr = "entries";
const String stackKeyStr = "stack";

class DaySummaryPanel extends StatefulWidget {
  DaySummaryPanel({Key key, this.title, this.theSavedStatus}) : super(key: key);

  final String title;

  static const Color backgroundColor =
      const Color(0xFFF9FBE7); // why can't i say Colors.lime[50]?

  @override
  _DaySummaryPanelState createState() =>
      new _DaySummaryPanelState(this.theSavedStatus);

  final SavedAppStatus theSavedStatus;
}

class _DaySummaryPanelState extends State {
  _DaySummaryPanelState(this.theSavedStatus) {
    _fromDate = theSavedStatus.getPreferredDate();
    if (_fromDate == null) {
      _fromDate = new DateTime.now();
      theSavedStatus.setPreferredDate(_fromDate);
    }
  }

  final SavedAppStatus theSavedStatus;

  charts.PieChart pieChart;

  void updateProjectIdToName() async {
    var idToProject = await Firestore.instance
        .collection(YastDb.DbProjectsTableName)
        .getDocuments();
    idToProject.documents.forEach((DocumentSnapshot ds) {
      var project = Project.fromDocumentSnapshot(ds);
      theSavedStatus.projects[project.id] = project;
    });
  }

  /// update the pie chart with new data. Flutter charts version
  void _cyclePieFlutterCharts(
      charts.PieChart pieChart, List<charts.Series> chartData) {}

  void _onTap() async {}

  void _pickDate() async {
    showSnackbar(_scaffoldContext, 'flat button was clicked');
    var tmpDate = await showDatePicker(
        context: _scaffoldContext,
        initialDate: _fromDate,
        firstDate: new DateTime(2018, 1, 1),
        lastDate: new DateTime(2018, 12, 31));
    _fromDate = (tmpDate == null) ? _fromDate : tmpDate;
    theSavedStatus.setPreferredDate(_fromDate);
    setState(() {
//       this is not triggering an update TODO
    });
  }

  BuildContext _scaffoldContext;
  DateTime _fromDate;

  @override
  Widget build(BuildContext context) {
    updateProjectIdToName();
    _scaffoldContext = context;
//    List<CircularStackEntry> data = <CircularStackEntry>[
//      new CircularStackEntry(
//        <CircularSegmentEntry>[
//        ],
//        rankKey: stackKeyStr,
//      )
//    ];
    List<charts.Series> data;

    return displayLoginStatus(
      savedAppStatus: theSavedStatus,
      context: context,
      child: Container(
        constraints: BoxConstraints.expand(width: loginStatusWidth),
        color: DaySummaryPanel.backgroundColor,
        padding:
            const EdgeInsets.only(left: 8.0, top: 8.0, right: 8.0, bottom: 8.0),
        child: new Scaffold(
          resizeToAvoidBottomPadding: true,
          backgroundColor: DaySummaryPanel.backgroundColor,
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
                  Set<Project> usedProjectsSet = new Set();
                  Set<Project> projectsSet = new Set();
                  List<DurationProject> durationProjects = new List();
                  List<DocumentSnapshot> dss = snapshot.data.documents;
                  List todaysRecords = new List<Record>();
                  DateTime beginTimeSegment = DateTime.parse(
                      new DateFormat('y-MM-dd').format(_fromDate));
                  DateTime endTimeSegment =
                      beginTimeSegment.add(new Duration(hours: 23, minutes: 59));
//                  int i = 0;
                  dss.forEach((DocumentSnapshot ds) {
                    // TODO this really should be someplace else--pulling data from database and
                    // putting in app's model.
                    var recordFromDb = Record.fromDocumentSnapshot(ds);
                    theSavedStatus.currentRecords[recordFromDb.id] = recordFromDb;
                    theSavedStatus.startTimeToRecord[recordFromDb.startTime] =
                        recordFromDb;
                    //                    debugPrint(
                    //                        ' --- $i ---> $tmpFromdate , ${recordFromDb.startTime} $toDate');
//                    i++;
                    if ((beginTimeSegment.compareTo(recordFromDb.startTime) < 0) &&
                        (endTimeSegment.compareTo(recordFromDb.endTime) > 0)) {
                      todaysRecords.add(recordFromDb);
                      durationProjects.add(new DurationProject(
                          recordFromDb.duration(),
                          theSavedStatus.projects[
                              recordFromDb.yastObjectFieldsMap["project"]]));
                      //TODO creat a getter and handle null
                      usedProjectsSet
                          .add(theSavedStatus.projects[recordFromDb.projectId]);
                    } else {
                      if (theSavedStatus.projects[recordFromDb.projectId] !=
                          null) {
                        projectsSet.add(
                            theSavedStatus.projects[recordFromDb.projectId]);
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
                    orderedProjectsList
                        .add(new DurationProject(new Duration(hours: 0), proj));
                  });

                  orderedProjectsList
                      .sort((a, b) => b.duration.compareTo(a.duration));
                  // circularSegmentEnties is passed by reference and set in the createPieSegments method
                  // circularSegmentEnties not used anymore
                  data = createPieSegmentsChartsFlutter(
                      durationProjects, theSavedStatus);
//                  if (pieChart == null) {
                  pieChart = createPieChartsFlutter(data);
//                  } else {
//                    _cyclePieFlutterCharts(pieChart, data);
//                  }
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //
                        // Date chooser button:
                        Container(
                          padding: EdgeInsets.only(top: 10.0),
                          alignment: Alignment(0.0, -1.0),
                          width: pieChartWidth,
                          height: barHeight,
                          child: FlatButton(
                            onPressed: _pickDate,
                            color: dateChooserButtonColor,
                            child: Text(
                              DateFormat.MMMMd().format(_fromDate),
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        //
                        // Pie chart
                        Container(
                          height: 300.0,
                          width: 300.0,
                          child: Center(
                            child: pieChart,
                          ),
                        ),

                        //
                        // Column of project rectangle bars
                        Expanded(
                          child: new ListView.builder(
                            itemCount: orderedProjectsList.length,
                            shrinkWrap: true,
                            itemExtent: 35.0,
                            itemBuilder: ((context, index) {
                              //
                              // one Project rectangle bar
                              return projectBar(orderedProjectsList[index]);
                            }),
                          ),
                        )
                      ]);
                }),
          ),
        ),
      ),
    );
  }

// only the hours and minutes part
  String formatDuration(Duration duration) {
    final formatter = new NumberFormat("##");
    int hours = duration.inHours % Duration.hoursPerDay;
    int minutes = duration.inMinutes % Duration.minutesPerHour;
    return formatter.format(hours) + ":" + formatter.format(minutes);
  }

  /// Create pie using flutter_charts

  charts.PieChart createPieChartsFlutter(List<charts.Series> data) {
    var pieChart = new charts.PieChart(data,
        animate: true,
        // Add an [ArcLabelDecorator] configured to render labels outside of the
        // arc with a leader line.
        //
        // Text style for inside / outside can be controlled independently by
        // setting [insideLabelStyleSpec] and [outsideLabelStyleSpec].
        //
        // Example configuring different styles for inside/outside:
        //       new charts.ArcLabelDecorator(
        //          insideLabelStyleSpec: new charts.TextStyleSpec(...),
        //          outsideLabelStyleSpec: new charts.TextStyleSpec(...)),
        defaultRenderer: new charts.ArcRendererConfig(
            arcWidth: 60,
            arcRendererDecorators: [new charts.ArcLabelDecorator()]));
    return pieChart;

//    defaultRenderer: new charts.ArcRendererConfig(arcRendererDecorators: [
//          new charts.ArcLabelDecorator(
//              labelPosition: charts.ArcLabelPosition.auto,
//            insideLabelStyleSpec:
//            common.TextStyleSpec(
//                fontFamily: 'Arial'
//                ,color: common.Color.fromHex(code:  'xff4444ff')),
//              outsideLabelStyleSpec:
//                  common.TextStyleSpec(
//                      fontFamily: 'Arial'
//                      ,color: common.Color.black))
//        ]));
  }

  /// Create pie segments from the DurationProject data, which should be sorted
  /// use flutter_charts
  List<charts.Series> createPieSegmentsChartsFlutter(
      durProjectsList, theSavedStatus) {
    // First, change the usedProjectsList into simpler data
    List<PieChartData> data = new List();
    durProjectsList.forEach((dp) {
      data.add(new PieChartData(dp.duration.inMinutes + 0.0, dp.project.name,
          dp.project.primaryColor));
    });
    if (data.isEmpty) {
      data.add(new PieChartData(100.0, "none", "#225599"));
    }
    var retval = [
      new charts.Series<PieChartData, int>(
        id: 'Where time went',
        domainFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
        measureFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
        // dp.getDurationNumber()
        data: data,
        // Set a label accessor to control the text of the arc label.
        labelAccessorFn: (PieChartData row, _) =>
            '${row.getProjectName()}:\n${row.getDuration().ceil()} min' ,
        outsideLabelStyleAccessorFn: _outsideLabelStyleAccessorFn,
        insideLabelStyleAccessorFn: _insideLabelStyleAccessorFn,
        fillColorFn: (_, __) => common.Color.fromHex(code: '#00FF00'),
        // common.Color.black ,
        colorFn: (pieChartData, index) => common.Color.fromHex(
            code: pieChartData
                .colorStr), // common.Color.fromHex(code: '#00FF00'),     // ('#00FF00'),
      )
    ];
    return retval;
  }

  common.TextStyleSpec _outsideLabelStyleAccessorFn(PieChartData pcd, int i) {
    debugPrint('_outsideLabelStyle called');
    return common.TextStyleSpec(fontFamily: 'Arial', fontSize: 12, color: common.Color.black);
  }

  common.TextStyleSpec _insideLabelStyleAccessorFn(PieChartData pcd, int i) {
    debugPrint('_insideLabelStyle called');
    return common.TextStyleSpec(fontFamily: 'Arial', fontSize: 12, color: common.Color.white);
  }

  Text textForOneProjectColorBar(Duration dura) {
    return Text(((dura != null) && (dura.inMinutes != 0))
        ? " ${formatDuration(dura)}"
        : "");
  }

  Container projectBar(DurationProject theProjectWithDuration) {
    return Container(
      constraints: BoxConstraints.expand(width: loginStatusWidth),
      padding: new EdgeInsets.all(barEdgeInsets),
      child: InkWell(
        borderRadius: BorderRadius.circular((Constants.BORDERRADIUS) / 4),
        // TODO fix these ink splash colors
        highlightColor: Colors.yellow,
        splashColor: Colors.white,
        onTap: _onTap,
        child: Row(children: [
          Container(
            width: barWidth,
            child: Container(
                margin: new EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.all(Radius.circular(Constants.BORDERRADIUS)),
                  color: hexToColor(theProjectWithDuration.project.primaryColor,
                      transparency: 0xff0000000),
                ),
                alignment: Alignment(1.0, 0.0),
                //
                // Time text
                child: Padding(
                  padding: EdgeInsets.only(
                      left: barTextEdgeInsets, right: barTextEdgeInsets),
                  child: textForOneProjectColorBar(
                      theProjectWithDuration.duration),
                )),
          ),
          Flexible(
              child: Text(
            " ${theProjectWithDuration.project.name}",
            overflow: TextOverflow.ellipsis,
          ))
        ]),
      ),
    );
  } // projectBar
}

class DurationProject {
  DurationProject(this.duration, this.project);

  Duration duration;
  Project project;
}

class PieChartData {
  PieChartData(this.duration, this.projectName, this.colorStr);

  double duration;

  double getDuration() {
    return duration;
  }

  String projectName;

  String getProjectName() {
    return projectName;
  }

  String colorStr;

  String getColorStr() => colorStr;
}
