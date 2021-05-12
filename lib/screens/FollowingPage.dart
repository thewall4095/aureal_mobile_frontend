import 'dart:convert';

import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/CommunityService.dart';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/utilities/Share.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../PlayerState.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/Player.dart';
import 'Player/VideoPlayer.dart';
import 'Profiles/CategoryView.dart';
import 'Profiles/Comments.dart';

class FollowingPage extends StatefulWidget {
  @override
  _FollowingPageState createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage>
    with TickerProviderStateMixin {
  AnimationController animationController;

  String word;
  String author;
  String displayPicture;
  bool isLoading;
  String hiveUserName;
  var _firstPress = true;
  String communityName;
  String communityDescription;

  var followingList;

  Launcher launcher = Launcher();

  final double maxSlide = 250.0;
  final double minDragStartingEdge = 10;
  final double maxDragStartingEdge = 30;

  CommunityProvider communities;

  var currentlyPlaying = null;

  // void share(var v) async {
  //   String sharableLink;
  //
  //   await FlutterShare.share(
  //       title: '${v['title']}',
  //       text:
  //           "Hey There, I'm listening to ${v['name']} on Aureal, here's the link for you https://api.aureal.one/podcast/${v['podcast_id']}");
  // }

  void getLocalData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      displayPicture = pref.getString('displayPicture');
      hiveUserName = pref.getString('HiveUserName');
    });
  }

  bool paginationLoading = false;

  bool _canBeDragged;

  ScrollController _scrollController;

  void getData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = true;
    });
  }

  SharedPreferences prefs;

  int count = 0;

  void _onDragStart(DragStartDetails details) {
    bool isDragOpenFromLeft = animationController.isDismissed &&
        details.globalPosition.dx < minDragStartingEdge;
    bool isDragCloseFromRight = animationController.isCompleted &&
        details.globalPosition.dx > maxDragStartingEdge;

    _canBeDragged = isDragOpenFromLeft || isDragCloseFromRight;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_canBeDragged) {
      double delta = details.primaryDelta / maxSlide;
      animationController.value += delta;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (animationController.isDismissed || animationController.isCompleted) {
      return;
    }
    if (details.velocity.pixelsPerSecond.dx.abs() >= 365.0) {
      double visualVelocity = details.velocity.pixelsPerSecond.dx /
          MediaQuery.of(context).size.width;
      animationController.fling(velocity: visualVelocity);
    } else if (animationController.value < 0.5) {
      // close();
    } else {
      // open();
    }
    setState(() {
      isLoading = false;
    });
  }

  CommunityService service;

  int pageNumber = 0;

  void toggle() {
    animationController.isDismissed
        ? animationController.forward()
        : animationController.reverse();
  }

  var episodes = [];

  // void getCommunityEposidesForUser() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String url =
  //       'https://api.aureal.one/public/getCommunityEpisodes?user_id=${prefs.getString('userId')}';
  //
  //   try {
  //     http.Response response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       print('communityepisodes');
  //       print(response.body);
  //
  //       episodes = jsonDecode(response.body)['EpisodeResult'];
  //     } else {
  //       print(response.statusCode);
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  //   // setState(() {
  //   //   isLoading = false;
  //   // });
  // }

  TabController _tabController;
  RegExp htmlMatch = RegExp(r'(\w+)');

  // void getCommunityEpisodesForUserPaginated() async {
  //   print('pagination starting');
  //   setState(() {
  //     paginationLoading = true;
  //   });
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String url =
  //       'https://api.aureal.one/public/getCommunityEpisodes?user_id=${prefs.getString('userId')}&page=$pageNumber';
  //
  //   try {
  //     http.Response response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       print('communityepisodes');
  //       print(response.body);
  //       setState(() {
  //         episodes = episodes + jsonDecode(response.body)['EpisodeResult'];
  //         pageNumber = pageNumber + 1;
  //       });
  //     } else {
  //       print(response.statusCode);
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  //   setState(() {
  //     paginationLoading = false;
  //   });
  // }

  List favPodcast = [];

  void getFollowedPodcasts() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/followedPodcasts?user_id=${prefs.getString('userId')}";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          favPodcast = jsonDecode(response.body)['PodcastResult'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });
  }

  int pagenumber = 0;

  List hiveEpisodes = [];

  void getHiveFollowedEpisode() async {
    // setState(() {
    //   hiveEpisodeLoading = true;
    // });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/browseHiveEpisodesTest?user_id=${prefs.getString('userId')}&page=$pageNumber";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        if (pageNumber != 0) {
          setState(() {
            isPaginationLoading = true;
            hiveEpisodes =
                hiveEpisodes + jsonDecode(response.body)['EpisodeResult'];
            pageNumber = pageNumber + 1;
          });
        } else {
          setState(() {
            hiveEpisodes = jsonDecode(response.body)['EpisodeResult'];
          });
          setState(() {
            for (var v in hiveEpisodes) {
              v['isLoading'] = false;
            }
            pageNumber = pageNumber + 1;
          });
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      hiveEpisodeLoading = false;
      isPaginationLoading = false;
    });
  }

  bool isPaginationLoading = false;

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
//    getCurrentUser();

    getData();
    getFollowedPodcasts();
    getHiveFollowedEpisode();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // getCommunityEpisodesForUserPaginated();
        getHiveFollowedEpisode();
      }
    });
    getLocalData();
    // getCommunityEposidesForUser();

    _tabController = TabController(length: 2, vsync: this);
    // TODO: implement initState
    super.initState();
  }

  bool hiveEpisodeLoading = true;

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    communities = Provider.of<CommunityProvider>(context);
    var categories = Provider.of<CategoriesProvider>(context);
    currentlyPlaying = Provider.of<PlayerChange>(context);
    // print('the communities');
    // print(communities);
    // print(communities.allCommunities);
    if (communities.isFetchedallCommunities == false) {
      communities.getAllCommunity();
    }
    if (communities.isFetcheduserCreatedCommunities == false) {
      communities.getUserCreatedCommunities();
    }
    if (communities.isFetcheduserCommunities == false) {
      communities.getAllCommunitiesForUser();
    }
    // isLoading = false;
    //
    Future<void> _pullRefreshEpisodes() async {
      // getCommunityEposidesForUser();
      await communities.getAllCommunitiesForUser();
      await communities.getUserCreatedCommunities();
      await communities.getAllCommunity();
      await getFollowedPodcasts();
      await getHiveFollowedEpisode();

      await getFollowedPodcasts();
    }

    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
          return <Widget>[
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 30,
              pinned: true,
              //     backgroundColor: kPrimaryColor,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(20),
                child: RefreshIndicator(
                  onRefresh: _pullRefreshEpisodes,
                  child: Container(
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (var v in categories.categoryList)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) {
                                      return CategoryView(categoryObject: v);
                                    }));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xff171b27)),
                                        // color: Color(0xff3a3a3a),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 3),
                                      child: Center(
                                        child: Text(
                                          v['name'],
                                          textScaleFactor: mediaQueryData
                                              .textScaleFactor
                                              .clamp(0.5, 1.1)
                                              .toDouble(),
                                          style: TextStyle(
                                              //  color:
                                              // Color(0xffe8e8e8),
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ];
        },
        body: RefreshIndicator(
          onRefresh: _pullRefreshEpisodes,
          child: Container(
            child: Container(
              child: ListView(
                controller: _scrollController,
                children: [
                  Column(
                    children: [
                      favPodcast.length == 0
                          ? SizedBox(
                              height: 0,
                              width: 0,
                            )
                          : Container(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Text(
                                      "Your Favourites",
                                      textScaleFactor: mediaQueryData
                                          .textScaleFactor
                                          .clamp(0.5, 1.3)
                                          .toDouble(),
                                      style: TextStyle(
                                          //    color: Color(0xffe8e8e8),
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  7,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    height: 200,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        for (var v in favPodcast)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (context) {
                                                  return PodcastView(v['id']);
                                                }));
                                              },
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            4,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            4,
                                                    //   color: Colors.white,
                                                    child: CachedNetworkImage(
                                                      imageUrl: v['image'],
                                                      memCacheWidth:
                                                          (MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width)
                                                              .floor(),
                                                      memCacheHeight:
                                                          (MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width)
                                                              .floor(),
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        child: Image.asset(
                                                            'assets/images/Thumbnail.png'),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Icon(Icons.error),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 10),
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            v['name'],
                                                            textScaleFactor:
                                                                mediaQueryData
                                                                    .textScaleFactor
                                                                    .clamp(
                                                                        0.5, 1)
                                                                    .toDouble(),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              // color: Colors.white,
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  4,
                                                            ),
                                                          ),
                                                          Text(
                                                            v['author'],
                                                            textScaleFactor:
                                                                mediaQueryData
                                                                    .textScaleFactor
                                                                    .clamp(0.5,
                                                                        0.9)
                                                                    .toDouble(),
                                                            style: TextStyle(
                                                                // color:
                                                                //     Colors.white,
                                                                fontSize: SizeConfig
                                                                        .safeBlockHorizontal *
                                                                    3),
                                                          )
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
                                ],
                              ),
                            ),
                      hiveEpisodeLoading == true
                          ? Container(
                              child: Column(
                                children: [
                                  for (int i = 0; i < 50; i++)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.white,
                                        highlightColor: Colors.white30,
                                        // child: Container(
                                        //   decoration: BoxDecoration(
                                        //       borderRadius:
                                        //           BorderRadius.circular(8),
                                        //       border: Border.all(
                                        //           color: Colors.grey,
                                        //           width: 2)),
                                        //   height: 80,
                                        //   width: double.infinity,
                                        //   child: Padding(
                                        //     padding:
                                        //         const EdgeInsets.symmetric(
                                        //             horizontal: 10),
                                        //     child: Row(
                                        //       mainAxisAlignment:
                                        //           MainAxisAlignment
                                        //               .spaceBetween,
                                        //       children: <Widget>[
                                        //         Row(
                                        //           children: <Widget>[
                                        //             CircleAvatar(
                                        //               radius: 25,
                                        //             ),
                                        //             SizedBox(
                                        //               width: 15,
                                        //             ),
                                        //             Column(
                                        //               mainAxisAlignment:
                                        //                   MainAxisAlignment
                                        //                       .center,
                                        //               crossAxisAlignment:
                                        //                   CrossAxisAlignment
                                        //                       .start,
                                        //               children: <Widget>[
                                        //                 Container(
                                        //                   width: MediaQuery.of(
                                        //                               context)
                                        //                           .size
                                        //                           .width /
                                        //                       2,
                                        //                   height: 8,
                                        //                   color: Colors
                                        //                       .white30,
                                        //                 ),
                                        //                 SizedBox(
                                        //                   height: 5,
                                        //                 ),
                                        //                 Container(
                                        //                   width: MediaQuery.of(
                                        //                               context)
                                        //                           .size
                                        //                           .width /
                                        //                       4,
                                        //                   height: 8,
                                        //                   color: Colors
                                        //                       .white30,
                                        //                 ),
                                        //               ],
                                        //             )
                                        //           ],
                                        //         ),
                                        //         Icon(Icons.more_vert)
                                        //       ],
                                        //     ),
                                        //   ),
                                        // ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border(top: BorderSide())
                                              // border: Border.all(
                                              //     color: kSecondaryColor),
                                              ),
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              4,
                                          width: double.infinity,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            15),
                                                    child: Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              7,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              7,
                                                      color: kSecondaryColor,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width: SizeConfig
                                                              .screenWidth /
                                                          28),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        color:
                                                            Color(0xff171b27),
                                                        height: 10,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            2,
                                                      ),
                                                      SizedBox(
                                                        height: 10,
                                                      ),
                                                      Container(
                                                        color:
                                                            Color(0xff171b27),
                                                        height: 10,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            4,
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(15),
                                                child: Container(
                                                  height: 10,
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  color: Color(0xff171b27),
                                                ),
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 15,
                                                        vertical: 5),
                                                    child: Container(
                                                      height: 5,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      color: Color(0xff171b27),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 15,
                                                        vertical: 5),
                                                    child: Container(
                                                      height: 5,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      color: Color(0xff171b27),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : Container(
                              child: Column(
                                children: [
                                  for (var v in hiveEpisodes)
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return EpisodeView(
                                              episodeId: v['id']);
                                        }));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  top: BorderSide(
                                                      color: Color(0xff171b27)),
                                                  bottom: BorderSide(
                                                      color: Color(0xff171b27),
                                                      width: 1))),
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      // color: Colors.white,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              7,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              7,
                                                      child: CachedNetworkImage(
                                                        imageUrl: v['image'],
                                                        memCacheWidth:
                                                            MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width
                                                                .floor(),
                                                        memCacheHeight:
                                                            MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width
                                                                .floor(),
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          child: Image.asset(
                                                              'assets/images/Thumbnail.png'),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(Icons.error),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: SizeConfig
                                                                .screenWidth /
                                                            26),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder:
                                                                          (context) {
                                                                return PodcastView(
                                                                    v['podcast_id']);
                                                              }));
                                                            },
                                                            child: Text(
                                                              v['podcast_name'],
                                                              textScaleFactor:
                                                                  mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.1,
                                                                          1.2)
                                                                      .toDouble(),
                                                              style: TextStyle(
                                                                  // color: Color(
                                                                  //     0xffe8e8e8),
                                                                  fontSize:
                                                                      SizeConfig
                                                                              .safeBlockHorizontal *
                                                                          5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal),
                                                            ),
                                                          ),
                                                          Text(
                                                            '${timeago.format(DateTime.parse(v['published_at']))}',
                                                            textScaleFactor:
                                                                mediaQueryData
                                                                    .textScaleFactor
                                                                    .clamp(0.5,
                                                                        0.9)
                                                                    .toDouble(),
                                                            style: TextStyle(
                                                                // color: Color(
                                                                //     0xffe8e8e8),
                                                                fontSize: SizeConfig
                                                                        .safeBlockHorizontal *
                                                                    3.5),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 10),
                                                  child: Container(
                                                    width: double.infinity,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          v['name'],
                                                          textScaleFactor:
                                                              mediaQueryData
                                                                  .textScaleFactor
                                                                  .clamp(0.5, 1)
                                                                  .toDouble(),
                                                          style: TextStyle(
                                                              // color: Color(
                                                              //     0xffe8e8e8),
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  4.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 10),
                                                          child: v['summary'] ==
                                                                  null
                                                              ? SizedBox(
                                                                  width: 0,
                                                                  height: 0)
                                                              : (htmlMatch.hasMatch(
                                                                          v['summary']) ==
                                                                      true
                                                                  ? Text(
                                                                      parse(v['summary'])
                                                                          .body
                                                                          .text,
                                                                      textScaleFactor: mediaQueryData
                                                                          .textScaleFactor
                                                                          .clamp(
                                                                              0.5,
                                                                              1)
                                                                          .toDouble(),
                                                                      maxLines:
                                                                          2,
                                                                      style: TextStyle(
                                                                          // color: Colors.white,
                                                                          fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                    )
                                                                  : Text(
                                                                      '${v['summary']}',
                                                                      textScaleFactor: mediaQueryData
                                                                          .textScaleFactor
                                                                          .clamp(
                                                                              0.5,
                                                                              1)
                                                                          .toDouble(),
                                                                      style: TextStyle(
                                                                          //      color: Colors.white,
                                                                          fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                    )),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          InkWell(
                                                            onTap: () async {
                                                              if (prefs.getString(
                                                                      'HiveUserName') !=
                                                                  null) {
                                                                setState(() {
                                                                  v['isLoading'] =
                                                                      true;
                                                                });
                                                                await upvoteEpisode(
                                                                    permlink: v[
                                                                        'permlink'],
                                                                    episode_id:
                                                                        v['id']);
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
                                                                            Color(0xff5bc3ef),
                                                                            Color(0xff5d5da8)
                                                                          ]),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              30))
                                                                  : BoxDecoration(
                                                                      border: Border.all(
                                                                          color:
                                                                              kSecondaryColor),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              30)),
                                                              child: Padding(
                                                                padding: const EdgeInsets
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
                                                                              color: Colors.blue,
                                                                            ),
                                                                          )
                                                                        : Icon(
                                                                            FontAwesomeIcons.chevronCircleUp,
                                                                            size:
                                                                                15,
                                                                            // color:
                                                                            //     Color(0xffe8e8e8),
                                                                          ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .symmetric(
                                                                          horizontal:
                                                                              8),
                                                                      child:
                                                                          Text(
                                                                        v['votes']
                                                                            .toString(),
                                                                        textScaleFactor:
                                                                            1.0,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                12
                                                                            // color:
                                                                            //     Color(0xffe8e8e8)
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          right:
                                                                              4),
                                                                      child:
                                                                          Text(
                                                                        '\$${v['payout_value'].toString().split(' ')[0]}',
                                                                        textScaleFactor:
                                                                            1.0,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          // color:
                                                                          //     Color(0xffe8e8e8)
                                                                        ),
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          InkWell(
                                                            onTap: () {
                                                              if (prefs.getString(
                                                                      'HiveUserName') !=
                                                                  null) {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) {
                                                                  return Comments(
                                                                    episodeObject:
                                                                        v,
                                                                  );
                                                                }));
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
                                                                        color: Color(
                                                                            0xff171b27)),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            30)),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          4.0),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .mode_comment_outlined,
                                                                        size:
                                                                            14,
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.symmetric(horizontal: 7),
                                                                        child:
                                                                            Text(
                                                                          v['comments_count']
                                                                              .toString(),
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          style: TextStyle(
                                                                              fontSize: 10
                                                                              // color:
                                                                              //     Color(0xffe8e8e8)
                                                                              ),
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
                                                              print(v
                                                                  .toString()
                                                                  .contains(
                                                                      '.mp4'));
                                                              if (v.toString().contains('.mp4') == true ||
                                                                  v.toString().contains(
                                                                          '.m4v') ==
                                                                      true ||
                                                                  v.toString().contains(
                                                                          '.flv') ==
                                                                      true ||
                                                                  v.toString().contains(
                                                                          '.f4v') ==
                                                                      true ||
                                                                  v.toString().contains(
                                                                          '.ogv') ==
                                                                      true ||
                                                                  v.toString().contains(
                                                                          '.ogx') ==
                                                                      true ||
                                                                  v.toString().contains(
                                                                          '.wmv') ==
                                                                      true ||
                                                                  v.toString().contains(
                                                                          '.webm') ==
                                                                      true) {
                                                                currentlyPlaying
                                                                    .stop();
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) {
                                                                  return PodcastVideoPlayer(
                                                                      episodeObject:
                                                                          v);
                                                                }));
                                                              } else {
                                                                if (v
                                                                        .toString()
                                                                        .contains(
                                                                            '.pdf') ==
                                                                    true) {
                                                                  // Navigator.push(
                                                                  //     context,
                                                                  //     MaterialPageRoute(
                                                                  //         builder:
                                                                  //             (context) {
                                                                  //   return PDFviewer(
                                                                  //       episodeObject:
                                                                  //           v);
                                                                  // }));
                                                                } else {
                                                                  currentlyPlaying
                                                                      .stop();
                                                                  currentlyPlaying
                                                                      .episodeObject = v;
                                                                  print(currentlyPlaying
                                                                      .episodeObject
                                                                      .toString());
                                                                  currentlyPlaying
                                                                      .play();
                                                                  showBarModalBottomSheet(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) {
                                                                        return Player();
                                                                      });
                                                                }
                                                              }
                                                            },
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      right:
                                                                          80),
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                    border: Border.all(
                                                                        color: Color(
                                                                            0xff171b27)),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
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
                                                                        size:
                                                                            15,
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.symmetric(horizontal: 8),
                                                                        child:
                                                                            Text(
                                                                          DurationCalculator(
                                                                              v['duration']),
                                                                          textScaleFactor:
                                                                              0.75,
                                                                          // style: TextStyle(
                                                                          //      color: Color(0xffe8e8e8)
                                                                          //     ),
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
                                                      // Row(
                                                      //   children: [
                                                      //     IconButton(
                                                      //       padding:
                                                      //           EdgeInsets.zero,
                                                      //       icon: Icon(
                                                      //         FontAwesomeIcons
                                                      //             .shareAlt,
                                                      //         size: SizeConfig
                                                      //                 .safeBlockHorizontal *
                                                      //             4,
                                                      //         // color: Color(
                                                      //         //     0xffe8e8e8),
                                                      //       ),
                                                      //       onPressed:
                                                      //           () async {
                                                      //         share(
                                                      //             episodeObject:
                                                      //                 v);
                                                      //       },
                                                      //     ),
                                                      //   ],
                                                      // )
                                                      InkWell(
                                                        onTap: () {
                                                          share(
                                                              episodeObject: v);
                                                        },
                                                        child: Icon(
                                                          FontAwesomeIcons
                                                              .shareAlt,
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  isPaginationLoading == true
                                      ? Container(
                                          height: 10,
                                          width: double.infinity,
                                          child: LinearProgressIndicator(
                                            minHeight: 10,
                                            backgroundColor: Colors.blue,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xff6249EF)),
                                          ),
                                        )
                                      : SizedBox(
                                          height: 0,
                                        )
                                ],
                              ),
                            )
                    ],
                  ),
                  SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
            // child: TabBarView(
            //   controller: _tabController,
            //   children: [
            //     Container(
            //       child: ListView(
            //         controller: _scrollController,
            //         children: [
            //           Column(
            //             children: [
            //               favPodcast.length == 0
            //                   ? SizedBox(
            //                       height: 0,
            //                       width: 0,
            //                     )
            //                   : Container(
            //                       width: double.infinity,
            //                       child: Column(
            //                         crossAxisAlignment:
            //                             CrossAxisAlignment.start,
            //                         children: [
            //                           Padding(
            //                             padding: const EdgeInsets.symmetric(
            //                                 horizontal: 10, vertical: 10),
            //                             child: Text(
            //                               "Your Favourites",
            //                               textScaleFactor: mediaQueryData
            //                                   .textScaleFactor
            //                                   .clamp(0.5, 1.3)
            //                                   .toDouble(),
            //                               style: TextStyle(
            //                                   //    color: Color(0xffe8e8e8),
            //                                   fontSize: SizeConfig
            //                                           .safeBlockHorizontal *
            //                                       7,
            //                                   fontWeight: FontWeight.bold),
            //                             ),
            //                           ),
            //                           Container(
            //                             height: 200,
            //                             child: ListView(
            //                               scrollDirection: Axis.horizontal,
            //                               children: [
            //                                 for (var v in favPodcast)
            //                                   Padding(
            //                                     padding:
            //                                         const EdgeInsets.all(8.0),
            //                                     child: InkWell(
            //                                       onTap: () {
            //                                         Navigator.push(context,
            //                                             MaterialPageRoute(
            //                                                 builder: (context) {
            //                                           return PodcastView(
            //                                               v['id']);
            //                                         }));
            //                                       },
            //                                       child: Column(
            //                                         crossAxisAlignment:
            //                                             CrossAxisAlignment
            //                                                 .start,
            //                                         mainAxisAlignment:
            //                                             MainAxisAlignment.start,
            //                                         children: [
            //                                           Container(
            //                                             width: MediaQuery.of(
            //                                                         context)
            //                                                     .size
            //                                                     .width /
            //                                                 4,
            //                                             height: MediaQuery.of(
            //                                                         context)
            //                                                     .size
            //                                                     .width /
            //                                                 4,
            //                                             //   color: Colors.white,
            //                                             child:
            //                                                 CachedNetworkImage(
            //                                               imageUrl: v['image'],
            //                                               memCacheWidth:
            //                                                   (MediaQuery.of(
            //                                                               context)
            //                                                           .size
            //                                                           .width)
            //                                                       .floor(),
            //                                               memCacheHeight:
            //                                                   (MediaQuery.of(
            //                                                               context)
            //                                                           .size
            //                                                           .width)
            //                                                       .floor(),
            //                                               placeholder:
            //                                                   (context, url) =>
            //                                                       Container(
            //                                                 child: Image.asset(
            //                                                     'assets/images/Thumbnail.png'),
            //                                               ),
            //                                               errorWidget: (context,
            //                                                       url, error) =>
            //                                                   Icon(Icons.error),
            //                                             ),
            //                                           ),
            //                                           Padding(
            //                                             padding:
            //                                                 const EdgeInsets
            //                                                         .symmetric(
            //                                                     vertical: 10),
            //                                             child: Container(
            //                                               width: MediaQuery.of(
            //                                                           context)
            //                                                       .size
            //                                                       .width /
            //                                                   4,
            //                                               child: Column(
            //                                                 crossAxisAlignment:
            //                                                     CrossAxisAlignment
            //                                                         .start,
            //                                                 children: [
            //                                                   Text(
            //                                                     v['name'],
            //                                                     textScaleFactor:
            //                                                         mediaQueryData
            //                                                             .textScaleFactor
            //                                                             .clamp(
            //                                                                 0.5,
            //                                                                 1)
            //                                                             .toDouble(),
            //                                                     overflow:
            //                                                         TextOverflow
            //                                                             .ellipsis,
            //                                                     style:
            //                                                         TextStyle(
            //                                                       // color: Colors.white,
            //                                                       fontSize:
            //                                                           SizeConfig
            //                                                                   .safeBlockHorizontal *
            //                                                               4,
            //                                                     ),
            //                                                   ),
            //                                                   Text(
            //                                                     v['author'],
            //                                                     textScaleFactor:
            //                                                         mediaQueryData
            //                                                             .textScaleFactor
            //                                                             .clamp(
            //                                                                 0.5,
            //                                                                 0.9)
            //                                                             .toDouble(),
            //                                                     style: TextStyle(
            //                                                         // color:
            //                                                         //     Colors.white,
            //                                                         fontSize: SizeConfig.safeBlockHorizontal * 3),
            //                                                   )
            //                                                 ],
            //                                               ),
            //                                             ),
            //                                           ),
            //                                         ],
            //                                       ),
            //                                     ),
            //                                   )
            //                               ],
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //               hiveEpisodeLoading == true
            //                   ? Container(
            //                       child: Column(
            //                         children: [
            //                           for (int i = 0; i < 50; i++)
            //                             Padding(
            //                               padding: const EdgeInsets.all(8.0),
            //                               child: Shimmer.fromColors(
            //                                 baseColor: Colors.white,
            //                                 highlightColor: Colors.white30,
            //                                 // child: Container(
            //                                 //   decoration: BoxDecoration(
            //                                 //       borderRadius:
            //                                 //           BorderRadius.circular(8),
            //                                 //       border: Border.all(
            //                                 //           color: Colors.grey,
            //                                 //           width: 2)),
            //                                 //   height: 80,
            //                                 //   width: double.infinity,
            //                                 //   child: Padding(
            //                                 //     padding:
            //                                 //         const EdgeInsets.symmetric(
            //                                 //             horizontal: 10),
            //                                 //     child: Row(
            //                                 //       mainAxisAlignment:
            //                                 //           MainAxisAlignment
            //                                 //               .spaceBetween,
            //                                 //       children: <Widget>[
            //                                 //         Row(
            //                                 //           children: <Widget>[
            //                                 //             CircleAvatar(
            //                                 //               radius: 25,
            //                                 //             ),
            //                                 //             SizedBox(
            //                                 //               width: 15,
            //                                 //             ),
            //                                 //             Column(
            //                                 //               mainAxisAlignment:
            //                                 //                   MainAxisAlignment
            //                                 //                       .center,
            //                                 //               crossAxisAlignment:
            //                                 //                   CrossAxisAlignment
            //                                 //                       .start,
            //                                 //               children: <Widget>[
            //                                 //                 Container(
            //                                 //                   width: MediaQuery.of(
            //                                 //                               context)
            //                                 //                           .size
            //                                 //                           .width /
            //                                 //                       2,
            //                                 //                   height: 8,
            //                                 //                   color: Colors
            //                                 //                       .white30,
            //                                 //                 ),
            //                                 //                 SizedBox(
            //                                 //                   height: 5,
            //                                 //                 ),
            //                                 //                 Container(
            //                                 //                   width: MediaQuery.of(
            //                                 //                               context)
            //                                 //                           .size
            //                                 //                           .width /
            //                                 //                       4,
            //                                 //                   height: 8,
            //                                 //                   color: Colors
            //                                 //                       .white30,
            //                                 //                 ),
            //                                 //               ],
            //                                 //             )
            //                                 //           ],
            //                                 //         ),
            //                                 //         Icon(Icons.more_vert)
            //                                 //       ],
            //                                 //     ),
            //                                 //   ),
            //                                 // ),
            //                                 child: Container(
            //                                   decoration: BoxDecoration(
            //                                       border:
            //                                           Border(top: BorderSide())
            //                                       // border: Border.all(
            //                                       //     color: kSecondaryColor),
            //                                       ),
            //                                   height: MediaQuery.of(context)
            //                                           .size
            //                                           .height /
            //                                       4,
            //                                   width: double.infinity,
            //                                   child: Column(
            //                                     mainAxisAlignment:
            //                                         MainAxisAlignment.center,
            //                                     children: [
            //                                       Row(
            //                                         children: [
            //                                           Padding(
            //                                             padding:
            //                                                 const EdgeInsets
            //                                                     .all(15),
            //                                             child: Container(
            //                                               height: MediaQuery.of(
            //                                                           context)
            //                                                       .size
            //                                                       .width /
            //                                                   7,
            //                                               width: MediaQuery.of(
            //                                                           context)
            //                                                       .size
            //                                                       .width /
            //                                                   7,
            //                                               color:
            //                                                   kSecondaryColor,
            //                                             ),
            //                                           ),
            //                                           SizedBox(
            //                                               width: SizeConfig
            //                                                       .screenWidth /
            //                                                   28),
            //                                           Column(
            //                                             crossAxisAlignment:
            //                                                 CrossAxisAlignment
            //                                                     .start,
            //                                             children: [
            //                                               Container(
            //                                                 color: Color(
            //                                                     0xff171b27),
            //                                                 height: 10,
            //                                                 width: MediaQuery.of(
            //                                                             context)
            //                                                         .size
            //                                                         .width /
            //                                                     2,
            //                                               ),
            //                                               SizedBox(
            //                                                 height: 10,
            //                                               ),
            //                                               Container(
            //                                                 color: Color(
            //                                                     0xff171b27),
            //                                                 height: 10,
            //                                                 width: MediaQuery.of(
            //                                                             context)
            //                                                         .size
            //                                                         .width /
            //                                                     4,
            //                                               )
            //                                             ],
            //                                           )
            //                                         ],
            //                                       ),
            //                                       Padding(
            //                                         padding:
            //                                             const EdgeInsets.all(
            //                                                 15),
            //                                         child: Container(
            //                                           height: 10,
            //                                           width:
            //                                               MediaQuery.of(context)
            //                                                   .size
            //                                                   .width,
            //                                           color: Color(0xff171b27),
            //                                         ),
            //                                       ),
            //                                       Column(
            //                                         mainAxisAlignment:
            //                                             MainAxisAlignment.start,
            //                                         children: [
            //                                           Padding(
            //                                             padding:
            //                                                 const EdgeInsets
            //                                                         .symmetric(
            //                                                     horizontal: 15,
            //                                                     vertical: 5),
            //                                             child: Container(
            //                                               height: 5,
            //                                               width: MediaQuery.of(
            //                                                       context)
            //                                                   .size
            //                                                   .width,
            //                                               color:
            //                                                   Color(0xff171b27),
            //                                             ),
            //                                           ),
            //                                           Padding(
            //                                             padding:
            //                                                 const EdgeInsets
            //                                                         .symmetric(
            //                                                     horizontal: 15,
            //                                                     vertical: 5),
            //                                             child: Container(
            //                                               height: 5,
            //                                               width: MediaQuery.of(
            //                                                       context)
            //                                                   .size
            //                                                   .width,
            //                                               color:
            //                                                   Color(0xff171b27),
            //                                             ),
            //                                           ),
            //                                         ],
            //                                       )
            //                                     ],
            //                                   ),
            //                                 ),
            //                               ),
            //                             ),
            //                         ],
            //                       ),
            //                     )
            //                   : Container(
            //                       child: Column(
            //                         children: [
            //                           for (var v in hiveEpisodes)
            //                             InkWell(
            //                               onTap: () {
            //                                 Navigator.push(context,
            //                                     MaterialPageRoute(
            //                                         builder: (context) {
            //                                   return EpisodeView(
            //                                       episodeId: v['id']);
            //                                 }));
            //                               },
            //                               child: Padding(
            //                                 padding: const EdgeInsets.symmetric(
            //                                     horizontal: 10),
            //                                 child: Container(
            //                                   decoration: BoxDecoration(
            //                                       border: Border(
            //                                           top: BorderSide(
            //                                               color: Color(
            //                                                   0xff171b27)),
            //                                           bottom: BorderSide(
            //                                               color:
            //                                                   Color(0xff171b27),
            //                                               width: 1))),
            //                                   width: double.infinity,
            //                                   child: Padding(
            //                                     padding:
            //                                         const EdgeInsets.symmetric(
            //                                             vertical: 20),
            //                                     child: Column(
            //                                       mainAxisAlignment:
            //                                           MainAxisAlignment.center,
            //                                       children: [
            //                                         Row(
            //                                           children: [
            //                                             Container(
            //                                               // color: Colors.white,
            //                                               width: MediaQuery.of(
            //                                                           context)
            //                                                       .size
            //                                                       .width /
            //                                                   7,
            //                                               height: MediaQuery.of(
            //                                                           context)
            //                                                       .size
            //                                                       .width /
            //                                                   7,
            //                                               child:
            //                                                   CachedNetworkImage(
            //                                                 imageUrl:
            //                                                     v['image'],
            //                                                 memCacheWidth:
            //                                                     MediaQuery.of(
            //                                                             context)
            //                                                         .size
            //                                                         .width
            //                                                         .floor(),
            //                                                 memCacheHeight:
            //                                                     MediaQuery.of(
            //                                                             context)
            //                                                         .size
            //                                                         .width
            //                                                         .floor(),
            //                                                 placeholder:
            //                                                     (context,
            //                                                             url) =>
            //                                                         Container(
            //                                                   child: Image.asset(
            //                                                       'assets/images/Thumbnail.png'),
            //                                                 ),
            //                                                 errorWidget:
            //                                                     (context, url,
            //                                                             error) =>
            //                                                         Icon(Icons
            //                                                             .error),
            //                                               ),
            //                                             ),
            //                                             SizedBox(
            //                                                 width: SizeConfig
            //                                                         .screenWidth /
            //                                                     26),
            //                                             Expanded(
            //                                               child: Column(
            //                                                 crossAxisAlignment:
            //                                                     CrossAxisAlignment
            //                                                         .start,
            //                                                 children: [
            //                                                   GestureDetector(
            //                                                     onTap: () {
            //                                                       Navigator.push(
            //                                                           context,
            //                                                           MaterialPageRoute(
            //                                                               builder:
            //                                                                   (context) {
            //                                                         return PodcastView(
            //                                                             v['podcast_id']);
            //                                                       }));
            //                                                     },
            //                                                     child: Text(
            //                                                       v['podcast_name'],
            //                                                       textScaleFactor: mediaQueryData
            //                                                           .textScaleFactor
            //                                                           .clamp(
            //                                                               0.1,
            //                                                               1.2)
            //                                                           .toDouble(),
            //                                                       style: TextStyle(
            //                                                           // color: Color(
            //                                                           //     0xffe8e8e8),
            //                                                           fontSize: SizeConfig.safeBlockHorizontal * 5.5,
            //                                                           fontWeight: FontWeight.normal),
            //                                                     ),
            //                                                   ),
            //                                                   Text(
            //                                                     '${timeago.format(DateTime.parse(v['published_at']))}',
            //                                                     textScaleFactor:
            //                                                         mediaQueryData
            //                                                             .textScaleFactor
            //                                                             .clamp(
            //                                                                 0.5,
            //                                                                 0.9)
            //                                                             .toDouble(),
            //                                                     style: TextStyle(
            //                                                         // color: Color(
            //                                                         //     0xffe8e8e8),
            //                                                         fontSize: SizeConfig.safeBlockHorizontal * 3.5),
            //                                                   ),
            //                                                 ],
            //                                               ),
            //                                             )
            //                                           ],
            //                                         ),
            //                                         Padding(
            //                                           padding: const EdgeInsets
            //                                                   .symmetric(
            //                                               vertical: 10),
            //                                           child: Container(
            //                                             width: double.infinity,
            //                                             child: Column(
            //                                               crossAxisAlignment:
            //                                                   CrossAxisAlignment
            //                                                       .start,
            //                                               children: [
            //                                                 Text(
            //                                                   v['name'],
            //                                                   textScaleFactor:
            //                                                       mediaQueryData
            //                                                           .textScaleFactor
            //                                                           .clamp(
            //                                                               0.5,
            //                                                               1)
            //                                                           .toDouble(),
            //                                                   style: TextStyle(
            //                                                       // color: Color(
            //                                                       //     0xffe8e8e8),
            //                                                       fontSize:
            //                                                           SizeConfig
            //                                                                   .safeBlockHorizontal *
            //                                                               4.5,
            //                                                       fontWeight:
            //                                                           FontWeight
            //                                                               .bold),
            //                                                 ),
            //                                                 Padding(
            //                                                   padding:
            //                                                       const EdgeInsets
            //                                                               .symmetric(
            //                                                           vertical:
            //                                                               10),
            //                                                   child: v['summary'] ==
            //                                                           null
            //                                                       ? SizedBox(
            //                                                           width: 0,
            //                                                           height: 0)
            //                                                       : (htmlMatch.hasMatch(
            //                                                                   v['summary']) ==
            //                                                               true
            //                                                           ? Text(
            //                                                               parse(v['summary'])
            //                                                                   .body
            //                                                                   .text,
            //                                                               textScaleFactor: mediaQueryData
            //                                                                   .textScaleFactor
            //                                                                   .clamp(0.5, 1)
            //                                                                   .toDouble(),
            //                                                               maxLines:
            //                                                                   2,
            //                                                               style: TextStyle(
            //                                                                   // color: Colors.white,
            //                                                                   fontSize: SizeConfig.safeBlockHorizontal * 3.2),
            //                                                             )
            //                                                           : Text(
            //                                                               '${v['summary']}',
            //                                                               textScaleFactor: mediaQueryData
            //                                                                   .textScaleFactor
            //                                                                   .clamp(0.5, 1)
            //                                                                   .toDouble(),
            //                                                               style: TextStyle(
            //                                                                   //      color: Colors.white,
            //                                                                   fontSize: SizeConfig.safeBlockHorizontal * 3.2),
            //                                                             )),
            //                                                 )
            //                                               ],
            //                                             ),
            //                                           ),
            //                                         ),
            //                                         Container(
            //                                           width: double.infinity,
            //                                           child: Row(
            //                                             mainAxisAlignment:
            //                                                 MainAxisAlignment
            //                                                     .spaceBetween,
            //                                             children: [
            //                                               Row(
            //                                                 mainAxisAlignment:
            //                                                     MainAxisAlignment
            //                                                         .spaceBetween,
            //                                                 children: [
            //                                                   InkWell(
            //                                                     onTap:
            //                                                         () async {
            //                                                       if (prefs.getString(
            //                                                               'HiveUserName') !=
            //                                                           null) {
            //                                                         setState(
            //                                                             () {
            //                                                           v['isLoading'] =
            //                                                               true;
            //                                                         });
            //                                                         await upvoteEpisode(
            //                                                             permlink: v[
            //                                                                 'permlink'],
            //                                                             episode_id:
            //                                                                 v['id']);
            //                                                         setState(
            //                                                             () {
            //                                                           v['ifVoted'] =
            //                                                               !v['ifVoted'];
            //                                                         });
            //                                                         setState(
            //                                                             () {
            //                                                           v['isLoading'] =
            //                                                               false;
            //                                                         });
            //                                                       } else {
            //                                                         showBarModalBottomSheet(
            //                                                             context:
            //                                                                 context,
            //                                                             builder:
            //                                                                 (context) {
            //                                                               return HiveDetails();
            //                                                             });
            //                                                       }
            //                                                     },
            //                                                     child:
            //                                                         Container(
            //                                                       decoration: v[
            //                                                                   'ifVoted'] ==
            //                                                               true
            //                                                           ? BoxDecoration(
            //                                                               gradient:
            //                                                                   LinearGradient(colors: [
            //                                                                 Color(0xff5bc3ef),
            //                                                                 Color(0xff5d5da8)
            //                                                               ]),
            //                                                               borderRadius: BorderRadius.circular(
            //                                                                   30))
            //                                                           : BoxDecoration(
            //                                                               border: Border.all(
            //                                                                   color:
            //                                                                       kSecondaryColor),
            //                                                               borderRadius:
            //                                                                   BorderRadius.circular(30)),
            //                                                       child:
            //                                                           Padding(
            //                                                         padding: const EdgeInsets
            //                                                                 .symmetric(
            //                                                             vertical:
            //                                                                 5,
            //                                                             horizontal:
            //                                                                 5),
            //                                                         child: Row(
            //                                                           children: [
            //                                                             v['isLoading'] ==
            //                                                                     true
            //                                                                 ? Container(
            //                                                                     height: 17,
            //                                                                     width: 18,
            //                                                                     child: SpinKitPulse(
            //                                                                       color: Colors.blue,
            //                                                                     ),
            //                                                                   )
            //                                                                 : Icon(
            //                                                                     FontAwesomeIcons.chevronCircleUp,
            //                                                                     size: 15,
            //                                                                     // color:
            //                                                                     //     Color(0xffe8e8e8),
            //                                                                   ),
            //                                                             Padding(
            //                                                               padding:
            //                                                                   const EdgeInsets.symmetric(horizontal: 8),
            //                                                               child:
            //                                                                   Text(
            //                                                                 v['votes'].toString(),
            //                                                                 textScaleFactor:
            //                                                                     1.0,
            //                                                                 style: TextStyle(fontSize: 12
            //                                                                     // color:
            //                                                                     //     Color(0xffe8e8e8)
            //                                                                     ),
            //                                                               ),
            //                                                             ),
            //                                                             Padding(
            //                                                               padding:
            //                                                                   const EdgeInsets.only(right: 4),
            //                                                               child:
            //                                                                   Text(
            //                                                                 '\$${v['payout_value'].toString().split(' ')[0]}',
            //                                                                 textScaleFactor:
            //                                                                     1.0,
            //                                                                 style:
            //                                                                     TextStyle(
            //                                                                   fontSize: 12,
            //                                                                   // color:
            //                                                                   //     Color(0xffe8e8e8)
            //                                                                 ),
            //                                                               ),
            //                                                             )
            //                                                           ],
            //                                                         ),
            //                                                       ),
            //                                                     ),
            //                                                   ),
            //                                                   // SizedBox(
            //                                                   //   width: SizeConfig
            //                                                   //           .screenWidth /
            //                                                   //       30,
            //                                                   // ),
            //                                                   InkWell(
            //                                                     onTap: () {
            //                                                       if (prefs.getString(
            //                                                               'HiveUserName') !=
            //                                                           null) {
            //                                                         Navigator.push(
            //                                                             context,
            //                                                             MaterialPageRoute(builder:
            //                                                                 (context) {
            //                                                           return Comments(
            //                                                             episodeObject:
            //                                                                 v,
            //                                                           );
            //                                                         }));
            //                                                       } else {
            //                                                         showBarModalBottomSheet(
            //                                                             context:
            //                                                                 context,
            //                                                             builder:
            //                                                                 (context) {
            //                                                               return HiveDetails();
            //                                                             });
            //                                                       }
            //                                                     },
            //                                                     child: Padding(
            //                                                       padding:
            //                                                           const EdgeInsets
            //                                                                   .all(
            //                                                               8.0),
            //                                                       child:
            //                                                           Container(
            //                                                         decoration: BoxDecoration(
            //                                                             border: Border.all(
            //                                                                 color: Color(
            //                                                                     0xff171b27)),
            //                                                             borderRadius:
            //                                                                 BorderRadius.circular(30)),
            //                                                         child:
            //                                                             Padding(
            //                                                           padding:
            //                                                               const EdgeInsets.all(
            //                                                                   4.0),
            //                                                           child:
            //                                                               Row(
            //                                                             children: [
            //                                                               Icon(
            //                                                                 Icons.mode_comment_outlined,
            //                                                                 size:
            //                                                                     14,
            //                                                               ),
            //                                                               Padding(
            //                                                                 padding:
            //                                                                     const EdgeInsets.symmetric(horizontal: 7),
            //                                                                 child:
            //                                                                     Text(
            //                                                                   v['comments_count'].toString(),
            //                                                                   textScaleFactor: 1.0,
            //                                                                   style: TextStyle(fontSize: 10
            //                                                                       // color:
            //                                                                       //     Color(0xffe8e8e8)
            //                                                                       ),
            //                                                                 ),
            //                                                               ),
            //                                                             ],
            //                                                           ),
            //                                                         ),
            //                                                       ),
            //                                                     ),
            //                                                   )
            //                                                 ],
            //                                               ),
            //                                               InkWell(
            //                                                 onTap: () {
            //                                                   print(v
            //                                                       .toString()
            //                                                       .contains(
            //                                                           '.mp4'));
            //                                                   if (v.toString().contains('.mp4') == true ||
            //                                                       v.toString().contains(
            //                                                               '.m4v') ==
            //                                                           true ||
            //                                                       v.toString().contains(
            //                                                               '.flv') ==
            //                                                           true ||
            //                                                       v.toString().contains(
            //                                                               '.f4v') ==
            //                                                           true ||
            //                                                       v.toString().contains(
            //                                                               '.ogv') ==
            //                                                           true ||
            //                                                       v.toString().contains(
            //                                                               '.ogx') ==
            //                                                           true ||
            //                                                       v.toString().contains(
            //                                                               '.wmv') ==
            //                                                           true ||
            //                                                       v.toString().contains(
            //                                                               '.webm') ==
            //                                                           true) {
            //                                                     currentlyPlaying
            //                                                         .stop();
            //                                                     Navigator.push(
            //                                                         context,
            //                                                         MaterialPageRoute(
            //                                                             builder:
            //                                                                 (context) {
            //                                                       return PodcastVideoPlayer(
            //                                                           episodeObject:
            //                                                               v);
            //                                                     }));
            //                                                   } else {
            //                                                     if (v
            //                                                             .toString()
            //                                                             .contains(
            //                                                                 '.pdf') ==
            //                                                         true) {
            //                                                       // Navigator.push(
            //                                                       //     context,
            //                                                       //     MaterialPageRoute(
            //                                                       //         builder:
            //                                                       //             (context) {
            //                                                       //   return PDFviewer(
            //                                                       //       episodeObject:
            //                                                       //           v);
            //                                                       // }));
            //                                                     } else {
            //                                                       currentlyPlaying
            //                                                           .stop();
            //                                                       currentlyPlaying
            //                                                           .episodeObject = v;
            //                                                       print(currentlyPlaying
            //                                                           .episodeObject
            //                                                           .toString());
            //                                                       currentlyPlaying
            //                                                           .play();
            //                                                       showBarModalBottomSheet(
            //                                                           context:
            //                                                               context,
            //                                                           builder:
            //                                                               (context) {
            //                                                             return Player();
            //                                                           });
            //                                                     }
            //                                                   }
            //                                                 },
            //                                                 child: Padding(
            //                                                   padding:
            //                                                       const EdgeInsets
            //                                                               .only(
            //                                                           right:
            //                                                               80),
            //                                                   child: Container(
            //                                                     decoration: BoxDecoration(
            //                                                         border: Border.all(
            //                                                             color: Color(
            //                                                                 0xff171b27)),
            //                                                         borderRadius:
            //                                                             BorderRadius.circular(
            //                                                                 30)),
            //                                                     child: Padding(
            //                                                       padding:
            //                                                           const EdgeInsets
            //                                                               .all(5),
            //                                                       child: Row(
            //                                                         children: [
            //                                                           Icon(
            //                                                             Icons
            //                                                                 .play_circle_outline,
            //                                                             size:
            //                                                                 15,
            //                                                           ),
            //                                                           Padding(
            //                                                             padding:
            //                                                                 const EdgeInsets.symmetric(horizontal: 8),
            //                                                             child:
            //                                                                 Text(
            //                                                               DurationCalculator(
            //                                                                   v['duration']),
            //                                                               textScaleFactor:
            //                                                                   0.75,
            //                                                               // style: TextStyle(
            //                                                               //      color: Color(0xffe8e8e8)
            //                                                               //     ),
            //                                                             ),
            //                                                           ),
            //                                                         ],
            //                                                       ),
            //                                                     ),
            //                                                   ),
            //                                                 ),
            //                                               ),
            //                                               Row(
            //                                                 children: [
            //                                                   // IconButton(
            //                                                   //   onPressed: () {},
            //                                                   //   icon: Icon(Icons
            //                                                   //       .arrow_circle_down_outlined),
            //                                                   // ),
            //                                                   IconButton(
            //                                                     icon: Icon(
            //                                                       FontAwesomeIcons
            //                                                           .shareAlt,
            //                                                       size: SizeConfig
            //                                                               .safeBlockHorizontal *
            //                                                           4,
            //                                                       // color: Color(
            //                                                       //     0xffe8e8e8),
            //                                                     ),
            //                                                     onPressed:
            //                                                         () async {
            //                                                       share(
            //                                                           episodeObject:
            //                                                               v);
            //                                                     },
            //                                                   )
            //                                                 ],
            //                                               )
            //                                             ],
            //                                           ),
            //                                         ),
            //                                       ],
            //                                     ),
            //                                   ),
            //                                 ),
            //                               ),
            //                             ),
            //                           isPaginationLoading == true
            //                               ? Container(
            //                                   height: 10,
            //                                   width: double.infinity,
            //                                   child: LinearProgressIndicator(
            //                                     minHeight: 10,
            //                                     backgroundColor: Colors.blue,
            //                                     valueColor:
            //                                         AlwaysStoppedAnimation<
            //                                                 Color>(
            //                                             Color(0xff6249EF)),
            //                                   ),
            //                                 )
            //                               : SizedBox(
            //                                   height: 0,
            //                                 )
            //                         ],
            //                       ),
            //                     )
            //             ],
            //           ),
            //           SizedBox(
            //             height: 100,
            //           ),
            //         ],
            //       ),
            //     ),
            //     // Container(
            //     //   child: ListView(
            //     //     children: [
            //     //       Padding(
            //     //         padding: const EdgeInsets.symmetric(horizontal: 10),
            //     //         child: Row(
            //     //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     //           children: [
            //     //             Text(
            //     //               "Your Communities",
            //     //               textScaleFactor: mediaQueryData.textScaleFactor
            //     //                   .clamp(0.5, 0.8)
            //     //                   .toDouble(),
            //     //               style: TextStyle(
            //     //                   fontWeight: FontWeight.bold,
            //     //                   // color: Color(0xffe8e8e8),
            //     //                   fontSize:
            //     //                       SizeConfig.safeBlockHorizontal * 6.5),
            //     //             ),
            //     //             IconButton(
            //     //                 icon: Icon(
            //     //                   FontAwesomeIcons.plusCircle,
            //     //                   size: 15,
            //     //                   // color: Color(0xffe8e8e8),
            //     //                 ),
            //     //                 onPressed: () {
            //     //                   Navigator.push(context,
            //     //                       MaterialPageRoute(builder: (context) {
            //     //                     return CreateCommunity();
            //     //                   })).then((value) async {
            //     //                     await _pullRefreshEpisodes();
            //     //                   });
            //     //                 }),
            //     //           ],
            //     //         ),
            //     //       ),
            //     //       Padding(
            //     //         padding: const EdgeInsets.symmetric(vertical: 10),
            //     //         child: Container(
            //     //           child: Column(
            //     //             children: [
            //     //               for (var c in communities.userCreatedCommunities)
            //     //                 Padding(
            //     //                     padding: const EdgeInsets.symmetric(
            //     //                         vertical: 2.5, horizontal: 10),
            //     //                     child: ListTile(
            //     //                       contentPadding: EdgeInsets.symmetric(
            //     //                         horizontal: 0,
            //     //                       ),
            //     //                       leading: AspectRatio(
            //     //                         aspectRatio: 1,
            //     //                         child: Container(
            //     //                           height: MediaQuery.of(context)
            //     //                                   .size
            //     //                                   .width /
            //     //                               6,
            //     //                           width: MediaQuery.of(context)
            //     //                                   .size
            //     //                                   .width /
            //     //                               6,
            //     //                           child: CachedNetworkImage(
            //     //                             memCacheHeight:
            //     //                                 (MediaQuery.of(context)
            //     //                                         .size
            //     //                                         .height)
            //     //                                     .floor(),
            //     //                             placeholder: (context, url) =>
            //     //                                 Container(
            //     //                               child: Image.asset(
            //     //                                   'assets/images/Thumbnail.png'),
            //     //                             ),
            //     //                             imageUrl: c['profileImageUrl'] !=
            //     //                                     null
            //     //                                 ? c['profileImageUrl']
            //     //                                 : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
            //     //                             fit: BoxFit.cover,
            //     //                           ),
            //     //                         ),
            //     //                       ),
            //     //                       title: Padding(
            //     //                         padding: const EdgeInsets.symmetric(
            //     //                             vertical: 5),
            //     //                         child: Text(
            //     //                           c['name'],
            //     //                           textScaleFactor: mediaQueryData
            //     //                               .textScaleFactor
            //     //                               .clamp(0.5, 0.8)
            //     //                               .toDouble(),
            //     //                           maxLines: 1,
            //     //                           overflow: TextOverflow.ellipsis,
            //     //                           style: TextStyle(
            //     //                               //  color: Color(0xffe8e8e8),
            //     //                               fontSize: SizeConfig
            //     //                                       .safeBlockHorizontal *
            //     //                                   5),
            //     //                         ),
            //     //                       ),
            //     //                       subtitle: Text(
            //     //                         c['description'],
            //     //                         textScaleFactor: mediaQueryData
            //     //                             .textScaleFactor
            //     //                             .clamp(0.5, 0.8)
            //     //                             .toDouble(),
            //     //                         style: TextStyle(
            //     //                             // color: Color(0xffe8e8e8)
            //     //                             ),
            //     //                       ),
            //     //                     ))
            //     //             ],
            //     //           ),
            //     //         ),
            //     //       ),
            //     //       SizedBox(
            //     //         height: 30,
            //     //       ),
            //     //       Padding(
            //     //         padding: const EdgeInsets.symmetric(horizontal: 10),
            //     //         child: Row(
            //     //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     //           children: [
            //     //             Text(
            //     //               "Communities you follow",
            //     //               textScaleFactor: mediaQueryData.textScaleFactor
            //     //                   .clamp(0.5, 0.8)
            //     //                   .toDouble(),
            //     //               style: TextStyle(
            //     //                   fontWeight: FontWeight.bold,
            //     //                   // color: Color(0xffe8e8e8),
            //     //                   fontSize:
            //     //                       SizeConfig.safeBlockHorizontal * 6.5),
            //     //             ),
            //     //             IconButton(
            //     //               onPressed: () {},
            //     //               icon: Icon(
            //     //                 FontAwesomeIcons.filter,
            //     //                 size: 15,
            //     //                 // color: Color(0xffe8e8e8),
            //     //               ),
            //     //             )
            //     //           ],
            //     //         ),
            //     //       ),
            //     //       Padding(
            //     //         padding: const EdgeInsets.symmetric(vertical: 10),
            //     //         child: Container(
            //     //           child: Column(
            //     //             children: [
            //     //               for (var c in communities.userCommunities)
            //     //                 Padding(
            //     //                     padding: const EdgeInsets.symmetric(
            //     //                         vertical: 2.5, horizontal: 10),
            //     //                     child: ListTile(
            //     //                       onTap: () {
            //     //                         Navigator.push(context,
            //     //                             MaterialPageRoute(
            //     //                                 builder: (context) {
            //     //                           return CommunityView(
            //     //                               communityObject: c);
            //     //                         }));
            //     //                       },
            //     //                       contentPadding: EdgeInsets.symmetric(
            //     //                         horizontal: 0,
            //     //                       ),
            //     //                       leading: AspectRatio(
            //     //                         aspectRatio: 1,
            //     //                         child: Container(
            //     //                           height: MediaQuery.of(context)
            //     //                                   .size
            //     //                                   .width /
            //     //                               6,
            //     //                           width: MediaQuery.of(context)
            //     //                                   .size
            //     //                                   .width /
            //     //                               6,
            //     //                           child: CachedNetworkImage(
            //     //                             memCacheHeight:
            //     //                                 (MediaQuery.of(context)
            //     //                                         .size
            //     //                                         .height)
            //     //                                     .floor(),
            //     //                             placeholder: (context, url) =>
            //     //                                 Container(
            //     //                               child: Image.asset(
            //     //                                   'assets/images/Thumbnail.png'),
            //     //                             ),
            //     //                             imageUrl: c['profileImageUrl'] !=
            //     //                                     null
            //     //                                 ? c['profileImageUrl']
            //     //                                 : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
            //     //                             fit: BoxFit.cover,
            //     //                           ),
            //     //                         ),
            //     //                       ),
            //     //                       title: Padding(
            //     //                         padding: const EdgeInsets.symmetric(
            //     //                             vertical: 5),
            //     //                         child: Text(
            //     //                           c['name'],
            //     //                           textScaleFactor: mediaQueryData
            //     //                               .textScaleFactor
            //     //                               .clamp(0.5, 0.8)
            //     //                               .toDouble(),
            //     //                           maxLines: 1,
            //     //                           overflow: TextOverflow.ellipsis,
            //     //                           style: TextStyle(
            //     //                               //   color: Color(0xffe8e8e8),
            //     //                               fontSize: SizeConfig
            //     //                                       .safeBlockHorizontal *
            //     //                                   5),
            //     //                         ),
            //     //                       ),
            //     //                       subtitle: Text(
            //     //                         c['description'],
            //     //                         textScaleFactor: mediaQueryData
            //     //                             .textScaleFactor
            //     //                             .clamp(0.5, 0.8)
            //     //                             .toDouble(),
            //     //                         style: TextStyle(
            //     //                             //   color: Color(0xffe8e8e8)
            //     //                             ),
            //     //                       ),
            //     //                     ))
            //     //             ],
            //     //           ),
            //     //         ),
            //     //       ),
            //     //       SizedBox(
            //     //         height: 100,
            //     //       ),
            //     //     ],
            //     //   ),
            //     // ),
            //   ],
            // ),
          ),
        ),
      ),
    );
  }
}

class Episode {
  final String episodeName; //Stream Name
  final String podcastName; //Category Name
  final String authorName; //Streamer Name
  final String listens; //views
  final String value; //value in USD

  Episode(
      {this.episodeName,
      this.podcastName,
      this.authorName,
      this.listens,
      this.value});
}

class Podcast {
  final String podcastName;
  final String authorName;
  final String category;
  final String listens;
  final String value;

  Podcast(
      {this.podcastName,
      this.authorName,
      this.category,
      this.listens,
      this.value});
}
