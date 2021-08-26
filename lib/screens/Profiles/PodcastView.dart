import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:audioplayer/audioplayer.dart';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/Share.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../PlayerState.dart';
import '../../main.dart';
import '../RouteAnimation.dart';
// import 'package:hive_flutter/hive_flutter.dart';

enum FollowState {
  follow,
  following,
}

class PodcastView extends StatefulWidget {
  static const String id = "Podcast view";

  var podcastId;

  PodcastView(this.podcastId);

  @override
  _PodcastViewState createState() => _PodcastViewState();
}

String _printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitHours = twoDigits(duration.inHours);
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  //
  String durationToShow = twoDigitHours != '00' ? (twoDigitHours + ':') : '';
  durationToShow += twoDigitMinutes != '00' ? (twoDigitMinutes + ':') : '';
  durationToShow += twoDigitSeconds;
  // return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  return durationToShow;
}

class _PodcastViewState extends State<PodcastView> {
  RegExp htmlMatch = RegExp(r'(\w+)');
  String hiveToken;

  FollowState followState;

  bool follows;

  ScrollController _controller = ScrollController();

  Dio dio = Dio();

  int maxLines;

  var episodeList = [];

  bool episodeListLoading = true;

  bool loading;

  bool isLoading = false;

  int pageNumber = 0;

  bool seeMore = false;

  get notificationPlugin => null;

  Future<void> _pullRefreshEpisodes() async {
    // getCommunityEposidesForUser();
    // await communities.getAllCommunitiesForUser();
    // await communities.getUserCreatedCommunities();
    // await communities.getAllCommunity();
    getPodcastData();
    getEpisodes();

    // await getFollowedPodcasts();
  }

  void podcastShare() async {
    await FlutterShare.share(
        title: '${podcastData['name']}',
        text:
            "Hey There, I'm listening to ${podcastData['name']} on Aureal, here's the link for you https://aureal.one/podcast/${podcastData['id']}");
  }

  void share({var episodeId, String episodeName}) async {
    await FlutterShare.share(
        title: '${podcastData['name']}',
        text:
            "Hey There, I'm listening to $episodeName from ${podcastData['name']} on Aureal, here's the link for you https://aureal.one/episode/${episodeId.toString()}");
  }

  SharedPreferences prefs;

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = widget.podcastId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  void _play(String url) {
    AudioPlayer player = AudioPlayer();
    player.play(url, isLocal: false);
  }

  var podcastData;

  String creator = '';

  void getEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/episode?podcast_id=${widget.podcastId}&user_id=${prefs.getString('userId')}&page=$pageNumber';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          if (pageNumber == 0) {
            episodeList = jsonDecode(response.body)['episodes'];
            pageNumber = pageNumber + 1;
            episodeListLoading = false;
          } else {
            episodeList = episodeList + jsonDecode(response.body)['episodes'];
            episodeListLoading = false;
            pageNumber = pageNumber + 1;
          }
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getPodcastData() async {
    setState(() {
      isLoading = true;
    });
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/podcast?podcast_id=${widget.podcastId}&user_id=${prefs.getString('userId')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(jsonDecode(response.body));
      if (response.statusCode == 200) {
        // episodeList = jsonDecode(response.body)['podcasts'][0]['Episodes'];

        setState(() {
          podcastData = jsonDecode(response.body)['podcast'];
          follows = jsonDecode(response.body)['podcast']['ifFollows'];
        });

        if (follows == true) {
          followState = FollowState.following;
        } else {
          followState = FollowState.follow;
        }

        print(podcastData);
        for (var v in episodeList) {
          v['isLoading'] = false;
        }

        setState(() {
          hiveToken = prefs.getString('access_token');
          creator = jsonDecode(response.body)['podcast']['user_id'];
          print(hiveToken);
          getColor(jsonDecode(response.body)['podcast']['image']);
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

  //Isolate port

  ReceivePort _port = ReceivePort();

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  var dominantColor;

  int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
    r = (r < 0) ? -r : r;
    g = (g < 0) ? -g : g;
    b = (b < 0) ? -b : b;
    opacity = (opacity < 0) ? -opacity : opacity;
    opacity = (opacity > 1) ? 255 : opacity * 255;
    r = (r > 255) ? 255 : r;
    g = (g > 255) ? 255 : g;
    b = (b > 255) ? 255 : b;
    int a = opacity.toInt();
    return int.parse(
        '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}');
  }

  void getColor(String url) async {
    getColorFromUrl(url).then((value) {
      setState(() {
        dominantColor = hexOfRGBA(value[0], value[1], value[2]);
        print(dominantColor.toString());

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Color(dominantColor),
        ));
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
//    setEpisodes();

    getPodcastData();
    getEpisodes();
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState(() {});
    });

    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        getEpisodes();
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final currentlyPlaying = Provider.of<PlayerChange>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
      body: CustomScrollView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverPersistentHeader(
            delegate: _AnimationHeader(
                podcastData: podcastData,
                dominantColor: dominantColor,
                followState: followState,
                follows: follows),
            pinned: true,
          ),
          ////////////////////////////////

          // SliverAppBar(
          //   centerTitle: true,
          //   pinned: true,
          //   floating: true,
          //   //   backgroundColor: kPrimaryColor,
          //   expandedHeight: MediaQuery.of(context).size.height / 3.5,
          //   flexibleSpace: FlexibleSpaceBar(
          //     background: Container(
          //       decoration: BoxDecoration(
          //           gradient: LinearGradient(colors: [
          //         Color(dominantColor == null ? 0xff3a3a3a : dominantColor),
          //         Colors.transparent
          //       ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          //       child: podcastData == null
          //           ? Padding(
          //               padding: const EdgeInsets.symmetric(horizontal: 10),
          //               child: Shimmer.fromColors(
          //                 baseColor: themeProvider.isLightTheme == false
          //                     ? kPrimaryColor
          //                     : Colors.white,
          //                 highlightColor: themeProvider.isLightTheme == false
          //                     ? Color(0xff3a3a3a)
          //                     : Colors.white,
          //                 child: Container(
          //                   child: Row(
          //                     crossAxisAlignment: CrossAxisAlignment.end,
          //                     mainAxisAlignment: MainAxisAlignment.start,
          //                     children: <Widget>[
          //                       Container(
          //                         color: kSecondaryColor,
          //                         width:
          //                             MediaQuery.of(context).size.width / 2.5,
          //                         height:
          //                             MediaQuery.of(context).size.width / 2.5,
          //                       ),
          //                       SizedBox(
          //                         width: 10,
          //                       ),
          //                       Expanded(
          //                         // width: MediaQuery.of(context).size.width / 2,
          //                         child: Column(
          //                           mainAxisAlignment: MainAxisAlignment.end,
          //                           crossAxisAlignment:
          //                               CrossAxisAlignment.start,
          //                           children: [
          //                             Column(
          //                               crossAxisAlignment:
          //                                   CrossAxisAlignment.start,
          //                               children: [
          //                                 Padding(
          //                                   padding:
          //                                       const EdgeInsets.all(8.0),
          //                                   child: Container(
          //                                     width: double.infinity,
          //                                     height: 20,
          //                                     color: kSecondaryColor,
          //                                   ),
          //                                 ),
          //                                 Padding(
          //                                   padding:
          //                                       const EdgeInsets.all(8.0),
          //                                   child: Container(
          //                                     width: double.infinity,
          //                                     height: 20,
          //                                     color: kSecondaryColor,
          //                                   ),
          //                                 ),
          //                                 Padding(
          //                                   padding: const EdgeInsets.only(
          //                                       left: 8.0,
          //                                       right: 8.0,
          //                                       top: 8.0),
          //                                   child: Container(
          //                                     width: double.infinity,
          //                                     height: 20,
          //                                     color: kSecondaryColor,
          //                                   ),
          //                                 ),
          //                               ],
          //                             ),
          //                           ],
          //                         ),
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ),
          //             )
          //           : Padding(
          //               padding: const EdgeInsets.symmetric(horizontal: 10),
          //               child: Container(
          //                 child: Row(
          //                   crossAxisAlignment: CrossAxisAlignment.end,
          //                   mainAxisAlignment: MainAxisAlignment.start,
          //                   children: <Widget>[
          //                     Padding(
          //                       padding: const EdgeInsets.all(8.0),
          //                       child: Hero(
          //                         tag: '${podcastData['id']}',
          //                         child: Container(
          //                           width:
          //                               MediaQuery.of(context).size.width / 2.5,
          //                           height:
          //                               MediaQuery.of(context).size.width / 2.5,
          //                           child: Padding(
          //                             padding: const EdgeInsets.all(8.0),
          //                             child: CachedNetworkImage(
          //                               imageBuilder: (context, imageProvider) {
          //                                 return Container(
          //                                   decoration: BoxDecoration(
          //                                     borderRadius:
          //                                         BorderRadius.circular(10),
          //                                     image: DecorationImage(
          //                                         image: imageProvider,
          //                                         fit: BoxFit.cover),
          //                                   ),
          //                                 );
          //                               },
          //                               memCacheHeight:
          //                                   (MediaQuery.of(context).size.height)
          //                                       .floor(),
          //                               placeholder: (context, url) => Container(
          //                                 width:
          //                                     MediaQuery.of(context).size.width /
          //                                         2.5,
          //                                 height:
          //                                     MediaQuery.of(context).size.width /
          //                                         2.5,
          //                                 child: Image.asset(
          //                                     'assets/images/Thumbnail.png'),
          //                               ),
          //                               imageUrl: podcastData == null
          //                                   ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
          //                                   : podcastData['image'],
          //                               fit: BoxFit.cover,
          //                             ),
          //                           ),
          //                         ),
          //                       ),
          //                     ),
          //                     SizedBox(
          //                       width: 10,
          //                     ),
          //                     Expanded(
          //                       // width: MediaQuery.of(context).size.width / 2,
          //                       child: Column(
          //                         mainAxisAlignment: MainAxisAlignment.end,
          //                         crossAxisAlignment:
          //                             CrossAxisAlignment.start,
          //                         children: [
          //                           Column(
          //                             mainAxisAlignment:
          //                                 MainAxisAlignment.start,
          //                             crossAxisAlignment:
          //                                 CrossAxisAlignment.start,
          //                             children: [
          //                               Text(
          //                                 podcastData['name'],
          //                                 textScaleFactor: mediaQueryData
          //                                     .textScaleFactor
          //                                     .clamp(0.5, 1)
          //                                     .toDouble(),
          //                                 style: TextStyle(
          //                                     //    color: Color(0xffe8e8e8),
          //                                     fontWeight: FontWeight.w500,
          //                                     fontSize: SizeConfig
          //                                             .safeBlockHorizontal *
          //                                         5),
          //                               ),
          //                               Text(
          //                                 podcastData['author'],
          //                                 maxLines: 2,
          //                                 overflow: TextOverflow.ellipsis,
          //                                 textScaleFactor: mediaQueryData
          //                                     .textScaleFactor
          //                                     .clamp(0.5, 1)
          //                                     .toDouble(),
          //                                 style: TextStyle(
          //                                     //   color: Color(0xffe8e8e8),
          //                                     fontWeight: FontWeight.w400,
          //                                     fontSize: SizeConfig
          //                                             .safeBlockHorizontal *
          //                                         4),
          //                               ),
          //                             ],
          //                           ),
          //                           Row(
          //                             mainAxisAlignment:
          //                                 MainAxisAlignment.start,
          //                             crossAxisAlignment:
          //                                 CrossAxisAlignment.center,
          //                             children: <Widget>[
          //                               followState == FollowState.following
          //                                   ? InkWell(
          //                                       onTap: () {
          //                                         follow();
          //                                         setState(() {
          //                                           if (followState ==
          //                                               FollowState.follow) {
          //                                             followState =
          //                                                 FollowState
          //                                                     .following;
          //                                           } else {
          //                                             followState =
          //                                                 FollowState.follow;
          //                                           }
          //                                         });
          //                                       },
          //                                       child: Container(
          //                                         decoration: BoxDecoration(
          //                                             borderRadius:
          //                                                 BorderRadius
          //                                                     .circular(20),
          //                                             border: Border.all(
          //                                                 color:
          //                                                     kSecondaryColor
          //                                                 //    color: Color(0xffe8e8e8),
          //                                                 ,
          //                                                 width: 0.5)),
          //                                         child: Padding(
          //                                           padding: const EdgeInsets
          //                                                   .symmetric(
          //                                               horizontal: 20,
          //                                               vertical: 5),
          //                                           child: Text(
          //                                             'Unsubscribe',
          //                                             textScaleFactor:
          //                                                 mediaQueryData
          //                                                     .textScaleFactor
          //                                                     .clamp(0.5, 1)
          //                                                     .toDouble(),
          //                                             style: TextStyle(
          //                                                 //      color: Color(0xffe8e8e8)
          //                                                 ),
          //                                           ),
          //                                         ),
          //                                       ))
          //                                   : InkWell(
          //                                       onTap: () async {
          //                                         follow();
          //                                         setState(() {
          //                                           if (followState ==
          //                                               FollowState.follow) {
          //                                             followState =
          //                                                 FollowState
          //                                                     .following;
          //                                           } else {
          //                                             followState =
          //                                                 FollowState.follow;
          //                                           }
          //                                         });
          //                                       },
          //                                       child: Container(
          //                                         decoration: BoxDecoration(
          //                                             borderRadius:
          //                                                 BorderRadius
          //                                                     .circular(20),
          //                                             border: Border.all(
          //                                                 color:
          //                                                     kSecondaryColor,
          //                                                 //    color: Color(0xffe8e8e8),
          //                                                 width: 0.5)
          //                                             //color: Color(0xffe8e8e8)
          //                                             ),
          //                                         child: Padding(
          //                                           padding: const EdgeInsets
          //                                                   .symmetric(
          //                                               horizontal: 20,
          //                                               vertical: 5),
          //                                           child: Text(
          //                                             'Subscribe',
          //                                             textScaleFactor:
          //                                                 mediaQueryData
          //                                                     .textScaleFactor
          //                                                     .clamp(0.5, 1)
          //                                                     .toDouble(),
          //                                             style: TextStyle(
          //                                                 // color: Color(0xff3a3a3a)
          //                                                 ),
          //                                           ),
          //                                         ),
          //                                       ),
          //                                     ),
          //                               SizedBox(height: 15),
          //                               GestureDetector(
          //                                 onTap: podcastShare,
          //                                 child: Column(
          //                                   children: <Widget>[
          //                                     IconButton(
          //                                       onPressed: () {
          //                                         podcastShare();
          //                                       },
          //                                       icon: Icon(
          //                                         FontAwesomeIcons.shareAlt,
          //                                         //    color: Colors.grey,
          //                                         size: 18,
          //                                       ),
          //                                     ),
          //                                   ],
          //                                 ),
          //                               )
          //                             ],
          //                           ),
          //                         ],
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //     ),
          //   ),
          // ),
          SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
            if (index == 0) {
              return Padding(
                  padding: const EdgeInsets.fromLTRB(15, 30, 15, 15),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        podcastData == null
                            ? SizedBox()
                            : htmlMatch.hasMatch(podcastData['description']) ==
                                    true
                                ? Text(
                                    '${(parse(podcastData['description']).body.text)}',
                                    maxLines: seeMore == true ? 30 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    textScaleFactor: mediaQueryData
                                        .textScaleFactor
                                        .clamp(0.5, 1.5)
                                        .toDouble(),
                                    style: TextStyle(
                                        //      color: Colors.grey,
                                        fontSize:
                                            SizeConfig.blockSizeHorizontal * 3),
                                  )
                                : Text(
                                    podcastData['description'],
                                    maxLines: seeMore == true ? 30 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    textScaleFactor: mediaQueryData
                                        .textScaleFactor
                                        .clamp(0.5, 1)
                                        .toDouble(),
                                    style: TextStyle(
                                        //  color: Colors.grey,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              seeMore = !seeMore;
                            });
                          },
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(colors: [
                                Color(0xffE73B57),
                                Color(0xff6048F6)
                              ]).createShader(bounds);
                            },
                            child: Text(
                              seeMore == false ? "See more" : "See less",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Divider(
                          color: kSecondaryColor,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Column(children: [
                          Row(
                            children: [
                              Text('Episodes',
                                  textScaleFactor: mediaQueryData
                                      .textScaleFactor
                                      .clamp(0.5, 1.5)
                                      .toDouble(),
                                  style: TextStyle(
                                      //     color: Color(0xffe8e8e8),
                                      fontWeight: FontWeight.w500,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 5)),
                            ],
                          ),
                        ])
                      ]));

            } else {
              if (index == episodeList.length + 1) {
                return isLoading == false
                    ? (_controller.position.pixels !=
                            _controller.position.maxScrollExtent
                        ?  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                    child: Shimmer.fromColors(
                      baseColor: themeProvider.isLightTheme == false
                          ? kPrimaryColor
                          : Colors.white,
                      highlightColor:
                      themeProvider.isLightTheme == false
                          ? Color(0xff3a3a3a)
                          : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(10),
                          border: Border.all(color: kSecondaryColor,),

                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                      width:
                                      SizeConfig.screenWidth / 28),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        color: kSecondaryColor,
                                        height: 10,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width /
                                            2,
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        color: kSecondaryColor,
                                        height: 10,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width /
                                            4,
                                      )
                                    ],
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: kSecondaryColor,
                                      ),
                                      height: 25,
                                      width:
                                      MediaQuery.of(context).size.width/8,
                                      //    color: kSecondaryColor,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: kSecondaryColor,
                                      ),
                                      height: 25,
                                      width:
                                      MediaQuery.of(context).size.width/8,
                                      //    color: kSecondaryColor,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: kSecondaryColor,
                                      ),
                                      height: 25,
                                      width:
                                      MediaQuery.of(context).size.width/8,
                                      //    color: kSecondaryColor,
                                    ),
                                  ),
                                ],
                              )
                              // Column(
                              //   mainAxisAlignment:
                              //   MainAxisAlignment.start,
                              //   children: [
                              //     Padding(
                              //       padding: const EdgeInsets.symmetric(
                              //           horizontal: 15, vertical: 5),
                              //       child: Container(
                              //         height: 5,
                              //         width: MediaQuery.of(context)
                              //             .size
                              //             .width,
                              //         color: kSecondaryColor,
                              //       ),
                              //     ),
                              //     Padding(
                              //       padding: const EdgeInsets.symmetric(
                              //           horizontal: 15, vertical: 5),
                              //       child: Container(
                              //         height: 5,
                              //         width: MediaQuery.of(context)
                              //             .size
                              //             .width,
                              //         color: kSecondaryColor,
                              //       ),
                              //     ),
                              //   ],
                              // )
                            ],
                          ),
                        ),
                      ),
                    ))
                        : Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                    child: Shimmer.fromColors(
                      baseColor: themeProvider.isLightTheme == false
                          ? kPrimaryColor
                          : Colors.white,
                      highlightColor:
                      themeProvider.isLightTheme == false
                          ? Color(0xff3a3a3a)
                          : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(10),
                          border: Border.all(color: kSecondaryColor,),

                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                      width:
                                      SizeConfig.screenWidth / 28),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        color: kSecondaryColor,
                                        height: 10,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width /
                                            2,
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        color: kSecondaryColor,
                                        height: 10,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width /
                                            4,
                                      )
                                    ],
                                  )
                                ],
                              ),
                             Row(
                                 children: [
                                   Padding(
                                     padding: const EdgeInsets.all(15),
                                     child: Container(
                                       decoration: BoxDecoration(
                                         borderRadius: BorderRadius.circular(10),
                                         color: kSecondaryColor,
                                       ),
                                       height: 25,
                                       width:
                                       MediaQuery.of(context).size.width/8,
                                       //    color: kSecondaryColor,
                                     ),
                                   ),
                                   Padding(
                                     padding: const EdgeInsets.all(15),
                                     child: Container(
                                       decoration: BoxDecoration(
                                         borderRadius: BorderRadius.circular(10),
                                         color: kSecondaryColor,
                                       ),
                                       height: 25,
                                       width:
                                       MediaQuery.of(context).size.width/8,
                                       //    color: kSecondaryColor,
                                     ),
                                   ),
                                   Padding(
                                     padding: const EdgeInsets.all(15),
                                     child: Container(
                                       decoration: BoxDecoration(
                                         borderRadius: BorderRadius.circular(10),
                                         color: kSecondaryColor,
                                       ),
                                       height: 25,
                                       width:
                                       MediaQuery.of(context).size.width/8,
                                       //    color: kSecondaryColor,
                                     ),
                                   ),
                                 ],
                             )
                              // Column(
                              //   mainAxisAlignment:
                              //   MainAxisAlignment.start,
                              //   children: [
                              //     Padding(
                              //       padding: const EdgeInsets.symmetric(
                              //           horizontal: 15, vertical: 5),
                              //       child: Container(
                              //         height: 5,
                              //         width: MediaQuery.of(context)
                              //             .size
                              //             .width,
                              //         color: kSecondaryColor,
                              //       ),
                              //     ),
                              //     Padding(
                              //       padding: const EdgeInsets.symmetric(
                              //           horizontal: 15, vertical: 5),
                              //       child: Container(
                              //         height: 5,
                              //         width: MediaQuery.of(context)
                              //             .size
                              //             .width,
                              //         color: kSecondaryColor,
                              //       ),
                              //     ),
                              //   ],
                              // )
                            ],
                          ),
                        ),
                      ),
                    )))
                    :SizedBox();
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          new BoxShadow(
                            color: Colors.black54.withOpacity(0.2),
                            blurRadius: 10.0,
                          ),
                        ],
                        color: themeProvider.isLightTheme == true
                            ? Colors.white
                            : Color(0xff222222),
                      ),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,

                          onTap: () {
                            Navigator.push(
                                context,
                                SlideRightRoute(
                                    widget: EpisodeView(
                                        episodeId: episodeList[index - 1]
                                            ['id'])));
                          },
                          //
                          title: Text(
                            episodeList[index - 1]['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textScaleFactor: mediaQueryData.textScaleFactor
                                .clamp(0.5, 1.5)
                                .toDouble(),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                //       color: Colors.white,
                                fontSize: SizeConfig.safeBlockHorizontal * 4),
                          ),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                episodeList[index - 1]['summary'] == null
                                    ? SizedBox(
                                        height: 20,
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: htmlMatch.hasMatch(
                                                    episodeList[index - 1]
                                                        ['summary']) ==
                                                true
                                            ? Text(
                                                '${(parse(episodeList[index - 1]['summary']).body.text)}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textScaleFactor: mediaQueryData
                                                    .textScaleFactor
                                                    .clamp(0.5, 1)
                                                    .toDouble(),
                                                style: TextStyle(
                                                    //       color: Colors.grey,
                                                    fontSize: SizeConfig
                                                            .blockSizeHorizontal *
                                                        3.5),
                                              )
                                            : Text(
                                                episodeList[index - 1]
                                                    ['summary'],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textScaleFactor: mediaQueryData
                                                    .textScaleFactor
                                                    .clamp(0.5, 1)
                                                    .toDouble(),
                                                style: TextStyle(
                                                    //         color: Colors.grey,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3.5),
                                              ),
                                      ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Row(children: [
                                          episodeList[index - 1]['permlink'] ==
                                                      null ||
                                                  episodeList[index - 1]
                                                          ['votes'] ==
                                                      null
                                              ? (creator ==
                                                      prefs.getString('userId')
                                                  ? GestureDetector(
                                                      onTap: () async {
                                                        await publishManually(
                                                            episodeList[index -
                                                                1]['id']);
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(right: 5),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            border:
                                                                Border.all(),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        5),
                                                            child: Text(
                                                              "Publish",
                                                              textScaleFactor:
                                                                  mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.5,
                                                                          1)
                                                                      .toDouble(),
                                                              style:
                                                                  TextStyle(),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : SizedBox(
                                                      width: 0,
                                                    ))
                                              : InkWell(
                                                  onTap: () async {
                                                    if (prefs.getString(
                                                            'HiveUserName') !=
                                                        null) {
                                                      setState(() {
                                                        episodeList[index - 1]
                                                                ['isLoading'] =
                                                            true;
                                                      });
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return Dialog(
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                child: UpvoteEpisode(
                                                                    permlink: episodeList[
                                                                            index -
                                                                                1]
                                                                        [
                                                                        'permlink'],
                                                                    episode_id:
                                                                        episodeList[index -
                                                                                1]
                                                                            [
                                                                            'id']));
                                                          }).then((value) async {
                                                        print(value);
                                                      });
                                                      // await upvoteEpisode(
                                                      //     permlink: episodeList[
                                                      //             index - 1]
                                                      //         ['permlink'],
                                                      //     episode_id: episodeList[
                                                      //         index - 1]['id']);
                                                      setState(() {
                                                        episodeList[index - 1]
                                                                ['ifVoted'] =
                                                            !episodeList[index -
                                                                1]['ifVoted'];
                                                        episodeList[index - 1]
                                                                ['isLoading'] =
                                                            false;
                                                      });
                                                    } else {
                                                      showBarModalBottomSheet(
                                                          context: context,
                                                          builder: (context) {
                                                            return HiveDetails();
                                                          });
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5),
                                                    child: Container(
                                                      decoration: episodeList[index - 1]
                                                                  ['ifVoted'] ==
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
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.0),
                                                        child: Row(
                                                          children: [
                                                            episodeList[index -
                                                                            1][
                                                                        'isLoading'] ==
                                                                    true
                                                                ? Container(
                                                                    height: 18,
                                                                    width: 18,
                                                                    child:
                                                                        SpinKitPulse(
                                                                      color: Colors
                                                                          .blue,
                                                                    ),
                                                                  )
                                                                : Icon(
                                                                    FontAwesomeIcons
                                                                        .chevronCircleUp,
                                                                    size: 15,
                                                                  ),
                                                            Padding(
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      8),
                                                              child: Text(
                                                                '${episodeList[index - 1]['votes']}',
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
                                                                style: TextStyle(
                                                                    //        color: Color(
                                                                    // 0xffe8e8e8)
                                                                    ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      right: 4),
                                                              child: Text(
                                                                '\$${episodeList[index - 1]['payout_value'].toString().split(' ')[0]}',
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                          episodeList[index - 1]['permlink'] ==
                                                      null ||
                                                  episodeList[index - 1]
                                                          ['votes'] ==
                                                      null
                                              ? SizedBox(
                                                  width: 0,
                                                )
                                              : InkWell(
                                                  onTap: () {
                                                    if (prefs.getString(
                                                            'HiveUserName') !=
                                                        null) {
                                                      Navigator.push(
                                                          context,
                                                          SlideRightRoute(
                                                              widget: Comments(
                                                            episodeObject:
                                                                episodeList[
                                                                    index - 1],
                                                          )));
                                                    } else {
                                                      showBarModalBottomSheet(
                                                          context: context,
                                                          builder: (context) {
                                                            return HiveDetails();
                                                          });
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5),
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
                                                                .all(5.0),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .mode_comment_outlined,
                                                              size: 15,
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      8),
                                                              child: Text(
                                                                episodeList[index -
                                                                            1][
                                                                        'comments_count']
                                                                    .toString(),
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
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
                                          InkWell(
                                            onTap: () {
                                              print(episodeList[index - 1]
                                                      ['url']
                                                  .toString()
                                                  .contains('.mp4'));
                                              if (episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.mp4') ==
                                                      true ||
                                                  episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.m4v') ==
                                                      true ||
                                                  episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.flv') ==
                                                      true ||
                                                  episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.f4v') ==
                                                      true ||
                                                  episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.ogv') ==
                                                      true ||
                                                  episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.ogx') ==
                                                      true ||
                                                  episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.wmv') ==
                                                      true ||
                                                  episodeList[index - 1]['url']
                                                          .toString()
                                                          .contains('.webm') ==
                                                      true) {
                                                currentlyPlaying.stop();
                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (context) {
                                                  return PodcastVideoPlayer(
                                                    episodeObject:
                                                        episodeList[index - 1],
                                                  );
                                                }));
                                              } else {
                                                if (episodeList[index - 1]
                                                            ['url']
                                                        .toString()
                                                        .contains('.pdf') ==
                                                    true) {
                                                  // Navigator.push(context,
                                                  //     MaterialPageRoute(
                                                  //         builder: (context) {
                                                  //   return PDFviewer(
                                                  //     episodeObject:
                                                  //         episodeList[index - 1],
                                                  //   );
                                                  // }));
                                                } else {
                                                  currentlyPlaying.stop();

                                                  currentlyPlaying
                                                          .episodeObject =
                                                      episodeList[index - 1];
                                                  currentlyPlaying.playList =
                                                      episodeList;
                                                  print(currentlyPlaying
                                                      .playList);
                                                  print(currentlyPlaying
                                                      .episodeObject
                                                      .toString());
                                                  currentlyPlaying.play();
                                                  // _pullRefreshEpisodes();
                                                  showBarModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return Container(
                                                          child: Player(),
                                                        );
                                                      });
                                                }
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: kSecondaryColor),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.play_circle_outline,
                                                      size: 15,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 8),
                                                      child: Text(
                                                        '${DurationCalculator(episodeList[index - 1]['duration']) == "Some Issue" ? '' : DurationCalculator(episodeList[index - 1]['duration'])}',
                                                        textScaleFactor:
                                                            mediaQueryData
                                                                .textScaleFactor
                                                                .clamp(0.5, 1)
                                                                .toDouble(),
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
                                        ]),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        episodeList[index - 1]['permlink'] ==
                                                    null ||
                                                episodeList[index - 1]
                                                        ['votes'] ==
                                                    null
                                            ? SizedBox(
                                                width: 0,
                                                height: 0,
                                              )
                                            : (creator ==
                                                    prefs.getString('userId')
                                                ? IconButton(
                                                    icon: Icon(Icons.more_vert),
                                                    onPressed: () {
                                                      showBarModalBottomSheet(
                                                          context: context,
                                                          builder: (context) {
                                                            // return Container(
                                                            //   child:
                                                            //   AddToCommunity(
                                                            //     episodeObject:
                                                            //     episodeList[
                                                            //     index -
                                                            //         1],
                                                            //   ),
                                                            //   // color:
                                                            //   //     kSecondaryColor,
                                                            // );
                                                          });
                                                    },
                                                  )
                                                : SizedBox(
                                                    width: 0,
                                                    height: 0,
                                                  )),

                                        // IconButton(
                                        //   onPressed: () async {
                                        //     final status = await Permission.storage.request();
                                        //
                                        //     if (status.isGranted) {
                                        //       final externalDir = await getExternalStorageDirectory();
                                        //
                                        //       final id = await FlutterDownloader.enqueue(
                                        //         url:
                                        //         "https://firebasestorage.googleapis.com/v0/b/storage-3cff8.appspot.com/o/2020-05-29%2007-18-34.mp4?alt=media&token=841fffde-2b83-430c-87c3-2d2fd658fd41",
                                        //
                                        //
                                        //         savedDir: externalDir.path,
                                        //         fileName: "download",
                                        //         showNotification: true,
                                        //         openFileFromNotification: true,
                                        //       );
                                        //
                                        //
                                        //     } else {
                                        //       print("Permission deined");
                                        //     }
                                        //   },
                                        //   icon: Icon(
                                        //       Icons.arrow_circle_down_outlined),
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                              ]),
                        ),
                      ),
                    ),
                    Builder(builder: (context) {
                      if (Provider.of<PlayerChange>(context).episodeObject !=
                          null) {
                        return episodeList[index - 1]['id'] ==
                                    currentlyPlaying.episodeObject['id'] &&
                                currentlyPlaying.episodeObject['id'] != null
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 7),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(colors: [
                                        Color(0xff5d5da8),
                                        Color(0xff5bc3ef)
                                      ])),
                                  width: double.infinity,
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
              );
            }
          }, childCount: episodeList.length + 2)),
        ],
      ),
      bottomSheet: BottomPlayer(),
    );
  }
}

class _AnimationHeader extends SliverPersistentHeaderDelegate {
  var podcastData;
  int dominantColor;

  _AnimationHeader(
      {this.podcastData,
      @required this.dominantColor,
      @required this.dio,
      @required this.followState,
      @required this.follows});

  RegExp htmlMatch = RegExp(r'(\w+)');
  Dio dio = Dio();
  FollowState followState;
  bool follows;

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = podcastData;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  double _maxExtent = 320;
  double _minExtent = 150;
  double _maxImageSize = 180;
  double _minImageSize = 80;
  double _maxTitleSize = 20;
  double _maxSubTitleSize = 12;
  double _minTitleSize = 15;
  double _minSubTitleSize = 10;
  double _maxFollowButton = 0;

  void setExtentValue(BuildContext context) {
    _maxExtent = MediaQuery.of(context).size.height * 0.33;
    _minExtent = MediaQuery.of(context).size.height / 5.5;
    _maxImageSize = MediaQuery.of(context).size.width * 0.42;
    _minImageSize = (MediaQuery.of(context).size.width * 0.42) / 2;
    _maxTitleSize = ((MediaQuery.of(context).size.width * 0.35) / 2) / 4;
    _maxFollowButton = MediaQuery.of(context).size.width * 0.2;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // print(shrinkOffset);
    setExtentValue(context);
    print(shrinkOffset);

    double percent = shrinkOffset / _maxExtent;
    double currentImageSize =
        (_maxImageSize * (1 - percent)).clamp(_minImageSize, _maxImageSize);
    double SubSize = (_maxSubTitleSize * (1 - percent)).clamp(
      _minSubTitleSize,
      _maxSubTitleSize,
    );
    double TitleSize = (_maxTitleSize * (1 - percent)).clamp(
      _minTitleSize,
      _maxTitleSize,
    );

    final buttonMargin = 320;
    final followButton = 200;
    final maxMargin = 200;
    final textMovement = 150;
    final marginFollow = 500;
    final buttonMargin1 = buttonMargin + (marginFollow * percent);
    final buttonFollowMargin = followButton + (marginFollow * percent);
    final leftTextMargin = maxMargin + (textMovement * percent);
    final mediaQueryData = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        Color(dominantColor == null ? 0xff3a3a3a : dominantColor),
        kPrimaryColor
      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: podcastData == null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Shimmer.fromColors(
                baseColor: themeProvider.isLightTheme == false
                    ? kPrimaryColor
                    : Colors.white,
                highlightColor: themeProvider.isLightTheme == false
                    ? Color(0xff3a3a3a)
                    : Colors.white,
                child: Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        color: kSecondaryColor,
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: MediaQuery.of(context).size.width / 2.5,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        // width: MediaQuery.of(context).size.width / 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: kSecondaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: kSecondaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8.0, top: 8.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: kSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                SafeArea(
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      currentImageSize != _maxImageSize
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 80),
                              child: IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    Icons.arrow_back,
                                  )),
                            )
                          : SizedBox(),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: CachedNetworkImage(
                          imageUrl: podcastData['image'],
                          memCacheHeight:
                              (MediaQuery.of(context).size.height / 2).ceil(),
                          imageBuilder: (context, imageProvider) {
                            return Container(
                              width: currentImageSize,
                              height: currentImageSize,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                      image: imageProvider, fit: BoxFit.cover)),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${podcastData['name']}",
                                style: TextStyle(fontSize: TitleSize),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height / 100,
                              ),
                              Text(
                                "${podcastData['author']}",
                                style: TextStyle(
                                    fontSize: SubSize,
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 40,
                              ),
                              currentImageSize != _maxImageSize
                                  ? SizedBox()
                                  : FollowButton(
                                      podcastData: podcastData,
                                      follows: follows,
                                      followState: followState,
                                    ),
                            ]),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class FollowButton extends StatefulWidget {
  FollowState followState;
  bool follows;
  var podcastData;

  FollowButton(
      {@required this.podcastData,
      @required this.follows,
      @required this.followState});

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  FollowState followState;
  bool follows;

  Dio dio = Dio();

  void podcastShare() async {
    await FlutterShare.share(
        title: '${widget.podcastData['name']}',
        text:
            "Hey There, I'm listening to ${widget.podcastData['name']} on Aureal, here's the link for you https://aureal.one/podcast/${widget.podcastData['id']}");
  }

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = widget.podcastData['id'];

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      followState = widget.followState;
      follows = widget.follows;
    });
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Row(
      children: [
        followState == FollowState.following
            ? InkWell(
                onTap: () {
                  follow();
                  setState(() {
                    if (followState == FollowState.follow) {
                      followState = FollowState.following;
                    } else {
                      followState = FollowState.follow;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: kSecondaryColor
                          //    color: Color(0xffe8e8e8),
                          ,
                          width: 0.5)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(
                      'Unsubscribe',
                      textScaleFactor: mediaQueryData.textScaleFactor
                          .clamp(0.5, 1)
                          .toDouble(),
                      style: TextStyle(
                          //      color: Color(0xffe8e8e8)
                          ),
                    ),
                  ),
                ))
            : InkWell(
                onTap: () async {
                  follow();
                  setState(() {
                    if (followState == FollowState.follow) {
                      followState = FollowState.following;
                    } else {
                      followState = FollowState.follow;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: kSecondaryColor,
                          //    color: Color(0xffe8e8e8),
                          width: 0.5)
                      //color: Color(0xffe8e8e8)
                      ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(
                      'Subscribe',
                      textScaleFactor: mediaQueryData.textScaleFactor
                          .clamp(0.5, 1)
                          .toDouble(),
                      style: TextStyle(
                          // color: Color(0xff3a3a3a)
                          ),
                    ),
                  ),
                ),
              ),
        GestureDetector(
          onTap:  podcastShare,
          child: Column(
            children: <Widget>[
              IconButton(
                onPressed: () {
                  podcastShare();
                },
                icon: Icon(
                  FontAwesomeIcons.shareAlt,
                  //    color: Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
// class AddToCommunity extends StatefulWidget {
//   var episodeObject;
//
//   AddToCommunity({@required this.episodeObject});
//
//   @override
//   _AddToCommunityState createState() => _AddToCommunityState();
// }
//
// class _AddToCommunityState extends State<AddToCommunity> {
//   List<String> added = [];
//   String currentText = "";
//
//   List alreadyAddedCommunities = [];
//
//   SimpleAutoCompleteTextField textField;
//   bool showWhichErrorText = false;
//
//   void getAddedCommunities() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         'https://api.aureal.one/public/getEpisodeCommunity?episode_id=${widget.episodeObject['id']}';
//
//     try {
//       http.Response response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         print(response.body);
//         setState(() {
//           addedCommunities = jsonDecode(response.body)['allCommunity'];
//         });
//       } else {
//         print(response.statusCode);
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   postreq.Interceptor intercept = postreq.Interceptor();
//
//   void addToCommunity(var communityId) async {
//     setState(() {
//       recommendedLoading = true;
//     });
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url = 'https://api.aureal.one/public/assignCommunityEpisode';
//     var map = Map<String, dynamic>();
//     map['user_id'] = prefs.getString('userId');
//     map['community_id'] = communityId;
//     map['episode_id'] = widget.episodeObject['id'];
//
//     FormData formData = FormData.fromMap(map);
//
//     try {
//       var response = await intercept.postRequest(formData, url);
//       print(response.toString());
//       await getAddedCommunities();
//     } catch (e) {
//       print(e);
//     }
//
//     setState(() {
//       recommendedLoading = false;
//     });
//   }
//
//   bool recommendedLoading = false;
//   bool addedLoading = false;
//
//   void removeFromCommunity(int communityId) async {
//     setState(() {
//       addedLoading = true;
//     });
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url = 'https://api.aureal.one/public/removeCommunityEpisode';
//     var map = Map<String, dynamic>();
//
//     map['user_id'] = prefs.getString('userId');
//     map['community_id'] = communityId;
//     map['episode_id'] = widget.episodeObject['id'];
//
//     FormData formData = FormData.fromMap(map);
//
//     print(map.toString());
//
//     try {
//       var response = await intercept.postRequest(formData, url);
//       print(response.toString());
//       await getAddedCommunities();
//     } catch (e) {
//       print(e);
//     }
//     setState(() {
//       addedLoading = false;
//     });
//   }
//
//   List addedCommunities = [];
//
//   List recommended = [];
//
//   TextEditingController controller;
//
//   @override
//   void initState() {
//     controller = TextEditingController();
//     // TODO: implement initState
//     getAddedCommunities();
//     super.initState();
//     print(widget.episodeObject.toString());
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var communities = Provider.of<CommunityProvider>(context);
//     final mediaQueryData = MediaQuery.of(context);
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Scaffold(
//           appBar: AppBar(
//             //   backgroundColor: Colors.transparent,
//             elevation: 0,
//             automaticallyImplyLeading: false,
//             title: Container(
//               decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   border: Border.all(color: kSecondaryColor
//                     //      color: Color(0xffe8e8e8),
//                   )),
//               width: double.infinity,
//               child: TextField(
//                 controller: controller,
//                 onChanged: (value) {
//                   for (var v in communities.allCommunities) {
//                     if (v['name'].toString().toLowerCase().contains(value) ==
//                         true) {
//                       setState(() {
//                         recommended.add(v);
//                       });
//                     }
//                   }
//                 },
//                 decoration: InputDecoration(
//                   prefixIcon: Container(
//                     decoration: BoxDecoration(
//                         image: DecorationImage(
//                             fit: BoxFit.contain,
//                             image: AssetImage('assets/images/Favicon.png'))),
//                     height: 20,
//                     width: 20,
//                   ),
//                   //   hintStyle: TextStyle(color: Color(0xffe8e8e8)),
//                   hintText: 'Search & Click on community to add directly',
//                   border: InputBorder.none,
//                 ),
//                 //   style: TextStyle(color: Color(0xffe8e8e8)),
//               ),
//             ),
//             toolbarHeight: 100,
//           ),
//           resizeToAvoidBottomInset: false,
//           body: Container(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 10, horizontal: 10),
//                       child: Text(
//                         "Recommended Communities",
//                         textScaleFactor: mediaQueryData.textScaleFactor
//                             .clamp(0.2, 1)
//                             .toDouble(),
//                         style: TextStyle(
//                           //   color: Color(0xffe8e8e8),
//                             fontSize: SizeConfig.safeBlockHorizontal * 5.5,
//                             fontWeight: FontWeight.w700),
//                       ),
//                     ),
//                     Container(
//                       decoration: BoxDecoration(
//                           border: Border(
//                               bottom: BorderSide(color: kSecondaryColor))),
//                       constraints: BoxConstraints(
//                           maxHeight: MediaQuery.of(context).size.height / 3.6),
//                       child: recommendedLoading == true
//                           ? LinearProgressIndicator(
//                         minHeight: double.infinity,
//                         //       backgroundColor: kSecondaryColor,
//                       )
//                           : ListView(
//                         scrollDirection: Axis.horizontal,
//                         children: [
//                           for (var v in controller.text == '' ||
//                               controller.text == null
//                               ? (communities.userCommunities.length == 0
//                               ? communities.allCommunities
//                               : communities.userCommunities)
//                               : recommended.toSet().toList())
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                     border: Border.all(
//                                         color: kSecondaryColor),
//                                     //     color: kSecondaryColor,
//                                     borderRadius:
//                                     BorderRadius.circular(10)),
//                                 width: MediaQuery.of(context).size.width /
//                                     1.5,
//                                 child: Column(
//                                   mainAxisAlignment:
//                                   MainAxisAlignment.center,
//                                   children: [
//                                     Container(
//                                         height: MediaQuery.of(context)
//                                             .size
//                                             .width /
//                                             5,
//                                         width: MediaQuery.of(context)
//                                             .size
//                                             .width /
//                                             5,
//                                         decoration: BoxDecoration(
//                                           //      color: Color(0xffe8e8e8),
//                                             shape: BoxShape.circle,
//                                             image: DecorationImage(
//                                                 image:
//                                                 CachedNetworkImageProvider(
//                                                   v['profileImageUrl'] == null
//                                                       ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
//                                                       : v['profileImageUrl'],
//                                                 )))),
//                                     Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Text(
//                                         '${v['name']}',
//                                         textScaleFactor: mediaQueryData
//                                             .textScaleFactor
//                                             .clamp(0.2, 1)
//                                             .toDouble(),
//                                         style: TextStyle(
//                                           //    color: Color(0xffe8e8e8),
//                                             fontSize: SizeConfig
//                                                 .safeBlockHorizontal *
//                                                 4.5),
//                                       ),
//                                     ),
//                                     Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Text(
//                                         '${v['description']}',
//                                         textScaleFactor: mediaQueryData
//                                             .textScaleFactor
//                                             .clamp(0.2, 1)
//                                             .toDouble(),
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           //       color: Color(0xffe8e8e8),
//                                             fontSize: SizeConfig
//                                                 .safeBlockHorizontal *
//                                                 3.5),
//                                       ),
//                                     ),
//                                     SizedBox(
//                                       height: 5,
//                                     ),
//                                     InkWell(
//                                       onTap: () async {
//                                         await addToCommunity(v['id']);
//                                       },
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                             borderRadius:
//                                             BorderRadius.circular(20),
//                                             border: Border.all(
//                                                 color: kSecondaryColor)
//                                           //   color: Color(0xffe8e8e8)
//                                         ),
//                                         child: Padding(
//                                           padding:
//                                           const EdgeInsets.symmetric(
//                                               horizontal: 15,
//                                               vertical: 5),
//                                           child: Row(
//                                             mainAxisAlignment:
//                                             MainAxisAlignment
//                                                 .spaceEvenly,
//                                             mainAxisSize:
//                                             MainAxisSize.min,
//                                             children: [
//                                               Icon(
//                                                 Icons.add,
//                                                 size: 20,
//                                                 //    color: kSecondaryColor,
//                                               ),
//                                               SizedBox(
//                                                 width: 10,
//                                               ),
//                                               Text(
//                                                 'Add',
//                                                 textScaleFactor:
//                                                 mediaQueryData
//                                                     .textScaleFactor
//                                                     .clamp(0.2, 1)
//                                                     .toDouble(),
//                                                 style: TextStyle(
//                                                   // colo r:
//                                                   //     kSecondaryColor,
//                                                     fontSize: SizeConfig
//                                                         .safeBlockHorizontal *
//                                                         4),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     )
//                                   ],
//                                 ),
//                               ),
//                             )
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 10, horizontal: 10),
//                       child: Text(
//                         "Selected Communities",
//                         textScaleFactor: mediaQueryData.textScaleFactor
//                             .clamp(0.2, 1)
//                             .toDouble(),
//                         style: TextStyle(
//                             fontSize: SizeConfig.safeBlockHorizontal * 5.5,
//                             fontWeight: FontWeight.w700),
//                       ),
//                     ),
//                     Container(
//                       constraints: BoxConstraints(
//                           maxHeight: MediaQuery.of(context).size.height / 4),
//                       child: addedLoading == true
//                           ? LinearProgressIndicator(
//                         minHeight: double.infinity,
//                         // backgroundColor: kSecondaryColor,
//                       )
//                           : ListView(
//                         scrollDirection: Axis.horizontal,
//                         children: [
//                           for (var v in addedCommunities)
//                             Stack(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       // color: kSecondaryColor,
//                                         border: Border.all(
//                                             color: kSecondaryColor),
//                                         borderRadius:
//                                         BorderRadius.circular(10)),
//                                     width: MediaQuery.of(context)
//                                         .size
//                                         .width /
//                                         1.5,
//                                     child: Column(
//                                       mainAxisAlignment:
//                                       MainAxisAlignment.center,
//                                       children: [
//                                         Container(
//                                             height: MediaQuery.of(context)
//                                                 .size
//                                                 .width /
//                                                 5,
//                                             width: MediaQuery.of(context)
//                                                 .size
//                                                 .width /
//                                                 5,
//                                             decoration: BoxDecoration(
//                                               // color: Color(0xffe8e8e8),
//                                                 shape: BoxShape.circle,
//                                                 image: DecorationImage(
//                                                     image:
//                                                     CachedNetworkImageProvider(
//                                                       v['profileImageUrl'] ==
//                                                           null
//                                                           ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
//                                                           : v['profileImageUrl'],
//                                                     )))),
//                                         Padding(
//                                           padding:
//                                           const EdgeInsets.all(8.0),
//                                           child: Text(
//                                             '${v['name']} ${v['id']}',
//                                             textScaleFactor:
//                                             mediaQueryData
//                                                 .textScaleFactor
//                                                 .clamp(0.2, 1)
//                                                 .toDouble(),
//                                             style: TextStyle(
//                                               // color: Color(0xffe8e8e8),
//                                                 fontSize: SizeConfig
//                                                     .safeBlockHorizontal *
//                                                     4.5),
//                                           ),
//                                         ),
//                                         Padding(
//                                           padding:
//                                           const EdgeInsets.all(8.0),
//                                           child: Text(
//                                             '${v['description']}',
//                                             textScaleFactor:
//                                             mediaQueryData
//                                                 .textScaleFactor
//                                                 .clamp(0.2, 1)
//                                                 .toDouble(),
//                                             textAlign: TextAlign.center,
//                                             style: TextStyle(
//                                               // color: Color(0xffe8e8e8),
//                                                 fontSize: SizeConfig
//                                                     .safeBlockHorizontal *
//                                                     3.5),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 Positioned(
//                                   right: 10,
//                                   top: 10,
//                                   child: IconButton(
//                                     onPressed: () async {
//                                       print(v['id']);
//                                       await removeFromCommunity(v['id']);
//                                     },
//                                     icon: Icon(
//                                       FontAwesomeIcons.timesCircle,
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             )
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 15),
//                       child: InkWell(
//                         onTap: () {
//                           Navigator.pop(context);
//                         },
//                         child: Container(
//                           decoration: BoxDecoration(
//                               border: Border.all(color: kSecondaryColor),
//                               borderRadius: BorderRadius.circular(20)),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20, vertical: 5),
//                             child: Text(
//                               'Continue',
//                               textScaleFactor: mediaQueryData.textScaleFactor
//                                   .clamp(0.2, 1)
//                                   .toDouble(),
//                               style: TextStyle(
//                                 // color: Color(0xffe8e8e8),
//                                   fontSize: SizeConfig.safeBlockHorizontal * 4),
//                             ),
//                           ),
//                         ),
//                       ),
//                     )
//                   ],
//                 )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
