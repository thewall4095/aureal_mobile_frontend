import 'dart:convert';


import 'package:auditory/DiscoverProvider.dart';
import 'package:auditory/PlayerState.dart';
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
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:just_audio/just_audio.dart' as ja;
import '../CommunityProvider.dart';
import 'Profiles/PodcastView.dart';

class DiscoverPage extends StatefulWidget {
  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {

  var player = ja.AudioPlayer();

  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  Future<Duration> getAudioDuration(String url) async {
    var duration = await player.setUrl(url);
    print(duration.inSeconds);
    return duration;
  }

  var homeData = [];
  var featured = [];
  var recentlyPlayed = [];
  var popular_trending = [];
  String displayPicture;
  String hiveUserName;

  void getLocalData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
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

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    var communities = Provider.of<CommunityProvider>(context);

    var currentlyPlaying = Provider.of<PlayerChange>(context);

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
        return WillPopScope(
          onWillPop: _onBackPressed,
          child: Scaffold(
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
                                child: ListTile(
                                    title: Text(
                                      "Refer and Earn",
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  4,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                        "Invite your favourite podcasts to Aureal and earn rewards"),
                                    trailing: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                          Icons.arrow_forward_ios_outlined),
                                    ))),
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
                                                  textScaleFactor:
                                                      mediaQueryData
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
                                                    baseColor:
                                                        Color(0xff3a3a3a),
                                                    highlightColor:
                                                        kPrimaryColor,
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
                                                              1.03,
                                                      width: double.infinity,
                                                      child: CarouselSlider(
                                                        options:
                                                            CarouselOptions(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    0.8,
                                                                autoPlay: true,
                                                                enableInfiniteScroll:
                                                                    true,
                                                                viewportFraction:
                                                                    0.85,
//
                                                                aspectRatio:
                                                                    4 / 3,
                                                                pauseAutoPlayOnTouch:
                                                                    true,
                                                                enlargeCenterPage:
                                                                    false),
                                                        items: <Widget>[
                                                          for (var v
                                                              in featured)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                    color: Color(
                                                                        0xff222222),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
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
                                                                      onTap:
                                                                          () {
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
                                                                        height: MediaQuery.of(context).size.width *
                                                                            0.8,
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.8,

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
                                                                            imageUrl: v['image'] == null
                                                                                ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                                                : v['image'],
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
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .fromLTRB(
                                                                          20,
                                                                          0,
                                                                          20,
                                                                          10),
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        children: [
                                                                          Text(
                                                                            v['name'] != null
                                                                                ? v['name']
                                                                                : ' ',
                                                                            textScaleFactor:
                                                                                mediaQueryData.textScaleFactor.clamp(0.2, 1.1).toDouble(),
                                                                            maxLines:
                                                                                2,
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
                                                                              v['author'] != null ? v['author'] : ' ',
                                                                              textScaleFactor: 1.0,
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: TextStyle(
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
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            3,
                                                    // child: ListView(
                                                    //   scrollDirection:
                                                    //       Axis.horizontal,
                                                    //   children: [
                                                    //     for (var a in v['data'])
                                                    //       Padding(
                                                    //         padding:
                                                    //             const EdgeInsets
                                                    //                 .all(8.0),
                                                    //         child: Container(
                                                    //             width: MediaQuery.of(
                                                    //                         context)
                                                    //                     .size
                                                    //                     .width *
                                                    //                 0.8,
                                                    //             decoration: BoxDecoration(
                                                    //                 color: Color(
                                                    //                     0xff222222)),
                                                    //             child: ListTile(
                                                    //               leading:
                                                    //                   SizedBox(
                                                    //                 height: MediaQuery.of(context)
                                                    //                         .size
                                                    //                         .width /
                                                    //                     7,
                                                    //                 width: MediaQuery.of(context)
                                                    //                         .size
                                                    //                         .width /
                                                    //                     7,
                                                    //                 child:
                                                    //                     CachedNetworkImage(
                                                    //                   imageUrl:
                                                    //                       a['image'],
                                                    //                   imageBuilder:
                                                    //                       (context,
                                                    //                           imageProvider) {
                                                    //                     return Container(
                                                    //                       height:
                                                    //                           MediaQuery.of(context).size.width / 7,
                                                    //                       width:
                                                    //                           MediaQuery.of(context).size.width / 7,
                                                    //                       decoration: BoxDecoration(
                                                    //                           borderRadius: BorderRadius.circular(8),
                                                    //                           image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                    //                     );
                                                    //                   },
                                                    //                 ),
                                                    //               ),
                                                    //               title: Text(
                                                    //                 a['name'],
                                                    //                 maxLines: 2,
                                                    //                 textScaleFactor:
                                                    //                     1.0,
                                                    //                 style: TextStyle(
                                                    //                     fontSize:
                                                    //                         SizeConfig.safeBlockHorizontal *
                                                    //                             3.5,
                                                    //                     color: Color(
                                                    //                         0xffe8e8e8)),
                                                    //               ),
                                                    //               subtitle:
                                                    //                   Column(
                                                    //                 crossAxisAlignment:
                                                    //                     CrossAxisAlignment
                                                    //                         .start,
                                                    //                 mainAxisSize:
                                                    //                     MainAxisSize
                                                    //                         .min,
                                                    //                 children: [
                                                    //                   Text(
                                                    //                     '${a['podcast_name']}',
                                                    //                     style: TextStyle(
                                                    //                         color:
                                                    //                             Color(0xff777777)),
                                                    //                   )
                                                    //                 ],
                                                    //               ),
                                                    //             )),
                                                    //       )
                                                    //   ],
                                                    // ),
                                                    child: GridView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 2,
                                                              mainAxisSpacing:
                                                                  10,
                                                              crossAxisSpacing:
                                                                  10,
                                                              childAspectRatio:
                                                                  1 / 2.6),
                                                      children: [
                                                        for (var a in v['data'])
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.8,
                                                              decoration: BoxDecoration(
                                                                  color: Color(
                                                                      0xff222222),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10)),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(15),
                                                                child: Row(
                                                                  children: [
                                                                    CachedNetworkImage(
                                                                      imageUrl:
                                                                          a['image'],
                                                                      imageBuilder:
                                                                          (context,
                                                                              imageProvider) {
                                                                        return Container(
                                                                          height:
                                                                              MediaQuery.of(context).size.width / 5.5,
                                                                          width:
                                                                              MediaQuery.of(context).size.width / 5.5,
                                                                          decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(8),
                                                                              image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                        );
                                                                      },
                                                                    ),
                                                                    Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              15),
                                                                      child:
                                                                          SizedBox(
                                                                        width:
                                                                            MediaQuery.of(context).size.width /
                                                                                2,
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(bottom: 5),
                                                                              child: Text(
                                                                                a['name'].toString(),
                                                                                overflow: TextOverflow.clip,
                                                                                maxLines: 2,
                                                                                textScaleFactor: 1.0,
                                                                                style: TextStyle(color: Color(0xffe8e8e8), fontWeight: FontWeight.w700, fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              a['podcast_name'].toString(),
                                                                              textScaleFactor: 1.0,
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: TextStyle(color: Color(0xff777777), fontSize: SizeConfig.safeBlockHorizontal * 2.8),
                                                                            ),
                                                                            FutureBuilder(future: dursaver.percentageDone(a['id']),builder: (context, snapshot){
                                                                              if(snapshot.data.toString() == 'null'){
                                                                                return Container();
                                                                              }else{
                                                                                // return Text(double.parse(snapshot.data.toString()).toStringAsFixed(2).toString());
                                                                                return Stack(children: [
                                                                                  Container(color: Colors.blue,width: MediaQuery.of(context).size.width /
                                                                                      2*double.parse(double.parse(snapshot.data.toString()).toStringAsFixed(2)), height: 2,),
                                                                                  Container(width: MediaQuery.of(context).size.width /
                                                                                      2, height: 2,)
                                                                                ],);
                                                                              }


                                                                            })
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
                                                            minHeight: MediaQuery.of(
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
                                                                        MaterialPageRoute(builder:
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
                                                                            BorderRadius.circular(8)),
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.38,
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        CachedNetworkImage(
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover), borderRadius: BorderRadius.circular(8)),
                                                                              width: MediaQuery.of(context).size.width * 0.38,
                                                                              height: MediaQuery.of(context).size.width * 0.38,
                                                                            );
                                                                          },
                                                                          memCacheHeight:
                                                                              (MediaQuery.of(context).size.height).floor(),
                                                                          imageUrl: a['image'] != null
                                                                              ? a['image']
                                                                              : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
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
                                                                                TextStyle(),
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
                                                                            style:
                                                                                TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 2.5, color: Color(0xffe777777)),
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
                                                            minHeight: MediaQuery.of(
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
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
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
                                                                            currentlyPlaying.stop();
                                                                            currentlyPlaying.episodeObject =
                                                                                a;
                                                                            currentlyPlaying.play();
                                                                          } else {
                                                                            Navigator.push(context,
                                                                                MaterialPageRoute(builder: (context) {
                                                                              return PodcastView(a['id']);
                                                                            }));
                                                                          }
                                                                        },
                                                                        child:
                                                                            CachedNetworkImage(
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover), borderRadius: BorderRadius.circular(8)),
                                                                              width: MediaQuery.of(context).size.width / 4,
                                                                              height: MediaQuery.of(context).size.width / 4,
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
                                                                          imageUrl: a['image'] != null
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
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        );
      },
    );
  }
}
