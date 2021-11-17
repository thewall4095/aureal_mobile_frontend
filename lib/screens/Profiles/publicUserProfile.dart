import 'dart:convert';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'dart:io';

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

    String url = 'https://api.aureal.one/public/users?user_id=${widget.userId}';
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
        print(
            "//////////////////////////////////////////////////${response.body}");
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
        print(
            "//////////////////////////////////////////////////${response.body}");
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

  @override
  void initState() {
    // TODO: implement initState

    getProfileData();
    userPodcast();
    userRooms(widget.userId);
    userSnippet(widget.userId);
    _controller = TabController(vsync: this, length: 4);
    super.initState();
  }

  PageController _pageController = PageController(viewportFraction: 0.8);

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        backgroundColor: Color(0xff161616),
        body: Container(
          child: ListView(
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 10,
                        ),
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
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
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
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 5,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text("@${userData['username']}"),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: InkWell(
                                    onTap: () {
                                      follow();
                                    },
                                    child: ifFollowed == true
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Text("Followed"),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_circle),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
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
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${userData['followers']}",
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4.5,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Followers",
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  2.5),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${userData['following']}",
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4.5,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Following",
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  2.5),
                                        )
                                      ],
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text("Latest Episode"),
                    ),
                    // InkWell(
                    //   onTap: () {
                    //     Navigator.push(
                    //         context,
                    //         CupertinoPageRoute(
                    //             builder: (context) =>
                    //                 EpisodeView(episodeId: v['id'])));
                    //   },
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 10, vertical: 10),
                    //     child: Column(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Container(
                    //           decoration: BoxDecoration(
                    //             boxShadow: [
                    //               new BoxShadow(
                    //                 color: Colors.black54.withOpacity(0.2),
                    //                 blurRadius: 10.0,
                    //               ),
                    //             ],
                    //             color: Color(0xff222222),
                    //             borderRadius: BorderRadius.circular(8),
                    //           ),
                    //           width: double.infinity,
                    //           child: Padding(
                    //             padding: const EdgeInsets.symmetric(
                    //                 vertical: 20, horizontal: 20),
                    //             child: Column(
                    //               mainAxisAlignment: MainAxisAlignment.center,
                    //               children: [
                    //                 Row(
                    //                   children: [
                    //                     CachedNetworkImage(
                    //                       imageBuilder:
                    //                           (context, imageProvider) {
                    //                         return Container(
                    //                           decoration: BoxDecoration(
                    //                             borderRadius:
                    //                                 BorderRadius.circular(10),
                    //                             image: DecorationImage(
                    //                                 image: imageProvider,
                    //                                 fit: BoxFit.cover),
                    //                           ),
                    //                           width: MediaQuery.of(context)
                    //                                   .size
                    //                                   .width /
                    //                               7,
                    //                           height: MediaQuery.of(context)
                    //                                   .size
                    //                                   .width /
                    //                               7,
                    //                         );
                    //                       },
                    //                       imageUrl: v['image'],
                    //                       memCacheWidth: MediaQuery.of(context)
                    //                           .size
                    //                           .width
                    //                           .floor(),
                    //                       memCacheHeight: MediaQuery.of(context)
                    //                           .size
                    //                           .width
                    //                           .floor(),
                    //                       placeholder: (context, url) =>
                    //                           Container(
                    //                         width: MediaQuery.of(context)
                    //                                 .size
                    //                                 .width /
                    //                             7,
                    //                         height: MediaQuery.of(context)
                    //                                 .size
                    //                                 .width /
                    //                             7,
                    //                         child: Image.asset(
                    //                             'assets/images/Thumbnail.png'),
                    //                       ),
                    //                       errorWidget: (context, url, error) =>
                    //                           Icon(Icons.error),
                    //                     ),
                    //                     SizedBox(
                    //                         width: SizeConfig.screenWidth / 26),
                    //                     Expanded(
                    //                       child: Column(
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.start,
                    //                         children: [
                    //                           GestureDetector(
                    //                             onTap: () {
                    //                               Navigator.push(
                    //                                   context,
                    //                                   CupertinoPageRoute(
                    //                                       builder: (context) =>
                    //                                           PodcastView(v[
                    //                                               'podcast_id'])));
                    //                             },
                    //                             child: Text(
                    //                               v['podcast_name'],
                    //                               textScaleFactor:
                    //                                   mediaQueryData
                    //                                       .textScaleFactor
                    //                                       .clamp(0.1, 1.2)
                    //                                       .toDouble(),
                    //                               style: TextStyle(
                    //                                   // color: Color(
                    //                                   //     0xffe8e8e8),
                    //                                   fontSize: SizeConfig
                    //                                           .safeBlockHorizontal *
                    //                                       5,
                    //                                   fontWeight:
                    //                                       FontWeight.normal),
                    //                             ),
                    //                           ),
                    //                           Text(
                    //                             '${timeago.format(DateTime.parse(v['published_at']))}',
                    //                             textScaleFactor: mediaQueryData
                    //                                 .textScaleFactor
                    //                                 .clamp(0.5, 0.9)
                    //                                 .toDouble(),
                    //                             style: TextStyle(
                    //                                 // color: Color(
                    //                                 //     0xffe8e8e8),
                    //                                 fontSize: SizeConfig
                    //                                         .safeBlockHorizontal *
                    //                                     3.5),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     )
                    //                   ],
                    //                 ),
                    //                 Padding(
                    //                   padding: const EdgeInsets.symmetric(
                    //                       vertical: 10),
                    //                   child: Container(
                    //                     width: double.infinity,
                    //                     child: Column(
                    //                       crossAxisAlignment:
                    //                           CrossAxisAlignment.start,
                    //                       children: [
                    //                         Text(
                    //                           v['name'],
                    //                           textScaleFactor: mediaQueryData
                    //                               .textScaleFactor
                    //                               .clamp(0.5, 1)
                    //                               .toDouble(),
                    //                           style: TextStyle(
                    //                               // color: Color(
                    //                               //     0xffe8e8e8),
                    //                               fontSize: SizeConfig
                    //                                       .safeBlockHorizontal *
                    //                                   4.5,
                    //                               fontWeight: FontWeight.bold),
                    //                         ),
                    //                         Padding(
                    //                           padding:
                    //                               const EdgeInsets.symmetric(
                    //                                   vertical: 10),
                    //                           child: v['summary'] == null
                    //                               ? SizedBox(
                    //                                   width: 0, height: 0)
                    //                               : (htmlMatch.hasMatch(
                    //                                           v['summary']) ==
                    //                                       true
                    //                                   ? Text(
                    //                                       parse(v['summary'])
                    //                                           .body
                    //                                           .text,
                    //                                       textScaleFactor:
                    //                                           mediaQueryData
                    //                                               .textScaleFactor
                    //                                               .clamp(0.5, 1)
                    //                                               .toDouble(),
                    //                                       maxLines: 2,
                    //                                       style: TextStyle(
                    //                                           // color: Colors.white,
                    //                                           fontSize: SizeConfig
                    //                                                   .safeBlockHorizontal *
                    //                                               3.2),
                    //                                     )
                    //                                   : Text(
                    //                                       '${v['summary']}',
                    //                                       textScaleFactor:
                    //                                           mediaQueryData
                    //                                               .textScaleFactor
                    //                                               .clamp(0.5, 1)
                    //                                               .toDouble(),
                    //                                       style: TextStyle(
                    //                                           //      color: Colors.white,
                    //                                           fontSize: SizeConfig
                    //                                                   .safeBlockHorizontal *
                    //                                               3.2),
                    //                                     )),
                    //                         )
                    //                       ],
                    //                     ),
                    //                   ),
                    //                 ),
                    //                 Container(
                    //                   width: MediaQuery.of(context).size.width,
                    //                   child: Row(
                    //                     mainAxisAlignment:
                    //                         MainAxisAlignment.spaceBetween,
                    //                     children: [
                    //                       Row(
                    //                         mainAxisAlignment:
                    //                             MainAxisAlignment.spaceBetween,
                    //                         children: [
                    //                           InkWell(
                    //                             onTap: () async {
                    //                               if (prefs.getString(
                    //                                       'HiveUserName') !=
                    //                                   null) {
                    //                                 setState(() {
                    //                                   v['isLoading'] = true;
                    //                                 });
                    //                                 double _value = 50.0;
                    //                                 showDialog(
                    //                                     context: context,
                    //                                     builder: (context) {
                    //                                       return Dialog(
                    //                                           backgroundColor:
                    //                                               Colors
                    //                                                   .transparent,
                    //                                           child: UpvoteEpisode(
                    //                                               permlink: v[
                    //                                                   'permlink'],
                    //                                               episode_id:
                    //                                                   v['id']));
                    //                                     }).then((value) async {
                    //                                   print(value);
                    //                                 });
                    //                                 setState(() {
                    //                                   v['ifVoted'] =
                    //                                       !v['ifVoted'];
                    //                                 });
                    //                                 setState(() {
                    //                                   v['isLoading'] = false;
                    //                                 });
                    //                               } else {
                    //                                 showBarModalBottomSheet(
                    //                                     context: context,
                    //                                     builder: (context) {
                    //                                       return HiveDetails();
                    //                                     });
                    //                               }
                    //                             },
                    //                             child: Container(
                    //                               decoration: v['ifVoted'] ==
                    //                                       true
                    //                                   ? BoxDecoration(
                    //                                       gradient:
                    //                                           LinearGradient(
                    //                                               colors: [
                    //                                             Color(
                    //                                                 0xff5bc3ef),
                    //                                             Color(
                    //                                                 0xff5d5da8)
                    //                                           ]),
                    //                                       borderRadius:
                    //                                           BorderRadius
                    //                                               .circular(30))
                    //                                   : BoxDecoration(
                    //                                       border: Border.all(
                    //                                           color:
                    //                                               kSecondaryColor),
                    //                                       borderRadius:
                    //                                           BorderRadius
                    //                                               .circular(
                    //                                                   30)),
                    //                               child: Padding(
                    //                                 padding: const EdgeInsets
                    //                                         .symmetric(
                    //                                     vertical: 5,
                    //                                     horizontal: 5),
                    //                                 child: Row(
                    //                                   children: [
                    //                                     v['isLoading'] == true
                    //                                         ? Container(
                    //                                             height: 17,
                    //                                             width: 18,
                    //                                             child:
                    //                                                 SpinKitPulse(
                    //                                               color: Colors
                    //                                                   .blue,
                    //                                             ),
                    //                                           )
                    //                                         : Icon(
                    //                                             FontAwesomeIcons
                    //                                                 .chevronCircleUp,
                    //                                             size: 15,
                    //                                             // color:
                    //                                             //     Color(0xffe8e8e8),
                    //                                           ),
                    //                                     Padding(
                    //                                       padding:
                    //                                           const EdgeInsets
                    //                                                   .symmetric(
                    //                                               horizontal:
                    //                                                   8),
                    //                                       child: Text(
                    //                                         v['votes']
                    //                                             .toString(),
                    //                                         textScaleFactor:
                    //                                             1.0,
                    //                                         style: TextStyle(
                    //                                             fontSize: 12
                    //                                             // color:
                    //                                             //     Color(0xffe8e8e8)
                    //                                             ),
                    //                                       ),
                    //                                     ),
                    //                                     Padding(
                    //                                       padding:
                    //                                           const EdgeInsets
                    //                                                   .only(
                    //                                               right: 4),
                    //                                       child: Text(
                    //                                         '\$${v['payout_value'].toString().split(' ')[0]}',
                    //                                         textScaleFactor:
                    //                                             1.0,
                    //                                         style: TextStyle(
                    //                                           fontSize: 12,
                    //
                    //                                           // color:
                    //                                           //     Color(0xffe8e8e8)
                    //                                         ),
                    //                                       ),
                    //                                     )
                    //                                   ],
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                           ),
                    //                           InkWell(
                    //                             onTap: () {
                    //                               if (prefs.getString(
                    //                                       'HiveUserName') !=
                    //                                   null) {
                    //                                 Navigator.push(
                    //                                     context,
                    //                                     CupertinoPageRoute(
                    //                                         builder:
                    //                                             (context) =>
                    //                                                 Comments(
                    //                                                   episodeObject:
                    //                                                       v,
                    //                                                 )));
                    //                               } else {
                    //                                 showBarModalBottomSheet(
                    //                                     context: context,
                    //                                     builder: (context) {
                    //                                       return HiveDetails();
                    //                                     });
                    //                               }
                    //                             },
                    //                             child: Padding(
                    //                               padding:
                    //                                   const EdgeInsets.all(8.0),
                    //                               child: Container(
                    //                                 decoration: BoxDecoration(
                    //                                     border: Border.all(
                    //                                         color:
                    //                                             kSecondaryColor),
                    //                                     borderRadius:
                    //                                         BorderRadius
                    //                                             .circular(30)),
                    //                                 child: Padding(
                    //                                   padding:
                    //                                       const EdgeInsets.all(
                    //                                           4.0),
                    //                                   child: Row(
                    //                                     children: [
                    //                                       Icon(
                    //                                         Icons
                    //                                             .mode_comment_outlined,
                    //                                         size: 14,
                    //                                       ),
                    //                                       Padding(
                    //                                         padding:
                    //                                             const EdgeInsets
                    //                                                     .symmetric(
                    //                                                 horizontal:
                    //                                                     7),
                    //                                         child: Text(
                    //                                           v['comments_count']
                    //                                               .toString(),
                    //                                           textScaleFactor:
                    //                                               1.0,
                    //                                           style: TextStyle(
                    //                                               fontSize: 10
                    //                                               // color:
                    //                                               //     Color(0xffe8e8e8)
                    //                                               ),
                    //                                         ),
                    //                                       ),
                    //                                     ],
                    //                                   ),
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                           ),
                    //                           InkWell(
                    //                             onTap: () {
                    //                               print(v
                    //                                   .toString()
                    //                                   .contains('.mp4'));
                    //                               if (v.toString().contains('.mp4') == true ||
                    //                                   v.toString().contains(
                    //                                           '.m4v') ==
                    //                                       true ||
                    //                                   v.toString().contains(
                    //                                           '.flv') ==
                    //                                       true ||
                    //                                   v.toString().contains(
                    //                                           '.f4v') ==
                    //                                       true ||
                    //                                   v.toString().contains(
                    //                                           '.ogv') ==
                    //                                       true ||
                    //                                   v.toString().contains(
                    //                                           '.ogx') ==
                    //                                       true ||
                    //                                   v.toString().contains(
                    //                                           '.wmv') ==
                    //                                       true ||
                    //                                   v.toString().contains(
                    //                                           '.webm') ==
                    //                                       true) {
                    //                                 currentlyPlaying.stop();
                    //                                 Navigator.push(context,
                    //                                     CupertinoPageRoute(
                    //                                         builder: (context) {
                    //                                   return PodcastVideoPlayer(
                    //                                       episodeObject: v);
                    //                                 }));
                    //                               } else {
                    //                                 if (v
                    //                                         .toString()
                    //                                         .contains('.pdf') ==
                    //                                     true) {
                    //                                   // Navigator.push(
                    //                                   //     context,
                    //                                   //     CupertinoPageRoute(
                    //                                   // der:
                    //                                   //             (context) {
                    //                                   //   return PDFviewer(
                    //                                   //       episodeObject:
                    //                                   //           v);
                    //                                   // }));
                    //                                 } else {
                    //                                   currentlyPlaying.stop();
                    //                                   currentlyPlaying
                    //                                       .episodeObject = v;
                    //                                   print(currentlyPlaying
                    //                                       .episodeObject
                    //                                       .toString());
                    //                                   currentlyPlaying.play();
                    //                                   Navigator.push(context,
                    //                                       CupertinoPageRoute(
                    //                                           builder:
                    //                                               (context) {
                    //                                     return Player();
                    //                                   }));
                    //                                 }
                    //                               }
                    //                             },
                    //                             child: Padding(
                    //                               padding:
                    //                                   const EdgeInsets.only(
                    //                                       right: 60),
                    //                               child: Container(
                    //                                 decoration: BoxDecoration(
                    //                                     border: Border.all(
                    //                                         color:
                    //                                             kSecondaryColor),
                    //                                     borderRadius:
                    //                                         BorderRadius
                    //                                             .circular(30)),
                    //                                 child: Padding(
                    //                                   padding:
                    //                                       const EdgeInsets.all(
                    //                                           5),
                    //                                   child: Row(
                    //                                     children: [
                    //                                       Icon(
                    //                                         Icons
                    //                                             .play_circle_outline,
                    //                                         size: 15,
                    //                                       ),
                    //                                       Padding(
                    //                                         padding:
                    //                                             const EdgeInsets
                    //                                                     .symmetric(
                    //                                                 horizontal:
                    //                                                     8),
                    //                                         child: Text(
                    //                                           DurationCalculator(
                    //                                               v['duration']),
                    //                                           textScaleFactor:
                    //                                               0.75,
                    //                                           // style: TextStyle(
                    //                                           //      color: Color(0xffe8e8e8)
                    //                                           //     ),
                    //                                         ),
                    //                                       ),
                    //                                     ],
                    //                                   ),
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                       InkWell(
                    //                         onTap: () {
                    //                           share(episodeObject: v);
                    //                         },
                    //                         child: Icon(
                    //                           Icons.ios_share,
                    //                           // size: 14,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         ),
                    //         Builder(builder: (context) {
                    //           if (currentlyPlaying.episodeName != null) {
                    //             return v['id'] ==
                    //                         currentlyPlaying
                    //                             .episodeObject['id'] &&
                    //                     currentlyPlaying.episodeObject['id'] !=
                    //                         null
                    //                 ? Padding(
                    //                     padding: const EdgeInsets.symmetric(
                    //                         horizontal: 7),
                    //                     child: Container(
                    //                       decoration: BoxDecoration(
                    //                           borderRadius:
                    //                               BorderRadius.circular(30),
                    //                           gradient: LinearGradient(colors: [
                    //                             Color(0xff5d5da8),
                    //                             Color(0xff5bc3ef)
                    //                           ])),
                    //                       width: double.infinity,
                    //                       height: 4,
                    //                     ),
                    //                   )
                    //                 : SizedBox();
                    //           } else {
                    //             return SizedBox();
                    //           }
                    //         }),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Podcasts",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.width / 2.5,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var v in podcastList)
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return PodcastView(v['id']);
                                }));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width / 4,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: v['image'],
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover),
                                          ),
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              4,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              4,
                                        );
                                      },
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "${v['name']}",
                                      textScaleFactor: 1.0,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  )
                ],
              ),
              userRoom == null
                  ? SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text("Active Room",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 4)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 7.5),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Color(0xff222222),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.group,
                                              size: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              userRoom[0]['communities'] != null
                                                  ? "community"
                                                  : 'general',
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  fontSize: SizeConfig
                                                          .blockSizeHorizontal *
                                                      2.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  userRoom[0]['roomParticipants'] == null
                                      ? SizedBox(
                                          height: 10,
                                        )
                                      : Container(
                                          height: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  9) *
                                              2.1,
                                          child: GridView(
                                            scrollDirection: Axis.vertical,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 5,
                                                    mainAxisSpacing: 10,
                                                    crossAxisSpacing: 5,
                                                    childAspectRatio: 1 / 1),
                                            children: [
                                              for (var a in userRoom[0]
                                                  ['roomParticipants'])
                                                CachedNetworkImage(
                                                  imageUrl: a['user_image'],
                                                  memCacheHeight:
                                                      (MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              2)
                                                          .ceil(),
                                                  imageBuilder:
                                                      (context, imageProvider) {
                                                    return Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              10,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              10,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                            image:
                                                                imageProvider,
                                                            fit: BoxFit.cover),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                  userRoom[0]['description'] == null
                                      ? SizedBox()
                                      : Text(
                                          "${userRoom[0]['description']}",
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: SizeConfig
                                                      .blockSizeHorizontal *
                                                  2.8),
                                        ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Text(
                                      "${userRoom[0]['title']}",
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  5,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: kPrimaryColor,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.stream,
                                              size: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              'LIVE',
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  fontSize: SizeConfig
                                                          .blockSizeHorizontal *
                                                      2.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      if (userRoom[0]['hostuserid'] !=
                                          prefs.getString('userId')) {
                                        addRoomParticipant(
                                            roomid: userRoom[0]['roomid']);
                                      } else {
                                        hostJoined(userRoom[0]['roomid']);
                                      }
                                      getRoomDetails(userRoom[0]['roomid'])
                                          .then((value) {
                                        _joinMeeting(
                                            roomId: value['roomid'],
                                            roomName: value['title'],
                                            hostUserId: value['hostuserid']);
                                      });
                                      // await _joinMeeting(
                                      //     roomId: v['roomid'],
                                      //     roomName: v['title'],
                                      //     hostUserId: v['hostuserid']);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Color(0xff191919),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 15),
                                        child: Text("join room"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    )
            ],
          ),
        ));
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
