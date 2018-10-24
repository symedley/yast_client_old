import 'package:flutter/material.dart';


// Constants
//
// for DateTime conversion, since yast uses seconds from epoch
const million = 1000000;
const dateConversionFactor = million;


// convert yast date string to a DateTime
DateTime yastTimetoDateTime(String dateTimeString) {
  DateTime retval;
  try {
    int millisecondsSinceEpoch = int.parse(dateTimeString) *
        dateConversionFactor;
    retval = new DateTime.fromMillisecondsSinceEpoch(
        millisecondsSinceEpoch);
  } catch (e) {
    debugPrint(e);
    debugPrint("------failure converting date-------");
    return null;
  }
  return retval;
}

String dateTimeToYastDate(DateTime inputDate) {
  String retval;
  try{
    double tmp = inputDate.millisecondsSinceEpoch / dateConversionFactor;
    retval = tmp.toString();
  }
  catch(e) {
    debugPrint(e);
    debugPrint("------failure converting date to string-------");
    return null;
  }
  return retval;
}

/// Construct a color from a hex code string, of the format #RRGGBB.
///  optional transparency, defaults to 0x88000000
Color hexToColor(String code, {int transparency = 0xff0000000}) {
  Color retval;
  debugPrint("hexToColor: $code transparency: $transparency ............");
  try {
    retval =  new Color(int.parse(code.substring(1, 7), radix: 16) |
    (transparency));
  } catch (e) {
    retval =  Color(0xffffffffff);
  }
  debugPrint("hexToColor: $retval ............");
  return retval;
}

void showSnackbar(BuildContext scaffoldContext, String theMesg) {
  final snackBar = SnackBar(
    content: Text(theMesg),
    action: SnackBarAction(
      label: 'OK',
      onPressed: () {
        // Some code to undo the change!
      },
    ),
  );
  Scaffold.of(scaffoldContext).showSnackBar(snackBar);
}