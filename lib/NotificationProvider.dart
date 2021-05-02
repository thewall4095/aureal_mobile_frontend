// // import 'dart:convert';
// //
// // import 'package:auditory/CommunityProvider.dart';
// // import 'package:auditory/Services/LaunchUrl.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_share/flutter_share.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:http/http.dart' as http;
// //
// // String word;
// // String author;
// // String displayPicture;
// // bool isLoading;
// // String hiveUserName;
// //
// // String communityName;
// // String communityDescription;
// //
// // var followingList;
// //
// // Launcher launcher = Launcher();
// //
// // final double maxSlide = 250.0;
// // final double minDragStartingEdge = 10;
// // final double maxDragStartingEdge = 30;
// //
// // CommunityProvider communities;
// //
// // var currentlyPlaying = null;
// //
// // bool paginationLoading = false;
// //
// // bool _canBeDragged;
// //
// // ScrollController _scrollController;
// //
// // var episodes = [];
// //
// // void getCommunityEposidesForUser() async {
// //
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   String url =
// //       'https://api.aureal.one/public/getCommunityEpisodes?user_id=${prefs.getString('userId')}';
// //
// //   try {
// //     http.Response response = await http.get(Uri.parse(url));
// //     if (response.statusCode == 200) {
// //       print('communityepisodes');
// //       print(response.body);
// //
// //       episodes = jsonDecode(response.body)['EpisodeResult'];
// //     } else {
// //       print(response.statusCode);
// //     }
// //   } catch (e) {
// //     print(e);
// //   }
// //
// // }
// //
// // TabController _tabController;
// //
// // void getCommunityEpisodesForUserPaginated() async {
// //   print('pagination starting');
// //
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   String url =
// //       'https://api.aureal.one/public/getCommunityEpisodes?user_id=${prefs.getString('userId')}&page=$pageNumber';
// //
// //   try {
// //     http.Response response = await http.get(Uri.parse(url));
// //     if (response.statusCode == 200) {
// //       print('communityepisodes');
// //       print(response.body);
// //     } else {
// //       print(response.statusCode);
// //     }
// //   } catch (e) {
// //     print(e);
// //   }
// //
// // }
// //
// // List favPodcast = [];
// //
// // void getFollowedPodcasts() async {
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   String url =
// //       "https://api.aureal.one/public/followedPodcasts?user_id=${prefs.getString('userId')}";
// //   try {
// //     http.Response response = await http.get(Uri.parse(url));
// //     if (response.statusCode == 200) {
// //
// //     } else {
// //       print(response.statusCode);
// //     }
// //   } catch (e) {
// //     print(e);
// //   }
// // }
// //
// // int pagenumber = 1;
// //
// // List hiveEpisodes = [];
// //
// // void getHiveFollowedEpisode() async {
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   String url =
// //       "https://api.aureal.one/public/browseHiveEpisodes?user_id=${prefs.getString('userId')}&page=$pageNumber";
// //   try {
// //     http.Response response = await http.get(Uri.parse(url));
// //     if (response.statusCode == 200) {
// //       print(response.body);
// //       if (pageNumber != 0) {
// //        + 1;
// //         });
// //       } else {
// //         setState(() {
// //           hiveEpisodes = jsonDecode(response.body)['EpisodeResult'];
// //         });
// //         setState(() {
// //           for (var v in hiveEpisodes) {
// //             v['isLoading'] = false;
// //           }
// //           pageNumber = pageNumber + 1;
// //         });
// //       }
// //     } else {
// //       print(response.statusCode);
// //     }
// //   } catch (e) {
// //     print(e);
// //   }
// // }
// //
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationProvider extends ChangeNotifier {
//
// }
// FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
// @override
// void initState() {
//   initState();
//   flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
//   var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
//   var iOS = new IOSInitializationSettings();
//   var initSetttings = new InitializationSettings(android, iOS);
//   flutterLocalNotificationsPlugin.initialize(initSetttings,
//       onSelectNotification: onSelectNotification);
// }
//
// Future onSelectNotification(String payload) {
//   debugPrint("payload : $payload");
//   showDialog(
//     context: context,
//     builder: (_) => new AlertDialog(
//       title: new Text('Notification'),
//       content: new Text('$payload'),
//     ),
//   );
// }
//
// Future<void>showNotification() async {
//   var android = new AndroidNotificationDetails(
//       'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
//       priority: Priority.High, importance: Importance.Max
//
//   );
//   var iOS = new IOSNotificationDetails();
//   var platform = new NotificationDetails(android, iOS);
//   await flutterLocalNotificationsPlugin.show(
//       0, 'Well Done', 'You Published Eposide', platform,
//       payload: 'Your Published Your Eposide to Hive');
//
// }
//
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io' show File, Platform;
import 'package:http/http.dart' as http;

import 'package:rxdart/subjects.dart';

class LocalNotificationScreen extends StatefulWidget {
  static const String id = 'Notification';
  @override
  _LocalNotificationScreenState createState() =>
      _LocalNotificationScreenState();
}

class _LocalNotificationScreenState extends State<LocalNotificationScreen> {
  //

  int count = 0;

  @override
  void initState() {
    super.initState();
    notificationPlugin
        .setListenerForLowerVersions(onNotificationInLowerVersions);
    notificationPlugin.setOnNotificationClick(onNotificationClick);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local Notifications'),
      ),
      body: Center(
        child: FlatButton(
          onPressed: () async {
            await notificationPlugin.showNotification();
            //  //  await notificationPlugin.scheduleNotification();
            //  // await notificationPlugin.showNotificationWithAttachment();
            //   await notificationPlugin.repeatNotification();
            //   await notificationPlugin.showDailyAtTime();
            //   await notificationPlugin.showWeeklyAtDayTime();
            count = await notificationPlugin.getPendingNotificationCount();
            print('Count $count');
            await notificationPlugin.cancelNotification();
            count = await notificationPlugin.getPendingNotificationCount();
            print('Count $count');
          },
          child: Text('Send Notification'),
        ),
      ),
    );
  }

  onNotificationInLowerVersions(ReceivedNotification receivedNotification) {
    print('Notification Received ${receivedNotification.id}');
  }

  onNotificationClick(String payload) {
    print('Payload $payload');
    Navigator.push(context, MaterialPageRoute(builder: (coontext) {
      return NotificationScreen(
        payload: payload,
      );
    }));
  }
}

class NotificationPlugin {
  //
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final BehaviorSubject<ReceivedNotification>
      didReceivedLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  var initializationSettings;

  NotificationPlugin._() {
    init();
  }

  init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isIOS) {
      _requestIOSPermission();
    }
    initializePlatformSpecifics();
  }

  initializePlatformSpecifics() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launchr');
    var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        ReceivedNotification receivedNotification = ReceivedNotification(
            id: id, title: title, body: body, payload: payload);
        didReceivedLocalNotificationSubject.add(receivedNotification);
      },
    );

    initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  }

  _requestIOSPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        .requestPermissions(
          alert: false,
          badge: true,
          sound: true,
        );
  }

  setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    didReceivedLocalNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }

  setOnNotificationClick(Function onNotificationClick) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {
      onNotificationClick(payload);
    });
  }

  Future<void> showNotification() async {
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID',
      'CHANNEL_NAME',
      "CHANNEL_DESCRIPTION",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      timeoutAfter: 5000,
      styleInformation: DefaultStyleInformation(true, true),
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Title',
      'Test Body', //null
      platformChannelSpecifics,
      payload: 'New Payload',
    );
  }

  Future<void> showDailyAtTime() async {
    var time = Time(21, 3, 0);
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID 4',
      'CHANNEL_NAME 4',
      "CHANNEL_DESCRIPTION 4",
      importance: Importance.max,
      priority: Priority.high,
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.showDailyAtTime(
      0,
      'Test Title at ${time.hour}:${time.minute}.${time.second}',
      'Test Body', //null
      time,
      platformChannelSpecifics,
      payload: 'Test Payload',
    );
  }

  Future<void> showWeeklyAtDayTime() async {
    var time = Time(21, 5, 0);
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID 5',
      'CHANNEL_NAME 5',
      "CHANNEL_DESCRIPTION 5",
      importance: Importance.max,
      priority: Priority.high,
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.showWeeklyAtDayAndTime(
      0,
      'Test Title at ${time.hour}:${time.minute}.${time.second}',
      'Test Body', //null
      Day.saturday,
      time,
      platformChannelSpecifics,
      payload: 'Test Payload',
    );
  }

  Future<void> repeatNotification() async {
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID 3',
      'CHANNEL_NAME 3',
      "CHANNEL_DESCRIPTION 3",
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: DefaultStyleInformation(true, true),
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(
      0,
      'Repeating Test Title',
      'Repeating Test Body',
      RepeatInterval.everyMinute,
      platformChannelSpecifics,
      payload: 'Test Payload',
    );
  }

  Future<void> scheduleNotification() async {
    var scheduleNotificationDateTime = DateTime.now().add(Duration(seconds: 5));
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID 1',
      'CHANNEL_NAME 1',
      "CHANNEL_DESCRIPTION 1",
      icon: 'secondary_icon',
      sound: RawResourceAndroidNotificationSound('my_sound'),
      largeIcon: DrawableResourceAndroidBitmap('large_notf_icon'),
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      timeoutAfter: 5000,
      styleInformation: DefaultStyleInformation(true, true),
    );
    var iosChannelSpecifics = IOSNotificationDetails(
      sound: 'my_sound.aiff',
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidChannelSpecifics,
      iOS: iosChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.schedule(
      0,
      'Test Title',
      'Test Body',
      scheduleNotificationDateTime,
      platformChannelSpecifics,
      payload: 'Test Payload',
    );
  }

  Future<void> showNotificationWithAttachment() async {
    var attachmentPicturePath = await _downloadAndSaveFile(
        'https://via.placeholder.com/800x200', 'attachment_img.jpg');
    var iOSPlatformSpecifics = IOSNotificationDetails(
      attachments: [IOSNotificationAttachment(attachmentPicturePath)],
    );
    var bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(attachmentPicturePath),
      contentTitle: '<b>Attached Image</b>',
      htmlFormatContentTitle: true,
      summaryText: 'Test Image',
      htmlFormatSummaryText: true,
    );
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL ID 2',
      'CHANNEL NAME 2',
      'CHANNEL DESCRIPTION 2',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigPictureStyleInformation,
    );
    var notificationDetails = NotificationDetails(
        android: androidChannelSpecifics, iOS: iOSPlatformSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Title with attachment',
      'Body with Attachment',
      notificationDetails,
    );
  }

  _downloadAndSaveFile(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(Uri.parse(url));
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<int> getPendingNotificationCount() async {
    List<PendingNotificationRequest> p =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return p.length;
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<void> cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

NotificationPlugin notificationPlugin = NotificationPlugin._();

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

class NotificationScreen extends StatefulWidget {
  //
  final String payload;

  NotificationScreen({this.payload});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications Screen'),
      ),
      body: Center(
        child: Text(widget.payload),
      ),
    );
  }
}
