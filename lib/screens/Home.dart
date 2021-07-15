import 'dart:async';
import 'dart:convert';
import 'dart:io';
import "package:badges/badges.dart";
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import '../NotificationProvider.dart';
import '../PlayerState.dart';
import '../models/message.dart';
import 'CommunityPage.dart';
import 'DiscoverPage.dart';
import 'FollowingPage.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/Player.dart';
import 'Profiles/EpisodeView.dart';
import 'Profiles/PodcastView.dart';
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

  int _selectedIndex = 2;

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
        return CommunityPage();
        break;

      case 1:
        return FollowingPage();
        break;

      case 2:
        return DiscoverPage();
        break;

      case 3:
        // return BrowsePage();
        return Profile();
        break;

      // case 3:
      //   return Player();
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
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return EpisodeView(
              episodeId: _latestUri
                  .toString()
                  .split('/')[_latestUri.toString().split('/').length - 1],
            );
          }));
        }
        if (_latestUri.toString().contains('podcast') == true) {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return PodcastView(
              _latestUri
                  .toString()
                  .split('/')[_latestUri.toString().split('/').length - 1],
            );
          }));
        }
        // if (uri.toString().contains('episode') == true) {
        //   Navigator.push(context, MaterialPageRoute(builder: (context) {
        //     return EpisodeView(
        //       episodeId: uri
        //           .toString()
        //           .split('/')[uri.toString().split('/').length - 1],
        //     );
        //   }));
        // }
        // if (uri.toString().contains('episode') == true) {
        //   Navigator.push(context, MaterialPageRoute(builder: (context) {
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
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return EpisodeView(
                episodeId: uri
                    .toString()
                    .split('/')[uri.toString().split('/').length - 1],
              );
            }));
          }
          if (uri.toString().contains('podcast') == true) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return PodcastView(
                uri.toString().split('/')[uri.toString().split('/').length - 1],
              );
            }));
          }
          // if (uri.toString().contains('episode') == true) {
          //   Navigator.push(context, MaterialPageRoute(builder: (context) {
          //     return EpisodeView(
          //       episodeId: uri
          //           .toString()
          //           .split('/')[uri.toString().split('/').length - 1],
          //     );
          //   }));
          // }
          // if (uri.toString().contains('episode') == true) {
          //   Navigator.push(context, MaterialPageRoute(builder: (context) {
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

    MediaNotification.setListener('pause', () {
      setState(() => status = 'pause');
    });
    MediaNotification.setListener('play', () {
      setState(() => status = 'play');
    });
    MediaNotification.setListener('next', () {});
    MediaNotification.setListener('prev', () {});
    MediaNotification.setListener('select', () {});

    getLocalData();
    _handleIncomingLinks();
    _handleInitialUri();
    super.initState();
  }

  bool open = false;
  var notificationList = [];
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
      appBar: AppBar(
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Profile();
              }));
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
            icon: Icon(Icons.account_balance_wallet_outlined),
            onPressed: () {
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
          ),
          Platform.isAndroid == true
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_circle_down_outlined,
                    //    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, DownloadPage.id);
                  },
                )
              : SizedBox(height: 0, width: 0),
          Center(
            child: IconButton(

              icon: Badge(
                badgeColor: Colors.blue,
                badgeContent: Text(
              "$count"

                ),
                child: Icon(
                  Icons.notifications_none,
                  //    color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, NotificationPage.id);
              },
            ),
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
          BottomNavigationBarItem(
            icon: Icon(
              Icons.stream,
            ),
            activeIcon: Icon(Icons.stream),
            label: '',
          ),
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
      body: _createPage(context, _selectedIndex),
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

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var episodeObject = Provider.of<PlayerChange>(context);

    return episodeObject.episodeName != null
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                showBarModalBottomSheet(
                    //    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) {
                      return Container(
                        height: 720,
                        child: Player(),
                      );
                    });
                // Navigator.pushNamed(context, Player.id);
              },
              child: Container(
                height: SizeConfig.safeBlockVertical * 6,
                width: double.infinity,

                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        episodeObject.audioPlayer.builderRealtimePlayingInfos(
                            builder: (context, infos) {
                          if (infos == null) {
                            return SizedBox(
                              height: 0,
                              width: 0,
                            );
                          } else {
                            if (infos.isBuffering == true) {
                              return SpinKitCircle(
                                size: 15,
                                color: Colors.white,
                              );
                            } else {
                              if (infos.isPlaying == true) {
                                return IconButton(
                                  splashColor: Colors.blue,
                                  icon: Icon(
                                    Icons.pause,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    episodeObject.pause();
                                  },
                                );
                              } else {
                                return IconButton(
                                  splashColor: Colors.blue,
                                  icon: Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    episodeObject.resume();
                                  },
                                );
                              }
                            }
                          }
                        }),
                        InkWell(
                          onTap: () {
                            {
                              if (episodeObject.permlink == null) {
                              } else {
                                if (prefs.getString('HiveUserName') != null) {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: UpvoteEpisode(
                                                episode_id: episodeObject.id,
                                                permlink:
                                                    episodeObject.permlink));
                                      }).then((value) async {
                                    print(value);
                                  });

                                  // upvoteEpisode(
                                  //     episode_id: episodeObject.id,
                                  //     permlink: episodeObject.permlink);
                                  Fluttertoast.showToast(msg: 'Upvote done');
                                } else {
                                  Fluttertoast.showToast(
                                      msg: 'Please connect your Hive Account');
                                  showBarModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return HiveDetails();
                                      });
                                }
                              }
                            }
                          },
                          child: IconButton(
                            icon: Icon(
                              FontAwesomeIcons.chevronCircleUp,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Fluttertoast.showToast(msg: 'Upvote done');
                              if (episodeObject.permlink == null) {
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: UpvoteEpisode(
                                              episode_id: episodeObject.id,
                                              permlink:
                                                  episodeObject.permlink));
                                    }).then((value) async {
                                  print(value);
                                });

                                // upvoteEpisode(
                                //     episode_id:
                                //         episodeObject
                                //             .id,
                                //     permlink:
                                //         episodeObject
                                //             .permlink);
                              }
                            },
                          ),
                          // child: Padding(
                          //   padding: const EdgeInsets.all(3.0),
                          //   child: IconButton(
                          //     onPressed: () {},
                          //     splashColor: Colors.blue,
                          //     icon: Icon(
                          //       FontAwesomeIcons.chevronCircleUp,
                          //       // color: _hasBeenPressed ? Colors.blue : Colors.black,
                          //       //color: Colors.white,
                          //     ),
                          //
                          //   ),
                          //
                          // ),
                        ),
                        Container(
                          height: 40,
                          width: MediaQuery.of(context).size.width / 1.5,
                          child: Marquee(
                            pauseAfterRound: Duration(seconds: 2),
                            text: ' ${episodeObject.episodeName} ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                            blankSpace: 100,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        : SizedBox(
            height: 0,
          );
  }
}
