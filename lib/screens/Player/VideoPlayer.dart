import 'dart:ui';

import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:better_player/better_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// class VideoPlayer extends StatefulWidget {
//   const VideoPlayer({
//     this.episodeObject,
//     this.title = 'Chewie Demo',
//   });
//   final episodeObject;
//   final String title;
//
//   @override
//   State<StatefulWidget> createState() {
//     return _VideoPlayerState();
//   }
// }
//
// class _VideoPlayerState extends State<VideoPlayer>
//     with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
//   TargetPlatform _platform;
//
//   // BetterPlayerController _betterPlayerController;
//   // BetterPlayerDataSource _betterPlayerDataSource;
//   GlobalKey _betterPlayerKey = GlobalKey();
//
//   @override
//   void initState() {
//     // BetterPlayerConfiguration betterPlayerConfiguration =
//     // BetterPlayerConfiguration(
//     //   aspectRatio: 16 / 9,
//     //   fit: BoxFit.contain,
//     //   autoPlay: true,
//     //   looping: true,
//     //   deviceOrientationsAfterFullScreen: [
//     //     DeviceOrientation.portraitDown,
//     //     DeviceOrientation.portraitUp
//     //   ],
//     //
//     // );
//     // _betterPlayerDataSource = BetterPlayerDataSource(
//     //   BetterPlayerDataSourceType.network,
//     //   widget.episodeObject['url'],
//     //   notificationConfiguration: BetterPlayerNotificationConfiguration(
//     //     showNotification: true,
//     //     title: "${widget.episodeObject['name']}",
//     //     author: "${widget.episodeObject['author']}",
//     //     imageUrl: widget.episodeObject['image'],
//     //   ),
//     // );
//     // _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
//     // _betterPlayerController.setupDataSource(_betterPlayerDataSource);
//     // _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);
//     _tabController = TabController(length: 2, vsync: this);
//     super.initState();
//     // initializePlayer();
//
//     // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
//     //   SystemUiOverlay.bottom,
//     // ]);
//   }
//
//   // @override
//   // void dispose() {
//   //
//   //   super.dispose();
//   // }
//
//   ScrollController _controller = ScrollController();
//
//   int currPlayIndex = 0;
//
//   TabController _tabController;
//
//   // Future<bool> willPopScope() async {
//   //   PIPView.of(context).presentBelow(Home());
//   //   Navigator.of(context).pop(true);
//   //   return true;
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     var episodeObject = Provider.of<PlayerChange>(context);
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: SafeArea(
//         child: ClipRect(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(
//               sigmaY: 15.0,
//               sigmaX: 15.0,
//             ),
//             child: Container(
//               child: ClipRect(
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(
//                     sigmaY: 15.0,
//                     sigmaX: 15.0,
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         color: Colors.black,
//                         height: MediaQuery.of(context).size.height / 3.8,
//                         width: double.infinity,
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             AspectRatio(
//                               aspectRatio: 16 / 9,
//                               child: BetterPlayer(
//                                 controller:
//                                     episodeObject.betterPlayerController,
//                                 key: _betterPlayerKey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       // IconButton(onPressed: (){
//                       //   PIPView.of(context).presentBelow(Home());
//                       // }, icon: Icon(Icons.height)),
//                       Container(
//                         // color: Colors.transparent,
//                         child: Expanded(
//                             child: Container(
//                           child: ListView(
//                             children: [
//                               ListTile(
//                                 title: Text(
//                                   "${widget.episodeObject['name']}",
//                                   textScaleFactor: 1.0,
//                                   style: TextStyle(
//                                       fontSize:
//                                           SizeConfig.safeBlockHorizontal * 3.5,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 trailing: IconButton(
//                                   onPressed: () {},
//                                   icon: Icon(Icons.arrow_drop_down),
//                                 ),
//                               ),
//                               ListTile(
//                                 title: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [],
//                                 ),
//                               ),
//                               ListTile(
//                                 leading: CachedNetworkImage(
//                                   imageBuilder: (context, imageProvider) {
//                                     return Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(3),
//                                         image: DecorationImage(
//                                             image: imageProvider,
//                                             fit: BoxFit.cover),
//                                       ),
//                                       width:
//                                           MediaQuery.of(context).size.width / 8,
//                                       height:
//                                           MediaQuery.of(context).size.width / 8,
//                                     );
//                                   },
//                                   imageUrl: widget.episodeObject['image'] ==
//                                           null
//                                       ? widget.episodeObject['podcast_image']
//                                       : widget.episodeObject['image'],
//                                   memCacheWidth:
//                                       MediaQuery.of(context).size.width.floor(),
//                                   memCacheHeight:
//                                       MediaQuery.of(context).size.width.floor(),
//                                   placeholder: (context, url) => Container(
//                                     width:
//                                         MediaQuery.of(context).size.width / 8,
//                                     height:
//                                         MediaQuery.of(context).size.width / 8,
//                                     child: Image.asset(
//                                         'assets/images/Thumbnail.png'),
//                                   ),
//                                   errorWidget: (context, url, error) =>
//                                       Icon(Icons.error),
//                                 ),
//                                 title: Text(
//                                     "${widget.episodeObject['podcast_name']}"),
//                                 subtitle:
//                                     Text("${widget.episodeObject['author']}"),
//                               ),
//                             ],
//                           ),
//                         )),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   // TODO: implement wantKeepAlive
//   bool get wantKeepAlive => true;
// }

class VideoPlayer extends StatelessWidget {
  const VideoPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverToBoxAdapter(
            child: Consumer<PlayerChange>(builder: (context, watch, _) {
              // final videoObject = watch.videoSource;
              // final miniPlayerController = watch.miniplayerController;
              return Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        child: BetterPlayer(
                          controller: watch.betterPlayerController,
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            watch.miniplayerController
                                .animateToHeight(state: PanelState.MIN);
                          },
                          icon: Icon(Icons.keyboard_arrow_down)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text("${watch.videoSource.title}"),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text("${watch.videoSource.album}"),
                      ),
                    ),
                  ),
                  watch.permlink != null
                      ? ListTile(title: Container())
                      : SizedBox(),
                ],
              );
            }),
          ),
          // VideoRecommendations()
        ],
      ),
    );
  }
}

class VideoRecommendations extends StatefulWidget {
  VideoRecommendations();

  @override
  State<VideoRecommendations> createState() => _VideoRecommendationsState();
}

class _VideoRecommendationsState extends State<VideoRecommendations> {
  SharedPreferences prefs;

  Dio dio = Dio();

  CancelToken _cancel = CancelToken();

  Future getVideoRecommendations(episodeId) async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedEpisodes?user_id=${prefs.getString('userId')}&size=20&page=0&episode_id=$episodeId";

    try {
      final response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['episodes'];
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final episodeobject = Provider.of<PlayerChange>(context);
    return FutureBuilder(
      future: getVideoRecommendations(episodeobject.episodeObject['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, int index) {
              return Container();
            }),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

Widget player() {
  return Consumer<PlayerChange>(builder: (context, watch, _) {
    return Container(
      child: BetterPlayer(
        controller: watch.betterPlayerController,
      ),
    );
  });
}

class PlaybackVideoButtons extends StatefulWidget {
  final episodeobject;

  PlaybackVideoButtons({@required this.episodeobject});

  @override
  State<PlaybackVideoButtons> createState() => _PlaybackVideoButtonsState();
}

class _PlaybackVideoButtonsState extends State<PlaybackVideoButtons> {
  Dio dio = Dio();

  Future getVotingValue() async {
    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://rpc.ecency.com";
    print(url);
    var map = Map<String, dynamic>();
    map = {
      "jsonrpc": "2.0",
      "method": "bridge.get_post",
      "params": {
        'author': episodeObject.episodeObject['author_hiveusername'],
        'permlink': episodeObject.episodeObject['permlink'],
        'observer': ""
      },
      "id": 0
    };
    print(map);

    try {
      await dio.post(url, data: map).then((value) async {
        // print(value.data);
        if (value.data['result'] != null) {
          // print("${
          //     {
          //       'hive_earnings': value.data['result']['payout'],
          //       'net_votes': value.data['result']['active_votes'].length,
          //       'ifVoted': getIfVoted(value.data['result']['active_votes']),}
          //
          // }");
          var responsedata = {
            'hive_earnings': value.data['result']['payout'],
            'net_votes': value.data['result']['active_votes'].length,
            'ifVoted': await getIfVoted(value.data['result']['active_votes']),
            'isLoading': false,
          };
          setState(() {
            data = responsedata;
          });

          // return responsedata;
        }
      });
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  Future getIfVoted(List activeVotes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('HiveUserName') != null) {
      if (activeVotes
          .toString()
          .contains("${prefs.getString("HiveUserName")}")) {
        return true;
      } else {
        return false;
      }
    }
  }

  SharedPreferences prefs;

  Future getLocalPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  var data = Map<String, dynamic>();

  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    getLocalPreferences().then((value) {
      var episodeObject = Provider.of<PlayerChange>(context, listen: false);
      if (episodeObject.episodeObject['permlink'] != null) {
        getVotingValue();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    return Row(
      children: [
        (episodeObject.episodeObject['permlink'] == null
            ? SizedBox(
                height: 0,
              )
            : (isLoading == true
                ? Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Container(
                      height: 25,
                      width: MediaQuery.of(context).size.width / 6,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Color(0xffe8e8e8).withOpacity(0.5),
                              width: 0.5),
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  )
                : GestureDetector(
                    onTap: () async {
                      Vibrate.feedback(FeedbackType.impact);
                      if (prefs.getString('HiveUserName') != null) {
                        setState(() {
                          data['isLoading'] = true;
                        });
                        double _value = 50.0;

                        showModalBottomSheet(
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) {
                              return ClipRect(
                                child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaY: 15.0,
                                      sigmaX: 15.0,
                                    ),
                                    child: Container(
                                      child: UpvoteEpisode(
                                          permlink: episodeObject
                                              .episodeObject['permlink'],
                                          episode_id: episodeObject
                                              .episodeObject['id']),
                                    )),
                              );
                            }).then((value) {
                          setState(() {
                            data['net_votes'] = data['net_votes'] + 1;
                            data['ifVoted'] = !data['ifVoted'];
                          });
                        });

                        setState(() {
                          data['isLoading'] = false;
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
                      decoration: data['ifVoted'] == true
                          ? BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Color(0xff5bc3ef),
                                Color(0xff5d5da8)
                              ]),
                              borderRadius: BorderRadius.circular(30))
                          : BoxDecoration(
                              border: Border.all(color: kSecondaryColor),
                              borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 5),
                        child: Row(
                          children: [
                            data['isLoading'] == true
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
                              child: Text(
                                "${data['net_votes'] != null ? data['net_votes'] : ""}",
                                textScaleFactor: 1.0,
                                style: TextStyle(fontSize: 12
                                    // color:
                                    //     Color(0xffe8e8e8)
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '\$${data['hive_earnings'] != null ? data['hive_earnings'] : ""}',
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
                  ))),
      ],
    );
  }
}
