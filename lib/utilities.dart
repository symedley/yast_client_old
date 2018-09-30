import 'package:flutter/material.dart';

/// Construct a color from a hex code string, of the format #RRGGBB.
///  optional transparency, defaults to 0x88000000
Color hexToColor(String code, {int transparency = 0x880000000}) {
  try {
    return new Color(int.parse(code.substring(1, 7), radix: 16) &
    (transparency ));
  } catch (e) {
    return Color(0x88ffffffff);
  }
}
