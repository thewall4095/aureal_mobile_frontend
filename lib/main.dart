import 'dart:async';
import 'dart:convert';

import 'package:auditory/Accounts/HiveAccount.dart';
import 'package:auditory/BrowseProvider.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/DiscoverProvider.dart';
import 'package:auditory/FilterState.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/SelectedCommunitiesProvider.dart';
import 'package:auditory/Wrapper.dart';
import 'package:auditory/screens/CommunityPages/CommunitySearch.dart';
import 'package:auditory/screens/CommunityPages/CommunityView.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Profiles/EditPodcast.dart';
import 'package:auditory/screens/buttonPages/HiveWallet.dart';
import 'package:auditory/screens/buttonPages/settings/Prefrences.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/screens/buttonPages/settings/security/AccountSettings/Presence.dart';
import 'package:auditory/screens/errorScreens/PopError.dart';
import 'package:auditory/screens/errorScreens/TemporaryError.dart';
import 'package:auditory/screens/recorderApp/recorderpages/PostRSSFeed.dart';
import 'package:auditory/utilities/TagSearch.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
// import 'package:in_app_update/in_app_update.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'SearchProvider.dart';
import 'screens/Home.dart';
import 'screens/LoginSignup/Auth.dart';
import 'screens/LoginSignup/Login.dart';
import 'screens/LoginSignup/SignUp.dart';
import 'screens/LoginSignup/WelcomeScreen.dart';
import 'screens/Onboarding/Categories.dart';
import 'screens/Onboarding/LanguageSelection.dart';
import 'screens/Player/Player.dart';
import 'screens/Profiles/CategoryView.dart';
import 'screens/buttonPages/Bio.dart';
import 'screens/buttonPages/Downloads.dart';
// import 'screens/recorderApp/recorder/Recorder.dart';
import 'screens/buttonPages/Messages.dart';
import 'screens/buttonPages/Notification.dart';
import 'screens/buttonPages/Profile.dart';
import 'screens/buttonPages/Settings.dart';
import 'screens/buttonPages/search.dart';
import 'screens/buttonPages/settings/AccountSettings.dart';
import 'screens/buttonPages/settings/EmailNotifications/EmailNotifications.dart';
import 'screens/buttonPages/settings/MobileNotifications/MobileNotifications.dart';
import 'screens/buttonPages/settings/NotificationsSetting.dart';
import 'screens/buttonPages/settings/security/Security.dart';
import 'screens/recorderApp/RecorderDashboard.dart';
import 'screens/recorderApp/recorderpages/CreatePodcast.dart';
import 'screens/recorderApp/recorderpages/SoundEditor/SoundEditor.dart';
import 'screens/recorderApp/recorderpages/selectPodcast.dart';

// Future main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   final appDocumentDirectory =
//   await pathProvider.getApplicationDocumentsDirectory();
//   Hive.init(appDocumentDirectory.path);
//
//   AssetsAudioPlayer.setupNotificationsOpenAction((notification) {
//     return true;
//   });
//
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//     ]);

const debug = true;

/// Define a top-level named handler which background/terminated messages will
/// call.
///
/// To verify things are working, check out the native platform logs.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  'This channel is used for important notifications.', // description
  importance: Importance.high,
);

/// Initialize the [FlutterLocalNotificationsPlugin] package.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final appDocumentDirectory =
      await pathProvider.getApplicationDocumentsDirectory();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );

  Hive.init(appDocumentDirectory.path);

  final settings = await Hive.openBox('settings');
  bool isLightTheme = settings.get('isLightTheme') ?? false;

  print(isLightTheme);

  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(isLightTheme: isLightTheme),
    child: AppStart(),
  ));
}

class AppStart extends StatelessWidget {
  const AppStart({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    return MyApp(
      themeProvider: themeProvider,
    );
  }
}

class MyApp extends StatefulWidget with WidgetsBindingObserver {
  final ThemeProvider themeProvider;

  const MyApp({Key key, @required this.themeProvider}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

// Future main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   AssetsAudioPlayer.setupNotificationsOpenAction((notification) {
//     return true;
//   });
//
//   runApp(MyApp());
// }
class _MyAppState extends State<MyApp> {
  // AppUpdateInfo _updateInfo;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  bool _flexibleUpdateAvailable = false;
  String _token;

  Future<void> checkForUpdate() async {
    // InAppUpdate.checkForUpdate().then((info) {
    //   setState(() {
    //     _updateInfo = info;
    //   });
    // }).catchError((e) {
    //   showSnack(e.toString());
    // });
  }

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      Scaffold.of(_scaffoldKey.currentContext)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        print(message.toString());
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message);
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: 'notification_icon',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Navigating to screen');
      // Navigator.pushNamed(context, NotificationPage.id,
      //     arguments: MessageArguments(message, true));
    });

    checkForUpdate();
  }

  int _messageCount = 0;

  /// The API endpoint here accepts a raw FCM payload for demonstration purposes.
  String constructFCMPayload(String token) {
    _messageCount++;
    return jsonEncode({
      'token': token,
      'data': {
        'via': 'FlutterFire Cloud Messaging!!!',
        'count': _messageCount.toString(),
      },
      'notification': {
        'title': 'Hello FlutterFire!',
        'body': 'This notification (#$_messageCount) was created via FCM!',
      },
    });
  }

  Future<void> sendPushMessage() async {
    if (_token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      await http.post(
        Uri.parse('https://api.rnfirebase.io/messaging/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: constructFCMPayload(_token),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  Future<void> onActionSelected(String value) async {
    switch (value) {
      case 'subscribe':
        {
          print(
              'FlutterFire Messaging Example: Subscribing to topic "fcm_test".');
          await FirebaseMessaging.instance.subscribeToTopic('fcm_test');
          print(
              'FlutterFire Messaging Example: Subscribing to topic "fcm_test" successful.');
        }
        break;
      case 'unsubscribe':
        {
          print(
              'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test".');
          await FirebaseMessaging.instance.unsubscribeFromTopic('fcm_test');
          print(
              'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test" successful.');
        }
        break;
      case 'get_apns_token':
        {
          if (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS) {
            print('FlutterFire Messaging Example: Getting APNs token...');
            String token = await FirebaseMessaging.instance.getAPNSToken();
            print('FlutterFire Messaging Example: Got APNs token: $token');
          } else {
            print(
                'FlutterFire Messaging Example: Getting an APNs token is only supported on iOS and macOS platforms.');
          }
        }
        break;
      default:
        break;
    }
  }

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    sendPushMessage();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return ChangeNotifierProvider(
        create: (context) => SearchProvider(),
        child: ChangeNotifierProvider(
          create: (context) => SelectedCommunityProvider(),
          // child:   ChangeNotifierProvider(
          //    create: (context) => FileDownloaderProvider(),
          child: ChangeNotifierProvider(
            create: (context) => CommunityProvider(),
            child: ChangeNotifierProvider(
                create: (context) => CategoriesProvider(),
                child: ChangeNotifierProvider(
                    create: (context) => DiscoverProvider(),
                    child: ChangeNotifierProvider(
                      create: (context) => BrowseProvider(),
                      child: ChangeNotifierProvider(
                          create: (context) => PlayerChange(),
                          child: Provider(
                              create: (context) => AuthBloc(),
                              child: ChangeNotifierProvider(
                                create: (context) => SortFilterPreferences(),
                                child: MaterialApp(
                                  debugShowCheckedModeBanner: false,
                                  navigatorKey: navigatorKey,
                                  

                                  title: 'Aureal',
                                  theme: widget.themeProvider.themeData(),
                                  home: Wallet(),
                                  // home: TemporaryError(),
                                  // initialRoute: HiveAccount.id,
                                  routes: {
                                    PostRSSFeed.id: (context) => PostRSSFeed(),
                                    //       EmailVerificationDialog.id :(context)=> EmailVerificationDialog(),
                                    PopError.id: (context) => PopError(),
                                    EditPodcast.id: (context) => EditPodcast(),
                                    // Recorder.id: (context) => Recorder(),
                                    Home.id: (context) => Home(),
                                    RecorderDashboard.id: (context) =>
                                        RecorderDashboard(),
                                    Messages.id: (context) => Messages(),
                                    Search.id: (context) => Search(),
                                    Profile.id: (context) => Profile(),
                                    DownloadPage.id: (context) =>
                                        DownloadPage(),
                                    NotificationPage.id: (context) =>
                                        NotificationPage(),
                                    Login.id: (context) => Login(),
                                    SignUp.id: (context) => SignUp(),
                                    Player.id: (context) => Player(),
                                    Welcome.id: (context) => Welcome(),
                                    Profile.id: (context) => Profile(),
                                    Settings.id: (context) => Settings(),
                                    AccountSettings.id: (context) =>
                                        AccountSettings(),
                                    Notifications.id: (context) =>
                                        Notifications(),
                                    MobileNotifications.id: (context) =>
                                        MobileNotifications(),
                                    EmailNotifications.id: (context) =>
                                        EmailNotifications(),
                                    Security.id: (context) => Security(),
                                    SoundEditor.id: (context) => SoundEditor(),
                                    CreatePodcast.id: (context) =>
                                        CreatePodcast(),
                                    CategoryView.id: (context) =>
                                        CategoryView(),
                                    Wrapper.id: (context) => Wrapper(),
                                    Bio.id: (context) => Bio(),
                                    Presence.id: (context) => Presence(),
                                    SelectLanguage.id: (context) =>
                                        SelectLanguage(),
                                    OnboardingCategories.id: (context) =>
                                        OnboardingCategories(),
                                    SelectPodcast.id: (context) =>
                                        SelectPodcast(),
                                    TemporaryError.id: (context) =>
                                        TemporaryError(),
                                    HiveAccount.id: (context) => HiveAccount(),
                                    TagSearch.id: (context) => TagSearch(),
                                    Wallet.id: (context) => Wallet(),
                                    CommunityView.id: (context) =>
                                        CommunityView(),
                                    //      Noti.id: (context) => Noti(),
                                    HiveDetails.id: (context) => HiveDetails(),
                                    CommunitySearch.id: (context) =>
                                        CommunitySearch(),
                                    Prefrences.id: (context) => Prefrences(),
                                    // HomePage.id: (context) =>
                                    //  HomePage(),

                                    // Download.id: (context) =>
                                    //     Download(),
                                  },
                                ),
                              ))),
                    ))),
          ),
          // ),
        ));
  }
}

class SplashScreenPage extends StatelessWidget {
  Widget _home = Welcome();

  Dio dio = Dio();

  void checkAuthenticity(BuildContext context) async {
    // var setCategories = Provider.of<CategoriesProvider>(context);
    // await setCategories.getCategories();
    String url = 'https://api.aureal.one/public/getToken';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userId')) {
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      // print(map.toString());
      // print(prefs.containsKey('userId'));
      FormData formData = FormData.fromMap(map);
      try {
        // print(url);
        // print(map.toString());
        var response = await dio.post(url, data: formData);
        print(response.statusCode);
        if (response.statusCode == 200) {
          print(response.data.toString());
          prefs.setString(
              'access_token', response.data['updatedUser']['access_token']);
          prefs.setString('token', response.data['updatedUser']['token']);
          prefs.setString(
              'displayPicture', response.data['updatedUser']['img']);
          prefs.setString('userName', response.data['updatedUser']['username']);
          print(prefs.getString('token'));
          DiscoverProvider discoverData =
              Provider.of<DiscoverProvider>(context, listen: false);
          if (discoverData.isFetcheddiscoverList == false) {
            await discoverData.getDiscoverProvider();
            _home = Home();
          }
          // var categoryBuild = Provider.of<CategoriesProvider>(context);
          // // var communities = Provider.of<CommunityProvider>(context);
          // categoryBuild.getCategories();
        } else {
          _home = Welcome();
        }
      } catch (e) {
        _home = Welcome();
      }
    } else {
      _home = Welcome();
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return _home;
    }));

    counter = counter + 1;
  }

  letsRoute(BuildContext context) {}
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    if (counter < 1) {
      checkAuthenticity(context);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.width / 1.8,
          width: MediaQuery.of(context).size.width / 1.8,
          child: Image.asset('assets/images/pulsate.gif'),
        ),
      ),
    );
  }
}
