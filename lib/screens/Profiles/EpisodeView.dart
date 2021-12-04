import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:auditory/Services/audioEditor.dart';
import 'package:auditory/screens/Profiles/publicUserProfile.dart';
import 'package:html/parser.dart';
import 'package:auditory/DatabaseFunctions/EpisodesBloc.dart';
import 'package:auditory/DatabaseFunctions/EpisodesProvider.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/models/Episode.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:linkable/linkable.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PodcastView.dart';

enum Like {
  liked,
  unliked,
}

class EpisodeView extends StatefulWidget {
  static const String id = "EpisodeView";

  final episodeId;
  String podcastName;

  EpisodeView({@required this.episodeId});

  @override
  _EpisodeViewState createState() => _EpisodeViewState();
}

class _EpisodeViewState extends State<EpisodeView>
    with TickerProviderStateMixin {
  final _episodeBloc = EpisodeBloc();
  final _mp = EpisodesProvider.getInstance();

  RegExp htmlMatch = RegExp(r'(\w+)');

  SharedPreferences pref;
  Like likeStatus;
  String hiveToken;
  String displayPicture;
  bool _loading;
  double _progressValue;

  TextEditingController _commentsController;
  TextEditingController _replyController;
  String comment;
  bool isSending = false;
  var comments = [];
  var storedepisodes = [];
  var episodeContent;

  var recommendations = [];

  void getRecommendations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getSimilarPodcasts?podcast_id=${episodeContent['podcast_id']}&user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          recommendations = jsonDecode(response.body)['podcasts'];
          print(recommendations);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void share1({var episodeObject}) async {
    // String sharableLink;
    await FlutterShare.share(
        title: '${episodeContent['podcast_name']}',
        text:
            "Hey There, I'm listening to ${episodeContent['name']} from ${episodeContent['podcast_name']} on Aureal, \n \nhere's the link for you https://aureal.one/episode/${episodeContent['id']}");
  }

  void getEpisode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/episode?episode_id=${widget.episodeId}&user_id=${prefs.getString('userId')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (this.mounted) {
          setState(() {
            episodeContent = jsonDecode(response.body)['episode'];
            print(episodeContent);
          });
        }
        await getColor(episodeContent['image']);
        setState(() {
          isLoading = false;
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    getRecommendations();
  }

  void getInitialComments(BuildContext context) {
    getComments();
  }

  void getHiveToken() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      hiveToken = prefs.getString('access_token');
      displayPicture = prefs.getString('displayPicture');
    });
  }

  Dio dio = Dio();

  postreq.Interceptor interceptor = postreq.Interceptor();

  TabController _tabController;

  var tags = [];

  void getTags() {
    setState(() {
      // tags = episodeContent['tags'];
    });
  }

  void getComments() async {
    String url =
        'https://api.aureal.one/public/getComments?episode_id=${widget.episodeId}';
    // print('loada');
    // print(widget.episodeObject.toString());

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          comments = jsonDecode(response.body)['comments'];
        });
        print(comments);
      }
    } catch (e) {
      print(e);
    }
  }

  bool isLoading = true;

  Episode _getFinalEpisode(taskId) => Episode(
      id: widget.episodeId,
      episodeId: widget.episodeId,
      taskId: taskId,
      name: episodeContent['name'],
      podcastName: episodeContent['podcast_name'],
      summary: episodeContent['summary'],
      image: episodeContent['image']);

  String getFileExtension(url) {
    if (episodeContent['url'].toString().contains('.mp4'))
      return '.mp4';
    else if (episodeContent['url'].toString().contains('.m4v'))
      return '.m4v';
    else if (episodeContent['url'].toString().contains('.flv'))
      return '.flv';
    else if (episodeContent['url'].toString().contains('.f4v'))
      return '.f4v';
    else if (episodeContent['url'].toString().contains('.ogv'))
      return '.ogv';
    else if (episodeContent['url'].toString().contains('.ogx'))
      return '.ogx';
    else if (episodeContent['url'].toString().contains('.wmv'))
      return '.wmv';
    else if (episodeContent['url'].toString().contains('.webm'))
      return '.wmv';
    else if (episodeContent['url'].toString().contains('.m4a')) return '.m4a';
  }

  void startDownload() async {
    setState(() {
      isDownloading = true;
    });

    final status = await Permission.storage.request();

    if (status.isGranted) {
      // var externalDir = await getExternalStorageDirectory();
      var externalDir = Platform.isAndroid == true
          ? (await getExternalStorageDirectory())
          : (await getApplicationDocumentsDirectory());
      print(externalDir.path);

      final bool r = await _mp.getEpisode(
          widget.episodeId); // tells if episode is already downloaded
      print(widget.episodeId);
      var fileextension = getFileExtension(episodeContent['url']);
      if (!r) {
        // final id = await FlutterDownloader.enqueue(
        //   url: episodeContent['url'],
        //   savedDir: externalDir.path,
        //   fileName: '${episodeContent['name'] + fileextension.toString()}',
        //   showNotification: true,
        //   openFileFromNotification: true,
        // );
        // print(id);
        // await _episodeBloc.addEpisode(_getFinalEpisode(id));
      }
    } else {
      print("Permission denied");
    }
  }

  SharedPreferences prefs;

  int progress = 0;

  ReceivePort _receivePort = ReceivePort();

  static downloadingCallback(id, status, progress) {
    ///Looking up for a send port
    SendPort sendPort = IsolateNameServer.lookupPortByName("downloading");

    ///ssending the data
    sendPort.send([id, status, progress]);
  }

  void getServerData() async {
    getEpisode();
    getHiveToken();
    getTags();
    getComments();
  }

  void init() async {
    setState(() {
      isLoading = true;
    });
    _tabController = TabController(length: 2, vsync: this);
    // TODO: implement initState
    _loading = false;
    _progressValue = 0.0;
    await getServerData();

    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, "downloading");

    ///Listening for the data is comming other isolataes
    _receivePort.listen((message) {
      setState(() {
        print('idhar');
        print(message.toString());
        progress = message[2];
      });

      print(progress);
    });

    // FlutterDownloader.registerCallback(downloadingCallback);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  bool isDownloading = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _tabController.dispose();
  }

  bool isUpvoteButtonLoading = false;
  void _updateProgress() {
    const oneSec = const Duration(seconds: 1);
    new Timer.periodic(oneSec, (Timer t) {
      setState(() {
        _progressValue += 0.2;
        // we "finish" downloading here
        if (_progressValue.toStringAsFixed(1) == '1.0') {
          _loading = false;
          t.cancel();
          _progressValue:
          0.0;
          return;
        }
      });
    });
  }

  var dominantColor = 0xff222222;

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

  void getColor(String url) async {
    getColorFromUrl(url).then((value) {
      setState(() {
        dominantColor = hexOfRGBA(value[0], value[1], value[2]);

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Color(dominantColor),
        ));
      });
    });
  }

  ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        // title: Text(
        //   "${episodeContent['name'] == null ? "" : episodeContent['name']}",
        //   textScaleFactor: 1.0,
        //   style: TextStyle(fontSize: SizeConfig.blockSizeHorizontal * 3),
        // ),
        backgroundColor:
            dominantColor == null ? Colors.transparent : Color(dominantColor),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.crop),
            onPressed: () {
              Navigator.push(context, CupertinoPageRoute(builder: (context) {
                return AudioEditor(
                  episodeObject: episodeContent,
                );
              }));
            },
          ),
          Platform.isAndroid == true
              ? GestureDetector(
                  onTap: () {
                    startDownload();
                    setState(() {
                      _loading = !_loading;
                      _updateProgress();
                    });
                  },
                  child: Container(
                      padding: EdgeInsets.all(15.0),
                      child: _loading
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                CircularProgressIndicator(
                                  value: _progressValue,
                                ),
                                Text('${(_progressValue * 100).round()}%'),
                              ],
                            )
                          : Icon(Icons.arrow_circle_down,
                              color: isDownloading == true
                                  ? Colors.blue
                                  : Colors.white)),
                )
              : SizedBox(
                  height: 0,
                  width: 0,
                ),
          IconButton(
            onPressed: () {
              share1(episodeObject: episodeObject.episodeObject);
            },
            icon: Icon(Icons.ios_share),
          )
        ],
      ),
      body: ModalProgressHUD(
        color: Colors.black,
        inAsyncCall: isLoading,
        child: isLoading == true
            ? Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.black,
              )
            : ListView(
                physics: BouncingScrollPhysics(),
                children: [
                  Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(dominantColor), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CachedNetworkImage(
                              imageUrl: episodeContent['image'] == null
                                  ? episodeContent['podcast_image']
                                  : episodeContent['image'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  height: MediaQuery.of(context).size.width / 2,
                                  width: MediaQuery.of(context).size.width / 2,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
                                );
                              },
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 80,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${episodeContent['name']}',
                                textScaleFactor: 1.0,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 4,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xffe8e8e8)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      CupertinoPageRoute(builder: (context) {
                                    return PodcastView(
                                        episodeContent['podcast_id']);
                                  }));
                                },
                                child: Text(
                                  '${episodeContent['podcast_name']}',
                                  textAlign: TextAlign.center,
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3,
                                      color:
                                          Color(0xffe8e8e8).withOpacity(0.5)),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${DurationCalculator(episodeContent['duration'])}',
                                  textAlign: TextAlign.center,
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3,
                                      color:
                                          Color(0xffe8e8e8).withOpacity(0.5)),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            episodeObject.episodeObject == null
                                ? GestureDetector(
                                    onTap: () {
                                      print(episodeContent['url']
                                          .toString()
                                          .contains('.mp4'));
                                      if (episodeContent['url']
                                                  .toString()
                                                  .contains('.mp4') ==
                                              true ||
                                          episodeContent['url']
                                                  .toString()
                                                  .contains('.m4v') ==
                                              true ||
                                          episodeContent['url']
                                                  .toString()
                                                  .contains('.flv') ==
                                              true ||
                                          episodeContent['url']
                                                  .toString()
                                                  .contains('.f4v') ==
                                              true ||
                                          episodeContent['url']
                                                  .toString()
                                                  .contains('.ogv') ==
                                              true ||
                                          episodeContent['url']
                                                  .toString()
                                                  .contains('.ogx') ==
                                              true ||
                                          episodeContent['url']
                                                  .toString()
                                                  .contains('.wmv') ==
                                              true ||
                                          episodeContent['url']
                                                  .toString()
                                                  .contains('.webm') ==
                                              true) {
                                        episodeObject.stop();
                                        Navigator.push(context,
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return PodcastVideoPlayer(
                                            episodeObject: episodeContent,
                                          );
                                        }));
                                      } else {
                                        if (episodeContent['url']
                                                .toString()
                                                .contains('.pdf') ==
                                            true) {
                                          // Navigator.push(context,
                                          //     CupertinoPageRoute(
                                          //         builder: (context) {
                                          //   return PDFviewer(
                                          //     episodeObject:
                                          //         widget.episodeObject,
                                          //   );
                                          // }));
                                        } else {
                                          episodeObject.stop();
                                          episodeObject.episodeObject =
                                              episodeContent;
                                          print(episodeObject.episodeObject
                                              .toString());
                                          episodeObject.play();
                                          Navigator.push(context,
                                              CupertinoPageRoute(
                                                  builder: (context) {
                                            return Player();
                                          }));
                                        }
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xff5d5da8),
                                              Color(0xff5bc3ef)
                                            ],
                                          )),
                                      width: double.infinity,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                            child: Padding(
                                          padding: const EdgeInsets.all(7.0),
                                          child: Text("GET STARTED"),
                                        )),
                                      ),
                                    ),
                                  )
                                : (episodeObject.episodeObject['id'] == null ||
                                        episodeObject.episodeObject['id'] ==
                                            episodeContent['id']
                                    ? (episodeObject
                                                .audioPlayer
                                                .realtimePlayingInfos
                                                .value
                                                .isPlaying ==
                                            true
                                        ? GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                episodeObject.pause();
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xff5d5da8),
                                                      Color(0xff5bc3ef)
                                                    ],
                                                  )),
                                              width: double.infinity,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                    child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(7.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // Padding(
                                                      //   padding: const EdgeInsets
                                                      //           .symmetric(
                                                      //       horizontal:
                                                      //           5),
                                                      //   child: Icon(
                                                      //       Icons
                                                      //           .pause),
                                                      // ),
                                                      Text("PAUSE"),
                                                    ],
                                                  ),
                                                )),
                                              ),
                                            ),
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                episodeObject.resume();
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xff5d5da8),
                                                      Color(0xff5bc3ef)
                                                    ],
                                                  )),
                                              width: double.infinity,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Center(
                                                    child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(7.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      // Padding(
                                                      //   padding: const EdgeInsets
                                                      //           .symmetric(
                                                      //       horizontal:
                                                      //           5),
                                                      //   child: Icon(Icons
                                                      //       .play_arrow_rounded),
                                                      // ),
                                                      Text("RESUME"),
                                                    ],
                                                  ),
                                                )),
                                              ),
                                            ),
                                          ))
                                    : GestureDetector(
                                        onTap: () {
                                          print(episodeContent['url']
                                              .toString()
                                              .contains('.mp4'));
                                          if (episodeContent['url']
                                                      .toString()
                                                      .contains('.mp4') ==
                                                  true ||
                                              episodeContent['url']
                                                      .toString()
                                                      .contains('.m4v') ==
                                                  true ||
                                              episodeContent['url']
                                                      .toString()
                                                      .contains('.flv') ==
                                                  true ||
                                              episodeContent['url']
                                                      .toString()
                                                      .contains('.f4v') ==
                                                  true ||
                                              episodeContent['url']
                                                      .toString()
                                                      .contains('.ogv') ==
                                                  true ||
                                              episodeContent['url']
                                                      .toString()
                                                      .contains('.ogx') ==
                                                  true ||
                                              episodeContent['url']
                                                      .toString()
                                                      .contains('.wmv') ==
                                                  true ||
                                              episodeContent['url']
                                                      .toString()
                                                      .contains('.webm') ==
                                                  true) {
                                            episodeObject.stop();
                                            Navigator.push(context,
                                                CupertinoPageRoute(
                                                    builder: (context) {
                                              return PodcastVideoPlayer(
                                                episodeObject: episodeContent,
                                              );
                                            }));
                                          } else {
                                            if (episodeContent['url']
                                                    .toString()
                                                    .contains('.pdf') ==
                                                true) {
                                              // Navigator.push(context,
                                              //     CupertinoPageRoute(
                                              //         builder: (context) {
                                              //   return PDFviewer(
                                              //     episodeObject:
                                              //         widget.episodeObject,
                                              //   );
                                              // }));
                                            } else {
                                              episodeObject.stop();
                                              episodeObject.episodeObject =
                                                  episodeContent;
                                              print(episodeObject.episodeObject
                                                  .toString());
                                              episodeObject.play();
                                              showBarModalBottomSheet(
                                                  context: context,
                                                  builder: (context) {
                                                    return Player();
                                                  });
                                            }
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xff5d5da8),
                                                  Color(0xff5bc3ef)
                                                ],
                                              )),
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Center(
                                                child: Padding(
                                              padding:
                                                  const EdgeInsets.all(7.0),
                                              child: Text("GET STARTED"),
                                            )),
                                          ),
                                        ),
                                      )),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 30,
                            ),
                            episodeContent['permlink'] == null
                                ? SizedBox()
                                : InkWell(
                                    onTap: () async {
                                      if (prefs.getString('HiveUserName') !=
                                          null) {
                                        setState(() {
                                          isUpvoteButtonLoading = true;
                                        });
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: UpvoteEpisode(
                                                      permlink: episodeContent[
                                                          'permlink'],
                                                      episode_id:
                                                          episodeContent[
                                                              'id']));
                                            }).then((value) async {
                                          print(value);
                                        });
                                        await upvoteEpisode(
                                            permlink:
                                                episodeContent['permlink'],
                                            episode_id: episodeContent['id']);
                                        setState(() {
                                          episodeContent['ifVoted'] =
                                              !episodeContent['ifVoted'];
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
                                        decoration: episodeContent['ifVoted'] ==
                                                true
                                            ? BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Color(dominantColor),
                                                      Color(0xff5d5da8)
                                                    ]),
                                                borderRadius:
                                                    BorderRadius.circular(8))
                                            : BoxDecoration(
                                                border: Border.all(
                                                    color: kSecondaryColor),
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                      FontAwesomeIcons
                                                          .chevronCircleUp,
                                                      size: 15,
                                                    ),
                                              episodeContent['ifVoted'] == false
                                                  ? Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 10),
                                                      child: Text("UPVOTE"),
                                                    )
                                                  : Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      8),
                                                          child: Text(
                                                            '${episodeContent['votes']}',
                                                            textScaleFactor:
                                                                1.0,
                                                            style: TextStyle(
                                                                //        color: Color(
                                                                // 0xffe8e8e8)
                                                                ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  right: 4),
                                                          child: Text(
                                                            '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
                                                            textScaleFactor:
                                                                1.0,
                                                          ),
                                                        )
                                                      ],
                                                    )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            episodeContent['permlink'] == null
                                ? SizedBox()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Community",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Color(0xff222222),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: ListTile(
                                              onTap: () {
                                                Navigator.push(context,
                                                    CupertinoPageRoute(
                                                        builder: (context) {
                                                  return Comments(
                                                    episodeObject:
                                                        episodeContent,
                                                  );
                                                }));
                                              },
                                              title:
                                                  Text("Join the conversation"),
                                              trailing:
                                                  Icon(Icons.arrow_forward_ios),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            episodeContent['summary'] == null
                                ? SizedBox()
                                : ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      "About",
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  4,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      // child: htmlMatch.hasMatch(
                                      //             episodeContent['summary']) ==
                                      //         true
                                      //     ? Text(
                                      //         (parse(episodeContent['summary'])
                                      //             .body
                                      //             .text))
                                      //     : Text(
                                      //         '${episodeContent['summary'] == null ? '' : episodeContent['summary']}'),
                                      child: htmlMatch.hasMatch(
                                                  episodeContent['summary']) ==
                                              true
                                          ? Linkable(
                                              text:
                                                  '${(parse(episodeContent['summary']).body.text)}',
                                              textScaleFactor: 1.0,
                                              textColor: Color(0xffe8e8e8),
                                              style: TextStyle(
                                                fontSize: SizeConfig
                                                        .blockSizeHorizontal *
                                                    3,
                                              ),
                                            )
                                          : Linkable(
                                              text:
                                                  "${episodeContent['summary']}",
                                              textScaleFactor: 1.0,
                                              textColor: Color(0xffe8e8e8),
                                              style: TextStyle(
                                                fontSize: SizeConfig
                                                        .blockSizeHorizontal *
                                                    3,
                                              ),
                                            ),
                                    ),
                                  ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: ListTile(
                                onTap: () {
                                  if (episodeContent['author_hiveusername'] !=
                                      null) {
                                    Navigator.push(context,
                                        CupertinoPageRoute(builder: (context) {
                                      return PublicProfile(
                                        userId: episodeContent['user_id'],
                                      );
                                    }));
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                      episodeContent['author_image'],
                                      imageRenderMethodForWeb:
                                          ImageRenderMethodForWeb.HtmlImage),
                                ),
                                title: Text("${episodeContent['author']}"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class UpvoteWidget extends StatefulWidget {
  @override
  _UpvoteWidgetState createState() => _UpvoteWidgetState();
}

class _UpvoteWidgetState extends State<UpvoteWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.blue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }
}
