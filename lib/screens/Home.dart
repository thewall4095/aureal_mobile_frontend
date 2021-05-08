import 'dart:convert';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
// import 'package:music_player/music_player.dart';
import 'package:provider/provider.dart';
// import 'package:music_player/music_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../PlayerState.dart';
import '../models/message.dart';
import 'CommunityPage.dart';
import 'DiscoverPage.dart';
import 'FollowingPage.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/Player.dart';
import 'buttonPages/Downloads.dart';
import 'buttonPages/HiveWallet.dart';
import 'buttonPages/Notification.dart';
import 'buttonPages/Profile.dart';
import 'buttonPages/search.dart';

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

  int _selectedIndex = 1;

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

    super.initState();
  }

  bool open = false;

  Launcher launcher = Launcher();

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    // getUserDetails();
    var category = Provider.of<CategoriesProvider>(context);
    if (category.isFetchedCategories == false) {
      getCategoryData(context);
    }

    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        //  backgroundColor: Colors.transparent,
        // leading: InkWell(
        //     onTap: () {
        //       Navigator.push(context, MaterialPageRoute(builder: (context) {
        //         return Profile();
        //       }));
        //     },
        //     child: displayPicture != null
        //         ? CircleAvatar(
        //             radius: SizeConfig.safeBlockHorizontal * 2,
        //           )
        //         : CircleAvatar(
        //             radius: SizeConfig.safeBlockHorizontal * 2,
        //           )),
        leading: IconButton(
          onPressed: () {},
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
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              //    color: Colors.white,
            ),
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
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        //  unselectedItemColor: Colors.black54,
        selectedItemColor: Color(0xff5bc3ef),
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
            icon: Icon(FontAwesomeIcons.heart),
            activeIcon: Icon(FontAwesomeIcons.solidHeart),
          ),
          BottomNavigationBarItem(
            label: "",
            icon: Icon(FontAwesomeIcons.compass),
            activeIcon: Icon(FontAwesomeIcons.solidCompass),
          ),
          BottomNavigationBarItem(
            label: "",
            icon: Icon(
              Icons.perm_identity,
              size: 28,
            ),
            activeIcon: Icon(
              Icons.person,
              size: 28,
            ),
          ),
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
        ? GestureDetector(
            onTap: () {
              showBarModalBottomSheet(
                  //    backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) {
                    return Player();
                  });
              // Navigator.pushNamed(context, Player.id);
            },
            child: Container(
              height: SizeConfig.safeBlockVertical * 6,
              width: double.infinity,
              decoration: BoxDecoration(
                  //   color: kSecondaryColor,
                  //     border: Border(
                  //   top: BorderSide(color: Color(0xff171b27), width: 2.0),
                  //   bottom: BorderSide(color: Color(0xff171b27), width: 2.0),
                  // ),
                  ),
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
                                  //color: Colors.white,
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
                                  //    color: Colors.white,
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
                                upvoteEpisode(
                                    episode_id: episodeObject.id,
                                    permlink: episodeObject.permlink);
                              } else {
                                showBarModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return HiveDetails();
                                    });
                              }
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: IconButton(
                            onPressed: () {},
                            splashColor: Colors.blue,
                            icon: Icon(
                              FontAwesomeIcons.chevronCircleUp,
                              // color: _hasBeenPressed ? Colors.blue : Colors.black,
                              //color: Colors.white,
                            ),
                            // onPressed: () => {
                            // setState(() {
                            // _hasBeenPressed = !_hasBeenPressed;
                            // })

                            // }
                          ),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: MediaQuery.of(context).size.width / 1.5,
                        child: Marquee(
                          pauseAfterRound: Duration(seconds: 2),
                          text:
                              ' ${episodeObject.podcastName} - ${episodeObject.episodeName} ',
                          style: TextStyle(
                              //   color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                          blankSpace: 100,
//                  scrollAxis: Axis.horizontal,
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
          )
        : SizedBox(
            height: 0,
          );
  }
}
