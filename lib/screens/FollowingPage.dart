import 'dart:convert';

import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/CommunityService.dart';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
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
import 'package:timeago/timeago.dart' as timeago;

import '../PlayerState.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/VideoPlayer.dart';
import 'Profiles/CategoryView.dart';
import 'Profiles/Comments.dart';
import 'RouteAnimation.dart';
import 'buttonPages/settings/Theme-.dart';

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

  CommunityProvider communities;

  var currentlyPlaying = null;

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

  CommunityService service;

  int pageNumber = 0;

  void toggle() {
    animationController.isDismissed
        ? animationController.forward()
        : animationController.reverse();
  }

  var episodes = [];

  TabController _tabController;
  RegExp htmlMatch = RegExp(r'(\w+)');

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
    print("Following podcasts done");

    setState(() {
      isLoading = false;
    });
  }

  int pagenumber = 0;

  List hiveEpisodes = [];

  void getHiveFollowedEpisode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/browseHiveEpisodesTest?user_id=${prefs.getString('userId')}&page=$pageNumber&pageSize=10";
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
      isFollowingPageLoading = false;
    });
  }

  bool isPaginationLoading = true;
  bool isFollowingPageLoading = true;

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
        getHiveFollowedEpisode();
      }
    });
    getLocalData();

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

    var categories = Provider.of<CategoriesProvider>(context);
    currentlyPlaying = Provider.of<PlayerChange>(context);

    Future<void> _pullRefreshEpisodes() async {
      getFollowedPodcasts();
      getHiveFollowedEpisode();

      // await getFollowedPodcasts();
    }

    Future<bool> _onBackPressed() async {
      Navigator.pushNamedAndRemoveUntil(
          context, Home.id, ModalRoute.withName("/"));
      return false; // return true if the route to be popped
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

    final mediaQueryData = MediaQuery.of(context);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: NestedScrollView(
          physics: BouncingScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Color(0xff161616),
                automaticallyImplyLeading: false,
                expandedHeight: 30,
                pinned: true,
                //     backgroundColor: kPrimaryColor,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(20),
                  child: Container(
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Row(
                              children: [
                                for (var v in categories.categoryList)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          SlideRightRoute(
                                              widget: CategoryView(
                                                  categoryObject: v)));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kSecondaryColor),
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
                                  ),
                              ],
                            ),
                          ],
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
            child: ListView(
              controller: _scrollController,
              children: [
                Container(
                  child: WidgetANimator(
                    Column(
                      children: [
                        favPodcast.length == 0 || favPodcast.length == null
                            ? Container(
                                width: double.infinity,
                                height: MediaQuery.of(context).size.height / 5,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (int i = 0; i < 10; i++)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          child: Column(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: Color(0xff222222)),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    4,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    4,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Color(0xff222222)),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      4,
                                                  height: 12,
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: Color(0xff222222)),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    4,
                                                height: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                  ],
                                ),
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
                                        height:
                                            MediaQuery.of(context).size.height /
                                                4.2,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: [
                                            for (var v in favPodcast)
                                              InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      SlideRightRoute(
                                                          widget: PodcastView(
                                                              v['id'])));
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      CachedNetworkImage(
                                                        imageBuilder: (context,
                                                            imageProvider) {
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover),
                                                            ),
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                4,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                4,
                                                          );
                                                        },
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
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                          child: Image.asset(
                                                              'assets/images/Thumbnail.png'),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(Icons.error),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                vertical: 10),
                                                        child: Container(
                                                          width: MediaQuery.of(
                                                                      context)
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
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  // color: Colors.white,
                                                                  fontSize:
                                                                      SizeConfig
                                                                              .safeBlockHorizontal *
                                                                          4,
                                                                ),
                                                              ),
                                                              Text(
                                                                v['author'],
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            0.9)
                                                                        .toDouble(),
                                                                maxLines: 2,
                                                                style: TextStyle(
                                                                    // color:
                                                                    //     Colors.white,
                                                                    fontSize: SizeConfig.safeBlockHorizontal * 3),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )),
                                  ],
                                ),
                              ),
                        hiveEpisodeLoading == true
                            ? Column(
                                children: [
                                  for (int i = 0; i < 50; i++)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Color(0xff222222)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Container(
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
                                                    decoration: BoxDecoration(
                                                        color:
                                                            Color(0xff161616),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Color(
                                                                    0xff161616)),
                                                        height: 16,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            3,
                                                      ),
                                                      SizedBox(
                                                        height: 5,
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Color(
                                                                    0xff161616)),
                                                        height: 8,
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
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Color(0xff161616),
                                                    height: 10,
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Color(0xff161616),
                                                    height: 10,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            2),
                                              ),
                                              SizedBox(
                                                height: 6,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Color(0xff161616),
                                                    height: 6,
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Color(0xff161616),
                                                    height: 6,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.75),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 20),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color:
                                                            Color(0xff161616),
                                                      ),
                                                      height: 25,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                      //    color: kSecondaryColor,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          color:
                                                              Color(0xff161616),
                                                        ),
                                                        height: 25,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            8,
                                                        //    color: kSecondaryColor,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          color:
                                                              Color(0xff161616),
                                                        ),
                                                        height: 20,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            8,
                                                        //    color: kSecondaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    for (var v in hiveEpisodes)
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              SlideRightRoute(
                                                  widget: EpisodeView(
                                                      episodeId: v['id'])));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    new BoxShadow(
                                                      color: Colors.black54
                                                          .withOpacity(0.2),
                                                      blurRadius: 10.0,
                                                    ),
                                                  ],
                                                  color: themeProvider
                                                              .isLightTheme ==
                                                          true
                                                      ? Colors.white
                                                      : Color(0xff222222),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                width: double.infinity,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 20,
                                                      horizontal: 20),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          CachedNetworkImage(
                                                            imageBuilder: (context,
                                                                imageProvider) {
                                                              return Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  image: DecorationImage(
                                                                      image:
                                                                          imageProvider,
                                                                      fit: BoxFit
                                                                          .cover),
                                                                ),
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    7,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    7,
                                                              );
                                                            },
                                                            imageUrl:
                                                                v['image'],
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
                                                                (context,
                                                                        url) =>
                                                                    Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  7,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  7,
                                                              child: Image.asset(
                                                                  'assets/images/Thumbnail.png'),
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                        error) =>
                                                                    Icon(Icons
                                                                        .error),
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
                                                                        SlideRightRoute(
                                                                            widget:
                                                                                PodcastView(v['podcast_id'])));
                                                                  },
                                                                  child: Text(
                                                                    v['podcast_name'],
                                                                    textScaleFactor: mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.1,
                                                                            1.2)
                                                                        .toDouble(),
                                                                    style: TextStyle(
                                                                        // color: Color(
                                                                        //     0xffe8e8e8),
                                                                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                                                                        fontWeight: FontWeight.normal),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '${timeago.format(DateTime.parse(v['published_at']))}',
                                                                  textScaleFactor: mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.5,
                                                                          0.9)
                                                                      .toDouble(),
                                                                  style: TextStyle(
                                                                      // color: Color(
                                                                      //     0xffe8e8e8),
                                                                      fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                vertical: 10),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
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
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
                                                                style: TextStyle(
                                                                    // color: Color(
                                                                    //     0xffe8e8e8),
                                                                    fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                                                                    fontWeight: FontWeight.bold),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        10),
                                                                child: v['summary'] ==
                                                                        null
                                                                    ? SizedBox(
                                                                        width:
                                                                            0,
                                                                        height:
                                                                            0)
                                                                    : (htmlMatch.hasMatch(v['summary']) ==
                                                                            true
                                                                        ? Text(
                                                                            parse(v['summary']).body.text,
                                                                            textScaleFactor:
                                                                                mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                            maxLines:
                                                                                2,
                                                                            style: TextStyle(
                                                                                // color: Colors.white,
                                                                                fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                          )
                                                                        : Text(
                                                                            '${v['summary']}',
                                                                            textScaleFactor:
                                                                                mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
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
                                                        width: MediaQuery.of(
                                                                context)
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
                                                                  onTap:
                                                                      () async {
                                                                    if (prefs.getString(
                                                                            'HiveUserName') !=
                                                                        null) {
                                                                      setState(
                                                                          () {
                                                                        v['isLoading'] =
                                                                            true;
                                                                      });
                                                                      double
                                                                          _value =
                                                                          50.0;
                                                                      showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return Dialog(
                                                                                backgroundColor: Colors.transparent,
                                                                                child: UpvoteEpisode(permlink: v['permlink'], episode_id: v['id']));
                                                                          }).then((value) async {
                                                                        print(
                                                                            value);
                                                                      });
                                                                      setState(
                                                                          () {
                                                                        v['ifVoted'] =
                                                                            !v['ifVoted'];
                                                                      });
                                                                      setState(
                                                                          () {
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
                                                                  child:
                                                                      Container(
                                                                    decoration: v['ifVoted'] ==
                                                                            true
                                                                        ? BoxDecoration(
                                                                            gradient:
                                                                                LinearGradient(colors: [
                                                                              Color(0xff5bc3ef),
                                                                              Color(0xff5d5da8)
                                                                            ]),
                                                                            borderRadius: BorderRadius.circular(
                                                                                30))
                                                                        : BoxDecoration(
                                                                            border:
                                                                                Border.all(color: kSecondaryColor),
                                                                            borderRadius: BorderRadius.circular(30)),
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                              .symmetric(
                                                                          vertical:
                                                                              5,
                                                                          horizontal:
                                                                              5),
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          v['isLoading'] == true
                                                                              ? Container(
                                                                                  height: 17,
                                                                                  width: 18,
                                                                                  child: SpinKitPulse(
                                                                                    color: Colors.blue,
                                                                                  ),
                                                                                )
                                                                              : Icon(
                                                                                  FontAwesomeIcons.chevronCircleUp,
                                                                                  size: 15,
                                                                                  // color:
                                                                                  //     Color(0xffe8e8e8),
                                                                                ),
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 8),
                                                                            child:
                                                                                Text(
                                                                              v['votes'].toString(),
                                                                              textScaleFactor: 1.0,
                                                                              style: TextStyle(fontSize: 12
                                                                                  // color:
                                                                                  //     Color(0xffe8e8e8)
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.only(right: 4),
                                                                            child:
                                                                                Text(
                                                                              '\$${v['payout_value'].toString().split(' ')[0]}',
                                                                              textScaleFactor: 1.0,
                                                                              style: TextStyle(
                                                                                fontSize: 12,

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
                                                                          SlideRightRoute(
                                                                              widget: Comments(
                                                                            episodeObject:
                                                                                v,
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
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                            8.0),
                                                                    child:
                                                                        Container(
                                                                      decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                              color:
                                                                                  kSecondaryColor),
                                                                          borderRadius:
                                                                              BorderRadius.circular(30)),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(4.0),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.mode_comment_outlined,
                                                                              size: 14,
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 7),
                                                                              child: Text(
                                                                                v['comments_count'].toString(),
                                                                                textScaleFactor: 1.0,
                                                                                style: TextStyle(fontSize: 10
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
                                                                        v.toString().contains('.m4v') ==
                                                                            true ||
                                                                        v.toString().contains('.flv') ==
                                                                            true ||
                                                                        v.toString().contains('.f4v') ==
                                                                            true ||
                                                                        v.toString().contains('.ogv') ==
                                                                            true ||
                                                                        v.toString().contains('.ogx') ==
                                                                            true ||
                                                                        v.toString().contains('.wmv') ==
                                                                            true ||
                                                                        v.toString().contains('.webm') ==
                                                                            true) {
                                                                      currentlyPlaying
                                                                          .stop();
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(builder:
                                                                              (context) {
                                                                        return PodcastVideoPlayer(
                                                                            episodeObject:
                                                                                v);
                                                                      }));
                                                                    } else {
                                                                      if (v.toString().contains(
                                                                              '.pdf') ==
                                                                          true) {
                                                                        // Navigator.push(
                                                                        //     context,
                                                                        //     MaterialPageRoute(
                                                                        // der:
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
                                                                        Navigator.push(
                                                                            context,
                                                                            MaterialPageRoute(builder:
                                                                                (context) {
                                                                          return Player();
                                                                        }));
                                                                      }
                                                                    }
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            60),
                                                                    child:
                                                                        Container(
                                                                      decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                              color:
                                                                                  kSecondaryColor),
                                                                          borderRadius:
                                                                              BorderRadius.circular(30)),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(5),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.play_circle_outline,
                                                                              size: 15,
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                              child: Text(
                                                                                DurationCalculator(v['duration']),
                                                                                textScaleFactor: 0.75,
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
                                                            InkWell(
                                                              onTap: () {
                                                                share(
                                                                    episodeObject:
                                                                        v);
                                                              },
                                                              child: Icon(
                                                                Icons.share,
                                                                // size: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Builder(builder: (context) {
                                                if (currentlyPlaying
                                                        .episodeName !=
                                                    null) {
                                                  return v['id'] ==
                                                              currentlyPlaying
                                                                      .episodeObject[
                                                                  'id'] &&
                                                          currentlyPlaying
                                                                      .episodeObject[
                                                                  'id'] !=
                                                              null
                                                      ? Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      7),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30),
                                                                gradient:
                                                                    LinearGradient(
                                                                        colors: [
                                                                      Color(
                                                                          0xff5d5da8),
                                                                      Color(
                                                                          0xff5bc3ef)
                                                                    ])),
                                                            width:
                                                                double.infinity,
                                                            height: 4,
                                                          ),
                                                        )
                                                      : SizedBox();
                                                } else {
                                                  return SizedBox();
                                                }
                                              }),
                                            ],
                                          ),
                                        ),
                                      ),
                                    for (int i = 0; i < 2; i++)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Color(0xff222222)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Container(
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
                                                      decoration: BoxDecoration(
                                                          color:
                                                              Color(0xff161616),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                  color: Color(
                                                                      0xff161616)),
                                                          height: 16,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              3,
                                                        ),
                                                        SizedBox(
                                                          height: 5,
                                                        ),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                  color: Color(
                                                                      0xff161616)),
                                                          height: 8,
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
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Color(0xff161616),
                                                      height: 10,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Color(0xff161616),
                                                      height: 10,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              2),
                                                ),
                                                SizedBox(
                                                  height: 6,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Color(0xff161616),
                                                      height: 6,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Color(0xff161616),
                                                      height: 6,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.75),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 20),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          color:
                                                              Color(0xff161616),
                                                        ),
                                                        height: 25,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            8,
                                                        //    color: kSecondaryColor,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 10),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            color: Color(
                                                                0xff161616),
                                                          ),
                                                          height: 25,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                          //    color: kSecondaryColor,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 10),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            color: Color(
                                                                0xff161616),
                                                          ),
                                                          height: 20,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                          //    color: kSecondaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
