
/// Just organizing hte database stuff
class YastDb {
  static const DbProjectsTableName = "projects_";
  static const DbFoldersTableName = "folders_";
  static const DbRecordsTableName = "records_";
  static const DbIdToProjectTableName = 'idToProjectMap_';


  static const int BATCHLIMIT = 500;

  // for debugging, reduce the number of records to something
  // that i can examine under a debugger. Usually, I get 600+ records.
  static const LIMITCOUNTOFRECORDS = null;

}
