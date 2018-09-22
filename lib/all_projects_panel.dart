import 'package:flutter/foundation.dart';
import 'yast_api.dart';
import 'saved_app_status.dart';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';

class AllProjectsPanel extends StatefulWidget {
  AllProjectsPanel({Key key, this.title, @required this.theSavedStatus})
      : super(key: key);

  static Color color = Colors.orange[50];
  final String title;
  final SavedAppStatus theSavedStatus;

  @override
  _AllProjectsPanelState createState() => new _AllProjectsPanelState();
}

const int MAXCHARS = 20;

class _AllProjectsPanelState extends State<AllProjectsPanel> {
  _AllProjectsPanelState();

  @override
  Widget build(BuildContext context) {
    return null;
  }

}
