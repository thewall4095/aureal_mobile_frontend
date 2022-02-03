import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/CommunityService.dart';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PlaylistView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/Share.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../PlayerState.dart';
import 'Clips.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/VideoPlayer.dart';
import 'Profiles/CategoryView.dart';
import 'Profiles/Comments.dart';
import 'RouteAnimation.dart';
import 'buttonPages/settings/Theme-.dart';




class Feed extends StatefulWidget {

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> with AutomaticKeepAliveClientMixin{
  CancelToken _cancel = CancelToken();

  final String baseUrl = "https://api.aureal.one/public";

  var feedStructure = [];

  RegExp htmlMatch = RegExp(r'(\w+)');

  Future<List> getFeedStructure() async {
    Dio dio = Dio();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/recommended?page=0&pageSize=5&user_id=${prefs.getString('userId')}";

    try{
      var response = await dio.get(url);
      if(response.statusCode == 200){

        return response.data['data'];
      }else{

      }
    }catch(e){
      print(e);
    }
  }

  SharedPreferences prefs;

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio(

    );
    prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";

    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }

  }

  Widget _feedBuilder(BuildContext context, var data){

    var episodeObject = Provider.of<PlayerChange>(context);
    var currentlyPlaying = Provider.of<PlayerChange>(context);

    switch(data['type']){
      case 'podcast':
        return PodcastWidget(data: data);
        break;
      case 'episode':
        return EpisodeWidget(data: data);
        break;

      case "playlist":
        return PlaylistWidget(data: data);
        break;
      case 'snippet':
        return SnippetWidget(data: data);
        break;
      case 'user':
        return FutureBuilder(
          future: generalisedApiCall(data['api']),
          builder: (context, snapshot){
            return Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text("${data['name']}", style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                        fontWeight: FontWeight.bold
                    )),
                  ),
                  Text("${snapshot.data}"),
                ],
              ),
            );
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled){
          return <Widget>[

          ];
        },
        body: FutureBuilder(
          future: getFeedStructure(),
          builder: (context, snapshot){
            if(snapshot.hasData){
              return ListView(
                addAutomaticKeepAlives: true,
                children: [
                  for(var v in snapshot.data)
                    _feedBuilder(context, v),
                ],
              );
            }else{
              return SizedBox();
            }

          },

        ),


      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class EpisodeWidget extends StatefulWidget {

  final data;

  const EpisodeWidget({@required this.data}) ;

  @override
  _EpisodeWidgetState createState() => _EpisodeWidgetState();
}

class _EpisodeWidgetState extends State<EpisodeWidget> {

  SharedPreferences prefs;

  RegExp htmlMatch = RegExp(r'(\w+)');

  CancelToken _cancel = CancelToken();

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio(

    );
    prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/$apicall?pageSize=10&user_id=${prefs.getString('userId')}";

    try{
      var response = await dio.get(url, cancelToken: _cancel);
      print(response.data['data']);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }

  }

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    var episodeObject = Provider.of<PlayerChange>(context);
    return FutureBuilder(
      future: generalisedApiCall(widget.data['api']),
      builder: (context, snapshot){
        try{
          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text("${widget.data['name']}", style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.bold
                  )),
                ),
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      for (var v in snapshot.data)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) =>
                                          EpisodeView(
                                              episodeId: v['id'])));
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    // boxShadow: [
                                    //   new BoxShadow(
                                    //     color: Colors.black54
                                    //         .withOpacity(0.2),
                                    //     blurRadius: 10.0,
                                    //   ),
                                    // ],
                                    // border: Border(bottom: BorderSide(width: 0.5,color: Color(0xffe8e8e8).withOpacity(0.5))),
                                    color:
                                    Color(0xff222222),
                                    borderRadius:
                                    BorderRadius.circular(5),
                                  ),
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        vertical: 15,
                                        horizontal: 15),
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
                                                        3),
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
                                                      8,
                                                  height: MediaQuery.of(
                                                      context)
                                                      .size
                                                      .width /
                                                      8,
                                                );
                                              },
                                              imageUrl:
                                              v['image'] == null ? v['podcast_image'] : v['image'],
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
                                                        8,
                                                    height: MediaQuery.of(
                                                        context)
                                                        .size
                                                        .width /
                                                        8,
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
                                                          CupertinoPageRoute(
                                                              builder: (context) =>
                                                                  PodcastView(v['podcast_id'])));
                                                    },
                                                    child: Text(
                                                      v['podcast_name'],
                                                      textScaleFactor: 0.8,
                                                      style: TextStyle(
                                                        // color: Color(
                                                        //     0xffe8e8e8),
                                                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${timeago.format(DateTime.parse(v['published_at']))}',
                                                    textScaleFactor: 0.8,
                                                    style: TextStyle(
                                                      // color: Color(
                                                      //     0xffe8e8e8),
                                                        fontSize: SizeConfig.safeBlockHorizontal * 3),
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
                                              vertical: 15),
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
                                                  0.8,
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
                                                    0.8,
                                                    maxLines:
                                                    2,
                                                    style: TextStyle(
                                                      // color: Colors.white,
                                                        fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                  )
                                                      : Text(
                                                    '${v['summary']}',
                                                    textScaleFactor:
                                                    1.0,
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
                                                  v['permlink'] == null ?SizedBox():InkWell(
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
                                                  v['permlink'] == null ? SizedBox():InkWell(
                                                    onTap: () {
                                                      if (prefs.getString(
                                                          'HiveUserName') !=
                                                          null) {
                                                        Navigator.push(
                                                            context,
                                                            CupertinoPageRoute(
                                                                builder: (context) => Comments(
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
                                                            CupertinoPageRoute(builder:
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
                                                          //     CupertinoPageRoute(
                                                          // der:
                                                          //             (context) {
                                                          //   return PDFviewer(
                                                          //       episodeObject:
                                                          //           v);
                                                          // }));
                                                        } else {
                                                          List<Audio>
                                                          playable =
                                                          [];
                                                          for (var v
                                                          in snapshot.data) {
                                                            playable
                                                                .add(Audio.network(
                                                              v['url'],
                                                              metas:
                                                              Metas(
                                                                id: '${v['id']}',
                                                                title: '${v['name']}',
                                                                artist: '${v['author']}',
                                                                album: '${v['podcast_name']}',
                                                                // image: MetasImage.network('https://www.google.com')
                                                                image: MetasImage.network('${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                              ),
                                                            ));
                                                          }
                                                          episodeObject.playList =
                                                              playable;
                                                          episodeObject.audioPlayer.open(
                                                              Playlist(
                                                                  audios: episodeObject.playList,
                                                                  startIndex: snapshot.data.indexOf(v)),
                                                              showNotification: true);
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
                                                  Icons.ios_share,
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
                              ],
                            ),
                          ),
                        ),

                    ],
                  ),
                )
              ],
            ),
          );
        }catch(e){
          return Column(
            children: [
              for (int i = 0; i < 6; i++)
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
          );
        }

      },
    );
  }
}

class PodcastWidget extends StatelessWidget {

  final data;

  PodcastWidget({@required this.data});

  SharedPreferences prefs;

  CancelToken _cancel = CancelToken();

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio(

    );
    prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/$apicall?pageSize=10&user_id=${prefs.getString('userId')}";

    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }

  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: generalisedApiCall(data['api']),
      builder: (context, snapshot){
        try{
          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text("${data['name']}", style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 5,
                    fontWeight: FontWeight.bold
                )),trailing: Text("See more", style: TextStyle(fontWeight: FontWeight.bold),),),
                SizedBox(height: 10,),
                Container(
                  width: double.infinity,
                  height: SizeConfig.blockSizeVertical * 25,
                  constraints: BoxConstraints(
                      minHeight:
                      MediaQuery.of(context).size.height *
                          0.17),
                  child: ListView.builder(
                    addAutomaticKeepAlives: true,
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, int index){
                      return Padding(
                        padding:
                        const EdgeInsets.fromLTRB(
                            15, 0, 0, 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) =>
                                        PodcastView(
                                            snapshot.data[index]['id'])));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              // x
                              borderRadius:
                              BorderRadius.circular(
                                  15),
                            ),
                            width: MediaQuery.of(context)
                                .size
                                .width *
                                0.38,
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                CachedNetworkImage(
                                  errorWidget: (context,
                                      url, error) {
                                    return Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: NetworkImage(
                                                  "https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png"),
                                              fit: BoxFit
                                                  .cover),
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                              3)),
                                      width: MediaQuery.of(
                                          context)
                                          .size
                                          .width *
                                          0.38,
                                      height: MediaQuery.of(
                                          context)
                                          .size
                                          .width *
                                          0.38,
                                    );
                                  },
                                  imageBuilder: (context,
                                      imageProvider) {
                                    return Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image:
                                              imageProvider,
                                              fit: BoxFit
                                                  .cover),
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                              3)),
                                      width: MediaQuery.of(
                                          context)
                                          .size
                                          .width *
                                          0.38,
                                      height: MediaQuery.of(
                                          context)
                                          .size
                                          .width *
                                          0.38,
                                    );
                                  },
                                  memCacheHeight:
                                  (MediaQuery.of(
                                      context)
                                      .size
                                      .height)
                                      .floor(),
                                  imageUrl:snapshot.data[index]['image'],

                                  placeholder: (context,
                                      imageProvider) {
                                    return Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/Thumbnail.png'),
                                              fit: BoxFit
                                                  .cover)),
                                      height: MediaQuery.of(
                                          context)
                                          .size
                                          .width *
                                          0.38,
                                      width: MediaQuery.of(
                                          context)
                                          .size
                                          .width *
                                          0.38,
                                    );
                                  },
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  snapshot.data[index]['name'],
                                  maxLines: 1,
                                  textScaleFactor: 1.0,
                                  overflow: TextOverflow
                                      .ellipsis,
                                  // style:
                                  //     TextStyle(color: Color(0xffe8e8e8)),
                                ),
                                Text(
                                  snapshot.data[index]['author'],
                                  maxLines: 2,
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                      fontSize: SizeConfig
                                          .safeBlockHorizontal *
                                          2.5,
                                      color: Color(
                                          0xffe777777)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    scrollDirection: Axis.horizontal,

                  ),
                ),
                // Text("${snapshot.data}"),
              ],
            ),
          );
        }catch(e){
          return Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              ListTile(title: Text("${data['name']}", style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 5,
                  fontWeight: FontWeight.bold
              )),trailing: Text("See more", style: TextStyle(fontWeight: FontWeight.bold),),),
              SizedBox(height: 10,),
              Container(
                width: double.infinity,
                height: SizeConfig.blockSizeVertical * 25,
                constraints: BoxConstraints(
                    minHeight:
                    MediaQuery.of(context).size.height *
                        0.17),
                child: ListView.builder(

                  addAutomaticKeepAlives: true,

                  itemCount: 10,
                  itemBuilder: (context, int index){
                    return Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                          15, 0, 0, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          // x
                          borderRadius:
                          BorderRadius.circular(
                              15),
                        ),
                        width: MediaQuery.of(context)
                            .size
                            .width *
                            0.38,
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            CachedNetworkImage(
                              errorWidget: (context,
                                  url, error) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xff222222),
                                      // image: DecorationImage(
                                      //     image: NetworkImage(
                                      //         "https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png"),
                                      //     fit: BoxFit
                                      //         .cover),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          3)),
                                  width: MediaQuery.of(
                                      context)
                                      .size
                                      .width *
                                      0.38,
                                  height: MediaQuery.of(
                                      context)
                                      .size
                                      .width *
                                      0.38,
                                );
                              },
                              imageBuilder: (context,
                                  imageProvider) {
                                return Container(
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image:
                                          imageProvider,
                                          fit: BoxFit
                                              .cover),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          3)),
                                  width: MediaQuery.of(
                                      context)
                                      .size
                                      .width *
                                      0.38,
                                  height: MediaQuery.of(
                                      context)
                                      .size
                                      .width *
                                      0.38,
                                );
                              },
                              memCacheHeight:
                              (MediaQuery.of(
                                  context)
                                  .size
                                  .height)
                                  .floor(),
                              imageUrl: 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                              placeholder: (context,
                                  imageProvider) {
                                return Container(
                                  decoration: BoxDecoration(
                                      // image: DecorationImage(
                                      //     image: AssetImage(
                                      //         'assets/images/Thumbnail.png'),
                                      //     fit: BoxFit
                                      //         .cover),
                                    color: Color(0xff222222)
                                  ),
                                  height: MediaQuery.of(
                                      context)
                                      .size
                                      .width *
                                      0.38,
                                  width: MediaQuery.of(
                                      context)
                                      .size
                                      .width *
                                      0.38,
                                );
                              },
                            ),
                            SizedBox(
                              height: 5,
                            ),

                          ],
                        ),
                      ),
                    );
                  },
                  scrollDirection: Axis.horizontal,

                ),
              ),
            ],
          );
        }

      },
    );
  }
}

class PlaylistWidget extends StatelessWidget {

  final data;

  PlaylistWidget({@required this.data}) ;

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio(

    );
    prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";
    print(url); //TODO: Delete this print statement later

    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }

  }

  SharedPreferences prefs;

  CancelToken _cancel = CancelToken();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: generalisedApiCall(data['api']),
      builder: (context, snapshot){
        if(snapshot.hasData){
          try{
            return Container(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text("${data['name']}", style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                        fontWeight: FontWeight.bold
                    )),
                  ),
                  Container(
                    width: double.infinity,
                    height: SizeConfig.blockSizeVertical * 25,
                    constraints:  BoxConstraints(
                        minHeight:
                        MediaQuery.of(context).size.height *
                            0.17),
                    child: ListView.builder(scrollDirection: Axis.horizontal,itemBuilder: (context, int index){
                      return Padding(
                        padding:
                        const EdgeInsets.fromLTRB(
                            15, 0, 0, 8),
                        child: InkWell(
                          onTap: (){
                            Navigator.push(context, CupertinoPageRoute(builder: (context){
                              return PlaylistView(playlistId: snapshot.data[index]['id']);
                            }));
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                int.parse(snapshot.data[index]['episodes_count']) <= 4 ? CachedNetworkImage(imageUrl: snapshot.data[index]['episodes_images'][0], imageBuilder: (context, imageProvider){
                                  return Container(
                                    height: MediaQuery.of(context).size.width / 3,
                                    width: MediaQuery.of(context).size.width / 3,
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: imageProvider, fit: BoxFit.cover
                                        )
                                    ),
                                  );
                                },) : Container(child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CachedNetworkImage(
                                          imageBuilder: (context, imageProvider){
                                            return Container(
                                              height: MediaQuery.of(context).size.width / 6,
                                              width: MediaQuery.of(context).size.width / 6,
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover
                                                  )
                                              ),
                                            );
                                          },
                                          imageUrl: snapshot.data[index]['episodes_images'][0],
                                        ),
                                        CachedNetworkImage(
                                          imageBuilder: (context, imageProvider){
                                            return Container(
                                              height: MediaQuery.of(context).size.width / 6,
                                              width: MediaQuery.of(context).size.width / 6,
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover
                                                  )
                                              ),
                                            );
                                          },
                                          imageUrl: snapshot.data[index]['episodes_images'][1],
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        CachedNetworkImage(
                                          imageBuilder: (context, imageProvider){
                                            return Container(
                                              height: MediaQuery.of(context).size.width / 6,
                                              width: MediaQuery.of(context).size.width / 6,
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover
                                                  )
                                              ),
                                            );
                                          },
                                          imageUrl: snapshot.data[index]['episodes_images'][2],
                                        ),
                                        CachedNetworkImage(
                                          imageBuilder: (context, imageProvider){
                                            return Container(
                                              height: MediaQuery.of(context).size.width / 6,
                                              width: MediaQuery.of(context).size.width / 6,
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover
                                                  )
                                              ),
                                            );
                                          },
                                          imageUrl: snapshot.data[index]['episodes_images'][3],
                                        )
                                      ],
                                    ),
                                  ],
                                ),),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Text("${snapshot.data[index]['playlist_name']}", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4,fontWeight: FontWeight.bold),),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }, itemCount: snapshot.data.length,),
                  ),
                ],
              ),
            );
          }catch(e){
            return Container(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text("${data['name']}", style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                        fontWeight: FontWeight.bold
                    )),
                  ),
                  Container(
                    width: double.infinity,
                    height: SizeConfig.blockSizeVertical * 25,
                    constraints:  BoxConstraints(
                        minHeight:
                        MediaQuery.of(context).size.height *
                            0.17),
                    child: ListView.builder(scrollDirection: Axis.horizontal,itemBuilder: (context, int index){
                      return Padding(
                        padding:
                        const EdgeInsets.fromLTRB(
                            15, 0, 0, 8),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.width / 3,
                                width: MediaQuery.of(context).size.width / 3,
                                decoration: BoxDecoration(
                                    color: Color(0xff222222)
                                ),
                              )
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(vertical: 5),
                              //   child: Text("${snapshot.data[index]['playlist_name']}", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4,fontWeight: FontWeight.bold),),
                              // )
                            ],
                          ),
                        ),
                      );
                    }, itemCount: snapshot.data.length,),
                  ),
                ],
              ),
            );
          }
        }else{
          return Container(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text("${data['name']}", style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.bold
                  )),
                ),
                Container(
                  width: double.infinity,
                  height: SizeConfig.blockSizeVertical * 25,
                  constraints:  BoxConstraints(
                      minHeight:
                      MediaQuery.of(context).size.height *
                          0.17),
                  child: ListView.builder(scrollDirection: Axis.horizontal,itemBuilder: (context, int index){
                    return Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                          15, 0, 0, 8),
                      child: Container(
                        width: MediaQuery.of(context).size.width / 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.width / 3,
                              width: MediaQuery.of(context).size.width / 3,
                              decoration: BoxDecoration(
                                  color: Color(0xff222222)
                              ),
                            )
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(vertical: 5),
                            //   child: Text("${snapshot.data[index]['playlist_name']}", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4,fontWeight: FontWeight.bold),),
                            // )
                          ],
                        ),
                      ),
                    );
                  }, itemCount: 10,),
                ),
              ],
            ),
          );
        }


      },
    );
  }
}


class SnippetWidget extends StatelessWidget {

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio(

    );
    prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";
    print(url); //TODO: Delete this print statement later

    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }

  }

  SharedPreferences prefs;

  CancelToken _cancel = CancelToken();
  final data;
  
  
  SnippetWidget(
  {@required this.data});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: generalisedApiCall(data['api']),
      builder: (context, snapshot){
        if(snapshot.hasData){
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text("${data['name']}", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 5, fontWeight: FontWeight.bold),),
                ),
                Container(
                  height: SizeConfig.blockSizeVertical * 32,
                  constraints:  BoxConstraints(
                      minHeight:
                      MediaQuery.of(context).size.height *
                          0.17),
                  child: ListView.builder(scrollDirection: Axis.horizontal,itemBuilder: (context, int index){
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: (){
                          Navigator.push(context, CupertinoPageRoute(builder: (context){
                            return SnippetStoryView(data: snapshot.data,  index: index,);
                          }));
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Stack(
                            children: [
                              Container(
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                      colors: [Colors.transparent, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter
                                  ),
                                ),

                                decoration: BoxDecoration(

                                  borderRadius: BorderRadius.circular(5),

                                  image: DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          snapshot.data[index]['podcast_image']),
                                      fit: BoxFit.cover),
                                ),
                              ),
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text("${snapshot.data[index]['episode_name']}", maxLines:  2, style: TextStyle(fontWeight: FontWeight.bold),),
                                        subtitle: Text("${snapshot.data[index]['podcast_name']}", maxLines: 1,),
                                      )


                                    ],
                                  ),
                                ),
                              )
                              // ClipRect(
                              //   child: BackdropFilter(
                              //     filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                              //     child: Container(
                              //       decoration: BoxDecoration(
                              //         borderRadius: BorderRadius.circular(10),
                              //       ),
                              //     ),
                              //   ),
                              // ),

                              ],

                          ),
                        ),
                      ),
                    );
                  }, itemCount: snapshot.data.length,),
                ),
              ],
            ),
          );
        }else{
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Text("${data['name']}", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 5, fontWeight: FontWeight.bold),),
              ),
              Container(
                height: SizeConfig.blockSizeVertical * 32,
                constraints:  BoxConstraints(
                    minHeight:
                    MediaQuery.of(context).size.height *
                        0.17),

                child: ListView.builder(scrollDirection: Axis.horizontal,itemBuilder: (context, int index){
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: (){
                        Navigator.push(context, CupertinoPageRoute(builder: (context){
                          return SnippetStoryView(data: snapshot.data,  index: index,);
                        }));
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Stack(
                          children: [
                            Container(
                              foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter
                                ),
                              ),

                              decoration: BoxDecoration(
                                color: Color(0xff222222),

                                borderRadius: BorderRadius.circular(5),


                              ),
                            ),

                            // ClipRect(
                            //   child: BackdropFilter(
                            //     filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                            //     child: Container(
                            //       decoration: BoxDecoration(
                            //         borderRadius: BorderRadius.circular(10),
                            //       ),
                            //     ),
                            //   ),
                            // ),

                          ],

                        ),
                      ),
                    ),
                  );
                }, itemCount: 10 ,),

              ),

            ],
          );
        }
      },
    );
  }
}

class SnippetStoryView extends StatefulWidget {

  final data;
  int index;

  SnippetStoryView({@required this.data, this.index});

  @override
  _SnippetStoryViewState createState() => _SnippetStoryViewState();
}

class _SnippetStoryViewState extends State<SnippetStoryView> {

  PageController _pageController ;


  AssetsAudioPlayer audioplayer = AssetsAudioPlayer();
  int currentIndex;

  @override
  void initState() {
    _pageController =
        PageController(viewportFraction: 1.0, keepPage: true, initialPage: widget.index);
    // TODO: implement initState
    super.initState();

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    audioplayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
          itemCount: widget.data.length,
          pageSnapping: true,
          controller: _pageController,

          itemBuilder: (context, int index) {
            currentIndex = index;
            return SwipeCard(
              clipObject: widget.data[index],
            );
          }),
    );
  }
}

class SeeMore extends StatelessWidget {

  final data;

 SeeMore({@required this.data});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}







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

  int followedPodPageNumber = 0;

  void getFollowedPodcasts() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/followedPodcasts?user_id=${prefs.getString('userId')}&page=$followedPodPageNumber";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        if (followedPodPageNumber == 0) {
          setState(() {
            favPodcast = jsonDecode(response.body)['podcasts'];
            followedPodPageNumber = followedPodPageNumber + 1;
          });
        } else {
          setState(() {
            favPodcast = favPodcast + jsonDecode(response.body)['podcasts'];
            followedPodPageNumber = followedPodPageNumber + 1;
          });
        }
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

  ScrollController _podcastScrollController;

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
//    getCurrentUser();

    getData();
    getFollowedPodcasts();
    getHiveFollowedEpisode();
    _podcastScrollController = ScrollController();

    _podcastScrollController.addListener(() {
      if (_podcastScrollController.position.pixels ==
          _podcastScrollController.position.maxScrollExtent) {
        print("pagination happening");
        getFollowedPodcasts();
      }
    });

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
    var episodeObject = Provider.of<PlayerChange>(context);
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
                                      Navigator.push(context,
                                          CupertinoPageRoute(
                                              builder: (context) {
                                        return CategoryView(categoryObject: v);
                                      }));
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: Text(
                        //     "Your Favourites",
                        //     textScaleFactor: mediaQueryData
                        //         .textScaleFactor
                        //         .clamp(0.5, 1.3)
                        //         .toDouble(),
                        //     style: TextStyle(
                        //       //    color: Color(0xffe8e8e8),
                        //         fontSize:
                        //         SizeConfig.safeBlockHorizontal *
                        //             7,
                        //         fontWeight: FontWeight.bold),
                        //   ),
                        // ),
                        favPodcast == null
                            ? Container(
                                width: double.infinity,
                                height: MediaQuery.of(context).size.height / 5,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _podcastScrollController,
                                  children: [
                                    for (int i = 0; i < 10; i++)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          child: Column(
                                            children: [
                                              Container(
                                                child: Icon(Icons.add),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Color(0xff222222),
                                                ),
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
                                                      CupertinoPageRoute(
                                                          builder: (context) =>
                                                              PodcastView(
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
                                              CupertinoPageRoute(
                                                  builder: (context) =>
                                                      EpisodeView(
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
                                                                        CupertinoPageRoute(
                                                                            builder: (context) =>
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
                                                                          CupertinoPageRoute(
                                                                              builder: (context) => Comments(
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
                                                                          CupertinoPageRoute(builder:
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
                                                                        //     CupertinoPageRoute(
                                                                        // der:
                                                                        //             (context) {
                                                                        //   return PDFviewer(
                                                                        //       episodeObject:
                                                                        //           v);
                                                                        // }));
                                                                      } else {
                                                                        List<Audio>
                                                                            playable =
                                                                            [];
                                                                        for (var v
                                                                            in hiveEpisodes) {
                                                                          playable
                                                                              .add(Audio.network(
                                                                            v['url'],
                                                                            metas:
                                                                                Metas(
                                                                              id: '${v['id']}',
                                                                              title: '${v['name']}',
                                                                              artist: '${v['author']}',
                                                                              album: '${v['podcast_name']}',
                                                                              // image: MetasImage.network('https://www.google.com')
                                                                              image: MetasImage.network('${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                                            ),
                                                                          ));
                                                                        }
                                                                        episodeObject.playList =
                                                                            playable;
                                                                        episodeObject.audioPlayer.open(
                                                                            Playlist(
                                                                                audios: episodeObject.playList,
                                                                                startIndex: hiveEpisodes.indexOf(v)),
                                                                            showNotification: true);
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
                                                                Icons.ios_share,
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

class PodcastViewBuilder extends StatefulWidget {

  var podcastData;


  PodcastViewBuilder(@required this.podcastData);

  @override
  _PodcastViewBuilderState createState() => _PodcastViewBuilderState();
}

class _PodcastViewBuilderState extends State<PodcastViewBuilder> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}






