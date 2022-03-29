String DurationCalculator(int duration) {
  try {
    var hours = (duration / 3600).floor();
    duration %= 3600;
    var minutes = (duration / 60).floor();
    var seconds = duration % 60;
    return ((hours == 0 ? '' : hours.toString() + ' hr ') +
        minutes.toString() +
        " min ");
  } catch (e) {
    return 'Some Issue';
  }
}
