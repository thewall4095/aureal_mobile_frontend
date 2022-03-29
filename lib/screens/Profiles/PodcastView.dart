import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/FollowingPage.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Profiles/publicUserProfile.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../PlayerState.dart';
import '../../main.dart';
import '../Clips.dart';
// import 'package:hive_flutter/hive_flutter.dart';

enum FollowState {
  follow,
  following,
}

class PodcastView extends StatefulWidget {
  static const String id = "Podcast view";

  var podcastId;

  PodcastView(this.podcastId);

  @override
  _PodcastViewState createState() => _PodcastViewState();
}

String _printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitHours = twoDigits(duration.inHours);
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  //
  String durationToShow = twoDigitHours != '00' ? (twoDigitHours + ':') : '';
  durationToShow += twoDigitMinutes != '00' ? (twoDigitMinutes + ':') : '';
  durationToShow += twoDigitSeconds;
  // return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  return durationToShow;
}

class _PodcastViewState extends State<PodcastView>
    with TickerProviderStateMixin {
  RegExp htmlMatch = RegExp(r'(\w+)');
  String hiveToken;

  FollowState followState;

  bool follows;

  ScrollController _controller = ScrollController();

  Dio dio = Dio();

  int maxLines;

  var episodeList = [];

  bool episodeListLoading = true;

  bool loading;

  bool isLoading = false;

  int pageNumber = 0;

  bool seeMore = false;

  get notificationPlugin => null;

  Future<void> _pullRefreshEpisodes() async {
    // getCommunityEposidesForUser();
    // await communities.getAllCommunitiesForUser();
    // await communities.getUserCreatedCommunities();
    // await communities.getAllCommunity();
    getPodcastData();
    getEpisodes();

    // await getFollowedPodcasts();
  }

  void podcastShare() async {
    await FlutterShare.share(
        title: '${podcastData['name']}',
        text:
            "Hey There, I'm listening to ${podcastData['name']} on Aureal, here's the link for you https://aureal.one/podcast/${podcastData['id']}");
  }

  void share({var episodeId, String episodeName}) async {
    await FlutterShare.share(
        title: '${podcastData['name']}',
        text:
            "Hey There, I'm listening to $episodeName from ${podcastData['name']} on Aureal, here's the link for you https://aureal.one/episode/${episodeId.toString()}");
  }

  SharedPreferences prefs;

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = widget.podcastId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  void _play(String url) {
    AudioPlayer player = AudioPlayer();
    player.play(url, isLocal: false);
  }

  var podcastData;

  String creator = '';

  List<Audio> playlist;

  void playListGenerator({List data}) async {
    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    List<Audio> playable = [];
    for (int i = 0; i < data.length; i++) {
      var v = data[i];
      playable.add(Audio.network(
        v['url'],
        metas: Metas(
          id: '${v['id']}',
          title: '${v['name']}',
          artist: '${v['author']}',
          album: '${v['podcast_name']}',
          // image: MetasImage.network('https://www.google.com')
          image: MetasImage.network(
              '${v['image'] == null ? v['podcast_image'] : v['image']}'),
        ),
      ));
    }

    playlist = playable;
    print(playlist);
    // episodeObject.dispose();
  }

  void getEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/episode?podcast_id=${widget.podcastId}&user_id=${prefs.getString('userId')}&page=$pageNumber';
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
          playListGenerator(data: episodeList);
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getPodcastData() async {
    setState(() {
      isLoading = true;
    });
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/podcast?podcast_id=${widget.podcastId}&user_id=${prefs.getString('userId')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(jsonDecode(response.body));
      if (response.statusCode == 200) {
        print(response.body);
        // episodeList = jsonDecode(response.body)['podcasts'][0]['Episodes'];

        setState(() {
          podcastData = jsonDecode(response.body)['podcast'];
          follows = jsonDecode(response.body)['podcast']['ifFollows'];
        });

        if (follows == true) {
          followState = FollowState.following;
        } else {
          followState = FollowState.follow;
        }

        print(podcastData);
        for (var v in episodeList) {
          v['isLoading'] = false;
        }

        setState(() {
          hiveToken = prefs.getString('access_token');
          creator = jsonDecode(response.body)['podcast']['user_id'];
          print(hiveToken);
          getColor(jsonDecode(response.body)['podcast']['image']);
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  //Isolate port

  ReceivePort _port = ReceivePort();

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  int dominantColor;

  Future<Color> getColor(String url) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(
            CachedNetworkImageProvider(url));

    setState(() {
      dominantColor = paletteGenerator.dominantColor.color.value;
    });
  }

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

  // void getColor(String url) async {
  //   getColorFromUrl(url).then((value) {
  //     setState(() {
  //       dominantColor = hexOfRGBA(value[0], value[1], value[2]);
  //       print(dominantColor.toString());
  //
  //       SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //         statusBarColor: Color(dominantColor),
  //       ));
  //     });
  //   });
  // }

  void _showBottomSheet() {
    setState(() {
      _showPersistantBottomSheetCallBack = null;
    });

    _scaffoldKey.currentState
        .showBottomSheet((context) {
          return new Container(
            height: 200.0,
            color: Colors.teal[100],
            child: Center(
              child: Text(
                "Drag Downwards Or Back To Dismiss Sheet",
                style: TextStyle(fontSize: 18, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          );
        })
        .closed
        .whenComplete(() {
          if (mounted) {
            setState(() {
              _showPersistantBottomSheetCallBack = _showBottomSheet;
            });
          }
        });
  }

  int page = 0;
  List snippets = [];

  void getAllSnippets() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/discoverSnippets?loggedinuser=${prefs.getString('userId')}&page=$page&podcast_id=${widget.podcastId}";
    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (page == 0) {
          setState(() {
            snippets = jsonDecode(response.body)['snippets'];
            page = page + 1;
          });
        } else {
          setState(() {
            snippets = snippets + jsonDecode(response.body)['snippets'];
            page = page + 1;
          });
        }
        print(response.body);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    // TODO: implement initState
//    setEpisodes();
    _showPersistantBottomSheetCallBack = _showBottomSheet;

    getPodcastData();
    getEpisodes();
    getEpisodeRecommendations();
    getPodcastRecommendations();
    getPeopleRecommendation(widget.podcastId);
    getAllSnippets();

    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState(() {});
    });

    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        getEpisodes();
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  List podcastRecommendations = [];
  List episodeRecommendations = [];
  List peopleRecommendations = [];
  List playlistRecommendations = [];

  void getPeopleRecommendation(var podcastId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedArtists?page=0&pageSize=10&user_id=${prefs.getString('userId')}&type=podcast_based&podcast_id=$podcastId";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print(response.data);
        setState(() {
          peopleRecommendations = response.data['authors'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getEpisodeRecommendations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedEpisodes?user_id=${prefs.getString('userId')}&size=20&page=0&podcast_id=${widget.podcastId}";
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        setState(() {
          episodeRecommendations = response.data['episodes'];
        });
        print(episodeRecommendations);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getPodcastRecommendations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommendedPodcasts?page=0&pageSize=10&user_id=${prefs.getString('userId')}&type=podcast_based&podcast_id=${widget.podcastId}";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        setState(() {
          podcastRecommendations = response.data['podcasts'];
        });
        print(response.data);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  VoidCallback _showPersistantBottomSheetCallBack;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  var audioPlaylist = <Audio>[];

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final currentlyPlaying = Provider.of<PlayerChange>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
      key: _scaffoldKey,

      body: Stack(
        children: [
          NestedScrollView(
              controller: _controller,
              physics: BouncingScrollPhysics(),
              headerSliverBuilder:
                  (BuildContext context, bool isInnerBoxScrolled) {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: dominantColor == null
                        ? Colors.black
                        : Color(dominantColor),
                    centerTitle: true,
                    pinned: true,
                    floating: true,
                    actions: [
                      IconButton(
                        icon: Icon(Icons.more_vert_outlined),
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: ListTile(
                                        leading: CachedNetworkImage(
                                          memCacheHeight:
                                              (MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2)
                                                  .floor(),
                                          imageUrl: podcastData['image'],
                                          imageBuilder:
                                              (context, imageProvider) {
                                            return Container(
                                              height: 50,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover)),
                                            );
                                          },
                                          placeholder: (context, url) {
                                            return Container(
                                              height: 50,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  image: DecorationImage(
                                                      image:
                                                          CachedNetworkImageProvider(
                                                              placeholderUrl),
                                                      fit: BoxFit.cover)),
                                            );
                                          },
                                          errorWidget: (context, e, url) {
                                            return Container(
                                              height: 50,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                color: Color(0xff121212),
                                              ),
                                            );
                                          },
                                        ),
                                        title: Text(
                                          "${podcastData['name']}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle:
                                            Text("${podcastData['author']}"),
                                      ),
                                    ),
                                    Divider(),
                                    ListTile(
                                      leading: Icon(Icons.ios_share),
                                      title: Text("Share"),
                                      onTap: () {
                                        podcastShare();
                                      },
                                    ),
                                    ListTile(
                                      onTap: () {
                                        follow();
                                        setState(() {
                                          if (followState ==
                                              FollowState.follow) {
                                            followState = FollowState.following;
                                          } else {
                                            followState = FollowState.follow;
                                          }
                                        });
                                        Navigator.pop(context);
                                      },
                                      leading: Icon(Icons.add_circle_outline),
                                      title: Text("Subscribe"),
                                    ),
                                    // ListTile(
                                    //   leading: Icon(Icons.notification_add),
                                    //   title: Text("Get Notified"),
                                    // ),
                                    //     ListTile(
                                    //       onTap:() {
                                    //
                                    // },
                                    //       leading: Icon(Icons.playlist_add),
                                    //       title: Text("Add to podcast playlist"),
                                    //     ),
                                    // ListTile(
                                    //   leading: Icon(Icons.animation),
                                    //   title: Text("More like these"),
                                    // ),
                                    // ListTile(
                                    //   leading: Icon(Icons.send),
                                    //   title: Text("Invite this podcast to Aureal"),
                                    // ),
                                  ],
                                );
                              });
                        },
                      ),
                    ],
                    //   backgroundColor: kPrimaryColor,
                    expandedHeight: MediaQuery.of(context).size.height / 1.5,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              Color(dominantColor == null
                                  ? 0xff3a3a3a
                                  : dominantColor),
                              Colors.black
                            ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter)),
                        child: podcastData == null
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Shimmer.fromColors(
                                  baseColor: themeProvider.isLightTheme == false
                                      ? kPrimaryColor
                                      : Colors.white,
                                  highlightColor:
                                      themeProvider.isLightTheme == false
                                          ? Color(0xff3a3a3a)
                                          : Colors.white,
                                  child: Container(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          color: kSecondaryColor,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2.5,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2.5,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          // width: MediaQuery.of(context).size.width / 2,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 20,
                                                      color: kSecondaryColor,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 20,
                                                      color: kSecondaryColor,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0,
                                                            right: 8.0,
                                                            top: 8.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 20,
                                                      color: kSecondaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                10,
                                      ),
                                      Hero(
                                        tag: '${podcastData['id']}',
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CachedNetworkImage(
                                              imageBuilder:
                                                  (context, imageProvider) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover),
                                                  ),
                                                );
                                              },
                                              memCacheHeight:
                                                  (MediaQuery.of(context)
                                                          .size
                                                          .height)
                                                      .floor(),
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2.5,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2.5,
                                                child: Image.asset(
                                                    'assets/images/Thumbnail.png'),
                                              ),
                                              imageUrl: podcastData == null
                                                  ? placeholderUrl
                                                  : podcastData['image'],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  podcastData['name'],
                                                  textScaleFactor:
                                                      mediaQueryData
                                                          .textScaleFactor
                                                          .clamp(0.5, 1)
                                                          .toDouble(),
                                                  style: TextStyle(
                                                      //    color: Color(0xffe8e8e8),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          5),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: InkWell(
                                                    onTap: () {
                                                      if (podcastData[
                                                              'author_hiveusername'] !=
                                                          null) {
                                                        Navigator.push(context,
                                                            CupertinoPageRoute(
                                                                builder:
                                                                    (context) {
                                                          return PublicProfile(
                                                            userId: podcastData[
                                                                'user_id'],
                                                          );
                                                        }));
                                                      }
                                                    },
                                                    child: Text(
                                                      podcastData['author'],
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textScaleFactor:
                                                          mediaQueryData
                                                              .textScaleFactor
                                                              .clamp(0.5, 1)
                                                              .toDouble(),
                                                      style: TextStyle(
                                                          color: Color(
                                                                  0xffe8e8e8)
                                                              .withOpacity(0.5),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              3),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                currentlyPlaying
                                                            .isPlaylistPlaying ==
                                                        true
                                                    ? InkWell(
                                                        onTap: () {
                                                          Vibrate.feedback(
                                                              FeedbackType
                                                                  .impact);
                                                          currentlyPlaying
                                                              .audioPlayer
                                                              .pause();
                                                        },
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30),
                                                              gradient:
                                                                  LinearGradient(
                                                                      colors: [
                                                                    Color(
                                                                        0xff5d5da8),
                                                                    Color(
                                                                        0xff5bc3ef)
                                                                  ])),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        40,
                                                                    vertical:
                                                                        8),
                                                            child:
                                                                Text("Pause"),
                                                          ),
                                                        ),
                                                      )
                                                    : InkWell(
                                                        onTap: () {
                                                          Vibrate.feedback(
                                                              FeedbackType
                                                                  .impact);
                                                          showModalBottomSheet(
                                                              isScrollControlled:
                                                                  true,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              barrierColor: Colors
                                                                  .transparent,
                                                              isDismissible:
                                                                  true,
                                                              // bounce: true,
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return Player2();
                                                              });
                                                          currentlyPlaying
                                                              .audioPlayer
                                                              .open(
                                                                  Playlist(
                                                                      audios:
                                                                          playlist,
                                                                      startIndex:
                                                                          0),
                                                                  showNotification:
                                                                      true);
                                                          // setState(() {
                                                          //   currentlyPlaying.stop();
                                                          //   currentlyPlaying.playList =
                                                          //       episodeList;
                                                          //
                                                          //   currentlyPlaying
                                                          //           .episodeObject =
                                                          //       currentlyPlaying
                                                          //           .playList[0];
                                                          //   currentlyPlaying.play();
                                                          //   currentlyPlaying
                                                          //           .isPlaylistPlaying =
                                                          //       true;
                                                          // });
                                                        },
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          30),
                                                              gradient:
                                                                  LinearGradient(
                                                                      colors: [
                                                                    Color(
                                                                        0xff5d5da8),
                                                                    Color(
                                                                        0xff5bc3ef)
                                                                  ])),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        40,
                                                                    vertical:
                                                                        8),
                                                            child: Text("Play"),
                                                          ),
                                                        ),
                                                      ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                followState ==
                                                        FollowState.following
                                                    ? InkWell(
                                                        onTap: () {
                                                          follow();
                                                          setState(() {
                                                            if (followState ==
                                                                FollowState
                                                                    .follow) {
                                                              followState =
                                                                  FollowState
                                                                      .following;
                                                            } else {
                                                              followState =
                                                                  FollowState
                                                                      .follow;
                                                            }
                                                          });
                                                        },
                                                        child: Icon(
                                                            Icons.check_circle))
                                                    : InkWell(
                                                        onTap: () async {
                                                          follow();
                                                          setState(() {
                                                            if (followState ==
                                                                FollowState
                                                                    .follow) {
                                                              followState =
                                                                  FollowState
                                                                      .following;
                                                            } else {
                                                              followState =
                                                                  FollowState
                                                                      .follow;
                                                            }
                                                          });
                                                        },
                                                        child: Icon(
                                                            Icons.add_circle),
                                                      ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Padding(
                                      //   padding: const EdgeInsets.all(8.0),
                                      //   child: Container(
                                      //     width: MediaQuery.of(context).size.width,
                                      //     child: Column(
                                      //         crossAxisAlignment:
                                      //         CrossAxisAlignment.start,
                                      //         children: [
                                      //           podcastData == null
                                      //               ? SizedBox()
                                      //               : htmlMatch.hasMatch(podcastData[
                                      //           'description']) ==
                                      //               true
                                      //               ? Text(
                                      //             '${(parse(podcastData['description']).body.text)}',
                                      //             maxLines:
                                      //             seeMore == true
                                      //                 ? 30
                                      //                 : 2,
                                      //             overflow: TextOverflow
                                      //                 .ellipsis,
                                      //             textScaleFactor:
                                      //             mediaQueryData
                                      //                 .textScaleFactor
                                      //                 .clamp(0.5, 1.5)
                                      //                 .toDouble(),
                                      //             style: TextStyle(
                                      //               //      color: Colors.grey,
                                      //                 fontSize: SizeConfig
                                      //                     .blockSizeHorizontal *
                                      //                     3),
                                      //           )
                                      //               : Text(
                                      //             podcastData[
                                      //             'description'],
                                      //             maxLines:
                                      //             seeMore == true
                                      //                 ? 30
                                      //                 : 2,
                                      //             overflow: TextOverflow
                                      //                 .ellipsis,
                                      //             textScaleFactor:
                                      //             mediaQueryData
                                      //                 .textScaleFactor
                                      //                 .clamp(0.5, 1)
                                      //                 .toDouble(),
                                      //             style: TextStyle(
                                      //               //  color: Colors.grey,
                                      //                 fontSize: SizeConfig
                                      //                     .safeBlockHorizontal *
                                      //                     3),
                                      //           ),
                                      //           InkWell(
                                      //             onTap: () {
                                      //               showBarModalBottomSheet(
                                      //                   context: context,
                                      //                   builder: (context) {
                                      //                     return Container(
                                      //                       child: Column(
                                      //                         mainAxisSize:
                                      //                         MainAxisSize.min,
                                      //                         children: [
                                      //                           ListTile(
                                      //                             leading: SizedBox(
                                      //                               height: 50,
                                      //                               width: 50,
                                      //                               child:
                                      //                               CachedNetworkImage(
                                      //                                 imageUrl: podcastData ==
                                      //                                     null
                                      //                                     ? placeholderUrl
                                      //                                     : podcastData[
                                      //                                 'image'],
                                      //                                 imageBuilder:
                                      //                                     (context,
                                      //                                     imageProvider) {
                                      //                                   return Container(
                                      //                                     decoration: BoxDecoration(
                                      //                                         image: DecorationImage(
                                      //                                             image: imageProvider,
                                      //                                             fit: BoxFit.cover)),
                                      //                                   );
                                      //                                 },
                                      //                               ),
                                      //                             ),
                                      //                             title: Text(
                                      //                                 "${podcastData['name']}"),
                                      //                             subtitle: Text(
                                      //                                 "${podcastData['author']}"),
                                      //                           ),
                                      //                           Divider(),
                                      //                           ListTile(
                                      //                             subtitle: podcastData ==
                                      //                                 null
                                      //                                 ? SizedBox()
                                      //                                 : htmlMatch.hasMatch(
                                      //                                 podcastData['description']) ==
                                      //                                 true
                                      //                                 ? Text(
                                      //                               '${(parse(podcastData['description']).body.text)}',
                                      //                               textScaleFactor: mediaQueryData
                                      //                                   .textScaleFactor
                                      //                                   .clamp(0.5, 1.5)
                                      //                                   .toDouble(),
                                      //                               style: TextStyle(
                                      //                                 //      color: Colors.grey,
                                      //                                   fontSize: SizeConfig.blockSizeHorizontal * 3.5),
                                      //                             )
                                      //                                 : Text(
                                      //                               podcastData[
                                      //                               'description'],
                                      //                               textScaleFactor: mediaQueryData
                                      //                                   .textScaleFactor
                                      //                                   .clamp(0.5, 1)
                                      //                                   .toDouble(),
                                      //                               style: TextStyle(
                                      //                                 //  color: Colors.grey,
                                      //                                   fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                      //                             ),
                                      //                           ),
                                      //                           SizedBox(
                                      //                             height: 20,
                                      //                           )
                                      //                         ],
                                      //                       ),
                                      //                     );
                                      //                   });
                                      //             },
                                      //             child: Text(
                                      //               seeMore == false
                                      //                   ? "See more"
                                      //                   : "See less",
                                      //               style: TextStyle(
                                      //                   color: Colors.white
                                      //                       .withOpacity(0.5)),
                                      //             ),
                                      //           ),
                                      //         ]),
                                      //   ),
                                      // ),
                                      // Padding(
                                      //   padding: const EdgeInsets.all(8.0),
                                      //   child: Row(
                                      //     mainAxisAlignment:
                                      //         MainAxisAlignment.spaceBetween,
                                      //     children: [
                                      //       Text(
                                      //           "All Episodes (${podcastData['total_count']})"),
                                      //       Padding(
                                      //         padding: const EdgeInsets.symmetric(
                                      //             horizontal: 8),
                                      //         child: ShaderMask(
                                      //             shaderCallback: (Rect bounds) {
                                      //               return LinearGradient(colors: [
                                      //                 Color(0xff5d5da8),
                                      //                 Color(0xff5bc3ef)
                                      //               ]).createShader(bounds);
                                      //             },
                                      //             child: InkWell(
                                      //               onTap: () {
                                      //                 showMaterialModalBottomSheet(
                                      //                     enableDrag: false,
                                      //                     context: context,
                                      //                     builder: (context) {
                                      //                       return SnippetDisplay(
                                      //                         podcastObject:
                                      //                             podcastData,
                                      //                       );
                                      //                     });
                                      //               },
                                      //               child: Text(
                                      //                 "Snippets",
                                      //                 textScaleFactor: 1.0,
                                      //                 style: TextStyle(
                                      //                     fontWeight:
                                      //                         FontWeight.w600),
                                      //               ),
                                      //             )),
                                      //       )
                                      //     ],
                                      //   ),
                                      // )
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(50),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaY: 15.0,
                              sigmaX: 15.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TabBar(
                                  isScrollable: true,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  controller: _tabController,
                                  tabs: [
                                    Tab(
                                      text: "EPISODES",
                                    ),
                                    Tab(
                                      text: "RELATED",
                                    ),
                                    Tab(
                                      text: "ABOUT",
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(colors: [
                                          Color(0xff5d5da8),
                                          Color(0xff5bc3ef)
                                        ]).createShader(bounds);
                                      },
                                      child: InkWell(
                                        onTap: () {
                                          showMaterialModalBottomSheet(
                                              enableDrag: false,
                                              context: context,
                                              builder: (context) {
                                                // return SnippetDisplay(
                                                //   podcastObject: podcastData,
                                                // );
                                                return SnippetStoryView(
                                                  data: snippets,
                                                  index: 0,
                                                );
                                              });
                                        },
                                        child: Text(
                                          "Snippets",
                                          textScaleFactor: 1.0,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      )),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: episodeList.length + 2,
                      itemBuilder: (context, int index) {
                        if (index == 0) {
                          return SizedBox();
                        } else {
                          if (index == episodeList.length + 1) {
                            if (isLoading == false) {
                              for (int i = 0; i < 2; i++) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Color(0xff1a1a1a)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3),
                                            child: Container(
                                                color: Colors.black,
                                                height: 10,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3),
                                            child: Container(
                                                color: Colors.black,
                                                height: 10,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2),
                                          ),
                                          SizedBox(
                                            height: 6,
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3),
                                            child: Container(
                                                color: Colors.black,
                                                height: 6,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3),
                                            child: Container(
                                                color: Colors.black,
                                                height: 6,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.75),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: Colors.black,
                                                  ),
                                                  height: 25,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      8,
                                                  //    color: kSecondaryColor,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Colors.black,
                                                    ),
                                                    height: 25,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            8,
                                                    //    color: kSecondaryColor,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.black,
                                                    ),
                                                    height: 20,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            8,
                                                    //    color: kSecondaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } else {
                              return SizedBox();
                            }
                          }

                          return EpisodeCard(
                            data: episodeList[index - 1],
                            index: index - 1,
                            playlist: playlist,
                          );
                        }
                      }),
                  ListView(
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: 15,
                          ),
                          episodeRecommendations.length == 0
                              ? SizedBox()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Text(
                                        "You might also like",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              2.8,
                                      child: GridView(
                                        scrollDirection: Axis.horizontal,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 4,
                                                mainAxisSpacing: 10,
                                                crossAxisSpacing: 1,
                                                childAspectRatio: 1.2 / 5.3),
                                        children: [
                                          for (var a in episodeRecommendations)
                                            ListTile(
                                              onTap: () {
                                                List<Audio> playable = [];
                                                for (var v
                                                    in episodeRecommendations) {
                                                  playable.add(Audio.network(
                                                    v['url'],
                                                    metas: Metas(
                                                      id: '${v['id']}',
                                                      title: '${v['name']}',
                                                      artist: '${v['author']}',
                                                      album:
                                                          '${v['podcast_name']}',
                                                      // image: MetasImage.network('https://www.google.com')
                                                      image: MetasImage.network(
                                                          '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                    ),
                                                  ));
                                                }
                                                currentlyPlaying.playList =
                                                    playable;
                                                currentlyPlaying.audioPlayer.open(
                                                    Playlist(
                                                        audios: currentlyPlaying
                                                            .playList,
                                                        startIndex:
                                                            episodeRecommendations
                                                                .indexOf(a)),
                                                    showNotification: true);
                                              },
                                              leading: CircleAvatar(
                                                radius: 25,
                                                child: CachedNetworkImage(
                                                  imageBuilder:
                                                      (context, imageProvider) {
                                                    return Container(
                                                      height: 60,
                                                      width: 60,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                        image: DecorationImage(
                                                            image:
                                                                imageProvider,
                                                            fit: BoxFit.cover),
                                                      ),
                                                    );
                                                  },
                                                  memCacheHeight:
                                                      (MediaQuery.of(context)
                                                              .size
                                                              .height)
                                                          .floor(),
                                                  imageUrl: a['image'] != null
                                                      ? a['image']
                                                      : placeholderUrl,
                                                  placeholder:
                                                      (context, imageProvider) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                          image: DecorationImage(
                                                              image: AssetImage(
                                                                  'assets/images/Thumbnail.png'),
                                                              fit: BoxFit
                                                                  .cover)),
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.38,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.38,
                                                    );
                                                  },
                                                ),
                                              ),
                                              title: Text(
                                                a['name'].toString(),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                                textScaleFactor: 1.0,
                                                style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3),
                                              ),
                                              trailing: Icon(Icons.more_vert),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          podcastRecommendations.length == 0
                              ? SizedBox()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Text(
                                        "Recommended Podcasts",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: SizeConfig.blockSizeVertical * 28,
                                      constraints: BoxConstraints(
                                          minHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.17),
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          Row(
                                            children: [
                                              for (var a
                                                  in podcastRecommendations)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          15, 0, 0, 8),
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                          context,
                                                          CupertinoPageRoute(
                                                              builder: (context) =>
                                                                  PodcastView(a[
                                                                      'id'])));
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                      ),
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.38,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          CachedNetworkImage(
                                                            errorWidget:
                                                                (context, url,
                                                                    error) {
                                                              return Container(
                                                                decoration: BoxDecoration(
                                                                    image: DecorationImage(
                                                                        image: NetworkImage(
                                                                            placeholderUrl),
                                                                        fit: BoxFit
                                                                            .cover),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            3)),
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.38,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.38,
                                                              );
                                                            },
                                                            imageBuilder: (context,
                                                                imageProvider) {
                                                              return Container(
                                                                decoration: BoxDecoration(
                                                                    image: DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            3)),
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.38,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.38,
                                                              );
                                                            },
                                                            memCacheHeight:
                                                                (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height)
                                                                    .floor(),
                                                            imageUrl: a['image'] !=
                                                                    null
                                                                ? a['image']
                                                                : placeholderUrl,
                                                            placeholder: (context,
                                                                imageProvider) {
                                                              return Container(
                                                                decoration: BoxDecoration(
                                                                    image: DecorationImage(
                                                                        image: AssetImage(
                                                                            'assets/images/Thumbnail.png'),
                                                                        fit: BoxFit
                                                                            .cover)),
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.38,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.38,
                                                              );
                                                            },
                                                          ),
                                                          SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            a['name'],
                                                            maxLines: 1,
                                                            textScaleFactor:
                                                                1.0,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            // style:
                                                            //     TextStyle(color: Color(0xffe8e8e8)),
                                                          ),
                                                          Text(
                                                            a['author'],
                                                            maxLines: 2,
                                                            textScaleFactor:
                                                                1.0,
                                                            style: TextStyle(
                                                                fontSize: SizeConfig
                                                                        .safeBlockHorizontal *
                                                                    2.5,
                                                                color: Color(
                                                                    0xffe777777)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          peopleRecommendations.length == 0
                              ? SizedBox()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Text(
                                        "Podcasters for you",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              5,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          for (var v in peopleRecommendations)
                                            Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(context,
                                                      CupertinoPageRoute(
                                                          builder: (context) {
                                                    return PublicProfile(
                                                      userId: v['id'],
                                                    );
                                                  }));
                                                },
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
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
                                                              4,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                        );
                                                      },
                                                      imageUrl: v['img'],
                                                      memCacheWidth:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width
                                                              .floor(),
                                                      memCacheHeight:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width
                                                              .floor(),
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            7,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            7,
                                                        child: Image.asset(
                                                            'assets/images/Thumbnail.png'),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Container(
                                                              width: MediaQuery
                                                                          .of(
                                                                              context)
                                                                      .size
                                                                      .width /
                                                                  4,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  4,
                                                              child: Icon(
                                                                Icons.error,
                                                                color: Color(
                                                                    0xffe8e8e8),
                                                              )),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 10),
                                                      child: Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            4,
                                                        child: Text(
                                                          "${v['username']}",
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xffe8e8e8)),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                        ],
                      ),
                    ],
                  ),
                  ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: podcastData == null
                            ? SizedBox()
                            : htmlMatch.hasMatch(podcastData['description']) ==
                                    true
                                ? Text(
                                    '${(parse(podcastData['description']).body.text)}',
                                    maxLines: 30,
                                    overflow: TextOverflow.ellipsis,
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        //      color: Colors.grey,
                                        fontSize:
                                            SizeConfig.blockSizeHorizontal * 3),
                                  )
                                : Text(
                                    podcastData['description'],
                                    maxLines: 30,
                                    overflow: TextOverflow.ellipsis,
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        //  color: Colors.grey,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  ),
                      ),
                    ],
                  ),
                ],
                physics: BouncingScrollPhysics(),
              )),
          Align(alignment: Alignment.bottomCenter, child: BottomPlayer())
        ],
      ),
      // bottomSheet: BottomPlayer(),
    );
  }
}

class _AnimationHeader extends SliverPersistentHeaderDelegate {
  var podcastData;
  int dominantColor;

  _AnimationHeader(
      {this.podcastData,
      @required this.dominantColor,
      @required this.dio,
      @required this.followState,
      @required this.follows});

  RegExp htmlMatch = RegExp(r'(\w+)');
  Dio dio = Dio();
  FollowState followState;
  bool follows;

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = podcastData;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  double _maxExtent = 320;
  double _minExtent = 150;
  double _maxImageSize = 180;
  double _minImageSize = 80;
  double _maxTitleSize = 20;
  double _maxSubTitleSize = 12;
  double _minTitleSize = 15;
  double _minSubTitleSize = 10;
  double _maxFollowButton = 0;

  void setExtentValue(BuildContext context) {
    _maxExtent = MediaQuery.of(context).size.height * 0.33;
    _minExtent = MediaQuery.of(context).size.height / 5.5;
    _maxImageSize = MediaQuery.of(context).size.width * 0.42;
    _minImageSize = (MediaQuery.of(context).size.width * 0.42) / 2;
    _maxTitleSize = ((MediaQuery.of(context).size.width * 0.35) / 2) / 4;
    _maxFollowButton = MediaQuery.of(context).size.width * 0.2;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // print(shrinkOffset);
    setExtentValue(context);
    print(shrinkOffset);

    double percent = shrinkOffset / _maxExtent;
    double currentImageSize =
        (_maxImageSize * (1 - percent)).clamp(_minImageSize, _maxImageSize);
    double SubSize = (_maxSubTitleSize * (1 - percent)).clamp(
      _minSubTitleSize,
      _maxSubTitleSize,
    );
    double TitleSize = (_maxTitleSize * (1 - percent)).clamp(
      _minTitleSize,
      _maxTitleSize,
    );

    final buttonMargin = 320;
    final followButton = 200;
    final maxMargin = 200;
    final textMovement = 150;
    final marginFollow = 500;
    final buttonMargin1 = buttonMargin + (marginFollow * percent);
    final buttonFollowMargin = followButton + (marginFollow * percent);
    final leftTextMargin = maxMargin + (textMovement * percent);
    final mediaQueryData = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        Color(dominantColor == null ? 0xff3a3a3a : dominantColor),
        kPrimaryColor
      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: podcastData == null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Shimmer.fromColors(
                baseColor: themeProvider.isLightTheme == false
                    ? kPrimaryColor
                    : Colors.white,
                highlightColor: themeProvider.isLightTheme == false
                    ? Color(0xff3a3a3a)
                    : Colors.white,
                child: Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        color: kSecondaryColor,
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: MediaQuery.of(context).size.width / 2.5,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        // width: MediaQuery.of(context).size.width / 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: kSecondaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: kSecondaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8.0, top: 8.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: kSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                SafeArea(
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      currentImageSize != _maxImageSize
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 80),
                              child: IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    Icons.arrow_back,
                                  )),
                            )
                          : SizedBox(),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: CachedNetworkImage(
                          imageUrl: podcastData['image'],
                          memCacheHeight:
                              (MediaQuery.of(context).size.height / 2).ceil(),
                          imageBuilder: (context, imageProvider) {
                            return Container(
                              width: currentImageSize,
                              height: currentImageSize,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                      image: imageProvider, fit: BoxFit.cover)),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${podcastData['name']}",
                                style: TextStyle(fontSize: TitleSize),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height / 100,
                              ),
                              Text(
                                "${podcastData['author']}",
                                style: TextStyle(
                                    fontSize: SubSize,
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 40,
                              ),
                              currentImageSize != _maxImageSize
                                  ? SizedBox()
                                  : FollowButton(
                                      podcastData: podcastData,
                                      follows: follows,
                                      followState: followState,
                                    ),
                            ]),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class FollowButton extends StatefulWidget {
  FollowState followState;
  bool follows;
  var podcastData;

  FollowButton(
      {@required this.podcastData,
      @required this.follows,
      @required this.followState});

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  FollowState followState;
  bool follows;

  Dio dio = Dio();

  void podcastShare() async {
    await FlutterShare.share(
        title: '${widget.podcastData['name']}',
        text:
            "Hey There, I'm listening to ${widget.podcastData['name']} on Aureal, here's the link for you https://aureal.one/podcast/${widget.podcastData['id']}");
  }

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = widget.podcastData['id'];

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      followState = widget.followState;
      follows = widget.follows;
    });
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Row(
      children: [
        followState == FollowState.following
            ? InkWell(
                onTap: () {
                  follow();
                  setState(() {
                    if (followState == FollowState.follow) {
                      followState = FollowState.following;
                    } else {
                      followState = FollowState.follow;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: kSecondaryColor
                          //    color: Color(0xffe8e8e8),
                          ,
                          width: 0.5)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(
                      'Unsubscribe',
                      textScaleFactor: mediaQueryData.textScaleFactor
                          .clamp(0.5, 1)
                          .toDouble(),
                      style: TextStyle(
                          //      color: Color(0xffe8e8e8)
                          ),
                    ),
                  ),
                ))
            : InkWell(
                onTap: () async {
                  follow();
                  setState(() {
                    if (followState == FollowState.follow) {
                      followState = FollowState.following;
                    } else {
                      followState = FollowState.follow;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: kSecondaryColor,
                          //    color: Color(0xffe8e8e8),
                          width: 0.5)
                      //color: Color(0xffe8e8e8)
                      ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(
                      'Subscribe',
                      textScaleFactor: mediaQueryData.textScaleFactor
                          .clamp(0.5, 1)
                          .toDouble(),
                      style: TextStyle(
                          // color: Color(0xff3a3a3a)
                          ),
                    ),
                  ),
                ),
              ),
        InkWell(
          onTap: podcastShare,
          child: Column(
            children: <Widget>[
              IconButton(
                onPressed: () {
                  podcastShare();
                },
                icon: Icon(
                  Icons.ios_share,
                  //    color: Colors.grey,
                  size: 18,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class SnippetDisplay extends StatefulWidget {
  var podcastObject;

  SnippetDisplay({@required this.podcastObject});

  @override
  _SnippetDisplayState createState() => _SnippetDisplayState();
}

class _SnippetDisplayState extends State<SnippetDisplay> {
  int currentIndex = 0;

  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

  PageController _pageController = PageController(viewportFraction: 0.7);

  List snippets = [];

  bool isLoading;

  int page = 0;

  postreq.Interceptor intercept = postreq.Interceptor();

  void getAllSnippets() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/discoverSnippets?loggedinuser=${prefs.getString('userId')}&page=$page&podcast_id=${widget.podcastObject['id']}";
    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (page == 0) {
          setState(() {
            snippets = jsonDecode(response.body)['snippets'];
            page = page + 1;
          });
        } else {
          setState(() {
            snippets = snippets + jsonDecode(response.body)['snippets'];
            page = page + 1;
          });
        }
        print(response.body);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getAllSnippets();

    super.initState();
    _pageController.addListener(() {
      print(_pageController.page);
      if (_pageController.page == snippets.length - 1) {
        getAllSnippets();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          Container(
            child: PageView(
              scrollDirection: Axis.vertical,
              onPageChanged: (int index) async {
                setState(() {
                  currentIndex = index;
                });
                audioPlayer.open(Audio.network(snippets[index]['url']));
              },
              pageSnapping: true,
              controller: _pageController,
              children: [
                for (var v in snippets)
                  SwipeCard(
                    clipObject: v,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
