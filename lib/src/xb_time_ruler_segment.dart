import 'package:flutter/material.dart';

class XBTimeRulerSegment {
  final double left;
  final double width;
  final bool isFirst;
  final bool isLst;
  final double markHeight;
  final double markWidth;
  final Color markColor;
  final int level;
  final String? text;
  final Color color;
  final double fontSize;

  XBTimeRulerSegment(
      {required this.left,
      required this.width,
      required this.isFirst,
      required this.isLst,
      required this.markHeight,
      required this.markWidth,
      required this.markColor,
      required this.level,
      this.text,
      this.color = Colors.white,
      this.fontSize = 12});
}
