import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/DatabaseFunctions/EpisodesBloc.dart';
import 'package:auditory/DatabaseFunctions/EpisodesProvider.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PlayerElements/Seekbar.dart';

enum PlayerState { stopped, playing, paused }

extension Pipe<T> on T {
  R pipe<R>(R f(T t)) => f(this);
}

class Player extends StatefulWidget {
  static const String id = "Player";

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  PlayerState playerState = PlayerState.playing;
  final _episodeBloc = EpisodeBloc();
  final _mp = EpisodesProvider.getInstance();
  RegExp htmlMatch = RegExp(r'(\w+)');
  ScrollController _controller;

  TextEditingController _commentsController;
  TextEditingController _replyController;
  Duration position;
  String comment;
  Duration duration;
  bool isSending = false;
  String displayPicture;
  String hiveToken;
  var comments = [];
  SharedPreferences pref;
  SharedPreferences prefs;
  var storedepisodes = [];
  var episodeContent;
  var episodeObject;

  bool isUpvoteLoading = false;

  void getInitialComments(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    getComments(episodeObject.episodeObject);
  }

  void getHiveToken() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      hiveToken = prefs.getString('access_token');
    });
  }

  void postReply(int commentId, String text, var episodeObject) async {
    setState(() {
      isSending = true;
    });
    String url = 'https://api.aureal.one/private/reply';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['text'] = text;
    map['comment_id'] = commentId;

    map['hive_username'] = prefs.getString('HiveUserName');

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);

    getComments(episodeObject);
    _replyController.clear();
    setState(() {
      isSending = false;
    });
  }

  void getComments(var episodeObject) async {
    String url =
        'https://api.aureal.one/public/getComments?episode_id=${episodeObject['id']}';
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          comments = jsonDecode(response.body)['comments'];
          displayPicture = prefs.getString('displayPicture');
        });
        print(comments);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      counter = counter + 1;
    });
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  void postComment(var episodeObject, String text) async {
    print("Starting the comment function");
    setState(() {
      isSending = true;
    });
    String url = 'https://api.aureal.one/private/comment';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = episodeObject['id'];
    map['text'] = text;
    if (episodeObject['permlink'] != null) {
      map['hive_username'] = prefs.getString('HiveUserName');
    }

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response);
    await getComments(episodeObject);
    _commentsController.clear();
    setState(() {
      isSending = false;
    });
  }

  int counter = 0;

  String hiveUsername;

  final List<StreamSubscription> _subscriptions = [];
  int progress = 0;

  var dominantColor;
  int hexOfRGBA(int r, int g, int b, {double opacity = 0.3}) {
    r = (r < 0) ? -r : r;
    g = (g < 0) ? -g : g;
    b = (b < 0) ? -b : b;
    opacity = (opacity < 0) ? -opacity : opacity;
    opacity = (opacity > 1) ? 500 : opacity * 500;
    r = (r > 255) ? 255 : r;
    g = (g > 255) ? 255 : g;
    b = (b > 255) ? 255 : b;
    int a = opacity.toInt();
    return int.parse(
        '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}');
  }

  void getColor(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    hiveUsername = prefs.getString('HiveUserName');

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
  void dispose() {
    super.dispose();
    // TODO: implement dispose
    print('Dispose Called//////////////////////////////////////////////');
    var episodeObject = Provider.of<PlayerChange>(context);
    episodeObject.dursaver.addToDatabase(
        episodeObject.episodeObject['id'],
        episodeObject.audioPlayer.currentPosition.valueWrapper.value,
        episodeObject
            .audioPlayer.realtimePlayingInfos.valueWrapper.value.duration);

    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    getColor(episodeObject.episodeObject['image'] == null
        ? episodeObject.episodeObject['podcast_image']
        : episodeObject.episodeObject['image']);
    if (counter < 1) {
      getComments(episodeObject.episodeObject);
    }

    print(episodeObject.episodeObject);

    _subscriptions
        .add(episodeObject.audioPlayer.playlistAudioFinished.listen((data) {
      print("playlistAudioFinished : $data");
    }));
    // _subscriptions
    //     .add(episodeObject.audioPlayer.((sessionId) {
    //   print("audioSessionId : $sessionId");
    // }));
    _subscriptions
        .add(AssetsAudioPlayer.addNotificationOpenAction((notification) {
      return false;
    }));

//    duration = Duration(seconds: episodeObject.episodeObject['duration']);
//    print(duration.toString());
    SizeConfig().init(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // print(episodeObject.episodeObject.toString());
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            // crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 13,
                    ),
                    CachedNetworkImage(
                      imageUrl: episodeObject.episodeObject['image'] == null
                          ? episodeObject.episodeObject['podcast_image']
                          : episodeObject.episodeObject['image'],
                      imageBuilder: (context, imageProvider) {
                        return Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                  image: imageProvider, fit: BoxFit.cover)),
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.width / 2,
                        );
                      },
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return EpisodeView(
                                episodeId: episodeObject.episodeObject['id']);
                          }));
                        },
                        child: Text(
                          '${episodeObject.episodeName}',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          textScaleFactor: 1.0,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: SizeConfig.blockSizeHorizontal * 4,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${episodeObject.episodeObject['author']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(FontAwesomeIcons.fighterJet),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: kSecondaryColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        height: 260,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 10),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FlatButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "0.25X",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.7)),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              FlatButton(
                                                onPressed: () {
                                                  // episodeObject
                                                  //     .audioPlayer
                                                  //     .setPlaySpeed(0.5);
                                                  Navigator.pop(context);
                                                },
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "0.5X",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.7)),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              FlatButton(
                                                onPressed: () {
                                                  // episodeObject
                                                  //     .audioPlayer
                                                  //     .setPlaySpeed(1.0);
                                                  Navigator.pop(context);
                                                },
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "1X",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.7)),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              FlatButton(
                                                onPressed: () {
                                                  // episodeObject
                                                  //     .audioPlayer
                                                  //     .setPlaySpeed(1.5);
                                                  Navigator.pop(context);
                                                },
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "1.5X",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.7)),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              FlatButton(
                                                onPressed: () {
                                                  // episodeObject
                                                  //     .audioPlayer
                                                  //     .setPlaySpeed(2.0);
                                                  Navigator.pop(context);
                                                },
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "2X",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.7)),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                            },
                          ),
                          episodeObject.episodeObject['permlink'] == null
                              ? SizedBox(
                                  width: 50,
                                )
                              : Container(
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          if (hiveUsername != null) {
                                            setState(() {
                                              isUpvoteLoading = true;
                                            });
                                            double _value = 50.0;
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      child: UpvoteEpisode(
                                                          permlink: episodeObject
                                                                  .episodeObject[
                                                              'permlink'],
                                                          episode_id: episodeObject
                                                                  .episodeObject[
                                                              'id']));
                                                }).then((value) async {
                                              print(value);
                                            });
                                            setState(() {
                                              if(episodeObject.ifVoted != true){
                                                episodeObject.ifVoted = true;
                                              }
                                            });
                                            setState(() {
                                              isUpvoteLoading = false;
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
                                          decoration: episodeObject.ifVoted ==
                                                  true
                                              ? BoxDecoration(
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        Color(0xff5bc3ef),
                                                        Color(0xff5d5da8)
                                                      ]),
                                                  borderRadius:
                                                      BorderRadius.circular(30))
                                              : BoxDecoration(
                                                  border: Border.all(
                                                      color: kSecondaryColor),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30)),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5, horizontal: 10),
                                            child: Row(
                                              children: [
                                                isUpvoteLoading == true
                                                    ? Container(
                                                        height: 17,
                                                        width: 18,
                                                        child: SpinKitPulse(
                                                          color: Colors.blue,
                                                        ),
                                                      )
                                                    : Icon(
                                                        FontAwesomeIcons
                                                            .chevronCircleUp,
                                                        size: 15,
                                                        // color:
                                                        //     Color(0xffe8e8e8),
                                                      ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Text(
                                                    episodeObject
                                                        .episodeObject['votes']
                                                        .toString(),
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        fontSize: 15
                                                        // color:
                                                        //     Color(0xffe8e8e8)
                                                        ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 15,
                                                  width: 10,
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                        left: BorderSide(
                                                      color: themeProvider
                                                                  .isLightTheme ==
                                                              false
                                                          ? Colors.white
                                                          : kPrimaryColor,
                                                    )),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4),
                                                  child: Text(
                                                    '\$${episodeObject.episodeObject['payout_value'].toString().split(' ')[0]}',
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                      fontSize: 15,

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
                                    ],
                                  ),
                                ),
                          IconButton(
                            onPressed: () {
                              share(episodeObject: episodeObject.episodeObject);
                            },
                            icon: Icon(FontAwesomeIcons.share),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              DraggableScrollableSheet(
                  initialChildSize: 0.32,
                  minChildSize: 0.32,
                  maxChildSize: 0.32,
                  builder: (context, controller) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          new BoxShadow(
                            color: Colors.black54.withOpacity(0.2),
                            blurRadius: 10.0,
                          ),
                        ],
                        color: themeProvider.isLightTheme == true
                            ? Colors.white
                            : Color(0xff222222),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        controller: controller,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: episodeObject.audioPlayer
                                    .builderRealtimePlayingInfos(
                                        builder: (context, infos) {
                                  if (infos == null) {
                                    return SizedBox(
                                      height: 0,
                                    );
                                  } else {
                                    return Seekbar(
                                      dominantColor: dominantColor,
                                      currentPosition: infos.currentPosition,
                                      duration: infos.duration,
                                      episodeName: episodeObject.episodeName,
                                      seekTo: (to) {
                                        episodeObject.audioPlayer.seek(to);
                                      },
                                    );
                                  }
                                }),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(
                                        Icons.replay_10,
                                        //  color: Colors.white,
                                        size: 40,
                                      ),
                                      onPressed: () {
                                        episodeObject.audioPlayer
                                            .seekBy(Duration(seconds: -10));
                                      },
                                    ),
                                    episodeObject.audioPlayer
                                        .builderRealtimePlayingInfos(
                                            builder: (context, infos) {
                                      if (infos == null) {
                                        return SpinKitPulse(
                                          color: Colors.white,
                                        );
                                      } else {
                                        if (infos.isBuffering == true) {
                                          return SpinKitCircle(
                                            size: 15,
                                            color: Colors.white,
                                          );
                                        } else {
                                          if (infos.isPlaying == true) {
                                            // return IconButton(
                                            //   highlightColor: Colors.blue,
                                            //   icon: Icon(
                                            //     Icons.pause,
                                            //     size: 40,
                                            //     color: themeProvider.isLightTheme == false
                                            //         ? Colors.white
                                            //         : kPrimaryColor,
                                            //     // color:
                                            //     //     Colors.black,
                                            //   ),
                                            //   onPressed: () {
                                            //     episodeObject.pause();
                                            //     setState(() {
                                            //       playerState = PlayerState.paused;
                                            //     });
                                            //   },
                                            // );
                                            return FloatingActionButton(
                                                child: Icon(Icons.pause),
                                                backgroundColor:
                                                    Color(dominantColor) == null
                                                        ? Colors.blue
                                                        : Color(dominantColor),
                                                onPressed: () {
                                                  episodeObject.pause();
                                                  setState(() {
                                                    playerState =
                                                        PlayerState.paused;
                                                  });
                                                });
                                          } else {
                                            return FloatingActionButton(
                                                backgroundColor:
                                                    Color(dominantColor) == null
                                                        ? Colors.blue
                                                        : Color(dominantColor),
                                                child: Icon(
                                                    Icons.play_arrow_rounded),
                                                onPressed: () {
                                                  // play(url);
                                                  episodeObject.resume();
                                                  setState(() {
                                                    playerState =
                                                        PlayerState.playing;
                                                  });
                                                });
                                            return IconButton(
                                              icon: Icon(
                                                Icons.play_arrow,
                                                size: 40, // color:
                                                color: themeProvider
                                                            .isLightTheme ==
                                                        false
                                                    ? Colors.white
                                                    : kPrimaryColor,
                                                //     Colors.black,
                                              ),
                                              onPressed: () {
//                                    play(url);
                                                episodeObject.resume();
                                                setState(() {
                                                  playerState =
                                                      PlayerState.playing;
                                                });
                                              },
                                            );
                                          }
                                        }
                                      }
                                    }),
                                    IconButton(
                                      icon: Icon(
                                        Icons.forward_10,
                                        //  color: Colors.white,
                                        size: 40,
                                      ),
                                      onPressed: () {
                                        episodeObject.audioPlayer.seekBy(
                                          Duration(seconds: 10),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 5),
              //   child: episodeObject.audioPlayer.builderRealtimePlayingInfos(
              //     builder: (context, infos) {
              //       if (infos == null) {
              //         return SizedBox(
              //           height: 0,
              //         );
              //       } else {
              //         return Seekbar(
              //           currentPosition: infos.currentPosition,
              //           duration: infos.duration,
              //           episodeName: episodeObject.episodeName,
              //           seekTo: (to) {
              //             episodeObject.audioPlayer.seek(to);
              //           },
              //         );
              //       }
              //     },
              //   ),
              // ),
            ],
          ),
        )
      ],
    );
    // return Scaffold(
    //     backgroundColor: Colors.transparent,
    //     body: Stack(
    //       children: [
    //         Center(
    //           child: ClipRect(
    //             child: BackdropFilter(
    //               filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
    //               child: Container(
    //                 width: double.infinity,
    //                 height: double.infinity,
    //                 decoration: new BoxDecoration(
    //                     color: Colors.black54.withOpacity(0.5)),
    //               ),
    //             ),
    //           ),
    //         ),
    //         Container(
    //           width: double.infinity,
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             children: [
    //               CachedNetworkImage(
    //                 imageUrl: episodeObject.episodeObject['image'] == null
    //                     ? episodeObject.episodeObject['podcast_image']
    //                     : episodeObject.episodeObject['image'],
    //                 imageBuilder: (context, imageProvider) {
    //                   return Container(
    //                     decoration: BoxDecoration(
    //                         borderRadius: BorderRadius.circular(10),
    //                         image: DecorationImage(
    //                             image: imageProvider, fit: BoxFit.cover)),
    //                     width: MediaQuery.of(context).size.width / 2,
    //                     height: MediaQuery.of(context).size.width / 2,
    //                   );
    //                 },
    //               ),
    //             ],
    //           ),
    //         )
    //       ],
    //     ));

//     The latest Player UI
//
//     return Scaffold(
//       body: Stack(children: [
//         Container(
//           height: MediaQuery.of(context).size.height,
//           decoration: BoxDecoration(
//               // color:  Color(dominantColor == null ? 0xff3a3a3a : dominantColor), ),
//               gradient: LinearGradient(colors: [
//             Color(dominantColor == null ? 0xff3a3a3a : dominantColor),
//             Colors.transparent
//           ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
//           child: episodeObject == null
//               ? Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Shimmer.fromColors(
//                     baseColor: themeProvider.isLightTheme == false
//                         ? kPrimaryColor
//                         : Colors.white,
//                     highlightColor: themeProvider.isLightTheme == false
//                         ? Color(0xff3a3a3a)
//                         : Colors.white,
//                   ))
//               : Column(
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.fromLTRB(25, 40, 25, 30),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           SizedBox(height: 15),
//                           GestureDetector(
//                             onTap: () {
//                               print(episodeObject.id);
//                               print(
//                                   episodeObject.episodeObject['podcast_image']);
//                               if (episodeObject.id != null)
//                                 Navigator.push(context,
//                                     MaterialPageRoute(builder: (context) {
//                                   return EpisodeView(
//                                     episodeId: episodeObject.id,
//                                   );
//                                 }));
//                             },
//                             child: Container(
//                                 margin: EdgeInsets.only(bottom: 30),
//                                 width: 200,
//                                 height: 200,
//                                 child: CachedNetworkImage(
//                                   imageBuilder: (context, imageProvider) {
//                                     return Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(10),
//                                         image: DecorationImage(
//                                             image: imageProvider,
//                                             fit: BoxFit.cover),
//                                       ),
//                                       height: MediaQuery.of(context).size.width,
//                                       width: MediaQuery.of(context).size.width,
//                                     );
//                                   },
//                                   imageUrl: episodeObject
//                                               .episodeObject['image'] ==
//                                           null
//                                       ? episodeObject
//                                           .episodeObject['podcast_image']
//                                       : episodeObject.episodeObject['image'],
//                                   memCacheHeight: MediaQuery.of(context)
//                                       .size
//                                       .height
//                                       .floor(),
//                                   errorWidget: (context, url, error) =>
//                                       Icon(Icons.error),
//                                 )),
//                           ),
//                           SizedBox(height: 1),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(
//                               '${episodeObject.episodeName}',
//                               textAlign: TextAlign.center,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(
//                               '${episodeObject.author}',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 10),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 5),
//                             child: episodeObject.audioPlayer
//                                 .builderRealtimePlayingInfos(
//                               builder: (context, infos) {
//                                 if (infos == null) {
//                                   return SizedBox(
//                                     height: 0,
//                                   );
//                                 } else {
//                                   return Seekbar(
//                                     currentPosition: infos.currentPosition,
//                                     duration: infos.duration,
//                                     episodeName: episodeObject.episodeName,
//                                     seekTo: (to) {
//                                       episodeObject.audioPlayer.seek(to);
//                                     },
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                           SizedBox(height: 5),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 5),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                               children: <Widget>[
//                                 IconButton(
//                                   icon: Icon(
//                                     Icons.replay_10,
//                                     //  color: Colors.white,
//                                     size: 40,
//                                   ),
//                                   onPressed: () {
//                                     episodeObject.audioPlayer
//                                         .seekBy(Duration(seconds: -10));
//                                   },
//                                 ),
//                                 CircleAvatar(
//                                   radius: 40,
//                                   // foregroundColor: Colors.white,
//                                   // backgroundColor: kSecondaryColor,
//                                   backgroundColor: Colors.transparent,
//                                   child: episodeObject.audioPlayer
//                                       .builderRealtimePlayingInfos(
//                                           builder: (context, infos) {
//                                     if (infos == null) {
//                                       return SpinKitPulse(
//                                         color: Colors.white,
//                                       );
//                                     } else {
//                                       if (infos.isBuffering == true) {
//                                         return SpinKitCircle(
//                                           size: 15,
//                                           color: Colors.white,
//                                         );
//                                       } else {
//                                         if (infos.isPlaying == true) {
//                                           return IconButton(
//                                             icon: Icon(
//                                               Icons.pause,
//                                               size: 40,
//                                               color:
//                                                   themeProvider.isLightTheme ==
//                                                           false
//                                                       ? Colors.white
//                                                       : kPrimaryColor,
//                                               // color:
//                                               //     Colors.black,
//                                             ),
//                                             onPressed: () {
//                                               episodeObject.pause();
//                                               setState(() {
//                                                 playerState =
//                                                     PlayerState.paused;
//                                               });
//                                             },
//                                           );
//                                         } else {
//                                           return IconButton(
//                                             icon: Icon(
//                                               Icons.play_arrow,
//                                               size: 40, // color:
//                                               color:
//                                                   themeProvider.isLightTheme ==
//                                                           false
//                                                       ? Colors.white
//                                                       : kPrimaryColor,
//                                               //     Colors.black,
//                                             ),
//                                             onPressed: () {
// //                                    play(url);
//                                               episodeObject.resume();
//                                               setState(() {
//                                                 playerState =
//                                                     PlayerState.playing;
//                                               });
//                                             },
//                                           );
//                                         }
//                                       }
//                                     }
//                                   }),
//                                 ),
//                                 IconButton(
//                                   icon: Icon(
//                                     Icons.forward_10,
//                                     //  color: Colors.white,
//                                     size: 40,
//                                   ),
//                                   onPressed: () {
//                                     episodeObject.audioPlayer.seekBy(
//                                       Duration(seconds: 10),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                           SizedBox(height: 30),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 35,
//                                 height: 35,
//                                 decoration: new BoxDecoration(
//                                   // color: Colors.white,
//                                   border: Border.all(
//                                     color: themeProvider.isLightTheme == false
//                                         ? Colors.white
//                                         : kPrimaryColor,
//                                   ),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: IconButton(
//                                   iconSize: 18,
//                                   icon: Icon(
//                                     Icons.bolt,
//                                     //     color: Colors.white,
//                                   ),
//                                   onPressed: () {
//                                     showDialog(
//                                         context: context,
//                                         builder: (context) {
//                                           return Dialog(
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(30),
//                                             ),
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 color: kSecondaryColor,
//                                                 borderRadius:
//                                                     BorderRadius.circular(10),
//                                               ),
//                                               height: 260,
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 15,
//                                                         vertical: 10),
//                                                 child: Column(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "0.25X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(0.5);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "0.5X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(1.0);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "1X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(1.5);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "1.5X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(2.0);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "2X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           );
//                                         });
//                                   },
//                                 ),
//                               ),
//                               episodeObject.episodeObject['permlink'] == null
//                                   ? SizedBox(
//                                       width: 50,
//                                     )
//                                   : Container(
//                                       child: Row(
//                                         children: [
//                                           InkWell(
//                                             onTap: () async {
//                                               if (prefs.getString(
//                                                       'HiveUserName') !=
//                                                   null) {
//                                                 setState(() {
//                                                   episodeObject.episodeObject[
//                                                       'isLoading'] = true;
//                                                 });
//                                                 double _value = 50.0;
//                                                 showDialog(
//                                                     context: context,
//                                                     builder: (context) {
//                                                       return Dialog(
//                                                           backgroundColor: Colors
//                                                               .transparent,
//                                                           child: UpvoteEpisode(
//                                                               permlink: episodeObject
//                                                                       .episodeObject[
//                                                                   'permlink'],
//                                                               episode_id:
//                                                                   episodeObject
//                                                                           .episodeObject[
//                                                                       'id']));
//                                                     }).then((value) async {
//                                                   print(value);
//                                                 });
//                                                 setState(() {
//                                                   episodeObject.episodeObject[
//                                                           'ifVoted'] =
//                                                       !episodeObject
//                                                               .episodeObject[
//                                                           'ifVoted'];
//                                                 });
//                                                 setState(() {
//                                                   episodeObject.episodeObject[
//                                                       'isLoading'] = false;
//                                                 });
//                                               } else {
//                                                 showBarModalBottomSheet(
//                                                     context: context,
//                                                     builder: (context) {
//                                                       return HiveDetails();
//                                                     });
//                                               }
//                                             },
//                                             child: Container(
//                                               decoration: episodeObject
//                                                               .episodeObject[
//                                                           'ifVoted'] ==
//                                                       true
//                                                   ? BoxDecoration(
//                                                       gradient: LinearGradient(
//                                                           colors: [
//                                                             Color(0xff5bc3ef),
//                                                             Color(0xff5d5da8)
//                                                           ]),
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               30))
//                                                   : BoxDecoration(
//                                                       border: Border.all(
//                                                           color:
//                                                               kSecondaryColor),
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               30)),
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         vertical: 5,
//                                                         horizontal: 5),
//                                                 child: Row(
//                                                   children: [
//                                                     episodeObject.episodeObject[
//                                                                 'isLoading'] ==
//                                                             true
//                                                         ? Container(
//                                                             height: 17,
//                                                             width: 18,
//                                                             child: SpinKitPulse(
//                                                               color:
//                                                                   Colors.blue,
//                                                             ),
//                                                           )
//                                                         : Icon(
//                                                             FontAwesomeIcons
//                                                                 .chevronCircleUp,
//                                                             size: 15,
//                                                             // color:
//                                                             //     Color(0xffe8e8e8),
//                                                           ),
//                                                     Padding(
//                                                       padding: const EdgeInsets
//                                                               .symmetric(
//                                                           horizontal: 8),
//                                                       child: Text(
//                                                         episodeObject
//                                                             .episodeObject[
//                                                                 'votes']
//                                                             .toString(),
//                                                         textScaleFactor: 1.0,
//                                                         style: TextStyle(
//                                                             fontSize: 15
//                                                             // color:
//                                                             //     Color(0xffe8e8e8)
//                                                             ),
//                                                       ),
//                                                     ),
//                                                     Container(
//                                                       height: 15,
//                                                       width: 10,
//                                                       decoration: BoxDecoration(
//                                                         border: Border(
//                                                             left: BorderSide(
//                                                           color: themeProvider
//                                                                       .isLightTheme ==
//                                                                   false
//                                                               ? Colors.white
//                                                               : kPrimaryColor,
//                                                         )),
//                                                       ),
//                                                     ),
//                                                     Padding(
//                                                       padding:
//                                                           const EdgeInsets.only(
//                                                               right: 4),
//                                                       child: Text(
//                                                         '\$${episodeObject.episodeObject['payout_value'].toString().split(' ')[0]}',
//                                                         textScaleFactor: 1.0,
//                                                         style: TextStyle(
//                                                           fontSize: 15,
//
//                                                           // color:
//                                                           //     Color(0xffe8e8e8)
//                                                         ),
//                                                       ),
//                                                     )
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                               // GestureDetector(
//                               //   onTap: () {
//                               //     startDownload();
//                               //     setState(() {
//                               //       _loading = !_loading;
//                               //       _updateProgress();
//                               //     });
//                               //   },
//                               //   child: Container(
//                               //       padding:
//                               //       EdgeInsets.all(15.0),
//                               //       child: _loading
//                               //           ? Column(
//                               //         mainAxisAlignment:
//                               //         MainAxisAlignment
//                               //             .center,
//                               //         children: <Widget>[
//                               //           CircularProgressIndicator(
//                               //             value:
//                               //             _progressValue,
//                               //           ),
//                               //           Text(
//                               //               '${(_progressValue * 100).round()}%'),
//                               //         ],
//                               //       )
//                               //           : Icon(
//                               //           Icons
//                               //               .arrow_circle_down,
//                               //           color: isDownloading ==
//                               //               true
//                               //               ? Color(
//                               //               0xff5d5da8)
//                               //               : Color(
//                               //               0xff5bc3ef))),
//                               // )
//                               Container(
//                                 width: 35,
//                                 height: 35,
//                                 decoration: new BoxDecoration(
//                                   // color: Colors.white,
//                                   border: Border.all(
//                                     color: themeProvider.isLightTheme == false
//                                         ? Colors.white
//                                         : kPrimaryColor,
//                                   ),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: IconButton(
//                                   iconSize: 18,
//                                   icon: Icon(
//                                     Icons.bolt,
//                                     //     color: Colors.white,
//                                   ),
//                                   onPressed: () {
//                                     showDialog(
//                                         context: context,
//                                         builder: (context) {
//                                           return Dialog(
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(30),
//                                             ),
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 color: kSecondaryColor,
//                                                 borderRadius:
//                                                     BorderRadius.circular(10),
//                                               ),
//                                               height: 260,
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 15,
//                                                         vertical: 10),
//                                                 child: Column(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "0.25X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(0.5);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "0.5X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(1.0);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "1X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(1.5);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "1.5X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     FlatButton(
//                                                       onPressed: () {
//                                                         // episodeObject
//                                                         //     .audioPlayer
//                                                         //     .setPlaySpeed(2.0);
//                                                         Navigator.pop(context);
//                                                       },
//                                                       child: Row(
//                                                         children: [
//                                                           Text(
//                                                             "2X",
//                                                             textScaleFactor:
//                                                                 0.75,
//                                                             style: TextStyle(
//                                                                 color: Colors
//                                                                     .white
//                                                                     .withOpacity(
//                                                                         0.7)),
//                                                           )
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           );
//                                         });
//                                   },
//                                 ),
//                               ),
//                             ],
//                           )
//                         ],
//                       ),
//                     ),
//                     // for (var v in comments)
//                   ],
//                 ),
//         ),
//       ]),
//       // bottomSheet: GestureDetector(
//       //   onTap: () async {
//       //     print(episodeObject.episodeObject['comments']);
//       //     // if (pref.getString('HiveUserName') = null) {
//       //     Navigator.push(context, MaterialPageRoute(builder: (context) {
//       //       return Comments(
//       //         episodeObject: episodeObject.episodeObject,
//       //       );
//       //     }));
//       //   },
//       //   child: Container(
//       //     decoration: BoxDecoration(
//       //         // color: Color(dominantColor == null ? 0xff3a3a3a : dominantColor),
//       //         ), //color: Colors.white,
//       //     child: Padding(
//       //       padding: const EdgeInsets.all(5.0),
//       //       child: Row(
//       //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       //         // mainAxisAlignment: MainAxisAlignment.start,
//       //         crossAxisAlignment: CrossAxisAlignment.center,
//       //         children: [
//       //           Row(
//       //             mainAxisSize: MainAxisSize.min,
//       //             children: [
//       //               Padding(
//       //                 padding: const EdgeInsets.only(left: 50),
//       //                 child: Icon(
//       //                   Icons.mode_comment_outlined,
//       //                   size: 30,
//       //                 ),
//       //               ),
//       //               SizedBox(
//       //                 width: 5,
//       //               ),
//       //               Text(
//       //                 '${episodeObject.episodeObject['comments_count'].toString()}',
//       //                 textScaleFactor: 1.0,
//       //               ),
//       //             ],
//       //           ),
//       //           Padding(
//       //               padding: const EdgeInsets.only(right: 50, bottom: 20),
//       //               child: IconButton(
//       //                 icon: Icon(
//       //                   Icons.keyboard_arrow_up_outlined,
//       //                   size: 50,
//       //                   //     color: Colors.white,
//       //                 ),
//       //                 onPressed: () {},
//       //               ))
//       //         ],
//       //       ),
//       //     ),
//       //   ),
//       // ),
//     );
  }
}

//     return Scaffold(
//       body: Stack(
//         children: [
//           GestureDetector(
//             onTap: (){
//               print(episodeObject.id);
//               if( episodeObject.id!= null)
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (context) {
//                       return EpisodeView(
//                         episodeId: episodeObject.id,
//                       );
//                     }));
//
//             },
//             child: Container(
//               child: Column(
//                 children: [
//                   Expanded(
//                   child:  CachedNetworkImage(
//                   imageBuilder:
//                   (context, imageProvider) {
//             return Container(
//             decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
//             ),
//             height: MediaQuery.of(context).size.width,
//             width: MediaQuery.of(context).size.width,
//             );
//             },
//               imageUrl: episodeObject.episodeObject['image'] == null
//                   ? episodeObject.episodeObject['podcast_image']
//                   : episodeObject.episodeObject['image'],
//
//
//               memCacheHeight: MediaQuery.of(context)
//                   .size
//                   .height
//                   .floor(),
//
//               errorWidget: (context, url, error) =>
//                   Icon(Icons.error),
//             ),),
//
//
//
//                   Expanded(
//                     child: Container(),
//                   )
//                 ],
//               ),
//             ),
//           ),
//           SafeArea(
//             child: DraggableScrollableSheet(
//                 initialChildSize: 0.5,
//                 minChildSize: 0.5,
//                 maxChildSize: 1.0,
//                 builder: (BuildContext context, ScrollController controller) {
//                   return Container(
//                     child: Scaffold(
//                       resizeToAvoidBottomInset: true,
//                       body: Stack(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(top: 20),
//                             child: ListView(
//                               controller: controller,
//                               children: [
//                                 SizedBox(
//                                   height: SizeConfig.screenHeight / 5.5,
//                                 ),
//                                 ListTile(
//                                   onTap: () {
//                                     showModalBottomSheet(
//                                         //   backgroundColor: kSecondaryColor,
//                                         context: context,
//                                         builder: (context) {
//                                           return Comments(
//                                             episodeObject:
//                                                 episodeObject.episodeObject,
//                                           );
//                                         });
//                                   },
//                                   leading: CircleAvatar(
//                                     backgroundImage: CachedNetworkImageProvider(
//                                         prefs.getString('displayPicture') ==
//                                                 null
//                                             ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
//                                             : prefs
//                                                 .getString('displayPicture')),
//                                   ),
//                                   title: Text(
//                                     "Add a public comment",
//                                     textScaleFactor: 0.75,
//                                     style: TextStyle(),
//                                   ),
//                                 ),
//                                 for (var v in comments)
//                                   Column(
//                                     children: [
//                                       ListTile(
//                                         leading: CircleAvatar(
//                                           backgroundImage:
//                                               CachedNetworkImageProvider(v[
//                                                           'user_image'] ==
//                                                       null
//                                                   ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
//                                                   : v['user_image']),
//                                         ),
//                                         title: Text(
//                                           '${v['author']}',
//                                           textScaleFactor: 0.75,
//                                         ),
//                                         subtitle: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Padding(
//                                               padding: const EdgeInsets.only(
//                                                   bottom: 5),
//                                               child: Text(
//                                                 "${v['text']}",
//                                                 textScaleFactor: 0.75,
//                                               ),
//                                             ),
//                                             Row(
//                                               children: [
//                                                 GestureDetector(
//                                                   onTap: () {
//                                                     showModalBottomSheet(
//                                                         context: context,
//                                                         builder: (context) {
//                                                           return ListTile(
//                                                             leading: InkWell(
//                                                               onTap: () {
//                                                                 Navigator.pop(
//                                                                     context);
//                                                               },
//                                                               child: Icon(
//                                                                 Icons.close,
//                                                               ),
//                                                             ),
//                                                             title: Column(
//                                                               mainAxisAlignment:
//                                                                   MainAxisAlignment
//                                                                       .start,
//                                                               children: [
//                                                                 TextField(
//                                                                     controller:
//                                                                         _replyController,
//                                                                     autofocus:
//                                                                         true,
//                                                                     maxLines:
//                                                                         10,
//                                                                     minLines:
//                                                                         1),
//                                                               ],
//                                                             ),
//                                                             trailing: InkWell(
//                                                               onTap: () {
//                                                                 postReply(
//                                                                     v['id'],
//                                                                     _replyController
//                                                                         .text,
//                                                                     episodeObject
//                                                                         .episodeObject);
//                                                                 _commentsController
//                                                                     .clear();
//                                                               },
//                                                               child: Icon(
//                                                                 Icons.send,
//                                                               ),
//                                                             ),
//                                                           );
//                                                         });
//                                                   },
//                                                   child: Text(
//                                                     "Reply",
//                                                     textScaleFactor: 0.75,
// // style:TextStyle(color:Colors.blue)
//                                                   ),
//                                                 )
//                                               ],
//                                             )
//                                           ],
//                                         ),
//                                         trailing: IconButton(
//                                           onPressed: () {
//                                             showDialog(
//                                                 context: context,
//                                                 builder: (context) {
//                                                   return Dialog(
//                                                       backgroundColor:
//                                                           Colors.transparent,
//                                                       child: UpvoteComment(
//                                                         comment_id:
//                                                             v['id'].toString(),
//                                                       ));
//                                                 }).then((value) async {
//                                               print(value);
//                                             });
//                                           },
//                                           icon: Icon(
//                                             FontAwesomeIcons.chevronCircleUp,
//                                           ),
//                                         ),
//                                         isThreeLine: true,
//                                       ),
//                                       v['comments'] == null
//                                           ? SizedBox(
//                                               height: 0,
//                                             )
//                                           : ExpansionTile(
//                                               // backgroundColor: Colors.transparent,
//                                               trailing: SizedBox(
//                                                 width: 0,
//                                               ),
//                                               title: Align(
//                                                 alignment: Alignment.centerLeft,
//                                                 child: Text(
//                                                   "View replies",
//                                                   textScaleFactor: 0.75,
//                                                   style: TextStyle(
//                                                     fontSize: SizeConfig
//                                                             .safeBlockHorizontal *
//                                                         3,
//                                                     // color: Colors.grey,
//                                                   ),
//                                                 ),
//                                               ),
//                                               children: <Widget>[
//                                                 for (var c in v['comments'])
//                                                   Align(
//                                                     alignment:
//                                                         Alignment.centerLeft,
//                                                     child: Padding(
//                                                       padding:
//                                                           const EdgeInsets.only(
//                                                               bottom: 10),
//                                                       child: Container(
//                                                         child: Row(
//                                                           children: <Widget>[
//                                                             CircleAvatar(
//                                                               radius: 20,
//                                                               backgroundImage: v[
//                                                                           'user_image'] ==
//                                                                       null
//                                                                   ? AssetImage(
//                                                                       'assets/images/person.png')
//                                                                   : NetworkImage(
//                                                                       v['user_image']),
//                                                             ),
//                                                             SizedBox(width: 10),
//                                                             Expanded(
//                                                               child: Row(
//                                                                 mainAxisAlignment:
//                                                                     MainAxisAlignment
//                                                                         .spaceBetween,
//                                                                 children: [
//                                                                   Column(
//                                                                     crossAxisAlignment:
//                                                                         CrossAxisAlignment
//                                                                             .start,
//                                                                     children: <
//                                                                         Widget>[
//                                                                       Text(
//                                                                         '${c['author']}',
//                                                                         textScaleFactor:
//                                                                             1.0,
//                                                                         style: TextStyle(
//                                                                             fontWeight:
//                                                                                 FontWeight.w600),
//                                                                       ),
//                                                                       Text(
//                                                                         '${c['text']}',
//                                                                         textScaleFactor:
//                                                                             1.0,
//                                                                         style: TextStyle(
//                                                                             fontWeight:
//                                                                                 FontWeight.normal),
//                                                                       ),
//                                                                       Row(
//                                                                         children: <
//                                                                             Widget>[
//                                                                           GestureDetector(
//                                                                             onTap:
//                                                                                 () {
//                                                                               showModalBottomSheet(
//                                                                                   context: context,
//                                                                                   builder: (context) {
//                                                                                     return ListTile(
//                                                                                       leading: InkWell(
//                                                                                         onTap: () {
//                                                                                           Navigator.pop(context);
//                                                                                         },
//                                                                                         child: Icon(
//                                                                                           Icons.close,
//                                                                                         ),
//                                                                                       ),
//                                                                                       title: Column(
//                                                                                         mainAxisAlignment: MainAxisAlignment.start,
//                                                                                         children: [
//                                                                                           TextField(controller: _replyController, autofocus: true, maxLines: 10, minLines: 1),
//                                                                                         ],
//                                                                                       ),
//                                                                                       trailing: InkWell(
//                                                                                         onTap: () {
//                                                                                           postReply(c['id'], _replyController.text, episodeObject.episodeObject);
//                                                                                           _commentsController.clear();
//                                                                                           //  postComment;
//                                                                                         },
//                                                                                         child: Icon(
//                                                                                           Icons.send,
//                                                                                         ),
//                                                                                       ),
//                                                                                     );
//                                                                                   });
//                                                                             },
//                                                                             child:
//                                                                                 Text(
//                                                                               "Reply",
//                                                                               textScaleFactor: 1.0,
//                                                                             ),
//                                                                           )
//                                                                         ],
//                                                                       )
//                                                                     ],
//                                                                   ),
//                                                                   IconButton(
//                                                                     onPressed:
//                                                                         () {
//                                                                       showDialog(
//                                                                           context:
//                                                                               context,
//                                                                           builder:
//                                                                               (context) {
//                                                                             return Dialog(
//                                                                                 backgroundColor: Colors.transparent,
//                                                                                 child: UpvoteComment(
//                                                                                   comment_id: v['id'].toString(),
//                                                                                 ));
//                                                                           }).then((value) async {
//                                                                         print(
//                                                                             value);
//                                                                       });
//                                                                     },
//                                                                     icon: Icon(
//                                                                       FontAwesomeIcons
//                                                                           .chevronCircleUp,
//                                                                     ),
//                                                                   )
//                                                                 ],
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   )
//                                               ],
//                                             )
//                                     ],
//                                   )
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Container(
//                                   height: SizeConfig.screenHeight / 5,
//                                   width: double.infinity,
//                                   //color: Colors.white,
//                                   child: Container(
//                                     // color: kSecondaryColor,
//                                     child: Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.start,
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: <Widget>[
//                                           Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                                 vertical: 5),
//                                             child: episodeObject.audioPlayer
//                                                 .builderRealtimePlayingInfos(
//                                               builder: (context, infos) {
//                                                 if (infos == null) {
//                                                   return SizedBox(
//                                                     height: 0,
//                                                   );
//                                                 } else {
//                                                   return Seekbar(
//                                                     currentPosition:
//                                                         infos.currentPosition,
//                                                     duration: infos.duration,
//                                                     episodeName: episodeObject
//                                                         .episodeName,
//                                                     seekTo: (to) {
//                                                       episodeObject.audioPlayer
//                                                           .seek(to);
//                                                     },
//                                                   );
//                                                 }
//                                               },
//                                             ),
//                                           ),
//                                           Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                                 vertical: 5),
//                                             child: Row(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.center,
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.spaceEvenly,
//                                               children: <Widget>[
//                                                 CircleAvatar(
//                                                   radius: 20,
//                                                   foregroundColor: Colors.white,
//                                                   backgroundColor:
//                                                       kSecondaryColor,
//                                                   //      backgroundColor: Colors.white,
//                                                   child: IconButton(
//                                                     icon: Icon(
//                                                       FontAwesomeIcons.bolt,
//                                                       size: 16,
//                                                       //  color: Colors.black,
//                                                     ),
//                                                     onPressed: () {
//                                                       showDialog(
//                                                           context: context,
//                                                           builder: (context) {
//                                                             return Dialog(
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             30),
//                                                               ),
//                                                               child: Container(
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   color:
//                                                                       kSecondaryColor,
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               10),
//                                                                 ),
//                                                                 height: 260,
//                                                                 child: Padding(
//                                                                   padding: const EdgeInsets
//                                                                           .symmetric(
//                                                                       horizontal:
//                                                                           15,
//                                                                       vertical:
//                                                                           10),
//                                                                   child: Column(
//                                                                     mainAxisAlignment:
//                                                                         MainAxisAlignment
//                                                                             .spaceBetween,
//                                                                     crossAxisAlignment:
//                                                                         CrossAxisAlignment
//                                                                             .start,
//                                                                     children: [
//                                                                       FlatButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           // episodeObject
//                                                                           //     .audioPlayer
//                                                                           //     .setPlaySpeed(0.25);
//                                                                           Navigator.pop(
//                                                                               context);
//                                                                         },
//                                                                         child:
//                                                                             Row(
//                                                                           children: [
//                                                                             Text(
//                                                                               "0.25X",
//                                                                               textScaleFactor: 0.75,
//                                                                               style: TextStyle(color: Colors.white.withOpacity(0.7)),
//                                                                             )
//                                                                           ],
//                                                                         ),
//                                                                       ),
//                                                                       FlatButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           // episodeObject
//                                                                           //     .audioPlayer
//                                                                           //     .setPlaySpeed(0.5);
//                                                                           Navigator.pop(
//                                                                               context);
//                                                                         },
//                                                                         child:
//                                                                             Row(
//                                                                           children: [
//                                                                             Text(
//                                                                               "0.5X",
//                                                                               textScaleFactor: 0.75,
//                                                                               style: TextStyle(color: Colors.white.withOpacity(0.7)),
//                                                                             )
//                                                                           ],
//                                                                         ),
//                                                                       ),
//                                                                       FlatButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           // episodeObject
//                                                                           //     .audioPlayer
//                                                                           //     .setPlaySpeed(1.0);
//                                                                           Navigator.pop(
//                                                                               context);
//                                                                         },
//                                                                         child:
//                                                                             Row(
//                                                                           children: [
//                                                                             Text(
//                                                                               "1X",
//                                                                               textScaleFactor: 0.75,
//                                                                               style: TextStyle(color: Colors.white.withOpacity(0.7)),
//                                                                             )
//                                                                           ],
//                                                                         ),
//                                                                       ),
//                                                                       FlatButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           // episodeObject
//                                                                           //     .audioPlayer
//                                                                           //     .setPlaySpeed(1.5);
//                                                                           Navigator.pop(
//                                                                               context);
//                                                                         },
//                                                                         child:
//                                                                             Row(
//                                                                           children: [
//                                                                             Text(
//                                                                               "1.5X",
//                                                                               textScaleFactor: 0.75,
//                                                                               style: TextStyle(color: Colors.white.withOpacity(0.7)),
//                                                                             )
//                                                                           ],
//                                                                         ),
//                                                                       ),
//                                                                       FlatButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           // episodeObject
//                                                                           //     .audioPlayer
//                                                                           //     .setPlaySpeed(2.0);
//                                                                           Navigator.pop(
//                                                                               context);
//                                                                         },
//                                                                         child:
//                                                                             Row(
//                                                                           children: [
//                                                                             Text(
//                                                                               "2X",
//                                                                               textScaleFactor: 0.75,
//                                                                               style: TextStyle(color: Colors.white.withOpacity(0.7)),
//                                                                             )
//                                                                           ],
//                                                                         ),
//                                                                       ),
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             );
//                                                           });
//                                                     },
//                                                   ),
//                                                 ),
//                                                 IconButton(
//                                                   icon: Icon(
//                                                     Icons.replay_10,
//                                                     //  color: Colors.white,
//                                                     size: 20,
//                                                   ),
//                                                   onPressed: () {
//                                                     episodeObject.audioPlayer
//                                                         .seekBy(Duration(
//                                                             seconds: -10));
//                                                   },
//                                                 ),
//                                                 CircleAvatar(
//                                                   radius: 20,
//                                                   foregroundColor: Colors.white,
//                                                   backgroundColor:
//                                                       kSecondaryColor,
//                                                   //   backgroundColor: Colors.white,
//                                                   child: episodeObject
//                                                       .audioPlayer
//                                                       .builderRealtimePlayingInfos(
//                                                           builder:
//                                                               (context, infos) {
//                                                     if (infos == null) {
//                                                       return SpinKitPulse(
//                                                         color: Colors.white,
//                                                       );
//                                                     } else {
//                                                       if (infos.isBuffering ==
//                                                           true) {
//                                                         return SpinKitCircle(
//                                                           size: 16,
//                                                           color: Colors.white,
//                                                         );
//                                                       } else {
//                                                         if (infos.isPlaying ==
//                                                             true) {
//                                                           return IconButton(
//                                                             icon: Icon(
//                                                               Icons.pause,
//                                                               // color:
//                                                               //     Colors.black,
//                                                             ),
//                                                             onPressed: () {
//                                                               episodeObject
//                                                                   .pause();
//                                                               setState(() {
//                                                                 playerState =
//                                                                     PlayerState
//                                                                         .paused;
//                                                               });
//                                                             },
//                                                           );
//                                                         } else {
//                                                           return IconButton(
//                                                             icon: Icon(
//                                                               Icons.play_arrow,
//                                                               // color:
//                                                               //     Colors.black,
//                                                             ),
//                                                             onPressed: () {
// //                                    play(url);
//                                                               episodeObject
//                                                                   .resume();
//                                                               setState(() {
//                                                                 playerState =
//                                                                     PlayerState
//                                                                         .playing;
//                                                               });
//                                                             },
//                                                           );
//                                                         }
//                                                       }
//                                                     }
//                                                   }),
//                                                 ),
//                                                 IconButton(
//                                                   icon: Icon(
//                                                     Icons.forward_10,
//                                                     //  color: Colors.white,
//                                                     size: 20,
//                                                   ),
//                                                   onPressed: () {
//                                                     episodeObject.audioPlayer
//                                                         .seekBy(
//                                                       Duration(seconds: 10),
//                                                     );
//                                                   },
//                                                 ),
//                                                 // hiveToken == null
//                                                 //     ? SizedBox(
//                                                 //         width: 50,
//                                                 //       )
//                                                 //     :
//                                                 CircleAvatar(
//                                                   radius: 20,
//                                                   foregroundColor: Colors.white,
//                                                   backgroundColor:
//                                                       kSecondaryColor,
//                                                   // backgroundColor:
//                                                   //     Color(0xff37a1f7),
//                                                   child: IconButton(
//                                                     icon: Center(
//                                                       child: Icon(
//                                                         FontAwesomeIcons
//                                                             .chevronCircleUp,
//                                                         size: 16,
//                                                         //     color: Colors.black,
//                                                       ),
//                                                     ),
//                                                     onPressed: () {
//                                                       Fluttertoast.showToast(
//                                                           msg: 'Upvote done');
//                                                       if (episodeObject
//                                                               .permlink ==
//                                                           null) {
//                                                       } else {
//                                                         showDialog(
//                                                             context: context,
//                                                             builder: (context) {
//                                                               return Dialog(
//                                                                   backgroundColor:
//                                                                       Colors
//                                                                           .transparent,
//                                                                   child: UpvoteEpisode(
//                                                                       episode_id:
//                                                                           episodeObject
//                                                                               .id,
//                                                                       permlink:
//                                                                           episodeObject
//                                                                               .permlink));
//                                                             }).then((value) async {
//                                                           print(value);
//                                                         });
//
//                                                         // upvoteEpisode(
//                                                         //     episode_id:
//                                                         //         episodeObject
//                                                         //             .id,
//                                                         //     permlink:
//                                                         //         episodeObject
//                                                         //             .permlink);
//                                                       }
//                                                     },
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ]),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//           )
//         ],
//       ),
//     );
//   }
// }

Widget buildSheet({
  @required num headerHeight,
  @required num fullHeight,
  @required Widget child,
}) {
  final fraction = headerHeight / fullHeight;

  return DraggableScrollableSheet(
    initialChildSize: fraction,
    minChildSize: fraction,
    builder: (_, scrollController) {
      return SingleChildScrollView(
        controller: scrollController,
        child: SizedBox(
          height: fullHeight,
          child: child,
        ),
      );
    },
  );
}

class MClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: min(size.width, size.height) / 2);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    // TODO: implement shouldReclip
    return true;
  }
}
