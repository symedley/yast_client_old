import 'dart:math';
import 'package:intl/intl.dart';
import 'Model/record.dart';
import 'saved_app_status.dart';
import 'utilities.dart';

// create copies of records going out into the future.
// plausible fakes.
// These must go into the database and be entered using the yast api
Map<String, Record> createFutureRecords( Map<String, Record> records) {
  DateTime startReferenceDay = DateTime.parse('2018-10-24 00:00:00');
  DateTime endReferenceDay = DateTime.parse('2018-10-24 23:59:00');
  List<Record> recsToCopy = new List();
  records.forEach((String key, Record value) {
    DateTime start = value.startTime;
    // ignore end time for now
    if ((start.compareTo(startReferenceDay) > 0) &&
        (start.compareTo(endReferenceDay) < 0)) {
      recsToCopy.add(value);
    }
  });
  int count = 0;
  Map<String, Record> newFakeRecords = new Map();
  DateTime fakeDay = DateTime.now();
  fakeDay = DateTime(fakeDay.year, fakeDay.month, fakeDay.day);
  DateTime fakeTime;
  var rng = new Random();
  while (count < 365) {
    //does this modify fakeDAte?
    fakeTime = fakeDay.add(new Duration( hours: 7));
    recsToCopy.forEach((rec) {
      Record fakeRecord = Record.clone(rec);
      fakeRecord.startTime = fakeTime;
      fakeRecord.startTimeStr = dateTimeToYastDate(fakeRecord.startTime);
      int randomInt = (rng.nextInt(15) +1) * 5;
      Duration randomDur = Duration(minutes: randomInt);
      fakeTime = fakeTime.add(randomDur);
      fakeRecord.endTime = fakeTime;
      String fakeKey = fakeRecord.id + (count.toString());
      fakeRecord.id = fakeKey;
//      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPPROJECTID] = fakeKey;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPTIMEFROM] = fakeRecord.startTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPTIMETO] = fakeRecord.endTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPSTARTTIME] = fakeRecord.startTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPENDTIME] = fakeRecord.endTimeStr;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPISRUNNING] = '0';
      newFakeRecords[fakeKey] = fakeRecord;
    });
    fakeDay = fakeDay.add(new Duration(days: 1));
    count++;
  }
  return newFakeRecords;
} // create fake records
