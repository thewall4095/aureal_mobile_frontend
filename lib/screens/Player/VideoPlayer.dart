import 'dart:ui';

import 'package:auditory/PlayerState.dart';
import 'package:auditory/screens/FollowingPage.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:better_player/better_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import 'package:video_player/video_player.dart';
import 'package:pip_view/pip_view.dart';

class VideoPlayer extends StatefulWidget {


  const VideoPlayer({
    this.episodeObject,
    this.title = 'Chewie Demo',
  }) ;
  final episodeObject;
  final String title;

  @override
  State<StatefulWidget> createState() {
    return _VideoPlayerState();
  }
}

class _VideoPlayerState extends State<VideoPlayer> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin{
  TargetPlatform _platform;


  // BetterPlayerController _betterPlayerController;
  // BetterPlayerDataSource _betterPlayerDataSource;
  GlobalKey _betterPlayerKey = GlobalKey();

  @override
  void initState() {
    // BetterPlayerConfiguration betterPlayerConfiguration =
    // BetterPlayerConfiguration(
    //   aspectRatio: 16 / 9,
    //   fit: BoxFit.contain,
    //   autoPlay: true,
    //   looping: true,
    //   deviceOrientationsAfterFullScreen: [
    //     DeviceOrientation.portraitDown,
    //     DeviceOrientation.portraitUp
    //   ],
    //
    // );
    // _betterPlayerDataSource = BetterPlayerDataSource(
    //   BetterPlayerDataSourceType.network,
    //   widget.episodeObject['url'],
    //   notificationConfiguration: BetterPlayerNotificationConfiguration(
    //     showNotification: true,
    //     title: "${widget.episodeObject['name']}",
    //     author: "${widget.episodeObject['author']}",
    //     imageUrl: widget.episodeObject['image'],
    //   ),
    // );
    // _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    // _betterPlayerController.setupDataSource(_betterPlayerDataSource);
    // _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    // initializePlayer();

    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
    //   SystemUiOverlay.bottom,
    // ]);
  }

  // @override
  // void dispose() {
  //
  //   super.dispose();
  // }



  ScrollController _controller = ScrollController();



  int currPlayIndex = 0;

  TabController _tabController;

  // Future<bool> willPopScope() async {
  //   PIPView.of(context).presentBelow(Home());
  //   Navigator.of(context).pop(true);
  //   return true;
  // }


  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaY: 15.0,
              sigmaX: 15.0,
            ),
            child: Container(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaY: 15.0,
                    sigmaX: 15.0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        color: Colors.black,
                        height: MediaQuery.of(context).size.height / 3.8,
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: BetterPlayer(controller: episodeObject.betterPlayerController, key: _betterPlayerKey,),
                            ),
                          ],
                        ),
                      ),
                      // IconButton(onPressed: (){
                      //   PIPView.of(context).presentBelow(Home());
                      // }, icon: Icon(Icons.height)),
                      Container(
                        // color: Colors.transparent,
                        child: Expanded(child: Container(
                          child: ListView(
                            children: [
                              ListTile(
                                title: Text("${widget.episodeObject['name']}",textScaleFactor: 1.0, style: TextStyle(
                                    fontSize: SizeConfig.safeBlockHorizontal * 3.5, fontWeight: FontWeight.bold
                                ),),
                                trailing: IconButton(
                                  onPressed: (){

                                  },
                                  icon: Icon(Icons.arrow_drop_down),
                                ),
                              ),
                              ListTile(
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [

                                  ],
                                ),
                              ),
                              ListTile(
                                leading: CachedNetworkImage(
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
                                  widget.episodeObject['image'] == null ? widget.episodeObject['podcast_image'] : widget.episodeObject['image'],
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
                                title: Text("${widget.episodeObject['podcast_name']}"),
                                subtitle: Text("${widget.episodeObject['author']}"),
                              ),


                            ],
                          ),
                        )),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

