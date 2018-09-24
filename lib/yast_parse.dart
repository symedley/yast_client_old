import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'Model/record.dart';
import 'Model/yast_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeXmlObject {
  Project,
  Folder,
}

const String projectStr = 'project'; //plural
const String folderStr = 'folder';

Future<Map<String, String>> _getFoldersFrom(xml.XmlDocument xmlBody) async {
  debugPrint('-------------********** _getFoldersFrom');

  List<xml.XmlElement> xmlObjs = await _getXmlObjectsFrom(xmlBody, folderStr);
  Map<String, String> mapFolderIdName = new Map();
  var retval = await _getYastObjectsFrom(
      mapFolderIdName, TypeXmlObject.Folder, xmlObjs);
  debugPrint('-------------**********END  _getFoldersFrom');
  return retval;
}

/// _getXmlObjectsFrom gets Projects or Folders out of this
/// Xml element. The element must be named folder or project
/// and its children are the items of that type.
List<xml.XmlElement> _getXmlObjectsFrom(
    xml.XmlDocument xmlBody, String objType) {
  Iterable iterable = xmlBody.findAllElements(objType).map((obj) {
    return obj;
  });
  List<xml.XmlElement> xmlObjectList = new List<xml.XmlElement>();
  iterable.forEach((dynamic it) {
    xmlObjectList.add(it);
  });
  return xmlObjectList;
}


Future<Map<String, String>> _getProjectsFrom(xml.XmlDocument xmlBody) async {
  List<xml.XmlElement> xmlObjs = _getXmlObjectsFrom(xmlBody, projectStr);
  Map<String, String> mapProjectIdName = new Map();
  return await _getYastObjectsFrom(
      mapProjectIdName, TypeXmlObject.Project, xmlObjs);
}

///getRecordsFrom
///
// id(optional): Comma separated list of requested record identifiers
//  user(required): Yast user
//  hash(required): Yast user hash
//  parentId(optional) : Comma separated list of Ids of the project requested records belong to.
//  typeId(optional) : Id of the recordType object describing this record
//  timeFrom(optional) : Time of creation [seconds since 1st of January 1970]
//  timeTo(optional) : Time of last update [seconds since 1st of January 1970]
//  userId(optional) : Only relevant for usage through Entity API as Organization. Comma separated list of user identifiers for requested records
//
//  Work Record
//  A record is a work record if the typeId field is 1. A work record has the following variables in the variables array :
//
//  startTime : Start-time of record [seconds since 1st of January 1970]
//  endTime : End-time of record [seconds since 1st of January 1970]
//  comment : String with comment for record
//  isRunning : 1 if the record is running. In that case endTime has not been set yet. Else 0
///getRecordsFrom
///
// id(optional): Comma separated list of requested record identifiers
//  user(required): Yast user
//  hash(required): Yast user hash
//  parentId(optional) : Comma separated list of Ids of the project requested records belong to.
//  typeId(optional) : Id of the recordType object describing this record
//  timeFrom(optional) : Time of creation [seconds since 1st of January 1970]
//  timeTo(optional) : Time of last update [seconds since 1st of January 1970]
//  userId(optional) : Only relevant for usage through Entity API as Organization. Comma separated list of user identifiers for requested records
//
//  Work Record
//  A record is a work record if the typeId field is 1. A work record has the following variables in the variables array :
//
//  startTime : Start-time of record [seconds since 1st of January 1970]
//  endTime : End-time of record [seconds since 1st of January 1970]
//  comment : String with comment for record
//  isRunning : 1 if the record is running. In that case endTime has not been set yet. Else 0
Future<Map<String, dynamic>> getRecordsFrom(xml.XmlDocument xmlBody) async {
  //return _getXmlObjectsFrom(xmlBody, "record");
  debugPrint('==========_getRecordsFrom');
  List<xml.XmlElement> xmlObjs = _getXmlObjectsFrom(xmlBody, "record");
  if (null != YastDb.LIMITCOUNTOFRECORDS) {
    xmlObjs.length = YastDb.LIMITCOUNTOFRECORDS;
  }
  Map<String, dynamic> recs = new Map<String, dynamic>();
  xmlObjs.forEach((it) {
    Record aRec = new Record.fromXml(it);
    recs[aRec.id] = aRec;
  });
  // This could return the recs before putting them in database.
  // I guess that's okay, but what if i needed to wait?
  // It complains if I try to await _putRecordsInDatabase
  await _putRecordsInDatabase(recs);
  return recs;
} //_getRecordsFrom

Future<void> _putRecordsInDatabase(Map<String, dynamic> recs) async {
  // take the things in the variables block
  // that were pulled out in making the Record
  // object and put into the fieldsMap of the
  // Record object. Then store in Firestore db.

  // Brute force delete all the old records and then just add new ones that were retrieved.
  // if the HTTP request to yast.com failed, then we shouldn't get to this point
  // so we won't end up with no records if data connection is lost. (I hope)
  debugPrint('==========_putRecordsInDatabase');

  await _deleteAllDocsInCollection(YastDb.DbRecordsTableName);

  int counter = 0;

  WriteBatch batch = Firestore.instance.batch();
  recs.values.forEach((rec) async {
    if ((counter % YastDb.BATCHLIMIT) == 0) {
      batch.commit();
      batch = Firestore.instance.batch();
      debugPrint("====mid way store records count: $counter");
    }
    DocumentReference dr =
    Firestore.instance.document('${YastDb.DbRecordsTableName}/${rec.id}');
    batch.setData(dr, rec.yastObjectFieldsMap);

    counter++;
  });
  debugPrint("============== store records count: $counter");

  await batch.commit().timeout(Duration(seconds: 30)).then((it) {
    debugPrint('records batch result $it');
  }).whenComplete(() {
    debugPrint('records batch complete');
  });
} // _putRecordsInDatabase

/// Brute force delete all documents in a collection of the given name.
/// A utility function.
Future<void> _deleteAllDocsInCollection(String collectionName) async {
  debugPrint('-------------**********_deleteAllDocsInCollection');
  // TODO a try-catch since for most database errors in deleting old
  // stuff, we want to continue on.
  Query query = Firestore.instance.collection(collectionName);
  int counter = 0;
  WriteBatch batchDelete = Firestore.instance.batch();
  QuerySnapshot qss = await query.getDocuments();
  qss.documents.forEach((snap) async {
    if ((counter % YastDb.BATCHLIMIT) == 0) {
      batchDelete.commit();
      batchDelete = Firestore.instance.batch();
      debugPrint("====mid way deletion count: $counter");
    }
    if (collectionName == 'folders') {
      debugPrint('-------------**********these docs are folders');

      Query querySubCollections = await snap.reference.collection('children');
      QuerySnapshot subcollectionSnap =
      await querySubCollections.getDocuments();
      subcollectionSnap.documents.forEach((subSnap) async {
        await subSnap.reference.delete();
      });
    }
    batchDelete.delete(snap.reference);
    counter++;
  });
  batchDelete.commit();
  debugPrint("============== _deleteAllDocsInCollection count: $counter");
} //_deleteAllDocsInCollection

/// getYastObjectsFrom - most of the logic in getYastProjects and getYastFoldesr
/// is the same.
/// returns the Map that was passed in.
Future<Map<String, String>> _getYastObjectsFrom(
    Map<String, String> mapIdToYastObjects,
    TypeXmlObject whichOne,
    //   String tableName,
    List<xml.XmlElement> xmlObjs) async {}

