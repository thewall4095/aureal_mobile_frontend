import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
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

import '../CategoriesProvider.dart';
import '../DiscoverProvider.dart';
import '../PlayerState.dart';
import 'Player/Player.dart';
import 'Player/PlayerElements/Seekbar.dart';
import 'Profiles/CategoryView.dart';
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

  int currentIndex = 0;

  SwiperController _controller;

  AssetsAudioPlayer audioPlayer;

  List loadedIndex = [];

  List<PaletteGenerator> backgroundColorList = [];

  // void setColor() async {
  //   for(var v in recentlyPlayed )
  //   backgroundColorList.add(await PaletteGenerator.fromImageProvider(CachedNetworkImageProvider(url)))
  // }

  CustomLayoutOption customLayoutOption;

  void init(BuildContext context) async {
    DiscoverProvider discoverData =
        Provider.of<DiscoverProvider>(context, listen: false);
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
          print(recentlyPlayed);
          for (var v in recentlyPlayed) {
            getColor(v['image']).then((value) {
              setState(() {
                tileColor.add(value.dominantColor.color);
              });
            });
            v['isLoading'] = false;
          }
          print(tileColor);
        });
      }
    }
  }

  List<Color> tileColor = [];

  @override
  void initState() {
    customLayoutOption = new CustomLayoutOption(startIndex: 0, stateCount: 10);

    // TODO: implement initState
    init(context);
    audioPlayer = AssetsAudioPlayer();
    _controller = SwiperController();
    super.initState();
  }

  Future<PaletteGenerator> getColor(String url) async {
    return (await PaletteGenerator.fromImageProvider(NetworkImage(url),
        size: Size(20, 20)));
  }

  @override
  Widget build(BuildContext context) {
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

    var categories = Provider.of<CategoriesProvider>(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Color(0xff161616),
              automaticallyImplyLeading: false,
              expandedHeight: 20,
              pinned: true,
              //     backgroundColor: kPrimaryColor,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(5),
                child: Container(
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Row(
                            children: [
                              for (var v in categories.categoryList)
                                GestureDetector(
                                  onTap: () {
                                    // Navigator.push(
                                    //     context,
                                    //     CupertinoPageRoute(
                                    //         widget: CategoryView(
                                    //             categoryObject: v)));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: kSecondaryColor),
                                          // color: Color(0xff3a3a3a),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 3),
                                        child: Center(
                                          child: Text(
                                            v['name'],
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                //  color:
                                                // Color(0xffe8e8e8),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    2.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Swiper(
          index: currentIndex,
          onIndexChanged: (int index) async {
// audioPlayer.stop();
            audioPlayer.open(Audio.network(recentlyPlayed[index]['url']),
                autoStart: true);
            setState(() {
              currentIndex = index;
            });
          },
          // autoplay: true,
          autoplayDelay: 100,
          controller: _controller,
          customLayoutOption: customLayoutOption,
          viewportFraction: 0.8,
          scrollDirection: Axis.vertical,
          itemCount: recentlyPlayed.length,
          containerHeight: MediaQuery.of(context).size.height * 0.9,
          itemHeight: MediaQuery.of(context).size.height * 0.9,
          itemBuilder: (context, int index) {
            return SwipeCard(
                clipObject: recentlyPlayed[index],
                audioPlayer: audioPlayer,
                play: index == currentIndex ? true : false,
                index: index,
                currentIndex: currentIndex);
          },
        ),
      ),
    );
  }
}

class SwipeCard extends StatefulWidget {
  var clipObject;
  AssetsAudioPlayer audioPlayer;
  bool play;
  PaletteGenerator generator;
  int index;
  int currentIndex;

  SwipeCard(
      {@required this.clipObject,
      this.audioPlayer,
      this.play,
      this.generator,
      this.index,
      this.currentIndex});

  @override
  _SwipeCardState createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  var dominantColor = 0xff222222;
  SharedPreferences pref;

  Rect region;
  Rect dragRegion;
  Offset startDrag;
  Offset currentDrag;
  PaletteGenerator paletteGenerator;

  Future<PaletteColor> _updatePaletteGenerator(Rect newRegion) async {
    paletteGenerator = await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(widget.clipObject['image']),
      size: Size(256.0, 256.0),
      region: newRegion,
      maximumColorCount: 20,
    );
    return paletteGenerator.dominantColor;
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    print("did widget update is being called right now");
    print("currentIndex: ${widget.currentIndex}");
    print("index: ${widget.index}");

    if (widget.index == widget.currentIndex) {
      // widget.audioPlayer.stop();

      // widget.audioPlayer.open(Audio.network(widget.clipObject['url']));
    }
    // print(
    //     "${oldWidget.play} /////////////////////////////Teri maa ki oldWidget");
  }

  var color;

  @override
  void initState() {
    // TODO: implement initState

    print("init state is getting called eight now");
    // region = Offset.zero & Size(256.0, 256.0);
    // addColor();
    //
    // _updatePaletteGenerator(region);
    // setState(() {
    //   // dominantColor = getColor(widget.clipObject['image']);
    //   if (widget.play == true) {
    //     widget.audioPlayer.stop();
    //     widget.audioPlayer.open(Audio.network(widget.clipObject['url']));
    //   }
    // });

    addColor(widget.clipObject);
    super.initState();
  }

  PaletteColor backgroundColor;
  int index;

  void addColor(clipObject) async {
    final PaletteGenerator pg = await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.clipObject['image']),
        size: Size(20, 20));

    setState(() {
      backgroundColor = pg.dominantColor;
      bgColor = pg.dominantColor.color;
    });
  }

  Color bgColor = Color(0xff222222);

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();

    print("Dispose getting called right now");
    widget.audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: bgColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: CachedNetworkImage(
                    memCacheHeight:
                        (MediaQuery.of(context).size.hashCode / 2).floor(),
                    imageUrl: widget.clipObject['image'],
                    imageBuilder: (context, imageProvider) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: MediaQuery.of(context).size.width * 0.6,
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
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: backgroundColor.bodyTextColor),
                      ),
                      subtitle: Text(
                        "${widget.clipObject['podcast_name']}",
                        style: TextStyle(
                          color: backgroundColor.bodyTextColor,
                        ),
                      ),
                    ),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                widget.audioPlayer.builderRealtimePlayingInfos(
                                    builder: (context, infos) {
                                  if (infos.isPlaying == true) {
                                    return InkWell(
                                        onTap: () {
                                          widget.audioPlayer.pause();
                                        },
                                        child: Icon(Icons.pause_circle_filled,
                                            color:
                                                backgroundColor.bodyTextColor));
                                  }
                                  if (infos.isBuffering == true) {
                                    return SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          color: backgroundColor.bodyTextColor,
                                          strokeWidth: 1,
                                        ));
                                  } else {
                                    return InkWell(
                                        onTap: () {
                                          widget.audioPlayer.play();
                                        },
                                        child: Icon(Icons.play_circle_fill,
                                            color:
                                                backgroundColor.bodyTextColor));
                                  }
                                }),
                                // Text(
                                //     "${widget.audioPlayer.realtimePlayingInfos.value.currentPosition}")
                              ],
                            ),
                            Text(
                              "CONTINUE LISTENING",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  color: backgroundColor.bodyTextColor,
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 2.5,
                                  fontWeight: FontWeight.w600),
                            )
                          ],
                        ),
                        subtitle: widget.audioPlayer
                            .builderRealtimePlayingInfos(
                                builder: (context, infos) {
                          if (infos != null) {
                            return ClipSeekBar(
                                currentPosition: infos.currentPosition,
                                duration: infos.duration,
                                audioplayer: widget.audioPlayer);
                          } else {
                            return SizedBox();
                          }
                        })),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(LineIcons.heart,
                            color: backgroundColor.bodyTextColor),
                        Text(
                          "SUBSCRIBE",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: backgroundColor.bodyTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.safeBlockHorizontal * 3),
                        ),
                        Icon(Icons.ios_share,
                            color: backgroundColor.bodyTextColor)
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return SizedBox();
    }
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class ClipSeekBar extends StatefulWidget {
  Duration currentPosition;
  Duration duration;
  AssetsAudioPlayer audioplayer;

  ClipSeekBar(
      {@required this.currentPosition,
      @required this.duration,
      @required this.audioplayer});

  @override
  _ClipSeekBarState createState() => _ClipSeekBarState();
}

class _ClipSeekBarState extends State<ClipSeekBar> {
  String changingDuration = '0.0';

  void durationToString(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes =
        twoDigits(duration.inMinutes.remainder(Duration.minutesPerHour));
    String twoDigitSeconds =
        twoDigits(duration.inSeconds.remainder(Duration.secondsPerMinute));

    setState(() {
      changingDuration = "$twoDigitMinutes:$twoDigitSeconds";
    });
  }

  Duration _visibleValue;
  bool listenOnlyUserInteraction = false;
  double get percent => widget.duration.inMilliseconds == 0
      ? 0
      : _visibleValue.inMilliseconds / widget.duration.inMilliseconds;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _visibleValue = widget.currentPosition;
  }

  @override
  void didUpdateWidget(ClipSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listenOnlyUserInteraction) {
      _visibleValue = widget.currentPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackShape: CustomTrackShape(),
        trackHeight: 2,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0.0),
        // activeTrackColor: Color(0xff212121),
        //    inactiveTrackColor: Colors.black,
        thumbColor: Colors.transparent,
        //  thumbShape: SliderComponentShape
        // thumbShape: RoundSliderThumbShape(
        //     pressedElevation: 1.0,
        //     pressedElevation: 1.0,
        //     enabledThumbRadius: 8,
        //     disabledThumbRadius: 5),
      ),
      child: Slider(
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.5),
        min: 0,
        max: widget.duration.inMilliseconds.toDouble(),
        value: percent * widget.duration.inMilliseconds.toDouble(),
        onChangeEnd: (newValue) {
          setState(() {
            listenOnlyUserInteraction = false;
          });
        },
        onChangeStart: (_) {
          setState(() {
            listenOnlyUserInteraction = true;
          });
        },
        onChanged: (newValue) {
          setState(() {
            final to = Duration(milliseconds: newValue.floor());
            _visibleValue = to;
          });
        },
      ),
    );
  }
}
