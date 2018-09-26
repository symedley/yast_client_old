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

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> sqs =
        Firestore.instance.collection(YastDb.DbRecordsTableName).snapshots();
    CollectionReference idToProject =
        Firestore.instance.collection(YastDb.DbIdToProjectTableName);
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
              stream: sqs,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                return new ListView.builder(
                    itemCount: snapshot.data.documents.length,
                    padding: const EdgeInsets.only(top: 10.0),
                    itemExtent: 25.0,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.documents[index];
//                      String name =
//                          theSavedStatus.getProjectNameFromId(ds['project']);
                      idToProject
                          .document(ds['project'])
                          .get()
                          .then((DocumentSnapshot ds2) {
                        String nm = ds2.data.values.first;
                        return new Text(
                          " $nm ${ds['id']}",
                          overflow: TextOverflow.ellipsis,
                        );
                      });
                    });
              }),
        ),
      ),
    );
  }
}
