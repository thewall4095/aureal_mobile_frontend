import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DiscoverProvider.dart';
import '../PlayerState.dart';
import 'Player/Player.dart';
import 'Player/PlayerElements/Seekbar.dart';
import 'Profiles/EpisodeView.dart';

import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';

import 'package:auditory/PlayerState.dart';

import 'package:auditory/screens/Profiles/EpisodeView.dart';

import 'package:flutter/rendering.dart';

import 'Profiles/PodcastView.dart';

enum PlayerState { stopped, playing, paused }
class Clips extends StatefulWidget {
  @override
  _ClipsState createState() => _ClipsState();
}

class _ClipsState extends State<Clips> {
  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  PlayerState playerState = PlayerState.playing;
  var recentlyPlayed = [];
  var homeData = [];
  var dominantColor = 0xff222222;
  SharedPreferences pref;

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    var episodeObject = Provider.of<PlayerChange>(context);
    DiscoverProvider discoverData = Provider.of<DiscoverProvider>(context);
    if (discoverData.isFetcheddiscoverList == false) {
      discoverData.getDiscoverProvider();
    }

    setState(() {
      homeData = discoverData.discoverList;
    });
    for (var v in homeData) {
      if (v['Key'] == 'general_episode') {
        setState(() {
          recentlyPlayed = v['data'];
          for (var v in recentlyPlayed) {
            v['isLoading'] = false;
          }
        });
      }
    }
    return Scaffold(
      body:  ListView(
        children: [
          for (var a in recentlyPlayed)
            Padding(
              padding:
              const EdgeInsets
                  .all(40),
              child: Container(
                width: MediaQuery.of(context).size.width/0.5,
                height: MediaQuery.of(context).size.height/1.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0xff222222),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .center,
                    children: [
                      CachedNetworkImage(
                        imageBuilder:
                            (context,
                            imageProvider) {
                          return Container(
                            height: MediaQuery.of(context).size.width /
                                1.5,
                            width: MediaQuery.of(context).size.width /
                                1.5,
                            decoration:
                            BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(8),
                              image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover),
                            ),
                          );
                        },
                        memCacheHeight: (MediaQuery.of(context)
                            .size
                            .height)
                            .floor(),
                        imageUrl: a['image'] !=
                            null
                            ? a['image']
                            : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                        placeholder:
                            (context,
                            imageProvider) {
                          return Container(
                            decoration:
                            BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/Thumbnail.png'), fit: BoxFit.cover)),
                            height: MediaQuery.of(context).size.width *
                                0.38,
                            width: MediaQuery.of(context).size.width *
                                0.38,
                          );
                        },
                      ),
                      SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets
                            .symmetric(
                            horizontal:
                            15),
                        child: SizedBox(
                          width: MediaQuery.of(
                              context)
                              .size
                              .width /
                              2,
                          height: MediaQuery.of(
                              context)
                              .size
                              .width /
                              6,
                          child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(bottom: 5),
                                      child:
                                      GestureDetector(
                                        onTap:
                                            () {
                                          // Navigator.push(context, CupertinoPageRoute(widget: EpisodeView(episodeId: a['id'])));
                                          Navigator.push(context, CupertinoPageRoute(builder: (context) {
                                            return EpisodeView(
                                              episodeId: a['id'],
                                            );
                                          }));
                                        },
                                        child:
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, CupertinoPageRoute(builder: (context) {
                                              return PodcastView(a['podcast_id']);
                                            }));
                                          },
                                          child: Padding(
                                            padding:   const EdgeInsets.only(top: 8),
                                            child: Text(
                                              a['name'].toString(),
                                              overflow: TextOverflow.clip,
                                              maxLines: 2,
                                              textScaleFactor: 1.0,
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      a['podcast_name']
                                          .toString(),
                                      textScaleFactor:
                                      1.0,
                                      maxLines:
                                      1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Color(0xff777777),
                                          fontSize: SizeConfig.safeBlockHorizontal * 2.8),
                                    ),

                                  ],
                                ),
                              ]
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
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
                                            return FloatingActionButton(
                                                child: Icon(Icons.pause),backgroundColor: Colors.red,
                                                onPressed: () {
                                                  episodeObject.pause();
                                                  setState(() {
                                                    playerState =
                                                        PlayerState.paused;
                                                  });
                                                });
                                          } else {
                                            return FloatingActionButton(
                                                child: Icon(
                                                    Icons.play_arrow_rounded,size: 20,),
                                                onPressed: () {
                                                  // play(url);
                                                  episodeObject.resume();
                                                  setState(() {
                                                    playerState =
                                                        PlayerState.playing;
                                                  });
                                                });
                                          }
                                        }
                                      }
                                    }),
Text("Episode")
                              ],
                            ),
                          ),

                        ],
                      ),
                      Divider(color: Colors.white,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          IconButton(onPressed: (){}, icon: Icon(Icons.lens_outlined)),
                          Text("Subscribe"),
                          IconButton(onPressed: (){}, icon: Icon(Icons.share))
                        ],
                      )

                    ],
                  ),
                ),
              ),
            )
        ],
      ),

    );
  }
}
