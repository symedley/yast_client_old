import 'package:flutter/widgets.dart';

class Constants {
//  static const String referenceDay = '2018-11-13';
  static const String referenceDay = '2018-11-20';
  static const String firstFakeRecordsDay = '2018-11-21';
  static const int fakeDayMorningStartTime = 7;

  // retrieve records around the preferredDate. Go back this many days and forward this many days.
  static const int defaultGoBackThisManyDays = 10;
  static const int defaultGoForwardThisManyDays = 10;

  static const int HTTP_TIMEOUT = 90; //seconds
  static const double BORDERRADIUS = (32.0);
  static const double EDGEINSETS = 16.0;
  static const Color COLOR = Color(0x88ffffff);
  static const String COLORSTRING = 'xffffff';
  static const String PIECHARTNAME = 'where time went';
  static const double PIECONTAINERWIDTH = 300.0;
  static const double EMPTYPIECIRCLEWIDTH = 260.0;

  static const Color dateChooserButtonColor = Color(0xff9e9e9e); //Colors.grey[300];??
  static const Color deleteButtonColor = Color(0xffFF0000);

  static const String emptyPieChartMessage = 'No data for this day';

}
