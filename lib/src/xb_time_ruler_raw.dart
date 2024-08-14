import 'package:flutter/material.dart';
import 'package:xb_time_ruler/src/xb_time_ruler_area.dart';
import 'package:xb_time_ruler/src/xb_time_ruler_cropper.dart';
import 'package:xb_time_ruler/src/xb_time_ruler_segment.dart';

class XBTimeRulerRaw extends StatefulWidget {
  /// 每级的格子数，举例：[3,5]，代表第一级有3格，第二级有5格
  final List<int> levelSegments;

  /// 每个刻度的文字，第几个元素就代表第几级的刻度的文字列表，再根据刻度的索引从列表中查找对应的文字
  /// 如果列表没找到或者文字没找到，默认则什么文字也不绘制
  /// [["00:00","01:00","02:00"],[]]
  final List<List<String>>? levelTitles;

  /// 第一级刻度的间距
  final double topLevelMarkGap;

  /// 偏移量百分比，用于在缩放时固定当前位置
  final double offsetPercent;

  /// 最大的偏移百分比，用于限制滚动范围
  final double maxOffsetPercent;

  /// 颜色区域
  final List<XBTimeRulerArea> areas;

  /// 覆盖的层，用于视频段落截取
  final XBTimeRulerCropper? cropper;

  /// 底部刻度是否需要为cropper留出底部空隙
  final bool needAdaptCroper;

  /// -------------------------------以下不需要更新----------------------------------

  /// 改变刻度的回调，参数为当前偏移量百分比
  final ValueChanged<double>? onChanged;

  /// 滚动结束回调
  final ValueChanged<double>? onScrollEnd;

  /// 刻度文字的大小
  final double? levelTitleFontSize;

  /// 刻度文字的颜色
  final Color? levelTitleColor;

  /// 第一级刻度的高度（之后每级递减）
  final double topLevelMarkHeight;

  /// 下级相对于上级的高度
  final double markHeightFactor;

  /// 整改卡尺的高度
  final double height;

  /// 卡尺的背景颜色
  final Color bgColor;

  /// 标记的颜色
  final Color markColor;

  /// 每个标记的宽度
  final double markWidth;

  /// 中心线颜色
  final Color centerLineColor;

  /// 中心线宽度
  final double centerLineWidth;

  const XBTimeRulerRaw(
      {required this.levelSegments,
      required this.topLevelMarkHeight,
      required this.topLevelMarkGap,
      required this.areas,
      this.cropper,
      this.levelTitleColor,
      this.levelTitleFontSize,
      this.levelTitles,
      this.markHeightFactor = 0.5,
      this.offsetPercent = 0,
      this.maxOffsetPercent = 1,
      this.onChanged,
      this.onScrollEnd,
      this.height = 50,
      this.bgColor = Colors.black,
      this.markColor = Colors.grey,
      this.markWidth = 1,
      this.centerLineColor = Colors.white,
      this.centerLineWidth = 1.0,
      this.needAdaptCroper = false,
      super.key});
  @override
  State<XBTimeRulerRaw> createState() => XBTimeRulerRawState();
}

class XBTimeRulerRawState extends State<XBTimeRulerRaw> {
  ScrollController? _scrollController;

  /// SingleChildScrollView的key，用于重新构建
  int _keySingleChildScrollView = 1;

  late List<int> _levelSegments;

  late List<List<String>>? _levelTitles;

  late double _topLevelMarkGap;

  late double _offsetPercent;

  late double _maxOffsetPercent;

  late List<XBTimeRulerArea> _areas;

  late XBTimeRulerCropper? _cropper;

  /// 用于控制是否可以滚动
  bool _scrollAble = true;

  @override
  void initState() {
    super.initState();
    _levelSegments = widget.levelSegments;
    _levelTitles = widget.levelTitles;
    _topLevelMarkGap = widget.topLevelMarkGap;
    _offsetPercent = widget.offsetPercent;
    _maxOffsetPercent = widget.maxOffsetPercent;
    _areas = widget.areas;
    _cropper = widget.cropper;

    _buildScrollController();
  }

  void updateMaxOffsetPercent(double newValue) {
    if (_maxOffsetPercent == newValue) return;
    _maxOffsetPercent = newValue;
    setState(() {
      /// 如果当前偏移的百分比超过_maxOffsetPercent，则跳转到_maxOffsetPercent
      if (_offsetPercent > _maxOffsetPercent) {
        updatedOffsetPercent(_maxOffsetPercent);
      }
    });
  }

  bool get isAtMaxOffset => _offsetPercent >= _maxOffsetPercent;

  double get offsetPercent => _offsetPercent;

  void updateCover(XBTimeRulerCropper? newValue) {
    setState(() {
      _cropper = newValue;
    });
  }

  void updatedOffsetPercent(double newValue) {
    if (_offsetPercent == newValue || newValue > _maxOffsetPercent) return;
    _offsetPercent = newValue;

    /// 因为滚动完成的回调是在NotificationListener中监听的，这里延迟一下避免滚动不生效
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController?.hasClients ?? false) {
        _scrollController?.animateTo(_calculateOffset,
            duration: const Duration(milliseconds: 300), curve: Curves.linear);
      }
    });
  }

  void updatedScrollAble(bool newValue) {
    if (_scrollAble == newValue) return;
    _buildScrollController();
    _scrollAble = newValue;
    _rebuildScrollView();
  }

  void updateAreas(List<XBTimeRulerArea> areas) {
    _areas = areas;
    _buildScrollController();
    _rebuildScrollView();
  }

  double currentPercent() {
    _caculateOffsetPercent();
    return _offsetPercent;
  }

  void updateProperties(
      {required List<int> levelSegments,
      required List<List<String>> levelTitles,
      required double topLevelMarkGap,
      required List<XBTimeRulerArea> areas}) {
    setState(() {
      _levelSegments = levelSegments;
      _levelTitles = levelTitles;
      _topLevelMarkGap = topLevelMarkGap;
      _areas = areas;
      _buildScrollController();
      _rebuildScrollView();
    });
  }

  @override
  Widget build(BuildContext context) {
    final segments = _generateSegments(
        fatherLevelW: calculateTotalWidth,
        level: 0,
        startPosition: 0,
        fatherTitle: null);
    double screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollStartNotification) {
              // print('开始滚动');
            } else if (notification is ScrollUpdateNotification) {
              // print('正在滚动');
            } else if (notification is ScrollEndNotification) {
              // print('滚动结束');
              if (widget.onScrollEnd != null) {
                widget.onScrollEnd!(_offsetPercent);
              }
            } else if (notification is OverscrollNotification) {
              // print('滚动到边界');
            }
            return true; // 返回true，以阻止通知冒泡，返回false，以允许通知继续向上冒泡
          },
          child: SingleChildScrollView(
            key: ValueKey(_keySingleChildScrollView),
            physics: _scrollAble ? null : const NeverScrollableScrollPhysics(),
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Container(
              height: widget.height,
              width: calculateTotalWidth + screenWidth,
              color: widget.bgColor,
              child: Padding(
                padding: EdgeInsets.only(
                    left: screenWidth * 0.5, right: screenWidth * 0.5),
                child: CustomPaint(
                    painter: XBTimeRulesPainter(
                        segments: segments,
                        areas: _areas,
                        isSegmentInScreen: _isSegmentInScreen,
                        cropper: _cropper,
                        needAdaptCroper: widget.needAdaptCroper)),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.5),
          child: Container(
            height: widget.height,
            color: widget.centerLineColor,
            width: widget.centerLineWidth,
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  _buildScrollController() {
    if (_scrollController != null) {
      _scrollController?.removeListener(_scrollListener);
      _scrollController?.dispose();
    }
    _scrollController = ScrollController(
      initialScrollOffset: _calculateOffset,
    );

    _scrollController?.addListener(_scrollListener);
  }

  double get _calculateOffset => calculateTotalWidth * _offsetPercent;

  _scrollListener() {
    if (_scrollController == null) return;
    _caculateOffsetPercent();
    if (_offsetPercent > _maxOffsetPercent) {
      _offsetPercent = _maxOffsetPercent;
      _scrollController?.jumpTo(_calculateOffset);
      return;
    }
    widget.onChanged?.call(_offsetPercent);
  }

  _caculateOffsetPercent() {
    double maxScrollExtent = _scrollController!.position.maxScrollExtent;
    double currentScrollPosition = _scrollController!.offset;
    _offsetPercent = currentScrollPosition / maxScrollExtent;
  }

  _rebuildScrollView() {
    setState(() {
      _keySingleChildScrollView++;
      if (_keySingleChildScrollView > 100) {
        _keySingleChildScrollView = 1;
      }
    });
  }

  /// 判断segment是否在屏幕内
  bool _isSegmentInScreen(XBTimeRulerSegment segment) {
    double screenWidth = MediaQuery.of(context).size.width;
    double leftBoundary = (_scrollController?.offset ?? 0) - screenWidth / 2;
    double rightBoundary = (_scrollController?.offset ?? 0) + screenWidth / 2;

    return segment.left + segment.width > leftBoundary &&
        segment.left < rightBoundary;
  }

  double get calculateTotalWidth {
    return _levelSegments[0] * _topLevelMarkGap;
  }

  double _calculateMarkH(int curLevel) {
    double ret = widget.topLevelMarkHeight;
    while (curLevel > 0) {
      ret = ret * widget.markHeightFactor;
      curLevel--;
    }
    return ret;
  }

  List<String>? _getLevelTitles(int level) {
    if (_levelTitles != null && _levelTitles!.length > level && level >= 0) {
      return _levelTitles?[level];
    }
    return null;
  }

  List<XBTimeRulerSegment> _generateSegments(
      {required double fatherLevelW,
      required int level,
      required double startPosition,
      required String? fatherTitle}) {
    List<XBTimeRulerSegment> ret = [];
    if (level >= _levelSegments.length) return ret;
    double markH = _calculateMarkH(level);
    int curLevelSegmentCount = _levelSegments[level];
    double curLevelSegmentWidth = fatherLevelW / curLevelSegmentCount;
    List<String>? curLevelTitleList = _getLevelTitles(level);
    for (int j = 0; j < curLevelSegmentCount; j++) {
      String? text;
      if (curLevelTitleList != null && curLevelTitleList.length > j) {
        text = curLevelTitleList[j];
      }

      if (fatherTitle != null && text != null) {
        if (j == 0) {
          text = "";
        } else {
          if (level == 1) {
            text = "${fatherTitle.substring(0, 3)}$text";
          } else if (level == 2) {
            text = "${fatherTitle.substring(0, 4)}$text";
          }
        }
      }

      /// 因为子级别的第一个title是不显示的，避免孙级别第一个段落内的时间不正确
      String? fatherTitlePara;
      if (text != null) {
        if (text.isEmpty) {
          fatherTitlePara = fatherTitle;
        } else {
          fatherTitlePara = text;
        }
      }

      XBTimeRulerSegment tempSegment = XBTimeRulerSegment(
          left: startPosition + curLevelSegmentWidth * j,
          width: curLevelSegmentWidth,
          isFirst: j == 0,
          isLst: j == curLevelSegmentCount - 1,
          markHeight: markH,
          markWidth: widget.markWidth,
          markColor: widget.markColor,
          level: level,
          text: text,
          color: widget.levelTitleColor ?? Colors.white,
          fontSize: widget.levelTitleFontSize ?? 12);
      ret.add(tempSegment);
      ret.addAll(_generateSegments(
          fatherLevelW: tempSegment.width,
          level: level + 1,
          startPosition: tempSegment.left,
          fatherTitle: fatherTitlePara));
    }
    return ret;
  }
}

class XBTimeRulesPainter extends CustomPainter {
  final List<XBTimeRulerSegment> segments;
  final List<XBTimeRulerArea> areas;
  final Function(XBTimeRulerSegment) isSegmentInScreen;
  final XBTimeRulerCropper? cropper;
  final Paint markPaint = Paint();
  final Paint areaPaint = Paint();
  final Paint textPaint = Paint();
  final bool needAdaptCroper;

  XBTimeRulesPainter(
      {required this.segments,
      required this.areas,
      required this.isSegmentInScreen,
      required this.needAdaptCroper,
      this.cropper});

  @override
  void paint(Canvas canvas, Size size) {
    double coverBottom;
    if (needAdaptCroper) {
      coverBottom = cropper != null ? cropper!.lineWidthH : 0;
    } else {
      coverBottom = 0;
    }

    for (int i = 0; i < segments.length; i++) {
      XBTimeRulerSegment segment = segments[i];

      /// 只渲染需要展示的
      if (!isSegmentInScreen(segment)) continue;
      markPaint
        ..color = segment.markColor
        ..strokeWidth = segment.markWidth;

      // left
      if (segment.level == 0) {
        var startPoint = Offset(segment.left, size.height - coverBottom);
        var endPoint = Offset(
            segment.left, size.height - segment.markHeight - coverBottom);

        canvas.drawLine(startPoint, endPoint, markPaint);
      }

      // right
      if (!segment.isLst || segment.level == 0) {
        var startPoint =
            Offset(segment.left + segment.width, size.height - coverBottom);
        var endPoint = Offset(segment.left + segment.width,
            size.height - segment.markHeight - coverBottom);
        canvas.drawLine(startPoint, endPoint, markPaint);
      }

      // Draw the text
      if (segment.text != null) {
        textPaint.color = segment.color;
        TextSpan span = TextSpan(
            style: TextStyle(color: segment.color, fontSize: segment.fontSize),
            text: segment.text);
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        Offset textOffset = Offset(segment.left,
            size.height - segment.markHeight - tp.height - coverBottom);
        tp.paint(canvas, textOffset);
      }
    }

    // Draw the colored area
    for (int i = 0; i < areas.length; i++) {
      XBTimeRulerArea areaModel = areas[i];
      areaPaint.color = areaModel.color;
      double left = areaModel.startOffsetPercent * size.width;
      double right = areaModel.endOffsetPercent * size.width;
      double top = 0.0;
      double bottom = size.height - coverBottom;
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), areaPaint);
    }

    // Draw the cover
    if (cropper != null) {
      // Paint coverPaint = Paint()
      //   ..color = Colors.red
      //   ..style = PaintingStyle.stroke
      //   ..strokeWidth = cover!.lineWidtV;

      // double left =
      //     cover!.startOffsetPercent * size.width - cover!.lineWidtV * 0.5;
      // double right =
      //     cover!.endOffsetPercent * size.width + cover!.lineWidtV * 0.5;
      // double top = -coverPaint.strokeWidth * 0.5 + coverBottom;
      // double bottom = size.height + coverPaint.strokeWidth * 0.5 - coverBottom;

      // canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), coverPaint);
    }
    // Draw the cover
    if (cropper != null) {
      Paint coverPaint = Paint()
        ..color = cropper!.color
        ..style = PaintingStyle.stroke;

      // Draw vertical lines
      coverPaint.strokeWidth = cropper!.lineWidtV;
      double leftV =
          cropper!.startOffsetPercent * size.width - cropper!.lineWidtV * 0.5;
      double rightV =
          cropper!.endOffsetPercent * size.width + cropper!.lineWidtV * 0.5;
      double topV = 0;
      double bottomV = size.height;
      canvas.drawLine(Offset(leftV, topV), Offset(leftV, bottomV), coverPaint);
      canvas.drawLine(
          Offset(rightV, topV), Offset(rightV, bottomV), coverPaint);

      // Draw horizontal lines
      coverPaint.strokeWidth = cropper!.lineWidthH;
      double leftH = cropper!.startOffsetPercent * size.width - 1;
      double rightH = cropper!.endOffsetPercent * size.width + 1;
      double topH = cropper!.lineWidthH * 0.5;
      double bottomH = size.height - cropper!.lineWidthH * 0.5;
      canvas.drawLine(Offset(leftH, topH), Offset(rightH, topH), coverPaint);
      canvas.drawLine(
          Offset(leftH, bottomH), Offset(rightH, bottomH), coverPaint);

      // coverPaint.color = Colors.black;
      // coverPaint.strokeWidth = 2;

      // // Draw the left image at the center of the left line
      // if (cover!.leftImg != null) {
      //   double imgWidth = cover!.leftImg!.width.toDouble();
      //   double imgHeight = cover!.leftImg!.height.toDouble();
      //   Offset imgOffset =
      //       Offset(leftV - imgWidth / 2, (topV + bottomV - imgHeight) / 2);
      //   canvas.drawImage(cover!.leftImg!, imgOffset, Paint());
      // }

      // // Draw the right image at the center of the right line
      // if (cover!.rightImg != null) {
      //   double imgWidth = cover!.rightImg!.width.toDouble();
      //   double imgHeight = cover!.rightImg!.height.toDouble();
      //   Offset imgOffset =
      //       Offset(rightV - imgWidth / 2, (topV + bottomV - imgHeight) / 2);
      //   canvas.drawImage(cover!.rightImg!, imgOffset, Paint());
      // }

      if (cropper!.leftImg != null) {
        double imgWidth = cropper!.leftImg!.width.toDouble();
        double imgHeight = cropper!.leftImg!.height.toDouble();
        double maxWidth = cropper!.lineWidtV * 0.75;

        // Calculate new width and height while maintaining aspect ratio
        double newWidth = imgWidth > maxWidth ? maxWidth : imgWidth;
        double newHeight = (newWidth / imgWidth) * imgHeight;

        Offset imgOffset =
            Offset(leftV - newWidth / 2, (topV + bottomV - newHeight) / 2);
        Rect destRect =
            Rect.fromLTWH(imgOffset.dx, imgOffset.dy, newWidth, newHeight);
        canvas.drawImageRect(cropper!.leftImg!,
            Rect.fromLTRB(0, 0, imgWidth, imgHeight), destRect, Paint());
      } else {
        // 绘制向左的箭头
        coverPaint.color = cropper!.defaultArrowColor;
        coverPaint.strokeWidth = 2;
        double arrowSize = cropper!.lineWidtV * 0.5;
        double arrowCenterY = (topV + bottomV) / 2;
        double arrowLeftX = leftV - arrowSize / 4;
        double arrowRightX = leftV + arrowSize / 4;
        Path leftArrowPath = Path();
        leftArrowPath.moveTo(arrowRightX, arrowCenterY - arrowSize / 2);
        leftArrowPath.lineTo(arrowLeftX, arrowCenterY);
        leftArrowPath.lineTo(arrowRightX, arrowCenterY + arrowSize / 2);
        // 不需要关闭路径，因为我们不需要闭环
        canvas.drawPath(leftArrowPath, coverPaint);
      }

      if (cropper!.rightImg != null) {
        coverPaint.color = cropper!.color;
        coverPaint.strokeWidth = cropper!.lineWidtV;
        double imgWidth = cropper!.rightImg!.width.toDouble();
        double imgHeight = cropper!.rightImg!.height.toDouble();
        double maxWidth = cropper!.lineWidtV * 0.75;

        // Calculate new width and height while maintaining aspect ratio
        double newWidth = imgWidth > maxWidth ? maxWidth : imgWidth;
        double newHeight = (newWidth / imgWidth) * imgHeight;

        Offset imgOffset =
            Offset(rightV - newWidth / 2, (topV + bottomV - newHeight) / 2);
        Rect destRect =
            Rect.fromLTWH(imgOffset.dx, imgOffset.dy, newWidth, newHeight);
        canvas.drawImageRect(cropper!.rightImg!,
            Rect.fromLTRB(0, 0, imgWidth, imgHeight), destRect, Paint());
      } else {
        // 绘制向右的箭头
        coverPaint.color = cropper!.defaultArrowColor;
        coverPaint.strokeWidth = 2;
        double arrowSize = cropper!.lineWidtV * 0.5;
        double arrowCenterY = (topV + bottomV) / 2;
        double arrowLeftX = rightV - arrowSize / 4;
        double arrowRightX = rightV + arrowSize / 4;
        Path rightArrowPath = Path();
        rightArrowPath.moveTo(arrowLeftX, arrowCenterY - arrowSize / 2);
        rightArrowPath.lineTo(arrowRightX, arrowCenterY);
        rightArrowPath.lineTo(arrowLeftX, arrowCenterY + arrowSize / 2);
        // 不需要关闭路径，因为我们不需要闭环
        canvas.drawPath(rightArrowPath, coverPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
