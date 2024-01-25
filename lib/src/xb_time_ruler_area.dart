import 'package:flutter/material.dart';

class XBTimeRulerArea {
  /// 起始位置的百分比
  final double startOffsetPercent;

  /// 结束位置的百分比
  final double endOffsetPercent;

  final bool isAvailable;

  /// 颜色
  final Color color;

  bool isInSide(double value) {
    return startOffsetPercent <= value && value <= endOffsetPercent;
  }

  XBTimeRulerArea(
      {required this.startOffsetPercent,
      required this.endOffsetPercent,
      required this.color,
      this.isAvailable = true});
}
