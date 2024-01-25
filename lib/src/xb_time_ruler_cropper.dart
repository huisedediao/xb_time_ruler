import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class XBTimeRulerCropper {
  /// 起始位置的百分比
  final double startOffsetPercent;

  /// 结束位置的百分比
  final double endOffsetPercent;

  /// 纵向线宽
  final double lineWidtV;

  /// 横向线宽
  final double lineWidthH;

  /// 颜色
  final Color color;

  /// 颜色
  final Color defaultArrowColor;

  /// 左侧的图片
  final ui.Image? leftImg;

  /// 右侧的图片
  final ui.Image? rightImg;

  double _touchValidAreaScale(double totalW) => lineWidtV * 0.5 / totalW;

  /// 是否在左侧区域
  bool isInLeftArea(double percent, double totalW) {
    final touchValidAreaScale = _touchValidAreaScale(totalW);
    return (percent - startOffsetPercent + touchValidAreaScale).abs() <
        touchValidAreaScale;
  }

  /// 是否在右侧区域
  bool isInRightArea(double percent, double totalW) {
    final touchValidAreaScale = _touchValidAreaScale(totalW);
    return (percent - endOffsetPercent - touchValidAreaScale).abs() <
            touchValidAreaScale &&
        !isInLeftArea(percent, totalW);
  }

  bool isInCenterArea(double percent, double totalW) {
    return percent >= startOffsetPercent &&
        percent <= endOffsetPercent &&
        !isInLeftArea(percent, totalW) &&
        !isInRightArea(percent, totalW);
  }

  XBTimeRulerCropper copy(
      {double? newStartOffsetPercent, double? newEndOffsetPercent}) {
    late double newStart;
    late double newEnd;
    if (newStartOffsetPercent == null && newEndOffsetPercent != null) {
      newStart = startOffsetPercent;
      if (newEndOffsetPercent < newStart) {
        newEnd = newStart;
      } else {
        newEnd = newEndOffsetPercent;
      }
    } else if (newStartOffsetPercent != null && newEndOffsetPercent == null) {
      newEnd = endOffsetPercent;
      if (newStartOffsetPercent > newEnd) {
        newStart = newEnd;
      } else {
        newStart = newStartOffsetPercent;
      }
    } else {
      newStart = newStartOffsetPercent ?? startOffsetPercent;
      newEnd = newEndOffsetPercent ?? endOffsetPercent;
    }

    return XBTimeRulerCropper(
        startOffsetPercent: newStart,
        endOffsetPercent: newEnd,
        lineWidtV: lineWidtV,
        leftImg: leftImg,
        rightImg: rightImg);
  }

  XBTimeRulerCropper(
      {required this.startOffsetPercent,
      required this.endOffsetPercent,
      this.lineWidtV = 25,
      this.lineWidthH = 5,
      this.leftImg,
      this.color = Colors.red,
      this.defaultArrowColor = Colors.black,
      this.rightImg});
}
