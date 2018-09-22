import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;

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

///_getRecordsFrom
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
Future<Map<String, dynamic>> _getRecordsFrom(xml.XmlDocument xmlBody) async {
}

/// getYastObjectsFrom - most of the logic in getYastProjects and getYastFoldesr
/// is the same.
/// returns the Map that was passed in.
Future<Map<String, String>> _getYastObjectsFrom(
    Map<String, String> mapIdToYastObjects,
    TypeXmlObject whichOne,
    //   String tableName,
    List<xml.XmlElement> xmlObjs) async {}

