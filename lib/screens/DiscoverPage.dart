import 'package:auditory/DiscoverProvider.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/buttonPages/Referralprogram.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../CommunityProvider.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/Player.dart';
import 'Player/VideoPlayer.dart';
import 'Profiles/Comments.dart';
import 'Profiles/EpisodeView.dart';
import 'Profiles/PodcastView.dart';
import 'buttonPages/settings/Theme-.dart';

class DiscoverPage extends StatefulWidget {
  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  var homeData = [];
  var featured = [];
  var recentlyPlayed = [];
  var popular_trending = [];
  String displayPicture;
  String hiveUserName;

  void getLocalData() async {
    pref = await SharedPreferences.getInstance();
    print(pref.getString('token'));
    setState(() {
      displayPicture = pref.getString('displayPicture');
      hiveUserName = pref.getString('HiveUserName');
    });
  }

  Launcher launcher = Launcher();

  //to get the data for the discover page
  void getDiscoverContent() async {
    await getLocalData();
  }

  @override
  void initState() {
    // TODO: implement initState

    getDiscoverContent();
    super.initState();
  }

  String creator = '';

  SharedPreferences pref;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    var communities = Provider.of<CommunityProvider>(context);

    var currentlyPlaying = Provider.of<PlayerChange>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    DiscoverProvider discoverData = Provider.of<DiscoverProvider>(context);
    if (discoverData.isFetcheddiscoverList == false) {
      discoverData.getDiscoverProvider();
    }

    setState(() {
      homeData = discoverData.discoverList;
    });
    for (var v in homeData) {
      if (v['Key'] == 'featured') {
        setState(() {
          featured = v['data'];
        });
      }
      if (v['Key'] == 'general_episode') {
        setState(() {
          recentlyPlayed = v['data'];
          for (var v in recentlyPlayed) {
            v['isLoading'] = false;
          }
        });
      }
      if (v['Key'] == 'general_podcast') {
        setState(() {
          popular_trending = v['data'];
        });
      }
    }

    Future<void> _pullRefresh() async {
      print('proceedd');
      await discoverData.getDiscoverProvider();
    }

    Future<bool> _onBackPressed() async {
      Navigator.pushNamedAndRemoveUntil(
          context, Home.id, ModalRoute.withName("/"));
      return false; // return true if the route to be popped
    }

    final mediaQueryData = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          extendBody: true,
          body: ModalProgressHUD(
            inAsyncCall: !discoverData.isFetcheddiscoverList,
            progressIndicator: CircularProgressIndicator(),
            child: Container(
                height: double.infinity,
                width: double.infinity,
                child: RefreshIndicator(
                  onRefresh: _pullRefresh,
                  child: ListView(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ReferralProgram();
                            }));
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Color(0xff222222),
                                  gradient: LinearGradient(colors: [
                                    Color(0xff5d5da8),
                                    Color(0xff5bc3ef)
                                  ]),
                                  borderRadius: BorderRadius.circular(8)),
                              width: MediaQuery.of(context).size.width * 0.75,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                    title: Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        "Help us spread the word!",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Invite your favourite podcasts to Aureal and earn rewards",
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3),
                                    ),
                                    trailing: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                          Icons.arrow_forward_ios_outlined),
                                    )),
                              )),
                        ),
                      ),
                      for (var v in homeData)
                        v['data'].length == 0
                            ? SizedBox(
                                height: 0,
                              )
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      v['topic'] == 'Featured Podcasts'
                                          ? SizedBox(
                                              width: 0,
                                              height: 0,
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15),
                                              child: Text(
                                                v['topic'],
                                                textScaleFactor: mediaQueryData
                                                    .textScaleFactor
                                                    .clamp(0.1, 1.3)
                                                    .toDouble(),
                                                style: TextStyle(
                                                    //  color: Color(0xffe8e8e8),
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        7.2,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      v['topic'] == 'Featured Podcasts'
                                          ? v['isLoaded'] == false
                                              ? Shimmer.fromColors(
                                                  baseColor: Color(0xff3a3a3a),
                                                  highlightColor: kPrimaryColor,
                                                  child: Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.8,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.8,
                                                    color: kSecondaryColor,
                                                  ),
                                                )
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 20),
                                                  child: Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            1.04,
                                                    width: double.infinity,
                                                    child: CarouselSlider(
                                                      options: CarouselOptions(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.9,
                                                          autoPlay: true,
                                                          enableInfiniteScroll:
                                                              true,
                                                          viewportFraction: 0.9,
//
                                                          aspectRatio: 4 / 3,
                                                          pauseAutoPlayOnTouch:
                                                              true,
                                                          enlargeCenterPage:
                                                              false),
                                                      items: <Widget>[
                                                        for (var v in featured)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: Color(
                                                                      0xff222222),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              15)),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(builder:
                                                                              (context) {
                                                                        return PodcastView(
                                                                            v['id']);
                                                                      }));
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.85,
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.85,

//
                                                                      child:
                                                                          Container(
                                                                        child:
                                                                            CachedNetworkImage(
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: BorderRadius.circular(10),
                                                                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                                                              ),
                                                                              height: MediaQuery.of(context).size.width,
                                                                              width: MediaQuery.of(context).size.width,
                                                                            );
                                                                          },
                                                                          placeholder:
                                                                              (context, String url) {
                                                                            return Container(
                                                                              width: MediaQuery.of(context).size.width / 4,
                                                                              height: MediaQuery.of(context).size.width / 4,
                                                                            );
                                                                          },
                                                                          memCacheHeight:
                                                                              (MediaQuery.of(context).size.height).floor(),
                                                                          imageUrl: v['image'] == null
                                                                              ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                                              : v['image'],
                                                                          errorWidget: (context, url, error) =>
                                                                              Icon(Icons.error),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets.fromLTRB(
                                                                            20,
                                                                            0,
                                                                            20,
                                                                            10),
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .end,
                                                                      children: [
                                                                        Text(
                                                                          v['name'] != null
                                                                              ? v['name']
                                                                              : ' ',
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          style: TextStyle(
                                                                              color: Color(0xffe8e8e8),
                                                                              fontSize: SizeConfig.blockSizeHorizontal * 4.7,
                                                                              fontWeight: FontWeight.normal),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.only(top: 5),
                                                                          child:
                                                                              Text(
                                                                            v['author'] != null
                                                                                ? v['author']
                                                                                : ' ',
                                                                            textScaleFactor:
                                                                                1.0,
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style:
                                                                                TextStyle(
                                                                              color: Color(0xff777777),
                                                                              fontSize: SizeConfig.safeBlockHorizontal * 3,
                                                                              //   color: Colors
                                                                              //     .grey
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              5.0,
                                                                        )
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
                                                )
                                          : v['topic'] == 'Recently Played'
                                              ? Container(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      3,
                                                  child: GridView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                            crossAxisCount: 2,
                                                            mainAxisSpacing: 10,
                                                            crossAxisSpacing: 1,
                                                            childAspectRatio:
                                                                1 / 2.6),
                                                    children: [
                                                      for (var a
                                                          in recentlyPlayed)
                                                        InkWell(
                                                          onTap: () {
                                                            print(a
                                                                .toString()
                                                                .contains(
                                                                    '.mp4'));
                                                            if (a.toString().contains('.mp4') == true ||
                                                                a.toString().contains(
                                                                        '.m4v') ==
                                                                    true ||
                                                                a.toString().contains(
                                                                        '.flv') ==
                                                                    true ||
                                                                a.toString().contains(
                                                                        '.f4v') ==
                                                                    true ||
                                                                a.toString().contains(
                                                                        '.ogv') ==
                                                                    true ||
                                                                a.toString().contains(
                                                                        '.ogx') ==
                                                                    true ||
                                                                a.toString().contains(
                                                                        '.wmv') ==
                                                                    true ||
                                                                a.toString().contains(
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
                                                                        a);
                                                              }));
                                                            } else {
                                                              if (a
                                                                      .toString()
                                                                      .contains(
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
                                                                    .episodeObject = a;
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
                                                          child: Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.85,
                                                            decoration:
                                                                BoxDecoration(
                                                                    // color: Color(
                                                                    //     0xff222222),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10)),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(15),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        4.5,
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        4.5,
                                                                    child:
                                                                        Stack(
                                                                      children: [
                                                                        CachedNetworkImage(
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              height: MediaQuery.of(context).size.width / 4.5,
                                                                              width: MediaQuery.of(context).size.width / 4.5,
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: BorderRadius.circular(8),
                                                                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                                                              ),
                                                                            );
                                                                          },
                                                                          memCacheHeight:
                                                                              (MediaQuery.of(context).size.height).floor(),
                                                                          imageUrl: a['image'] != null
                                                                              ? a['image']
                                                                              : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                                                          placeholder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/Thumbnail.png'), fit: BoxFit.cover)),
                                                                              height: MediaQuery.of(context).size.width * 0.38,
                                                                              width: MediaQuery.of(context).size.width * 0.38,
                                                                            );
                                                                          },
                                                                        ),
                                                                        Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.end,
                                                                          children: [
                                                                            FutureBuilder(
                                                                                future: dursaver.percentageDone(a['id']),
                                                                                builder: (context, snapshot) {
                                                                                  if (snapshot.data.toString() == 'null') {
                                                                                    return Container();
                                                                                  } else {
                                                                                    // return Text(double.parse(snapshot.data.toString()).toStringAsFixed(2).toString());
                                                                                    return Stack(
                                                                                      children: [
                                                                                        Container(
                                                                                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
                                                                                          width: MediaQuery.of(context).size.width / 4.5 * double.parse(double.parse(snapshot.data.toString()).toStringAsFixed(2)),
                                                                                          height: 5,
                                                                                        ),
                                                                                        Container(
                                                                                          width: MediaQuery.of(context).size.width / 4.5,
                                                                                          height: 2,
                                                                                        )
                                                                                      ],
                                                                                    );
                                                                                  }
                                                                                }),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .symmetric(
                                                                        horizontal:
                                                                            15),
                                                                    child:
                                                                        SizedBox(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          2,
                                                                      height: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          4.5,
                                                                      child:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Padding(
                                                                                padding: const EdgeInsets.only(bottom: 5),
                                                                                child: GestureDetector(
                                                                                  onTap: () {
                                                                                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                                                                                      return EpisodeView(
                                                                                        episodeId: a['id'],
                                                                                      );
                                                                                    }));
                                                                                  },
                                                                                  child: GestureDetector(
                                                                                    onTap: () {
                                                                                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                                                                                        return PodcastView(a['podcast_id']);
                                                                                      }));
                                                                                    },
                                                                                    child: Text(
                                                                                      a['name'].toString(),
                                                                                      overflow: TextOverflow.clip,
                                                                                      maxLines: 2,
                                                                                      textScaleFactor: 1.0,
                                                                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                a['podcast_name'].toString(),
                                                                                textScaleFactor: 1.0,
                                                                                maxLines: 1,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                style: TextStyle(color: Color(0xff777777), fontSize: SizeConfig.safeBlockHorizontal * 2.8),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              InkWell(
                                                                                onTap: () async {
                                                                                  if (pref.getString('HiveUserName') != null) {
                                                                                    setState(() {
                                                                                      v['isLoading'] = true;
                                                                                    });
                                                                                    double _value = 50.0;
                                                                                    showDialog(
                                                                                        context: context,
                                                                                        builder: (context) {
                                                                                          return Dialog(backgroundColor: Colors.transparent, child: UpvoteEpisode(permlink: a['permlink'], episode_id: a['id']));
                                                                                        }).then((value) async {
                                                                                      print(value);
                                                                                    });
                                                                                    setState(() {
                                                                                      a['ifVoted'] = !a['ifVoted'];
                                                                                    });
                                                                                    setState(() {
                                                                                      a['isLoading'] = false;
                                                                                    });
                                                                                  } else {
                                                                                    showBarModalBottomSheet(
                                                                                        context: context,
                                                                                        builder: (context) {
                                                                                          return HiveDetails();
                                                                                        });
                                                                                  }
                                                                                },
                                                                                child: Container(
                                                                                  decoration: a['ifVoted'] == true ? BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Color(0xff5bc3ef), Color(0xff5d5da8)])) : BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xff222222))),
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                                    child: Row(
                                                                                      children: [
                                                                                        a['isLoading'] == true
                                                                                            ? SpinKitCircle(
                                                                                                color: Colors.white,
                                                                                                size: 10,
                                                                                              )
                                                                                            : Icon(
                                                                                                FontAwesomeIcons.chevronCircleUp,
                                                                                                size: 15,
                                                                                              ),
                                                                                        SizedBox(
                                                                                          width: 5,
                                                                                        ),
                                                                                        Text(
                                                                                          "${a['payout_value'].toString().split(' ')[0]}",
                                                                                          textScaleFactor: 1.0,
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                width: 10,
                                                                              ),
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  if (pref.getString('HiveUserName') != null) {
                                                                                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                                                                                      return Comments(
                                                                                        episodeObject: a,
                                                                                      );
                                                                                    }));
                                                                                  } else {
                                                                                    showBarModalBottomSheet(
                                                                                        context: context,
                                                                                        builder: (context) {
                                                                                          return HiveDetails();
                                                                                        });
                                                                                  }
                                                                                },
                                                                                child: Container(
                                                                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xff222222))),
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                                    child: Row(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        Icon(
                                                                                          Icons.mode_comment_outlined,
                                                                                          size: 15,
                                                                                        ),
                                                                                        SizedBox(
                                                                                          width: 5,
                                                                                        ),
                                                                                        Text(
                                                                                          '${a['comments_count'].toString()}',
                                                                                          textScaleFactor: 1.0,
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                                )
                                              : v['topic'] ==
                                                      'Recommended for you'
                                                  ? Container(
                                                      width: double.infinity,
                                                      height: SizeConfig
                                                              .blockSizeVertical *
                                                          28,
                                                      constraints: BoxConstraints(
                                                          minHeight:
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.17),
                                                      child: ListView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        children: [
                                                          for (var a
                                                              in v['data'])
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .fromLTRB(
                                                                      15,
                                                                      8,
                                                                      0,
                                                                      8),
                                                              child: InkWell(
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder:
                                                                              (context) {
                                                                    return PodcastView(
                                                                        a['id']);
                                                                  }));
                                                                },
                                                                child:
                                                                    Container(
                                                                  decoration: BoxDecoration(
                                                                      color: Color(
                                                                          0xff222222),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8)),
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.38,
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      CachedNetworkImage(
                                                                        imageBuilder:
                                                                            (context,
                                                                                imageProvider) {
                                                                          return Container(
                                                                            decoration:
                                                                                BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover), borderRadius: BorderRadius.circular(8)),
                                                                            width:
                                                                                MediaQuery.of(context).size.width * 0.38,
                                                                            height:
                                                                                MediaQuery.of(context).size.width * 0.38,
                                                                          );
                                                                        },
                                                                        memCacheHeight:
                                                                            (MediaQuery.of(context).size.height).floor(),
                                                                        imageUrl: a['image'] !=
                                                                                null
                                                                            ? a['image']
                                                                            : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                                                        placeholder:
                                                                            (context,
                                                                                imageProvider) {
                                                                          return Container(
                                                                            decoration:
                                                                                BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/Thumbnail.png'), fit: BoxFit.cover)),
                                                                            height:
                                                                                MediaQuery.of(context).size.width * 0.38,
                                                                            width:
                                                                                MediaQuery.of(context).size.width * 0.38,
                                                                          );
                                                                        },
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets.fromLTRB(
                                                                            8,
                                                                            8,
                                                                            8,
                                                                            0),
                                                                        child:
                                                                            Text(
                                                                          a['name'],
                                                                          maxLines:
                                                                              2,
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          style:
                                                                              TextStyle(color: Color(0xffe8e8e8)),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets.fromLTRB(
                                                                            8,
                                                                            0,
                                                                            8,
                                                                            8),
                                                                        child:
                                                                            Text(
                                                                          a['author'],
                                                                          maxLines:
                                                                              2,
                                                                          textScaleFactor:
                                                                              1.0,
                                                                          style: TextStyle(
                                                                              fontSize: SizeConfig.safeBlockHorizontal * 2.5,
                                                                              color: Color(0xffe777777)),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                        ],
                                                      ),
                                                    )
                                                  : Container(
                                                      width: double.infinity,
                                                      height: SizeConfig
                                                              .blockSizeVertical *
                                                          23,
                                                      constraints: BoxConstraints(
                                                          minHeight:
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.14),
                                                      child: ListView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        children: <Widget>[
                                                          for (var a
                                                              in v['data'])
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .fromLTRB(
                                                                      15,
                                                                      8,
                                                                      0,
                                                                      8),
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: <
                                                                      Widget>[
                                                                    GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        if (a['duration'] !=
                                                                            null) {
                                                                          currentlyPlaying
                                                                              .stop();
                                                                          currentlyPlaying.episodeObject =
                                                                              a;
                                                                          currentlyPlaying
                                                                              .play();
                                                                        } else {
                                                                          Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(builder: (context) {
                                                                            return PodcastView(a['id']);
                                                                          }));
                                                                        }
                                                                      },
                                                                      child:
                                                                          CachedNetworkImage(
                                                                        imageBuilder:
                                                                            (context,
                                                                                imageProvider) {
                                                                          return Container(
                                                                            decoration:
                                                                                BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover), borderRadius: BorderRadius.circular(8)),
                                                                            width:
                                                                                MediaQuery.of(context).size.width / 4,
                                                                            height:
                                                                                MediaQuery.of(context).size.width / 4,
                                                                          );
                                                                        },
                                                                        placeholder:
                                                                            (context,
                                                                                String url) {
                                                                          return Container(
                                                                            width:
                                                                                MediaQuery.of(context).size.width / 4,
                                                                            height:
                                                                                MediaQuery.of(context).size.width / 4,
                                                                          );
                                                                        },
                                                                        memCacheHeight:
                                                                            (MediaQuery.of(context).size.height).floor(),
                                                                        imageUrl: a['image'] !=
                                                                                null
                                                                            ? a['image']
                                                                            : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          10,
                                                                    ),
                                                                    Flexible(
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(left: 5),
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              MediaQuery.of(context).size.width / 4,
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: <Widget>[
                                                                              Text(
                                                                                a['name'] != null ? a['name'] : ' ',
                                                                                textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                                maxLines: 2,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                style: TextStyle(
                                                                                    //     color: C
                                                                                    //       .wh,
                                                                                    fontWeight: FontWeight.normal,
                                                                                    fontSize: SizeConfig.safeBlockHorizontal * 3.4),
                                                                              ),
                                                                              a['author'] == null
                                                                                  ? Text('  ')
                                                                                  : Text(
                                                                                      a['author'],
                                                                                      textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                                      maxLines: 1,
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      style: TextStyle(
                                                                                        color: Color(0xff777777),
                                                                                        fontSize: SizeConfig.safeBlockHorizontal * 2.5,
                                                                                        //    color: Colors.black54
                                                                                      ),
                                                                                    )
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
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
                      SizedBox(
                        height: 50,
                      )
                    ],
                  ),
                )),
          ),
          // ),
        );
      },
    );
  }
}
