import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:auditory/DatabaseFunctions/EpisodesBloc.dart';
import 'package:auditory/DatabaseFunctions/EpisodesProvider.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/models/Episode.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
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
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        'https://api.aureal.one/public/getSimilarPodcasts?podcast_id=${episodeContent['episode']['podcast_id']}&user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          recommendations = jsonDecode(response.body)['podcasts'];
        });
      }
    } catch (e) {
      print(e);
    }
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
          });
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    await getColor(episodeContent['image']);
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
        final id = await FlutterDownloader.enqueue(
          url: episodeContent['url'],
          savedDir: externalDir.path,
          fileName: '${episodeContent['name'] + fileextension.toString()}',
          showNotification: true,
          openFileFromNotification: true,
        );
        print(id);
        await _episodeBloc.addEpisode(_getFinalEpisode(id));
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

  @override
  void initState() {
    super.initState();
    getEpisode();
    _tabController = TabController(length: 2, vsync: this);
    // TODO: implement initState
    _loading = false;
    _progressValue = 0.0;
    getHiveToken();
    getTags();
    getComments();
    getRecommendations();

    // if (episodeContent['likes'] == true) {
    //   setState(() {
    //     likeStatus = Like.liked;
    //   });
    // } else {
    //   setState(() {
    //     likeStatus = Like.unliked;
    //   });
    // }
    print(comments.toString());
    // print(episodeContent['summary']);

//    print(htmlMatch.hasMatch(widget.episodeObject['summary']));

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

    FlutterDownloader.registerCallback(downloadingCallback);
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

  var dominantColor;

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
        print(dominantColor.toString());

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Color(dominantColor),
        ));
      });
    });
  }

  ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final currentlyPlaying = Provider.of<PlayerChange>(context);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);

    SizeConfig().init(context);
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
            return <Widget>[
              SliverAppBar(
                pinned: true,
                //    backgroundColor: kPrimaryColor,
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
                    onPressed: () {},
                    icon: Icon(
                      Icons.share,
                    ),
                  )
                ],
                expandedHeight: MediaQuery.of(context).size.height / 1.45,
                //       flexibleSpace: FlexibleSpaceBar(
                //         background:
                //             Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
                //                 Widget>[
                //           Container(
                //               decoration: BoxDecoration(
                //                   gradient: LinearGradient(colors: [
                //                     Color(dominantColor == null ? 0xff3a3a3a : dominantColor),
                //                     Colors.transparent
                //                   ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                //               height: MediaQuery.of(context).size.height * 0.3,
                //               child: Stack(children: <Widget>[
                //                 Positioned(
                //                   bottom: 0,
                //                   left: 120,
                //                   right: 0,
                //                   child: Container(
                //                     child: Row(
                //                       children: <Widget>[
                //                         Container(
                //                           decoration: BoxDecoration(
                //                             boxShadow: [
                //                               BoxShadow(
                //                                 offset: Offset(0, 10),
                //                                 blurRadius: 50,
                //
                //                               ),
                //                             ],
                //                             borderRadius: BorderRadius.circular(30),
                //                           ),
                //                           width: MediaQuery.of(context).size.width / 2.5,
                //                           height: MediaQuery.of(context).size.width / 2.5,
                //                           child: CachedNetworkImage(
                //                             imageBuilder: (context, imageProvider) {
                //                               return Container(
                //                                 decoration: BoxDecoration(
                //                                   borderRadius: BorderRadius.circular(10),
                //                                   image: DecorationImage(
                //                                       image: imageProvider,
                //                                       fit: BoxFit.cover),
                //                                 ),
                //                               );
                //                             },
                //                             imageUrl: episodeContent['image'] != null
                //                                 ? episodeContent['image']
                //                                 : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                //                           ),
                //                         ),
                //                       ],
                //                     ),
                //                   ),
                //                 ),
                //               ])),
                //           SizedBox(
                //             height: 10,
                //           ),
                //           Padding(
                //             padding: const EdgeInsets.all(5.0),
                //             child: Center(
                //               child: Text(
                //                 episodeContent['author'],
                //                 textAlign: TextAlign.center,
                //                 maxLines: 2,
                //                 textScaleFactor: 1.0,
                //                 style: TextStyle(
                //                     fontSize: SizeConfig.safeBlockHorizontal * 4,
                //                     fontWeight: FontWeight.bold),
                //               ),
                //             ),
                //           ),
                //           Padding(
                //             padding: const EdgeInsets.all(5.0),
                //             child: Center(
                //               child: Text(episodeContent['name'],
                //                   textAlign: TextAlign.center,
                //                   maxLines: 2,
                //                   textScaleFactor: 1.0,
                //                   style: TextStyle(
                //                     fontSize: SizeConfig.safeBlockHorizontal * 3,
                //                   )),
                //             ),
                //           ),
                //           SizedBox(
                //             height: 20,
                //           ),
                //           Padding(
                //             padding: const EdgeInsets.all(5.0),
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //               crossAxisAlignment: CrossAxisAlignment.center,
                //               children: [
                //                 Column(
                //                   children: [
                //                     Padding(
                //                       padding: const EdgeInsets.only(bottom: 10),
                //                       child: Text("Upvote"),
                //                     ),
                //                     episodeContent['permlink'] == null ||
                //                             episodeContent['votes'] == null
                //                         ? (episodeContent['user_id'] ==
                //                                 prefs.getString('userId')
                //                             ? InkWell(
                //                                 onTap: () async {
                //                                   await publishManually(
                //                                       episodeContent['id']);
                //                                 },
                //                                 child: Container(
                //                                   decoration: BoxDecoration(
                //                                       border: Border.all(
                //                                         color: Color(0xff171b27),
                //                                       ),
                //                                       borderRadius:
                //                                           BorderRadius.circular(20),
                //                                       gradient: LinearGradient(colors: [
                //                                         Color(0xff5bc3ef),
                //                                         Color(0xff5d5da8)
                //                                       ])),
                //                                   child: Padding(
                //                                     padding: const EdgeInsets.symmetric(
                //                                         horizontal: 20, vertical: 5),
                //                                     child: Text(
                //                                       'Publish',
                //                                       textScaleFactor: mediaQueryData
                //                                           .textScaleFactor
                //                                           .clamp(0.5, 1)
                //                                           .toDouble(),
                //                                       style: TextStyle(
                //                                           // color:
                //                                           //     Color(0xffe8e8e8),
                //                                           fontSize: SizeConfig
                //                                                   .safeBlockHorizontal *
                //                                               3.5),
                //                                     ),
                //                                   ),
                //                                 ),
                //                               )
                //                             : SizedBox(
                //                                 width: 0,
                //                               ))
                //                         : InkWell(
                //                             onTap: () async {
                //                               if (prefs.getString('HiveUserName') != null) {
                //                                 setState(() {
                //                                   isUpvoteButtonLoading = true;
                //                                 });
                //                                 showDialog(
                //                                     context: context,
                //                                     builder: (context) {
                //                                       return Dialog(
                //                                           backgroundColor:
                //                                               Colors.transparent,
                //                                           child: UpvoteEpisode(
                //                                               permlink: episodeContent[
                //                                                   'permlink'],
                //                                               episode_id:
                //                                                   episodeContent['id']));
                //                                     }).then((value) async {
                //                                   print(value);
                //                                 });
                //                                 setState(() {
                //                                   episodeContent['ifVoted'] =
                //                                       !episodeContent['ifVoted'];
                //                                 });
                //                                 setState(() {
                //                                   isUpvoteButtonLoading = false;
                //                                 });
                //                               } else {
                //                                 showBarModalBottomSheet(
                //                                     context: context,
                //                                     builder: (context) {
                //                                       return HiveDetails();
                //                                     });
                //                               }
                //                             },
                //                             child: Container(
                //                               decoration: episodeContent['ifVoted'] == true
                //                                   ? BoxDecoration(
                //                                   gradient: LinearGradient(colors: [
                //                                     Color(dominantColor == null ? 0xff3a3a3a : dominantColor),
                //                                     Colors.transparent
                //
                //                                       ]),
                //                                       borderRadius:
                //                                           BorderRadius.circular(30))
                //                                   : BoxDecoration(
                //                                       border: Border.all(
                //                                           color: Color(0xff171b27)),
                //                                       // color: kSecondaryColor,
                //                                       borderRadius:
                //                                           BorderRadius.circular(30),
                //                                     ),
                //                               child: Padding(
                //                                 padding: const EdgeInsets.all(5.0),
                //                                 child: Row(
                //                                   children: [
                //                                     Padding(
                //                                       padding: const EdgeInsets.symmetric(
                //                                           horizontal: 8),
                //                                       child: Text(
                //                                         '${episodeContent['votes']}',
                //                                         textScaleFactor: mediaQueryData
                //                                             .textScaleFactor
                //                                             .clamp(0.5, 1)
                //                                             .toDouble(),
                //                                         style: TextStyle(
                //                                             // color: Color(
                //                                             //     0xffe8e8e8)
                //                                             ),
                //                                       ),
                //                                     ),
                //                                     Padding(
                //                                       padding:
                //                                           const EdgeInsets.only(right: 4),
                //                                       child: Text(
                //                                         '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
                //                                         textScaleFactor: mediaQueryData
                //                                             .textScaleFactor
                //                                             .clamp(0.5, 1)
                //                                             .toDouble(),
                //                                         style: TextStyle(
                //                                             // color: Color(
                //                                             //     0xffe8e8e8)
                //                                             ),
                //                                       ),
                //                                     )
                //                                   ],
                //                                 ),
                //                               ),
                //                             ),
                //                           ),
                //                   ],
                //                 ),
                //                 Container(
                //                   height: 20,
                //                   width: 3,
                //                   color: Colors.white,
                //                 ),
                //                 Column(
                //                   children: [
                //                     Padding(
                //                       padding: const EdgeInsets.only(bottom: 10),
                //                       child: Text("Duration"),
                //                     ),
                //                     Text(
                //                       '${DurationCalculator(episodeContent['duration']) == "Some Issue" ? '' : DurationCalculator(episodeContent['duration'])}',
                //                     ),
                //                   ],
                //                 ),
                //                 Container(
                //                   height: 20,
                //                   width: 3,
                //                   color: Colors.white,
                //                 ),
                //                 Column(
                //                   children: [
                //                     Padding(
                //                       padding: const EdgeInsets.only(bottom: 10),
                //                       child: Text("Earning"),
                //                     ),
                //                     Text(
                //                       '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
                //                       textScaleFactor: 1.0,
                //                     ),
                //                   ],
                //                 ),
                //               ],
                //             ),
                //           ),
                //           SizedBox(
                //             height: 20,
                //           ),
                //           episodeContent == null
                //               ? Container()
                //               : Row(
                //                   mainAxisAlignment: MainAxisAlignment.center,
                //                   children: <Widget>[
                //                       Row(
                //                         children: [
                //                           GestureDetector(
                //                               onTap: () {
                //                                 print(episodeContent['url']
                //                                     .toString()
                //                                     .contains('.mp4'));
                //                                 if (episodeContent['url']
                //                                             .toString()
                //                                             .contains('.mp4') ==
                //                                         true ||
                //                                     episodeContent['url']
                //                                             .toString()
                //                                             .contains('.m4v') ==
                //                                         true ||
                //                                     episodeContent['url']
                //                                             .toString()
                //                                             .contains('.flv') ==
                //                                         true ||
                //                                     episodeContent['url']
                //                                             .toString()
                //                                             .contains('.f4v') ==
                //                                         true ||
                //                                     episodeContent['url']
                //                                             .toString()
                //                                             .contains('.ogv') ==
                //                                         true ||
                //                                     episodeContent['url']
                //                                             .toString()
                //                                             .contains('.ogx') ==
                //                                         true ||
                //                                     episodeContent['url']
                //                                             .toString()
                //                                             .contains('.wmv') ==
                //                                         true ||
                //                                     episodeContent['url']
                //                                             .toString()
                //                                             .contains('.webm') ==
                //                                         true) {
                //                                   currentlyPlaying.stop();
                //                                   Navigator.push(context,
                //                                       MaterialPageRoute(builder: (context) {
                //                                     return PodcastVideoPlayer(
                //                                       episodeObject: episodeContent,
                //                                     );
                //                                   }));
                //                                 } else {
                //                                   if (episodeContent['url']
                //                                           .toString()
                //                                           .contains('.pdf') ==
                //                                       true) {
                //                                     // Navigator.push(context,
                //                                     //     MaterialPageRoute(
                //                                     //         builder: (context) {
                //                                     //   return PDFviewer(
                //                                     //     episodeObject:
                //                                     //         widget.episodeObject,
                //                                     //   );
                //                                     // }));
                //                                   } else {
                //                                     currentlyPlaying.stop();
                //                                     currentlyPlaying.episodeObject =
                //                                         episodeContent;
                //                                     print(currentlyPlaying.episodeObject
                //                                         .toString());
                //                                     currentlyPlaying.play();
                //                                     showBarModalBottomSheet(
                //                                         context: context,
                //                                         builder: (context) {
                //                                           return Player();
                //                                         });
                //                                   }
                //                                 }
                //                               },
                //                               child: Center(
                //                                 child: Container(
                //                                   height: 40,
                //                                     width: 300,
                //                                     decoration: BoxDecoration(
                //                                         borderRadius:
                //                                             BorderRadius.circular(15),
                //                                             color: Colors.blue,),
                //                                     child: Center(
                //                                       child: Padding(
                //                                         padding: const EdgeInsets.symmetric(
                //                                             horizontal: 20, vertical: 5),
                //                                         child: Text("Play"),
                //                                       ),
                //                                     )),
                //                               ))
                //                         ],
                //                       ),
                //                     ]),
                //         ]
                // ),
                //       ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [
                                    Color(dominantColor),
                                    Colors.transparent
                                  ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter)),
                            ),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: episodeContent['image'] == null
                                    ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                    : episodeContent['image'],
                                imageBuilder: (context, imageProvider) {
                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.width / 2,
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover)),
                                  );
                                },
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 40,
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
                                    textAlign: TextAlign.center,
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3,
                                        color:
                                            Color(0xffe8e8e8).withOpacity(0.5)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.arrow_drop_down_circle,
                                      size: SizeConfig.safeBlockHorizontal * 1,
                                      color: Color(0xffe8e8e8).withOpacity(0.5),
                                    ),
                                  ),
                                  Text(
                                    '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
                                    textAlign: TextAlign.center,
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3,
                                        color:
                                            Color(0xffe8e8e8).withOpacity(0.5)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.arrow_drop_down_circle,
                                      size: SizeConfig.safeBlockHorizontal * 1,
                                      color: Color(0xffe8e8e8).withOpacity(0.5),
                                    ),
                                  ),
                                  Text(
                                    '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
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
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(vertical: 10),
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.center,
                              //     children: [
                              //       Container(
                              //         decoration: BoxDecoration(
                              //             borderRadius: BorderRadius.circular(20),
                              //             border: Border.all(color: Color(0xffe8e8e8))),
                              //         child: Padding(
                              //           padding: const EdgeInsets.symmetric(
                              //               horizontal: 5, vertical: 5),
                              //           child: Row(
                              //             mainAxisSize: MainAxisSize.min,
                              //             children: [
                              //               Icon(
                              //                 Icons.play_circle_outline,
                              //                 size: 15,
                              //               ),
                              //               SizedBox(
                              //                 width: 5,
                              //               ),
                              //               Text("Play"),
                              //               SizedBox(
                              //                 width: 5,
                              //               )
                              //             ],
                              //           ),
                              //         ),
                              //       ),
                              //       SizedBox(width: 10,),
                              //       Container(
                              //         decoration: BoxDecoration(
                              //             borderRadius: BorderRadius.circular(20),
                              //             border: Border.all(color: Color(0xffe8e8e8))),
                              //         child: Padding(
                              //           padding: const EdgeInsets.symmetric(
                              //               horizontal: 5, vertical: 5),
                              //           child: Row(
                              //             mainAxisSize: MainAxisSize.min,
                              //             children: [
                              //               Icon(
                              //                 Icons.play_circle_outline,
                              //                 size: 15,
                              //               ),
                              //               SizedBox(
                              //                 width: 5,
                              //               ),
                              //               Text("Play"),
                              //               SizedBox(
                              //                 width: 5,
                              //               )
                              //             ],
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              SizedBox(
                                height: 20,
                              ),
                              episodeContent == null
                                  ? Container()
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
                                          currentlyPlaying.stop();
                                          Navigator.push(context,
                                              MaterialPageRoute(
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
                                            //     MaterialPageRoute(
                                            //         builder: (context) {
                                            //   return PDFviewer(
                                            //     episodeObject:
                                            //         widget.episodeObject,
                                            //   );
                                            // }));
                                          } else {
                                            currentlyPlaying.stop();
                                            currentlyPlaying.episodeObject =
                                                episodeContent;
                                            print(currentlyPlaying.episodeObject
                                                .toString());
                                            currentlyPlaying.play();
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
                                            padding: const EdgeInsets.all(7.0),
                                            child: Text("PLAY"),
                                          )),
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
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(32),
                  child: Container(
                    color: kPrimaryColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xff222222),
                        ),
                        // width: 300,
                        //  color: kPrimaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: TabBar(
                            // isScrollable: true,
                            controller: _tabController,

                            // give the indicator a decoration (color and border radius)
                            indicator: BoxDecoration(
                              boxShadow: [
                                new BoxShadow(
                                  color: Colors.black54.withOpacity(0.2),
                                  blurRadius: 5.0,
                                ),
                              ],
                              color: themeProvider.isLightTheme == true
                                  ? Colors.white
                                  : kPrimaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelColor: Colors.white,

                            tabs: [
                              // first tab [you can add an icon using the icon property]
                              Tab(
                                text: 'Overview',
                              ),

                              // second tab [you can add an icon using the icon property]
                              Tab(
                                text: 'Comment',
                              ),
                            ],
                          ),
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
              Container(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "About",
                                textScaleFactor: 1.0,
                                style: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 4,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                child: Text('${episodeContent['summary']}'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: ListTile(
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
                            Text(
                              "Community",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                  fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Color(0xff222222),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    title: Text("Join the conversation"),
                                    trailing: Icon(Icons.arrow_forward_ios),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                child: ListView(
                  children: [
                    for (var v in recommendations)
                      Container(
                        color: Colors.blue,
                        child: ListTile(
                          title: Text('${v['name']}'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//
// class Comment extends StatefulWidget {
//   // const Comment({Key? key}) : super(key: key);
//
//   @override
//   _CommentState createState() => _CommentState();
// }
//
// class _CommentState extends State<Comment> {
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }

// body: episodeContent == null
// ? Shimmer.fromColors(
// baseColor: Color(0xff3a3a3a),
// highlightColor: kPrimaryColor,
// child: Container(
// width: double.infinity,
// height: double.infinity,
// color: kSecondaryColor,
// ))
// : Container(
// decoration:
// BoxDecoration(borderRadius: BorderRadius.circular(30)),
// child: TabBarView(
// controller: _tabController,
// children: <Widget>[
// ListView(
// children: [
// episodeContent['summary'] == null
// ? Container()
//     : Container(
// child: Padding(
// padding: const EdgeInsets.symmetric(
// vertical: 10, horizontal: 15),
// child: htmlMatch.hasMatch(
// episodeContent['summary']) ==
// true
// ? Text(
// parse(episodeContent['summary'])
// .body
//     .text,
// textScaleFactor: mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
// .toDouble(),
// style: TextStyle(
// // color: Colors.white,
// fontSize: SizeConfig
//     .safeBlockHorizontal *
// 3.8),
// )
// : Text(
// '${episodeContent['summary']}',
// textScaleFactor: mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
// .toDouble(),
// style: TextStyle(
// //      color: Colors.white,
// fontSize: SizeConfig
//     .safeBlockHorizontal *
// 3.8),
// ),
// ),
// ),
// SizedBox(
// height: 0,
// ),
// ],
// ),
// Container(
// child: Stack(
// children: <Widget>[
// ListView.builder(
// itemBuilder: (BuildContext context, int index) {
// return Padding(
// padding: const EdgeInsets.symmetric(
// horizontal: 10, vertical: 15),
// child: Container(
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: <Widget>[
// ListTile(
// leading: CircleAvatar(
// backgroundImage:
// CachedNetworkImageProvider(comments[
// index]['user_image'] ==
// null
// ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
//     : comments[index]
// ['user_image']),
// ),
// title: Text(
// '${comments[index]['author']}',
// textScaleFactor: mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
//     .toDouble(),
// //     style: TextStyle(color: Color(0xffe8e8e8)),
// ),
// subtitle: Column(
// crossAxisAlignment:
// CrossAxisAlignment.start,
// children: [
// Padding(
// padding: const EdgeInsets.only(
// bottom: 5),
// child: Text(
// "${comments[index]['text']}",
// textScaleFactor: mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
//     .toDouble(),
// // style:
// //     TextStyle(color: Color(0xffe8e8e8)),
// ),
// ),
// Row(
// children: [
// GestureDetector(
// onTap: () {},
// child: Text(
// "Reply",
// textScaleFactor:
// mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
//     .toDouble(),
// // style: TextStyle(color: Colors.white),
// ),
// )
// ],
// )
// ],
// ),
// trailing: IconButton(
// onPressed: () {
// showDialog(
// context: context,
// builder: (context) {
// return Dialog(
// backgroundColor:
// Colors.transparent,
// child: UpvoteComment(
// comment_id:
// comments[index]['id']
//     .toString(),
// ));
// }).then((value) async {
// print(value);
// });
// },
// icon: Icon(
// FontAwesomeIcons.chevronCircleUp,
// //  color: Colors.white,
// ),
// ),
// isThreeLine: true,
// ),
// comments[index]['comments'] == null
// // comments[index].contains('comments') == false
// ? SizedBox(
// height: 0,
// )
//     : ExpansionTile(
// //  backgroundColor: Colors.transparent,
// trailing: SizedBox(
// width: 0,
// ),
// title: Align(
// alignment: Alignment.centerLeft,
// child: Text(
// "View replies",
// textScaleFactor: mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
//     .toDouble(),
// style: TextStyle(
// fontSize: SizeConfig
//     .safeBlockHorizontal *
// 3,
// //  color: Colors.grey,
// ),
// ),
// ),
// children: <Widget>[
// for (var v in comments[index]
// ['comments'])
// ListTile(
// leading: CircleAvatar(
// backgroundImage:
// CachedNetworkImageProvider(
// v['user_image']),
// ),
// title: Text(
// '${v['author']}',
// textScaleFactor:
// mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
//     .toDouble(),
// ),
// subtitle: Column(
// crossAxisAlignment:
// CrossAxisAlignment
//     .start,
// children: [
// Padding(
// padding:
// const EdgeInsets
//     .only(
// bottom: 5),
// child: Text(
// "${v['text']}",
// textScaleFactor:
// mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
//     .toDouble(),
// style: TextStyle(),
// ),
// ),
// Row(
// children: [
// GestureDetector(
// onTap: () {},
// child: Text(
// "Reply",
// textScaleFactor:
// mediaQueryData
//     .textScaleFactor
//     .clamp(
// 0.5,
// 1)
//     .toDouble(),
// style:
// TextStyle(),
// ),
// )
// ],
// )
// ],
// ),
// trailing: IconButton(
// onPressed: () {
// showDialog(
// context: context,
// builder: (context) {
// return Dialog(
// backgroundColor:
// Colors
//     .transparent,
// child:
// UpvoteComment(
// comment_id: v[
// 'id']
//     .toString(),
// ));
// }).then((value) async {
// print(value);
// });
// },
// icon: Icon(
// FontAwesomeIcons
//     .chevronCircleUp,
// ),
// ),
// isThreeLine: true,
// ),
// ],
// )
// ],
// )),
// );
// },
// itemCount: comments.length,
// ),
// Column(
// mainAxisAlignment: MainAxisAlignment.end,
// children: <Widget>[
// FlatButton(
// //    color: Colors.blueAccent,
// onPressed: () {
// Navigator.push(context, MaterialPageRoute(
// builder: (BuildContext context) {
// return Comments(
// episodeObject: episodeContent,
// );
// })).then((value) {
// getTags();
// getComments();
// if (episodeContent['likes'] == true) {
// setState(() {
// likeStatus = Like.liked;
// });
// } else {
// setState(() {
// likeStatus = Like.unliked;
// });
// }
// });
// },
// child: Container(
// child: Row(
// children: <Widget>[
// Padding(
// padding: const EdgeInsets.symmetric(
// vertical: 10),
// child: Row(
// children: <Widget>[
// CircleAvatar(
// backgroundImage: prefs.getString(
// 'displayPicture') ==
// null
// ? AssetImage(
// 'assets/images/Thumbnail.png')
// : NetworkImage(
// prefs.getString(
// 'displayPicture')),
// ),
// SizedBox(
// width: 10,
// ),
// Text(
// 'Add a comment...',
// textScaleFactor: mediaQueryData
//     .textScaleFactor
//     .clamp(0.5, 1)
// .toDouble(),
// )
// ],
// ),
// )
// ],
// ),
// ),
// ),
// ],
// ),
// ],
// ),
// )
// ],
// ),
// ),
//
// );
// }

//   // SliverList(delegate: SliverChildBuilderDelegate(
//   //     // ignore: missing_return
//   //     (BuildContext context, int index)
//   //     {if (index == 0)
//   //       return Padding(
//   //         padding: const EdgeInsets.only(left: 50,right: 50),
//   //         child: Container(
//   //
//   //           decoration: BoxDecoration(
//   //             color: Colors.blueGrey,
//   //             borderRadius: BorderRadius.circular(15)
//   //           ),
//   //           child: DefaultTabController(
//   //             length: 2,
//   //             initialIndex: 0,
//   //             child: Container(
//   //               decoration: BoxDecoration(
//   //             //    color: kLightGrey,
//   //                 borderRadius: BorderRadius.all(
//   //                   Radius.circular(15),
//   //                 ),
//   //               ),
//   //               child: TabBar(
//   //                 tabs: <Tab>[
//   //                   Tab(text: "About"),
//   //                   Tab(text: "Comments")
//   //                 ],
//   //                 unselectedLabelColor: Colors.white,
//   //                 labelColor: Colors.white,
//   //                 unselectedLabelStyle: TextStyle(
//   //                   fontWeight: FontWeight.bold,
//   //                 //  fontFamily: kRobotoBold,
//   //                 ),
//   //                 labelStyle: TextStyle(
//   //                   fontWeight: FontWeight.bold,
//   //                   //fontFamily: kRobotoBold,
//   //                 ),
//   //                 indicatorSize: TabBarIndicatorSize.tab,
//   //                 indicator: BoxDecoration(
//   //                   shape: BoxShape.rectangle,
//   //                   borderRadius: BorderRadius.circular(15),
//   //                   color: Colors.grey,
//   //                 ),
//   //               ),
//   //             ),
//   //
//   //           ),
//   //         ),
//   //       );
//   //
//   //     }
//   // )
//  // )
//
//   ]),
//           bottom: TabBar(
//             controller: _tabController,
//             isScrollable: true,
//             //  labelColor: kActiveColor,
//             // unselectedLabelColor: Colors.white,
//             labelStyle: TextStyle(
//                 fontSize: SizeConfig.safeBlockHorizontal * 3.4),
//             tabs: <Widget>[
//               Tab(
//                   child: Text(
//                 "About",
//                 textScaleFactor: mediaQueryData.textScaleFactor
//                     .clamp(0.5, 1)
//                     .toDouble(),
//               )),
//               Tab(
//                   child: Text(
//                 "Comments",
//                 textScaleFactor: mediaQueryData.textScaleFactor
//                     .clamp(0.5, 1)
//                     .toDouble(),
//               )),
//             ],
//           ),
// )];
//     },

//                 Container(
//                   child: Container(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 15),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: <Widget>[
//                           episodeContent == null
//                               ? Shimmer.fromColors(
//                                   baseColor: Color(0xff3a3a3a),
//                                   highlightColor: kPrimaryColor,
//                                   child: Container(
//                                     height: 80,
//                                     width: 80,
//                                     color: kSecondaryColor,
//                                   ))
//                               : Container(
//                                   height: 90,
//                                   width: 80,
//                                   child: CachedNetworkImage(
//                                     imageBuilder: (context, imageProvider) {
//                                       return Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius:
//                                               BorderRadius.circular(10),
//                                           image: DecorationImage(
//                                               image: imageProvider,
//                                               fit: BoxFit.cover),
//                                         ),
//                                         height:
//                                             MediaQuery.of(context).size.width,
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                       );
//                                     },
//                                     imageUrl: episodeContent['image'] != null
//                                         ? episodeContent['image']
//                                         : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
//                                     fit: BoxFit.cover,
//                                     // memCacheHeight:
//                                     //     MediaQuery.of(
//                                     //             context)
//                                     //         .size
//                                     //         .width
//                                     //         .ceil(),
//                                     memCacheHeight: MediaQuery.of(context)
//                                         .size
//                                         .height
//                                         .floor(),
//
//                                     errorWidget: (context, url, error) =>
//                                         Icon(Icons.error),
//                                   ),
//                                   //   child: FadeInImage.assetNetwork(
//                                   //       placeholder:
//                                   //           'assets/images/Thumbnail.png',
//                                   //       image: episodeContent['image'] != null
//                                   //           ? episodeContent['image']
//                                   //           : 'assets/images/Thumbnail.png'),
//                                   //   decoration: BoxDecoration(
//                                   //       //   color: Colors.white,
//                                   //       borderRadius: BorderRadius.circular(5)),
//                                 ),
//                           SizedBox(
//                             height: 25,
//                           ),
//                           episodeContent == null
//                               ? Shimmer.fromColors(
//                                   baseColor: Color(0xff3a3a3a),
//                                   highlightColor: kPrimaryColor,
//                                   child: Container(
//                                     width: double.infinity,
//                                     height: 20,
//                                     color: kSecondaryColor,
//                                   ),
//                                 )
//                               : Text(
//                                   episodeContent['name'],
//                                   textScaleFactor: 1.0,
//                                   style: TextStyle(
//                                       fontSize:
//                                           SizeConfig.safeBlockHorizontal * 5,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                           SizedBox(
//                             height: 25,
//                           ),
//                           episodeContent == null
//                               ? Shimmer.fromColors(
//                                   baseColor: Color(0xff3a3a3a),
//                                   highlightColor: kPrimaryColor,
//                                   child: Container(
//                                     width: double.infinity,
//                                     height: 15,
//                                     color: kSecondaryColor,
//                                   ))
//                               : Text(
//                                   episodeContent['podcast_name'],
//                                   textScaleFactor: mediaQueryData
//                                       .textScaleFactor
//                                       .clamp(1, 1.2)
//                                       .toDouble(),
//                                   style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize:
//                                           SizeConfig.safeBlockHorizontal * 3.8),
//                                 ),
//                           SizedBox(
//                             height: 2,
//                           ),
//
//                           SizedBox(
//                             height: 20,
//                           ),
//                           episodeContent == null
//                               ? Container()
//                               : Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: <Widget>[
//                                     Row(
//                                       children: [
//                                         GestureDetector(
//                                           onTap: () {
//                                             print(episodeContent['url']
//                                                 .toString()
//                                                 .contains('.mp4'));
//                                             if (episodeContent['url']
//                                                         .toString()
//                                                         .contains('.mp4') ==
//                                                     true ||
//                                                 episodeContent['url']
//                                                         .toString()
//                                                         .contains('.m4v') ==
//                                                     true ||
//                                                 episodeContent['url']
//                                                         .toString()
//                                                         .contains('.flv') ==
//                                                     true ||
//                                                 episodeContent['url']
//                                                         .toString()
//                                                         .contains('.f4v') ==
//                                                     true ||
//                                                 episodeContent['url']
//                                                         .toString()
//                                                         .contains('.ogv') ==
//                                                     true ||
//                                                 episodeContent['url']
//                                                         .toString()
//                                                         .contains('.ogx') ==
//                                                     true ||
//                                                 episodeContent['url']
//                                                         .toString()
//                                                         .contains('.wmv') ==
//                                                     true ||
//                                                 episodeContent['url']
//                                                         .toString()
//                                                         .contains('.webm') ==
//                                                     true) {
//                                               currentlyPlaying.stop();
//                                               Navigator.push(context,
//                                                   MaterialPageRoute(
//                                                       builder: (context) {
//                                                 return PodcastVideoPlayer(
//                                                   episodeObject: episodeContent,
//                                                 );
//                                               }));
//                                             } else {
//                                               if (episodeContent['url']
//                                                       .toString()
//                                                       .contains('.pdf') ==
//                                                   true) {
//                                                 // Navigator.push(context,
//                                                 //     MaterialPageRoute(
//                                                 //         builder: (context) {
//                                                 //   return PDFviewer(
//                                                 //     episodeObject:
//                                                 //         widget.episodeObject,
//                                                 //   );
//                                                 // }));
//                                               } else {
//                                                 currentlyPlaying.stop();
//                                                 currentlyPlaying.episodeObject =
//                                                     episodeContent;
//                                                 print(currentlyPlaying
//                                                     .episodeObject
//                                                     .toString());
//                                                 currentlyPlaying.play();
//                                                 showBarModalBottomSheet(
//                                                     context: context,
//                                                     builder: (context) {
//                                                       return Player();
//                                                     });
//                                               }
//                                             }
//                                           },
//                                           child: Container(
//                                             decoration: BoxDecoration(
//                                                 borderRadius:
//                                                     BorderRadius.circular(30),
//                                                 border: Border.all(
//                                                     color: Color(
//                                                         0xff171b27),
//                                                     width: 2)),
//                                             child: Center(
//                                               child: Padding(
//                                                 padding:
//                                                 const EdgeInsets
//                                                     .symmetric(
//                                                     horizontal: 20,
//                                                     vertical: 5),
//
//                                                 child: Text("Play"),
//                                               ),
//
//                                             ),
//                                           ),
//                                         ),
//                                         Platform.isAndroid == true
//                                             ? GestureDetector(
//                                                 onTap: () {
//                                                   startDownload();
//                                                   setState(() {
//                                                     _loading = !_loading;
//                                                     _updateProgress();
//                                                   });
//                                                 },
//                                                 child: Container(
//                                                     padding:
//                                                         EdgeInsets.all(15.0),
//                                                     child: _loading
//                                                         ? Column(
//                                                             mainAxisAlignment:
//                                                                 MainAxisAlignment
//                                                                     .center,
//                                                             children: <Widget>[
//                                                               CircularProgressIndicator(
//                                                                 value:
//                                                                     _progressValue,
//                                                               ),
//                                                               Text(
//                                                                   '${(_progressValue * 100).round()}%'),
//                                                             ],
//                                                           )
//                                                         : Icon(
//                                                             Icons
//                                                                 .arrow_circle_down,
//                                                             color: isDownloading ==
//                                                                     true
//                                                                 ? Color(
//                                                                     0xff5d5da8)
//                                                                 : Color(
//                                                                     0xff5bc3ef))),
//                                               )
//                                             : SizedBox(
//                                                 height: 0,
//                                                 width: 0,
//                                               ),
//                                       ],
//                                     ),
//                                     Row(
//                                       children: <Widget>[
//                                         episodeContent['permlink'] == null ||
//                                                 episodeContent['votes'] == null
//                                             ? (episodeContent['user_id'] ==
//                                                     prefs.getString('userId')
//                                                 ? InkWell(
//                                                     onTap: () async {
//                                                       await publishManually(
//                                                           episodeContent['id']);
//                                                     },
//                                                     child: Container(
//                                                       decoration: BoxDecoration(
//                                                           border: Border.all(
//                                                             color: Color(
//                                                                 0xff171b27),
//                                                           ),
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(20),
//                                                           gradient:
//                                                               LinearGradient(
//                                                                   colors: [
//                                                                 Color(
//                                                                     0xff5bc3ef),
//                                                                 Color(
//                                                                     0xff5d5da8)
//                                                               ])),
//                                                       child: Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                     .symmetric(
//                                                                 horizontal: 20,
//                                                                 vertical: 5),
//                                                         child: Text(
//                                                           'Publish',
//                                                           textScaleFactor:
//                                                               mediaQueryData
//                                                                   .textScaleFactor
//                                                                   .clamp(0.5, 1)
//                                                                   .toDouble(),
//                                                           style: TextStyle(
//                                                               // color:
//                                                               //     Color(0xffe8e8e8),
//                                                               fontSize: SizeConfig
//                                                                       .safeBlockHorizontal *
//                                                                   3.5),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   )
//                                                 : SizedBox(
//                                                     width: 0,
//                                                   ))
//                                             : InkWell(
//                                                 onTap: () async {
//                                                   if (prefs.getString(
//                                                           'HiveUserName') !=
//                                                       null) {
//                                                     setState(() {
//                                                       isUpvoteButtonLoading =
//                                                           true;
//                                                     });
//                                                     showDialog(
//                                                         context: context,
//                                                         builder: (context) {
//                                                           return Dialog(
//                                                               backgroundColor:
//                                                                   Colors
//                                                                       .transparent,
//                                                               child: UpvoteEpisode(
//                                                                   permlink:
//                                                                       episodeContent[
//                                                                           'permlink'],
//                                                                   episode_id:
//                                                                       episodeContent[
//                                                                           'id']));
//                                                         }).then((value) async {
//                                                       print(value);
//                                                     });
//                                                     // await upvoteEpisode(
//                                                     //     permlink:
//                                                     //         episodeContent[
//                                                     //             'permlink'],
//                                                     //     episode_id:
//                                                     //         episodeContent[
//                                                     //             'id']);
//                                                     setState(() {
//                                                       episodeContent[
//                                                               'ifVoted'] =
//                                                           !episodeContent[
//                                                               'ifVoted'];
//                                                     });
//                                                     setState(() {
//                                                       isUpvoteButtonLoading =
//                                                           false;
//                                                     });
//                                                   } else {
//                                                     showBarModalBottomSheet(
//                                                         context: context,
//                                                         builder: (context) {
//                                                           return HiveDetails();
//                                                         });
//                                                   }
//                                                 },
//                                                 child: Container(
//                                                   decoration: episodeContent[
//                                                               'ifVoted'] ==
//                                                           true
//                                                       ? BoxDecoration(
//                                                           gradient:
//                                                               LinearGradient(
//                                                                   colors: [
//                                                                 Color(
//                                                                     0xff5bc3ef),
//                                                                 Color(
//                                                                     0xff5d5da8)
//                                                               ]),
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(30))
//                                                       : BoxDecoration(
//                                                           border: Border.all(
//                                                               color: Color(
//                                                                   0xff171b27)),
//                                                           // color: kSecondaryColor,
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(30),
//                                                         ),
//                                                   child: Padding(
//                                                     padding:
//                                                         const EdgeInsets.all(
//                                                             5.0),
//                                                     child: Row(
//                                                       children: [
//                                                         isUpvoteButtonLoading ==
//                                                                 true
//                                                             ? Container(
//                                                                 height: 18,
//                                                                 width: 18,
//                                                                 child:
//                                                                     SpinKitPulse(
//                                                                   color: Colors
//                                                                       .blue,
//                                                                 ),
//                                                               )
//                                                             : Icon(
//                                                                 FontAwesomeIcons
//                                                                     .chevronCircleUp,
//                                                                 size: 18,
//
//                                                                 // color: Color(
//                                                                 //     0xffe8e8e8),
//                                                               ),
//                                                         Padding(
//                                                           padding:
//                                                               const EdgeInsets
//                                                                       .symmetric(
//                                                                   horizontal:
//                                                                       8),
//                                                           child: Text(
//                                                             '${episodeContent['votes']}',
//                                                             textScaleFactor:
//                                                                 mediaQueryData
//                                                                     .textScaleFactor
//                                                                     .clamp(
//                                                                         0.5, 1)
//                                                                     .toDouble(),
//                                                             style: TextStyle(
//                                                                 // color: Color(
//                                                                 //     0xffe8e8e8)
//                                                                 ),
//                                                           ),
//                                                         ),
//                                                         Padding(
//                                                           padding:
//                                                               const EdgeInsets
//                                                                       .only(
//                                                                   right: 4),
//                                                           child: Text(
//                                                             '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
//                                                             textScaleFactor:
//                                                                 mediaQueryData
//                                                                     .textScaleFactor
//                                                                     .clamp(
//                                                                         0.5, 1)
//                                                                     .toDouble(),
//                                                             style: TextStyle(
//                                                                 // color: Color(
//                                                                 //     0xffe8e8e8)
//                                                                 ),
//                                                           ),
//                                                         )
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                           SizedBox(
//                             height: 10,
//                           ),
//
//                           SizedBox(
//                             height: 20,
//                           ),
// //
//                         ],
//                       ),
//
//                     ),
//                    ]),
//                  ]),
//               ),
//               bottom: PreferredSize(
//                 preferredSize: const Size.fromHeight(80.0),
//                 child: Container(
//                   width: double.infinity,
//                   //     color: kPrimaryColor,
//                   child: Align(
//                     alignment: Alignment.centerLeft,
//                     child: Center(
//                       child: TabBar(
//                         controller: _tabController,
//                         isScrollable: true,
//                         //  labelColor: kActiveColor,
//                         // unselectedLabelColor: Colors.white,
//                         labelStyle: TextStyle(
//                             fontSize: SizeConfig.safeBlockHorizontal * 3.4),
//                         tabs: <Widget>[
//                           Tab(
//                               child: Text(
//                             "About",
//                             textScaleFactor: mediaQueryData.textScaleFactor
//                                 .clamp(0.5, 1)
//                                 .toDouble(),
//                           )),
//                           Tab(
//                               child: Text(
//                             "Comments",
//                             textScaleFactor: mediaQueryData.textScaleFactor
//                                 .clamp(0.5, 1)
//                                 .toDouble(),
//                           )),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 //   preferredSize: Size.fromHeight(0),
//               ),
//             ),
//           ];
//         },
//         body: episodeContent == null
//             ? Shimmer.fromColors(
//                 baseColor: Color(0xff3a3a3a),
//                 highlightColor: kPrimaryColor,
//                 child: Container(
//                   width: double.infinity,
//                   height: double.infinity,
//                   color: kSecondaryColor,
//                 ))
//             : Container(
//                 decoration:
//                     BoxDecoration(borderRadius: BorderRadius.circular(30)),
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: <Widget>[
//                     ListView(
//                       children: [
//                         episodeContent['summary'] == null
//                             ? Container()
//                             : Container(
//                                 child: Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 10, horizontal: 15),
//                                   child: htmlMatch.hasMatch(
//                                               episodeContent['summary']) ==
//                                           true
//                                       ? Text(
//                                           parse(episodeContent['summary'])
//                                               .body
//                                               .text,
//                                           textScaleFactor: mediaQueryData
//                                               .textScaleFactor
//                                               .clamp(0.5, 1)
//                                               .toDouble(),
//                                           style: TextStyle(
//                                               // color: Colors.white,
//                                               fontSize: SizeConfig
//                                                       .safeBlockHorizontal *
//                                                   3.8),
//                                         )
//                                       : Text(
//                                           '${episodeContent['summary']}',
//                                           textScaleFactor: mediaQueryData
//                                               .textScaleFactor
//                                               .clamp(0.5, 1)
//                                               .toDouble(),
//                                           style: TextStyle(
//                                               //      color: Colors.white,
//                                               fontSize: SizeConfig
//                                                       .safeBlockHorizontal *
//                                                   3.8),
//                                         ),
//                                 ),
//                               ),
//                         SizedBox(
//                           height: 0,
//                         ),
//                       ],
//                     ),
//                     Container(
//                       child: Stack(
//                         children: <Widget>[
//                           ListView.builder(
//                             itemBuilder: (BuildContext context, int index) {
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 10, vertical: 15),
//                                 child: Container(
//                                     child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: <Widget>[
//                                     ListTile(
//                                       leading: CircleAvatar(
//                                         backgroundImage:
//                                             CachedNetworkImageProvider(comments[
//                                                         index]['user_image'] ==
//                                                     null
//                                                 ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
//                                                 : comments[index]
//                                                     ['user_image']),
//                                       ),
//                                       title: Text(
//                                         '${comments[index]['author']}',
//                                         textScaleFactor: mediaQueryData
//                                             .textScaleFactor
//                                             .clamp(0.5, 1)
//                                             .toDouble(),
//                                         //     style: TextStyle(color: Color(0xffe8e8e8)),
//                                       ),
//                                       subtitle: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Padding(
//                                             padding: const EdgeInsets.only(
//                                                 bottom: 5),
//                                             child: Text(
//                                               "${comments[index]['text']}",
//                                               textScaleFactor: mediaQueryData
//                                                   .textScaleFactor
//                                                   .clamp(0.5, 1)
//                                                   .toDouble(),
//                                               // style:
//                                               //     TextStyle(color: Color(0xffe8e8e8)),
//                                             ),
//                                           ),
//                                           Row(
//                                             children: [
//                                               GestureDetector(
//                                                 onTap: () {},
//                                                 child: Text(
//                                                   "Reply",
//                                                   textScaleFactor:
//                                                       mediaQueryData
//                                                           .textScaleFactor
//                                                           .clamp(0.5, 1)
//                                                           .toDouble(),
//                                                   // style: TextStyle(color: Colors.white),
//                                                 ),
//                                               )
//                                             ],
//                                           )
//                                         ],
//                                       ),
//                                       trailing: IconButton(
//                                         onPressed: () {
//                                           showDialog(
//                                               context: context,
//                                               builder: (context) {
//                                                 return Dialog(
//                                                     backgroundColor:
//                                                         Colors.transparent,
//                                                     child: UpvoteComment(
//                                                       comment_id:
//                                                           comments[index]['id']
//                                                               .toString(),
//                                                     ));
//                                               }).then((value) async {
//                                             print(value);
//                                           });
//                                         },
//                                         icon: Icon(
//                                           FontAwesomeIcons.chevronCircleUp,
//                                           //  color: Colors.white,
//                                         ),
//                                       ),
//                                       isThreeLine: true,
//                                     ),
//                                     comments[index]['comments'] == null
//                                         // comments[index].contains('comments') == false
//                                         ? SizedBox(
//                                             height: 0,
//                                           )
//                                         : ExpansionTile(
//                                             //  backgroundColor: Colors.transparent,
//                                             trailing: SizedBox(
//                                               width: 0,
//                                             ),
//                                             title: Align(
//                                               alignment: Alignment.centerLeft,
//                                               child: Text(
//                                                 "View replies",
//                                                 textScaleFactor: mediaQueryData
//                                                     .textScaleFactor
//                                                     .clamp(0.5, 1)
//                                                     .toDouble(),
//                                                 style: TextStyle(
//                                                   fontSize: SizeConfig
//                                                           .safeBlockHorizontal *
//                                                       3,
//                                                   //  color: Colors.grey,
//                                                 ),
//                                               ),
//                                             ),
//                                             children: <Widget>[
//                                               for (var v in comments[index]
//                                                   ['comments'])
//                                                 ListTile(
//                                                   leading: CircleAvatar(
//                                                     backgroundImage:
//                                                         CachedNetworkImageProvider(
//                                                             v['user_image']),
//                                                   ),
//                                                   title: Text(
//                                                     '${v['author']}',
//                                                     textScaleFactor:
//                                                         mediaQueryData
//                                                             .textScaleFactor
//                                                             .clamp(0.5, 1)
//                                                             .toDouble(),
//                                                   ),
//                                                   subtitle: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                     .only(
//                                                                 bottom: 5),
//                                                         child: Text(
//                                                           "${v['text']}",
//                                                           textScaleFactor:
//                                                               mediaQueryData
//                                                                   .textScaleFactor
//                                                                   .clamp(0.5, 1)
//                                                                   .toDouble(),
//                                                           style: TextStyle(),
//                                                         ),
//                                                       ),
//                                                       Row(
//                                                         children: [
//                                                           GestureDetector(
//                                                             onTap: () {},
//                                                             child: Text(
//                                                               "Reply",
//                                                               textScaleFactor:
//                                                                   mediaQueryData
//                                                                       .textScaleFactor
//                                                                       .clamp(
//                                                                           0.5,
//                                                                           1)
//                                                                       .toDouble(),
//                                                               style:
//                                                                   TextStyle(),
//                                                             ),
//                                                           )
//                                                         ],
//                                                       )
//                                                     ],
//                                                   ),
//                                                   trailing: IconButton(
//                                                     onPressed: () {
//                                                       showDialog(
//                                                           context: context,
//                                                           builder: (context) {
//                                                             return Dialog(
//                                                                 backgroundColor:
//                                                                     Colors
//                                                                         .transparent,
//                                                                 child:
//                                                                     UpvoteComment(
//                                                                   comment_id: v[
//                                                                           'id']
//                                                                       .toString(),
//                                                                 ));
//                                                           }).then((value) async {
//                                                         print(value);
//                                                       });
//                                                     },
//                                                     icon: Icon(
//                                                       FontAwesomeIcons
//                                                           .chevronCircleUp,
//                                                     ),
//                                                   ),
//                                                   isThreeLine: true,
//                                                 ),
//                                             ],
//                                           )
//                                   ],
//                                 )),
//                               );
//                             },
//                             itemCount: comments.length,
//                           ),
//                           Column(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: <Widget>[
//                               FlatButton(
//                                 //    color: Colors.blueAccent,
//                                 onPressed: () {
//                                   Navigator.push(context, MaterialPageRoute(
//                                       builder: (BuildContext context) {
//                                     return Comments(
//                                       episodeObject: episodeContent,
//                                     );
//                                   })).then((value) {
//                                     getTags();
//                                     getComments();
//                                     if (episodeContent['likes'] == true) {
//                                       setState(() {
//                                         likeStatus = Like.liked;
//                                       });
//                                     } else {
//                                       setState(() {
//                                         likeStatus = Like.unliked;
//                                       });
//                                     }
//                                   });
//                                 },
//                                 child: Container(
//                                   child: Row(
//                                     children: <Widget>[
//                                       Padding(
//                                         padding: const EdgeInsets.symmetric(
//                                             vertical: 10),
//                                         child: Row(
//                                           children: <Widget>[
//                                             CircleAvatar(
//                                               backgroundImage: prefs.getString(
//                                                           'displayPicture') ==
//                                                       null
//                                                   ? AssetImage(
//                                                       'assets/images/Thumbnail.png')
//                                                   : NetworkImage(
//                                                       prefs.getString(
//                                                           'displayPicture')),
//                                             ),
//                                             SizedBox(
//                                               width: 10,
//                                             ),
//                                             Text(
//                                               'Add a comment...',
//                                               textScaleFactor: mediaQueryData
//                                                   .textScaleFactor
//                                                   .clamp(0.5, 1)
//                                                   .toDouble(),
//                                             )
//                                           ],
//                                         ),
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//  ),
// );
//   }
// }
