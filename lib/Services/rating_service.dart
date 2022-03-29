import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

const key = "FIRST_TIME_OPEN";

class RatingService {
  SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;

  Future<bool> isSecondTimeOpen() async {
    _prefs = await SharedPreferences.getInstance();

    try {
      dynamic isSecondTime = _prefs.getBool(key);

      if (isSecondTime != null && !isSecondTime) {
        _prefs.setBool(key, false);
        return false;
      } else if (isSecondTime != null && isSecondTime) {
        _prefs.setBool(key, false);
        return false;
      } else {
        _prefs.setBool(key, true);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> showRating() async {
    try {
      final available = await _inAppReview.isAvailable();
      if (available) {
        _inAppReview.requestReview();
      } else {
        _inAppReview.openStoreListing(appStoreId: 'co.titandlt.aureal');
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
