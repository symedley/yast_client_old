import 'package:xml/xml/nodes/element.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// One Project object represents one Project from
/// Yast's database.
///
/// Projects are user defined types of work. They can be organized in folders
/// and subfolders. They have user-assigned colors.
abstract class YastObject {
  //
  //  fields from their API documentation:
//  id : Unique id of the project
//  name : Name of the project
//  description : Project description
//  primaryColor : Primary color associated with the project
//  parentId : Id of group if project has parent group or 0 if project is not in a group
//  privileges : Privileges the current user has on this project
//  timeCreated : Time of creation [seconds since 1st of January 1970]
//  creator : Id of the user that created this project
  static const String ID = "id";
  static const String NAME = "name";
  static const String DESCRIPTION = "description";
  static const String PRIMARYCOLOR = "primaryColor";
  static const String PARENTID = "parentId";
  static const String PRIVILEGES = "privileges";
  static const String TIMECREATED =
      "timeCreated"; // Strings can be replaced with other types later.
  static const String CREATOR = "creator";

  String id;
  String name;
  String description;
  String primaryColor;
  String parentId;
  String privileges;
  String timeCreated; // Strings can be replaced with other types later.
  String creator;

  Map<String, String> yastObjectFieldsMap = new Map();

  YastObject(XmlElement xmlElement, String objectType) {
    assert(xmlElement.name.local == objectType);

    xmlElement.children.forEach((it) {
      try {
        try {
          if (it.nodeType == xml.XmlNodeType.ELEMENT) {
//            (it as XmlElement).name;
            yastObjectFieldsMap.addAll(
                {(it as XmlElement).name.toString(): it.children.first.text});
          }
        } catch (e) {
          debugPrint(e);
        }
        if (it.children.length > 0) {
          this.id = yastObjectFieldsMap[ID];
          this.name = yastObjectFieldsMap[NAME];
          this.description = yastObjectFieldsMap[DESCRIPTION];
          this.primaryColor = yastObjectFieldsMap[PRIMARYCOLOR];
          this.parentId = yastObjectFieldsMap[PARENTID];
          this.privileges = yastObjectFieldsMap[PRIVILEGES];
          this.timeCreated = yastObjectFieldsMap[TIMECREATED];
          this.creator = yastObjectFieldsMap[CREATOR];
        }
      } catch (e) {
        debugPrint(e);
      }
    });
  }

  YastObject.fromDocSnap(DocumentSnapshot docSnap, String objectType) {
    try {
      docSnap.data.forEach((String key, dynamic value) {
        try {
          yastObjectFieldsMap[key] = value;
        } catch (e) {
          debugPrint(e);
          throw (e);
        }
      });
      if (docSnap.data.length > 0) {
        this.id = yastObjectFieldsMap[ID];
        this.name = yastObjectFieldsMap[NAME];
        this.description = yastObjectFieldsMap[DESCRIPTION];
        this.primaryColor = yastObjectFieldsMap[PRIMARYCOLOR];
        this.parentId = yastObjectFieldsMap[PARENTID];
        this.privileges = yastObjectFieldsMap[PRIVILEGES];
        this.timeCreated = yastObjectFieldsMap[TIMECREATED];
        this.creator = yastObjectFieldsMap[CREATOR];
      }
    } catch (e) {
      debugPrint(e);
      throw (e);
    }
  }

  String toString() {
    return this.name + ":   " + this.description;
  }
}
