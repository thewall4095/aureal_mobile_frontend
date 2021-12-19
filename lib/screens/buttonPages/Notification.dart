import 'dart:convert';

import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'settings/Theme-.dart';

class NotificationPage extends StatefulWidget {
  static const String id = "NotificationsPage";

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  String registrationToken;
  final _messaging = FirebaseMessaging.instance;

  Dio dio = Dio();
  TabController _tabController;
  String displayPicture;

  var notificationList = [];

  void getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      displayPicture = prefs.getString('displayPicture');
    });
  }

  void getNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getNotifications?user_id=${prefs.getString('userId')}';
    print(
        'https://api.aureal.one/public/getNotifications?user_id=${prefs.getString('userId')}');
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          notificationList = jsonDecode(response.body)['notifications'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void sendNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String url = 'https://api.aureal.one/public/send';

    var map = Map<String, dynamic>();

    print(registrationToken);
    map['identifier'] = prefs.getString('code');
    map['registrationToken'] = registrationToken;
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          notificationList = jsonDecode(response.body)['notifications'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void viewedNotification(int notificationId) async {
    String url = 'https://api.aureal.one/public/viewedNotificaiton';
    var map = Map<String, dynamic>();
    map['notification_id'] = notificationId;

    FormData formData = FormData.fromMap(map);

    var response = await dio.post(url, data: formData);
    print(response.toString());
    print('notification_id');
  }

  @override
  void initState() {
    // TODO: implement initState
    getNotifications();
    getLocalData();

    _tabController = TabController(length: 4, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    SizeConfig().init(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              elevation: 0,
              //  backgroundColor: Colors.transparent,
              // leading: IconButton(
              //   icon: displayPicture != null
              //       ? CircleAvatar(
              //           radius: 14,
              //           backgroundImage: NetworkImage(displayPicture),
              //         )
              //       : Container(
              //           decoration: BoxDecoration(
              //               shape: BoxShape.circle,
              //               border: Border.all(width: 1.5)),
              //           child: CircleAvatar(
              //             backgroundImage: AssetImage('assets/images/user.png'),
              //             radius: 14,
              //             backgroundColor: Colors.transparent,
              //           ),
              //         ),
              //   onPressed: () {
              //     Navigator.pushNamed(context, Profile.id);
              //   },
              // ),
              actions: <Widget>[
//                IconButton(
//                  icon: Icon(
//                    Icons.settings,
//                    color: Colors.white,
//                  ),
//                  onPressed: () => debugPrint('Action Notification'),
//                ),
              ],
              //       expandedHeight: 170,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 0, 64),
                  height: 50,
                  alignment: Alignment.bottomLeft,
                  // child: Text('Notifications',
                  //     textScaleFactor: 0.75,
                  //     style: TextStyle(
                  //       fontSize: 36,
                  //       fontWeight: FontWeight.bold,
                  //     )),
                ),
              ),
            ),
          ];
        },
        body: Container(
            child: notificationList.length == 0
                ? Text(
                    "There is nothing here as of now",
                    textScaleFactor: 0.75,
                  )
                : ListView(
                    children: <Widget>[
                      for (var v in notificationList)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            onTap: () {
                              if (v['data']['episode_id'] != null)
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return EpisodeView(
                                    episodeId: v['data']['episode_id'],
                                  );
                                }));
                            },
                            leading: Container(
                              height: 65,
                              width: 65,
                              child: CachedNetworkImage(
                                imageBuilder: (context, imageProvider) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                    ),
                                    height: MediaQuery.of(context).size.width,
                                    width: MediaQuery.of(context).size.width,
                                  );
                                },
                                imageUrl: v['data']['image'] == null
                                    ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                    : v['data']['image'],
                                fit: BoxFit.cover,
                                // memCacheHeight:
                                //     MediaQuery.of(
                                //             context)
                                //         .size
                                //         .width
                                //         .ceil(),
                                memCacheHeight:
                                    MediaQuery.of(context).size.height.floor(),

                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              ),
                            ),
                            title: Text(
                              v['title'],
                              textScaleFactor: 0.75,
                              style: TextStyle(
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 3.2),
                            ),
                            subtitle: Text(
                              v['body'],
                              textScaleFactor: 0.75,
                              style: TextStyle(
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 3.2),
                            ),
                            trailing: Text(
                                "${timeago.format(DateTime.parse(v['createdAt']))}"),
                          ),
                        )
                    ],
                  )),
      ),
    );
  }
}
// class Noti extends StatefulWidget {
//   static const String id = "NotificationsPage";
//   @override
//   _NotiState createState() => _NotiState();

// }
// class _NotiState extends State<Noti> {
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
//
//   @override
//   void initState() {
//     super.initState();
//     flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
//     var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
//     var iOS = new IOSInitializationSettings();
//     var initSetttings = new InitializationSettings(android, iOS);
//     flutterLocalNotificationsPlugin.initialize(initSetttings,
//        onSelectNotification: onSelectNotification);
//   }
//
//   Future onSelectNotification(String payload) {
//     debugPrint("payload : $payload");
//     showDialog(
//       context: context,
//       builder: (_) =>
//       new AlertDialog(
//         title: new Text('Notification'),
//         content: new Text('$payload'),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//    // var notification = Provider.of<NotificationProvider>(context);
//     return Scaffold(
//       appBar: new AppBar(
//         title: new Text('Notification'),
//       ),
//       body: new Center(
//         child: new RaisedButton(
//           onPressed: showNotification,
//           child: new Text(
//             'Demo',
//             style: Theme
//                 .of(context)
//                 .textTheme
//                 .headline,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void>showNotification() async {
//     var android = new AndroidNotificationDetails(
//         'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
//         priority: Priority.High, importance: Importance.Max
//
//     );
//     var iOS = new IOSNotificationDetails();
//     var platform = new NotificationDetails(android, iOS);
//     await flutterLocalNotificationsPlugin.show(
//         0, 'Well Done', 'You Published Eposide', platform,
//         payload: 'Your Published Your Eposide to Hive');
//
//   }
// }
//
// class _NotiState extends State {
//   FlutterLocalNotificationsPlugin fltrNotification;
//   String _selectedParam;
//   String task;
//   int val;
//
//   @override
//   void initState() {
//     super.initState();
//     var androidInitilize = new AndroidInitializationSettings('app_icon');
//     var iOSinitilize = new IOSInitializationSettings();
//     var initilizationsSettings =
//     new InitializationSettings(androidInitilize, iOSinitilize);
//     fltrNotification = new FlutterLocalNotificationsPlugin();
//     fltrNotification.initialize(initilizationsSettings,
//         onSelectNotification: notificationSelected);
//   }
//
//   Future _showNotification() async {
//     var androidDetails = new AndroidNotificationDetails(
//         "Channel ID", "Desi programmer", "This is my channel",
//         importance: Importance.Max);
//     var iSODetails = new IOSNotificationDetails();
//     var generalNotificationDetails =
//     new NotificationDetails(androidDetails, iSODetails);
//
//     // await fltrNotification.show(
//     //     0, "Task", "You created a Task", generalNotificationDetails, payload: "Task");
//     var scheduledTime;
//     if (_selectedParam == "Hour") {
//       scheduledTime = DateTime.now().add(Duration(hours: val));
//     } else if (_selectedParam == "Minute") {
//       scheduledTime = DateTime.now().add(Duration(minutes: val));
//     } else {
//       scheduledTime = DateTime.now().add(Duration(seconds: val));
//     }
//
//     fltrNotification.schedule(
//         1, "Times Uppp", task, scheduledTime, generalNotificationDetails);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(15.0),
//               child: TextField(
//                 decoration: InputDecoration(border: OutlineInputBorder()),
//                 onChanged: (_val) {
//                   task = _val;
//                 },
//               ),
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 DropdownButton(
//                   value: _selectedParam,
//                   items: [
//                     DropdownMenuItem(
//                       child: Text("Seconds"),
//                       value: "Seconds",
//                     ),
//                     DropdownMenuItem(
//                       child: Text("Minutes"),
//                       value: "Minutes",
//                     ),
//                     DropdownMenuItem(
//                       child: Text("Hour"),
//                       value: "Hour",
//                     ),
//                   ],
//                   hint: Text(
//                     "Select Your Field.",
//                     style: TextStyle(
//                       color: Colors.black,
//                     ),
//                   ),
//                   onChanged: (_val) {
//                     setState(() {
//                       _selectedParam = _val;
//                     });
//                   },
//                 ),
//                 DropdownButton(
//                   value: val,
//                   items: [
//                     DropdownMenuItem(
//                       child: Text("1"),
//                       value: 1,
//                     ),
//                     DropdownMenuItem(
//                       child: Text("2"),
//                       value: 2,
//                     ),
//                     DropdownMenuItem(
//                       child: Text("3"),
//                       value: 3,
//                     ),
//                     DropdownMenuItem(
//                       child: Text("4"),
//                       value: 4,
//                     ),
//                   ],
//                   hint: Text(
//                     "Select Value",
//                     style: TextStyle(
//                       color: Colors.black,
//                     ),
//                   ),
//                   onChanged: (_val) {
//                     setState(() {
//                       val = _val;
//                     });
//                   },
//                 ),
//               ],
//             ),
//             RaisedButton(
//               onPressed: _showNotification,
//               child: new Text('Set Task With Notification'),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future notificationSelected(String payload) async {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         content: Text("Notification Clicked $payload"),
//       ),
//     );
//   }
// }
//
//
