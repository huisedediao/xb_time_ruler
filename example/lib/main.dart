import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xb_time_ruler/xb_time_ruler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<XBTimeRulerPlaybackState> _globalKey = GlobalKey();

  final int _alpha = 80;

  late final List<XBTimeRulerArea> _areas;

  @override
  void initState() {
    super.initState();
    _areas = [
      XBTimeRulerArea(
          startOffsetPercent: 0.1,
          endOffsetPercent: 0.2,
          color: Colors.blue.withAlpha(_alpha)),
      XBTimeRulerArea(
          startOffsetPercent: 0.4,
          endOffsetPercent: 0.6,
          color: Colors.blue.withAlpha(_alpha)),
      XBTimeRulerArea(
          startOffsetPercent: 0.7,
          endOffsetPercent: 1.0,
          color: Colors.red.withAlpha(_alpha))
    ];
  }

  bool isInAvailable(double value) {
    bool ret = false;
    for (var element in _areas) {
      if (element.isAvailable && element.isInSide(value)) {
        ret = true;
        break;
      }
    }
    return ret;
  }

  XBTimeRulerArea? findFirstAvailable() {
    for (var element in _areas) {
      if (element.isAvailable) {
        return element;
      }
    }
    return null;
  }

  int fingers = 0;

  Timer? delayTimer;

  double? percent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(''),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            XBTimeRulerPlayback(
                cropperMaxRangePercent: 0.1,
                needCropper: true,
                // needAdaptCroper: true,
                initCropperStartPercent: 0.15,
                initCropperEndPercent: 0.22,
                // coverLeftImg: "assets/images/arrow_left.png",
                // coverRightImg: "assets/images/arrow_right.png",
                key: _globalKey,
                initOffsetPercent: 0.2,
                onChanged: (value) {
                  // print("百分比更新：$value");
                  percent = value;
                },
                onScrollEnd: (value) {
                  percent = value;
                  scrollIfNeed();
                },
                onFingersChanged: (value) {
                  fingers = value;
                  if (fingers != 0) {
                    delayTimer?.cancel();
                  } else {
                    scrollIfNeed();
                  }
                },
                areas: _areas),
            const SizedBox(
              height: 40,
            ),
            GestureDetector(
                onTap: () {
                  print(_globalKey.currentState?.coverPercentRange);
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("获取百分比"),
                ))
          ],
        )),
      ),
    );
  }

  scrollIfNeed() {
    if (percent == null) return;
    final available = isInAvailable(percent!);
    if (!available) {
      final first = findFirstAvailable();
      if (first != null) {
        delayTimer?.cancel(); // 取消上一个计时器
        delayTimer = Timer(const Duration(milliseconds: 1000), () {
          if (fingers == 0) {
            _globalKey.currentState
                ?.updatedOffsetPercent(first.startOffsetPercent);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    delayTimer?.cancel();
    super.dispose();
  }
}
