import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Player/PlayerElements/Seekbar.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../PlayerState.dart';
import '../Clips.dart';

class PublicProfile extends StatefulWidget {
  String userId;
  AssetsAudioPlayer audioPlayer;
  PublicProfile({@required this.userId, this.audioPlayer,});

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

  void userPodcast(String userId) async {
    String url =
        "https://api.aureal.one/public/podcast?user_id=${widget.userId}";
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
    userPodcast(widget.userId);
    userRooms(widget.userId);
    userSnippet(widget.userId);
    _controller = TabController(vsync: this, length: 4);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    print(widget.userId);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.ios_share),
                  onPressed: () {
                    print("profile pressed");
                  },
                )
              ],
              expandedHeight: MediaQuery.of(context).size.height / 1.9,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: userData['img'] == null
                                  ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                  : userData['img'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.width / 5.5,
                                  width:
                                      MediaQuery.of(context).size.width / 5.5,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
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
                                ],
                              ),
                            ),
                           for (var v in podcastList)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        v['description'] == null
                                            ? SizedBox()
                                            : htmlMatch.hasMatch(
                                                        v['description']) ==
                                                    true
                                                ? Text(
                                                    '${((v['description']).toString())}',
                                                    maxLines: seeMore == true
                                                        ? 30
                                                        : 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textScaleFactor:
                                                        mediaQueryData
                                                            .textScaleFactor
                                                            .clamp(1, 1.5)
                                                            .toDouble(),
                                                    style: TextStyle(
                                                        //      color: Colors.grey,
                                                        fontSize: SizeConfig
                                                                .blockSizeHorizontal *
                                                            3),
                                                  )
                                                : Text(
                                                    v['description'].toString(),
                                                    maxLines: seeMore == true
                                                        ? 30
                                                        : 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textScaleFactor:
                                                        mediaQueryData
                                                            .textScaleFactor
                                                            .clamp(0.5, 1)
                                                            .toDouble(),
                                                    style: TextStyle(
                                                        //  color: Colors.grey,
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3),
                                                  ),
                                        GestureDetector(
                                          onTap: () {
                                            showBarModalBottomSheet(
                                                context: context,
                                                builder: (context) {
                                                  return Container(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          leading: SizedBox(
                                                            height: 50,
                                                            width: 50,
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl: v ==
                                                                      null
                                                                  ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                                  : userData[
                                                                      'img'],
                                                              imageBuilder:
                                                                  (context,
                                                                      imageProvider) {
                                                                return Container(
                                                                  decoration: BoxDecoration(
                                                                      image: DecorationImage(
                                                                          image:
                                                                              imageProvider,
                                                                          fit: BoxFit
                                                                              .cover)),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          title: Text(
                                                              "${v['name']}"),
                                                          subtitle: Text(
                                                              "${v['author']}"),
                                                        ),
                                                        Divider(),
                                                        ListTile(
                                                          subtitle: v == null
                                                              ? SizedBox()
                                                              : htmlMatch.hasMatch(
                                                                          v['description']
                                                                              .toString()) ==
                                                                      true
                                                                  ? Text(
                                                                      '${((v['description']).toString())}',
                                                                      textScaleFactor: mediaQueryData
                                                                          .textScaleFactor
                                                                          .clamp(
                                                                              0.5,
                                                                              1.5)
                                                                          .toDouble(),
                                                                      style: TextStyle(
                                                                          //      color: Colors.grey,
                                                                          fontSize: SizeConfig.blockSizeHorizontal * 3.5),
                                                                    )
                                                                  : Text(
                                                                      v['description'],
                                                                      textScaleFactor: mediaQueryData
                                                                          .textScaleFactor
                                                                          .clamp(
                                                                              0.5,
                                                                              1)
                                                                          .toDouble(),
                                                                      style: TextStyle(
                                                                          //  color: Colors.grey,
                                                                          fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                                    ),
                                                        ),
                                                        SizedBox(
                                                          height: 20,
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                });
                                          },
                                          child: Text(
                                            seeMore == false
                                                ? "See more"
                                                : "See less",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5)),
                                          ),
                                        ),
                                      ]),
                                ),
                              ),
                            Row(
                              children: [
                                RichText(
                                    text: TextSpan(
                                        text: "1.4M ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                        children: [
                                      TextSpan(
                                          text: "Followers",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal)),
                                    ])),
                                SizedBox(
                                  width: 20,
                                ),
                                RichText(
                                    text: TextSpan(
                                        text: "1.4M ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                        children: [
                                      TextSpan(
                                          text: "Followers",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal)),
                                    ])),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      print(userData['instagram']);
                                      launcher.launchInBrowser(
                                        userData['instagram'],
                                      );
                                    },
                                    icon: Icon(FontAwesomeIcons.instagram),
                                  ),
                                  //Text("@${userData['linkedin']}"),
                                  IconButton(
                                    onPressed: () {
                                      launcher.launchInBrowser(
                                        userData['twitter'],
                                      );
                                    },
                                    icon: Icon(FontAwesomeIcons.twitter),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      launcher.launchInBrowser(
                                        userData['linkedin'],
                                      );
                                    },
                                    icon: Icon(FontAwesomeIcons.linkedin),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      launcher.launchInBrowser(
                                        userData['website'],
                                      );
                                    },
                                    icon: Icon(
                                        FontAwesomeIcons.externalLinkSquareAlt),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(colors: [
                                    Color(0xff5d5da8),
                                    Color(0xff5bc3ef)
                                  ])),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 10),
                                child: Text("Follow"),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 16,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              bottom: PreferredSize(
                 preferredSize: Size.fromHeight(50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    color: Color(0xff161616),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TabBar(
                          enableFeedback: true,
                          isScrollable: true,
                          controller: _controller,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: [
                            Tab(
                              text: 'Home',
                            ),
                            Tab(
                              text: 'Podcast',
                            ),
                            Tab(
                              text: 'Live Rooms',
                            ),
                            Tab(
                              text: 'Snippets',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ];
        },
        body: TabBarView(
          controller: _controller,
          children: [
            Container(
              child: ListView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: [
                  for (var v in getSnippet)
                    ListTile(
                      subtitle: Text("${v['snippet'][0]['start_time']}"),
                    )
                ],
              ),
            ),

            ///Podcast
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: podcastList.length == 0
                  ?
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [  for (var v in podcastList)
                    Container(
                      child: ListTile(
                        title:   Transform.translate(
                            offset: Offset(-16, 0),
                            child: Text("${v['author']} hasn't published podcast yet.!")),
                        leading:  Icon(FontAwesomeIcons.podcast),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: MediaQuery.of(context).size.height/15,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ],
                ),
              )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var a in podcastList)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  new BoxShadow(
                                    color: Colors.black54.withOpacity(0.2),
                                    blurRadius: 10.0,
                                  ),
                                ],
                                color: Color(0xff222222),
                              ),
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 15),
                                child: ListTile(
                                  onTap: () {
                                    showBarModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Container(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: SizedBox(
                                                    height: 50,
                                                    width: 50,
                                                    child: CachedNetworkImage(
                                                      imageUrl: userData[
                                                                  'img'] ==
                                                              null
                                                          ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                          : userData['img'],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  title: a['name'] == null
                                                      ? SizedBox()
                                                      : Text("${a['name']}"),
                                                  subtitle: a['author'] == null
                                                      ? SizedBox()
                                                      : Text("${a['author']}"),
                                                ),
                                                Divider(),
                                                ListTile(
                                                  title: a['description'] ==
                                                          null
                                                      ? SizedBox()
                                                      : htmlMatch.hasMatch(a[
                                                                      'description']
                                                                  .toString()) ==
                                                              true
                                                          ? Text(
                                                              '${((a['description']).toString())}',
                                                              textScaleFactor:
                                                                  mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.5,
                                                                          1.5)
                                                                      .toDouble(),
                                                              style: TextStyle(
                                                                  //      color: Colors.grey,
                                                                  fontSize:
                                                                      SizeConfig
                                                                              .blockSizeHorizontal *
                                                                          3.5),
                                                            )
                                                          : Text(
                                                              a['description'],
                                                              textScaleFactor:
                                                                  mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.5,
                                                                          1)
                                                                      .toDouble(),
                                                              style: TextStyle(
                                                                  //  color: Colors.grey,
                                                                  fontSize:
                                                                      SizeConfig
                                                                              .safeBlockHorizontal *
                                                                          3.5),
                                                            ),
                                                ),
                                                SizedBox(
                                                  height: 20,
                                                )
                                              ],
                                            ),
                                          );
                                        });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${a['name']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textScaleFactor: mediaQueryData
                                        .textScaleFactor
                                        .clamp(0.5, 1.5)
                                        .toDouble(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        //       color: Colors.white,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4),
                                  ),
                                  subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        a['description'] == null
                                            ? SizedBox(
                                                height: 20,
                                              )
                                            : Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10.0),
                                                child: htmlMatch.hasMatch(
                                                            a['description']) ==
                                                        true
                                                    ? Text(
                                                        '${(a['description'].toString())}',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textScaleFactor:
                                                            mediaQueryData
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
                                                        a['description'],
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textScaleFactor:
                                                            mediaQueryData
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
                                      ]),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            ///LiveRoom
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: userRoom == null
                  ?
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [  for (var v in podcastList)
                    Container(
                      child: ListTile(
                        title:   Transform.translate(
                        offset: Offset(-16, 0),
                        child: Text("${v['author']} has no Live Room yet.!")),
                        leading:  Icon(Icons.stream,color: Colors.blue,),

                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: MediaQuery.of(context).size.height/15,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ],
                ),
              )
                  : ListView(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: [
                        for (var d in userRoom)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                for (var a in d['Communities'])
                                  showBarModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Container(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: Icon(
                                                    Icons.group,
                                                    size: SizeConfig
                                                            .safeBlockHorizontal *
                                                        10,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                title:
                                                    Text("${a['description']}"),
                                              ),
                                              Divider(),
                                              Column(
                                                children: [
                                                  for (var a
                                                      in d['Communities'])
                                                    ListTile(
                                                      //   title:Text("${d['Communities'][0]['createdAt'].toString()}"),
                                                      title: a['description'] ==
                                                              null
                                                          ? SizedBox()
                                                          : htmlMatch.hasMatch(d[
                                                                          'description']
                                                                      .toString()) ==
                                                                  true
                                                              ? Text(
                                                                  '${((a['description']).toString())}',
                                                                  textScaleFactor: mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.5,
                                                                          1.5)
                                                                      .toDouble(),
                                                                  style: TextStyle(
                                                                      //      color: Colors.grey,
                                                                      fontSize: SizeConfig.blockSizeHorizontal * 3.5),
                                                                )
                                                              : Text(
                                                                  a['description'],
                                                                  textScaleFactor: mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.5,
                                                                          1)
                                                                      .toDouble(),
                                                                  style: TextStyle(
                                                                      //  color: Colors.grey,
                                                                      fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                                ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              )
                                            ],
                                          ),
                                        );
                                      });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    new BoxShadow(
                                      color: Colors.black54.withOpacity(0.2),
                                      blurRadius: 10.0,
                                    ),
                                  ],
                                  color: Color(0xff222222),
                                ),
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      CachedNetworkImage(
                                        imageBuilder: (context, imageProvider) {
                                          return Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                12,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5.2,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.fill),
                                            ),
                                          );
                                        },
                                        memCacheHeight:
                                            (MediaQuery.of(context).size.height)
                                                .floor(),
                                        imageUrl: d['imageurl'] != null
                                            ? d['imageurl']
                                            : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                        placeholder: (context, imageProvider) {
                                          return Container(
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: AssetImage(
                                                        'assets/images/Thumbnail.png'),
                                                    fit: BoxFit.fill)),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                10.5,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                4.5,
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20 ,vertical: 10),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.9,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${d['title'].toString()}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              d['description'] == null
                                                  ? SizedBox(
                                                      height: 20,
                                                    )
                                                  : Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 10.0),
                                                      child: htmlMatch.hasMatch(
                                                                  d['description']) ==
                                                              true
                                                          ? Text(
                                                              '${(d['description'].toString())}',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              textScaleFactor:
                                                                  mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.5,
                                                                          1)
                                                                      .toDouble(),
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.5),

                                                                  //       color: Colors.grey,
                                                                  fontSize:
                                                                      SizeConfig
                                                                              .blockSizeHorizontal *
                                                                          3.5),
                                                            )
                                                          : Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Text(
                                                                d['description'],
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.5),
                                                                    fontSize:
                                                                        SizeConfig.safeBlockHorizontal *
                                                                            3.5),
                                                              ),
                                                            ),
                                                    ),

                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
            ),

            ///Snippets
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: getSnippet.length == 0
                  ?
              Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Container(
                          child: ListTile(
                            onTap: (){
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) =>
                                          Clips()));
                            },
                            title:   Transform.translate(
                                offset: Offset(-16, 0),child: Text("No Snippet's. Browse for more... ")),
                            leading:  Icon(Icons.library_books_outlined),
                          ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(10),
              ),
              height: MediaQuery.of(context).size.height/15,
                          width: MediaQuery.of(context).size.width,
              ),
                      ],
                    ),
                  )
                  : ListView(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: [
                        for (var g in getSnippet)
                          // for(var b in g['snippet'])
                          InkWell(
                            onTap: () {
                              showBarModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        height: MediaQuery.of(context).size.height,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (var b in g['snippet'])
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      boxShadow: [
                                                        new BoxShadow(
                                                          color: Colors.black54
                                                              .withOpacity(0.2),
                                                          blurRadius: 10.0,
                                                        ),
                                                      ],
                                                      color: Color(0xff222222),
                                                    ),
                                                    width: double.infinity,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height /
                                                                12,
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                5,
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl: g['episode']
                                                                          [
                                                                          'episode_image'] ==
                                                                      null
                                                                  ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                                  : g['episode'][
                                                                      'episode_image'],
                                                              imageBuilder: (context,
                                                                  imageProvider) {
                                                                return Container(
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                      image: DecorationImage(
                                                                          image:
                                                                              imageProvider,
                                                                          fit: BoxFit
                                                                              .fill)),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 20, vertical: 10),
                                                            child: Column(

                                                              crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  "${g['episode']['episode_name'].toString()}",
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                      FontWeight.bold),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets.only(
                                                                      top: 10),
                                                                  child: Text(
                                                                    "${g['episode']['podcast_name'].toString()}",
                                                                    style: TextStyle(
                                                                      color: Colors.white
                                                                          .withOpacity(0.5),
                                                                    ),
                                                                  ),
                                                                ),
                                                                 SizedBox(height: 22,),
                                                                 Row(
                                                                  mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                                                                   children: [
                                                                     Icon(Icons.play_arrow),
                                                                     SizedBox(width: 5,),
                                                                     Container(height: 2,
                                                                     width: MediaQuery.of(context).size.width/2.5,
                                                                     color: Colors.white,),
                                                                     SizedBox(width: 5,),
                                                                     Text("${b["end_time"]}")
                                                                   ],
                                                                 ),

                                                              ],
                                                            ),
                                                          ),

                                                        ],
                                                      ),
                                                    )),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  new BoxShadow(
                                    color: Colors.black54.withOpacity(0.2),
                                    blurRadius: 10.0,
                                  ),
                                ],
                                color: Color(0xff222222),
                              ),
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                      },
                                      child: CachedNetworkImage(
                                        imageBuilder:
                                            (context, imageProvider) {
                                          return Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                12,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.fill),
                                            ),
                                          );
                                        },
                                        memCacheHeight:
                                            (MediaQuery.of(context)
                                                    .size
                                                    .height)
                                                .floor(),
                                        imageUrl: g['episode']
                                                    ['episode_image'] !=
                                                null
                                            ? g['episode']['episode_image']
                                            : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                        placeholder:
                                            (context, imageProvider) {
                                          return Container(
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: AssetImage(
                                                        'assets/images/Thumbnail.png'),
                                                    fit: BoxFit.fill)),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.38,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.38,
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${g['episode']['episode_name']}",
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10),
                                            child: Text(
                                              "${g['episode']['podcast_name']}",
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              ),
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
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
