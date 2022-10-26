import 'package:amplitude_flutter/amplitude.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AmplitudeAnalyticsProvider extends ChangeNotifier{
  final Amplitude analytics = Amplitude.getInstance(instanceName: 'Aureal_mobile');

  void initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    analytics.init(kAmplitudeAnalyticskey);
    analytics.enableCoppaControl();
    analytics.setUserId("${prefs.getString('userId')}");
    analytics.trackingSessionEvents(true);
    analytics.logEvent('Amplitude is working now adding the events', eventProperties: {
      'friend_num': 10,
      'is_heavy_user': true
    });

  }

  void logEvent({String event, Map<String, dynamic> eventData}) async {
    analytics.logEvent('$event', eventProperties: eventData);
  }


}