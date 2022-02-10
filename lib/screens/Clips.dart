import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/FollowingPage.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icons.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CategoriesProvider.dart';
import '../DiscoverProvider.dart';
import 'Profiles/EpisodeView.dart';

enum PlayerState { stopped, playing, paused }

Future<PaletteGenerator> computeFunction(var clipObject) async {
  print(clipObject['image']);
  final PaletteGenerator pg = await PaletteGenerator.fromImageProvider(
    CachedNetworkImageProvider(clipObject['image']),
  );

  return pg;
}

class Clips extends StatefulWidget {
  @override
  _ClipsState createState() => _ClipsState();
}

class _ClipsState extends State<Clips> {
  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  var snippetPlayer;

  void getSnippetPlayer(BuildContext context){
    snippetPlayer = Provider.of<PlayerChange>(context, listen: false);
  }

  PlayerState playerState = PlayerState.playing;
  var recentlyPlayed = [];
  var homeData = [];

  int currentIndex = 0;

  SwiperController _controller;

  AssetsAudioPlayer audioPlayer;

  List loadedIndex = [];

  List<PaletteGenerator> backgroundColorList = [];

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
    // for (var v in homeData) {
    //   if (v['Key'] == 'general_episode') {
    //     setState(() {
    //       recentlyPlayed = v['data'];
    //       print(recentlyPlayed);
    //       for (var v in recentlyPlayed) {
    //         getColor(v['image']).then((value) {
    //           setState(() {
    //             tileColor.add(value.dominantColor.color);
    //           });
    //         });
    //         v['isLoading'] = false;
    //       }
    //       print(tileColor);
    //     });
    //   }
    // }
  }

  int page = 0;

  void getMySnippets(int categoryId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getSnippet?category_id=$categoryId&user_id=${prefs.getString('userId')}&page=$page";

    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (page == 0) {
          setState(() {
            snippets = jsonDecode(response.body)['snippets'];
          });
        } else {
          setState(() {
            snippets = snippets + jsonDecode(response.body)['snippets'];
          });
        }
      } else {
        print(response.statusCode);
      }

      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  ScrollController pageViewScrollController =
      ScrollController(keepScrollOffset: false);
  List<Color> tileColor = [];

  PageController _pageController =
      PageController(viewportFraction: 1.0, keepPage: true);

  @override
  void initState() {


    // TODO: implement initState

    getAllSnippetsWOCategory();
    // init(context);
    getSnippetPlayer(context);

    super.initState();

    // _pageController.addListener(() {
    //   if (currentIndex == snippets.length - 1) {
    //     if (selectedCategory == 30) {
    //       getAllSnippetsWOCategory();
    //     } else {
    //       getAllSnippets(selectedCategory);
    //     }
    //   }
    // });
  }

  @override
  void dispose() {
print("dispose is getting called on Clips");
    super.dispose();
    // var snippetPlayer = Provider.of<PlayerChange>(context, listen: false);
    snippetPlayer.snippetPlayer.stop();

  }

  Future<PaletteGenerator> getColor(String url) async {
    return (await PaletteGenerator.fromImageProvider(NetworkImage(url),
        size: Size(20, 20)));
  }

  var snippets = [];

  bool isLoading = false;

  Future getAllSnippetsWOCategory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/discoverSnippets?loggedinuser=${prefs.getString('userId')}&page=$page&pageSize=5";
    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        if (page == 0) {
          setState(() {
            snippets = jsonDecode(response.body)['snippets'];
            page = page + 1;
          });
          return snippets;
        } else {
          setState(() {
            snippets = snippets + jsonDecode(response.body)['snippets'];
            page = page + 1;
          });
          return snippets;
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future getAllSnippets(var categoryId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/discoverSnippets?loggedinuser=${prefs.getString('userId')}&page=$page&category_id=$categoryId&pageSize=5";
    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (page == 0) {
          isLoading = true;

          setState(() {
            snippets = jsonDecode(response.body)['snippets'];
            page = page + 1;
          });

          isLoading = false;
          return snippets;
        } else {
          setState(() {
            snippets = snippets + jsonDecode(response.body)['snippets'];
            page = page + 1;
          });
          return snippets;
        }
        print(response.body);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  int selectedCategory = 30;

  @override
  Widget build(BuildContext context) {
    var categories = Provider.of<CategoriesProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(context, CupertinoPageRoute(builder: (context) {
      //       return CreateClipSnippet();
      //     }));
      //   },
      //   isExtended: true,
      //   child: Icon(Icons.add),
      // ),
      body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
            return <Widget>[
              // SliverAppBar(
              //   backgroundColor: Color(0xff161616),
              //   automaticallyImplyLeading: false,
              //   expandedHeight: 20,
              //   pinned: true,
              //   //     backgroundColor: kPrimaryColor,
              //   // bottom: PreferredSize(
              //   //   preferredSize: Size.fromHeight(5),
              //   //   child: Container(
              //   //     height: 60,
              //   //     child: Padding(
              //   //       padding: const EdgeInsets.symmetric(vertical: 10),
              //   //       child: Container(
              //   //         height: 30,
              //   //         child: ListView(
              //   //           scrollDirection: Axis.horizontal,
              //   //           children: [
              //   //             Row(
              //   //               children: [
              //   //                 GestureDetector(
              //   //                   onTap: () {
              //   //                     setState(() {
              //   //                       page = 0;
              //   //                       selectedCategory = 30;
              //   //                     });
              //   //                     audioPlayer.stop();
              //   //                     getAllSnippetsWOCategory();
              //   //                   },
              //   //                   child: Padding(
              //   //                     padding: const EdgeInsets.all(2.0),
              //   //                     child: Container(
              //   //                       decoration: BoxDecoration(
              //   //                           border: Border.all(
              //   //                               color: kSecondaryColor),
              //   //                           color: selectedCategory == 30
              //   //                               ? Color(0xff3a3a3a)
              //   //                               : Colors.transparent,
              //   //                           borderRadius:
              //   //                               BorderRadius.circular(20)),
              //   //                       child: Padding(
              //   //                         padding: const EdgeInsets.symmetric(
              //   //                             horizontal: 15, vertical: 3),
              //   //                         child: Center(
              //   //                           child: Text(
              //   //                             "All",
              //   //                             textScaleFactor: 1.0,
              //   //                             style: TextStyle(
              //   //                                 //  color:
              //   //                                 // Color(0xffe8e8e8),
              //   //                                 fontSize: SizeConfig
              //   //                                         .safeBlockHorizontal *
              //   //                                     2.5),
              //   //                           ),
              //   //                         ),
              //   //                       ),
              //   //                     ),
              //   //                   ),
              //   //                 ),
              //   //                 for (var v in categories.categoryList)
              //   //                   GestureDetector(
              //   //                     onTap: () {
              //   //                       audioPlayer.stop();
              //   //                       setState(() {
              //   //                         page = 0;
              //   //                         selectedCategory = v['id'];
              //   //                       });
              //   //                       getAllSnippets(v['id']);
              //   //                     },
              //   //                     child: Padding(
              //   //                       padding: const EdgeInsets.all(2.0),
              //   //                       child: Container(
              //   //                         decoration: BoxDecoration(
              //   //                             border: Border.all(
              //   //                                 color: kSecondaryColor),
              //   //                             color: selectedCategory == v['id']
              //   //                                 ? Color(0xff3a3a3a)
              //   //                                 : Colors.transparent,
              //   //                             borderRadius:
              //   //                                 BorderRadius.circular(20)),
              //   //                         child: Padding(
              //   //                           padding: const EdgeInsets.symmetric(
              //   //                               horizontal: 15, vertical: 3),
              //   //                           child: Center(
              //   //                             child: Text(
              //   //                               v['name'],
              //   //                               textScaleFactor: 1.0,
              //   //                               style: TextStyle(
              //   //                                   //  color:
              //   //                                   // Color(0xffe8e8e8),
              //   //                                   fontSize: SizeConfig
              //   //                                           .safeBlockHorizontal *
              //   //                                       2.5),
              //   //                             ),
              //   //                           ),
              //   //                         ),
              //   //                       ),
              //   //                     ),
              //   //                   ),
              //   //               ],
              //   //             ),
              //   //           ],
              //   //         ),
              //   //       ),
              //   //     ),
              //   //   ),
              //   // ),
              // ),
            ];
          },
          body: SnippetStoryView(data: snippets, index: 0,)),
    );
  }

  // Widget listPageViewSection() {
  //   return ListView.builder(
  //       controller: pageViewScrollController,
  //       physics: PageScrollPhysics(),
  //       addAutomaticKeepAlives: true,
  //       itemCount: snippets.length,
  //       itemBuilder: (context, int index) {
  //         return Container(
  //           height: MediaQuery.of(context).size.height,
  //           width: MediaQuery.of(context).size.width,
  //           child: Center(
  //             child: SwipeCard(
  //               clipObject: snippets[index],
  //
  //             ),
  //           ),
  //         );
  //       });
  // }
  //
  // Widget pageViewSection() {
  //   return PageView(
  //     scrollDirection: Axis.vertical,
  //     onPageChanged: (int index) async {
  //       setState(() {
  //         currentIndex = index;
  //       });
  //       audioPlayer.open(Audio.network(snippets[index]['url']));
  //       if (index == snippets.length - 1) {
  //         if (selectedCategory == 30) {
  //           getAllSnippetsWOCategory();
  //         } else {
  //           getAllSnippets(selectedCategory);
  //         }
  //       }
  //     },
  //     pageSnapping: true,
  //     controller: _pageController,
  //     children: [
  //       for (var v in snippets)
  //         SwipeCard(
  //           clipObject: v,
  //
  //         ),
  //     ],
  //   );
  // }
}




class SwipeCard extends StatefulWidget {
  final clipObject;

  final audioPlayer = AssetsAudioPlayer();

  SwipeCard({
    @required this.clipObject,
  });

  @override
  _SwipeCardState createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with  WidgetsBindingObserver{




  SharedPreferences pref;



  void play(BuildContext context) async {
    final snippetPlayer = Provider.of<PlayerChange>(context, listen: false);
    snippetPlayer.snippetPlayer.open(Audio.network(widget.clipObject['url']));
  }


  @override
  void initState() {
    // TODO: implement initState





    setState(() {
      isLiked = widget.clipObject['isLiked'];
      ifFollowed = widget.clipObject['ifFollows'];
    });
    super.initState();
    play(context);
  }

  void share() async {}

  bool isLiked;
  bool ifFollowed;




  int index;

  Future createIsolate() async {
    ReceivePort receiveport = ReceivePort();

    // Isolate.spawn(isolateFunction, receiveport.sendPort);

    SendPort childSendPort = await receiveport.first;

    ReceivePort responsePort = ReceivePort();

    childSendPort.send([widget.clipObject, responsePort.sendPort]);

    var response = await responsePort.first;

    print(response);
  }

  Color bgColor = Color(0xff222222);






  @override
  void dispose() {
    // TODO: implement dispose


    print("Dispose getting called right now");
    super.dispose();



  }

  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused) {
  //     audioPlayer.stop();
  //   }
  // }

  Dio dio = Dio();

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = widget.clipObject['podcast_id'];

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  void like() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/likeSnippet";

    var map = Map<String, dynamic>();
    map['snippet_id'] = widget.clipObject['id'];
    map['user_id'] = prefs.getString('userId');

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
    } catch (e) {
      print(e);
    }
  }



  @override
  Widget build(BuildContext context) {
    var snippetPlayer = Provider.of<PlayerChange>(context);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(

            gradient:
                LinearGradient(colors: [Color(0xff5d5da8), Color(0xff5bc3ef)]),
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
                image: CachedNetworkImageProvider(
                    widget.clipObject['podcast_image']),
                fit: BoxFit.cover),
          ),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaY: 15.0,
              sigmaX: 15.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        Center(
          child: Container(

            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: CachedNetworkImage(
                      placeholder: (context, url) {
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.width * 0.6,
                        );
                      },
                      memCacheHeight:
                          (MediaQuery.of(context).size.hashCode / 2).floor(),
                      imageUrl: widget.clipObject['podcast_image'],
                      imageBuilder: (context, imageProvider) {
                        return Container(
                          width: MediaQuery.of(context).size.height * 0.3,
                          height: MediaQuery.of(context).size.height * 0.3,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                  image: imageProvider, fit: BoxFit.cover)),
                        );
                      },
                    ),
                  ),
                  snippetPlayer.snippetPlayer
                      .builderRealtimePlayingInfos(
                      builder: (context, infos) {
                        if (infos != null) {
                          return ClipSeekBar(
                              currentPosition: infos.currentPosition,
                              duration: infos.duration,
                              audioplayer: snippetPlayer.snippetPlayer);
                        } else {
                          return SizedBox();
                        }
                      }),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "${widget.clipObject['episode_name']}",
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
                                  snippetPlayer.snippetPlayer
                                      .builderRealtimePlayingInfos(
                                          builder: (context, infos) {
                                    if (infos.isPlaying == true) {
                                      return InkWell(
                                          onTap: () {
                                            snippetPlayer.snippetPlayer.pause();
                                          },
                                          child: Icon(
                                              Icons.pause_circle_filled,
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
                                            snippetPlayer.snippetPlayer.play();
                                          },
                                          child: Icon(Icons.play_circle_fill,
                                              color: Color(0xffe8e8e8)));
                                    }
                                  }),
                                  // Text(
                                  //     "${widget.audioPlayer.realtimePlayingInfos.value.currentPosition}")
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      CupertinoPageRoute(builder: (context) {
                                    return EpisodeView(
                                        episodeId:
                                            widget.clipObject['episode_id']);
                                  }));
                                },
                                child: Text(
                                  "CONTINUE LISTENING",
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                      color: Color(0xffe8e8e8),
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal *
                                              2.5,
                                      fontWeight: FontWeight.w600),
                                ),
                              )
                            ],
                          ),
                          ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                              onTap: () {
                                setState(() {
                                  isLiked = !isLiked;
                                });
                                like();
                              },
                              child: isLiked == true
                                  ? Icon(
                                      FontAwesomeIcons.solidHeart,
                                      color: Colors.red,
                                    )
                                  : Icon(LineIcons.heart,
                                      color: Color(0xffe8e8e8))),
                          InkWell(
                            onTap: () {
                              setState(() {
                                ifFollowed = true;
                              });
                              follow();
                            },
                            child: ifFollowed == true
                                ? Text(
                                    "SUBSCRIBED",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        color: Color(0xffe8e8e8),
                                        fontWeight: FontWeight.w700,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal *
                                                3),
                                  )
                                : Text(
                                    "SUBSCRIBE",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        color: Color(0xffe8e8e8),
                                        fontWeight: FontWeight.w700,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal *
                                                3),
                                  ),
                          ),
                          // Icon(Icons.ios_share, color: Color(0xffe8e8e8))
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [

          ],
        )
      ],
    );
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
        trackHeight: 1,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0.0),
        activeTrackColor: Color(0xffe8e8e8),
           inactiveTrackColor: Colors.transparent,
        thumbColor: Colors.transparent,
        //  thumbShape: SliderComponentShape
        // thumbShape: RoundSliderThumbShape(
        //     pressedElevation: 1.0,
        //     pressedElevation: 1.0,
        //     enabledThumbRadius: 8,
        //     disabledThumbRadius: 5),
      ),
      child: Slider(
        // activeColor: Colors.white,
        // inactiveColor: Colors.white.withOpacity(0.5),
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

  postreq.Interceptor intercept = postreq.Interceptor();

  bool isPodcastListLoading = false;

  var podcastList = [];

  void getPodcasts() async {
    setState(() {
      isPodcastListLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/private/getUserPodcast?user_id=${prefs.getString('userId')}';
    try {
      print('came here too');
      print(url);

      var response = await intercept.getRequest(url);
      print(url);
      setState(() {
        print('came here too');

        isPodcastListLoading = false;
      });
      print('came here too');

      var data = response['podcasts'];
      print('came here too');
      print(data.toString());

      setState(() {
        podcastList = data;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _tabControler = TabController(length: 2, vsync: this);
    getPodcasts();

    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
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
                          hintText: "Search Podcast",
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
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
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
          ModalProgressHUD(
            inAsyncCall: isPodcastListLoading,
            child: isPodcastListLoading == true
                ? Container()
                : Container(
                    height: MediaQuery.of(context).size.height,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (var v in podcastList)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
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
                                  memCacheHeight:
                                      (MediaQuery.of(context).size.width / 2)
                                          .floor(),
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
                          )
                      ],
                    ),
                  ),
          )
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
  bool episodeListLoading = true;

  ScrollController _controller;

  void getEpisodes() async {
    setState(() {
      episodeListLoading = true;
    });
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

  RegExp htmlMatch = RegExp(r'(\w+)');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
                    colors: [Color(0xff5d5da8), Color(0xff5bc3ef)])
                .createShader(bounds);
          },
          child: Text(
            "Select episode to create your clip",
            textScaleFactor: 1.0,
            style: TextStyle(
                fontSize: SizeConfig.safeBlockHorizontal * 4,
                fontWeight: FontWeight.normal),
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: episodeListLoading,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView(
                shrinkWrap: true,
                controller: _controller,
                children: [
                  for (var v in episodeList)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: double.infinity,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          child: CachedNetworkImage(
                            memCacheHeight:
                                (MediaQuery.of(context).size.height / 3)
                                    .floor(),
                            imageUrl: v['image'],
                            imageBuilder: (context, imageProvider) {
                              return Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover)),
                              );
                            },
                          ),
                        ),

                        onTap: () {
                          Navigator.push(context,
                              CupertinoPageRoute(builder: (context) {
                            return SnippetEditor(
                              episodeObject: v,
                            );
                          }));
                        },
                        //
                        title: Text(
                          v['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              //       color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                        ),
                        subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              v['summary'] == null
                                  ? SizedBox(
                                      height: 20,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10.0),
                                      child: htmlMatch.hasMatch(v['summary']) ==
                                              true
                                          ? Text(
                                              '${(parse(v['summary']).body.text)}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  //       color: Colors.grey,
                                                  fontSize: SizeConfig
                                                          .blockSizeHorizontal *
                                                      3),
                                            )
                                          : Text(
                                              v['summary'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  //         color: Colors.grey,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3),
                                            ),
                                    ),
                            ]),
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

class SnippetEditor extends StatefulWidget {
  var episodeObject;

  SnippetEditor({@required this.episodeObject});

  @override
  _SnippetEditorState createState() => _SnippetEditorState();
}

class _SnippetEditorState extends State<SnippetEditor> {
  bool loading;

  String imagePath;

  // final FlutterFFmpeg _fFmpeg = FlutterFFmpeg();

  void createSnippet() async {
    String url = 'https://api.aureal.one/private/createSnippet';

    var map = Map<String, dynamic>();

    map['episode_id'] = widget.episodeObject['id'];
    map['start_time'] = startTime;
    map['end_time'] = endTime;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response.toString());
      preview.stop();
      Navigator.push(context, CupertinoPageRoute(builder: (context) {
        return ClipScreen();
      }));
    } catch (e) {
      print(e);
    }
  }

  double end = 1000;
  double start = 0.0;

  void getAudioGram(String audioUrl) async {
    setState(() {
      loading = true;
    });

    String customPath = 'aurealAudiogram';
    io.Directory appDocDirectory;

    if (io.Platform.isIOS) {
//      appDocDirectory = await getApplicationDocumentsDirectory();
      appDocDirectory = await getTemporaryDirectory();
    } else {
//      appDocDirectory = await getExternalStorageDirectory();
      appDocDirectory = await getTemporaryDirectory();
    }

    customPath = appDocDirectory.path +
        customPath +
        DateTime.now().millisecondsSinceEpoch.toString();

    // _fFmpeg
    //     .execute(
    //         '-i ${audioUrl} -filter_complex showwavespic=s=1280x720:colors=ffffff -frames:v 1 ${customPath}.png')
    //     .then((value) {
    //   setState(() {
    //     imagePath = '${customPath}.png';
    //   });
    // });

    setState(() {
      loading = false;
    });
  }

  bool isPlaying = false;

  AssetsAudioPlayer player = AssetsAudioPlayer();

  postreq.Interceptor intercept = postreq.Interceptor();

  @override
  void initState() {
    // TODO: implement initState

    getAudioGram(widget.episodeObject['url']);

    player.open(Audio.network(widget.episodeObject['url']));

    print(widget.episodeObject);

    super.initState();
  }

  void stop() {
    preview.stop();
  }

  @override
  void dispose() {
    player.stop();
    player.dispose();
    preview.stop();
    preview.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SnippetEditor oldWidget) {
    // TODO: implement didUpdateWidget

    super.didUpdateWidget(oldWidget);
  }

  var startTime;
  var endTime;

  RangeValues _values = RangeValues(0.00, 500);

  String DurationCalculation(int time) {
    double H = (time / 3600);
    double min = ((time % 3600) / 60);
    int sec = ((time % 3600) % 60);

    return "${H < 1 ? '00' : H.toStringAsFixed(0)} : ${min.toStringAsFixed(0)} : ${sec.toStringAsFixed(0)}";
  }

  TextEditingController _startTimeController = TextEditingController();
  TextEditingController _endTimeController = TextEditingController();

  AssetsAudioPlayer preview = AssetsAudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: CachedNetworkImage(
                            imageUrl: widget.episodeObject['image'],
                            imageBuilder: (context, imageProvider) {
                              return Container(
                                height: MediaQuery.of(context).size.width / 2.5,
                                width: MediaQuery.of(context).size.width / 2.5,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        "${widget.episodeObject['name']}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaleFactor: 1.0,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Color(0xffe8e8e8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: player.builderRealtimePlayingInfos(
                        builder: (context, infos) {
                      if (infos == null) {
                        return Container();
                      } else {
                        if (infos.isBuffering) {
                          return Icon(Icons.radio_button_off);
                        }
                        if (infos.isPlaying) {
                          return InkWell(
                              onTap: () {
                                player.pause();
                              },
                              child: Text("PAUSE"));
                        } else {
                          return InkWell(
                              onTap: () {
                                player.play();
                              },
                              child: Text("PLAY"));
                        }
                      }
                    }),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        enabled: false,
                        textAlign: TextAlign.center,
                        controller: _startTimeController,
                        decoration: InputDecoration(
                            hintText:
                                '${DurationCalculation(_values.start.round())}'),
                      ),
                    ),
                  )),
                  Expanded(
                      child: TextField(
                    enabled: false,
                    onChanged: (value) {
                      setState(() {});
                    },
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        hintText:
                            '${DurationCalculation(_values.end.round())}'),
                    controller: _endTimeController,
                  ))
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: imagePath == null
                            ? Container(
                                child: LinearProgressIndicator(
                                  value: 1.0,
                                  backgroundColor: Colors.redAccent,
                                ),
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Image.file(
                                  io.File(imagePath),
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                      Container(
                        decoration: BoxDecoration(),
                        child: SliderTheme(
                          data: SliderThemeData(
                              thumbColor: Colors.white,
                              overlayColor: Colors.transparent,
                              activeTrackColor:
                                  Colors.blueAccent.withOpacity(0.5),
                              inactiveTrackColor: Colors.transparent,
                              trackHeight: 150,
                              trackShape: RectangularSliderTrackShape()),
                          child: RangeSlider(
                            values: _values,
                            min: 0.00,
                            max: player.realtimePlayingInfos.hasValue == false
                                ? 1000.0
                                : player.realtimePlayingInfos.valueOrNull
                                    .duration.inSeconds
                                    .toDouble(),
                            divisions:
                                player.realtimePlayingInfos.hasValue == false
                                    ? 1000
                                    : player.realtimePlayingInfos.valueOrNull
                                        .duration.inSeconds,
                            labels: RangeLabels(
                                '${DurationCalculation(_values.start.round())}',
                                '${DurationCalculation(_values.end.round())}'),
                            onChanged: (RangeValues values) {
                              setState(() {
                                _values = values;
                                startTime = _values.start;
                                endTime = _values.end;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  player.builderRealtimePlayingInfos(builder: (context, infos) {
                    if (infos == null) {
                      return Container();
                    } else {
                      return Container(
                        child: SliderTheme(
                          data: SliderThemeData(
                              thumbColor: Colors.transparent,

                              // inactiveTrackColor: Colors.transparent,
                              activeTrackColor: Colors.amberAccent,
                              // trackHeight: 2,
                              thumbShape: SliderComponentShape.noThumb),
                          child: Slider(
                            value: infos.currentPosition.inSeconds.toDouble(),
                            onChanged: (double value) {
                              player.seek(Duration(seconds: value.floor()));
                            },
                            min: 0.0,
                            max: infos.duration.inSeconds.toDouble(),
                          ),
                        ),
                      );
                    }
                  }),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        isPlaying == true
                            ? InkWell(
                                onTap: () {
                                  setState(() {
                                    isPlaying = !isPlaying;
                                  });
                                  preview.stop();
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border:
                                          Border.all(color: Color(0xffe8e8e8))),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      child: Center(
                                          child: preview.isPlaying == true
                                              ? Text(
                                                  "${preview.realtimePlayingInfos.valueOrNull.currentPosition}")
                                              : Text("STOP")),
                                    ),
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () {
                                  setState(() {
                                    isPlaying = !isPlaying;
                                  });
                                  preview
                                      .open(
                                        Audio.network(
                                            widget.episodeObject['url']),
                                        seek: Duration(
                                          seconds: _values.start.floor(),
                                        ),
                                      )
                                      .then((value) => {
                                            Future.delayed(
                                                Duration(
                                                    seconds:
                                                        _values.end.round()),
                                                stop)
                                          });
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width / 3,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border:
                                          Border.all(color: Color(0xffe8e8e8))),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      child: Center(
                                          child: preview.isPlaying == true
                                              ? Text(
                                                  "${preview.realtimePlayingInfos.valueOrNull.currentPosition}")
                                              : Text("PREVIEW")),
                                    ),
                                  ),
                                ),
                              ),
                        InkWell(
                          onTap: () {
                            createSnippet();
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(colors: [
                                Color(0xff5d5da8),
                                Color(0xff5bc3ef)
                              ]),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                child: Center(child: Text("SAVE")),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
