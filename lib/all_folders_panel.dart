import 'dart:core';
import 'package:flutter/material.dart';
import 'saved_app_status.dart';

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
    return null;
  }
}
