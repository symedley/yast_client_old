import 'dart:math';
import 'Model/record.dart';
import 'utilities.dart';
import 'yast_parse.dart';
import 'Model/yast_db.dart';

// create copies of records going out into the future.
// plausible fakes.
// These must go into the database and be entered using the yast api
void createFutureRecords( Map<String, Record> records) async {
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
  int recordCount = 0;
  while (count < 5) {
    //does this modify fakeDAte?
    fakeTime = fakeDay.add(new Duration( hours: 7));

    if ((recordCount % YastDb.FAKERECORDSBATCHLIMIT) == 0) {
      await putRecordsInDatabase(newFakeRecords);
      newFakeRecords.clear();
    }
    recsToCopy.forEach((rec) {
      recordCount++;
      Record fakeRecord = Record.clone(rec);
      fakeRecord.startTime = fakeTime;
      fakeRecord.startTimeStr = dateTimeToYastDate(fakeRecord.startTime);
      int randomInt = (rng.nextInt(15) +1) * 5;
      Duration randomDur = Duration(minutes: randomInt);
      fakeTime = fakeTime.add(randomDur);
      fakeRecord.endTime = fakeTime;
      fakeRecord.endTimeStr = dateTimeToYastDate(fakeRecord.endTime);
      String fakeKey = fakeRecord.id + (count.toString());
      fakeRecord.id = fakeKey;
      fakeRecord.yastObjectFieldsMap[Record.FIELDSMAPID] = fakeKey;
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
  if (true) {
    await putRecordsInDatabase(newFakeRecords);
    newFakeRecords.clear();
  }
  return ;
} // create fake records
