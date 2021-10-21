import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:line_icons/line_icons.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DiscoverProvider.dart';
import '../PlayerState.dart';
import 'Player/Player.dart';
import 'Player/PlayerElements/Seekbar.dart';
import 'Profiles/EpisodeView.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

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

  int currentIndex = 1;

  SwiperController _controller;

  AssetsAudioPlayer audioPlayer;

  List loadedIndex = [];

  CustomLayoutOption customLayoutOption;

  @override
  void initState() {
    customLayoutOption = new CustomLayoutOption(startIndex: 1, stateCount: 2);

    // TODO: implement initState
    audioPlayer = AssetsAudioPlayer();
    _controller = SwiperController();
    super.initState();
  }

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
      body: Swiper(
        index: currentIndex,
        onIndexChanged: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        controller: _controller,
        customLayoutOption: customLayoutOption,
        viewportFraction: 0.82,
        scrollDirection: Axis.vertical,
        itemCount: recentlyPlayed.length,
        itemBuilder: (context, int index) {
          return SwipeCard(
            clipObject: recentlyPlayed[index],
            audioPlayer: audioPlayer,
            play: index == currentIndex ? true : false,
          );
        },
      ),
    );
  }
}

class SwipeCard extends StatefulWidget {
  var clipObject;
  AssetsAudioPlayer audioPlayer;
  bool play;

  SwipeCard({@required this.clipObject, this.audioPlayer, this.play});

  @override
  _SwipeCardState createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  var dominantColor = 0xff222222;
  SharedPreferences pref;

  int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
    r = (r < 0) ? -r : r;
    g = (g < 0) ? -g : g;
    b = (b < 0) ? -b : b;
    opacity = (opacity < 0) ? -opacity : opacity;
    opacity = (opacity > 1) ? 255 : opacity * 255;
    r = (r > 255) ? 255 : r;
    g = (g > 255) ? 255 : g;
    b = (b > 255) ? 255 : b;
    int a = opacity.toInt();
    return int.parse(
        '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}');
  }

  int getColor(String url) {
    getColorFromUrl(url).then((value) {
      return dominantColor = hexOfRGBA(value[0], value[1], value[2]);
    });
  }

  Future<Color> getImagePalette(ImageProvider imageProvider) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(imageProvider);
    return paletteGenerator.dominantColor.color;
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    print("${widget.play} /////////////////////////////Teri maa ki widget");
    if (widget.play == true) {
      widget.audioPlayer.stop();
      widget.audioPlayer.open(Audio.network(widget.clipObject['url']));
    }
    // print(
    //     "${oldWidget.play} /////////////////////////////Teri maa ki oldWidget");
  }

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      dominantColor = getColor(widget.clipObject['image']);
      if (widget.play == true) {
        widget.audioPlayer.stop();
        widget.audioPlayer.open(Audio.network(widget.clipObject['url']));
      }
    });

    print("${widget.play} /////////////////////////////Teri maa ki chhot");

    widget.play.pipe((t) =>
        print("${widget.play} /////////////////////////////Teri maa bhosada"));

    print(
        "Init State Called.//////////////////////////// for ${widget.clipObject['name']}");
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();

    widget.audioPlayer.stop();

    print("Dispose called ${widget.clipObject['name']}");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.play == true ? Colors.blue : Color(0xff222222)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: CachedNetworkImage(
                  imageUrl: widget.clipObject['image'],
                  imageBuilder: (context, imageProvider) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                              image: imageProvider, fit: BoxFit.cover)),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "${widget.clipObject['name']}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text("${widget.clipObject['podcast_name']}"),
                  ),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          widget.audioPlayer.builderRealtimePlayingInfos(
                              builder: (context, infos) {
                            if (infos.isPlaying == true) {
                              return InkWell(
                                  onTap: () {
                                    widget.audioPlayer.pause();
                                  },
                                  child: Icon(Icons.pause));
                            }
                            if (infos.isBuffering == true) {
                              return Icon(Icons.radio_button_off);
                            } else {
                              return Icon(Icons.play_circle_fill);
                            }
                          }),
                          Text(
                            "CONTINUE LISTENING",
                            textScaleFactor: 1.0,
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 2.5,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                            width: double.infinity,
                            height: 0.5,
                            color: Colors.blue,
                            child: Container(
                              height: 0.5,
                              width: MediaQuery.of(context).size.width / 2,
                              color: Colors.white,
                            )),
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(LineIcons.heart),
                      Text(
                        "SUBSCRIBE",
                        textScaleFactor: 1.0,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                      ),
                      Icon(Icons.ios_share)
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
