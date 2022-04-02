import 'dart:async';
import 'dart:io';

import 'package:auditory/Accounts/HiveAccount.dart';
import 'package:auditory/BrowseProvider.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/DiscoverProvider.dart';
import 'package:auditory/FilterState.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/SelectedCommunitiesProvider.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/Wrapper.dart';
import 'package:auditory/screens/CommunityPages/CommunitySearch.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/screens/Profiles/publicUserProfile.dart';
import 'package:auditory/screens/buttonPages/Bio.dart';
import 'package:auditory/screens/buttonPages/HiveWallet.dart';
import 'package:auditory/screens/buttonPages/settings/Prefrences.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/screens/buttonPages/settings/security/AccountSettings/Presence.dart';
import 'package:auditory/screens/errorScreens/PopError.dart';
import 'package:auditory/screens/errorScreens/TemporaryError.dart';
import 'package:auditory/screens/recorderApp/recorderpages/PostRSSFeed.dart';
import 'package:auditory/utilities/TagSearch.dart';
import 'package:auditory/utilities/getRoomDetails.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:in_app_update/in_app_update.dart';
// import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:provider/provider.dart' as pro;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'SearchProvider.dart';
import 'Services/rating_service.dart';
import 'screens/Home.dart';
import 'screens/LoginSignup/Auth.dart';
import 'screens/LoginSignup/Login.dart';
import 'screens/LoginSignup/SignUp.dart';
import 'screens/LoginSignup/WelcomeScreen.dart';
import 'screens/Onboarding/Categories.dart';
import 'screens/Onboarding/LanguageSelection.dart';
import 'screens/buttonPages/Downloads.dart';
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
    ThemeProvider themeProvider = pro.Provider.of<ThemeProvider>(context);
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

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _MyAppState extends State<MyApp> {
  // AppUpdateInfo _updateInfo;

  bool _flexibleUpdateAvailable = false;
  String _token;

  // Future<void> checkForUpdate() async {
  //   InAppUpdate.checkForUpdate().then((info) {
  //     setState(() {
  //       _updateInfo = info;
  //     });
  //   }).catchError((e) {
  //     showSnack(e.toString());
  //   });
  // }

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      Scaffold.of(_scaffoldKey.currentContext)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  AppUpdateInfo _updateInfo;
  Future<void> checkForUpdate() async {
    try {
      if (Platform.isAndroid) {
        InAppUpdate.checkForUpdate().then((info) {
          setState(() {
            _updateInfo = info;
          });
        }).catchError((error) => print(error));

        if (_updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable) {
          InAppUpdate.performImmediateUpdate()
              .catchError((error) => print(error));
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    checkForUpdate();
    // TODO: implement initState
    super.initState();

    Timer(const Duration(seconds: 2), () {
      _ratingService.isSecondTimeOpen().then((secondOpen) {
        if (secondOpen) {
          _ratingService.showRating();
        }
      });
    });
  }

  void _showSnackBar(String msg) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final context = _scaffoldKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
        ));
      }
    });
  }

  int _messageCount = 0;

  final navigatorKey = GlobalKey<NavigatorState>();

  final RatingService _ratingService = RatingService();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        // statusBarColor: Colors.transparent,
        ));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return pro.ChangeNotifierProvider(
      create: (context) => SearchResultProvider(),
      child: pro.ChangeNotifierProvider(
          create: (context) => SearchProvider(),
          child: pro.ChangeNotifierProvider(
            create: (context) => SelectedCommunityProvider(),
            // child:   ChangeNotifierProvider(
            //    create: (context) => FileDownloaderProvider(),
            child: pro.ChangeNotifierProvider(
              create: (context) => CommunityProvider(),
              child: pro.ChangeNotifierProvider(
                  create: (context) => CategoriesProvider(),
                  child: pro.ChangeNotifierProvider(
                      create: (context) => DiscoverProvider(),
                      child: pro.ChangeNotifierProvider(
                        create: (context) => BrowseProvider(),
                        child: pro.ChangeNotifierProvider(
                            create: (context) => PlayerChange(),
                            child: pro.Provider(
                                create: (context) => AuthBloc(),
                                child: pro.ChangeNotifierProvider(
                                  create: (context) => SortFilterPreferences(),
                                  child: MaterialApp(
                                    debugShowCheckedModeBanner: false,
                                    navigatorKey: navigatorKey,
                                    darkTheme: ThemeData.dark(),
                                    themeMode: ThemeMode.light,
                                    title: 'Aureal',
                                    theme: widget.themeProvider.themeData(),
                                    home: SplashScreenPage(),
                                    // home: OnboardingCategories(),
                                    // initialRoute: HiveAccount.id,
                                    routes: {
                                      PostRSSFeed.id: (context) =>
                                          PostRSSFeed(),
                                      //       EmailVerificationDialog.id :(context)=> EmailVerificationDialog(),
                                      PopError.id: (context) => PopError(),

                                      // Recorder.id: (context) => Recorder(),
                                      Home.id: (context) => Home(),
                                      RecorderDashboard.id: (context) =>
                                          RecorderDashboard(),
                                      Messages.id: (context) => Messages(),
                                      // Search.id: (context) => Search(),
                                      Profile.id: (context) => Profile(),
                                      DownloadPage.id: (context) =>
                                          DownloadPage(),
                                      NotificationPage.id: (context) =>
                                          NotificationPage(),
                                      Login.id: (context) => Login(),
                                      SignUp.id: (context) => SignUp(),

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
                                      SoundEditor.id: (context) =>
                                          SoundEditor(),
                                      CreatePodcast.id: (context) =>
                                          CreatePodcast(),

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
                                      HiveAccount.id: (context) =>
                                          HiveAccount(),
                                      TagSearch.id: (context) => TagSearch(),
                                      Wallet.id: (context) => Wallet(),
                                      // CommunityView.id: (context) =>
                                      //     CommunityView(),
                                      //      Noti.id: (context) => Noti(),
                                      HiveDetails.id: (context) =>
                                          HiveDetails(),
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
          )),
    );
  }
}

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String registrationToken;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  Widget _home = Welcome();

  Dio dio = Dio();

  @override
  void initState() {
    // TODO: implement initState

    init();
    super.initState();
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  // _joinMeeting({String roomId, String roomName, String hostUserId}) async {
  //   // Enable or disable any feature flag here
  //   // If feature flag are not provided, default values will be used
  //   // Full list of feature flags (and defaults) available in the README
  //   Map<FeatureFlagEnum, bool> featureFlags = {
  //     FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
  //     FeatureFlagEnum.CHAT_ENABLED: false,
  //   };
  //   if (!kIsWeb) {
  //     // Here is an example, disabling features for each platform
  //     if (Platform.isAndroid) {
  //       // Disable ConnectionService usage on Android to avoid issues (see README)
  //       featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
  //     } else if (Platform.isIOS) {
  //       // Disable PIP on iOS as it looks weird
  //       featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
  //     }
  //   }
  //
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //
  //   bool isAudioMuted = true;
  //   bool isVideoMuted = true;
  //
  //   var options = JitsiMeetingOptions(room: roomId)
  //     ..serverURL = 'https://sessions.aureal.one'
  //     ..subject = roomName
  //     ..userDisplayName = prefs.getString("HiveUserName")
  //     ..userEmail = 'emailText.text'
  //     // ..iosAppBarRGBAColor = iosAppBarRGBAColor.text
  //     ..audioOnly = true
  //     ..audioMuted = isAudioMuted
  //     ..videoMuted = isVideoMuted
  //     ..featureFlags.addAll(featureFlags)
  //     ..webOptions = {
  //       "roomName": roomName,
  //       "width": "100%",
  //       "height": "100%",
  //       "enableWelcomePage": false,
  //       "chromeExtensionBanner": null,
  //       "userInfo": {
  //         "displayName": prefs.getString('userName'),
  //         'avatarUrl': prefs.getString('displayPicture')
  //       }
  //     };
  //
  //   debugPrint("JitsiMeetingOptions: $options");
  //
  //   await JitsiMeet.joinMeeting(
  //     options,
  //     listener: JitsiMeetingListener(
  //         onConferenceWillJoin: (message) {
  //           debugPrint("${options.room} will join with message: $message");
  //         },
  //         onConferenceJoined: (message) {
  //           debugPrint("${options.room} joined with message: $message");
  //         },
  //         onConferenceTerminated: (message) {
  //           debugPrint("${options.room} terminated with message: $message");
  //         },
  //         genericListeners: [
  //           JitsiGenericListener(
  //               eventName: 'onConferenceTerminated',
  //               callback: (dynamic message) {
  //                 if (hostUserId == prefs.getString("userId")) {
  //                   hostLeft(roomId);
  //                 }
  //                 debugPrint("readyToClose callback");
  //               }),
  //         ]),
  //   );
  // }

  void addRoomParticipant({String roomid}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/addRoomParticipant';

    var map = Map<String, dynamic>();
    map['roomid'] = roomid;
    map['userid'] = prefs.getString('userId');

    FormData formData = FormData.fromMap(map);
    try {
      var response = await dio.post(url, data: formData);
      print(response.data);
    } catch (e) {
      print(e);
    }
  }

  void hostLeft(var roomId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/hostLeft";

    var map = Map<String, dynamic>();
    map['userid'] = prefs.getString("userId");
    map['roomid'] = roomId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  void hostJoined(var roomId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/hostJoined";

    var map = Map<String, dynamic>();
    map['userid'] = prefs.getString("userId");
    map['roomid'] = roomId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  void _showSnackBar(String msg) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final context = _scaffoldKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
        ));
      }
    });
  }

  void init() async {
    if (counter < 1) {
      await checkAuthenticity(context);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      // print('${message.data}');
      // print(message.contentAvailable);

      if (message != null) {
        if (message.data['type'] != null) {
          if (message.data['type'] == 'vote_episode') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(episodeId: message.data['episode_id']);
            }));
          }
          if (message.data['type'] == 'reply_comment') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(episodeId: message.data['episode_id']);
            }));
          }
          if (message.data['type'] == 'comment_episode') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(episodeId: message.data['episode_id']);
            }));
          }
          if (message.data['type'] == 'episode_published') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(episodeId: message.data['episode_id']);
            }));
          }
          if (message.data['type'] == 'episode_published') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(
                episodeId: message.data['episode_id'],
              );
            }));
          }
          if (message.data['type'] == 'new_episode') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(
                episodeId: message.data['episode_id'],
              );
            }));
          }
          if (message.data['type'] == 'new_podcast') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return PodcastView(message.data['podcast_id']);
            }));
          }
          if (message.data['type'] == 'new_episode') {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(
                episodeId: message.data['episode_id'],
              );
            }));
          }
          if (message.data['type'] == 'room_active') {
            getRoomDetails(message.data['room_id']).then((value) {
              if (value['hostuserid'] != prefs.getString('userId')) {
                addRoomParticipant(roomid: value['roomid']);
              } else {
                hostJoined(value['roomid']);
              }
              // _joinMeeting(
              //     roomId: value['roomid'],
              //     roomName: value['title'],
              //     hostUserId: value['hostuserid']);
            });
          }
        } else {
          Navigator.push(context, CupertinoPageRoute(builder: (context) {
            return _home;
          }));
        }
      } else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return _home;
        }));
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
                importance: Importance.max,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: 'notification_icon',
              ),
            ));
        print(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          "it is coming here/////////////////////////////////////////////////");
      if (message.data['type'] == 'vote_episode') {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return EpisodeView(episodeId: message.data['episode_id']);
        }));
      }
      if (message.data['type'] == 'comment_reply') {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return EpisodeView(episodeId: message.data['episode_id']);
        }));
      }
      if (message.data['type'] == 'comment_episode') {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return EpisodeView(episodeId: message.data['episode_id']);
        }));
      }
      if (message.data['type'] == 'episode_published') {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return EpisodeView(episodeId: message.data['episode_id']);
        }));
      }
      if (message.data['type'] == 'new_podcast') {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return PodcastView(message.data['podcast_id']);
        }));
      }
      if (message.data['type'] == 'new_episode') {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return EpisodeView(
            episodeId: message.data['episode_id'],
          );
        }));
      }
      if (message.data['type'] == 'publish_first_episode') {}
      if (message.data['type'] == 'episode_published') {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return EpisodeView(
            episodeId: message.data['episode_id'],
          );
        }));
      }

      if (message.data['type'] == "used_referral_code") {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return PublicProfile(
            userId: message.data['user_id'],
          );
        }));
      }
      if (message.data['type'] == "followed_podcast") {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return PodcastView(message.data['podcast_id']);
        }));
      }
      if (message.data['type'] == "followed_user") {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return PublicProfile(userId: message.data['user_id']);
        }));
      }
      if (message.data['type'] == "used_referral_code") {
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return PublicProfile(
            userId: message.data['user_id'],
          );
        }));
      }
    });
  }

  void checkAuthenticity(BuildContext context) async {
    print("Came Here//////////////////////");

    String url = 'https://api.aureal.one/public/getToken';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userId')) {
      await _messaging.getToken().then((token) {
        setState(() {
          registrationToken = token;
        });
      });
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['registration_token'] = registrationToken;
      print(registrationToken);
      FormData formData = FormData.fromMap(map);
      try {
        var response = await dio.post(url, data: formData);

        if (response.statusCode == 200) {
          print("Response == 200 //////////////////////");
          print(response.data);

          setState(() {
            print("Came here too ///////////////////");
            prefs.setString(
                'access_token', response.data['updatedUser']['access_token']);
            print("Came here!!!!!!!!!!!!!!!!!!!");
            prefs.setString('token', response.data['updatedUser']['token']);
            print("Came here ---------------------");
            prefs.setString(
                'displayPicture', response.data['updatedUser']['img']);
            print("came here ----------------------");
            print(prefs.getString('userId'));
            // prefs.setString(
            //     'userName', response.data['updatedUser']['username']);
            // print(prefs.getString('userName'));
            print("Came here -----------------------");
            print(
                "${prefs.getString('userId')} //////////////////////////////////////");
          });

          print('${prefs.getString('userId')} /////////////////////');

          setState(() {
            _home = Home();
          });
        } else {
          setState(() {
            _home = Welcome();
          });
        }
      } catch (e) {
        print(e);
        setState(() {
          _home = Welcome();
        });
      }
    } else {
      setState(() {
        _home = Welcome();
      });
    }

    setState(() {
      counter = counter + 1;
    });
  }

  letsRoute(BuildContext context) {}

  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
