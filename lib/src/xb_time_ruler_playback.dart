import 'package:flutter/material.dart';
import 'package:xb_time_ruler/src/xb_time_ruler_raw.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'package:xb_time_ruler/src/xb_time_ruler_area.dart';
import 'package:xb_time_ruler/src/xb_time_ruler_cropper.dart';
import 'package:flutter/services.dart' show rootBundle;

class XBTimeRulerPlayback extends StatefulWidget {
  /// 初始情况下，偏移的百分比，范围 0 - 1
  final double initOffsetPercent;

  /// 最大偏移量百分比
  final double maxOffsetPercent;

  /// 文字的颜色
  final Color? levelTitleColor;

  /// 中心线的颜色
  final Color? centerLineColor;

  /// 卡尺的背景颜色
  final Color bgColor;

  /// 第一级刻度的高度（之后每级递减）
  final double topLevelMarkHeight;

  /// 下级相对于上级的高度
  final double markHeightFactor;

  /// 刻度文字的大小
  final double levelTitleFontSize;

  /// 颜色区域
  final List<XBTimeRulerArea>? areas;

  /// 改变刻度的回调，参数为当前偏移量百分比
  final ValueChanged<double>? onChanged;

  /// cropper范围改变的回调
  final VoidCallback? onCropperChanged;

  /// 触摸手指数量变化
  final ValueChanged<int>? onFingersChanged;

  /// 滚动结束回调
  final ValueChanged<double>? onScrollEnd;

  /// 高度
  final double height;

  /// 是否需要裁剪器
  final bool needCropper;

  /// 底部刻度是否需要为cropper
  final bool needAdaptCroper;

  /// Cropper 最大的覆盖范围的，占总长度的百分比
  final double? cropperMaxRangePercent;

  /// Cropper start的百分比
  final double? initCropperStartPercent;

  /// Cropper end的百分比
  final double? initCropperEndPercent;

  /// 裁剪器左侧的图标
  final String? cropperLeftImg;

  /// 裁剪器右侧的图标
  final String? cropperRightImg;

  /// 每个高刻度间的距离
  final double topLevelMarkGap;

  const XBTimeRulerPlayback(
      {required this.initOffsetPercent,
      this.maxOffsetPercent = 1,
      this.levelTitleColor,
      this.centerLineColor,
      this.areas,
      this.onChanged,
      this.onCropperChanged,
      this.onFingersChanged,
      this.levelTitleFontSize = 10,
      this.markHeightFactor = 0.6,
      this.onScrollEnd,
      this.height = 50,
      this.topLevelMarkGap = 60,
      this.needCropper = false,
      this.needAdaptCroper = false,
      this.initCropperStartPercent,
      this.cropperMaxRangePercent,
      this.initCropperEndPercent,
      this.cropperLeftImg,
      this.cropperRightImg,
      this.topLevelMarkHeight = 10,
      this.bgColor = Colors.black,
      super.key})
      : assert(
            cropperMaxRangePercent == null ||
                (cropperMaxRangePercent >= 0 && cropperMaxRangePercent <= 1),
            'cropperMaxRangePercent 不合法'),
        assert(
            cropperMaxRangePercent == null ||
                (initCropperStartPercent == null &&
                    initCropperEndPercent == null) ||
                (initCropperStartPercent != null &&
                    initCropperEndPercent != null &&
                    initCropperEndPercent - initCropperStartPercent <=
                        cropperMaxRangePercent),
            "cropperMaxRangePercent、initCropperStartPercent、initCropperEndPercent 参数设置有误，请检查！");

  @override
  State<XBTimeRulerPlayback> createState() => XBTimeRulerPlaybackState();
}

class XBTimeRulerPlaybackState extends State<XBTimeRulerPlayback> {
  final GlobalKey<XBTimeRulerRawState> _rulerKey =
      GlobalKey<XBTimeRulerRawState>();
  late double _rawTotalWidthLevel1;

  double get _rawTotalWidth {
    return _rawTotalWidthLevel1;
  }

  @override
  void initState() {
    super.initState();
    _rawTotalWidthLevel1 = _levelSegments1[0] * widget.topLevelMarkGap;
    _areas = widget.areas ?? [];
    _generateCover(
        needCropper: widget.needCropper,
        initCropperStartPercent: widget.initCropperStartPercent,
        initCropperEndPercent: widget.initCropperEndPercent);
  }

  void updateAreas(List<XBTimeRulerArea>? newValue) {
    _areas = newValue ?? [];
    _rulerKey.currentState?.updateAreas(_areas);
  }

  double get startPercent {
    if (_cropper == null) {
      return 0;
    }
    return _cropper!.startOffsetPercent;
  }

  double get endPercent {
    if (_cropper == null) {
      return 0;
    }
    return _cropper!.endOffsetPercent;
  }

  double get currentPercent {
    return _rulerKey.currentState?.currentPercent() ?? 0;
  }

  void updateCroper(
      {required bool needCropper,
      required double? initCropperStartPercent,
      required double? initCropperEndPercent}) {
    _generateCover(
        needCropper: needCropper,
        initCropperStartPercent: initCropperStartPercent,
        initCropperEndPercent: initCropperEndPercent);
  }

  _generateCover(
      {required bool needCropper,
      required double? initCropperStartPercent,
      required double? initCropperEndPercent}) async {
    if (needCropper == false) {
      _cropper = null;
      _rulerKey.currentState?.updateCover(_cropper);
      return;
    }

    ui.Image? leftImg;
    ui.Image? rightImg;
    if (widget.cropperLeftImg != null) {
      leftImg = await _generateUiImgFromAssetsPath(widget.cropperLeftImg!);
    }
    if (widget.cropperRightImg != null) {
      rightImg = await _generateUiImgFromAssetsPath(widget.cropperRightImg!);
    }

    double? startPercent = initCropperStartPercent ?? widget.initOffsetPercent;
    double? endPercent = initCropperEndPercent;
    if (endPercent == null || endPercent < startPercent) {
      endPercent = startPercent < 0.9 ? startPercent + 0.1 : startPercent;
    }
    _cropper = XBTimeRulerCropper(
        startOffsetPercent: startPercent,
        endOffsetPercent: endPercent,
        leftImg: leftImg,
        rightImg: rightImg);
    _rulerKey.currentState?.updateCover(_cropper);
  }

  /// 触摸的手指数量
  int _fingers = 0;

  /// 手势操作的缩放比例，未操作前，为1
  double _scale = 1;

  /// 用于记录，手势开始时的缩放比例，再此基础上，增加本次缩放的影响
  double _baseScale = 1.0;

  /// 获取展示的格子数
  List<int> get _levelSegments {
    if (_scale < _threshold1 * 0.5) {
      return _levelSegments1;
    } else if (_scale < _threshold2 * 0.45) {
      return _levelSegments2;
    } else {
      return _levelSegments3;
    }
  }

  late List<XBTimeRulerArea> _areas;

  /// 1级缩放最小阈值
  final double _threshold0 = 0.75;

  /// 1级缩放最大阈值（2级缩放最小阈值）
  final double _threshold1 = 3;

  /// 2级缩放最大阈值（3级缩放最小阈值）
  final double _threshold2 = 15;

  /// 3级缩放最大阈值
  final double _threshold3 = 28;

  /// 1级缩放的格子数
  final List<int> _levelSegments1 = const [24, 6, 5];

  /// 2级缩放的格子数
  final List<int> _levelSegments2 = const [24, 6, 5];

  /// 3级缩放的格子数
  final List<int> _levelSegments3 = const [24, 6, 5, 10];

  /// 获取刻度的文字
  List<List<String>> get _levelTitles {
    return _levelTitles1;
  }

  /// 1级缩的刻度文字
  List<List<String>> get _levelTitles1 {
    final List<List<String>> ret = [];

    final hourList = List.generate(_levelSegments[0], (index) {
      String hour = fixSmallerThanTen(index);
      return "$hour:00";
    });
    ret.add(hourList);

    if (_scale < _threshold1) return ret;

    final tenMinList = List.generate(_levelSegments[1], (index) {
      if (index == 0) {
        return "";
      }
      return fixSmallerThanTen(index * 10);
    });
    ret.add(tenMinList);

    if (_scale < _threshold2) return ret;

    final twoMinList = List.generate(_levelSegments[2], (index) {
      if (index == 0) {
        return "";
      }
      return "${index * 2}";
    });
    ret.add(twoMinList);

    return ret;
  }

  /// 2级缩的刻度文字
  List<List<String>> get _levelTitles2 => [
        List.generate(_levelSegments2[0], (index) {
          int hourInt = index ~/ 6;
          int minInt = index % 6 * 10;
          return "${fixSmallerThanTen(hourInt)}:${fixSmallerThanTen(minInt)}";
        })
      ];

  /// 3级缩的刻度文字
  List<List<String>> get _levelTitles3 => [
        List.generate(_levelSegments3[0], (index) {
          int hourInt = index ~/ 30;
          int minInt = index % 30 * 2;
          return "${fixSmallerThanTen(hourInt)}:${fixSmallerThanTen(minInt)}";
        })
      ];

  /// 不足10的数字，前面补零
  String fixSmallerThanTen(int value) {
    if (value < 10) {
      return "0$value";
    }
    return "$value";
  }

  /// 设置卡尺是否可以滚动
  _updateRuleScrollAble() {
    // print('Number of fingers: $_fingers');
    _rulerKey.currentState?.updatedScrollAble(_fingers < 2);
    if (widget.onFingersChanged != null) {
      widget.onFingersChanged!(_fingers);
    }
  }

  /// 更新offset百分比
  void updatedOffsetPercent(double newValue) {
    _rulerKey.currentState?.updatedOffsetPercent(newValue);
  }

  /// 更新最大百分比
  void updateMaxOffsetPercent(double newValue) {
    _rulerKey.currentState?.updateMaxOffsetPercent(newValue);
  }

  /// 获取cover覆盖的范围（百分比范围）
  List<double> get coverPercentRange {
    if (_cropper == null) {
      return [];
    }
    return [_cropper!.startOffsetPercent, _cropper!.endOffsetPercent];
  }

  double get screenWidth => MediaQuery.of(context).size.width;

  XBTimeRulerCropper? _cropper;

  bool _isInLeftArea = false;
  bool _isInRightArea = false;
  bool _isInCenterArea = false;

  double _calculateDistanceScale(double distance) {
    /// 真实的距离
    final realDistance = (distance / _scale);

    /// 总的宽度
    final rulerTotalWidth = _rawTotalWidth;

    /// 4.用真实距离 / 总的宽度，计算d的百分比 dp
    final distanceScale = realDistance / rulerTotalWidth;
    return distanceScale;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) {
        // _touchBeginX = details.localPosition.dx;
        if (_rulerKey.currentState != null && _cropper != null) {
          /// 计算当前点击位置与屏幕中心位置在x轴上的距离 d
          final distance = details.localPosition.dx - screenWidth * 0.5;

          final distanceScale = _calculateDistanceScale(distance);

          /// 用_offsetPercent 加或者减去 dp，得到点击位置的百分比
          final touchPercent =
              _rulerKey.currentState!.offsetPercent + distanceScale;

          /// 计算当前_scale下，总的宽度
          final rulerTotalWidth = _rawTotalWidth * _scale;
          _isInLeftArea = _cropper!.isInLeftArea(touchPercent, rulerTotalWidth);

          _isInRightArea =
              _cropper!.isInRightArea(touchPercent, rulerTotalWidth);

          _isInCenterArea =
              _cropper!.isInCenterArea(touchPercent, rulerTotalWidth);

          _rulerKey.currentState!.updatedScrollAble(
              !(_isInLeftArea || _isInRightArea || _isInCenterArea));

          // print("isInLeftArea:$_isInLeftArea,isInRightArea:$_isInRightArea");
        }

        _fingers++;
        _updateRuleScrollAble();
      },
      onPointerUp: (_) {
        _fingers--;
        _updateRuleScrollAble();
      },
      onPointerCancel: (_) {
        _fingers--;
        _updateRuleScrollAble();
      },
      child: GestureDetector(
        onScaleStart: (details) {
          _baseScale = _scale;
        },
        onScaleEnd: (details) {},
        onScaleUpdate: (details) {
          // 如果需要移动，可以在这里处理
          if (details.scale == 1.0) {
            // debugPrint("这是移动，${details.toString()}");
            if (_fingers > 1) return;
            if (_cropper == null) return;
            double changeScale =
                _calculateDistanceScale(details.focalPointDelta.dx);
            if (_isInLeftArea) {
              if (_cropper!.startOffsetPercent + changeScale < 0) {
                changeScale = -_cropper!.startOffsetPercent;
              } else if (changeScale < 0 &&
                  widget.cropperMaxRangePercent != null &&
                  (_cropper!.endOffsetPercent -
                          (_cropper!.startOffsetPercent + changeScale)) >
                      widget.cropperMaxRangePercent!) {
                changeScale = _cropper!.endOffsetPercent -
                    _cropper!.startOffsetPercent -
                    widget.cropperMaxRangePercent!;
              }
              _cropper = _cropper!.copy(
                  newStartOffsetPercent:
                      _cropper!.startOffsetPercent + changeScale);
              widget.onCropperChanged?.call();
              _rulerKey.currentState?.updateCover(_cropper);
            } else if (_isInRightArea) {
              if (_cropper!.endOffsetPercent + changeScale > 1) {
                changeScale = 1 - _cropper!.endOffsetPercent;
              } else if (changeScale > 0 &&
                  widget.cropperMaxRangePercent != null &&
                  ((_cropper!.endOffsetPercent + changeScale) -
                          _cropper!.startOffsetPercent) >
                      widget.cropperMaxRangePercent!) {
                changeScale = widget.cropperMaxRangePercent! +
                    _cropper!.startOffsetPercent -
                    _cropper!.endOffsetPercent;
              }
              _cropper = _cropper!.copy(
                  newEndOffsetPercent:
                      _cropper!.endOffsetPercent + changeScale);
              widget.onCropperChanged?.call();
              _rulerKey.currentState?.updateCover(_cropper);
            } else if (_isInCenterArea) {
              if (_cropper!.startOffsetPercent + changeScale < 0 ||
                  _cropper!.endOffsetPercent + changeScale > 1) {
                return;
              }
              _cropper = _cropper!.copy(
                  newStartOffsetPercent:
                      _cropper!.startOffsetPercent + changeScale,
                  newEndOffsetPercent:
                      _cropper!.endOffsetPercent + changeScale);
              widget.onCropperChanged?.call();
              _rulerKey.currentState?.updateCover(_cropper);
            }
          } else {
            // debugPrint('${details.horizontalScale}');
            // debugPrint(details.toString());
            _scale = _baseScale * details.scale;
            if (_scale > _threshold3) {
              _scale = _threshold3;
            } else if (_scale < _threshold0) {
              _scale = _threshold0;
            }
            _rulerKey.currentState?.updateProperties(
                levelSegments: _levelSegments,
                levelTitles: _levelTitles,
                topLevelMarkGap: _topLevelMarkGap,
                areas: _areas);
          }
        },
        child: XBTimeRulerRaw(
          key: _rulerKey,
          levelSegments: _levelSegments,
          levelTitles: _levelTitles,
          levelTitleColor: widget.levelTitleColor ?? Colors.white,
          levelTitleFontSize: widget.levelTitleFontSize,
          topLevelMarkHeight: widget.topLevelMarkHeight,
          topLevelMarkGap: _topLevelMarkGap,
          centerLineColor: widget.centerLineColor ?? Colors.white,
          areas: _areas,
          bgColor: widget.bgColor,
          markHeightFactor: widget.markHeightFactor,
          onChanged: (value) {
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
          onScrollEnd: widget.onScrollEnd,
          height: widget.height,
          offsetPercent: widget.initOffsetPercent,
          maxOffsetPercent: widget.maxOffsetPercent,
          cropper: _cropper,
          needAdaptCroper: widget.needAdaptCroper,
        ),
      ),
    );
  }

  double get _topLevelMarkGap => widget.topLevelMarkGap * _scale;

  /// 用assets中的图片生成ui.Image
  Future<ui.Image> _generateUiImgFromAssetsPath(String path) async {
    final byteData = await rootBundle.load(path);
    final Uint8List bytes = byteData.buffer.asUint8List();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}
