import 'package:flutter/material.dart';

/// Construct a color from a hex code string, of the format #RRGGBB.
///  optional transparency, defaults to 0x88000000
Color hexToColor(String code, {transparency: int}) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) +
      (transparency ??= 0x88000000) - code.length);
}
