import 'package:xml/xml.dart' as xml;
import 'yast_object.dart';

/// One Project object represents one Project from
/// Yast's database.
///
/// Projects are user defined types of work. They can be organized in folders
/// and subfolders. They have user-assigned colors.
class Folder extends YastObject {
  //
  //  fields from yast API documentation
  // are inherited from abstract superclass
//  id : Unique id of the project
//  name : Name of the project
//  description : Project description
//  primaryColor : Primary color associated with the project
//  parentId : Id of group if project has parent group or 0 if project is not in a group
//  privileges : Privileges the current user has on this project
//  timeCreated : Time of creation [seconds since 1st of January 1970]
//  creator : Id of the user that created this project

  static const String __object = "folder";

  Folder.fromXml(xml.XmlElement xmlElement)
      : super.fromXml(xmlElement, __object);

  // this is so i can pass this method as a paramter
  static Folder fromXmlConstructor(xml.XmlElement xmlEl) => new Folder.fromXml(xmlEl);
}
