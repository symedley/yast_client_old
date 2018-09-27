import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import 'saved_app_status.dart';
import 'display_login_status.dart';
import 'Model/yast_db.dart';

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

  void UpdateProjectIdToName() async {
    var idToProject = await Firestore.instance
        .collection(YastDb.DbIdToProjectTableName)
        .getDocuments();
    idToProject.documents.forEach((DocumentSnapshot ds) {
      var id = ds.data.keys.first;
      var name = ds.data.values.first;
      theSavedStatus.projectIdToName[id] = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    UpdateProjectIdToName();

    return displayLoginStatus(
      savedAppStatus: theSavedStatus,
      context: context,
      child: Container(
        color: TimelinePanel.color,
        constraints: BoxConstraints.loose(Size(200.0, 400.0)),
        padding: const EdgeInsets.only(
            left: 8.0, top: 8.0, right: 8.0, bottom: 48.0),
        child: new Scaffold(
          resizeToAvoidBottomPadding: true,
          backgroundColor: TimelinePanel.color,
          body: new StreamBuilder(
              stream: Firestore.instance.collection('records').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                return new ListView.builder(
                    itemCount: snapshot.data.documents.length,
                    padding: const EdgeInsets.only(top: 10.0),
                    itemExtent: 25.0,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.documents[index];
                      String name =
                          theSavedStatus.getProjectNameFromId(ds['project']);

                      return new Text(
                        " $name ${ds['id']}",
                        overflow: TextOverflow.ellipsis,
                      );
                    });
              }),
        ),
      ),
    );
  }
}
