import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/DatabaseFunctions/EpisodesBloc.dart';
import 'package:auditory/DatabaseFunctions/EpisodesProvider.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/screens/Profiles/publicUserProfile.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PlayerElements/Seekbar.dart';

class Player2 extends StatelessWidget {
  final episodeId;
  Player2({this.episodeId});

  @override
  Widget build(BuildContext context) {
    try {
      return Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaY: 15.0,
                sigmaX: 15.0,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaY: 15.0,
                  sigmaX: 15.0,
                ),
                child: Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.height,
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Banner(),
                          PlayerPlaybackButtons(),
                        ],
                      ),
                      Align(
                          alignment: Alignment.bottomCenter,
                          child: PLayerBottomSheet())
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Container();
    }
  }
}

class PlayerPlaybackButtons extends StatefulWidget {
  const PlayerPlaybackButtons();

  @override
  _PlayerPlaybackButtonsState createState() => _PlayerPlaybackButtonsState();
}

class _PlayerPlaybackButtonsState extends State<PlayerPlaybackButtons> {
  @override
  void initState() {
    // getEpisode(context);
    // TODO: implement initState
    super.initState();
  }

  var episodeContent;
  var hiveUsername;

  SharedPreferences prefs;

  Dio dio = Dio();
  CancelToken _cancel = CancelToken();

  Future getEpisode1() async {
    prefs = await SharedPreferences.getInstance();
    var playerState = Provider.of<PlayerChange>(context, listen: false);
    String url =
        'https://api.aureal.one/public/episode?episode_id=${playerState.audioPlayer.realtimePlayingInfos.value.current.audio.audio.metas.id}&user_id=${prefs.getString('userId')}';
    print(url);
    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['episode'];
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          episodeObject.audioPlayer.builderRealtimePlayingInfos(
              builder: (context, infos) {
            if (infos == null) {
              return SizedBox(
                height: 0,
              );
            } else {
              return Seekbar(
                // dominantColor:
                // dominantColor == null
                //     ? 0xff222222
                //     : dominantColor,
                currentPosition: infos.currentPosition,
                duration: infos.duration,
                episodeName: episodeObject.episodeName,
                seekTo: (to) {
                  episodeObject.audioPlayer.seek(to);
                },
              );
            }
          }),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {
                      episodeObject.audioPlayer.seekBy(Duration(seconds: -10));
                    },
                    icon: Icon(Icons.replay_10)),
                InkWell(
                  onTap: () {
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                              height: 380,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    .withOpacity(0.7)),
                                          )
                                        ],
                                      ),
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        episodeObject.audioPlayer
                                            .setPlaySpeed(0.5);
                                        Navigator.pop(context);
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            "0.5X",
                                            textScaleFactor: 0.75,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7)),
                                          )
                                        ],
                                      ),
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        episodeObject.audioPlayer
                                            .setPlaySpeed(0.75);
                                        Navigator.pop(context);
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            "0.75X",
                                            textScaleFactor: 0.75,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7)),
                                          )
                                        ],
                                      ),
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        episodeObject.audioPlayer
                                            .setPlaySpeed(1.0);
                                        Navigator.pop(context);
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            "Normal",
                                            textScaleFactor: 0.75,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7)),
                                          )
                                        ],
                                      ),
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        episodeObject.audioPlayer
                                            .setPlaySpeed(1.25);
                                        Navigator.pop(context);
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            "1.25X",
                                            textScaleFactor: 0.75,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7)),
                                          )
                                        ],
                                      ),
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        episodeObject.audioPlayer
                                            .setPlaySpeed(1.5);
                                        Navigator.pop(context);
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            "1.5X",
                                            textScaleFactor: 0.75,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7)),
                                          )
                                        ],
                                      ),
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        episodeObject.audioPlayer
                                            .setPlaySpeed(2.0);
                                        Navigator.pop(context);
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            "2X",
                                            textScaleFactor: 0.75,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7)),
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
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 22,
                    child: IconButton(
                      icon: Icon(
                        Icons.speed,
                        color: Color(0xff1a1a1a),
                      ),
                    ),
                  ),
                ),
                episodeObject.audioPlayer.builderRealtimePlayingInfos(
                    builder: (context, infos) {
                  if (infos == null) {
                    return Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white),
                    );
                  } else {
                    if (infos.isBuffering) {
                      return CircularProgressIndicator.adaptive();
                    }
                    if (infos.isPlaying) {
                      return InkWell(
                        onTap: () {
                          episodeObject.audioPlayer.pause();
                        },
                        child: Container(
                          width: 55,
                          height: 55,
                          child: Icon(
                            Icons.pause,
                            color: Color(0xff1a1a1a),
                            size: 40,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                      );
                    } else {
                      return InkWell(
                        onTap: () {
                          episodeObject.audioPlayer.play();
                        },
                        child: Container(
                          width: 55,
                          height: 55,
                          child: Icon(
                            Icons.play_arrow,
                            color: Color(0xff1a1a1a),
                            size: 40,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                      );
                    }
                  }
                }),
                FutureBuilder(
                  future: getEpisode1(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data['permlink'] == null) {
                        return Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                              // gradient: LinearGradient(
                              //     colors: [
                              //       Color(
                              //           0xff5bc3ef),
                              //       Color(
                              //           0xff5d5da8)
                              //     ]
                              // ),
                              color: Colors.grey,
                              shape: BoxShape.circle),
                          child: Icon(
                            FontAwesomeIcons.chevronCircleUp,
                            color: Colors.black54,
                          ),
                        );
                      } else {
                        if (snapshot.data['ifVoted'] == false) {
                          return InkWell(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      child: UpvoteEpisode(
                                        permlink: snapshot.data['permlink'],
                                        episode_id: snapshot.data['id'],
                                      ),
                                    );
                                  }).then((value) {
                                setState(() {
                                  snapshot.data['ifVoted'] = true;
                                });
                              });
                            },
                            child: Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                  // gradient: LinearGradient(
                                  //     colors: [
                                  //       Color(
                                  //           0xff5bc3ef),
                                  //       Color(
                                  //           0xff5d5da8)
                                  //     ]
                                  // ),
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                        // center: Alignment.center,
                                        // radius: 0.5,
                                        colors: [Colors.blue, Colors.red],
                                        tileMode: TileMode.mirror,
                                      ).createShader(bounds),
                                  child: Icon(
                                    FontAwesomeIcons.chevronCircleUp,
                                    color: Colors.white,
                                  )),
                            ),
                          );
                        } else {
                          return Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Color(0xff5bc3ef),
                                  Color(0xff5d5da8)
                                ]),
                                color: Colors.white,
                                shape: BoxShape.circle),
                            child: Icon(FontAwesomeIcons.chevronCircleUp),
                          );
                        }
                      }
                    } else {
                      return Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                            // gradient: LinearGradient(
                            //     colors: [
                            //       Color(
                            //           0xff5bc3ef),
                            //       Color(
                            //           0xff5d5da8)
                            //     ]
                            // ),
                            color: Colors.grey,
                            shape: BoxShape.circle),
                        child: Icon(
                          FontAwesomeIcons.chevronCircleUp,
                          color: Colors.black54,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                    onPressed: () {
                      episodeObject.audioPlayer.seekBy(Duration(seconds: 10));
                    },
                    icon: Icon(Icons.forward_10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PLayerBottomSheet extends StatefulWidget {
  const PLayerBottomSheet();

  @override
  _PLayerBottomSheetState createState() => _PLayerBottomSheetState();
}

class _PLayerBottomSheetState extends State<PLayerBottomSheet>
    with TickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(vsync: this, length: 3);
    super.initState();
  }

  int index = 0;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // showModalBottomSheet(
        //     isScrollControlled: true,
        //     backgroundColor: Colors.transparent,
        //     barrierColor: Colors.transparent,
        //     isDismissible: true,
        //     // bounce: true,
        //     context: context,
        //     builder: (context) {
        //       return SheetView(index: _tabController.index);
        //     });

      }
    });
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaY: 15.0,
          sigmaX: 15.0,
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      isDismissible: true,
                      // bounce: true,
                      context: context,
                      builder: (context) {
                        return SheetView(index: 0);
                      });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 3,
                  height: 70,
                  child: Center(child: Text("UP NEXT")),
                ),
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      isDismissible: true,
                      // bounce: true,
                      context: context,
                      builder: (context) {
                        return SheetView(index: 1);
                      });
                },
                child: Container(
                  height: 70,
                  width: MediaQuery.of(context).size.width / 3,
                  child: Center(child: Text("TRANSCRIPT")),
                ),
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      isDismissible: true,
                      // bounce: true,
                      context: context,
                      builder: (context) {
                        return SheetView(index: 2);
                      });
                },
                child: Container(
                  height: 70,
                  width: MediaQuery.of(context).size.width / 3,
                  child: Center(child: Text("RELATED")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SheetView extends StatefulWidget {
  int index;
  SheetView({@required this.index});

  @override
  _SheetViewState createState() => _SheetViewState();
}

class _SheetViewState extends State<SheetView> with TickerProviderStateMixin {
  TabController _tabController;

  ScrollController nestedScrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    _tabController =
        TabController(vsync: this, length: 3, initialIndex: widget.index);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaY: 15.0,
          sigmaX: 15.0,
        ),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(),
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        text: "UP NEXT",
                      ),
                      Tab(
                        text: 'TRANSCRIPT',
                      ),
                      Tab(
                        text: 'RELATED',
                      )
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        episodeObject.audioPlayer.builderCurrent(
                          builder: (context, Playing playing) {
                            return SongSelector(
                              audios: playing.playlist.audios,
                              onPlaylistSelected: (myAudios) {
                                episodeObject.audioPlayer.open(
                                  Playlist(audios: myAudios),
                                  showNotification: true,
                                  headPhoneStrategy:
                                      HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
                                  audioFocusStrategy:
                                      AudioFocusStrategy.request(
                                          resumeAfterInterruption: true),
                                );
                                // getEpisode(context);
                              },
                              onSelected: (myAudio) async {
                                try {
                                  await episodeObject.audioPlayer.open(
                                    myAudio,
                                    autoStart: true,
                                    showNotification: true,
                                    playInBackground: PlayInBackground.enabled,
                                    audioFocusStrategy:
                                        AudioFocusStrategy.request(
                                            resumeAfterInterruption: true,
                                            resumeOthersPlayersAfterDone: true),
                                    headPhoneStrategy:
                                        HeadPhoneStrategy.pauseOnUnplug,
                                    notificationSettings: NotificationSettings(
                                        //seekBarEnabled: false,
                                        //stopEnabled: true,
                                        //customStopAction: (player){
                                        //  player.stop();
                                        //}
                                        //prevEnabled: false,
                                        //customNextAction: (player) {
                                        //  print('next');
                                        //}
                                        //customStopIcon: AndroidResDrawable(name: 'ic_stop_custom'),
                                        //customPauseIcon: AndroidResDrawable(name:'ic_pause_custom'),
                                        //customPlayIcon: AndroidResDrawable(name:'ic_play_custom'),
                                        ),
                                  );
                                  // getEpisode(context);
                                } catch (e) {
                                  print(e);
                                }
                              },
                              playing: playing,
                            );
                          },
                        ),
                        MiniTranscript(
                          episodeId: episodeObject
                              .audioPlayer
                              .realtimePlayingInfos
                              .valueOrNull
                              .current
                              .audio
                              .audio
                              .metas
                              .id,
                        ),
                        episodeObject.audioPlayer.builderCurrent(
                            builder: (context, Playing playing) {
                          return Related(
                            episodeId: episodeObject
                                .audioPlayer
                                .realtimePlayingInfos
                                .valueOrNull
                                .current
                                .audio
                                .audio
                                .metas
                                .id,
                          );
                        }),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum PlayerState { stopped, playing, paused }

extension Pipe<T> on T {
  R pipe<R>(R f(T t)) => f(this);
}

class MiniTranscript extends StatefulWidget {
  final episodeId;

  MiniTranscript({@required this.episodeId});

  @override
  _MiniTranscriptState createState() => _MiniTranscriptState();
}

class _MiniTranscriptState extends State<MiniTranscript>
    with AutomaticKeepAliveClientMixin {
  var transcript;

  void Transcription() async {
    String url =
        "https://api.aureal.one/public/getTranscription?episode_id=${widget.episodeId}";
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          transcript = jsonDecode(response.body)['data']['transcription'];
        });
        print(transcript);
        print(transcript.runtimeType);
      }
    } catch (e) {
      print(e);
    }
  }

  int currentIndex = 0;
  ItemScrollController itemScrollController;
  ItemPositionsListener itemPositionsListener;

  void init() {
    Transcription();

    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    episodeObject.audioPlayer.currentPosition.listen((event) {
      var currentPositionSeconds = event.inMilliseconds / 1000;
      if (transcript != null && transcript.length > 0) {
        // print(event.inMilliseconds / 1000);
        // print(transcript.indexWhere((element) => element['start_time'] < currentPositionSeconds && element['end_time'] > currentPositionSeconds));
        // setState(() {
        if (transcript != null && transcript.length > 0) {
          var count = (transcript.indexWhere((element) =>
              element['start_time'] < currentPositionSeconds &&
              element['end_time'] > currentPositionSeconds));
          if (count >= 0) {
            print(count);

            setState(() {
              currentIndex = count;
            });

            itemScrollController.jumpTo(
              index: count,
              // curve: Curves.easeInCirc,
            );
          }
        }
      }
    });

    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();
  }

  @override
  void initState() {
    // TODO: implement initState

    init();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MiniTranscript oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    if (widget.episodeId != oldWidget.episodeId) {
      init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: [
          Center(
            child: transcript == null
                ? SizedBox()
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (context) {
                          print(transcript);
                          print(transcript.runtimeType);
                          return TrancriptionPlayer(
                            transcript: transcript,
                          );
                        }));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black,
                        ),
                        height: MediaQuery.of(context).size.height / 4,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "${transcript[currentIndex]['msg'].toString().trimLeft().trimRight()}",
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 4),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "${transcript[currentIndex + 1]['msg'].toString().trimLeft().trimRight()}",
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 4,
                                      color: Colors.white.withOpacity(0.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class Player extends StatefulWidget {
  final episodeId;

  Player({@required this.episodeId});

  static const String id = "Player";

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> with TickerProviderStateMixin {
  //Global Key For ScrollController for transcription

  final dataKey = new GlobalKey();

  PlayerState playerState = PlayerState.playing;
  final _episodeBloc = EpisodeBloc();
  final _mp = EpisodesProvider.getInstance();
  RegExp htmlMatch = RegExp(r'(\w+)');
  ScrollController _controller;
  ScreenshotController screenshotController = ScreenshotController();
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
  List transcript;
  final picker = ImagePicker();
  File _image;
  bool isUpvoteLoading = false;

  int currentIndex = 0;

  ItemScrollController itemScrollController;

  TabController _tabController;

  void Transcription() async {
    var playerState = Provider.of<PlayerChange>(context, listen: false);
    String url =
        "https://api.aureal.one/public/getTranscription?episode_id=${playerState.audioPlayer.realtimePlayingInfos.value.current.audio.audio.metas.id}";
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          transcript = jsonDecode(response.body)['data']['transcription'];
        });
        print(transcript);
        print(transcript.runtimeType);
      }
    } catch (e) {
      print(e);
    }
  }

  ItemPositionsListener itemPositionsListener;

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
// print("${episodeObject['id']}");
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
  String copyclip;
  String hiveUsername;

  final List<StreamSubscription> _subscriptions = [];
  int progress = 0;

  var dominantColor = 0xff222222;

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

  // void getColor(String url) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   hiveUsername = prefs.getString('HiveUserName');
  //
  //   getColorFromUrl(url).then((value) {
  //     setState(() {
  //       dominantColor = hexOfRGBA(value[0], value[1], value[2]);
  //       print(dominantColor.toString());
  //
  //       SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //         statusBarColor: Color(dominantColor),
  //       ));
  //     });
  //   });
  // }

  void getEpisode(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var playerState = Provider.of<PlayerChange>(context, listen: false);
    String url =
        'https://api.aureal.one/public/episode?episode_id=${playerState.audioPlayer.realtimePlayingInfos.value.current.audio.audio.metas.id}&user_id=${prefs.getString('userId')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (this.mounted) {
          setState(() {
            episodeContent = jsonDecode(response.body)['episode'];

            hiveUsername = prefs.getString('HiveUserName');
          });
        }
        // await getColor(episodeContent['image']);
        setState(() {
          // isLoading = false;
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    // getRecommendations();
  }

  @override
  void initState() {
    // TODO: implement initState

    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();

    super.initState();
    _tabController = TabController(vsync: this, length: 2);

    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    getEpisode(context);
    print('abc');
    print(episodeObject.id);
    // Transcription();
    // episodeObject.audioPlayer.currentPosition.listen((event) {
    //   var currentPositionSeconds = event.inMilliseconds / 1000;
    //   if (transcript != null && transcript.length > 0) {
    //     // print(event.inMilliseconds / 1000);
    //     // print(transcript.indexWhere((element) => element['start_time'] < currentPositionSeconds && element['end_time'] > currentPositionSeconds));
    //     // setState(() {
    //     if (transcript != null && transcript.length > 0) {
    //       var count = (transcript.indexWhere((element) =>
    //           element['start_time'] < currentPositionSeconds &&
    //           element['end_time'] > currentPositionSeconds));
    //       if (count >= 0) {
    //         print(count);
    //
    //         setState(() {
    //           currentIndex = count;
    //         });
    //
    //         itemScrollController.jumpTo(
    //           index: count,
    //           // curve: Curves.easeInCirc,
    //         );
    //       }
    //     }
    //   }
    // });

    // episodeObject.audioPlayer.currentPosition.listen((event) {
    //   if (episodeObject.audioPlayer.currentPosition.value ==
    //       episodeObject.audioPlayer.realtimePlayingInfos.value.duration) {
    //     episodeObject.customNextAction(episodeObject.audioPlayer);
    //   }
    // });

    // getColor(episodeObject.episodeObject['image'] == null
    //     ? episodeObject.episodeObject['podcast_image']
    //     : episodeObject.episodeObject['image']);
    // if (counter < 1) {
    //   getComments(episodeObject.episodeObject);
    // }

    print(episodeObject.episodeObject);

    _subscriptions
        .add(episodeObject.audioPlayer.playlistAudioFinished.listen((data) {
      print("playlistAudioFinished : $data");
      print("///////////////////This is the data");
      getEpisode(context);
    }));
    // _subscriptions
    //     .add(episodeObject.audioPlayer.((sessionId) {
    //   print("audioSessionId : $sessionId");
    // }));
    _subscriptions
        .add(AssetsAudioPlayer.addNotificationOpenAction((notification) {
      return false;
    }));

    _playListTabController = TabController(vsync: this, length: 3);
  }

  TabController _playListTabController;

  Audio find(List<Audio> source, String fromPath) {
    return source.firstWhere((element) => element.path == fromPath);
  }

  @override
  void dispose() {
    super.dispose();
    // TODO: implement dispose
    print('Dispose Called//////////////////////////////////////////////');

    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.black));
  }

  void share() async {
    var playerProvider = Provider.of<PlayerChange>(context, listen: false);

    // String sharableLink;

    await FlutterShare.share(
        title:
            '${playerProvider.audioPlayer.current.value.audio.audio.metas.album}',
        text:
            "Hey There, I'm listening to ${playerProvider.audioPlayer.current.value.audio.audio.metas.title} from ${playerProvider.audioPlayer.current.value.audio.audio.metas.album} on : Aureal, \n \nhere's the link for you https://aureal.one/episode/${playerProvider.audioPlayer.current.value.audio.audio.metas.id}");
  }

  Future<Color> getImagePalette(ImageProvider imageProvider) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(imageProvider);
    return paletteGenerator.dominantColor.color;
  }

  String _fileName;
  String _path;
  Map<String, String> _paths;

  ScrollController nestedController = ScrollController();

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    SizeConfig().init(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return FutureBuilder(
      future: getImagePalette(CachedNetworkImageProvider(episodeObject
          .audioPlayer
          .realtimePlayingInfos
          .value
          .current
          .audio
          .audio
          .metas
          .image
          .path)),
      builder: (context, snapshot) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: NestedScrollView(
            controller: nestedController,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                Platform.isIOS
                    ? SliverAppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.black,
                        pinned: true,
                        expandedHeight:
                            MediaQuery.of(context).size.height / 1.09,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                              color: Colors.black,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              child: episodeObject.audioPlayer
                                  .builderRealtimePlayingInfos(
                                      builder: (context, infos) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // SizedBox(
                                    //   height:
                                    //       MediaQuery.of(context).size.height / 30,
                                    // ),
                                    Banner(),
                                    ListTile(
                                      title: GestureDetector(
                                        onTap: () {
                                          Navigator.push(context,
                                              CupertinoPageRoute(
                                                  builder: (context) {
                                            return EpisodeView(
                                                episodeId: episodeObject
                                                    .episodeObject['id']);
                                          }));
                                        },
                                        child: Text(
                                          '${infos.current.audio.audio.metas.title}',
                                          maxLines: 2,
                                          textScaleFactor: 1.0,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .blockSizeHorizontal *
                                                  3.7,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      subtitle: InkWell(
                                        onTap: () {
                                          Navigator.push(context,
                                              CupertinoPageRoute(
                                                  builder: (context) {
                                            return PublicProfile(
                                              userId: episodeObject
                                                  .episodeObject['user_id'],
                                            );
                                          }));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Text(
                                            '${infos.current.audio.audio.metas.artist}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: SizeConfig
                                                      .blockSizeHorizontal *
                                                  3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Builder(
                                        builder: (context) {
                                          try {
                                            return episodeContent['permlink'] ==
                                                    null
                                                ? SizedBox()
                                                : Container(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        InkWell(
                                                          onTap: () async {
                                                            if (hiveUsername !=
                                                                null) {
                                                              setState(() {
                                                                isUpvoteLoading =
                                                                    true;
                                                              });
                                                              double _value =
                                                                  50.0;
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    return Dialog(
                                                                        backgroundColor:
                                                                            Colors
                                                                                .transparent,
                                                                        child: UpvoteEpisode(
                                                                            permlink:
                                                                                episodeContent['permlink'],
                                                                            episode_id: int.parse(episodeObject.audioPlayer.current.value.audio.audio.metas.id)));
                                                                  }).then((value) async {
                                                                print(value);
                                                              });
                                                              setState(() {
                                                                if (episodeObject
                                                                        .ifVoted !=
                                                                    true) {
                                                                  episodeObject
                                                                          .ifVoted =
                                                                      true;
                                                                }
                                                              });
                                                              setState(() {
                                                                isUpvoteLoading =
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
                                                          child: Container(
                                                            decoration: episodeContent[
                                                                        'ifVoted'] ==
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
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 5,
                                                                  horizontal:
                                                                      10),
                                                              child: Row(
                                                                children: [
                                                                  isUpvoteLoading ==
                                                                          true
                                                                      ? Container(
                                                                          height:
                                                                              17,
                                                                          width:
                                                                              18,
                                                                          child:
                                                                              SpinKitPulse(
                                                                            color:
                                                                                Colors.blue,
                                                                          ),
                                                                        )
                                                                      : Icon(
                                                                          FontAwesomeIcons
                                                                              .chevronCircleUp,
                                                                          size:
                                                                              12,
                                                                          // color:
                                                                          //     Color(0xffe8e8e8),
                                                                        ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .symmetric(
                                                                        horizontal:
                                                                            8),
                                                                    child: Text(
                                                                      episodeContent[
                                                                              'votes']
                                                                          .toString(),
                                                                      textScaleFactor:
                                                                          1.0,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              SizeConfig.blockSizeHorizontal * 3.5
                                                                          // color:
                                                                          //     Color(0xffe8e8e8)
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    height: 15,
                                                                    width: 10,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border: Border(
                                                                          left: BorderSide(
                                                                        color: themeProvider.isLightTheme ==
                                                                                false
                                                                            ? Colors.white
                                                                            : kPrimaryColor,
                                                                      )),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            4),
                                                                    child: Text(
                                                                      '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
                                                                      textScaleFactor:
                                                                          1.0,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              SizeConfig.blockSizeHorizontal * 3.5

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
                                                        SizedBox(
                                                          width: 10,
                                                        ),
                                                        InkWell(
                                                          onTap: () async {
                                                            SharedPreferences
                                                                prefs =
                                                                await SharedPreferences
                                                                    .getInstance();
                                                            if (prefs.getString(
                                                                    'HiveUserName') !=
                                                                null) {
                                                              Navigator.push(
                                                                  context,
                                                                  CupertinoPageRoute(
                                                                      builder: (context) =>
                                                                          Comments(
                                                                            episodeObject:
                                                                                episodeContent,
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
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    right: 5),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                          color:
                                                                              kSecondaryColor),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              30)),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        5.0),
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
                                                                      child:
                                                                          Text(
                                                                        episodeContent['comments_count']
                                                                            .toString(),
                                                                        textScaleFactor:
                                                                            1.0,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                SizeConfig.blockSizeHorizontal * 3.5),
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
                                                  );
                                          } catch (e) {
                                            print("API call still Happening");
                                            return SizedBox();
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      // height: MediaQuery.of(context).size.height / 1.5,
                                      decoration: BoxDecoration(
                                        // boxShadow: [
                                        //   new BoxShadow(
                                        //     color: Colors.black54.withOpacity(0.2),
                                        //     blurRadius: 10.0,
                                        //   ),
                                        // ],
                                        // color: Color(0xff1a1a1a),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          episodeObject.audioPlayer
                                              .builderRealtimePlayingInfos(
                                                  builder: (context, infos) {
                                            if (infos == null) {
                                              return SizedBox(
                                                height: 0,
                                              );
                                            } else {
                                              return Seekbar(
                                                dominantColor:
                                                    dominantColor == null
                                                        ? 0xff222222
                                                        : dominantColor,
                                                currentPosition:
                                                    infos.currentPosition,
                                                duration: infos.duration,
                                                episodeName:
                                                    episodeObject.episodeName,
                                                seekTo: (to) {
                                                  episodeObject.audioPlayer
                                                      .seek(to);
                                                },
                                              );
                                            }
                                          }),
                                          // SizedBox(
                                          //   height:
                                          //       MediaQuery.of(context).size.height /
                                          //           35,
                                          // ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                IconButton(
                                                  icon: Icon(
                                                    FontAwesomeIcons.fighterJet,
                                                    size: 18,
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
                                                              height: 380,
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
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "0.25X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(0.5);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "0.5X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(0.75);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "0.75X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(1.0);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "Normal",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(1.25);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "1.25X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(1.5);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "1.5X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(2.0);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "2X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
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
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.replay_10,
                                                    //  color: Colors.white,
                                                    size: 40,
                                                  ),
                                                  onPressed: () {
                                                    episodeObject.audioPlayer
                                                        .seekBy(Duration(
                                                            seconds: -10));
                                                  },
                                                ),
                                                episodeObject.audioPlayer
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
                                                        size: 15,
                                                        color: Colors.white,
                                                      );
                                                    } else {
                                                      if (infos.isPlaying ==
                                                          true) {
                                                        return FloatingActionButton(
                                                            child: Icon(
                                                                Icons.pause),
                                                            backgroundColor:
                                                                Color(dominantColor) ==
                                                                        null
                                                                    ? Colors
                                                                        .blue
                                                                    : Color(
                                                                        dominantColor),
                                                            onPressed: () {
                                                              episodeObject
                                                                  .pause();
                                                            });
                                                      } else {
                                                        return FloatingActionButton(
                                                            backgroundColor:
                                                                Color(dominantColor) ==
                                                                        null
                                                                    ? Colors
                                                                        .blue
                                                                    : Color(
                                                                        dominantColor),
                                                            child: Icon(Icons
                                                                .play_arrow_rounded),
                                                            onPressed: () {
                                                              // play(url);
                                                              episodeObject
                                                                  .resume();
                                                            });
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
                                                    episodeObject.audioPlayer
                                                        .seekBy(
                                                      Duration(seconds: 10),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    share();
                                                  },
                                                  icon: Icon(
                                                    Icons.ios_share,
                                                    size: 18,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 50,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              })),
                        ),
                        bottom: PreferredSize(
                          preferredSize: Size.fromHeight(50),
                          child: Container(
                            color: Color(0xff1a1a1a),
                            child: TabBar(
                                controller: _playListTabController,
                                tabs: [
                                  Tab(
                                    text: "UP NEXT",
                                  ),
                                  Tab(
                                    text: "TRANSCRIPT",
                                  ),
                                  Tab(
                                    text: "RELATED",
                                  )
                                ]),
                          ),
                        ),
                      )
                    : SliverAppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.black,
                        pinned: true,
                        expandedHeight:
                            MediaQuery.of(context).size.height / 1.2,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                              color: Colors.black,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              child: episodeObject.audioPlayer
                                  .builderRealtimePlayingInfos(
                                      builder: (context, infos) {
                                return Column(
                                  children: [
                                    Banner(),
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Builder(
                                        builder: (context) {
                                          try {
                                            return episodeContent['permlink'] ==
                                                    null
                                                ? SizedBox()
                                                : Container(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        InkWell(
                                                          onTap: () async {
                                                            if (hiveUsername !=
                                                                null) {
                                                              setState(() {
                                                                isUpvoteLoading =
                                                                    true;
                                                              });
                                                              double _value =
                                                                  50.0;
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    return Dialog(
                                                                        backgroundColor:
                                                                            Colors
                                                                                .transparent,
                                                                        child: UpvoteEpisode(
                                                                            permlink:
                                                                                episodeContent['permlink'],
                                                                            episode_id: int.parse(episodeObject.audioPlayer.current.value.audio.audio.metas.id)));
                                                                  }).then((value) async {
                                                                print(value);
                                                              });
                                                              setState(() {
                                                                if (episodeObject
                                                                        .ifVoted !=
                                                                    true) {
                                                                  episodeObject
                                                                          .ifVoted =
                                                                      true;
                                                                }
                                                              });
                                                              setState(() {
                                                                isUpvoteLoading =
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
                                                          child: Container(
                                                            decoration: episodeContent[
                                                                        'ifVoted'] ==
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
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 5,
                                                                  horizontal:
                                                                      10),
                                                              child: Row(
                                                                children: [
                                                                  isUpvoteLoading ==
                                                                          true
                                                                      ? Container(
                                                                          height:
                                                                              17,
                                                                          width:
                                                                              18,
                                                                          child:
                                                                              SpinKitPulse(
                                                                            color:
                                                                                Colors.blue,
                                                                          ),
                                                                        )
                                                                      : Icon(
                                                                          FontAwesomeIcons
                                                                              .chevronCircleUp,
                                                                          size:
                                                                              15,
                                                                          // color:
                                                                          //     Color(0xffe8e8e8),
                                                                        ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .symmetric(
                                                                        horizontal:
                                                                            8),
                                                                    child: Text(
                                                                      episodeContent[
                                                                              'votes']
                                                                          .toString(),
                                                                      textScaleFactor:
                                                                          1.0,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              15
                                                                          // color:
                                                                          //     Color(0xffe8e8e8)
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    height: 15,
                                                                    width: 10,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      border: Border(
                                                                          left: BorderSide(
                                                                        color: themeProvider.isLightTheme ==
                                                                                false
                                                                            ? Colors.white
                                                                            : kPrimaryColor,
                                                                      )),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            4),
                                                                    child: Text(
                                                                      '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
                                                                      textScaleFactor:
                                                                          1.0,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            15,

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
                                                        SizedBox(
                                                          width: 10,
                                                        ),
                                                        InkWell(
                                                          onTap: () async {
                                                            SharedPreferences
                                                                prefs =
                                                                await SharedPreferences
                                                                    .getInstance();
                                                            if (prefs.getString(
                                                                    'HiveUserName') !=
                                                                null) {
                                                              Navigator.push(
                                                                  context,
                                                                  CupertinoPageRoute(
                                                                      builder: (context) =>
                                                                          Comments(
                                                                            episodeObject:
                                                                                episodeContent,
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
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    right: 5),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                          color:
                                                                              kSecondaryColor),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              30)),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        5.0),
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
                                                                      child:
                                                                          Text(
                                                                        episodeContent['comments_count']
                                                                            .toString(),
                                                                        textScaleFactor:
                                                                            1.0,
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
                                                  );
                                          } catch (e) {
                                            print("API call still Happening");
                                            return SizedBox();
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      // height: MediaQuery.of(context).size.height / 1.5,
                                      decoration: BoxDecoration(
                                        // boxShadow: [
                                        //   new BoxShadow(
                                        //     color: Colors.black54.withOpacity(0.2),
                                        //     blurRadius: 10.0,
                                        //   ),
                                        // ],
                                        // color: Color(0xff1a1a1a),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          episodeObject.audioPlayer
                                              .builderRealtimePlayingInfos(
                                                  builder: (context, infos) {
                                            if (infos == null) {
                                              return SizedBox(
                                                height: 0,
                                              );
                                            } else {
                                              return Seekbar(
                                                dominantColor:
                                                    dominantColor == null
                                                        ? 0xff222222
                                                        : dominantColor,
                                                currentPosition:
                                                    infos.currentPosition,
                                                duration: infos.duration,
                                                episodeName:
                                                    episodeObject.episodeName,
                                                seekTo: (to) {
                                                  episodeObject.audioPlayer
                                                      .seek(to);
                                                },
                                              );
                                            }
                                          }),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                35,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20, horizontal: 10),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                IconButton(
                                                  icon: Icon(
                                                    FontAwesomeIcons.fighterJet,
                                                    size: 18,
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
                                                              height: 380,
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
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "0.25X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(0.5);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "0.5X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(0.75);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "0.75X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(1.0);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "Normal",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(1.25);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "1.25X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(1.5);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "1.5X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    FlatButton(
                                                                      onPressed:
                                                                          () {
                                                                        episodeObject
                                                                            .audioPlayer
                                                                            .setPlaySpeed(2.0);
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Text(
                                                                            "2X",
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Colors.white.withOpacity(0.7)),
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
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.replay_10,
                                                    //  color: Colors.white,
                                                    size: 40,
                                                  ),
                                                  onPressed: () {
                                                    episodeObject.audioPlayer
                                                        .seekBy(Duration(
                                                            seconds: -10));
                                                  },
                                                ),
                                                episodeObject.audioPlayer
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
                                                        size: 15,
                                                        color: Colors.white,
                                                      );
                                                    } else {
                                                      if (infos.isPlaying ==
                                                          true) {
                                                        return FloatingActionButton(
                                                            child: Icon(
                                                                Icons.pause),
                                                            backgroundColor:
                                                                Color(dominantColor) ==
                                                                        null
                                                                    ? Colors
                                                                        .blue
                                                                    : Color(
                                                                        dominantColor),
                                                            onPressed: () {
                                                              episodeObject
                                                                  .pause();
                                                              setState(() {
                                                                playerState =
                                                                    PlayerState
                                                                        .paused;
                                                              });
                                                            });
                                                      } else {
                                                        return FloatingActionButton(
                                                            backgroundColor:
                                                                Color(dominantColor) ==
                                                                        null
                                                                    ? Colors
                                                                        .blue
                                                                    : Color(
                                                                        dominantColor),
                                                            child: Icon(Icons
                                                                .play_arrow_rounded),
                                                            onPressed: () {
                                                              // play(url);
                                                              episodeObject
                                                                  .resume();
                                                              setState(() {
                                                                playerState =
                                                                    PlayerState
                                                                        .playing;
                                                              });
                                                            });
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
                                                    episodeObject.audioPlayer
                                                        .seekBy(
                                                      Duration(seconds: 10),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    share();
                                                  },
                                                  icon: Icon(
                                                    Icons.ios_share,
                                                    size: 18,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 50,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              })),
                        ),
                        bottom: PreferredSize(
                          preferredSize: Size.fromHeight(50),
                          child: Container(
                            color: Color(0xff1a1a1a),
                            child: TabBar(
                                controller: _playListTabController,
                                tabs: [
                                  Tab(
                                    text: "UP NEXT",
                                  ),
                                  Tab(
                                    text: "TRANSCRIPT",
                                  ),
                                  Tab(
                                    text: "RELATED",
                                  )
                                ]),
                          ),
                        ),
                      ),
              ];
            },
            body: TabBarView(
              controller: _playListTabController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                episodeObject.audioPlayer.builderCurrent(
                  builder: (context, Playing playing) {
                    return SongSelector(
                      audios: episodeObject.playList,
                      onPlaylistSelected: (myAudios) {
                        episodeObject.audioPlayer.open(
                          Playlist(audios: myAudios),
                          showNotification: true,
                          headPhoneStrategy:
                              HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
                          audioFocusStrategy: AudioFocusStrategy.request(
                              resumeAfterInterruption: true),
                        );
                        getEpisode(context);
                      },
                      onSelected: (myAudio) async {
                        try {
                          await episodeObject.audioPlayer.open(
                            myAudio,
                            autoStart: true,
                            showNotification: true,
                            playInBackground: PlayInBackground.enabled,
                            audioFocusStrategy: AudioFocusStrategy.request(
                                resumeAfterInterruption: true,
                                resumeOthersPlayersAfterDone: true),
                            headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplug,
                            notificationSettings: NotificationSettings(
                                //seekBarEnabled: false,
                                //stopEnabled: true,
                                //customStopAction: (player){
                                //  player.stop();
                                //}
                                //prevEnabled: false,
                                //customNextAction: (player) {
                                //  print('next');
                                //}
                                //customStopIcon: AndroidResDrawable(name: 'ic_stop_custom'),
                                //customPauseIcon: AndroidResDrawable(name:'ic_pause_custom'),
                                //customPlayIcon: AndroidResDrawable(name:'ic_play_custom'),
                                ),
                          );
                          getEpisode(context);
                        } catch (e) {
                          print(e);
                        }
                      },
                      playing: playing,
                    );
                  },
                ),
                MiniTranscript(
                  episodeId: episodeObject.audioPlayer.realtimePlayingInfos
                      .valueOrNull.current.audio.audio.metas.id,
                ),
                episodeObject.audioPlayer.builderCurrent(
                    builder: (context, Playing playing) {
                  return Related1(
                    episodeId: episodeObject.audioPlayer.realtimePlayingInfos
                        .valueOrNull.current.audio.audio.metas.id,
                  );
                }),
              ],
            ),
          ),
        );
      },
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

class Related1 extends StatelessWidget {
  final episodeId;

  Related1({@required this.episodeId});

  SharedPreferences prefs;
  Dio dio = Dio();

  CancelToken _cancel = CancelToken();

  Future episodeRecommendations(var episodeId) async {
    prefs = await SharedPreferences.getInstance();

    String url =
        "https://api.aureal.one/public/recommendedEpisodes?user_id=${prefs.getString('userId')}&size=20&page=0&episode_id=$episodeId";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['episodes'];
      } else {
        print(e);
      }
    } catch (e) {
      print(e);
    }
  }

  Future getPodcastfromEpisodeId(var episodeId) async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/episode?episode_id=$episodeId&user_id=${prefs.getString('userId')}";

    print(url);

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['episode'];
      } else {
        print("Exception Called motherfucker");
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print(e);
    }
  }

  Future getPodcastRecommendations(var podcastId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedPodcasts?page=0&pageSize=10&user_id=${prefs.getString('userId')}&type=podcast_based&podcast_id=$podcastId";
    print(url);

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        return response.data['podcasts'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future getPeopleRecommendation(var podcastId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedArtists?page=0&pageSize=10&user_id=${prefs.getString('userId')}&type=podcast_based&podcast_id=$podcastId";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        return response.data['authors'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future podcastRecommendations(var episodeId) async {
    await getPodcastfromEpisodeId(episodeId).then((value) {
      getPodcastRecommendations(value['podcast_id']);
    });
  }

  Future peopleRecommendations(var episodeId) async {
    await getPodcastfromEpisodeId(episodeId).then((value) {
      getPeopleRecommendation(value['podcastId']);
    });
  }

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    return ListView(
      children: [
        Column(
          children: [
            FutureBuilder(
                future: episodeRecommendations(episodeId),
                builder: (context, snapshot) {
                  try {
                    if (snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              "You might also like",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height / 2.8,
                            child: GridView.builder(
                              itemCount: snapshot.data.length,
                              scrollDirection: Axis.horizontal,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 1,
                                      childAspectRatio: 1.2 / 5.3),
                              // children: [
                              //   for (var a in snapshot.data)
                              //     ListTile(
                              //       onTap: () {
                              //         // List<Audio> playable = [];
                              //         // for (var v
                              //         // in snapshot.data) {
                              //         //   playable.add(Audio.network(
                              //         //     v['url'],
                              //         //     metas: Metas(
                              //         //       id: '${v['id']}',
                              //         //       title: '${v['name']}',
                              //         //       artist: '${v['author']}',
                              //         //       album: '${v['podcast_name']}',
                              //         //       // image: MetasImage.network('https://www.google.com')
                              //         //       image: MetasImage.network(
                              //         //           '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                              //         //     ),
                              //         //   ));
                              //         // }
                              //         // currentlyPlaying.playList =
                              //         //     playable;
                              //         // currentlyPlaying.audioPlayer.open(
                              //         //     Playlist(
                              //         //         audios: currentlyPlaying
                              //         //             .playList,
                              //         //         startIndex:
                              //         //         snapshot.data.
                              //         //             .indexOf(a)),
                              //         //     showNotification: true);
                              //       },
                              //       leading: CircleAvatar(
                              //         radius: 25,
                              //         child: CachedNetworkImage(
                              //           imageBuilder:
                              //               (context, imageProvider) {
                              //             return Container(
                              //               height: 60,
                              //               width: 60,
                              //               decoration: BoxDecoration(
                              //                 borderRadius:
                              //                 BorderRadius.circular(
                              //                     3),
                              //                 image: DecorationImage(
                              //                     image: imageProvider,
                              //                     fit: BoxFit.cover),
                              //               ),
                              //             );
                              //           },
                              //           memCacheHeight:
                              //           (MediaQuery.of(context)
                              //               .size
                              //               .height)
                              //               .floor(),
                              //           imageUrl: a['image'] != null
                              //               ? a['image']
                              //               : placeholderUrl,
                              //           placeholder:
                              //               (context, imageProvider) {
                              //             return Container(
                              //               decoration: BoxDecoration(
                              //                   image: DecorationImage(
                              //                       image: AssetImage(
                              //                           'assets/images/Thumbnail.png'),
                              //                       fit: BoxFit.cover)),
                              //               height: MediaQuery.of(context)
                              //                   .size
                              //                   .width *
                              //                   0.38,
                              //               width: MediaQuery.of(context)
                              //                   .size
                              //                   .width *
                              //                   0.38,
                              //             );
                              //           },
                              //         ),
                              //       ),
                              //       title: Text(
                              //         a['name'].toString(),
                              //         overflow: TextOverflow.ellipsis,
                              //         maxLines: 2,
                              //         textScaleFactor: 1.0,
                              //         style: TextStyle(
                              //             fontSize: SizeConfig
                              //                 .safeBlockHorizontal *
                              //                 3),
                              //       ),
                              //       trailing: Icon(Icons.more_vert),
                              //     ),
                              // ],
                              itemBuilder: (context, int index) {
                                return ListTile(
                                  onTap: () {
                                    // List<Audio> playable = [];
                                    // for (var v
                                    // in snapshot.data) {
                                    //   playable.add(Audio.network(
                                    //     v['url'],
                                    //     metas: Metas(
                                    //       id: '${v['id']}',
                                    //       title: '${v['name']}',
                                    //       artist: '${v['author']}',
                                    //       album: '${v['podcast_name']}',
                                    //       // image: MetasImage.network('https://www.google.com')
                                    //       image: MetasImage.network(
                                    //           '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                    //     ),
                                    //   ));
                                    // }
                                    // currentlyPlaying.playList =
                                    //     playable;
                                    // currentlyPlaying.audioPlayer.open(
                                    //     Playlist(
                                    //         audios: currentlyPlaying
                                    //             .playList,
                                    //         startIndex:
                                    //         snapshot.data.
                                    //             .indexOf(a)),
                                    //     showNotification: true);
                                  },
                                  leading: CircleAvatar(
                                    radius: 25,
                                    child: CachedNetworkImage(
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          height: 60,
                                          width: 60,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover),
                                          ),
                                        );
                                      },
                                      memCacheHeight:
                                          (MediaQuery.of(context).size.height)
                                              .floor(),
                                      imageUrl:
                                          snapshot.data[index]['image'] != null
                                              ? snapshot.data[index]['image']
                                              : placeholderUrl,
                                      placeholder: (context, imageProvider) {
                                        return Container(
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/Thumbnail.png'),
                                                  fit: BoxFit.cover)),
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
                                  title: Text(
                                    snapshot.data[index]['name'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  ),
                                  trailing: Icon(Icons.more_vert),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Container();
                    }
                  } catch (e) {
                    print(e);
                    return Container();
                  }
                }),
            FutureBuilder(
              future: podcastRecommendations(episodeId),
              builder: (context, AsyncSnapshot snapshot) {
                try {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            "Recommended Podcasts",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 4,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: SizeConfig.blockSizeVertical * 25,
                          constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height * 0.17),
                          child: ListView.builder(
                            // addAutomaticKeepAlives: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (context, int index) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(15, 0, 0, 8),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) => PodcastView(
                                                snapshot.data[index]['id'])));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      // x
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    width: MediaQuery.of(context).size.width *
                                        0.38,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CachedNetworkImage(
                                          errorWidget: (context, url, error) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                          placeholderUrl),
                                                      fit: BoxFit.cover),
                                                  borderRadius:
                                                      BorderRadius.circular(3)),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.38,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.38,
                                            );
                                          },
                                          imageBuilder:
                                              (context, imageProvider) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover),
                                                  borderRadius:
                                                      BorderRadius.circular(3)),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.38,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.38,
                                            );
                                          },
                                          memCacheHeight:
                                              (MediaQuery.of(context)
                                                      .size
                                                      .height)
                                                  .floor(),
                                          imageUrl: snapshot.data[index]
                                              ['image'],
                                          placeholder:
                                              (context, imageProvider) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/Thumbnail.png'),
                                                      fit: BoxFit.cover)),
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
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          snapshot.data[index]['name'],
                                          maxLines: 1,
                                          textScaleFactor: 1.0,
                                          overflow: TextOverflow.ellipsis,
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
                                              color: Color(0xffe777777)),
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
                      ],
                    );
                  } else {
                    return Container();
                  }
                } catch (e) {
                  print(e);
                  return Container();
                }
              },
            ),
            FutureBuilder(
              future: peopleRecommendations(episodeId),
              builder: (context, snapshot) {
                try {
                  if (snapshot.data) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            "Podcasters for you",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 4,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(itemBuilder: (context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return PublicProfile(
                                    userId: snapshot.data[index]['id'],
                                  );
                                }));
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CachedNetworkImage(
                                    imageBuilder: (context, imageProvider) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover),
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                4,
                                      );
                                    },
                                    imageUrl: snapshot.data[index]['img'],
                                    memCacheWidth: MediaQuery.of(context)
                                        .size
                                        .width
                                        .floor(),
                                    memCacheHeight: MediaQuery.of(context)
                                        .size
                                        .width
                                        .floor(),
                                    placeholder: (context, url) => Container(
                                      width:
                                          MediaQuery.of(context).size.width / 7,
                                      height:
                                          MediaQuery.of(context).size.width / 7,
                                      child: Image.asset(
                                          'assets/images/Thumbnail.png'),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                4,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                4,
                                            child: Icon(
                                              Icons.error,
                                              color: Color(0xffe8e8e8),
                                            )),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width / 4,
                                      child: Text(
                                        "${snapshot.data[index]['username']}",
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            TextStyle(color: Color(0xffe8e8e8)),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  } else {
                    return Container();
                  }
                } catch (e) {
                  print(e);
                  return Container();
                }
              },
            )

            // SizedBox(
            //   height: 15,
            // ),
            // episodeRecommendations.length == 0
            //     ? SizedBox()
            //     : Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     Padding(
            //       padding: const EdgeInsets.all(15),
            //       child: Text(
            //         "You might also like",
            //         textScaleFactor: 1.0,
            //         style: TextStyle(
            //             fontSize:
            //             SizeConfig.safeBlockHorizontal * 4,
            //             fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //     SizedBox(
            //       height: 15,
            //     ),
            //     Container(
            //       height:
            //       MediaQuery.of(context).size.height / 2.8,
            //       child: GridView(
            //         scrollDirection: Axis.horizontal,
            //         gridDelegate:
            //         SliverGridDelegateWithFixedCrossAxisCount(
            //             crossAxisCount: 4,
            //             mainAxisSpacing: 10,
            //             crossAxisSpacing: 1,
            //             childAspectRatio: 1.2 / 5.3),
            //         children: [
            //           for (var a in episodeRecommendations)
            //             ListTile(
            //               onTap: () {
            //                 List<Audio> playable = [];
            //                 for (var v
            //                 in episodeRecommendations) {
            //                   playable.add(Audio.network(
            //                     v['url'],
            //                     metas: Metas(
            //                       id: '${v['id']}',
            //                       title: '${v['name']}',
            //                       artist: '${v['author']}',
            //                       album: '${v['podcast_name']}',
            //                       // image: MetasImage.network('https://www.google.com')
            //                       image: MetasImage.network(
            //                           '${v['image'] == null ? v['podcast_image'] : v['image']}'),
            //                     ),
            //                   ));
            //                 }
            //                 currentlyPlaying.playList =
            //                     playable;
            //                 currentlyPlaying.audioPlayer.open(
            //                     Playlist(
            //                         audios: currentlyPlaying
            //                             .playList,
            //                         startIndex:
            //                         episodeRecommendations
            //                             .indexOf(a)),
            //                     showNotification: true);
            //               },
            //               leading: CircleAvatar(
            //                 radius: 25,
            //                 child: CachedNetworkImage(
            //                   imageBuilder:
            //                       (context, imageProvider) {
            //                     return Container(
            //                       height: 60,
            //                       width: 60,
            //                       decoration: BoxDecoration(
            //                         borderRadius:
            //                         BorderRadius.circular(
            //                             3),
            //                         image: DecorationImage(
            //                             image: imageProvider,
            //                             fit: BoxFit.cover),
            //                       ),
            //                     );
            //                   },
            //                   memCacheHeight:
            //                   (MediaQuery.of(context)
            //                       .size
            //                       .height)
            //                       .floor(),
            //                   imageUrl: a['image'] != null
            //                       ? a['image']
            //                       : placeholderUrl,
            //                   placeholder:
            //                       (context, imageProvider) {
            //                     return Container(
            //                       decoration: BoxDecoration(
            //                           image: DecorationImage(
            //                               image: AssetImage(
            //                                   'assets/images/Thumbnail.png'),
            //                               fit: BoxFit.cover)),
            //                       height: MediaQuery.of(context)
            //                           .size
            //                           .width *
            //                           0.38,
            //                       width: MediaQuery.of(context)
            //                           .size
            //                           .width *
            //                           0.38,
            //                     );
            //                   },
            //                 ),
            //               ),
            //               title: Text(
            //                 a['name'].toString(),
            //                 overflow: TextOverflow.ellipsis,
            //                 maxLines: 2,
            //                 textScaleFactor: 1.0,
            //                 style: TextStyle(
            //                     fontSize: SizeConfig
            //                         .safeBlockHorizontal *
            //                         3),
            //               ),
            //               trailing: Icon(Icons.more_vert),
            //             ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // podcastRecommendations.length == 0
            //     ? SizedBox()
            //     : Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     SizedBox(
            //       height: 15,
            //     ),
            //     Padding(
            //       padding: const EdgeInsets.all(15),
            //       child: Text(
            //         "Recommended Podcasts",
            //         textScaleFactor: 1.0,
            //         style: TextStyle(
            //             fontSize:
            //             SizeConfig.safeBlockHorizontal * 4,
            //             fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //     Container(
            //       width: double.infinity,
            //       height: SizeConfig.blockSizeVertical * 28,
            //       constraints: BoxConstraints(
            //           minHeight:
            //           MediaQuery.of(context).size.height *
            //               0.17),
            //       child: ListView(
            //         scrollDirection: Axis.horizontal,
            //         children: [
            //           Row(
            //             children: [
            //               for (var a in podcastRecommendations)
            //                 Padding(
            //                   padding:
            //                   const EdgeInsets.fromLTRB(
            //                       15, 0, 0, 8),
            //                   child: InkWell(
            //                     onTap: () {
            //                       Navigator.push(
            //                           context,
            //                           CupertinoPageRoute(
            //                               builder: (context) =>
            //                                   PodcastView(
            //                                       a['id'])));
            //                     },
            //                     child: Container(
            //                       decoration: BoxDecoration(
            //                         // x
            //                         borderRadius:
            //                         BorderRadius.circular(
            //                             15),
            //                       ),
            //                       width: MediaQuery.of(context)
            //                           .size
            //                           .width *
            //                           0.38,
            //                       child: Column(
            //                         crossAxisAlignment:
            //                         CrossAxisAlignment
            //                             .start,
            //                         mainAxisSize:
            //                         MainAxisSize.min,
            //                         children: [
            //                           CachedNetworkImage(
            //                             errorWidget: (context,
            //                                 url, error) {
            //                               return Container(
            //                                 decoration: BoxDecoration(
            //                                     image: DecorationImage(
            //                                         image: NetworkImage(
            //                                             placeholderUrl),
            //                                         fit: BoxFit
            //                                             .cover),
            //                                     borderRadius:
            //                                     BorderRadius
            //                                         .circular(
            //                                         3)),
            //                                 width: MediaQuery.of(
            //                                     context)
            //                                     .size
            //                                     .width *
            //                                     0.38,
            //                                 height: MediaQuery.of(
            //                                     context)
            //                                     .size
            //                                     .width *
            //                                     0.38,
            //                               );
            //                             },
            //                             imageBuilder: (context,
            //                                 imageProvider) {
            //                               return Container(
            //                                 decoration: BoxDecoration(
            //                                     image: DecorationImage(
            //                                         image:
            //                                         imageProvider,
            //                                         fit: BoxFit
            //                                             .cover),
            //                                     borderRadius:
            //                                     BorderRadius
            //                                         .circular(
            //                                         3)),
            //                                 width: MediaQuery.of(
            //                                     context)
            //                                     .size
            //                                     .width *
            //                                     0.38,
            //                                 height: MediaQuery.of(
            //                                     context)
            //                                     .size
            //                                     .width *
            //                                     0.38,
            //                               );
            //                             },
            //                             memCacheHeight:
            //                             (MediaQuery.of(
            //                                 context)
            //                                 .size
            //                                 .height)
            //                                 .floor(),
            //                             imageUrl: a['image'] !=
            //                                 null
            //                                 ? a['image']
            //                                 : placeholderUrl,
            //                             placeholder: (context,
            //                                 imageProvider) {
            //                               return Container(
            //                                 decoration: BoxDecoration(
            //                                     image: DecorationImage(
            //                                         image: AssetImage(
            //                                             'assets/images/Thumbnail.png'),
            //                                         fit: BoxFit
            //                                             .cover)),
            //                                 height: MediaQuery.of(
            //                                     context)
            //                                     .size
            //                                     .width *
            //                                     0.38,
            //                                 width: MediaQuery.of(
            //                                     context)
            //                                     .size
            //                                     .width *
            //                                     0.38,
            //                               );
            //                             },
            //                           ),
            //                           SizedBox(
            //                             height: 5,
            //                           ),
            //                           Text(
            //                             a['name'],
            //                             maxLines: 1,
            //                             textScaleFactor: 1.0,
            //                             overflow: TextOverflow
            //                                 .ellipsis,
            //                             // style:
            //                             //     TextStyle(color: Color(0xffe8e8e8)),
            //                           ),
            //                           Text(
            //                             a['author'],
            //                             maxLines: 2,
            //                             textScaleFactor: 1.0,
            //                             style: TextStyle(
            //                                 fontSize: SizeConfig
            //                                     .safeBlockHorizontal *
            //                                     2.5,
            //                                 color: Color(
            //                                     0xffe777777)),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   ),
            //                 ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // peopleRecommendation.length == 0
            //     ? SizedBox()
            //     : Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     Padding(
            //       padding: const EdgeInsets.all(15),
            //       child: Text(
            //         "Podcasters for you",
            //         textScaleFactor: 1.0,
            //         style: TextStyle(
            //             fontSize:
            //             SizeConfig.safeBlockHorizontal * 4,
            //             fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //     Container(
            //       height:
            //       MediaQuery.of(context).size.height / 5,
            //       child: ListView(
            //         scrollDirection: Axis.horizontal,
            //         children: [
            //           for (var v in peopleRecommendation)
            //             Padding(
            //               padding: const EdgeInsets.all(10),
            //               child: InkWell(
            //                 onTap: () {
            //                   Navigator.push(context,
            //                       CupertinoPageRoute(
            //                           builder: (context) {
            //                             return PublicProfile(
            //                               userId: v['id'],
            //                             );
            //                           }));
            //                 },
            //                 child: Column(
            //                   mainAxisSize: MainAxisSize.min,
            //                   children: [
            //                     CachedNetworkImage(
            //                       imageBuilder:
            //                           (context, imageProvider) {
            //                         return Container(
            //                           decoration: BoxDecoration(
            //                             shape: BoxShape.circle,
            //                             image: DecorationImage(
            //                                 image:
            //                                 imageProvider,
            //                                 fit: BoxFit.cover),
            //                           ),
            //                           width:
            //                           MediaQuery.of(context)
            //                               .size
            //                               .width /
            //                               4,
            //                           height:
            //                           MediaQuery.of(context)
            //                               .size
            //                               .width /
            //                               4,
            //                         );
            //                       },
            //                       imageUrl: v['img'],
            //                       memCacheWidth:
            //                       MediaQuery.of(context)
            //                           .size
            //                           .width
            //                           .floor(),
            //                       memCacheHeight:
            //                       MediaQuery.of(context)
            //                           .size
            //                           .width
            //                           .floor(),
            //                       placeholder: (context, url) =>
            //                           Container(
            //                             width:
            //                             MediaQuery.of(context)
            //                                 .size
            //                                 .width /
            //                                 7,
            //                             height:
            //                             MediaQuery.of(context)
            //                                 .size
            //                                 .width /
            //                                 7,
            //                             child: Image.asset(
            //                                 'assets/images/Thumbnail.png'),
            //                           ),
            //                       errorWidget: (context, url,
            //                           error) =>
            //                           Container(
            //                               width:
            //                               MediaQuery.of(
            //                                   context)
            //                                   .size
            //                                   .width /
            //                                   4,
            //                               height: MediaQuery.of(
            //                                   context)
            //                                   .size
            //                                   .width /
            //                                   4,
            //                               child: Icon(
            //                                 Icons.error,
            //                                 color: Color(
            //                                     0xffe8e8e8),
            //                               )),
            //                     ),
            //                     Padding(
            //                       padding:
            //                       const EdgeInsets.only(
            //                           top: 10),
            //                       child: Container(
            //                         width:
            //                         MediaQuery.of(context)
            //                             .size
            //                             .width /
            //                             4,
            //                         child: Text(
            //                           "${v['username']}",
            //                           textAlign:
            //                           TextAlign.center,
            //                           maxLines: 2,
            //                           overflow:
            //                           TextOverflow.ellipsis,
            //                           style: TextStyle(
            //                               color: Color(
            //                                   0xffe8e8e8)),
            //                         ),
            //                       ),
            //                     )
            //                   ],
            //                 ),
            //               ),
            //             )
            //         ],
            //       ),
            //     ),
            //   ],
            // )
          ],
        ),
      ],
    );
  }
}

class Related extends StatefulWidget {
  final episodeId;

  Related({this.episodeId});

  @override
  State<Related> createState() => _RelatedState();
}

class _RelatedState extends State<Related> with AutomaticKeepAliveClientMixin {
  Dio dio = Dio();

  List episodeRecommendations = [];

  List podcastRecommendations = [];

  List peopleRecommendation = [];

  void getPeopleRecommendation(var podcastId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedArtists?page=0&pageSize=10&user_id=${prefs.getString('userId')}&type=podcast_based&podcast_id=$podcastId";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print(response.data);
        if (mounted) {
          setState(() {
            peopleRecommendation = response.data['authors'];
          });
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future getPodcastfromEpisodeId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/episode?episode_id=${widget.episodeId}&user_id=${prefs.getString('userId')}";

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['episode'];
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print(e);
    }
  }

  void getPodcastRecommendations(var podcastId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedPodcasts?page=0&pageSize=10&user_id=${prefs.getString('userId')}&type=podcast_based&podcast_id=$podcastId";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            podcastRecommendations = response.data['podcasts'];
          });
        }

        print(response.data);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getEpisodeRecommendations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedEpisodes?user_id=${prefs.getString('userId')}&size=20&page=0&episode_id=${widget.episodeId}";
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            episodeRecommendations = response.data['episodes'];
          });
        }

        print(episodeRecommendations);
      } else {
        print(e);
      }
    } catch (e) {
      print(e);
    }
  }

  bool isLoading = true;

  void init() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    await getPodcastfromEpisodeId().then((value) {
      if (value != null) {
        getEpisodeRecommendations();
        getPodcastRecommendations(value['podcast_id']);
        getPeopleRecommendation(value['podcast_id']);
      }
    });
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    return Container(
      child: ModalProgressHUD(
        color: Colors.black,
        inAsyncCall: isLoading,
        child: isLoading == true
            ? SizedBox()
            : ListView(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 15,
                      ),
                      episodeRecommendations.length == 0
                          ? SizedBox()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    "You might also like",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 2.8,
                                  child: GridView(
                                    scrollDirection: Axis.horizontal,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            mainAxisSpacing: 10,
                                            crossAxisSpacing: 1,
                                            childAspectRatio: 1.2 / 5.3),
                                    children: [
                                      for (var a in episodeRecommendations)
                                        ListTile(
                                          onTap: () {
                                            List<Audio> playable = [];
                                            for (var v
                                                in episodeRecommendations) {
                                              playable.add(Audio.network(
                                                v['url'],
                                                metas: Metas(
                                                  id: '${v['id']}',
                                                  title: '${v['name']}',
                                                  artist: '${v['author']}',
                                                  album: '${v['podcast_name']}',
                                                  // image: MetasImage.network('https://www.google.com')
                                                  image: MetasImage.network(
                                                      '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                ),
                                              ));
                                            }
                                            currentlyPlaying.playList =
                                                playable;
                                            currentlyPlaying.audioPlayer.open(
                                                Playlist(
                                                    audios: currentlyPlaying
                                                        .playList,
                                                    startIndex:
                                                        episodeRecommendations
                                                            .indexOf(a)),
                                                showNotification: true);
                                          },
                                          leading: CircleAvatar(
                                            radius: 25,
                                            child: CachedNetworkImage(
                                              imageBuilder:
                                                  (context, imageProvider) {
                                                return Container(
                                                  height: 60,
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3),
                                                    image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover),
                                                  ),
                                                );
                                              },
                                              memCacheHeight:
                                                  (MediaQuery.of(context)
                                                          .size
                                                          .height)
                                                      .floor(),
                                              imageUrl: a['image'] != null
                                                  ? a['image']
                                                  : placeholderUrl,
                                              placeholder:
                                                  (context, imageProvider) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                          image: AssetImage(
                                                              'assets/images/Thumbnail.png'),
                                                          fit: BoxFit.cover)),
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
                                          title: Text(
                                            a['name'].toString(),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3),
                                          ),
                                          trailing: Icon(Icons.more_vert),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      podcastRecommendations.length == 0
                          ? SizedBox()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 15,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    "Recommended Podcasts",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: SizeConfig.blockSizeVertical * 28,
                                  constraints: BoxConstraints(
                                      minHeight:
                                          MediaQuery.of(context).size.height *
                                              0.17),
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      Row(
                                        children: [
                                          for (var a in podcastRecommendations)
                                            Padding(
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
                                                                  a['id'])));
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
                                                                        placeholderUrl),
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
                                                        imageUrl: a['image'] !=
                                                                null
                                                            ? a['image']
                                                            : placeholderUrl,
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
                                                        a['name'],
                                                        maxLines: 1,
                                                        textScaleFactor: 1.0,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        // style:
                                                        //     TextStyle(color: Color(0xffe8e8e8)),
                                                      ),
                                                      Text(
                                                        a['author'],
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
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      peopleRecommendation.length == 0
                          ? SizedBox()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    "Podcasters for you",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 5,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      for (var v in peopleRecommendation)
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(context,
                                                  CupertinoPageRoute(
                                                      builder: (context) {
                                                return PublicProfile(
                                                  userId: v['id'],
                                                );
                                              }));
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CachedNetworkImage(
                                                  imageBuilder:
                                                      (context, imageProvider) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                            image:
                                                                imageProvider,
                                                            fit: BoxFit.cover),
                                                      ),
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                    );
                                                  },
                                                  imageUrl: v['img'],
                                                  memCacheWidth:
                                                      MediaQuery.of(context)
                                                          .size
                                                          .width
                                                          .floor(),
                                                  memCacheHeight:
                                                      MediaQuery.of(context)
                                                          .size
                                                          .width
                                                          .floor(),
                                                  placeholder: (context, url) =>
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
                                                    child: Image.asset(
                                                        'assets/images/Thumbnail.png'),
                                                  ),
                                                  errorWidget: (context, url,
                                                          error) =>
                                                      Container(
                                                          width:
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  4,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                          child: Icon(
                                                            Icons.error,
                                                            color: Color(
                                                                0xffe8e8e8),
                                                          )),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 10),
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            4,
                                                    child: Text(
                                                      "${v['username']}",
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          color: Color(
                                                              0xffe8e8e8)),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ],
                            )
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant Related oldWidget) {
    // TODO: implement didUpdateWidget
    if (oldWidget.episodeId != widget.episodeId) {
      init();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class Banner extends StatelessWidget {
  bool isVideo;

  Banner({this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    return episodeObject.audioPlayer.builderRealtimePlayingInfos(
        builder: (context, infos) {
      if (infos.isBuffering) {
        return CachedNetworkImage(
          imageUrl: placeholderUrl,
          imageBuilder: (context, imageProvider) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: MediaQuery.of(context).size.height / 3,
                  height: MediaQuery.of(context).size.height / 3,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      image: DecorationImage(
                          image: imageProvider, fit: BoxFit.cover)),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 35,
                ),
                ListTile(
                  title: Text(
                    ' ',
                    maxLines: 2,
                    textScaleFactor: 1.0,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: SizeConfig.blockSizeHorizontal * 5,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(" "),
                )
              ],
            );
          },
        );
      } else {
        return CachedNetworkImage(
          imageUrl: infos.current.audio.audio.metas.image.path,
          imageBuilder: (context, imageProvider) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      image: DecorationImage(
                          image: imageProvider, fit: BoxFit.cover)),
                  width: MediaQuery.of(context).size.height / 3,
                  height: MediaQuery.of(context).size.height / 3,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 35,
                ),
                Container(
                  width: MediaQuery.of(context).size.height / 3,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (context) {
                          return EpisodeView(
                              episodeId: episodeObject
                                  .audioPlayer
                                  .realtimePlayingInfos
                                  .value
                                  .current
                                  .audio
                                  .audio
                                  .metas
                                  .id);
                        }));
                      },
                      child: Text(
                        '${infos.current.audio.audio.metas.title}',
                        maxLines: 2,
                        textScaleFactor: 1.0,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: SizeConfig.blockSizeHorizontal * 5,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    subtitle: InkWell(
                      onTap: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (context) {
                          return PublicProfile(
                            userId: episodeObject.episodeObject['user_id'],
                          );
                        }));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${infos.current.audio.audio.metas.artist}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 35,
                ),
              ],
            );
          },
        );
      }
    });
  }
}

class SongSelector extends StatelessWidget {
  final Playing playing;
  final List<Audio> audios;
  final Function(Audio) onSelected;
  final Function(List<Audio>) onPlaylistSelected;

  const SongSelector(
      {this.playing, this.audios, this.onSelected, this.onPlaylistSelected});

  Widget _image(Audio item) {
    if (item.metas.image == null) {
      return SizedBox(height: 40, width: 40);
    }

    return item.metas.image?.type == ImageType.network
        ? CachedNetworkImage(
            imageUrl: item.metas.image.path,
            width: 40,
            height: 40,
          )
        : Image.asset(
            item.metas.image.path,
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          );
  }

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    return Container(
      // height: MediaQuery.of(context).size.height,
      child: ListView.builder(
        // shrinkWrap: true,
        // physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, position) {
          final item = audios[position];
          final isPlaying = item.path == playing?.audio.assetAudioPath;
          return ListTile(
              selected: isPlaying,
              selectedTileColor: Colors.black,
              leading: Material(
                clipBehavior: Clip.antiAlias,
                child: _image(item),
              ),
              title: Text(item.metas.title.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffe8e8e8),
                  )),
              onTap: () {
                onSelected(item);
              });
        },
        itemCount: audios.length,
      ),
    );
  }
}

class TrancriptionPlayer extends StatefulWidget {
  var transcript;

  TrancriptionPlayer({@required this.transcript});

  @override
  _TrancriptionPlayerState createState() => _TrancriptionPlayerState();
}

class _TrancriptionPlayerState extends State<TrancriptionPlayer> {
  int currentIndex = 0;

  ItemScrollController itemScrollController;
  ItemPositionsListener itemPositionsListener;

  PlayerState playerState = PlayerState.playing;

  String actualText = '';

  List transcript = [];

  Widget _dialogContent(int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  "Replace previous selection?",
                  textAlign: TextAlign.center,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "This line is over the character limit and can't be added to your previous selection",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context, false);
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context, true);

                      // setState(() {
                      //   if (index - snippet[snippet.length - 1]['index'] == 1) {
                      //     snippet.add(transcript[index]);
                      //     snippet.removeAt(0);
                      //   }
                      //   if (index - snippet[0]['index'] == -1) {
                      //     snippet = snippet.reversed.toList();
                      //     snippet.add(transcript[index]);
                      //     snippet.removeAt(0);
                      //     snippet = snippet.reversed.toList();
                      //   }
                      //   // if ((index - snippet[0]['index']) < -1) {
                      //   //   int difference = snippet[0]['index'] - index;
                      //   //   snippet = snippet.reversed.toList();
                      //   //   for (int i = difference; i >= 0; i--) {
                      //   //     snippet.add(transcript[index + i]);
                      //   //     snippetString = '';
                      //   //     for (var v in snippet) {
                      //   //       snippetString = snippetString + v['msg'];
                      //   //     }
                      //   //     if (snippetString.length > 150) {
                      //   //       snippet.removeAt(0);
                      //   //     }
                      //   //   }
                      //   //   snippet = snippet.toSet().toList().reversed.toList();
                      //   //   snippetString = '';
                      //   //   for (var v in snippet) {
                      //   //     snippetString = snippetString + v['msg'];
                      //   //   }
                      //   // }
                      //
                      //   for (var v in snippet) {
                      //     print(v['index']);
                      //   }
                      //
                      //   Navigator.pop(context);
                      // });
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Replace",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _selectionFunction(int index) async {
    // setState(() {
    //   if (snippet.length == 0) {
    //     snippet.add(transcript[index]);
    //   } else {
    //     if (snippet.contains(transcript[index]) == true) {
    //       snippet.remove(transcript[index]);
    //     } else {
    //       if (snippetString.length >= 150) {
    //         showDialog(
    //             context: context,
    //             builder: (context) {
    //               return Dialog(
    //                 backgroundColor: Color(0xff1a1a1a),
    //                 child: _dialogContent(index),
    //               );
    //             });
    //       } else {
    //         if (index - snippet[snippet.length - 1]['index'] == 1) {
    //           snippet.add(transcript[index]);
    //         }
    //         if (snippet[0]['index'] - index > 1) {
    //           snippet = snippet.reversed.toSet().toList();
    //           for (int i = (snippet[0]['index'] - 1); i >= index; i--) {
    //             snippet.add(transcript[i]);
    //           }
    //         }
    //       }
    //     }
    //   }
    //   snippetString = '';
    //   for (var v in snippet) {
    //     snippetString = snippetString + v['msg'];
    //   }
    //   print("$snippetString ////////////////////////");
    // });

    if (snippet.length == 0) {
      snippet.add(transcript[index]);
    } else {
      if (snippetString.length < 150) {
        if (snippet.contains(transcript[index])) {
          snippet = [transcript[index]];
        }
        if (index > snippet[snippet.length - 1]['index']) {
          for (int i = snippet[snippet.length - 1]["index"]; i <= index; i++) {
            snippet.add(transcript[i]);
          }
        }
        if (index < snippet[0]['index']) {
          var listElement = snippet[0];
          snippet = snippet.reversed.toList();
          for (int i = snippet[0]['index'] - 1; i >= index; i--) {
            snippet.add(transcript[i]);
          }
          snippet = snippet.toSet().toList().reversed.toList();

          // for (var v in snippet) {
          //   print(v['index']);
          // }
          // for (int i = snippet[snippet.length - 1]['index'];
          //     i > listElement['index'];
          //     i--) {
          //   snippet.remove(transcript[i]);
          // }
        }
      } else {
        if (snippet.contains(transcript[index])) {
          snippet = [transcript[index]];
        } else {
          showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: _dialogContent(index),
                );
              }).then((value) {
            if (value == true) {
              setState(() {
                if (index < snippet[0]['index']) {
                  snippet = snippet.reversed.toList();
                  for (int i = snippet[0]['index'] - 1; i >= index; i--) {
                    snippet.add(transcript[index]);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  while (snippetString.length > 150) {
                    snippet.removeAt(0);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  snippet = snippet.reversed.toList();
                  snippetString = '';
                  for (var v in snippet) {
                    snippetString = snippetString + v['msg'];
                  }
                }
                if (index > snippet[snippet.length - 1]['index']) {
                  for (int i = snippet[snippet.length - 1]['index'] + 1;
                      i <= index;
                      i++) {
                    snippet.add(transcript[i]);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  while (snippetString.length > 150) {
                    snippet.removeAt(0);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  snippet = snippet.reversed.toList();
                  snippetString = '';
                  for (var v in snippet) {
                    snippetString = snippetString + v['msg'];
                  }
                }
              });
            }
          });
        }
      }

      // if (snippet.contains(transcript[index])) {
      //   for (int i = snippet[snippet.length - 1]['index']; i > index; i--) {
      //     snippet.remove(transcript[i]);
      //   }
      // }
    }
    // } else {
    //   showDialog(context: context, builder: (context){
    //     return Dialog(
    //       child: Text("Character Limit Exceeded 150"),
    //     );
    //   });
    // }
    snippetString = '';
    for (var v in snippet) {
      snippetString = snippetString + v['msg'];
    }
    print("$snippetString");
  }

  @override
  void initState() {
    // getTranscription(widget.episode_id);
    // TODO: implement initState

    super.initState();

    setState(() {
      transcript = widget.transcript;
      for (var v in transcript) {
        v['index'] = transcript.indexOf(v);
      }
    });

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    for (var v in widget.transcript) {
      actualText = actualText + v['msg'];
    }

    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();

    var episodeObject = Provider.of<PlayerChange>(context, listen: false);

    episodeObject.audioPlayer.currentPosition.listen((event) {
      var currentPositionSeconds = event.inMilliseconds / 1000;
      if (transcript != null && widget.transcript.length > 0) {
        if (transcript != null && transcript.length > 0) {
          var count = (transcript.indexWhere((element) =>
              element['start_time'] < currentPositionSeconds &&
              element['end_time'] > currentPositionSeconds));
          if (count >= 0) {
            print(count);

            setState(() {
              currentIndex = count;
            });

            itemScrollController.jumpTo(
              index: count,
              alignment: count < 10 ? 0.0 : 0.3,
            );
          }
        }
      }
    });
  }

  int dominantColor = 0xff222222;

  List snippet = [];
  String snippetString = '';

  bool isSelecting = false;

  ScrollController _scrollController;
  double _scrollPosition;

  _scrollListener() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);

    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.black,
        toolbarHeight: MediaQuery.of(context).size.height / 10,
        automaticallyImplyLeading: false,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CachedNetworkImage(
            imageUrl: episodeObject
                .audioPlayer.current.value.audio.audio.metas.image.path,
            imageBuilder: (context, imageProvider) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover)),
                width: MediaQuery.of(context).size.width / 10,
                height: MediaQuery.of(context).size.width / 10,
              );
            },
          ),
          title: Text(
            '${episodeObject.audioPlayer.current.value.audio.audio.metas.title}',
            maxLines: 2,
            textScaleFactor: 1.0,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: SizeConfig.blockSizeHorizontal * 3,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${episodeObject.audioPlayer.current.value.audio.audio.metas.album}",
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ScrollablePositionedList.builder(
                itemCount: transcript.length + 1,
                itemBuilder: (context, index) {
                  // print(itemPositionsListener.itemPositions.value.toString());
                  if (index == currentIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(8),
                              right: Radius.circular(8)),
                        ),
                        selectedTileColor: Colors.black54,
                        selected: snippet.contains(transcript[index]),
                        onTap: () {
                          setState(() {
                            _selectionFunction(index);
                          });
                        },
                        title: Text(
                          '${transcript[index]['msg'].toString().trimLeft().trimRight()}',
                          style: TextStyle(
                              height: 1.8,
                              fontSize: SizeConfig.safeBlockHorizontal * 6,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    );
                  } else {
                    if (index == transcript.length) {
                      return SizedBox(
                        height: 300,
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(8)),
                          ),
                          onTap: () {
                            setState(() {
                              _selectionFunction(index);
                            });
                          },
                          selectedTileColor: Colors.black54,
                          selected: snippet.contains(transcript[index]),
                          title: Text(
                            '${transcript[index]['msg'].toString().trimLeft().trimRight()}',
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 6,
                                fontWeight: FontWeight.w600,
                                height: 1.8,
                                color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                      );
                    }
                  }
                },
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                  ),

                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      snippet.length == 0
                          ? SizedBox()
                          : Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        snippet = [];
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                        Color(0xff5d5da8),
                                        Colors.red
                                      ])),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text("CANCEL"),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context,
                                          CupertinoPageRoute(
                                              builder: (context) {
                                        return EditSnippet(
                                          snippetString: snippetString,
                                          snippet: snippet,
                                        );
                                      }));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                        Color(0xff5d5da8),
                                        Color(0xff5bc3ef)
                                      ])),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text("CREATE CLIP"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      SizedBox(
                        height: 20,
                      ),
                      episodeObject.audioPlayer.builderRealtimePlayingInfos(
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
                              itemScrollController.jumpTo(
                                index: currentIndex,

                                // curve: Curves.easeInCirc,
                              );
                            },
                          );
                        }
                      }),
                      episodeObject.audioPlayer.builderRealtimePlayingInfos(
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
                              return FloatingActionButton(
                                  child: Icon(Icons.pause),
                                  backgroundColor: Colors.blue,
                                  onPressed: () {
                                    episodeObject.pause();
                                    setState(() {
                                      playerState = PlayerState.paused;
                                    });
                                  });
                            } else {
                              return FloatingActionButton(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.play_arrow_rounded),
                                  onPressed: () {
                                    // play(url);
                                    episodeObject.resume();
                                    setState(() {
                                      playerState = PlayerState.playing;
                                    });
                                  });
                            }
                          }
                        }
                      }),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                  // color: Colors.blue,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class EditSnippet extends StatefulWidget {
  String snippetString;
  List snippet;
  var snippetObject;
  bool isEditing;

  EditSnippet({this.snippetString, this.snippet});

  @override
  _EditSnippetState createState() => _EditSnippetState();
}

class _EditSnippetState extends State<EditSnippet> {
  TextEditingController controller;

  postreq.Interceptor intercept = postreq.Interceptor();

  String title;

  void addCLip() async {
    String url = 'https://api.aureal.one/private/createSnippet';
    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    var map = Map<String, dynamic>();
    map['episode_id'] = episodeObject.episodeObject['id'];
    map['words'] = widget.snippetString;
    map['start_time'] = widget.snippet[0]['start_time'];
    map['end_time'] = widget.snippet[widget.snippet.length - 1]['end_time'];
    map['title'] = title;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      Navigator.push(context, CupertinoPageRoute(builder: (context) {
        return ClipScreen();
      }));
    } catch (e) {
      print(e);
    }
  }

  String snippetText = '';
  @override
  void initState() {
    // TODO: implement initState
    controller = TextEditingController(
        text: "${widget.snippetString.trimLeft().trimRight()}");
    super.initState();
    setState(() {
      snippetText = widget.snippetString.trimRight().trimLeft();
    });
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        title: Text(
          "Edit Clip",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Color(0xff1a1a1a),
                            borderRadius: BorderRadius.circular(5)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CachedNetworkImage(
                                imageUrl: episodeObject.episodeObject['image'],
                                imageBuilder: (context, imageProvider) {
                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.width / 6,
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${episodeObject.episodeObject['name']}",
                                        maxLines: 1,
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        "${episodeObject.episodeObject['podcast_name']}",
                                        textScaleFactor: 1.0,
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                title = value;
                              });
                            },
                            decoration: InputDecoration(
                                labelText: 'Give your snippet a title',
                                labelStyle: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 5)),
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 6),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "(Optional)",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          maxLength: 200,
                          onChanged: (value) {
                            setState(() {
                              snippetText = value;
                            });
                            print(snippetText);
                          },
                          controller: controller,
                          maxLines: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigator.push(context,
                      //     CupertinoPageRoute(builder: (context) {
                      //   return SnippetShare(snippet: snippetText);
                      // }));
                      addCLip();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Color(0xffe8e8e8),
                          borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        child: Text(
                          "Create",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SnippetShare extends StatefulWidget {
  var snippet;

  var episodeDetails;

  SnippetShare({@required this.snippet, @required this.episodeDetails});

  @override
  _SnippetShareState createState() => _SnippetShareState();
}

class _SnippetShareState extends State<SnippetShare> {
  ScreenshotController squareScreenshotController = ScreenshotController();
  ScreenshotController rectScreenshotController = ScreenshotController();

  Future<dynamic> ShowCapturedWidget(
      BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: true,
      context: context,
      builder: (context) {
        return Container(
          color: Colors.black.withOpacity(0.7),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                height: MediaQuery.of(context).size.height * 0.75,
                width: MediaQuery.of(context).size.width * 0.75,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.memory(
                      capturedImage,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          onPressed: () {},
                          child: Icon(FontAwesomeIcons.square),
                        ),
                        FloatingActionButton(
                          onPressed: () {},
                          child: Icon(FontAwesomeIcons.react),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  bool isSquare = false;

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.black54,
                child: Icon(Icons.crop_square),
                onPressed: () {
                  setState(() {
                    isSquare = true;
                  });
                },
              ),
              FloatingActionButton(
                backgroundColor: Colors.black54,
                child: Icon(Icons.crop_16_9_outlined),
                onPressed: () {
                  // rectScreenshotController
                  //     .capture(delay: Duration(milliseconds: 10))
                  //     .then((capturedImage) async {
                  //   ShowCapturedWidget(context, capturedImage);
                  // }).catchError((onError) {
                  //   print(onError);
                  // });
                  setState(() {
                    isSquare = false;
                  });
                },
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () async {
                if (isSquare == true) {
                  // await squareScreenshotController
                  //     .capture(delay: Duration(milliseconds: 10))
                  //     .then((capturedImage) async {
                  //
                  //   // ShowCapturedWidget(context, capturedImage);
                  // }).catchError((onError) {
                  //   print(onError);
                  // });
                  await squareScreenshotController
                      .capture(delay: const Duration(milliseconds: 10))
                      .then((Uint8List image) async {
                    if (image != null) {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final imagePath =
                          await File('${directory.path}/image.png').create();
                      await imagePath.writeAsBytes(image);

                      /// Share Plugin
                      await Share.shareFiles([imagePath.path],
                          text:
                              "${widget.snippet['words'].toString().trimLeft().trimRight()} \n https://aureal.one/episode/${widget.episodeDetails['episode_id']} \n #YourVoiceIsworthSomething #Aureal");
                    }
                  });
                } else {
                  await rectScreenshotController
                      .capture(delay: const Duration(milliseconds: 10))
                      .then((Uint8List image) async {
                    if (image != null) {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final imagePath =
                          await File('${directory.path}/image.png').create();
                      await imagePath.writeAsBytes(image);

                      /// Share Plugin
                      await Share.shareFiles([imagePath.path],
                          text:
                              "${widget.snippet['words'].toString().trimLeft().trimRight()} \n https://aureal.one/episode/${widget.episodeDetails['episode_id']} \n #YourVoiceIsworthSomething #Aureal");
                    }
                  });
                  // await rectScreenshotController
                  //     .capture(delay: Duration(milliseconds: 10))
                  //     .then((capturedImage) async {
                  //
                  //   // ShowCapturedWidget(context, capturedImage);
                  // }).catchError((onError) {
                  //   print(onError);
                  // });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black,
                ),
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Text(
                      "Share",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            isSquare == true
                ? Center(
                    child: Screenshot(
                      controller: squareScreenshotController,
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                              Color(0xff5d5da8),
                              Color(0xff5bc3ef)
                            ])),
                        width: MediaQuery.of(context).size.width * 1.1,
                        height: MediaQuery.of(context).size.width * 1.1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(10),
                                        topLeft: Radius.circular(10))),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 30),
                                  child: Column(
                                    children: [
                                      Icon(FontAwesomeIcons.quoteLeft),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 20),
                                        child: Text(
                                          "${widget.snippet['words']}",
                                          textScaleFactor: 1.0,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  5,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Icon(FontAwesomeIcons.quoteRight),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20, left: 40, right: 40),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10))),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8, bottom: 8, top: 8),
                                      child: Row(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: widget.episodeDetails[
                                                'podcast_image'],
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover),
                                                ),
                                              );
                                            },
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${widget.episodeDetails['episode_name']}",
                                                    maxLines: 1,
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff1a1a1a),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3),
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    "${widget.episodeDetails['podcast_name']}",
                                                    textScaleFactor: 1.0,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff1a1a1a),
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            2.5),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 5,
                                      bottom: 5,
                                      child: Image.asset(
                                        'assets/images/Favicon.png',
                                        cacheHeight: (MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                4)
                                            .floor(),
                                        height: 30,
                                        width: 30,
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
                  )
                : Screenshot(
                    controller: rectScreenshotController,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xff5d5da8), Color(0xff5bc3ef)])),
                      child: Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      topLeft: Radius.circular(10))),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30),
                                child: Column(
                                  children: [
                                    Icon(FontAwesomeIcons.quoteLeft),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 20),
                                      child: Text(
                                        "${widget.snippet['words']}",
                                        textScaleFactor: 1.0,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    5,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Icon(FontAwesomeIcons.quoteRight),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20, left: 40, right: 40),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10))),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, right: 8, bottom: 8, top: 8),
                                    child: Row(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: widget
                                              .episodeDetails['podcast_image'],
                                          imageBuilder:
                                              (context, imageProvider) {
                                            return Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  6,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  6,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover),
                                              ),
                                            );
                                          },
                                        ),
                                        Flexible(
                                          child: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${widget.episodeDetails['episode_name']}",
                                                  maxLines: 1,
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      color: Color(0xff1a1a1a),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          3),
                                                ),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  "${widget.episodeDetails['podcast_name']}",
                                                  textScaleFactor: 1.0,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Color(0xff1a1a1a),
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          2.5),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 5,
                                    bottom: 5,
                                    child: Image.asset(
                                      'assets/images/Favicon.png',
                                      cacheHeight:
                                          (MediaQuery.of(context).size.height /
                                                  4)
                                              .floor(),
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10))),
                              height: MediaQuery.of(context).size.height / 3.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "#YourVoiceIsWorthSomething",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    "aureal.one",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class ClipScreen extends StatefulWidget {
  @override
  _ClipScreenState createState() => _ClipScreenState();
}

class _ClipScreenState extends State<ClipScreen> {
  postreq.Interceptor intercept = postreq.Interceptor();

  var clips = [];

  void edit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  void delete(var snippetId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/deleteSnippet';

    var map = Map<String, dynamic>();
    map['snippet_id'] = snippetId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  void getClips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getSnippet?user_id=${prefs.getString('userId')}";
    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          clips = jsonDecode(response.body)['snippets'];
          for (var v in clips) {
            v['isPlaying'] = false;
          }
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getClips();
  }

  int currentIndex = 0;

  ScrollController controller = ScrollController();

  void share(var snippetObject) async {
    await FlutterShare.share(
        text: "Here's a Snapshot from ${snippetObject['podcast_name']} ",
        title: 'Snapshot from ${snippetObject['episode_name']}',
        chooserTitle: "Here's a snapshot for you",
        linkUrl: 'https://aureal.one/snippet/${snippetObject['id']}');
  }

  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Your Clips",
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
          textScaleFactor: 1.0,
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 9 / 14,
          children: [
            for (var v in clips)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                  v['podcast_image']),
                              fit: BoxFit.cover)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.black, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${v['episode_name']}",
                              textScaleFactor: 0.75,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                    onTap: () {
                                      if (v['isPlaying'] == false) {
                                        audioPlayer
                                            .open(Audio.network(v['url']));
                                        setState(() {
                                          v['isPlaying'] = true;
                                        });
                                      } else {
                                        setState(() {
                                          v['isPlaying'] = false;
                                        });
                                        audioPlayer.stop();
                                      }
                                    },
                                    child: Icon(v['isPlaying'] == true
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill)),
                                InkWell(
                                    onTap: () {
                                      showBarModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  title: Text(
                                                    "${v['episode_name']}",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3),
                                                  ),
                                                  trailing: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: CachedNetworkImage(
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              10,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              10,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                      imageUrl:
                                                          v['podcast_image'],
                                                    ),
                                                  ),
                                                ),
                                                Divider(),
                                                ListTile(
                                                  onTap: () {
                                                    delete(v['id']);
                                                    Navigator.pop(context);
                                                    getClips();
                                                  },
                                                  title: Text(
                                                    "Delete",
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3),
                                                  ),
                                                ),
                                                ListTile(
                                                  onTap: () {
                                                    share(v);
                                                  },
                                                  title: Text(
                                                    "Share",
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3),
                                                  ),
                                                )
                                              ],
                                            );
                                          });
                                    },
                                    child: Icon(Icons.more_vert))
                              ],
                            )
                          ],
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

class EditClip extends StatefulWidget {
  var episodeDetails;

  var clipDetails;

  EditClip({@required this.episodeDetails, @required this.clipDetails});

  @override
  _EditClipState createState() => _EditClipState();
}

class _EditClipState extends State<EditClip> {
  String title;

  TextEditingController titleController = TextEditingController();
  TextEditingController clipController = TextEditingController();

  postreq.Interceptor intercept = postreq.Interceptor();

  void editClip(var snippetId, var snippetTitle, var snippetWords) async {
    String url = "https://api.aureal.one/private/updateSnippet";

    var map = Map<String, dynamic>();

    map['snippet_id'] = snippetId;
    map['title'] = snippetTitle;
    map['words'] = snippetWords;

    FormData formData = FormData.fromMap(map);

    print(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      Navigator.pop(context, true);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      titleController.text =
          widget.clipDetails['title'].toString().trimRight().trimLeft();
      clipController.text =
          widget.clipDetails['words'].toString().trimLeft().trimRight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Clip",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Color(0xff1a1a1a),
                            borderRadius: BorderRadius.circular(5)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CachedNetworkImage(
                                imageUrl: widget.episodeDetails['episode']
                                    ['podcast_image'],
                                imageBuilder: (context, imageProvider) {
                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.width / 6,
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${widget.episodeDetails['episode']['episode_name']}",
                                        maxLines: 1,
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        "${widget.episodeDetails['episode']['podcast_name']}",
                                        textScaleFactor: 1.0,
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: titleController,
                            onChanged: (value) {
                              setState(() {
                                title = value;
                              });
                            },
                            decoration: InputDecoration(
                                labelText: 'Title',
                                labelStyle: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 5)),
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 6),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "(Optional)",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: clipController,
                          maxLength: 200,
                          onChanged: (value) {
                            // setState(() {
                            //   snippetText = value;
                            // });
                            // print(snippetText);
                          },
                          // controller: controller,
                          maxLines: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigator.push(context,
                      //     CupertinoPageRoute(builder: (context) {
                      //   return SnippetShare(snippet: snippetText);
                      // }));
                      // addCLip();

                      editClip(widget.clipDetails['id'], titleController.text,
                          clipController.text);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Color(0xffe8e8e8),
                          borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        child: Text(
                          "Update",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
