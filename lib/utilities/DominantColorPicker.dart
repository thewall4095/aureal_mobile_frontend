import 'dart:ui';

import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:flutter/services.dart';

Color getColor(String url) {
  getColorFromUrl(url).then((value) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(hexOfRGBA(value[0], value[1], value[2])),
    ));
    return Color(hexOfRGBA(value[0], value[1], value[2]));
  });
}

int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
  r = (r < 0) ? -r : r;
  g = (g < 0) ? -g : g;
  b = (b < 0) ? -b : b;
  opacity = (opacity < 0) ? -opacity : opacity;
  opacity = (opacity > 1) ? 255 : opacity * 255;
  r = (r > 255) ? 255 : r;
  g = (g > 255) ? 255 : g;
  b = (b > 255) ? 255 : b;
  int a = opacity.toInt();
  return int.parse(
      '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}');
}
