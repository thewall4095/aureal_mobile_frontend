import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/DatabaseFunctions/EpisodesProvider.dart';
import 'package:auditory/screens/FollowingPage.dart';
import 'package:auditory/screens/Player/PlayerElements/Seekbar.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:marquee/marquee.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../../PlayerState.dart';

enum PlayerState {
  playing,
  paused,
  stopped,
}

class DownloadPage extends StatefulWidget {
  static const String id = "DownloadsPage";

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage>
    with SingleTickerProviderStateMixin {
  final _mp = EpisodesProvider.getInstance();

  RegExp htmlMatch = RegExp(r'(\w+)');

  var episodeList = [];
  var storedepisodes = [];
  var tasks = [];
  void getDownloadTasks() async {
    tasks = await FlutterDownloader.loadTasks();
    print(tasks.toString());
    // print(tasks[0].progress);
    print('aaaaaaaaaaa');
  }

  void getDownloads() async {
    storedepisodes = await _mp.getAllEpisodes();
    print(storedepisodes.length);

    // print(storedepisodes[0].toJson().toString());
    // print(storedepisodes[0].toJson().toString());
    // print(storedepisodes[0].status);
    var episodes = [];
    for (var i = 0; i < storedepisodes.length; i++) {
      for (var j = 0; j < tasks.length; j++) {
        if (storedepisodes[i].taskId == tasks[j].taskId) {
          var episode = {
            "name": storedepisodes[i].name,
            "url": tasks[j].savedDir + '/' + tasks[j].filename,
            "podcastName": storedepisodes[i].podcastName,
            "summary": storedepisodes[i].summary,
            "image": storedepisodes[i].image,
            "savedDir": tasks[j].savedDir,
            "progress": tasks[j].progress
          };
          episodes.add(episode);
        }
      }
    }
    print('bbbbbbbbbb');

    setState(() {
      episodeList = episodes;
      print(episodeList.toString());
      print(episodeList.length);
    });
  }

  playDownload(savedDir) {}

  var episodeObject;

  bool showBottomSheet = false;

  @override
  void initState() {
    // TODO: implement initState
    getDownloadTasks();
    getDownloads();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final currentlyPlaying = Provider.of<PlayerChange>(context);
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
//       body: NestedScrollView(
//         headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
//           return <Widget>[
//             SliverAppBar(
//               elevation: 0,
//               backgroundColor: Colors.transparent,
//               leading: IconButton(
//                 icon: Container(
//                   decoration: BoxDecoration(
//                       shape: BoxShape.circle, border: Border.all(width: 1.5)),
//                   child: CircleAvatar(
//                     backgroundImage: AssetImage('assets/images/user.png'),
//                     radius: 14,
//                     backgroundColor: Colors.transparent,
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.pushNamed(context, Profile.id);
//                 },
//               ),
//               actions: <Widget>[
// //                IconButton(
// //                  icon: Icon(
// //                    Icons.settings,
// //                    color: Colors.white,
// //                  ),
// //                  onPressed: () => debugPrint('Action Download'),
// //                ),
//               ],
//               expandedHeight: 170,
//               pinned: true,
//               flexibleSpace: FlexibleSpaceBar(
//                 background: Container(
//                   padding: EdgeInsets.fromLTRB(16, 0, 0, 64),
//                   height: 50,
//                   alignment: Alignment.bottomLeft,
//                   child: Text('Downloads',
//                      textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
//                       style: TextStyle(
//                         fontSize: 36,
//                         fontWeight: FontWeight.bold,
//                       )),
//                 ),
//               ),
//             ),
//           ];
//         },
//         body: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 15),
//           child: Container(
//               child: episodeList.length == 0
//                   ? Text(
//                       "There is nothing here as of now",
//                      textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
//                     )
//                   : ListView(
//                       children: <Widget>[
//                         for (var v in episodeList)
//                           // Padding(
//                           //   padding: const EdgeInsets.symmetric(vertical: 5),
//                           //   child: GestureDetector(
//                           //     onTap: () {
//                           //       playDownload(v['id']);
//                           //     },
//                           //     child: Container(
//                           //       width: double.infinity,
//                           //       child: Row(
//                           //         mainAxisAlignment:
//                           //             MainAxisAlignment.spaceBetween,
//                           //         children: <Widget>[
//                           //           Container(
//                           //             height: 65,
//                           //             width: 65,
//                           //             child: FadeInImage.assetNetwork(
//                           //               placeholder:
//                           //                   'assets/images/Thumbnail.png',
//                           //               image: v['image'] == null
//                           //                   ? 'assets/images/Thumbnail.png'
//                           //                   : v['image'],
//                           //               fit: BoxFit.cover,
//                           //             ),
//                           //           ),
//                           //           SizedBox(
//                           //             width: 10,
//                           //           ),
//                           //           Expanded(
//                           //             child: Column(
//                           //               children: <Widget>[
//                           //                 Text(
//                           //                   v['name'],
//                           //                  textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
//                           //                   style: TextStyle(
//                           //                       fontSize: SizeConfig
//                           //                               .safeBlockHorizontal *
//                           //                           3.2),
//                           //                 ),
//                           //               ],
//                           //             ),
//                           //           )
//                           //         ],
//                           //       ),
//                           //     ),
//                           //   ),
//                           // )
//                           Container(
//                             height: 100,
//                             width: double.infinity,
//                             color: Colors.blue,
//                           )
//                       ],
//                     )),
//         ),
//       ),
      appBar: AppBar(
        title: Text(
          'Downloaded Episodes',
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: Container(
        child: episodeList.length == 0
            ? Container(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width / 2,
                            height: MediaQuery.of(context).size.width / 2,
                            child: Image.asset('assets/images/Mascot.png'),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "No Downloads..!",
                                style: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 5),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Icon(Icons.download_outlined),
                          ),
                          Text("You can now download your favourate podcast.")
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return FollowingPage();
                              });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kSecondaryColor)
                              //  color: kSecondaryColor,
                              ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(FontAwesomeIcons.download),
                                SizedBox(
                                  width: 8.0,
                                ),
                                Text(
                                  'Browse',
                                  style: TextStyle(
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 100,
                      )
                    ],
                  ),
                ),
              )
            : ListView(
                children: [
                  for (var v in episodeList)
             Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 15),
                      child: Container(
                        decoration: BoxDecoration(
                            // color: Colors.blue,
                            border: Border(
                                bottom: BorderSide(
                                    color: kSecondaryColor, width: 2))),
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20 ,horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height:
                                        MediaQuery.of(context).size.width / 7,
                                    width:
                                        MediaQuery.of(context).size.width / 7,
                                    child: CachedNetworkImage(

                                        imageBuilder: (context, imageProvider) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              image: DecorationImage(
                                                  image: imageProvider, fit: BoxFit.cover),
                                            ),
                                          );
                                        },
                                        memCacheHeight: (MediaQuery.of(context).size.height).floor(),
                                        placeholder: (context, url) => Container(
                                          height:
                                          MediaQuery.of(context).size.width / 7,
                                          width:
                                          MediaQuery.of(context).size.width / 7,
                                          child: Image.asset('assets/images/Thumbnail.png'),
                                        ),
                                      imageUrl: v['image']
                                            // ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                            // : v['image'],
                                        //fit: BoxFit.cover,
                                      ),
                                    ),

                                  SizedBox(
                                    width: 10,
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${v['podcastName']}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textScaleFactor: mediaQueryData
                                            .textScaleFactor
                                            .clamp(0.2, 1)
                                            .toDouble(),
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    5.5),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Container(
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['name'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textScaleFactor: mediaQueryData
                                            .textScaleFactor
                                            .clamp(0.2, 1)
                                            .toDouble(),
                                        style: TextStyle(
                                            // color: Color(
                                            //     0xffe8e8e8),
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: htmlMatch
                                                    .hasMatch(v['summary']) ==
                                                true
                                            ? Text(
                                                parse(v['summary']).body.text,

                                          overflow: TextOverflow.ellipsis,

                                                textScaleFactor: mediaQueryData
                                                    .textScaleFactor
                                                    .clamp(0.2, 1)
                                                    .toDouble(),
                                                maxLines: 2,
                                                style: TextStyle(
                                                    // color: Colors.white,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3.2),
                                              )
                                            : Text(
                                                '${v['summary']}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                                textScaleFactor: mediaQueryData
                                                    .textScaleFactor
                                                    .clamp(0.2, 1)
                                                    .toDouble(),
                                                style: TextStyle(
                                                    //      color: Colors.white,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3.2),
                                              ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            setState(() {
                                              episodeObject = v;
                                              showBottomSheet = true;
                                            });
                                          },
                                          child: Container(
                                            decoration: v['ifVoted'] == true
                                                ? BoxDecoration(
                                                    gradient: LinearGradient(
                                                        colors: [
                                                          Color(0xff5bc3ef),
                                                          Color(0xff5d5da8)
                                                        ]),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30))
                                                : BoxDecoration(
                                                    border: Border.all(
                                                        color: kSecondaryColor),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 10),
                                              child: Row(
                                                children: [
                                                  v['isLoading'] == true
                                                      ? Container(
                                                          height: 18,
                                                          width: 18,
                                                          child: SpinKitPulse(
                                                            color: Colors.blue,
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons
                                                              .play_circle_outline,
                                                          size: 15,
                                                          // color:
                                                          //     Color(0xffe8e8e8),
                                                        ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 8),
                                                    child: Text(
                                                      'Play',
                                                      textScaleFactor: 1.0,
                                                      style: TextStyle(
                                                          fontSize: 12
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
                                        SizedBox(
                                          width: SizeConfig.screenWidth / 30,
                                        ),
                                      ],
                                    ),
                                    // Row(
                                    //   children: [
                                    //     IconButton(
                                    //       icon: Icon(
                                    //         FontAwesomeIcons.shareAlt,
                                    //         size:
                                    //             SizeConfig.safeBlockHorizontal *
                                    //                 4,
                                    //         // color: Color(
                                    //         //     0xffe8e8e8),
                                    //       ),
                                    //       onPressed: () async {
                                    //         // share(v);
                                    //       },
                                    //     )
                                    //   ],
                                    // )
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
      bottomSheet: showBottomSheet == false
          ? SizedBox(
              height: 0,
              width: 0,
            )
          : OfflineBottomPlayer(
              episodeObject: episodeObject,
            ),
    );
  }
}

class OfflineBottomPlayer extends StatefulWidget {
  var episodeObject;

  OfflineBottomPlayer({@required this.episodeObject});

  @override
  _OfflineBottomPlayerState createState() => _OfflineBottomPlayerState();
}

class _OfflineBottomPlayerState extends State<OfflineBottomPlayer> {
  PlayerState state = PlayerState.playing;

  AssetsAudioPlayer audioPlayer;

  void play() async {
    audioPlayer.stop();
    audioPlayer.open(
      Audio.file('${widget.episodeObject['url']}',
          metas: Metas(
              title: widget.episodeObject['name'],
              album: widget.episodeObject['podcastName'],
              image: MetasImage.asset(widget.episodeObject['image'] == null
                  ? 'assets/images/Thumbnail.png'
                  : widget.episodeObject['image']))),
      showNotification: true,
      // notificationSettings: NotificationSettings(
      //     nextEnabled: false, prevEnabled: false, seekBarEnabled: true),
    ); /////This is still getting worked on!
    // audioPlayer.open(
    //     Audio.network(_episodeObject['savedDir'],
    //         metas: Metas(
    //           title: _episodeObject['name'],
    //           album: _episodeObject['podcast_name'],
    //           artist: _episodeObject['author'],
    //           image: MetasImage.network(_episodeObject['image']),
    //         )),
    //     showNotification: true,
    //     notificationSettings: NotificationSettings(
    //         nextEnabled: false, prevEnabled: false, seekBarEnabled: true));
  }

  void pause() async {
    MediaNotification.showNotification(
        title: widget.episodeObject['name'],
        author: widget.episodeObject['podcast_name'],
        isPlaying: false);
    state = PlayerState.paused;
    audioPlayer.pause();
  }

  void stop() async {
    state = PlayerState.stopped;
    audioPlayer.stop();
  }

  void resume() {
    audioPlayer.play();
  }

  @override
  void initState() {
    audioPlayer = AssetsAudioPlayer();
    // TODO: implement initState
    super.initState();
    play();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showBarModalBottomSheet(
            //  barrierColor: Colors.transparent,
            context: context,
            builder: (context) {
              return OfflinePlayer(
                episodeObject: widget.episodeObject,
                audiocontroller: audioPlayer,
              );
            });
      },
      child: Container(
        height: SizeConfig.safeBlockVertical * 7,
        width: double.infinity,
        decoration: BoxDecoration(border: Border.all()),
        //  color: kSecondaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                audioPlayer.builderRealtimePlayingInfos(
                    builder: (context, infos) {
                  if (infos == null) {
                    return SizedBox(
                      height: 0,
                      width: 0,
                    );
                  } else {
                    if (infos.isBuffering == true) {
                      return SpinKitCircle(
                        size: 15,
                        color: Colors.white,
                      );
                    } else {
                      if (infos.isPlaying == true) {
                        return IconButton(
                          splashColor: Colors.blue,
                          icon: Icon(
                            Icons.pause,
                            //color: Colors.white,
                          ),
                          onPressed: () {
                            audioPlayer.pause();
                          },
                        );
                      } else {
                        return IconButton(
                          splashColor: Colors.blue,
                          icon: Icon(
                            Icons.play_arrow,
                            // color: Colors.white,
                          ),
                          onPressed: () {
                            audioPlayer.play();
                          },
                        );
                      }
                    }
                  }
                }),
                // audioPlayer.builderRealtimePlayingInfos(
                //     builder: (context, infos) {
                //   if (infos == null) {
                //     return SizedBox(
                //       height: 0,
                //       width: 0,
                //     );
                //   } else {
                //     if (infos.isBuffering == true) {
                //       return SpinKitCircle(
                //         size: 15,
                //         color: Colors.white,
                //       );
                //     } else {
                //       if (infos.isPlaying == true) {
                //         return IconButton(
                //           splashColor: Colors.blue,
                //           icon: Icon(
                //             Icons.pause,
                //             //color: Colors.white,
                //           ),
                //           onPressed: () {
                //             pause();
                //           },
                //         );
                //       } else {
                //         return IconButton(
                //           splashColor: Colors.blue,
                //           icon: Icon(
                //             Icons.play_arrow,
                //             //    color: Colors.white,
                //           ),
                //           onPressed: () {
                //             resume();
                //           },
                //         );
                //       }
                //     }
                //   }
                // }),
                // InkWell(
                //   onTap: () {
                //     {
                //       if (episodeObject.permlink == null) {
                //       } else {
                //         upvoteEpisode(
                //             episode_id: episodeObject.id,
                //             permlink: episodeObject.permlink);
                //       }
                //     }
                //   },
                //   child: Padding(
                //     padding: const EdgeInsets.all(3.0),
                //     child: IconButton(
                //       splashColor: Colors.blue,
                //       icon: Icon(
                //         FontAwesomeIcons.chevronCircleUp,
                //         // color: _hasBeenPressed ? Colors.blue : Colors.black,
                //         //color: Colors.white,
                //       ),
                //       // onPressed: () => {
                //       // setState(() {
                //       // _hasBeenPressed = !_hasBeenPressed;
                //       // })
                //
                //       // }
                //     ),
                //   ),
                // ),
                SizedBox(
                  width: 10,
                ),
                Container(
                  height: 40,
                  width: MediaQuery.of(context).size.width / 1.5,
                  child: Marquee(
                    pauseAfterRound: Duration(seconds: 2),
                    text:
                        '${widget.episodeObject['name']}  -  ${widget.episodeObject['podcastName']}',
                    style: TextStyle(
                        //   color: Colors.white,
                        fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                    blankSpace: 100,
//                  scrollAxis: Axis.horizontal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OfflinePlayer extends StatefulWidget {
  var episodeObject;

  AssetsAudioPlayer audiocontroller;

  OfflinePlayer({@required this.episodeObject, @required this.audiocontroller});

  @override
  _OfflinePlayerState createState() => _OfflinePlayerState();
}

class _OfflinePlayerState extends State<OfflinePlayer> {
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    return Container(
      height: MediaQuery.of(context).size.height / 1.5,
      width: double.infinity,
      child: Scaffold(
        //  backgroundColor: kSecondaryColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.width * 0.75,
              width: MediaQuery.of(context).size.width * 0.75,
              //  color: Colors.white,
              // child: Image.file(widget.episodeObject['image']),
              child: CachedNetworkImage(
                imageUrl: widget.episodeObject['image'],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Container(
                height: 40,
                child: Marquee(
                  pauseAfterRound: Duration(seconds: 2),
                  text: '${widget.episodeObject['name']}',

                  style: TextStyle(
                      //   color: Colors.white,

                      fontSize: SizeConfig.safeBlockHorizontal * 4.2),
                  blankSpace: 100,
//                  scrollAxis: Axis.horizontal,
                ),
              ),
            ),
            widget.audiocontroller.builderRealtimePlayingInfos(
              builder: (context, infos) {
                if (infos == null) {
                  return SizedBox(
                    height: 0,
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Seekbar(
                      currentPosition: infos.currentPosition,
                      duration: infos.duration,
                      episodeName: widget.episodeObject['name'],
                      seekTo: (to) {
                        widget.audiocontroller.seek(to);
                      },
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${widget.episodeObject['podcastName']}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // CircleAvatar(
                //   radius: 20,
                //   foregroundColor: Colors.white,
                //   backgroundColor: Colors.blue,
                //   //      backgroundColor: Colors.white,
                //   child: IconButton(
                //     icon: Icon(
                //       FontAwesomeIcons.bolt,
                //       size: 16,
                //       //  color: Colors.black,
                //     ),
                //     onPressed: () {
                //       showDialog(
                //           context: context,
                //           builder: (context) {
                //             return Dialog(
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(30),
                //               ),
                //               child: Container(
                //                 decoration: BoxDecoration(
                //                   borderRadius: BorderRadius.circular(10),
                //                 ),
                //                 height: 260,
                //                 child: Padding(
                //                   padding: const EdgeInsets.symmetric(
                //                       horizontal: 15, vertical: 10),
                //                   child: Column(
                //                     mainAxisAlignment:
                //                         MainAxisAlignment.spaceBetween,
                //                     crossAxisAlignment:
                //                         CrossAxisAlignment.start,
                //                     children: [
                //                       FlatButton(
                //                         onPressed: () {
                //                           widget.audiocontroller
                //                               .setPlaySpeed(0.25);
                //                           Navigator.pop(context);
                //                         },
                //                         child: Row(
                //                           children: [
                //                             Text(
                //                               "0.25X",
                //                              textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
                //                               style: TextStyle(
                //                                   color: Colors.white
                //                                       .withOpacity(0.7)),
                //                             )
                //                           ],
                //                         ),
                //                       ),
                //                       FlatButton(
                //                         onPressed: () {
                //                           widget.audiocontroller
                //                               .setPlaySpeed(0.5);
                //                           Navigator.pop(context);
                //                         },
                //                         child: Row(
                //                           children: [
                //                             Text(
                //                               "0.5X",
                //                              textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
                //                               style: TextStyle(
                //                                   color: Colors.white
                //                                       .withOpacity(0.7)),
                //                             )
                //                           ],
                //                         ),
                //                       ),
                //                       FlatButton(
                //                         onPressed: () {
                //                           widget.audiocontroller
                //                               .setPlaySpeed(1.0);
                //                           Navigator.pop(context);
                //                         },
                //                         child: Row(
                //                           children: [
                //                             Text(
                //                               "1X",
                //                              textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
                //                               style: TextStyle(
                //                                   color: Colors.white
                //                                       .withOpacity(0.7)),
                //                             )
                //                           ],
                //                         ),
                //                       ),
                //                       FlatButton(
                //                         onPressed: () {
                //                           widget.audiocontroller
                //                               .setPlaySpeed(1.5);
                //                           Navigator.pop(context);
                //                         },
                //                         child: Row(
                //                           children: [
                //                             Text(
                //                               "1.5X",
                //                              textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
                //                               style: TextStyle(
                //                                   color: Colors.white
                //                                       .withOpacity(0.7)),
                //                             )
                //                           ],
                //                         ),
                //                       ),
                //                       FlatButton(
                //                         onPressed: () {
                //                           widget.audiocontroller
                //                               .setPlaySpeed(2.0);
                //                           Navigator.pop(context);
                //                         },
                //                         child: Row(
                //                           children: [
                //                             Text(
                //                               "2X",
                //                              textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.2,1).toDouble(),
                //                               style: TextStyle(
                //                                   color: Colors.white
                //                                       .withOpacity(0.7)),
                //                             )
                //                           ],
                //                         ),
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ),
                //             );
                //           });
                //     },
                //   ),
                // ),
                IconButton(
                  icon: Icon(
                    Icons.replay_10,
                    //  color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    widget.audiocontroller.seek(Duration(seconds: -10));
                  },
                ),
                widget.audiocontroller.builderRealtimePlayingInfos(
                    builder: (context, infos) {
                  if (infos == null) {
                    return SizedBox(
                      height: 0,
                      width: 0,
                    );
                  } else {
                    if (infos.isBuffering == true) {
                      return SpinKitCircle(
                        size: 15,
                        color: Colors.white,
                      );
                    } else {
                      if (infos.isPlaying == true) {
                        return IconButton(
                          splashColor: Colors.blue,
                          icon: Icon(
                            Icons.pause,
                            //color: Colors.white,
                          ),
                          onPressed: () {
                            widget.audiocontroller.pause();
                          },
                        );
                      } else {
                        return IconButton(
                          splashColor: Colors.blue,
                          icon: Icon(
                            Icons.play_arrow,
                            // color: Colors.white,
                          ),
                          onPressed: () {
                            widget.audiocontroller.play();
                          },
                        );
                      }
                    }
                  }
                }),

//                 CircleAvatar(
//                   radius: 20,
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.blue,
//                   //   backgroundColor: Colors.white,
//                   child: episodeObject.audioPlayer.builderRealtimePlayingInfos(
//                       builder: (context, infos) {
//                     if (infos == null) {
//                       return SpinKitPulse(
//                         color: Colors.white,
//                       );
//                     } else {
//                       if (infos.isBuffering == true) {
//                         return SpinKitCircle(
//                           size: 16,
//                           color: Colors.black,
//                         );
//                       } else {
//                         if (infos.isPlaying == true) {
//                           return IconButton(
//                             icon: Icon(
//                               Icons.pause,
//                               // color:
//                               //     Colors.black,
//                             ),
//                             onPressed: () {
//                               widget.audiocontroller.pause();
//                               // setState(() {
//                               //   playerState = PlayerState.paused;
//                               // });
//                             },
//                           );
//                         } else {
//                           return IconButton(
//                             icon: Icon(
//                               Icons.play_arrow,
//                               // color:
//                               //     Colors.black,
//                             ),
//                             onPressed: () {
// //                                    play(url);
//                               widget.audiocontroller.play();
//                               // setState(() {
//                               //   playerState = PlayerState.playing;
//                               // });
//                             },
//                           );
//                         }
//                       }
//                     }
//                   }),
//                 ),
                IconButton(
                  icon: Icon(
                    Icons.forward_10,
                    //  color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    widget.audiocontroller.seek(
                      Duration(seconds: 10),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
