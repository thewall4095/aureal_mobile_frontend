import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
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

  SharedPreferences prefs;

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

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    _controller = ScrollController();

    // TODO: implement initState

    getHiveToken();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    print('Dispose Called//////////////////////////////////////////////');
    var episodeObject = Provider.of<PlayerChange>(context);
    episodeObject.dursaver.addToDatabase(episodeObject.episodeObject['id'],
        episodeObject.audioPlayer.currentPosition.valueWrapper.value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);

    if (counter < 1) {
      getComments(episodeObject.episodeObject);
    }

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

    return Scaffold(
      body: Stack(
        children: [
          Container(
            child: Column(
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: episodeObject.episodeObject['image'] == null
                        ? episodeObject.episodeObject['podcast_image']
                        : episodeObject.episodeObject['image'],
                  ),
                ),
                Expanded(
                  child: Container(),
                )
              ],
            ),
          ),
          SafeArea(
            child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.5,
                maxChildSize: 1.0,
                builder: (BuildContext context, ScrollController controller) {
                  return Container(
                    child: Scaffold(
                      resizeToAvoidBottomInset: true,
                      body: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: ListView(
                              controller: controller,
                              children: [
                                SizedBox(
                                  height: SizeConfig.screenHeight / 5.5,
                                ),
                                ListTile(
                                  onTap: () {
                                    showModalBottomSheet(
                                        //   backgroundColor: kSecondaryColor,
                                        context: context,
                                        builder: (context) {
                                          return Comments(
                                            episodeObject:
                                                episodeObject.episodeObject,
                                          );
                                        });
                                  },
                                  leading: CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                        prefs.getString('displayPicture') ==
                                                null
                                            ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                            : prefs
                                                .getString('displayPicture')),
                                  ),
                                  title: Text(
                                    "Add a public comment",
                                    textScaleFactor: 0.75,
                                    style: TextStyle(),
                                  ),
                                ),
                                for (var v in comments)
                                  Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              CachedNetworkImageProvider(v[
                                                          'user_image'] ==
                                                      null
                                                  ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                  : v['user_image']),
                                        ),
                                        title: Text(
                                          '${v['author']}',
                                          textScaleFactor: 0.75,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 5),
                                              child: Text(
                                                "${v['text']}",
                                                textScaleFactor: 0.75,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    showModalBottomSheet(
                                                        context: context,
                                                        builder: (context) {
                                                          return ListTile(
                                                            leading: InkWell(
                                                              onTap: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: Icon(
                                                                Icons.close,
                                                              ),
                                                            ),
                                                            title: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                TextField(
                                                                    controller:
                                                                        _replyController,
                                                                    autofocus:
                                                                        true,
                                                                    maxLines:
                                                                        10,
                                                                    minLines:
                                                                        1),
                                                              ],
                                                            ),
                                                            trailing: InkWell(
                                                              onTap: () {
                                                                postReply(
                                                                    v['id'],
                                                                    _replyController
                                                                        .text,
                                                                    episodeObject
                                                                        .episodeObject);
                                                                _commentsController
                                                                    .clear();
                                                              },
                                                              child: Icon(
                                                                Icons.send,
                                                              ),
                                                            ),
                                                          );
                                                        });
                                                  },
                                                  child: Text(
                                                    "Reply",
                                                    textScaleFactor: 0.75,
// style:TextStyle(color:Colors.blue)
                                                  ),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                        trailing: IconButton(
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      child: UpvoteComment(
                                                        comment_id:
                                                            v['id'].toString(),
                                                      ));
                                                }).then((value) async {
                                              print(value);
                                            });
                                          },
                                          icon: Icon(
                                            FontAwesomeIcons.chevronCircleUp,
                                          ),
                                        ),
                                        isThreeLine: true,
                                      ),
                                      v['comments'] == null
                                          ? SizedBox(
                                              height: 0,
                                            )
                                          : ExpansionTile(
                                              // backgroundColor: Colors.transparent,
                                              trailing: SizedBox(
                                                width: 0,
                                              ),
                                              title: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  "View replies",
                                                  textScaleFactor: 0.75,
                                                  style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3,
                                                    // color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              children: <Widget>[
                                                for (var c in v['comments'])
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 10),
                                                      child: Container(
                                                        child: Row(
                                                          children: <Widget>[
                                                            CircleAvatar(
                                                              radius: 20,
                                                              backgroundImage: v[
                                                                          'user_image'] ==
                                                                      null
                                                                  ? AssetImage(
                                                                      'assets/images/person.png')
                                                                  : NetworkImage(
                                                                      v['user_image']),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Expanded(
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: <
                                                                        Widget>[
                                                                      Text(
                                                                        '${c['author']}',
                                                                        textScaleFactor:
                                                                            1.0,
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      ),
                                                                      Text(
                                                                        '${c['text']}',
                                                                        textScaleFactor:
                                                                            1.0,
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.normal),
                                                                      ),
                                                                      Row(
                                                                        children: <
                                                                            Widget>[
                                                                          GestureDetector(
                                                                            onTap:
                                                                                () {
                                                                              showModalBottomSheet(
                                                                                  context: context,
                                                                                  builder: (context) {
                                                                                    return ListTile(
                                                                                      leading: InkWell(
                                                                                        onTap: () {
                                                                                          Navigator.pop(context);
                                                                                        },
                                                                                        child: Icon(
                                                                                          Icons.close,
                                                                                        ),
                                                                                      ),
                                                                                      title: Column(
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        children: [
                                                                                          TextField(controller: _replyController, autofocus: true, maxLines: 10, minLines: 1),
                                                                                        ],
                                                                                      ),
                                                                                      trailing: InkWell(
                                                                                        onTap: () {
                                                                                          postReply(c['id'], _replyController.text, episodeObject.episodeObject);
                                                                                          _commentsController.clear();
                                                                                          //  postComment;
                                                                                        },
                                                                                        child: Icon(
                                                                                          Icons.send,
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  });
                                                                            },
                                                                            child:
                                                                                Text(
                                                                              "Reply",
                                                                              textScaleFactor: 1.0,
                                                                            ),
                                                                          )
                                                                        ],
                                                                      )
                                                                    ],
                                                                  ),
                                                                  IconButton(
                                                                    onPressed:
                                                                        () {
                                                                      showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return Dialog(
                                                                                backgroundColor: Colors.transparent,
                                                                                child: UpvoteComment(
                                                                                  comment_id: v['id'].toString(),
                                                                                ));
                                                                          }).then((value) async {
                                                                        print(
                                                                            value);
                                                                      });
                                                                    },
                                                                    icon: Icon(
                                                                      FontAwesomeIcons
                                                                          .chevronCircleUp,
                                                                    ),
                                                                  )
                                                                ],
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
                                  )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: SizeConfig.screenHeight / 5,
                                  width: double.infinity,
                                  //color: Colors.white,
                                  child: Container(
                                    // color: kSecondaryColor,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: episodeObject.audioPlayer
                                                .builderRealtimePlayingInfos(
                                              builder: (context, infos) {
                                                if (infos == null) {
                                                  return SizedBox(
                                                    height: 0,
                                                  );
                                                } else {
                                                  return Seekbar(
                                                    currentPosition:
                                                        infos.currentPosition,
                                                    duration: infos.duration,
                                                    episodeName: episodeObject
                                                        .episodeName,
                                                    seekTo: (to) {
                                                      episodeObject.audioPlayer
                                                          .seek(to);
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                CircleAvatar(
                                                  radius: 20,
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      kSecondaryColor,
                                                  //      backgroundColor: Colors.white,
                                                  child: IconButton(
                                                    icon: Icon(
                                                      FontAwesomeIcons.bolt,
                                                      size: 16,
                                                      //  color: Colors.black,
                                                    ),
                                                    onPressed: () {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return Dialog(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30),
                                                              ),
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color:
                                                                      kSecondaryColor,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                ),
                                                                height: 260,
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          15,
                                                                      vertical:
                                                                          10),
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      FlatButton(
                                                                        onPressed:
                                                                            () {
                                                                          // episodeObject
                                                                          //     .audioPlayer
                                                                          //     .setPlaySpeed(0.25);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Text(
                                                                              "0.25X",
                                                                              textScaleFactor: 0.75,
                                                                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      FlatButton(
                                                                        onPressed:
                                                                            () {
                                                                          // episodeObject
                                                                          //     .audioPlayer
                                                                          //     .setPlaySpeed(0.5);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Text(
                                                                              "0.5X",
                                                                              textScaleFactor: 0.75,
                                                                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      FlatButton(
                                                                        onPressed:
                                                                            () {
                                                                          // episodeObject
                                                                          //     .audioPlayer
                                                                          //     .setPlaySpeed(1.0);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Text(
                                                                              "1X",
                                                                              textScaleFactor: 0.75,
                                                                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      FlatButton(
                                                                        onPressed:
                                                                            () {
                                                                          // episodeObject
                                                                          //     .audioPlayer
                                                                          //     .setPlaySpeed(1.5);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Text(
                                                                              "1.5X",
                                                                              textScaleFactor: 0.75,
                                                                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      FlatButton(
                                                                        onPressed:
                                                                            () {
                                                                          // episodeObject
                                                                          //     .audioPlayer
                                                                          //     .setPlaySpeed(2.0);
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Text(
                                                                              "2X",
                                                                              textScaleFactor: 0.75,
                                                                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.replay_10,
                                                    //  color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    episodeObject.audioPlayer
                                                        .seekBy(Duration(
                                                            seconds: -10));
                                                  },
                                                ),
                                                CircleAvatar(
                                                  radius: 20,
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      kSecondaryColor,
                                                  //   backgroundColor: Colors.white,
                                                  child: episodeObject
                                                      .audioPlayer
                                                      .builderRealtimePlayingInfos(
                                                          builder:
                                                              (context, infos) {
                                                    if (infos == null) {
                                                      return SpinKitPulse(
                                                        color: Colors.white,
                                                      );
                                                    } else {
                                                      if (infos.isBuffering ==
                                                          true) {
                                                        return SpinKitCircle(
                                                          size: 16,
                                                          color: Colors.white,
                                                        );
                                                      } else {
                                                        if (infos.isPlaying ==
                                                            true) {
                                                          return IconButton(
                                                            icon: Icon(
                                                              Icons.pause,
                                                              // color:
                                                              //     Colors.black,
                                                            ),
                                                            onPressed: () {
                                                              episodeObject
                                                                  .pause();
                                                              setState(() {
                                                                playerState =
                                                                    PlayerState
                                                                        .paused;
                                                              });
                                                            },
                                                          );
                                                        } else {
                                                          return IconButton(
                                                            icon: Icon(
                                                              Icons.play_arrow,
                                                              // color:
                                                              //     Colors.black,
                                                            ),
                                                            onPressed: () {
//                                    play(url);
                                                              episodeObject
                                                                  .resume();
                                                              setState(() {
                                                                playerState =
                                                                    PlayerState
                                                                        .playing;
                                                              });
                                                            },
                                                          );
                                                        }
                                                      }
                                                    }
                                                  }),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.forward_10,
                                                    //  color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    episodeObject.audioPlayer
                                                        .seekBy(
                                                      Duration(seconds: 10),
                                                    );
                                                  },
                                                ),
                                                // hiveToken == null
                                                //     ? SizedBox(
                                                //         width: 50,
                                                //       )
                                                //     :
                                                CircleAvatar(
                                                  radius: 20,
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      kSecondaryColor,
                                                  // backgroundColor:
                                                  //     Color(0xff37a1f7),
                                                  child: IconButton(
                                                    icon: Center(
                                                      child: Icon(
                                                        FontAwesomeIcons
                                                            .chevronCircleUp,
                                                        size: 16,
                                                        //     color: Colors.black,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Fluttertoast.showToast(
                                                          msg: 'Upvote done');
                                                      if (episodeObject
                                                              .permlink ==
                                                          null) {
                                                      } else {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return Dialog(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  child: UpvoteEpisode(
                                                                      episode_id:
                                                                          episodeObject
                                                                              .id,
                                                                      permlink:
                                                                          episodeObject
                                                                              .permlink));
                                                            }).then((value) async {
                                                          print(value);
                                                        });

                                                        // upvoteEpisode(
                                                        //     episode_id:
                                                        //         episodeObject
                                                        //             .id,
                                                        //     permlink:
                                                        //         episodeObject
                                                        //             .permlink);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }
}

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
