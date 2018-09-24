import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'saved_app_status.dart';
import 'display_login_status.dart';
import 'Model/yast_db.dart';

class AllFoldersPanel extends StatefulWidget {
  AllFoldersPanel({Key key, this.title, @required this.theSavedStatus})
      : super(key: key);

  static Color color = Colors.cyan[200];
  final title;
  final SavedAppStatus theSavedStatus;

  @override
  _AllFoldersPanelState createState() => new _AllFoldersPanelState();

  factory AllFoldersPanel.forDesignTime() {
    return AllFoldersPanel(
        title: 'Title', theSavedStatus: new SavedAppStatus.dummy());
  }
}

class _AllFoldersPanelState extends State<AllFoldersPanel> {
  // ignore: unused_field

  @override
  Widget build(BuildContext context) {
    return displayLoginStatus(
      savedAppStatus: widget.theSavedStatus,
      context: context,
      child: Container(
        color: AllFoldersPanel.color,
        constraints: BoxConstraints.loose(Size(200.0, 400.0)),
        padding: const EdgeInsets.only(
            left: 8.0, top: 8.0, right: 8.0, bottom: 48.0),
        child: new Scaffold(
          backgroundColor: AllFoldersPanel.color,
          body: new StreamBuilder(
              stream: Firestore.instance
                  .collection(YastDb.DbFoldersTableName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                return new ListView.builder(
                    itemCount: snapshot.data.documents.length,
                    padding: const EdgeInsets.all(10.0),
                    //itemExtent: 25.0,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.documents[index];
                      return ExpansionTile(
                        title: Text(ds['name']),
                        backgroundColor: hexToColor(ds['primaryColor']),
                      );
                      //return new Text(" ${ds['name']} ${ds['id']}");
                    });
              }),
        ),
      ),
    );
  }


    // TODO move to a utility class or file
    /// Construct a color from a hex code string, of the format #RRGGBB.
    Color hexToColor(String code) {
      return new Color(int.parse(code.substring(1, 7), radix: 16) + 0x88000000);
    }
  }
