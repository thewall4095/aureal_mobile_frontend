import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Clips.dart';
import 'package:auditory/screens/Library.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Profiles/PlaylistView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/UserProfile.dart';
import 'package:auditory/utilities/getRoomDetails.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:jitsi_meet/feature_flag/feature_flag_enum.dart' as featureflag;
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:marquee/marquee.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';

import '../NotificationProvider.dart';
import '../PlayerState.dart';
import '../models/message.dart';
import 'DiscoverPage.dart';
import 'FollowingPage.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/Player.dart';
import 'Player/PlayerElements/Seekbar.dart';
import 'Profiles/EpisodeView.dart';
import 'Profiles/PodcastView.dart';
import 'Profiles/publicUserProfile.dart';
import 'RoomsPage.dart';
import 'RouteAnimation.dart';
import 'buttonPages/Downloads.dart';
import 'buttonPages/HiveWallet.dart';
import 'buttonPages/Notification.dart';
import 'buttonPages/Profile.dart';
import 'buttonPages/search.dart';
import 'buttonPages/settings/Theme-.dart';

bool _initialUriIsHandled = true;

enum PlayerState {
  playing,
  stopped,
}

class Home extends StatefulWidget {
  // String username;
  // String userId;
  // Home({@required this.userId, @required this.username});

  static const String id = "Homepage";

  @override
  _HomeState createState() => _HomeState();
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  print('home + adasdasdas +  ' + message['data']);

  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  // Or do other work.
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int counter = 0;
  Dio dio = Dio();
  String userName;
  String status = 'hidden';
  String userId;
  List<Message> messages = [];

  void addExistingPodcast(var somevariable) async {
    ScrollController _scrollController = ScrollController();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final notificationPlugin = Provider.of<NotificationPlugin>(context);
    String url = 'https://api.aureal.one/public/createFromRSS';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['url'] = somevariable;
  }

  void getCategoryData(BuildContext context) async {
    var category = Provider.of<CategoriesProvider>(context);
    await category.getCategories();
  }

  void getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/private/users?user_id=${prefs.getString('userId')}';
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer ${prefs.getString('token')}"
    };

    try {
      http.Response response = await http.get(Uri.parse(url), headers: header);
      if (response.statusCode == 200) {
        if (this.mounted) {
          setState(() {
            prefs.setString(
                'FullName', jsonDecode(response.body)['users']['fullname']);

            prefs.setString(
                'userName', jsonDecode(response.body)['users']['username']);
            // displayPicture = jsonDecode(response.body)['users']['img'];
            status = jsonDecode(response.body)['users']['settings']['Account']
                ['Presence'];

            prefs.getString('HiveUserName');
            jsonDecode(response.body)['users']['email'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  int _selectedIndex = 0;

  var currentlyPlaying;

  void _onItemTapped(int index) {
    if (this.mounted) {
      setState(() {
        _selectedIndex = index;
        print(_selectedIndex);
      });
    }
  }

  Widget _createPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        return Feed();
        break;

      case 1:
        return DiscoverPage();
        break;

      case 2:
        return LibraryPage();
        break;

      case 3:
        // return BrowsePage();
        return Clips();
        break;

      // case 4:
      //   return RoomsPage();
      //   break;
    }
  }

  void getLocalData() async {
    prefs = await SharedPreferences.getInstance();
    print(prefs.getString('token'));
    if (this.mounted) {
      setState(() {
        displayPicture = prefs.getString('displayPicture');
        username = prefs.getString('HiveUserName');
      });
    }
  }

  String displayPicture;

  SharedPreferences prefs;
  String username;

  void setLocalData() async {
    prefs = await SharedPreferences.getInstance();
  }

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      Scaffold.of(_scaffoldKey.currentContext)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  postreq.Interceptor intercept = postreq.Interceptor();

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

  _joinMeeting({String roomId, String roomName, String hostUserId}) async {
    // Enable or disable any feature flag here
    // If feature flag are not provided, default values will be used
    // Full list of feature flags (and defaults) available in the README
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
      FeatureFlagEnum.CHAT_ENABLED: false,
    };
    if (!kIsWeb) {
      // Here is an example, disabling features for each platform
      if (Platform.isAndroid) {
        // Disable ConnectionService usage on Android to avoid issues (see README)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        // Disable PIP on iOS as it looks weird
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isAudioMuted = true;
    bool isVideoMuted = true;

    var options = JitsiMeetingOptions(room: roomId)
      ..serverURL = 'https://sessions.aureal.one'
      ..subject = roomName
      ..userDisplayName = prefs.getString("HiveUserName")
      ..userEmail = 'emailText.text'
      // ..iosAppBarRGBAColor = iosAppBarRGBAColor.text
      ..audioOnly = true
      ..audioMuted = isAudioMuted
      ..videoMuted = isVideoMuted
      ..featureFlags.addAll(featureFlags)
      ..webOptions = {
        "roomName": roomName,
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "userInfo": {
          "displayName": prefs.getString('userName'),
          'avatarUrl': prefs.getString('displayPicture')
        }
      };

    debugPrint("JitsiMeetingOptions: $options");

    await JitsiMeet.joinMeeting(
      options,
      listener: JitsiMeetingListener(
          onConferenceWillJoin: (message) {
            debugPrint("${options.room} will join with message: $message");
          },
          onConferenceJoined: (message) {
            debugPrint("${options.room} joined with message: $message");
          },
          onConferenceTerminated: (message) {
            debugPrint("${options.room} terminated with message: $message");
          },
          genericListeners: [
            JitsiGenericListener(
                eventName: 'onConferenceTerminated',
                callback: (dynamic message) {
                  if (hostUserId == prefs.getString("userId")) {
                    hostLeft(roomId);
                  }
                  debugPrint("readyToClose callback");
                }),
          ]),
    );
  }

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

  Uri _initialUri;
  Uri _latestUri;
  Object _err;
  StreamSubscription _sub;

  /// Handle incoming links - the ones that the app will recieve from the OS
  /// while already started.
  void _handleIncomingLinks() {
    if (!kIsWeb) {
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _sub = uriLinkStream.listen((Uri uri) {
        if (!mounted) return;
        print('got uri: $uri');
        setState(() {
          _latestUri = uri;
          _err = null;
        });

        if (_latestUri.toString().contains('episode') == true) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) {
            return EpisodeView(
              episodeId: _latestUri
                  .toString()
                  .split('/')[_latestUri.toString().split('/').length - 1],
            );
          }));
        }
        if (_latestUri.toString().contains('podcast') == true) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) {
            return PodcastView(
              _latestUri
                  .toString()
                  .split('/')[_latestUri.toString().split('/').length - 1],
            );
          }));
        }
        if (_latestUri.toString().contains('rooms-live') == true) {
          getRoomDetails(_latestUri.toString().split('rooms-live/')[1])
              .then((value) {
            if (value['hostuserid'] != prefs.getString('userId')) {
              addRoomParticipant(roomid: value['roomid']);
            } else {
              hostJoined(value['roomid']);
            }
            _joinMeeting(
                roomId: value['roomid'],
                roomName: value['title'],
                hostUserId: value['hostuserid']);
          });
        }
        if (_latestUri.toString().contains('playlist') == true) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) {
            return PlaylistView(
              playlistId: _latestUri
                  .toString()
                  .split('/')[uri.toString().split('/').length - 1],
            );
          }));
        }
        if (_latestUri.toString().contains('user') == true) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) {
            return PublicProfile(
              userId: _latestUri
                  .toString()
                  .split('/')[uri.toString().split('/').length - 1],
            );
          }));
        }

        // if (uri.toString().contains('episode') == true) {
        //   Navigator.push(context, CupertinoPageRoute(builder: (context) {
        //     return EpisodeView(
        //       episodeId: uri
        //           .toString()
        //           .split('/')[uri.toString().split('/').length - 1],
        //     );
        //   }));
        // }
        // if (uri.toString().contains('episode') == true) {
        //   Navigator.push(context, CupertinoPageRoute(builder: (context) {
        //     return EpisodeView(
        //       episodeId: uri
        //           .toString()
        //           .split('/')[uri.toString().split('/').length - 1],
        //     );
        //   }));
        // }

        print(_latestUri);
      }, onError: (Object err) {
        if (!mounted) return;
        print('got err: $err');
        setState(() {
          _latestUri = null;
          if (err is FormatException) {
            _err = err;
          } else {
            _err = null;
          }
        });
      });
    }
  }

  /// Handle the initial Uri - the one the app was started with
  ///
  /// **ATTENTION**: `getInitialLink`/`getInitialUri` should be handled
  /// ONLY ONCE in your app's lifetime, since it is not meant to change
  /// throughout your app's life.
  ///
  /// We handle all exceptions, since it is called from initState.
  Future<void> _handleInitialUri() async {
    // In this example app this is an almost useless guard, but it is here to
    // show we are not going to call getInitialUri multiple times, even if this
    // was a weidget that will be disposed of (ex. a navigation route change).
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      // _showSnackBar('_handleInitialUri called');
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          print('no initial uri');
        } else {
          print('got initial uri: $uri');
          if (uri.toString().contains('episode') == true) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return EpisodeView(
                episodeId: uri
                    .toString()
                    .split('/')[uri.toString().split('/').length - 1],
              );
            }));
          }
          if (uri.toString().contains('podcast') == true) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return PodcastView(
                uri.toString().split('/')[uri.toString().split('/').length - 1],
              );
            }));
          }
          if (uri.toString().contains('rooms-live') == true) {
            getRoomDetails(uri.toString().split('rooms-live/')[1])
                .then((value) {
              if (value['hostuserid'] != prefs.getString('userId')) {
                addRoomParticipant(roomid: value['roomid']);
              } else {
                hostJoined(value['roomid']);
              }
              _joinMeeting(
                  roomId: value['roomid'],
                  roomName: value['title'],
                  hostUserId: value['hostuserid']);
            });
          }
          if (uri.toString().contains('playlist') == true) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return PlaylistView(
                playlistId: uri
                    .toString()
                    .split('/')[uri.toString().split('/').length - 1],
              );
            }));
          }
          if (uri.toString().contains('user') == true) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) {
              return PublicProfile(
                userId: uri
                    .toString()
                    .split('/')[uri.toString().split('/').length - 1],
              );
            }));
          }
          // if (uri.toString().contains('episode') == true) {
          //   Navigator.push(context, CupertinoPageRoute(builder: (context) {
          //     return EpisodeView(
          //       episodeId: uri
          //           .toString()
          //           .split('/')[uri.toString().split('/').length - 1],
          //     );
          //   }));
          // }
          // if (uri.toString().contains('episode') == true) {
          //   Navigator.push(context, CupertinoPageRoute(builder: (context) {
          //     return EpisodeView(
          //       episodeId: uri
          //           .toString()
          //           .split('/')[uri.toString().split('/').length - 1],
          //     );
          //   }));
          // }
        }
        if (!mounted) return;
        setState(() => _initialUri = uri);
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        print('falied to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        print('malformed initial uri');
        setState(() => _err = err);
      }
    }
  }

  @override
  void initState() {
    setLocalData();
    // TODO: implement initState

    getUserDetails();

    // MediaNotification.setListener('pause', () {
    //   setState(() => status = 'pause');
    // });
    // MediaNotification.setListener('play', () {
    //   setState(() => status = 'play');
    // });
    // MediaNotification.setListener('next', () {});
    // MediaNotification.setListener('prev', () {});
    // MediaNotification.setListener('select', () {});

    getLocalData();
    _handleIncomingLinks();
    _handleInitialUri();
    super.initState();
  }

  bool open = false;
  var notificationList = [];
  int countNotification = 10;
  Launcher launcher = Launcher();

  @override
  void dispose() {
    // TODO: implement dispose
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    // getUserDetails();
    var category = Provider.of<CategoriesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (category.isFetchedCategories == false) {
      getCategoryData(context);
    }
    SizeConfig().init(context);
    int count = 0;
    return Scaffold(
      backgroundColor: Color(0xff161616),
      appBar: AppBar(
        backgroundColor: Color(0xff161616),
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(CupertinoPageRoute(builder: (context) => Profile()));
            },
            icon: CircleAvatar(
              radius: SizeConfig.safeBlockHorizontal * 6,
              backgroundImage: CachedNetworkImageProvider(
                displayPicture == null
                    ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                    : displayPicture,
                scale: 0.5,
              ),
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.pushNamed(context, NotificationPage.id);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              //     color: Colors.white,
            ),
            onPressed: () async {
              await showSearch(
                  context: context, delegate: SearchFunctionality());
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert_outlined),
            onPressed: () {
              showBarModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Platform.isAndroid != true
                              ? SizedBox()
                              : ListTile(
                                  onTap: () {
                                    Navigator.push(context,
                                        CupertinoPageRoute(builder: (context) {
                                      return DownloadPage();
                                    }));
                                  },
                                  leading: Icon(Icons.arrow_circle_down),
                                  title: Text("Downloads"),
                                ),
                          ListTile(
                            onTap: () {
                              Navigator.push(context,
                                  CupertinoPageRoute(builder: (context) {
                                return ClipScreen();
                              }));
                            },
                            leading: Icon(Icons.text_snippet),
                            title: Text("Clips"),
                          ),
                          ListTile(
                            onTap: () {
                              if (prefs.getString('HiveUserName') != null) {
                                print('Wallet Pressed');
                                Navigator.pushNamed(context, Wallet.id);
                              } else {
                                showBarModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return HiveDetails();
                                    });
                              }
                            },
                            leading: Icon(FontAwesomeIcons.hive),
                            title: Text("Wallet"),
                          )
                        ],
                      ),
                    );
                  });
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            themeProvider.isLightTheme == false ? Colors.black : Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        unselectedItemColor:
            themeProvider.isLightTheme == true ? Colors.black : Colors.white,
        selectedItemColor: Colors.blue,
        //Color(0xff5bc3ef),
        // backgroundColor: Colors.transparent,
        items: <BottomNavigationBarItem>[
          // BottomNavigationBarItem(
          //   icon: Icon(
          //     Icons.stream,
          //   ),
          //   activeIcon: Icon(Icons.stream),
          //   label: '',
          // ),

          BottomNavigationBarItem(
            label: "",
            icon: Icon(
              Icons.home_sharp,
              size: 30,
            ),
            activeIcon: Icon(
              Icons.home_rounded,
              size: 30,
            ),
          ),
          BottomNavigationBarItem(
            label: "",
            icon: Icon(FontAwesomeIcons.compass),
            activeIcon: Icon(FontAwesomeIcons.solidCompass),
          ),
          BottomNavigationBarItem(
            label: "",
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
          ),
          BottomNavigationBarItem(
            label: "",
            icon: Icon(Icons.casino_outlined),
            activeIcon: Icon(Icons.casino_outlined),
          )
          // BottomNavigationBarItem(
          //   label: "",
          //   icon: Icon(
          //     Icons.perm_identity,
          //     size: 28,
          //   ),
          //   activeIcon: Icon(
          //     Icons.person,
          //     size: 28,
          //   ),
          // ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      bottomSheet: BottomPlayer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      body: DoubleBackToCloseApp(
          snackBar: const SnackBar(
            content: Text('Tap back again to leave'),
          ),
          child: _createPage(context, _selectedIndex)),
    );
  }
}

class BottomPlayer extends StatefulWidget {
  @override
  _BottomPlayerState createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  // MusicPlayer player;

  PlayerState playerstate = PlayerState.playing;

  ScrollController _controller = ScrollController();

  var status;
  bool _hasBeenPressed = false;

  SharedPreferences prefs;

  getLocalData() async {
    prefs = await SharedPreferences.getInstance();
  }

  String changingDuration = '0.0';

  Duration _visibleValue;
  bool listenOnlyUserInteraction = false;
  double get percent => duration.inMilliseconds == 0
      ? 0
      : _visibleValue.inMilliseconds / duration.inMilliseconds;

  void durationToString(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes =
        twoDigits(duration.inMinutes.remainder(Duration.minutesPerHour));
    String twoDigitSeconds =
        twoDigits(duration.inSeconds.remainder(Duration.secondsPerMinute));

    setState(() {
      changingDuration = "$twoDigitMinutes:$twoDigitSeconds";
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    // episodeObject.episodeViewed(
    //     episodeObject.audioPlayer.current.value.audio.audio.metas.id);

    super.initState();
  }

  int count = 0;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var episodeObject = Provider.of<PlayerChange>(context);

    // if (episodeObject.episodeObject != null) {
    //   episodeObject.audioPlayer.currentPosition.listen((event) {
    //     if (episodeObject.audioPlayer.currentPosition.value ==
    //         episodeObject.audioPlayer.realtimePlayingInfos.value.duration) {
    //       episodeObject.customNextAction(episodeObject.audioPlayer);
    //     }
    //   });
    // }

    return GestureDetector(
      onTap: () {
        showBarModalBottomSheet(
            bounce: true,
            context: context,
            builder: (context) {
              return Player();
            });
        // Navigator.pushNamed(context, Player.id);
      },
      child: Dismissible(
        key: UniqueKey(),
        onDismissed: (direction) {
          setState(() {
            episodeObject.episodeName = null;
            episodeObject.pause();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xff161616),
          ),
          child: episodeObject.audioPlayer.builderRealtimePlayingInfos(
              builder: (context, infos) {
            if (infos == null) {
              return SizedBox(
                height: 0,
                width: 0,
              );
            } else {
              if (infos.isBuffering == true) {
                return SizedBox();
              } else {
                if (count == 0) {
                  episodeObject
                      .episodeViewed(infos.current.audio.audio.metas.id);
                  count++;
                }

                return ListTile(
                  trailing: infos.isPlaying == true
                      ? IconButton(
                          splashColor: Colors.transparent,
                          icon: Icon(
                            Icons.pause,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            episodeObject.audioPlayer.pause();
                          },
                        )
                      : IconButton(
                          splashColor: Colors.blue,
                          icon: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            episodeObject.resume();
                          },
                        ),
                  leading: CachedNetworkImage(
                    width: 40,
                    height: 40,
                    imageUrl: infos.current.audio.audio.metas.image.path,
                    imageBuilder: (context, imageProvider) {
                      return Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover)),
                      );
                    },
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      "${infos.current.audio.audio.metas.title}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }
            }
          }),
        ),
      ),
    );
  }
}
