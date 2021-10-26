import 'dart:convert';

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
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
import 'package:http/http.dart' as http;

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) {
            return CreateClipSnippet();
          }));
        },
        isExtended: true,
        child: Icon(Icons.add),
      ),
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
        body: Stack(
          children: [
            Swiper(
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
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 12,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.8),
                        Colors.transparent
                      ])),
                )
              ],
            ),
          ],
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
                              audioplayer: widget.audioPlayer,
                              color: backgroundColor.bodyTextColor,
                            );
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color(0xff222222)),
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
                            color: Color(0xffe8e8e8)),
                      ),
                      subtitle: Text(
                        "${widget.clipObject['podcast_name']}",
                        style: TextStyle(
                          color: Color(0xffe8e8e8),
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
                                            color: Color(0xffe8e8e8)));
                                  }
                                  if (infos.isBuffering == true) {
                                    return SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          color: Color(0xffe8e8e8),
                                          strokeWidth: 1,
                                        ));
                                  } else {
                                    return InkWell(
                                        onTap: () {
                                          widget.audioPlayer.play();
                                        },
                                        child: Icon(Icons.play_circle_fill,
                                            color: Color(0xffe8e8e8)));
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
                                  color: Color(0xffe8e8e8),
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
                        Icon(LineIcons.heart, color: Color(0xffe8e8e8)),
                        Text(
                          "SUBSCRIBE",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: Color(0xffe8e8e8),
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.safeBlockHorizontal * 3),
                        ),
                        Icon(Icons.ios_share, color: Color(0xffe8e8e8))
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
  Color color;

  ClipSeekBar(
      {@required this.currentPosition,
      @required this.duration,
      @required this.audioplayer,
      this.color});

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
        activeColor: widget.color,
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

class CreateClipSnippet extends StatefulWidget {
  @override
  _CreateClipSnippetState createState() => _CreateClipSnippetState();
}

class _CreateClipSnippetState extends State<CreateClipSnippet>
    with TickerProviderStateMixin {
  TabController _tabControler;

  List searchResults = [];

  int pageNumber = 0;

  void getPodcastSearchResults(String query) async {
    String url = "https://api.aureal.one/public/search?word=$query";

    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print(response.body);
        if (pageNumber == 0) {
          setState(() {
            searchResults = jsonDecode(response.body)['PodcastList'];
            pageNumber = pageNumber + 1;
          });
        } else {
          setState(() {
            searchResults =
                searchResults + jsonDecode(response.body)['PodcastList'];
            pageNumber = pageNumber + 1;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _tabControler = TabController(length: 3, vsync: this);

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
                    colors: [Color(0xff5d5da8), Color(0xff5bc3ef)])
                .createShader(bounds);
          },
          child: Text(
            "ADD CLIP",
            textScaleFactor: 1.0,
            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
          ),
        ),
        actions: [
          TabBar(
            controller: _tabControler,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                text: "Search",
              ),
              Tab(text: "Explore"),
              Tab(
                text: "Your Shows",
              )
            ],
          )
        ],
      ),
      body: TabBarView(
        controller: _tabControler,
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xff222222),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          pageNumber = 0;
                        });
                      },
                      onSubmitted: (value) {
                        getPodcastSearchResults(value);
                      },
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(top: 14),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search)),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (var v in searchResults.toSet().toList())
                        ListTile(
                          onTap: () {
                            Navigator.push(context,
                                CupertinoPageRoute(builder: (context) {
                              return PodcastDetailsSnippets(
                                podcastObject: v,
                              );
                            }));
                          },
                          leading: SizedBox(
                            height: 60,
                            width: 60,
                            child: CachedNetworkImage(
                              imageUrl: v['image'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover),
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text("${v['name']}"),
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(),
          Container()
        ],
      ),
    );
  }
}

class PodcastDetailsSnippets extends StatefulWidget {
  var podcastObject;

  PodcastDetailsSnippets({@required this.podcastObject});

  @override
  _PodcastDetailsSnippetsState createState() => _PodcastDetailsSnippetsState();
}

class _PodcastDetailsSnippetsState extends State<PodcastDetailsSnippets> {
  int pageNumber = 0;
  List episodeList = [];
  bool episodeListLoading;

  ScrollController _controller;

  void getEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/episode?podcast_id=${widget.podcastObject['id']}&user_id=${prefs.getString('userId')}&page=$pageNumber';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          if (pageNumber == 0) {
            episodeList = jsonDecode(response.body)['episodes'];
            pageNumber = pageNumber + 1;
            episodeListLoading = false;
          } else {
            episodeList = episodeList + jsonDecode(response.body)['episodes'];
            episodeListLoading = false;
            pageNumber = pageNumber + 1;
          }
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _controller = ScrollController();
    getEpisodes();

    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        getEpisodes();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 60,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: ListTile(
                  leading: SizedBox(
                    height: 60,
                    width: 60,
                    child: CachedNetworkImage(
                      imageUrl: widget.podcastObject['image'],
                      imageBuilder: (context, imageProvider) {
                        return Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              image: DecorationImage(
                                  image: imageProvider, fit: BoxFit.cover)),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    "${widget.podcastObject['name']}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text("${widget.podcastObject['author']}",
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            )
          ];
        },
        body: ListView(
          controller: _controller,
          children: [
            ListTile(
              title: Text(
                "Episodes",
                textScaleFactor: 1.0,
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 6,
                    fontWeight: FontWeight.bold),
              ),
            ),
            for (var v in episodeList)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: ListTile(
                  onTap: () {
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (context) {
                      return SnippetEditor();
                    }));
                  },
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tileColor: Color(0xff222222),
                  title: Text(
                    "${v['name']}",
                    maxLines: 2,
                    textScaleFactor: 1.0,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("${v['summary']}",
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SnippetEditor extends StatefulWidget {
  @override
  _SnippetEditorState createState() => _SnippetEditorState();
}

class _SnippetEditorState extends State<SnippetEditor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
