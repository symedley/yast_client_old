import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'yast_db.dart';
import '../constants.dart';

Future<Map<String,String>>getProjectIdMapFromDb() async {
  Map idToProjectName = new Map<String, String>();
  try {
    WriteBatch batch = Firestore.instance.batch();
    QuerySnapshot qs = await Firestore.instance
        .collection(YastDb.DbProjectsTableName)
        .getDocuments();

    qs.documents.forEach((DocumentSnapshot doc) {
      idToProjectName
          .addAll({doc.data['id']: doc.data['name']}.cast<String, String>());
      DocumentReference dr =
          Firestore.instance.document('/${YastDb.DbIdToProjectTableName}/${doc.data["id"]}');
      batch.setData(dr, {doc.data['id']: doc.data['name']});
    });

    await batch
        .commit()
        .timeout(Duration(seconds: Constants.HTTP_TIMEOUT))
        .then((it) {
      debugPrint('id to project map batch result $it');
    }).whenComplete(() {
      debugPrint('id to project map batch complete');
    });
  } catch (e) {
    print('Failed to retrieve projects from db and creat  id name map');
    print(e);
  }
  return idToProjectName;
}
