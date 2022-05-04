import 'dart:math';
import 'dart:ui';

import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/data/Datasource.dart';
import 'package:auditory/screens/FollowingPage.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:linkable/linkable.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class VideoPlayer extends StatefulWidget {
  VideoPlayer();

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    // _initControllers();
    super.initState();
  }

  // VideoPlayerController _controller;
  // ChewieController _chewie;

  // void _initControllers() {
  //   var episodeObject = Provider.of<PlayerChange>(context, listen: false);
  //   this._controller =
  //       VideoPlayerController.network(episodeObject.videoSource.url);
  //   this._chewie = ChewieController(
  //     aspectRatio: 16 / 9,
  //     videoPlayerController: this._controller,
  //     autoPlay: true,
  //   );
  // }

  // @override
  // void dispose() {
  //   this._controller?.dispose();
  //   this._chewie?.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    return Scaffold(
      body: Stack(
        children: [
          Chewie(controller: episodeObject.chewie),
          Consumer<PlayerChange>(builder: (context, watch, _) {
            // final videoObject = watch.videoSource;
            // final miniPlayerController = watch.miniplayerController;
            return Column(
              children: [
                Stack(
                  children: [
                    // Container(
                    //   child: BetterPlayer(
                    //     controller: watch.betterPlayerController,
                    //   ),
                    // ),
                    IconButton(
                        onPressed: () {
                          watch.miniplayerController
                              .animateToHeight(state: PanelState.MIN);
                        },
                        icon: Icon(Icons.keyboard_arrow_down)),
                  ],
                ),
                // watch.permlink != null
                //     ? ListTile(title: Container())
                //     : SizedBox(),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class VideoPlayerBottom extends StatefulWidget {
  VideoPlayerBottom();

  @override
  State<VideoPlayerBottom> createState() => _VideoPlayerBottomState();
}

class _VideoPlayerBottomState extends State<VideoPlayerBottom>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  void init() {
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void initState() {
    init();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: "EPISODES",
              ),
              // Tab(
              //   text: "SNIPPETS & MORE",
              // ),
              Tab(
                text: "MORE LIKE THESE",
              )
            ],
          ),
          Expanded(
            child: TabBarView(children: [
              Consumer<PlayerChange>(
                builder: (context, watch, _) {
                  return MoreEpisodes(episodeObject: watch.episodeObject);
                },
              ),
              Consumer<PlayerChange>(builder: (context, watch, _) {
                print(watch.id);
                return VideoRecommendation(episodeObject: watch.episodeObject);
              })
            ], controller: _tabController),
          ),
        ],
      ),
    );
  }
}

class UpvoteAndComment extends StatefulWidget {
  final Video videoObject;

  UpvoteAndComment({@required this.videoObject});

  @override
  State<UpvoteAndComment> createState() => _UpvoteAndCommentState();
}

class _UpvoteAndCommentState extends State<UpvoteAndComment> {
  Future myFuture;
  SharedPreferences prefs;

  var data = Map<String, dynamic>();

  Future getVotingValue(var episodeContent) async {
    // setState(() {
    //   isLoading = true;
    // });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://rpc.ecency.com";

    var map = Map<String, dynamic>();
    map = {
      "jsonrpc": "2.0",
      "method": "bridge.get_post",
      "params": {
        'author': episodeContent['author_hiveusername'],
        'permlink': episodeContent['permlink'],
        'observer': ""
      },
      "id": 0
    };

    try {
      await dio.post(url, data: map).then((value) async {
        if (value.data['result'] != null) {
          var responsedata = {
            'hive_earnings': value.data['result']['payout'],
            'net_votes': value.data['result']['active_votes'].length,
            'ifVoted': await getIfVoted(value.data['result']['active_votes']),
            'isLoading': false,
          };
          setState(() {
            data = responsedata;
          });
        }
      });
    } catch (e) {
      print(e);
    }
    // setState(() {
    //   isLoading = false;
    // });
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

  Dio dio = Dio();

  CancelToken cancel = CancelToken();

  Future getEpisode() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/episode?episode_id=${widget.videoObject.id}&user_id=${prefs.getString('userId')}';

    try {
      var response = await dio.get(url, cancelToken: cancel);
      if (response.statusCode == 200) {
        getVotingValue(response.data['episode']);
        return response.data['episode'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  RegExp htmlMatch = RegExp(r'(\w+)');

  void init() async {
    myFuture = getEpisode();
  }

  @override
  void initState() {
    // TODO: implement initState
    init();
    super.initState();
  }

  bool isUpvoteButtonLoading = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: myFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                snapshot.data['permlink'] == null
                    ? SizedBox()
                    : Padding(
                        padding: const EdgeInsets.all(15),
                        child: InkWell(
                          onTap: () async {
                            if (prefs.getString('HiveUserName') != null) {
                              setState(() {
                                isUpvoteButtonLoading = true;
                              });
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: UpvoteEpisode(
                                            permlink: snapshot.data['permlink'],
                                            episode_id: snapshot.data['id']));
                                  }).then((value) async {
                                print(value);
                              });
                              await upvoteEpisode(
                                  permlink: snapshot.data['permlink'],
                                  episode_id: snapshot.data['id']);
                              setState(() {
                                snapshot.data['ifVoted'] =
                                    !snapshot.data['ifVoted'];
                                isUpvoteButtonLoading = false;
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
                            padding: const EdgeInsets.only(right: 5),
                            child: Container(
                              width: double.infinity,
                              decoration: snapshot.data['ifVoted'] == true
                                  ? BoxDecoration(
                                      gradient: kGradient,
                                    )
                                  : BoxDecoration(
                                      border:
                                          Border.all(color: kSecondaryColor),
                                    ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    isUpvoteButtonLoading == true
                                        ? Container(
                                            height: 18,
                                            width: 18,
                                            child: SpinKitPulse(
                                              color: Colors.blue,
                                            ),
                                          )
                                        : Icon(
                                            FontAwesomeIcons.chevronCircleUp,
                                            size: 15,
                                          ),
                                    data['ifVoted'] == false
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Text("UPVOTE"),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                child: Text(
                                                  '${data['net_votes'] == null ? " " : data['net_votes']}',
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      //        color: Color(
                                                      // 0xffe8e8e8)
                                                      ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4),
                                                child: Text(
                                                  '\$${data['hive_earnings'] == null ? "" : data['hive_earnings']}',
                                                  textScaleFactor: 1.0,
                                                ),
                                              )
                                            ],
                                          )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ListTile(
                  subtitle: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: htmlMatch.hasMatch(snapshot.data['summary']) == true
                        ? Linkable(
                            text:
                                '${(parse(snapshot.data['summary']).body.text)}',
                            maxLines: 3,
                            textScaleFactor: 1.0,
                            textColor: Color(0xffe8e8e8),
                            style: TextStyle(
                              fontSize: SizeConfig.blockSizeHorizontal * 3,
                            ),
                          )
                        : Linkable(
                            text: "${snapshot.data['summary']}",
                            maxLines: 3,
                            textScaleFactor: 1.0,
                            textColor: Color(0xffe8e8e8),
                            style: TextStyle(
                              fontSize: SizeConfig.blockSizeHorizontal * 3,
                            ),
                          ),
                  ),
                ),
              ],
            );
          } else {
            return Container();
          }
        });
  }

  @override
  void didUpdateWidget(covariant UpvoteAndComment oldWidget) {
    // TODO: implement didUpdateWidget
    if (oldWidget.videoObject != widget.videoObject) {
      init();
    }
    super.didUpdateWidget(oldWidget);
  }
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
        ),
      ],
    );
  }
}

class _SliverPinnedBoxAdapter extends SingleChildRenderObjectWidget {
  const _SliverPinnedBoxAdapter({
    Key key,
    Widget child,
    this.pinned = true,
  }) : super(key: key, child: child);

  final bool pinned;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverPinnedBoxAdapter(pinned: pinned);
}

class _RenderSliverPinnedBoxAdapter extends RenderSliverSingleBoxAdapter {
  _RenderSliverPinnedBoxAdapter({RenderBox child, @required this.pinned})
      : super(child: child);

  /// If true, ✅ should stay pinned at the top of the list,
  /// ✅ but move back into it's original position when scrolling down
  ///
  /// If false, ✅ should move out of the list, ❌ but move back into it's original position
  /// when scrolling down
  ///
  /// ❌ You should be able to place a `pinned = false` sliver above a `pinned = true` sliver
  /// and have them never overlap
  ///
  /// ❌ Should not react to overscrolling on iOS
  final bool pinned;
  // double lastUpwardScrollOffset = 0;

  double previousScrollOffset = 0;
  double ratchetingScrollDistance = 0;

  @override
  void performLayout() {
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtent = child.size.height;
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    final dy = previousScrollOffset - constraints.scrollOffset;
    previousScrollOffset = constraints.scrollOffset;

    ratchetingScrollDistance =
        (ratchetingScrollDistance + dy).clamp(0.0, childExtent);

    if (pinned) {
      print(ratchetingScrollDistance);
    }

    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
      paintOrigin: pinned
          ? constraints.scrollOffset
          : max(
              0,
              constraints.scrollOffset - childExtent + ratchetingScrollDistance,
            ),
      visible: true,
    );

    setChildParentData(child, constraints, geometry);
  }
}

class VideoRecommendation extends StatefulWidget {
  final episodeObject;
  VideoRecommendation({@required this.episodeObject});

  @override
  State<VideoRecommendation> createState() => _VideoRecommendationState();
}

class _VideoRecommendationState extends State<VideoRecommendation>
    with AutomaticKeepAliveClientMixin {
  SharedPreferences prefs;

  Dio dio = Dio();

  CancelToken cancel = CancelToken();

  Future getVideoRecommendations() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedEpisodes?user_id=${prefs.getString('userId')}&size=20&page=0&episode_id=${widget.episodeObject['id']}&type=episode_based";
    print(url);

    try {
      var response = await dio.get(url, cancelToken: cancel);
      if (response.statusCode == 200) {
        return response.data['episodes'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future myFuture;

  void init() async {
    myFuture = getVideoRecommendations();
  }

  @override
  void initState() {
    // TODO: implement initState
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: myFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context, int index) {
                  return VideoCard(
                      video: Video(
                          id: snapshot.data[index]['id'],
                          title: snapshot.data[index]['name'],
                          thumbnailUrl: snapshot.data[index]['podcast_image'],
                          episodeImage: snapshot.data[index]['image'],
                          author: snapshot.data[index]['author'],
                          url: snapshot.data[index]['url'],
                          album: snapshot.data[index]['podcast_name'],
                          podcastid: snapshot.data[index]['podcast_id'],
                          author_id: snapshot.data[index]['author_user_id'],
                          createdAt: snapshot.data[index]['published_at']));
                },
                itemCount: snapshot.data.length);
          } else {
            return ModalProgressHUD(
              inAsyncCall: true,
              color: Colors.black,
              progressIndicator: CircularProgressIndicator(
                color: Colors.white,
              ),
              child: Container(),
            );
          }
        });
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class MoreEpisodes extends StatefulWidget {
  final episodeObject;
  MoreEpisodes({@required this.episodeObject});

  @override
  State<MoreEpisodes> createState() => _MoreEpisodesState();
}

class _MoreEpisodesState extends State<MoreEpisodes>
    with AutomaticKeepAliveClientMixin {
  SharedPreferences prefs;

  Dio dio = Dio();
  CancelToken cancel = CancelToken();

  Future getEpisodes() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/episode?podcast_id=${widget.episodeObject['podcast_id']}&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: cancel);
      if (response.statusCode == 200) {
        return response.data['episodes'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future myFuture;

  void init() async {
    myFuture = getEpisodes();
  }

  @override
  void initState() {
    // TODO: implement initState
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getEpisodes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemBuilder: (context, int index) {
                if (index == snapshot.data.length) {
                  return ListTile(
                    onTap: () {
                      Navigator.push(context,
                          CupertinoPageRoute(builder: (context) {
                        return PodcastView(
                            snapshot.data[index - 1]['podcast_id']);
                      }));
                    },
                    title: Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.white.withOpacity(0.5))),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Center(child: Text("More")),
                      ),
                    ),
                  );
                } else {
                  return EpisodeCard(data: snapshot.data[index]);
                }
              },
              itemCount: snapshot.data.length + 1,
            );
          } else {
            return Container(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class MyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final UniqueKey newKey;

  MyVideoPlayer(this.videoUrl, this.newKey) : super(key: newKey);

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  VideoPlayerController _controller;
  ChewieController _chewie;

  @override
  void initState() {
    this._initControllers(this.widget.videoUrl);
    super.initState();
  }

  void _initControllers(String url) {
    this._controller = VideoPlayerController.network(url);
    this._chewie = ChewieController(
      aspectRatio: 16 / 9,
      videoPlayerController: this._controller,
      autoPlay: true,
    );
  }

  @override
  void dispose() {
    this._controller?.dispose();
    this._chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Chewie(controller: this._chewie);
  }
}
