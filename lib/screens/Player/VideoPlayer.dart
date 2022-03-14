import 'dart:ui';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
// import 'package:chewie_example/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

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

class _VideoPlayerState extends State<VideoPlayer> with TickerProviderStateMixin{
  TargetPlatform _platform;
  VideoPlayerController _videoPlayerController1;
  VideoPlayerController _videoPlayerController2;
  ChewieController _chewieController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    initializePlayer();

    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
    //   SystemUiOverlay.bottom,
    // ]);
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _videoPlayerController2.dispose();
    _chewieController?.dispose();
    super.dispose();
  }



  ScrollController _controller = ScrollController();

  Future<void> initializePlayer() async {
    _videoPlayerController1 =
        VideoPlayerController.network(widget.episodeObject['url']);
    // _videoPlayerController2 =
    //     VideoPlayerController.network(srcs[currPlayIndex]);
    await Future.wait([
      _videoPlayerController1.initialize(),
      // _videoPlayerController2.initialize()
    ]);
    _createChewieController();
    setState(() {});
  }

  void _createChewieController() {
    // final subtitles = [
    //     Subtitle(
    //       index: 0,
    //       start: Duration.zero,
    //       end: const Duration(seconds: 10),
    //       text: 'Hello from subtitles',
    //     ),
    //     Subtitle(
    //       index: 0,
    //       start: const Duration(seconds: 10),
    //       end: const Duration(seconds: 20),
    //       text: 'Whats up? :)',
    //     ),
    //   ];

    final subtitles = [
      Subtitle(
        index: 0,
        start: Duration.zero,
        end: const Duration(seconds: 10),
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Hello',
              style: TextStyle(color: Colors.red, fontSize: 22),
            ),
            TextSpan(
              text: ' from ',
              style: TextStyle(color: Colors.green, fontSize: 20),
            ),
            TextSpan(
              text: 'subtitles',
              style: TextStyle(color: Colors.blue, fontSize: 18),
            )
          ],
        ),
      ),
      Subtitle(
        index: 0,
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 20),
        text: 'Whats up? :)',
        // text: const TextSpan(
        //   text: 'Whats up? :)',
        //   style: TextStyle(color: Colors.amber, fontSize: 22, fontStyle: FontStyle.italic),
        // ),
      ),
    ];

    _chewieController = ChewieController(
      placeholder: Container(
        height: MediaQuery.of(context).size.height / 3,
      ),
      // aspectRatio: 16/9,
      videoPlayerController: _videoPlayerController1,

      autoPlay: true,
      looping: true,

      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: toggleVideo,
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
      // subtitle: Subtitles(subtitles),


      // Try playing around with some of these other options:

      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      // autoInitialize: true,
    );
  }

  int currPlayIndex = 0;

  TabController _tabController;
  Future<void> toggleVideo() async {
    await _videoPlayerController1.pause();
    currPlayIndex = currPlayIndex == 0 ? 1 : 0;
    await initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(

      color: Colors.transparent,
      child: SafeArea(
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

                            Flexible(
                              child: _chewieController != null &&
                                  _chewieController
                                      .videoPlayerController.value.isInitialized
                                  ? Chewie(

                                controller: _chewieController,
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 20),
                                  Text('Loading'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

