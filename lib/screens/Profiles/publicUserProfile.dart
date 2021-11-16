import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Player/PlayerElements/Seekbar.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
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

  void getProfileData(String userId) async {
    String url = 'https://api.aureal.one/public/users?user_id=${widget.userId}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(
            "//////////////////////////////////////////////////${response.body}");
        setState(() {
          userData = jsonDecode(response.body)['users'];
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
        print(
            "//////////////////////////////////////////////////${response.body}");
        setState(() {
          userRoom = jsonDecode(response.body)['data'];
          //    communityRoom =jsonDecode(response.body)['data']['Communities'];
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
  @override
  void initState() {
    // TODO: implement initState

    getProfileData(widget.userId);
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
    print(widget.userId);
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
                                  child: Row(
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
                                          "96",
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
                                          "96",
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
                    ListTile(
                      title: Text("Episode Name"),
                      subtitle: Text("Description"),
                    )
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
                    height: MediaQuery.of(context).size.width / 3,
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: v['image'] == null
                                          ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                          : v['podcast_image'],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("Active Room",
                        textScaleFactor: 1.0,
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 7.5),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xff222222),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xff161616)),
                                    height: 15,
                                    width: 60,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                ],
                              ),
                            ),
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(vertical: 15),
                            //   child: Container(
                            //     height:
                            //         (MediaQuery.of(context).size.width / 9) *
                            //             2.1,
                            //     child: GridView.builder(
                            //       scrollDirection: Axis.horizontal,
                            //       gridDelegate:
                            //           SliverGridDelegateWithFixedCrossAxisCount(
                            //         crossAxisCount:
                            //             MediaQuery.of(context).orientation ==
                            //                     Orientation.landscape
                            //                 ? 3
                            //                 : 2,
                            //         crossAxisSpacing: 5,
                            //         mainAxisSpacing: 5,
                            //         childAspectRatio: (1 / 1),
                            //       ),
                            //       itemBuilder: (context, index) {
                            //         return CircleAvatar(
                            //           backgroundColor: Color(0xff161616),
                            //         );
                            //       },
                            //       itemCount: 10,
                            //     ),
                            //   ),
                            // ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                "${userRoom[0]['description']}",
                                textScaleFactor: 1.0,
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize:
                                        SizeConfig.blockSizeHorizontal * 2.8),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xff161616)),
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 10,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width / 5,
                              height: 40,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Color(0xff161616)),
                            )
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
