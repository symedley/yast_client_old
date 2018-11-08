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
import 'utilities.dart' as utilities;
import 'constants.dart';
import 'duration_project.dart';

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
      _fromDate = new DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
      theSavedStatus.setPreferredDate(_fromDate);
    }
    _beginDaySeconds =
        _fromDate.millisecondsSinceEpoch ~/ utilities.dateConversionFactor;
    DateTime tmp = _fromDate.add(Duration(hours: 24));
    _endDaySeconds =
        tmp.millisecondsSinceEpoch ~/ utilities.dateConversionFactor;
  }

  final SavedAppStatus theSavedStatus;

  charts.PieChart pieChart;

  void updateProjectIdToName() async {
    var idToProject = await Firestore.instance
        .collection(YastDb.DbProjectsTableName)
        .getDocuments();
    idToProject.documents.forEach((DocumentSnapshot ds) {
      var project = Project.fromDocumentSnapshot(ds);
      theSavedStatus.addProject(project);
    });
  }

  void _onTap() async {}

  void _pickDate() async {
    utilities.showSnackbar(_scaffoldContext, 'flat button was clicked');
    var tmpDate = await showDatePicker(
        context: _scaffoldContext,
        initialDate: _fromDate,
        firstDate: new DateTime(2018, 1, 1),
        lastDate: new DateTime(2018, 12, 31));
    _fromDate = (tmpDate == null) ? _fromDate : tmpDate;
    theSavedStatus.setPreferredDate(_fromDate);
    _beginDaySeconds =
        _fromDate.millisecondsSinceEpoch ~/ utilities.dateConversionFactor;
    DateTime tmp = _fromDate.add(Duration(hours: 24));
    _endDaySeconds =
        tmp.millisecondsSinceEpoch ~/ utilities.dateConversionFactor;
    setState(() {
//       this is not triggering an update TODO
    });
  }

  BuildContext _scaffoldContext;
  DateTime _fromDate;
  int _beginDaySeconds, _endDaySeconds;

  @override
  Widget build(BuildContext context) {
    theSavedStatus.resetProjectDurationMap();
    updateProjectIdToName();
    _scaffoldContext = context;
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
                    .where("startTime",
                        isGreaterThanOrEqualTo: _beginDaySeconds.toString())
                    .snapshots(),
                builder: (context, snapshot) {
                  // Loading...
                  if ((!snapshot.hasData) || (theSavedStatus.projects.isEmpty))
                    return const Text('Loading...');

                  // FIXING the mess
                  // copy the projects map into a map to DurationProjects.
                  // everytime you encoutner a DB record, look up
                  // in the map of DurationProjects and add the duration
                  // to that entry.
                  // Sort the map
                  // Create pie chart data segments from the map entries
                  // with > 0 duration.
                  // BUT WAIT: don't keep recreating those maps
                  // inside the stream builder.
                  // How about a simple Map projectname->duration?
                  List<DocumentSnapshot> dss = snapshot.data.documents;

                  // Records, Filter records and Pie chart
//                  Set<Project> projectsSet = theSavedStatus.projects.values.toSet();
//                  List<DurationProject> durationProjects = new List();
//                  List todaysRecords = new List<Record>();
//                  DateTime beginTimeSegment = DateTime.parse(
//                  new DateFormat('y-MM-dd').format(_fromDate));
//                  DateTime endTimeSegment = beginTimeSegment
//                      .add(ect> usedProjectsSet = new Set();
//                  Set<Projnew Duration(hours: 23, minutes: 59));
//                  int i = 0;
                  dss.forEach((DocumentSnapshot ds) {
                    // TODO this really should be someplace else--pulling data from database and
                    // putting in app's model.
                    var recordFromDb = Record.fromDocumentSnapshot(ds);
                    theSavedStatus.currentRecords[recordFromDb.id] =
                        recordFromDb;
                    theSavedStatus.startTimeToRecord[recordFromDb.startTime] =
                        recordFromDb;
                    //                    debugPrint(
                    //                        ' --- $i ---> $tmpFromdate , ${recordFromDb.startTime} $toDate');
//                    i++;
                    // for now, use only start time. Ignore end time.
                    if ((_beginDaySeconds <
                            (int.parse(recordFromDb.startTimeStr))) &&
                        (_endDaySeconds >
                            int.parse(recordFromDb.startTimeStr))) {
                      theSavedStatus.addToProjectDuration(
                          project:
                              theSavedStatus.projects[recordFromDb.projectId],
                          duration: recordFromDb.duration());
                    }
                  });
                  //Sort the duration projects
                  List<MapEntry<String, DurationProject>> sorted =
                      theSavedStatus.sortedProjectDurations();

                  data = createPieSegmentsChartsFlutter(sorted, theSavedStatus);
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
                            itemCount: sorted.length,
                            //orderedProjectsList.length,
                            shrinkWrap: true,
                            itemExtent: 35.0,
                            itemBuilder: ((context, index) {
                              //
                              // one Project rectangle bar
                              // this looks really inefficient
                              return projectBar(sorted[index]);
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
    final formatter2 = new NumberFormat("00");
    int hours = duration.inHours % Duration.hoursPerDay;
    int minutes = duration.inMinutes % Duration.minutesPerHour;
    return formatter.format(hours) + ":" + formatter2.format(minutes);
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
        defaultRenderer:
            new charts.ArcRendererConfig(arcWidth: 60, arcRendererDecorators: [
          new charts.ArcLabelDecorator(
              insideLabelStyleSpec: new charts.TextStyleSpec(
                  color: common.Color.black, fontSize: 12),
              outsideLabelStyleSpec: new charts.TextStyleSpec(
                  color: common.Color.black, fontSize: 12))
        ]));
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
      List<MapEntry<String, DurationProject>> projIdToDurProj, theSavedStatus) {
    // First, change the usedProjectsList into simpler data
    List<PieChartData> data = new List();
    projIdToDurProj.forEach((kv) {
      if (kv.value.duration.inMinutes > 0) {
        data.add(new PieChartData(
            kv.value.duration.inMinutes + 0.0,
            kv.value.project.name,
            theSavedStatus.getProjectColorStringFromId(kv.key)));
      }
    });
    var retval;
    if (data.isEmpty) {
      data.add(new PieChartData(100.0, "none", "#666666"));
      data.add(new PieChartData(100.0, "none ", "#888888"));
      retval = [
        new charts.Series<PieChartData, int>(
          id: 'Where time went',
          domainFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
          measureFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
          // dp.getDurationNumber()
          data: data,
          // Set a label accessor to control the text of the arc label.
          labelAccessorFn: (PieChartData row, _) =>
              'no data for this day',
          outsideLabelStyleAccessorFn: _outsideLabelStyleAccessorFn,
          insideLabelStyleAccessorFn: _insideLabelStyleAccessorFn,
          fillColorFn: (_, __) => common.Color.fromHex(code: '#00FF00'),
          // common.Color.black ,
          colorFn: (pieChartData, index) => common.Color.fromHex(
              code: pieChartData.colorStr),
          displayName: 'where time went',
        )
      ];
    } else {
      retval = [
        new charts.Series<PieChartData, int>(
          id: 'Where time went',
          domainFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
          measureFn: (PieChartData pcd, _) => (pcd.getDuration().round()),
          // dp.getDurationNumber()
          data: data,
          // Set a label accessor to control the text of the arc label.
          labelAccessorFn: (PieChartData row, _) =>
            '${row.getProjectName()}:\n${row.getDuration().ceil()} min',

          outsideLabelStyleAccessorFn: _outsideLabelStyleAccessorFn,
          insideLabelStyleAccessorFn: _insideLabelStyleAccessorFn,
          fillColorFn: (_, __) => common.Color.fromHex(code: '#00FF00'),
          // common.Color.black ,
          colorFn: (pieChartData, index) => common.Color.fromHex(
              code: pieChartData
                  .colorStr), // common.Color.fromHex(code: '#00FF00'),     // ('#00FF00'),
        )
      ];
    }
    return retval;
  }

  common.TextStyleSpec _outsideLabelStyleAccessorFn(PieChartData pcd, int i) {
    debugPrint('_outsideLabelStyle called');
    return common.TextStyleSpec(
        fontFamily: 'Arial', fontSize: 12, color: common.Color.black);
  }

  common.TextStyleSpec _insideLabelStyleAccessorFn(PieChartData pcd, int i) {
    debugPrint('_insideLabelStyle called');
    return common.TextStyleSpec(
        fontFamily: 'Arial', fontSize: 12, color: common.Color.white);
  }

  Text textForOneProjectColorBar(Duration dura) {
    return Text(((dura != null) && (dura.inMinutes != 0))
        ? " ${formatDuration(dura)}"
        : "");
  }

  Container projectBar(MapEntry<String, DurationProject> projectIdToProjDur) {
    //}  DurationProject theProjectWithDuration) {
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
                  color: utilities.hexToColor(
                      theSavedStatus
                          .getProjectColorStringFromId(projectIdToProjDur.key),
                      transparency: 0xff0000000),
                ),
                alignment: Alignment(1.0, 0.0),
                //
                // Time text
                child: Padding(
                  padding: EdgeInsets.only(
                      left: barTextEdgeInsets, right: barTextEdgeInsets),
                  child: textForOneProjectColorBar(
                      projectIdToProjDur.value.duration),
                )),
          ),
          Flexible(
              child: Text(
            " ${projectIdToProjDur.value.project.name}",
            overflow: TextOverflow.ellipsis,
          ))
        ]),
      ),
    );
  } // projectBar
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
