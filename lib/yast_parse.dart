import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'Model/record.dart';
import 'Model/yast_db.dart';
import 'Model/project.dart';
import 'Model/folder.dart';
import 'Model/yast_object.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

enum TypeXmlObject {
  Project,
  Folder,
  Record,
}

const String projectStr = 'project'; //plural
const String folderStr = 'folder';
const String recordStr = 'record';

Future<Map<String, String>> getFoldersFrom(xml.XmlDocument xmlBody) async {
  debugPrint('-------------********** _getFoldersFrom');

  List<xml.XmlElement> xmlObjs = await _getXmlObjectsFrom(xmlBody, folderStr);
  Map<String, String> mapFolderIdName = new Map();
  var retval =
      await _getYastObjectsFrom(mapFolderIdName, TypeXmlObject.Folder, xmlObjs);
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

Future<Map<String, Project>> getProjectsFrom(xml.XmlDocument xmlBody) async {
  List<xml.XmlElement> xmlObjs = _getXmlObjectsFrom(xmlBody, projectStr);
  Map<String, Project> mapProjects = new Map();
  return await _getYastObjectsFrom(
      mapProjects, TypeXmlObject.Project, xmlObjs);
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
Future<Map<String, Record>> getRecordsFrom(xml.XmlDocument xmlBody) async {
  //return _getXmlObjectsFrom(xmlBody, "record");
  debugPrint('==========_getRecordsFrom');
  List<xml.XmlElement> xmlObjs = _getXmlObjectsFrom(xmlBody, "record");
  if (null != YastDb.LIMITCOUNTOFRECORDS) {
    xmlObjs.length = YastDb.LIMITCOUNTOFRECORDS;
  }
  Map<String, dynamic> recs = new Map<String, Record>();
  xmlObjs.forEach((it) {
    Record aRec = new Record.fromXml(it);
    recs[aRec.id] = aRec;
  });
  // This could return the recs before putting them in database.
  // I guess that's okay, but what if i needed to wait?
  // It complains if I try to await _putRecordsInDatabase
//  await putRecordsInDatabase(recs);
  return recs;
} //_getRecordsFrom

Future<void> putRecordsInDatabase(Map<String, dynamic> recs) async {
  // take the things in the variables block
  // that were pulled out in making the Record
  // object and put into the fieldsMap of the
  // Record object. Then store in Firestore db.

  // Brute force delete all the old records and then just add new ones that were retrieved.
  // if the HTTP request to yast.com failed, then we shouldn't get to this point
  // so we won't end up with no records if data connection is lost. (I hope)
  debugPrint('==========_putRecordsInDatabase');

  // TODO chg this to only delete old keys = orphans
//  await _deleteAllDocsInCollection(YastDb.DbRecordsTableName);
  Set<String> oldKeys= await _getKeysOfCollection(YastDb.DbRecordsTableName);

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
    oldKeys.remove(rec.id);

    counter++;
  });
  debugPrint("============== store records count: $counter");
  debugPrint("============== list of record keys to delete: $oldKeys");

  _selectivelyDeleteFromCollection(YastDb.DbRecordsTableName, oldKeys );

  await (((batch
      .commit()
      .timeout(Duration(seconds: Constants.HTTP_TIMEOUT)))))
      .then((void it) {
    debugPrint('records batch result ');
  }).whenComplete(() {
    debugPrint('records batch complete');
  });
} // _putRecordsInDatabase

/// a List of the keys of the named collection in Firebase Cloud Firestore
Future<Set<String>> _getKeysOfCollection(String collectionName) async {
  debugPrint('-------------**********_getKeysOfCollection');
  // TODO a try-catch since for most database errors in deleting old
  // stuff, we want to continue on.
  Query query = Firestore.instance.collection(collectionName);
  QuerySnapshot qss = await query.getDocuments();
  Set<String> retval = new Set();
  qss.documents.forEach((docSnap) {
    docSnap.data.keys;
    int startchar = 1+ docSnap.reference.path.indexOf('/', 0);
    String id = docSnap.reference.path.substring(startchar,docSnap.reference.path.length);
    retval.add( id );
  });
  return retval;
} //_getKeysOfACollection

/// Delete only records matching these keys from the named collection
Future<void> _selectivelyDeleteFromCollection(String collectionName, Set<String> theTargets) async {
  int counter=0;
  debugPrint("selectively delete these records: $theTargets");
  WriteBatch batch = Firestore.instance.batch();
  theTargets.forEach((String key) {
      if ((counter % YastDb.BATCHLIMIT) == 0) {
        batch.commit();
        batch = Firestore.instance.batch();
        debugPrint("====mid way DELETE records count: $counter");
      }
      DocumentReference dr =
      Firestore.instance.document('${YastDb.DbRecordsTableName}/$key');
      batch.delete(dr);

      counter++;
    });
  await (batch
      .commit()
      .timeout(Duration(seconds: Constants.HTTP_TIMEOUT)) )
      .then((void it) {
    debugPrint('records batch result ');
  }).whenComplete(() {
    debugPrint('records batch complete');
  });
}

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
Future<Map<String, dynamic>> _getYastObjectsFrom(
    Map<String, dynamic> mapYastObjects,
    TypeXmlObject whichOne,
    //   String tableName,
    List<xml.XmlElement> xmlObjs) async {
  debugPrint("---------_getYastObjectsFrom");

  String tableName;
  tableName = (whichOne == TypeXmlObject.Project)
      ? YastDb.DbProjectsTableName
      : YastDb.DbFoldersTableName;

  var oldMap = new List.from(mapYastObjects.keys);

//  List<YastObject> objects = new List<YastObject>();

  xmlObjs.forEach((it) {
    var obj;

    if (whichOne == TypeXmlObject.Folder) {
      obj = new Folder.fromXml(it);
    } else {
      obj = new Project.fromXml(it);
    }
//    mapIdToYastObjects[obj.id] = obj.name;
    mapYastObjects[obj.id] = obj;
    oldMap.remove(obj.id);
  });
  debugPrint(mapYastObjects.toString());

  // remove old
  // TODO change to a batch operation
  oldMap.forEach((mapObj){
    DocumentReference dr =
        Firestore.instance.document('$tableName/${mapObj.key}');
    dr.delete();
  });

  WriteBatch batch = Firestore.instance.batch();
  mapYastObjects.values.forEach((obj) async {

    DocumentReference dr = Firestore.instance.document('$tableName/${obj.id}');
    batch.setData(dr, {
      YastObject.FIELDSMAPID: obj.id,
      YastObject.FIELDSMAPNAME: obj.name,
      YastObject.FIELDSMAPDESCRIPTION: obj.description,
      YastObject.FIELDSMAPPRIMARYCOLOR: obj.primaryColor,
      YastObject.FIELDSMAPPARENTID: obj.parentId,
      YastObject.FIELDSMAPPRIVILEGES: obj.privileges,
      YastObject.FIELDSMAPTIMECREATED: obj.timeCreated,
      YastObject.FIELDSMAPCREATOR: obj.creator,
      YastObject.FIELDSMAPFLAGS: obj.flags,
    });
  });
  await ( batch.commit().timeout(Duration(seconds: 30))).then((void it) {
    debugPrint('batch done ');
  }).whenComplete(() {
    debugPrint('batch complete');
  });
//    if (whichOne == TypeXmlObject.Folder) {
//      await _arrangeFoldersInHeirarchy();
//    }
  debugPrint("---------END _getYastObjectsFrom");

//  return mapIdToYastObjects;
  return mapYastObjects;
} //_getYastObjectsFrom
