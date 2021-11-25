import 'dart:convert';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/buttonPages/search.dart';
import 'package:auditory/utilities/Share.dart';
import 'dart:io';
import 'package:html/parser.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Player/PlayerElements/Seekbar.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:auditory/utilities/getRoomDetails.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../PlayerState.dart';
import '../Clips.dart';
import 'Comments.dart';
import 'PodcastView.dart';

class PublicProfile extends StatefulWidget {
  String userId;
  AssetsAudioPlayer audioPlayer;
  PublicProfile({
    @required this.userId,
    this.audioPlayer,
  });

  @override
  _PublicProfileState createState() => _PublicProfileState();
}

class _PublicProfileState extends State<PublicProfile>
    with TickerProviderStateMixin {
  var userData;
  List podcastList = [];
  List getSnippet = [];
  RegExp htmlMatch = RegExp(r'(\w+)');
  String discription;
  Launcher launcher = Launcher();
  List userRoom;

  var listSnippet;

  Dio dio = Dio();

  postreq.Interceptor intercept = postreq.Interceptor();

  bool ifFollowed;

  void follow() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/followAuthor";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['author_user_id'] = userData['id'];

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      if (jsonDecode(response.toString())['msg'] == 'unfollowed') {
        setState(() {
          ifFollowed = false;
        });
      } else {
        setState(() {
          ifFollowed = true;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void getProfileData() async {
    prefs = await SharedPreferences.getInstance();

    String url =
        'https://api.aureal.one/public/users?user_id=${widget.userId}&loggedinuser=${prefs.getString('userId')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          userData = jsonDecode(response.body)['users'];
          ifFollowed = userData['ifFollowsAuthor'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void userPodcast() async {
    String url =
        "https://api.aureal.one/public/podcast?user_id=${widget.userId}";
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          podcastList = jsonDecode(response.body)['podcasts'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    print(podcastList.length);
  }

  void userSnippet(String userId) async {
    String url =
        "https://api.aureal.one/public/getSnippet?user_id=${widget.userId}";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("${response.body}");
        setState(() {
          getSnippet = jsonDecode(response.body)['snippets'];
          listSnippet = jsonDecode(response.body)['snippets']['snippet'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void userRooms(String userId) async {
    String url =
        "https://api.aureal.one/public/getUserRooms?userid=${widget.userId}";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          userRoom = jsonDecode(response.body)['data'];
          //    communityRoom =jsonDecode(response.body)['data']['Communities'];
          print(userRoom);
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    //print(userRoom);
  }

  TabController _controller;

  bool seeMore = false;
  bool isPodcastListLoading;
  var isPlaying = false;
  var dominantColor = 0xff222222;

  SharedPreferences prefs;

  Widget bodyContainer() {
    return Container(
      color: Color(0xff161616),
      child: Column(
        children: [
          Container(
            height: (MediaQuery.of(context).size.height / 3) * (0.45),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xff5d5da8), Color(0xff5bc3ef)])),
          ),
          Container(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedNetworkImage(
                          imageUrl: userData['img'] == null
                              ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                              : userData['img'],
                          imageBuilder: (context, imageProvider) {
                            return Container(
                              height: MediaQuery.of(context).size.width / 5,
                              width: MediaQuery.of(context).size.width / 5,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.blueAccent, width: 2),
                                  image: DecorationImage(
                                      image: imageProvider, fit: BoxFit.cover)),
                            );
                          },
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${userData['fullname']}",
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 5,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text("@${userData['username']}"),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: InkWell(
                                onTap: () {
                                  follow();
                                },
                                child: ifFollowed == true
                                    ? ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return LinearGradient(colors: [
                                            Color(0xff5d5da8),
                                            Color(0xff5bc3ef)
                                          ]).createShader(bounds);
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Text("Followed"),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_circle),
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text("Follow"),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    showBarModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Followers(
                                            userId: widget.userId,
                                          );
                                        });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${userData['followers']}",
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Followers",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    2.5),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                InkWell(
                                  onTap: () {
                                    showBarModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Folllowing(
                                            userId: widget.userId,
                                          );
                                        });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${userData['following']}",
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Following",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    2.5),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List episodeList = [];

  void getUserEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getAuthorEpisodes/${widget.userId}?page=0&pageSize=14&loggedinuser=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url);

      setState(() {
        episodeList = response.data['episodes'];
      });
    } catch (e) {
      print(e);
    }
  }

  ScrollController subscriptionController;

  List subscriptions = [];

  @override
  void initState() {
    // TODO: implement initState

    // getUserFollowers();
    // getUserFollowing();

    _episodeScrollController = ScrollController();
    subscriptionController = ScrollController();
    getProfileData();
    userPodcast();
    getUserEpisodes();
    userRooms(widget.userId);
    userSnippet(widget.userId);
    userSubscriptions();
    _controller = TabController(vsync: this, length: 6);
    super.initState();
  }

  int pageSubscriptions = 0;

  void userSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/followedPodcasts?user_id=${widget.userId}&page=$pageSubscriptions";
    print(url);

    try {
      var response = await dio.get(url);
      print("This is subscription data");
      if (response.statusCode == 200) {
        if (pageSubscriptions == 0) {
          setState(() {
            subscriptions = response.data['podcasts'];
            pageSubscriptions += 1;
          });
        } else {
          setState(() {
            subscriptions = subscriptions + response.data['podcasts'];
            pageSubscriptions += 1;
          });
        }
      } else {
        print(response.statusCode);
      }

      print(response.data);
    } catch (e) {
      print(e);
    }
  }

  ScrollController _episodeScrollController;

  PageController _pageController = PageController(viewportFraction: 0.8);

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    try {
      return Scaffold(
        backgroundColor: Color(0xff161616),
        body: NestedScrollView(
          physics: BouncingScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
            return <Widget>[
              SliverAppBar(
                  forceElevated: isInnerBoxScrolled,
                  expandedHeight: MediaQuery.of(context).size.height / 2.8,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(children: [
                      Column(children: [
                        Container(
                          height:
                              (MediaQuery.of(context).size.height / 3) * (0.45),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                            Color(0xff5d5da8),
                            Color(0xff5bc3ef)
                          ])),
                        ),
                        Container(
                          height:
                              (MediaQuery.of(context).size.height / 3) * (0.55),
                        )
                      ]),
                      bodyContainer(),
                    ]),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(
                      (MediaQuery.of(context).size.height / 3) * (0.15),
                    ),
                    child: Container(
                      color: Color(0xff161616),
                      height: (MediaQuery.of(context).size.height / 3) * (0.15),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              TabBar(
                                isScrollable: true,
                                indicatorSize: TabBarIndicatorSize.label,
                                controller: _controller,
                                tabs: [
                                  Tab(
                                    text: "About",
                                  ),
                                  Tab(
                                    text: "Podcast",
                                  ),
                                  Tab(
                                    text: "Episode",
                                  ),
                                  Tab(
                                    text: "Subscriptions",
                                  ),
                                  Tab(
                                    text: "Live",
                                  ),
                                  Tab(
                                    text: "Snippets",
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ))
            ];
          },
          body: TabBarView(
            controller: _controller,
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text("${userData['bio']}"),
                ),
              ),
              Container(
                child: ListView(
                  children: [
                    Column(
                      children: [
                        for (var v in podcastList)
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return PodcastView(v['id']);
                                }));
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CachedNetworkImage(
                                    errorWidget: (context, url, error) =>
                                        Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                6,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                6,
                                            child: Icon(
                                              Icons.error,
                                              color: Color(0xffe8e8e8),
                                            )),
                                    placeholder: (context, url) {
                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        decoration: BoxDecoration(
                                          color: Color(0xff222222),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      );
                                    },
                                    imageUrl: v['image'],
                                    imageBuilder: (context, imageProvider) {
                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover)),
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${v['name']}",
                                            textScaleFactor: 1.0,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3.5,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "${v['author']}",
                                            textScaleFactor: 1.0,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)
                                                    .withOpacity(0.5),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                child: ListView(
                  controller: _episodeScrollController,
                  shrinkWrap: true,
                  children: [
                    for (var v in episodeList)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context,
                                CupertinoPageRoute(builder: (context) {
                              return EpisodeView(
                                episodeId: v['id'],
                              );
                            }));
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    new BoxShadow(
                                      color: Colors.black54.withOpacity(0.2),
                                      blurRadius: 10.0,
                                    ),
                                  ],
                                  color: Color(0xff222222),
                                  // color: themeProvider.isLightTheme == true
                                  //     ? Colors.white
                                  //     : Color(0xff222222),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          CachedNetworkImage(
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover),
                                                ),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    7,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    7,
                                              );
                                            },
                                            imageUrl: v['image'],
                                            memCacheWidth:
                                                MediaQuery.of(context)
                                                    .size
                                                    .width
                                                    .floor(),
                                            memCacheHeight:
                                                MediaQuery.of(context)
                                                    .size
                                                    .width
                                                    .floor(),
                                            placeholder: (context, url) =>
                                                Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  7,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  7,
                                              child: Image.asset(
                                                  'assets/images/Thumbnail.png'),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                          SizedBox(
                                              width:
                                                  SizeConfig.screenWidth / 26),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        CupertinoPageRoute(
                                                            builder: (context) =>
                                                                PodcastView(v[
                                                                    'podcast_id'])));
                                                  },
                                                  child: Text(
                                                    '${v['podcast_name']}',
                                                    textScaleFactor:
                                                        mediaQueryData
                                                            .textScaleFactor
                                                            .clamp(0.1, 1.2)
                                                            .toDouble(),
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xffe8e8e8),
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            5,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ),
                                                // Text(
                                                //   '${timeago.format(DateTime.parse(v['published_at']))}',
                                                //   textScaleFactor: mediaQueryData
                                                //       .textScaleFactor
                                                //       .clamp(
                                                //       0.5,
                                                //       0.9)
                                                //       .toDouble(),
                                                //   style: TextStyle(
                                                //     // color: Color(
                                                //     //     0xffe8e8e8),
                                                //       fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                // ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Container(
                                          width: double.infinity,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v['name'],
                                                textScaleFactor: mediaQueryData
                                                    .textScaleFactor
                                                    .clamp(0.5, 1)
                                                    .toDouble(),
                                                style: TextStyle(
                                                    color: Color(0xffe8e8e8),
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        4.5,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                                child: v['summary'] == null
                                                    ? SizedBox(
                                                        width: 0, height: 0)
                                                    : (htmlMatch.hasMatch(
                                                                v['summary']) ==
                                                            true
                                                        ? Text(
                                                            parse(v['summary'])
                                                                .body
                                                                .text,
                                                            textScaleFactor:
                                                                mediaQueryData
                                                                    .textScaleFactor
                                                                    .clamp(
                                                                        0.5, 1)
                                                                    .toDouble(),
                                                            maxLines: 2,
                                                            style: TextStyle(
                                                                color: Color(
                                                                        0xffe8e8e8)
                                                                    .withOpacity(
                                                                        0.5),
                                                                fontSize: SizeConfig
                                                                        .safeBlockHorizontal *
                                                                    3.2),
                                                          )
                                                        : Text(
                                                            '${v['summary']}',
                                                            textScaleFactor:
                                                                mediaQueryData
                                                                    .textScaleFactor
                                                                    .clamp(
                                                                        0.5, 1)
                                                                    .toDouble(),
                                                            style: TextStyle(
                                                                color: Color(
                                                                        0xffe8e8e8)
                                                                    .withOpacity(
                                                                        0.5),
                                                                fontSize: SizeConfig
                                                                        .safeBlockHorizontal *
                                                                    3.2),
                                                          )),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                v['permlink'] == null
                                                    ? SizedBox()
                                                    : InkWell(
                                                        onTap: () async {
                                                          if (prefs.getString(
                                                                  'HiveUserName') !=
                                                              null) {
                                                            setState(() {
                                                              v['isLoading'] =
                                                                  true;
                                                            });
                                                            double _value =
                                                                50.0;
                                                            showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) {
                                                                      return Dialog(
                                                                          backgroundColor: Colors
                                                                              .transparent,
                                                                          child: UpvoteEpisode(
                                                                              permlink: v['permlink'],
                                                                              episode_id: v['id']));
                                                                    })
                                                                .then(
                                                                    (value) async {
                                                              print(value);
                                                            });
                                                            setState(() {
                                                              v['ifVoted'] =
                                                                  !v['ifVoted'];
                                                            });
                                                            setState(() {
                                                              v['isLoading'] =
                                                                  false;
                                                            });
                                                          } else {
                                                            showBarModalBottomSheet(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return HiveDetails();
                                                                });
                                                          }
                                                        },
                                                        child: Container(
                                                          decoration: v[
                                                                      'ifVoted'] ==
                                                                  true
                                                              ? BoxDecoration(
                                                                  gradient:
                                                                      LinearGradient(
                                                                          colors: [
                                                                        Color(
                                                                            0xff5bc3ef),
                                                                        Color(
                                                                            0xff5d5da8)
                                                                      ]),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              30))
                                                              : BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                          color:
                                                                              kSecondaryColor),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              30)),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    vertical: 5,
                                                                    horizontal:
                                                                        5),
                                                            child: Row(
                                                              children: [
                                                                v['isLoading'] ==
                                                                        true
                                                                    ? Container(
                                                                        height:
                                                                            17,
                                                                        width:
                                                                            18,
                                                                        child:
                                                                            SpinKitPulse(
                                                                          color:
                                                                              Colors.blue,
                                                                        ),
                                                                      )
                                                                    : Icon(
                                                                        FontAwesomeIcons
                                                                            .chevronCircleUp,
                                                                        size:
                                                                            15,
                                                                        color: Color(
                                                                            0xffe8e8e8),
                                                                      ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          8),
                                                                  child: Text(
                                                                    v['votes']
                                                                        .toString(),
                                                                    textScaleFactor:
                                                                        1.0,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                          0xffe8e8e8),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      right: 4),
                                                                  child: Text(
                                                                    '\$${v['payout_value'].toString().split(' ')[0]}',
                                                                    textScaleFactor:
                                                                        1.0,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Color(
                                                                            0xffe8e8e8)),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                v['permlink'] == null
                                                    ? SizedBox()
                                                    : InkWell(
                                                        onTap: () {
                                                          if (prefs.getString(
                                                                  'HiveUserName') !=
                                                              null) {
                                                            Navigator.push(
                                                                context,
                                                                CupertinoPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            Comments(
                                                                              episodeObject: v,
                                                                            )));
                                                          } else {
                                                            showBarModalBottomSheet(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return HiveDetails();
                                                                });
                                                          }
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                                border: Border.all(
                                                                    color:
                                                                        kSecondaryColor),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30)),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4.0),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .mode_comment_outlined,
                                                                    size: 14,
                                                                    color: Color(
                                                                        0xffe8e8e8),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .symmetric(
                                                                        horizontal:
                                                                            7),
                                                                    child: Text(
                                                                      v['comments_count']
                                                                          .toString(),
                                                                      textScaleFactor:
                                                                          1.0,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              10,
                                                                          color:
                                                                              Color(0xffe8e8e8)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                InkWell(
                                                  onTap: () {
                                                    // print(v
                                                    //     .toString()
                                                    //     .contains('.mp4'));
                                                    // if (v
                                                    //             .toString()
                                                    //             .contains('.mp4') ==
                                                    //         true ||
                                                    //     v
                                                    //             .toString()
                                                    //             .contains('.m4v') ==
                                                    //         true ||
                                                    //     v
                                                    //             .toString()
                                                    //             .contains('.flv') ==
                                                    //         true ||
                                                    //     v
                                                    //             .toString()
                                                    //             .contains('.f4v') ==
                                                    //         true ||
                                                    //     v
                                                    //             .toString()
                                                    //             .contains('.ogv') ==
                                                    //         true ||
                                                    //     v
                                                    //             .toString()
                                                    //             .contains('.ogx') ==
                                                    //         true ||
                                                    //     v
                                                    //             .toString()
                                                    //             .contains('.wmv') ==
                                                    //         true ||
                                                    //     v.toString().contains(
                                                    //             '.webm') ==
                                                    //         true) {
                                                    //   currentlyPlaying.stop();
                                                    //   Navigator.push(context,
                                                    //       CupertinoPageRoute(
                                                    //           builder: (context) {
                                                    //     return PodcastVideoPlayer(
                                                    //         episodeObject: v);
                                                    //   }));
                                                    // } else {
                                                    //   if (v
                                                    //           .toString()
                                                    //           .contains('.pdf') ==
                                                    //       true) {
                                                    //     // Navigator.push(
                                                    //     //     context,
                                                    //     //     CupertinoPageRoute(
                                                    //     // der:
                                                    //     //             (context) {
                                                    //     //   return PDFviewer(
                                                    //     //       episodeObject:
                                                    //     //           v);
                                                    //     // }));
                                                    //   } else {
                                                    //     currentlyPlaying.stop();
                                                    //     currentlyPlaying
                                                    //         .episodeObject = v;
                                                    //     print(currentlyPlaying
                                                    //         .episodeObject
                                                    //         .toString());
                                                    //     currentlyPlaying.play();
                                                    //     Navigator.push(context,
                                                    //         CupertinoPageRoute(
                                                    //             builder: (context) {
                                                    //       return Player();
                                                    //     }));
                                                    //   }
                                                    // }
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 60),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  kSecondaryColor),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30)),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .play_circle_outline,
                                                              size: 15,
                                                              color: Color(
                                                                  0xffe8e8e8),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      8),
                                                              child: Text(
                                                                DurationCalculator(
                                                                    v['duration']),
                                                                textScaleFactor:
                                                                    0.75,
                                                                style: TextStyle(
                                                                    color: Color(
                                                                        0xffe8e8e8)),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            InkWell(
                                              onTap: () {
                                                share(episodeObject: v);
                                              },
                                              child: Icon(
                                                Icons.ios_share,
                                                // size: 14,
                                                color: Color(0xffe8e8e8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
              Container(
                child: ListView(
                  controller: subscriptionController,
                  children: [
                    Column(
                      children: [
                        for (var v in subscriptions)
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return PodcastView(v['id']);
                                }));
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CachedNetworkImage(
                                    errorWidget: (context, url, error) =>
                                        Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                6,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                6,
                                            child: Icon(
                                              Icons.error,
                                              color: Color(0xffe8e8e8),
                                            )),
                                    placeholder: (context, url) {
                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        decoration: BoxDecoration(
                                          color: Color(0xff222222),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      );
                                    },
                                    imageUrl: v['image'],
                                    imageBuilder: (context, imageProvider) {
                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover)),
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${v['name']}",
                                            textScaleFactor: 1.0,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3.5,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "${v['author']}",
                                            textScaleFactor: 1.0,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)
                                                    .withOpacity(0.5),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                      ],
                    ),
                  ],
                ),
              ),
              Container(),
              Container(),
            ],
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        body: Container(
          child: CircularProgressIndicator(),
        ),
      );
    }
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

void hostJoined(var roomId) async {
  Dio dio = Dio();

  postreq.Interceptor intercept = postreq.Interceptor();
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

void hostLeft(var roomId) async {
  postreq.Interceptor intercept = postreq.Interceptor();
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

bool isAudioOnly = true;
bool isAudioMuted = true;
bool isVideoMuted = true;

void addRoomParticipant({String roomid}) async {
  Dio dio = Dio();

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

class Followers extends StatefulWidget {
  String userId;

  Followers({@required this.userId});

  @override
  _FollowersState createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {
  Dio dio = Dio();

  int followerPage = 0;
  List followers = [];

  void getUserFollowers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // String url =
    //     "https://api.aureal.one/public/getUserFollowers?user_id=${widget.userId}&loggedinuser=${prefs.getString('userId')}&page=$followerPage";
    String url =
        "https://api.aureal.one/public/getUserFollowers?user_id=${widget.userId}&loggedinuser=${prefs.getString("userId")}&page=$followerPage";

    try {
      var response = await dio.get(url);
      print(response.data);
      if (response.statusCode == 200) {
        if (followerPage == 0) {
          setState(() {
            followers = response.data['users'];
            followerPage += 1;
          });
        } else {
          setState(() {
            followers = followers + response.data['users'];
            followerPage += 1;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  ScrollController followerController;

  @override
  void initState() {
    followerController = ScrollController();

    getUserFollowers();
    // TODO: implement initState
    super.initState();

    followerController.addListener(() {
      if (followerController.position.pixels ==
          followerController.position.maxScrollExtent) {
        getUserFollowers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Followers",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: ListView(
          controller: followerController,
          children: [
            for (var v in followers)
              Padding(
                padding: const EdgeInsets.all(15),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (context) {
                      return PublicProfile(
                        userId: v['id'],
                      );
                    }));
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              imageUrl: v['img'] == null
                                  ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                  : v['img'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  height: MediaQuery.of(context).size.width / 6,
                                  width: MediaQuery.of(context).size.width / 6,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
                                );
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${v['username']}",
                                      textScaleFactor: 1.0,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Color(0xffe8e8e8),
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.5,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    v['fullname'] == null
                                        ? SizedBox()
                                        : Text(
                                            "${v['fullname']}",
                                            textScaleFactor: 1.0,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)
                                                    .withOpacity(0.5),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3),
                                          )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          followUser(authorUserId: v['id']);
                          setState(() {
                            v['ifFollowsAuthor'] = !v['ifFollowsAuthor'];
                          });
                        },
                        icon: v['ifFollowsAuthor'] == true
                            ? Icon(
                                Icons.verified_user,
                                color: Color(0xffe8e8e8),
                              )
                            : Icon(
                                Icons.person_add,
                                color: Color(0xffe8e8e8),
                              ),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class Folllowing extends StatefulWidget {
  String userId;

  Folllowing({@required this.userId});

  @override
  _FolllowingState createState() => _FolllowingState();
}

class _FolllowingState extends State<Folllowing> {
  Dio dio = Dio();

  List following = [];

  void getUserFollowing() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // String url =
    //     "https://api.aureal.one/public/getUserFollowers?user_id=${widget.userId}&loggedinuser=${prefs.getString('userId')}&page=$followingPage";

    String url =
        "https://api.aureal.one/public/getUserFollowing?user_id=${widget.userId}&loggedinuser=${prefs.getString('userId')}&page=$followingPage";
    try {
      var response = await dio.get(url);
      print(response.data);
      if (response.statusCode == 200) {
        if (followingPage == 0) {
          setState(() {
            following = response.data['users'];
            followingPage += 1;
          });
        } else {
          setState(() {
            following = following + response.data['users'];
            followingPage += 1;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  int followingPage = 0;

  ScrollController followingController;

  @override
  void initState() {
    followingController = ScrollController();
    // TODO: implement initState
    getUserFollowing();
    super.initState();

    followingController.addListener(() {
      if (followingController.position.pixels ==
          followingController.position.maxScrollExtent) {
        getUserFollowing();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Following",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: ListView(
          controller: followingController,
          children: [
            for (var v in following)
              Padding(
                padding: const EdgeInsets.all(15),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (context) {
                      return PublicProfile(
                        userId: v['id'],
                      );
                    }));
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CachedNetworkImage(
                              imageUrl: v['img'] == null
                                  ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                  : v['img'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  height: MediaQuery.of(context).size.width / 6,
                                  width: MediaQuery.of(context).size.width / 6,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
                                );
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${v['username']}",
                                      textScaleFactor: 1.0,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Color(0xffe8e8e8),
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.5,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    v['fullname'] == null
                                        ? SizedBox()
                                        : Text(
                                            "${v['fullname']}",
                                            textScaleFactor: 1.0,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)
                                                    .withOpacity(0.5),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3),
                                          )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          followUser(authorUserId: v['id']);
                          setState(() {
                            v['ifFollowsAuthor'] = !v['ifFollowsAuthor'];
                          });
                        },
                        icon: v['ifFollowsAuthor'] == true
                            ? Icon(
                                Icons.verified_user,
                                color: Color(0xffe8e8e8),
                              )
                            : Icon(
                                Icons.person_add,
                                color: Color(0xffe8e8e8),
                              ),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
