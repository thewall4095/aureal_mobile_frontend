import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'FilterState.dart';
import 'screens/Home.dart';
import 'screens/LoginSignup/WelcomeScreen.dart';
//auth change user stream

// Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
//   print('wrapper+ adasdasdas +  ' + message['data']);
//   if (message.containsKey('data')) {
//     // Handle data message
//     final dynamic data = message['data'];
//   }
//
//   if (message.containsKey('notification')) {
//     // Handle notification message
//     final dynamic notification = message['notification'];
//   }
//
//   // Or do other work.
// }

class Wrapper extends StatefulWidget {
  static const String id = 'wapper';

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  int counter = 0;
  Dio dio = Dio();
  String status = 'hidden';
  String userId;
  String registrationToken;

  // List<Message> messages = [];
  void checkAuthenticity() async {
    // var setCategories = Provider.of<CategoriesProvider>(context);
    // await setCategories.getCategories();
    await _messaging.getToken().then((token) {
      setState(() {
        registrationToken = token;
      });
    });
    String url = 'https://api.aureal.one/public/getToken';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userId')) {
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['registration_token'] = registrationToken;
      print(registrationToken);
      print(map.toString());
      print(prefs.containsKey('userId'));

      FormData formData = FormData.fromMap(map);

      try {
        print(url);
        print(map.toString());
        var response = await dio.post(url, data: formData);

        print(response.statusCode);

        if (response.statusCode == 200) {
          print(response.data.toString());
          prefs.setString('token', response.data['updatedUser']['token']);
          prefs.setString(
              'displayPicture', response.data['updatedUser']['img']);
          print(prefs.getString('token'));
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) {
            return Home();
          }));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) {
            return Welcome();
          }));
        }
        counter++;
      } catch (e) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return Welcome();
        }));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return Welcome();
      }));
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    // TODO: implement initState

    MediaNotification.setListener('pause', () {
      setState(() => status = 'pause');
    });
    MediaNotification.setListener('play', () {
      setState(() => status = 'play');
    });
    MediaNotification.setListener('next', () {});
    MediaNotification.setListener('prev', () {});
    MediaNotification.setListener('select', () {});

    super.initState();

    // _messaging.configure(
    //     onMessage: (Map<String, dynamic> message) {
    //       print(message.toString() + 'asdsadsadsad');
    //       final notification = message['notification'];
    //       setState(() {
    //         messages.add(Message(
    //             title: notification['title'], body: notification['body']));
    //       });
    //       print("$message");
    //     },
    //     onLaunch: (Map<String, dynamic> message) {
    //       print("$message");
    //     },
    //     onResume: (Map<String, dynamic> message) {
    //       print("$message");
    //     },
    //     onBackgroundMessage: myBackgroundMessageHandler);
    //
    // _messaging.requestNotificationPermissions(
    //   const IosNotificationSettings(sound: true, badge: true, alert: true),
    // );
    // FirebaseMessaging.instance
    //     .getInitialMessage()
    //     .then((RemoteMessage message) {
    //   if (message != null) {
    //     Navigator.pushNamed(context, '/message',
    //         arguments: MessageArguments(message, true));
    //   }
    // });

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   RemoteNotification notification = message.notification;
    //   AndroidNotification android = message.notification?.android;

    //   if (notification != null && android != null) {
    //     flutterLocalNotificationsPlugin.show(
    //         notification.hashCode,
    //         notification.title,
    //         notification.body,
    //         NotificationDetails(
    //           android: AndroidNotificationDetails(
    //             channel.id,
    //             channel.name,
    //             channel.description,
    //             // TODO add a proper drawable resource to android, for now using
    //             //      one that already exists in example app.
    //             icon: 'launch_background',
    //           ),
    //         ));
    //   }
    // });

    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print('A new onMessageOpenedApp event was published!');
    //   Navigator.pushNamed(context, '/message',
    //       arguments: MessageArguments(message, true));
    // });

    // Timer(Duration(seconds: 50), () async {
    //   print("Void callback happening");
    //   // checkAuthenticity();
    //   if (counter < 2) {
    //     checkAuthenticity();
    //   }
    // });

    checkAuthenticity();
  }

  @override
  // Widget buildMessageList(BuildContext context) => ListView(
  //       children: messages.map(buildMessage).toList(),
  //     );

  // Widget buildMessage(Message message) => ListTile(
  //       title: Text(
  //         message.title,
  //         textScaleFactor: 0.75,
  //       ),
  //       subtitle: Text(
  //         message.body,
  //         textScaleFactor: 0.75,
  //       ),
  //     );

  Widget build(BuildContext context) {
    var categoryBuild = Provider.of<CategoriesProvider>(context);
    var communities = Provider.of<CommunityProvider>(context);
    categoryBuild.getCategories();
    // communities.getAllCommunitiesForUser();
    // communities.getUserCreatedCommunities();
    // communities.getAllCommunity();

    return ChangeNotifierProvider(
      create: (context) => SortFilterPreferences(),
      child: Center(
        child: Container(
          // color: kPrimaryColor,
          height: double.infinity,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/Favicon.png'))),
              )
            ],
          ),
        ),
      ),
    );
  }
}
