import 'package:flutter/material.dart';

String DurationCalculator(int duration) {
  var hours = (duration / 3600).floor();
  duration %= 3600;
  var minutes = (duration / 60).floor();
  var seconds = duration % 60;
  return (hours.toString() +
      ":" +
      minutes.toString() +
      ":" +
      seconds.toString());
}
