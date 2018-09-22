import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import 'saved_app_status.dart';
import 'display_login_status.dart';

class TimelinePanel extends StatefulWidget {
  TimelinePanel({Key key, this.title, this.theSavedState}) : super(key: key);

  final String title;

  _TimelinePanelState createState() =>
      new _TimelinePanelState();

  final SavedAppStatus theSavedState;

}

class _TimelinePanelState extends State {

  @override
  Widget build(BuildContext context) {
    return displayLoginStatus(
    );
  }
}