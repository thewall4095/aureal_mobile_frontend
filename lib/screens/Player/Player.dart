import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/DatabaseFunctions/EpisodesBloc.dart';
import 'package:auditory/DatabaseFunctions/EpisodesProvider.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/publicUserProfile.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/Share.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:social_share/social_share.dart';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../Clips.dart';
import '../FollowingPage.dart';
import '../Home.dart';
import 'PlayerElements/Seekbar.dart';
import 'package:screenshot/screenshot.dart';

enum PlayerState { stopped, playing, paused }

extension Pipe<T> on T {
  R pipe<R>(R f(T t)) => f(this);
}

class Player extends StatefulWidget {
  static const String id = "Player";

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> with TickerProviderStateMixin {
  //Global Key For ScrollController for transcription

  final dataKey = new GlobalKey();

  PlayerState playerState = PlayerState.playing;
  final _episodeBloc = EpisodeBloc();
  final _mp = EpisodesProvider.getInstance();
  RegExp htmlMatch = RegExp(r'(\w+)');
  ScrollController _controller;
  ScreenshotController screenshotController = ScreenshotController();
  TextEditingController _commentsController;
  TextEditingController _replyController;
  Duration position;
  String comment;
  Duration duration;
  bool isSending = false;
  String displayPicture;
  String hiveToken;
  var comments = [];
  SharedPreferences pref;
  SharedPreferences prefs;
  var storedepisodes = [];
  var episodeContent;
  var episodeObject;
  List transcript;
  final picker = ImagePicker();
  File _image;
  bool isUpvoteLoading = false;

  int currentIndex = 0;

  ItemScrollController itemScrollController;

  TabController _tabController;

  void Transcription(episode_id) async {
    String url =
        "https://api.aureal.one/public/getTranscription?episode_id=${episode_id}";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("sfjkab");
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          transcript = jsonDecode(response.body)['data']['transcription'];
        });
        print(transcript);
        print(transcript.runtimeType);
      }
    } catch (e) {
      print(e);
    }
  }

  ItemPositionsListener itemPositionsListener;

  void getInitialComments(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    getComments(episodeObject.episodeObject);
  }

  void getHiveToken() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      hiveToken = prefs.getString('access_token');
    });
  }

  void postReply(int commentId, String text, var episodeObject) async {
    setState(() {
      isSending = true;
    });
    String url = 'https://api.aureal.one/private/reply';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['text'] = text;
    map['comment_id'] = commentId;

    map['hive_username'] = prefs.getString('HiveUserName');

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);

    getComments(episodeObject);
    _replyController.clear();
    setState(() {
      isSending = false;
    });
  }

  void getComments(var episodeObject) async {
    String url =
        'https://api.aureal.one/public/getComments?episode_id=${episodeObject['id']}';
    SharedPreferences prefs = await SharedPreferences.getInstance();
// print("${episodeObject['id']}");
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          comments = jsonDecode(response.body)['comments'];
          displayPicture = prefs.getString('displayPicture');
        });
        print(comments);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      counter = counter + 1;
    });
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  void postComment(var episodeObject, String text) async {
    print("Starting the comment function");
    setState(() {
      isSending = true;
    });
    String url = 'https://api.aureal.one/private/comment';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = episodeObject['id'];
    map['text'] = text;
    if (episodeObject['permlink'] != null) {
      map['hive_username'] = prefs.getString('HiveUserName');
    }

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response);
    await getComments(episodeObject);
    _commentsController.clear();
    setState(() {
      isSending = false;
    });
  }

  int counter = 0;
  String copyclip;
  String hiveUsername;

  final List<StreamSubscription> _subscriptions = [];
  int progress = 0;

  var dominantColor = 0xff222222;

  int hexOfRGBA(int r, int g, int b, {double opacity = 0.3}) {
    r = (r < 0) ? -r : r;
    g = (g < 0) ? -g : g;
    b = (b < 0) ? -b : b;
    opacity = (opacity < 0) ? -opacity : opacity;
    opacity = (opacity > 1) ? 500 : opacity * 500;
    r = (r > 255) ? 255 : r;
    g = (g > 255) ? 255 : g;
    b = (b > 255) ? 255 : b;
    int a = opacity.toInt();
    return int.parse(
        '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}');
  }

  // void getColor(String url) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   hiveUsername = prefs.getString('HiveUserName');
  //
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

  void getEpisode(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var playerState = Provider.of<PlayerChange>(context, listen: false);
    String url =
        'https://api.aureal.one/public/episode?episode_id=${playerState.audioPlayer.realtimePlayingInfos.value.current.audio.audio.metas.id}&user_id=${prefs.getString('userId')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (this.mounted) {
          setState(() {
            episodeContent = jsonDecode(response.body)['episode'];

            hiveUsername = prefs.getString('HiveUserName');
          });
        }
        // await getColor(episodeContent['image']);
        setState(() {
          // isLoading = false;
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    // getRecommendations();
  }

  @override
  void initState() {
    // TODO: implement initState

    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();

    super.initState();
    _tabController = TabController(vsync: this, length: 2);

    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    getEpisode(context);
    print('abc');
    print(episodeObject.id);
    Transcription(episodeObject.id);
    episodeObject.audioPlayer.currentPosition.listen((event) {
      var currentPositionSeconds = event.inMilliseconds / 1000;
      if (transcript != null && transcript.length > 0) {
        // print(event.inMilliseconds / 1000);
        // print(transcript.indexWhere((element) => element['start_time'] < currentPositionSeconds && element['end_time'] > currentPositionSeconds));
        // setState(() {
        if (transcript != null && transcript.length > 0) {
          var count = (transcript.indexWhere((element) =>
              element['start_time'] < currentPositionSeconds &&
              element['end_time'] > currentPositionSeconds));
          if (count >= 0) {
            print(count);

            setState(() {
              currentIndex = count;
            });

            itemScrollController.jumpTo(
              index: count,
              // curve: Curves.easeInCirc,
            );
          }
        }
      }
    });

    // episodeObject.audioPlayer.currentPosition.listen((event) {
    //   if (episodeObject.audioPlayer.currentPosition.value ==
    //       episodeObject.audioPlayer.realtimePlayingInfos.value.duration) {
    //     episodeObject.customNextAction(episodeObject.audioPlayer);
    //   }
    // });

    // getColor(episodeObject.episodeObject['image'] == null
    //     ? episodeObject.episodeObject['podcast_image']
    //     : episodeObject.episodeObject['image']);
    if (counter < 1) {
      getComments(episodeObject.episodeObject);
    }

    print(episodeObject.episodeObject);

    _subscriptions
        .add(episodeObject.audioPlayer.playlistAudioFinished.listen((data) {
      print("playlistAudioFinished : $data");
      print("///////////////////This is the data");
      getEpisode(context);
    }));
    // _subscriptions
    //     .add(episodeObject.audioPlayer.((sessionId) {
    //   print("audioSessionId : $sessionId");
    // }));
    _subscriptions
        .add(AssetsAudioPlayer.addNotificationOpenAction((notification) {
      return false;
    }));

    _playListTabController = TabController(vsync: this, length: 3);
  }

  TabController _playListTabController;

  @override
  void dispose() {
    super.dispose();
    // TODO: implement dispose
    print('Dispose Called//////////////////////////////////////////////');

    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Color(0xff161616)));
  }

  void share() async {
    var playerProvider = Provider.of<PlayerChange>(context, listen: false);

    // String sharableLink;

    await FlutterShare.share(
        title:
            '${playerProvider.audioPlayer.current.value.audio.audio.metas.album}',
        text:
            "Hey There, I'm listening to ${playerProvider.audioPlayer.current.value.audio.audio.metas.title} from ${playerProvider.audioPlayer.current.value.audio.audio.metas.album} on : Aureal, \n \nhere's the link for you https://aureal.one/episode/${playerProvider.audioPlayer.current.value.audio.audio.metas.id}");
  }

  String _fileName;
  String _path;
  Map<String, String> _paths;

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);
    SizeConfig().init(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Color(0xff161616),
      resizeToAvoidBottomInset: false,
      // body: SafeArea(
      //   child: Container(
      //       width: MediaQuery.of(context).size.width,
      //       height: MediaQuery.of(context).size.height,
      //       child: episodeObject.audioPlayer.builderRealtimePlayingInfos(
      //           builder: (context, infos) {
      //         return Column(
      //           children: [
      //             CachedNetworkImage(
      //               imageUrl: infos.current.audio.audio.metas.image.path,
      //               imageBuilder: (context, imageProvider) {
      //                 return Stack(
      //                   children: [
      //                     Container(
      //                       decoration: BoxDecoration(
      //                           image: DecorationImage(
      //                               image: imageProvider, fit: BoxFit.cover)),
      //                       width: MediaQuery.of(context).size.width,
      //                       height: MediaQuery.of(context).size.width,
      //                     ),
      //                     Positioned(
      //                       bottom: 0,
      //                       child: Container(
      //                         child: Column(
      //                           mainAxisAlignment: MainAxisAlignment.end,
      //                           children: [
      //                             ListTile(
      //                               title: GestureDetector(
      //                                 onTap: () {
      //                                   Navigator.push(context,
      //                                       CupertinoPageRoute(
      //                                           builder: (context) {
      //                                     return EpisodeView(
      //                                         episodeId: episodeObject
      //                                             .episodeObject['id']);
      //                                   }));
      //                                 },
      //                                 child: Text(
      //                                   '${infos.current.audio.audio.metas.title}',
      //                                   maxLines: 2,
      //                                   textScaleFactor: 1.0,
      //                                   overflow: TextOverflow.ellipsis,
      //                                   style: TextStyle(
      //                                       fontSize:
      //                                           SizeConfig.blockSizeHorizontal *
      //                                               3.4,
      //                                       fontWeight: FontWeight.bold),
      //                                 ),
      //                               ),
      //                               subtitle: InkWell(
      //                                 onTap: () {
      //                                   Navigator.push(context,
      //                                       CupertinoPageRoute(
      //                                           builder: (context) {
      //                                     return PublicProfile(
      //                                       userId: episodeObject
      //                                           .episodeObject['user_id'],
      //                                     );
      //                                   }));
      //                                 },
      //                                 child: Padding(
      //                                   padding: const EdgeInsets.symmetric(
      //                                       vertical: 8),
      //                                   child: Text(
      //                                     '${infos.current.audio.audio.metas.artist}',
      //                                     style: TextStyle(
      //                                       fontSize: 16,
      //                                     ),
      //                                   ),
      //                                 ),
      //                               ),
      //                             ),
      //                           ],
      //                         ),
      //                         height: MediaQuery.of(context).size.width / 2,
      //                         width: MediaQuery.of(context).size.width,
      //                         decoration: BoxDecoration(
      //                             gradient: LinearGradient(
      //                                 colors: [
      //                               Colors.black,
      //                               Colors.transparent
      //                             ],
      //                                 begin: Alignment.bottomCenter,
      //                                 end: Alignment.topCenter)),
      //                       ),
      //                     ),
      //                   ],
      //                 );
      //               },
      //             ),
      //             Padding(
      //               padding: const EdgeInsets.all(15),
      //               child: Builder(
      //                 builder: (context) {
      //                   try {
      //                     return episodeContent['permlink'] == null
      //                         ? SizedBox()
      //                         : Container(
      //                             child: Row(
      //                               mainAxisAlignment: MainAxisAlignment.center,
      //                               children: [
      //                                 InkWell(
      //                                   onTap: () async {
      //                                     if (hiveUsername != null) {
      //                                       setState(() {
      //                                         isUpvoteLoading = true;
      //                                       });
      //                                       double _value = 50.0;
      //                                       showDialog(
      //                                           context: context,
      //                                           builder: (context) {
      //                                             return Dialog(
      //                                                 backgroundColor:
      //                                                     Colors.transparent,
      //                                                 child: UpvoteEpisode(
      //                                                     permlink:
      //                                                         episodeContent[
      //                                                             'permlink'],
      //                                                     episode_id: int.parse(
      //                                                         episodeObject
      //                                                             .audioPlayer
      //                                                             .current
      //                                                             .value
      //                                                             .audio
      //                                                             .audio
      //                                                             .metas
      //                                                             .id)));
      //                                           }).then((value) async {
      //                                         print(value);
      //                                       });
      //                                       setState(() {
      //                                         if (episodeObject.ifVoted !=
      //                                             true) {
      //                                           episodeObject.ifVoted = true;
      //                                         }
      //                                       });
      //                                       setState(() {
      //                                         isUpvoteLoading = false;
      //                                       });
      //                                     } else {
      //                                       showBarModalBottomSheet(
      //                                           context: context,
      //                                           builder: (context) {
      //                                             return HiveDetails();
      //                                           });
      //                                     }
      //                                   },
      //                                   child: Container(
      //                                     decoration: episodeContent[
      //                                                 'ifVoted'] ==
      //                                             true
      //                                         ? BoxDecoration(
      //                                             gradient: LinearGradient(
      //                                                 colors: [
      //                                                   Color(0xff5bc3ef),
      //                                                   Color(0xff5d5da8)
      //                                                 ]),
      //                                             borderRadius:
      //                                                 BorderRadius.circular(30))
      //                                         : BoxDecoration(
      //                                             border: Border.all(
      //                                                 color: kSecondaryColor),
      //                                             borderRadius:
      //                                                 BorderRadius.circular(
      //                                                     30)),
      //                                     child: Padding(
      //                                       padding: const EdgeInsets.symmetric(
      //                                           vertical: 5, horizontal: 10),
      //                                       child: Row(
      //                                         children: [
      //                                           isUpvoteLoading == true
      //                                               ? Container(
      //                                                   height: 17,
      //                                                   width: 18,
      //                                                   child: SpinKitPulse(
      //                                                     color: Colors.blue,
      //                                                   ),
      //                                                 )
      //                                               : Icon(
      //                                                   FontAwesomeIcons
      //                                                       .chevronCircleUp,
      //                                                   size: 15,
      //                                                   // color:
      //                                                   //     Color(0xffe8e8e8),
      //                                                 ),
      //                                           Padding(
      //                                             padding: const EdgeInsets
      //                                                 .symmetric(horizontal: 8),
      //                                             child: Text(
      //                                               episodeContent['votes']
      //                                                   .toString(),
      //                                               textScaleFactor: 1.0,
      //                                               style: TextStyle(
      //                                                   fontSize: 15
      //                                                   // color:
      //                                                   //     Color(0xffe8e8e8)
      //                                                   ),
      //                                             ),
      //                                           ),
      //                                           Container(
      //                                             height: 15,
      //                                             width: 10,
      //                                             decoration: BoxDecoration(
      //                                               border: Border(
      //                                                   left: BorderSide(
      //                                                 color: themeProvider
      //                                                             .isLightTheme ==
      //                                                         false
      //                                                     ? Colors.white
      //                                                     : kPrimaryColor,
      //                                               )),
      //                                             ),
      //                                           ),
      //                                           Padding(
      //                                             padding:
      //                                                 const EdgeInsets.only(
      //                                                     right: 4),
      //                                             child: Text(
      //                                               '\$${episodeContent['payout_value'].toString().split(' ')[0]}',
      //                                               textScaleFactor: 1.0,
      //                                               style: TextStyle(
      //                                                 fontSize: 15,
      //
      //                                                 // color:
      //                                                 //     Color(0xffe8e8e8)
      //                                               ),
      //                                             ),
      //                                           )
      //                                         ],
      //                                       ),
      //                                     ),
      //                                   ),
      //                                 ),
      //                               ],
      //                             ),
      //                           );
      //                   } catch (e) {
      //                     print("API call still Happening");
      //                     return SizedBox();
      //                   }
      //                 },
      //               ),
      //             ),
      //             Container(
      //               // height: MediaQuery.of(context).size.height / 1.5,
      //               decoration: BoxDecoration(
      //                 // boxShadow: [
      //                 //   new BoxShadow(
      //                 //     color: Colors.black54.withOpacity(0.2),
      //                 //     blurRadius: 10.0,
      //                 //   ),
      //                 // ],
      //                 // color: Color(0xff222222),
      //                 borderRadius: BorderRadius.circular(8),
      //               ),
      //               child: Column(
      //                 mainAxisAlignment: MainAxisAlignment.start,
      //                 children: [
      //                   episodeObject.audioPlayer.builderRealtimePlayingInfos(
      //                       builder: (context, infos) {
      //                     if (infos == null) {
      //                       return SizedBox(
      //                         height: 0,
      //                       );
      //                     } else {
      //                       return Seekbar(
      //                         dominantColor: dominantColor == null
      //                             ? 0xff222222
      //                             : dominantColor,
      //                         currentPosition: infos.currentPosition,
      //                         duration: infos.duration,
      //                         episodeName: episodeObject.episodeName,
      //                         seekTo: (to) {
      //                           episodeObject.audioPlayer.seek(to);
      //                         },
      //                       );
      //                     }
      //                   }),
      //                   SizedBox(
      //                     height: MediaQuery.of(context).size.height / 35,
      //                   ),
      //                   Padding(
      //                     padding: const EdgeInsets.symmetric(
      //                         vertical: 20, horizontal: 10),
      //                     child: Row(
      //                       crossAxisAlignment: CrossAxisAlignment.center,
      //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                       children: <Widget>[
      //                         IconButton(
      //                           icon: Icon(
      //                             FontAwesomeIcons.fighterJet,
      //                             size: 18,
      //                           ),
      //                           onPressed: () {
      //                             showDialog(
      //                                 context: context,
      //                                 builder: (context) {
      //                                   return Dialog(
      //                                     shape: RoundedRectangleBorder(
      //                                       borderRadius:
      //                                           BorderRadius.circular(30),
      //                                     ),
      //                                     child: Container(
      //                                       decoration: BoxDecoration(
      //                                         color: kSecondaryColor,
      //                                         borderRadius:
      //                                             BorderRadius.circular(10),
      //                                       ),
      //                                       height: 380,
      //                                       child: Padding(
      //                                         padding:
      //                                             const EdgeInsets.symmetric(
      //                                                 horizontal: 15,
      //                                                 vertical: 10),
      //                                         child: Column(
      //                                           mainAxisAlignment:
      //                                               MainAxisAlignment
      //                                                   .spaceBetween,
      //                                           crossAxisAlignment:
      //                                               CrossAxisAlignment.start,
      //                                           children: [
      //                                             FlatButton(
      //                                               onPressed: () {
      //                                                 Navigator.pop(context);
      //                                               },
      //                                               child: Row(
      //                                                 children: [
      //                                                   Text(
      //                                                     "0.25X",
      //                                                     textScaleFactor: 0.75,
      //                                                     style: TextStyle(
      //                                                         color: Colors
      //                                                             .white
      //                                                             .withOpacity(
      //                                                                 0.7)),
      //                                                   )
      //                                                 ],
      //                                               ),
      //                                             ),
      //                                             FlatButton(
      //                                               onPressed: () {
      //                                                 episodeObject.audioPlayer
      //                                                     .setPlaySpeed(0.5);
      //                                                 Navigator.pop(context);
      //                                               },
      //                                               child: Row(
      //                                                 children: [
      //                                                   Text(
      //                                                     "0.5X",
      //                                                     textScaleFactor: 0.75,
      //                                                     style: TextStyle(
      //                                                         color: Colors
      //                                                             .white
      //                                                             .withOpacity(
      //                                                                 0.7)),
      //                                                   )
      //                                                 ],
      //                                               ),
      //                                             ),
      //                                             FlatButton(
      //                                               onPressed: () {
      //                                                 episodeObject.audioPlayer
      //                                                     .setPlaySpeed(0.75);
      //                                                 Navigator.pop(context);
      //                                               },
      //                                               child: Row(
      //                                                 children: [
      //                                                   Text(
      //                                                     "0.75X",
      //                                                     textScaleFactor: 0.75,
      //                                                     style: TextStyle(
      //                                                         color: Colors
      //                                                             .white
      //                                                             .withOpacity(
      //                                                                 0.7)),
      //                                                   )
      //                                                 ],
      //                                               ),
      //                                             ),
      //                                             FlatButton(
      //                                               onPressed: () {
      //                                                 episodeObject.audioPlayer
      //                                                     .setPlaySpeed(1.0);
      //                                                 Navigator.pop(context);
      //                                               },
      //                                               child: Row(
      //                                                 children: [
      //                                                   Text(
      //                                                     "Normal",
      //                                                     textScaleFactor: 0.75,
      //                                                     style: TextStyle(
      //                                                         color: Colors
      //                                                             .white
      //                                                             .withOpacity(
      //                                                                 0.7)),
      //                                                   )
      //                                                 ],
      //                                               ),
      //                                             ),
      //                                             FlatButton(
      //                                               onPressed: () {
      //                                                 episodeObject.audioPlayer
      //                                                     .setPlaySpeed(1.25);
      //                                                 Navigator.pop(context);
      //                                               },
      //                                               child: Row(
      //                                                 children: [
      //                                                   Text(
      //                                                     "1.25X",
      //                                                     textScaleFactor: 0.75,
      //                                                     style: TextStyle(
      //                                                         color: Colors
      //                                                             .white
      //                                                             .withOpacity(
      //                                                                 0.7)),
      //                                                   )
      //                                                 ],
      //                                               ),
      //                                             ),
      //                                             FlatButton(
      //                                               onPressed: () {
      //                                                 episodeObject.audioPlayer
      //                                                     .setPlaySpeed(1.5);
      //                                                 Navigator.pop(context);
      //                                               },
      //                                               child: Row(
      //                                                 children: [
      //                                                   Text(
      //                                                     "1.5X",
      //                                                     textScaleFactor: 0.75,
      //                                                     style: TextStyle(
      //                                                         color: Colors
      //                                                             .white
      //                                                             .withOpacity(
      //                                                                 0.7)),
      //                                                   )
      //                                                 ],
      //                                               ),
      //                                             ),
      //                                             FlatButton(
      //                                               onPressed: () {
      //                                                 episodeObject.audioPlayer
      //                                                     .setPlaySpeed(2.0);
      //                                                 Navigator.pop(context);
      //                                               },
      //                                               child: Row(
      //                                                 children: [
      //                                                   Text(
      //                                                     "2X",
      //                                                     textScaleFactor: 0.75,
      //                                                     style: TextStyle(
      //                                                         color: Colors
      //                                                             .white
      //                                                             .withOpacity(
      //                                                                 0.7)),
      //                                                   )
      //                                                 ],
      //                                               ),
      //                                             ),
      //                                           ],
      //                                         ),
      //                                       ),
      //                                     ),
      //                                   );
      //                                 });
      //                           },
      //                         ),
      //                         IconButton(
      //                           icon: Icon(
      //                             Icons.replay_10,
      //                             //  color: Colors.white,
      //                             size: 40,
      //                           ),
      //                           onPressed: () {
      //                             episodeObject.audioPlayer
      //                                 .seekBy(Duration(seconds: -10));
      //                           },
      //                         ),
      //                         episodeObject.audioPlayer
      //                             .builderRealtimePlayingInfos(
      //                                 builder: (context, infos) {
      //                           if (infos == null) {
      //                             return SpinKitPulse(
      //                               color: Colors.white,
      //                             );
      //                           } else {
      //                             if (infos.isBuffering == true) {
      //                               return SpinKitCircle(
      //                                 size: 15,
      //                                 color: Colors.white,
      //                               );
      //                             } else {
      //                               if (infos.isPlaying == true) {
      //                                 return FloatingActionButton(
      //                                     child: Icon(Icons.pause),
      //                                     backgroundColor:
      //                                         Color(dominantColor) == null
      //                                             ? Colors.blue
      //                                             : Color(dominantColor),
      //                                     onPressed: () {
      //                                       episodeObject.pause();
      //                                       setState(() {
      //                                         playerState = PlayerState.paused;
      //                                       });
      //                                     });
      //                               } else {
      //                                 return FloatingActionButton(
      //                                     backgroundColor:
      //                                         Color(dominantColor) == null
      //                                             ? Colors.blue
      //                                             : Color(dominantColor),
      //                                     child: Icon(Icons.play_arrow_rounded),
      //                                     onPressed: () {
      //                                       // play(url);
      //                                       episodeObject.resume();
      //                                       setState(() {
      //                                         playerState = PlayerState.playing;
      //                                       });
      //                                     });
      //                               }
      //                             }
      //                           }
      //                         }),
      //                         IconButton(
      //                           icon: Icon(
      //                             Icons.forward_10,
      //                             //  color: Colors.white,
      //                             size: 40,
      //                           ),
      //                           onPressed: () {
      //                             episodeObject.audioPlayer.seekBy(
      //                               Duration(seconds: 10),
      //                             );
      //                           },
      //                         ),
      //                         IconButton(
      //                           onPressed: () {
      //                             share();
      //                           },
      //                           icon: Icon(
      //                             Icons.ios_share,
      //                             size: 18,
      //                           ),
      //                         )
      //                       ],
      //                     ),
      //                   ),
      //                   transcript == null
      //                       ? SizedBox()
      //                       : Padding(
      //                           padding: const EdgeInsets.all(20),
      //                           child: GestureDetector(
      //                             onTap: () {
      //                               Navigator.push(context,
      //                                   CupertinoPageRoute(builder: (context) {
      //                                 print(transcript);
      //                                 print(transcript.runtimeType);
      //                                 return TrancriptionPlayer(
      //                                   transcript: transcript,
      //                                 );
      //                               }));
      //                             },
      //                             child: Container(
      //                               decoration: BoxDecoration(
      //                                 borderRadius: BorderRadius.circular(10),
      //                                 color: Color(0xff161616),
      //                               ),
      //                               height:
      //                                   MediaQuery.of(context).size.height / 4,
      //                               width: double.infinity,
      //                               child: Padding(
      //                                 padding: const EdgeInsets.all(20),
      //                                 child: Column(
      //                                   crossAxisAlignment:
      //                                       CrossAxisAlignment.start,
      //                                   mainAxisAlignment:
      //                                       MainAxisAlignment.center,
      //                                   children: [
      //                                     Padding(
      //                                       padding: const EdgeInsets.all(8.0),
      //                                       child: Text(
      //                                         "${transcript[currentIndex]['msg'].toString().trimLeft().trimRight()}",
      //                                         textScaleFactor: 1.0,
      //                                         style: TextStyle(
      //                                             color: Colors.white,
      //                                             fontSize: SizeConfig
      //                                                     .safeBlockHorizontal *
      //                                                 4),
      //                                       ),
      //                                     ),
      //                                     Padding(
      //                                       padding: const EdgeInsets.all(8.0),
      //                                       child: Text(
      //                                         "${transcript[currentIndex + 1]['msg'].toString().trimLeft().trimRight()}",
      //                                         textScaleFactor: 1.0,
      //                                         style: TextStyle(
      //                                             fontSize: SizeConfig
      //                                                     .safeBlockHorizontal *
      //                                                 4,
      //                                             color: Colors.white
      //                                                 .withOpacity(0.5)),
      //                                       ),
      //                                     ),
      //                                   ],
      //                                 ),
      //                               ),
      //                             ),
      //                           ),
      //                         ),
      //                   SizedBox(
      //                     height: 50,
      //                   ),
      //                 ],
      //               ),
      //             ),
      //             // DraggableScrollableSheet(
      //             //     initialChildSize: 0.1,
      //             //     maxChildSize: 1.0,
      //             //     minChildSize: 0.1,
      //             //     builder: (context, controller) {
      //             //       return episodeObject.audioPlayer.builderCurrent(
      //             //           builder: (context, Playing playing) {
      //             //         return SongSelector(
      //             //           audios: episodeObject.audioPlayer.playlist.audios ==
      //             //                   null
      //             //               ? <Audio>[]
      //             //               : episodeObject.audioPlayer.playlist.audios,
      //             //           onPlaylistSelected: (myAudios) {
      //             //             episodeObject.audioPlayer.open(
      //             //               Playlist(audios: myAudios),
      //             //               showNotification: true,
      //             //               headPhoneStrategy:
      //             //                   HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
      //             //               audioFocusStrategy: AudioFocusStrategy.request(
      //             //                   resumeAfterInterruption: true),
      //             //             );
      //             //           },
      //             //           onSelected: (myAudio) async {
      //             //             try {
      //             //               await episodeObject.audioPlayer.open(
      //             //                 myAudio,
      //             //                 autoStart: true,
      //             //                 showNotification: true,
      //             //                 playInBackground: PlayInBackground.enabled,
      //             //                 audioFocusStrategy:
      //             //                     AudioFocusStrategy.request(
      //             //                         resumeAfterInterruption: true,
      //             //                         resumeOthersPlayersAfterDone: true),
      //             //                 headPhoneStrategy:
      //             //                     HeadPhoneStrategy.pauseOnUnplug,
      //             //                 notificationSettings: NotificationSettings(
      //             //                     //seekBarEnabled: false,
      //             //                     //stopEnabled: true,
      //             //                     //customStopAction: (player){
      //             //                     //  player.stop();
      //             //                     //}
      //             //                     //prevEnabled: false,
      //             //                     //customNextAction: (player) {
      //             //                     //  print('next');
      //             //                     //}
      //             //                     //customStopIcon: AndroidResDrawable(name: 'ic_stop_custom'),
      //             //                     //customPauseIcon: AndroidResDrawable(name:'ic_pause_custom'),
      //             //                     //customPlayIcon: AndroidResDrawable(name:'ic_play_custom'),
      //             //                     ),
      //             //               );
      //             //             } catch (e) {
      //             //               print(e);
      //             //             }
      //             //           },
      //             //           playing: playing,
      //             //         );
      //             //       });
      //             //     }),
      //           ],
      //         );
      //       })),
      // ),a
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Color(0xff161616),
              pinned: true,
              expandedHeight: MediaQuery.of(context).size.height / 1.2,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                    color: Color(0xff161616),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: episodeObject.audioPlayer
                        .builderRealtimePlayingInfos(builder: (context, infos) {
                      return Column(
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                infos.current.audio.audio.metas.image.path,
                            imageBuilder: (context, imageProvider) {
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover)),
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.width,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ListTile(
                                            title: GestureDetector(
                                              onTap: () {
                                                Navigator.push(context,
                                                    CupertinoPageRoute(
                                                        builder: (context) {
                                                  return EpisodeView(
                                                      episodeId: episodeObject
                                                          .episodeObject['id']);
                                                }));
                                              },
                                              child: Text(
                                                '${infos.current.audio.audio.metas.title}',
                                                maxLines: 2,
                                                textScaleFactor: 1.0,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .blockSizeHorizontal *
                                                        3.4,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            subtitle: InkWell(
                                              onTap: () {
                                                Navigator.push(context,
                                                    CupertinoPageRoute(
                                                        builder: (context) {
                                                  return PublicProfile(
                                                    userId: episodeObject
                                                            .episodeObject[
                                                        'user_id'],
                                                  );
                                                }));
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Text(
                                                  '${infos.current.audio.audio.metas.artist}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      height:
                                          MediaQuery.of(context).size.width / 2,
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              colors: [
                                            Colors.black,
                                            Colors.transparent
                                          ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter)),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Builder(
                              builder: (context) {
                                try {
                                  return episodeContent['permlink'] == null
                                      ? SizedBox()
                                      : Container(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              InkWell(
                                                onTap: () async {
                                                  if (hiveUsername != null) {
                                                    setState(() {
                                                      isUpvoteLoading = true;
                                                    });
                                                    double _value = 50.0;
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return Dialog(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              child: UpvoteEpisode(
                                                                  permlink:
                                                                      episodeContent[
                                                                          'permlink'],
                                                                  episode_id: int.parse(
                                                                      episodeObject
                                                                          .audioPlayer
                                                                          .current
                                                                          .value
                                                                          .audio
                                                                          .audio
                                                                          .metas
                                                                          .id)));
                                                        }).then((value) async {
                                                      print(value);
                                                    });
                                                    setState(() {
                                                      if (episodeObject
                                                              .ifVoted !=
                                                          true) {
                                                        episodeObject.ifVoted =
                                                            true;
                                                      }
                                                    });
                                                    setState(() {
                                                      isUpvoteLoading = false;
                                                    });
                                                  } else {
                                                    showBarModalBottomSheet(
                                                        context: context,
                                                        builder: (context) {
                                                          return HiveDetails();
                                                        });
                                                  }
                                                },
                                                child: Container(
                                                  decoration: episodeContent[
                                                              'ifVoted'] ==
                                                          true
                                                      ? BoxDecoration(
                                                          gradient: LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xff5bc3ef),
                                                                Color(
                                                                    0xff5d5da8)
                                                              ]),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30))
                                                      : BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  kSecondaryColor),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30)),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                    child: Row(
                                                      children: [
                                                        isUpvoteLoading == true
                                                            ? Container(
                                                                height: 17,
                                                                width: 18,
                                                                child:
                                                                    SpinKitPulse(
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                              )
                                                            : Icon(
                                                                FontAwesomeIcons
                                                                    .chevronCircleUp,
                                                                size: 15,
                                                                // color:
                                                                //     Color(0xffe8e8e8),
                                                              ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      8),
                                                          child: Text(
                                                            episodeContent[
                                                                    'votes']
                                                                .toString(),
                                                            textScaleFactor:
                                                                1.0,
                                                            style: TextStyle(
                                                                fontSize: 15
                                                                // color:
                                                                //     Color(0xffe8e8e8)
                                                                ),
                                                          ),
                                                        ),
                                                        Container(
                                                          height: 15,
                                                          width: 10,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border(
                                                                left:
                                                                    BorderSide(
                                                              color: themeProvider
                                                                          .isLightTheme ==
                                                                      false
                                                                  ? Colors.white
                                                                  : kPrimaryColor,
                                                            )),
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
                                                            style: TextStyle(
                                                              fontSize: 15,

                                                              // color:
                                                              //     Color(0xffe8e8e8)
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  SharedPreferences prefs =
                                                      await SharedPreferences
                                                          .getInstance();
                                                  if (prefs.getString(
                                                          'HiveUserName') !=
                                                      null) {
                                                    Navigator.push(
                                                        context,
                                                        CupertinoPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    Comments(
                                                                      episodeObject:
                                                                          episodeContent,
                                                                    )));
                                                  } else {
                                                    showBarModalBottomSheet(
                                                        context: context,
                                                        builder: (context) {
                                                          return HiveDetails();
                                                        });
                                                  }
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                                kSecondaryColor),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30)),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .mode_comment_outlined,
                                                            size: 15,
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        8),
                                                            child: Text(
                                                              episodeContent[
                                                                      'comments_count']
                                                                  .toString(),
                                                              textScaleFactor:
                                                                  1.0,
                                                              // style: TextStyle(
                                                              //      color: Color(0xffe8e8e8)
                                                              //     ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                } catch (e) {
                                  print("API call still Happening");
                                  return SizedBox();
                                }
                              },
                            ),
                          ),
                          Container(
                            // height: MediaQuery.of(context).size.height / 1.5,
                            decoration: BoxDecoration(
                              // boxShadow: [
                              //   new BoxShadow(
                              //     color: Colors.black54.withOpacity(0.2),
                              //     blurRadius: 10.0,
                              //   ),
                              // ],
                              // color: Color(0xff222222),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                episodeObject.audioPlayer
                                    .builderRealtimePlayingInfos(
                                        builder: (context, infos) {
                                  if (infos == null) {
                                    return SizedBox(
                                      height: 0,
                                    );
                                  } else {
                                    return Seekbar(
                                      dominantColor: dominantColor == null
                                          ? 0xff222222
                                          : dominantColor,
                                      currentPosition: infos.currentPosition,
                                      duration: infos.duration,
                                      episodeName: episodeObject.episodeName,
                                      seekTo: (to) {
                                        episodeObject.audioPlayer.seek(to);
                                      },
                                    );
                                  }
                                }),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 35,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      IconButton(
                                        icon: Icon(
                                          FontAwesomeIcons.fighterJet,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: kSecondaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    height: 380,
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 15,
                                                          vertical: 10),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          FlatButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "0.25X",
                                                                  textScaleFactor:
                                                                      0.75,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          FlatButton(
                                                            onPressed: () {
                                                              episodeObject
                                                                  .audioPlayer
                                                                  .setPlaySpeed(
                                                                      0.5);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "0.5X",
                                                                  textScaleFactor:
                                                                      0.75,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          FlatButton(
                                                            onPressed: () {
                                                              episodeObject
                                                                  .audioPlayer
                                                                  .setPlaySpeed(
                                                                      0.75);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "0.75X",
                                                                  textScaleFactor:
                                                                      0.75,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          FlatButton(
                                                            onPressed: () {
                                                              episodeObject
                                                                  .audioPlayer
                                                                  .setPlaySpeed(
                                                                      1.0);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "Normal",
                                                                  textScaleFactor:
                                                                      0.75,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          FlatButton(
                                                            onPressed: () {
                                                              episodeObject
                                                                  .audioPlayer
                                                                  .setPlaySpeed(
                                                                      1.25);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "1.25X",
                                                                  textScaleFactor:
                                                                      0.75,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          FlatButton(
                                                            onPressed: () {
                                                              episodeObject
                                                                  .audioPlayer
                                                                  .setPlaySpeed(
                                                                      1.5);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "1.5X",
                                                                  textScaleFactor:
                                                                      0.75,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          FlatButton(
                                                            onPressed: () {
                                                              episodeObject
                                                                  .audioPlayer
                                                                  .setPlaySpeed(
                                                                      2.0);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "2X",
                                                                  textScaleFactor:
                                                                      0.75,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7)),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.replay_10,
                                          //  color: Colors.white,
                                          size: 40,
                                        ),
                                        onPressed: () {
                                          episodeObject.audioPlayer
                                              .seekBy(Duration(seconds: -10));
                                        },
                                      ),
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
                                                  child: Icon(Icons.pause),
                                                  backgroundColor: Color(
                                                              dominantColor) ==
                                                          null
                                                      ? Colors.blue
                                                      : Color(dominantColor),
                                                  onPressed: () {
                                                    episodeObject.pause();
                                                    setState(() {
                                                      playerState =
                                                          PlayerState.paused;
                                                    });
                                                  });
                                            } else {
                                              return FloatingActionButton(
                                                  backgroundColor: Color(
                                                              dominantColor) ==
                                                          null
                                                      ? Colors.blue
                                                      : Color(dominantColor),
                                                  child: Icon(
                                                      Icons.play_arrow_rounded),
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
                                      IconButton(
                                        icon: Icon(
                                          Icons.forward_10,
                                          //  color: Colors.white,
                                          size: 40,
                                        ),
                                        onPressed: () {
                                          episodeObject.audioPlayer.seekBy(
                                            Duration(seconds: 10),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          share();
                                        },
                                        icon: Icon(
                                          Icons.ios_share,
                                          size: 18,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                transcript == null
                                    ? SizedBox()
                                    : Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(context,
                                                CupertinoPageRoute(
                                                    builder: (context) {
                                              print(transcript);
                                              print(transcript.runtimeType);
                                              return TrancriptionPlayer(
                                                transcript: transcript,
                                              );
                                            }));
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Color(0xff161616),
                                            ),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                4,
                                            width: double.infinity,
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "${transcript[currentIndex]['msg'].toString().trimLeft().trimRight()}",
                                                      textScaleFactor: 1.0,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              4),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      "${transcript[currentIndex + 1]['msg'].toString().trimLeft().trimRight()}",
                                                      textScaleFactor: 1.0,
                                                      style: TextStyle(
                                                          fontSize: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              4,
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.5)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                SizedBox(
                                  height: 50,
                                ),
                              ],
                            ),
                          ),
                          // DraggableScrollableSheet(
                          //     initialChildSize: 0.1,
                          //     maxChildSize: 1.0,
                          //     minChildSize: 0.1,
                          //     builder: (context, controller) {
                          //       return episodeObject.audioPlayer.builderCurrent(
                          //           builder: (context, Playing playing) {
                          //         return SongSelector(
                          //           audios: episodeObject.audioPlayer.playlist.audios ==
                          //                   null
                          //               ? <Audio>[]
                          //               : episodeObject.audioPlayer.playlist.audios,
                          //           onPlaylistSelected: (myAudios) {
                          //             episodeObject.audioPlayer.open(
                          //               Playlist(audios: myAudios),
                          //               showNotification: true,
                          //               headPhoneStrategy:
                          //                   HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
                          //               audioFocusStrategy: AudioFocusStrategy.request(
                          //                   resumeAfterInterruption: true),
                          //             );
                          //           },
                          //           onSelected: (myAudio) async {
                          //             try {
                          //               await episodeObject.audioPlayer.open(
                          //                 myAudio,
                          //                 autoStart: true,
                          //                 showNotification: true,
                          //                 playInBackground: PlayInBackground.enabled,
                          //                 audioFocusStrategy:
                          //                     AudioFocusStrategy.request(
                          //                         resumeAfterInterruption: true,
                          //                         resumeOthersPlayersAfterDone: true),
                          //                 headPhoneStrategy:
                          //                     HeadPhoneStrategy.pauseOnUnplug,
                          //                 notificationSettings: NotificationSettings(
                          //                     //seekBarEnabled: false,
                          //                     //stopEnabled: true,
                          //                     //customStopAction: (player){
                          //                     //  player.stop();
                          //                     //}
                          //                     //prevEnabled: false,
                          //                     //customNextAction: (player) {
                          //                     //  print('next');
                          //                     //}
                          //                     //customStopIcon: AndroidResDrawable(name: 'ic_stop_custom'),
                          //                     //customPauseIcon: AndroidResDrawable(name:'ic_pause_custom'),
                          //                     //customPlayIcon: AndroidResDrawable(name:'ic_play_custom'),
                          //                     ),
                          //               );
                          //             } catch (e) {
                          //               print(e);
                          //             }
                          //           },
                          //           playing: playing,
                          //         );
                          //       });
                          //     }),
                        ],
                      );
                    })),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: Container(
                  color: Color(0xff222222),
                  child: TabBar(controller: _playListTabController, tabs: [
                    Tab(
                      text: "UP NEXT",
                    ),
                    Tab(
                      text: "TRANSCRIPT",
                    ),
                    Tab(
                      text: "RELATED",
                    )
                  ]),
                ),
              ),
            )
          ];
        },
        body: TabBarView(
          controller: _playListTabController,
          children: [
            episodeObject.audioPlayer.builderCurrent(
              builder: (context, Playing playing) {
                return SongSelector(
                  audios: episodeObject.playList,
                  onPlaylistSelected: (myAudios) {
                    episodeObject.audioPlayer.open(
                      Playlist(audios: myAudios),
                      showNotification: true,
                      headPhoneStrategy:
                          HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
                      audioFocusStrategy: AudioFocusStrategy.request(
                          resumeAfterInterruption: true),
                    );
                  },
                  onSelected: (myAudio) async {
                    try {
                      await episodeObject.audioPlayer.open(
                        myAudio,
                        autoStart: true,
                        showNotification: true,
                        playInBackground: PlayInBackground.enabled,
                        audioFocusStrategy: AudioFocusStrategy.request(
                            resumeAfterInterruption: true,
                            resumeOthersPlayersAfterDone: true),
                        headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplug,
                        notificationSettings: NotificationSettings(
                            //seekBarEnabled: false,
                            //stopEnabled: true,
                            //customStopAction: (player){
                            //  player.stop();
                            //}
                            //prevEnabled: false,
                            //customNextAction: (player) {
                            //  print('next');
                            //}
                            //customStopIcon: AndroidResDrawable(name: 'ic_stop_custom'),
                            //customPauseIcon: AndroidResDrawable(name:'ic_pause_custom'),
                            //customPlayIcon: AndroidResDrawable(name:'ic_play_custom'),
                            ),
                      );
                    } catch (e) {
                      print(e);
                    }
                  },
                  playing: playing,
                );
              },
            ),
            Container(),
            Container(),
          ],
        ),
      ),
    );
  }
}

Widget buildSheet({
  @required num headerHeight,
  @required num fullHeight,
  @required Widget child,
}) {
  final fraction = headerHeight / fullHeight;

  return DraggableScrollableSheet(
    initialChildSize: fraction,
    minChildSize: fraction,
    builder: (_, scrollController) {
      return SingleChildScrollView(
        controller: scrollController,
        child: SizedBox(
          height: fullHeight,
          child: child,
        ),
      );
    },
  );
}

class TrancriptionPlayer extends StatefulWidget {
  var transcript;

  TrancriptionPlayer({@required this.transcript});

  @override
  _TrancriptionPlayerState createState() => _TrancriptionPlayerState();
}

class _TrancriptionPlayerState extends State<TrancriptionPlayer> {
  int currentIndex = 0;

  ItemScrollController itemScrollController;
  ItemPositionsListener itemPositionsListener;

  PlayerState playerState = PlayerState.playing;

  String actualText = '';

  List transcript = [];

  Widget _dialogContent(int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  "Replace previous selection?",
                  textAlign: TextAlign.center,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "This line is over the character limit and can't be added to your previous selection",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              color: Color(0xff161616),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context, false);
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context, true);

                      // setState(() {
                      //   if (index - snippet[snippet.length - 1]['index'] == 1) {
                      //     snippet.add(transcript[index]);
                      //     snippet.removeAt(0);
                      //   }
                      //   if (index - snippet[0]['index'] == -1) {
                      //     snippet = snippet.reversed.toList();
                      //     snippet.add(transcript[index]);
                      //     snippet.removeAt(0);
                      //     snippet = snippet.reversed.toList();
                      //   }
                      //   // if ((index - snippet[0]['index']) < -1) {
                      //   //   int difference = snippet[0]['index'] - index;
                      //   //   snippet = snippet.reversed.toList();
                      //   //   for (int i = difference; i >= 0; i--) {
                      //   //     snippet.add(transcript[index + i]);
                      //   //     snippetString = '';
                      //   //     for (var v in snippet) {
                      //   //       snippetString = snippetString + v['msg'];
                      //   //     }
                      //   //     if (snippetString.length > 150) {
                      //   //       snippet.removeAt(0);
                      //   //     }
                      //   //   }
                      //   //   snippet = snippet.toSet().toList().reversed.toList();
                      //   //   snippetString = '';
                      //   //   for (var v in snippet) {
                      //   //     snippetString = snippetString + v['msg'];
                      //   //   }
                      //   // }
                      //
                      //   for (var v in snippet) {
                      //     print(v['index']);
                      //   }
                      //
                      //   Navigator.pop(context);
                      // });
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Replace",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _selectionFunction(int index) async {
    // setState(() {
    //   if (snippet.length == 0) {
    //     snippet.add(transcript[index]);
    //   } else {
    //     if (snippet.contains(transcript[index]) == true) {
    //       snippet.remove(transcript[index]);
    //     } else {
    //       if (snippetString.length >= 150) {
    //         showDialog(
    //             context: context,
    //             builder: (context) {
    //               return Dialog(
    //                 backgroundColor: Color(0xff222222),
    //                 child: _dialogContent(index),
    //               );
    //             });
    //       } else {
    //         if (index - snippet[snippet.length - 1]['index'] == 1) {
    //           snippet.add(transcript[index]);
    //         }
    //         if (snippet[0]['index'] - index > 1) {
    //           snippet = snippet.reversed.toSet().toList();
    //           for (int i = (snippet[0]['index'] - 1); i >= index; i--) {
    //             snippet.add(transcript[i]);
    //           }
    //         }
    //       }
    //     }
    //   }
    //   snippetString = '';
    //   for (var v in snippet) {
    //     snippetString = snippetString + v['msg'];
    //   }
    //   print("$snippetString ////////////////////////");
    // });

    if (snippet.length == 0) {
      snippet.add(transcript[index]);
    } else {
      if (snippetString.length < 150) {
        if (snippet.contains(transcript[index])) {
          snippet = [transcript[index]];
        }
        if (index > snippet[snippet.length - 1]['index']) {
          for (int i = snippet[snippet.length - 1]["index"]; i <= index; i++) {
            snippet.add(transcript[i]);
          }
        }
        if (index < snippet[0]['index']) {
          var listElement = snippet[0];
          snippet = snippet.reversed.toList();
          for (int i = snippet[0]['index'] - 1; i >= index; i--) {
            snippet.add(transcript[i]);
          }
          snippet = snippet.toSet().toList().reversed.toList();

          // for (var v in snippet) {
          //   print(v['index']);
          // }
          // for (int i = snippet[snippet.length - 1]['index'];
          //     i > listElement['index'];
          //     i--) {
          //   snippet.remove(transcript[i]);
          // }
        }
      } else {
        if (snippet.contains(transcript[index])) {
          snippet = [transcript[index]];
        } else {
          showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: _dialogContent(index),
                );
              }).then((value) {
            if (value == true) {
              setState(() {
                if (index < snippet[0]['index']) {
                  snippet = snippet.reversed.toList();
                  for (int i = snippet[0]['index'] - 1; i >= index; i--) {
                    snippet.add(transcript[index]);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  while (snippetString.length > 150) {
                    snippet.removeAt(0);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  snippet = snippet.reversed.toList();
                  snippetString = '';
                  for (var v in snippet) {
                    snippetString = snippetString + v['msg'];
                  }
                }
                if (index > snippet[snippet.length - 1]['index']) {
                  for (int i = snippet[snippet.length - 1]['index'] + 1;
                      i <= index;
                      i++) {
                    snippet.add(transcript[i]);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  while (snippetString.length > 150) {
                    snippet.removeAt(0);
                    snippetString = '';
                    for (var v in snippet) {
                      snippetString = snippetString + v['msg'];
                    }
                  }
                  snippet = snippet.reversed.toList();
                  snippetString = '';
                  for (var v in snippet) {
                    snippetString = snippetString + v['msg'];
                  }
                }
              });
            }
          });
        }
      }

      // if (snippet.contains(transcript[index])) {
      //   for (int i = snippet[snippet.length - 1]['index']; i > index; i--) {
      //     snippet.remove(transcript[i]);
      //   }
      // }
    }
    // } else {
    //   showDialog(context: context, builder: (context){
    //     return Dialog(
    //       child: Text("Character Limit Exceeded 150"),
    //     );
    //   });
    // }
    snippetString = '';
    for (var v in snippet) {
      snippetString = snippetString + v['msg'];
    }
    print("$snippetString");
  }

  @override
  void initState() {
    // getTranscription(widget.episode_id);
    // TODO: implement initState

    super.initState();

    setState(() {
      transcript = widget.transcript;
      for (var v in transcript) {
        v['index'] = transcript.indexOf(v);
      }
    });

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    for (var v in widget.transcript) {
      actualText = actualText + v['msg'];
    }

    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();

    var episodeObject = Provider.of<PlayerChange>(context, listen: false);

    episodeObject.audioPlayer.currentPosition.listen((event) {
      var currentPositionSeconds = event.inMilliseconds / 1000;
      if (transcript != null && widget.transcript.length > 0) {
        if (transcript != null && transcript.length > 0) {
          var count = (transcript.indexWhere((element) =>
              element['start_time'] < currentPositionSeconds &&
              element['end_time'] > currentPositionSeconds));
          if (count >= 0) {
            print(count);

            setState(() {
              currentIndex = count;
            });

            itemScrollController.jumpTo(
              index: count,
              alignment: count < 10 ? 0.0 : 0.3,
            );
          }
        }
      }
    });
  }

  int dominantColor = 0xff222222;

  List snippet = [];
  String snippetString = '';

  bool isSelecting = false;

  ScrollController _scrollController;
  double _scrollPosition;

  _scrollListener() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);

    return Scaffold(
      appBar: AppBar(
        shadowColor: Color(0xff161616),
        toolbarHeight: MediaQuery.of(context).size.height / 10,
        automaticallyImplyLeading: false,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CachedNetworkImage(
            imageUrl: episodeObject.episodeObject['image'] == null
                ? episodeObject.episodeObject['podcast_image']
                : episodeObject.episodeObject['image'],
            imageBuilder: (context, imageProvider) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover)),
                width: MediaQuery.of(context).size.width / 10,
                height: MediaQuery.of(context).size.width / 10,
              );
            },
          ),
          title: Text(
            '${episodeObject.episodeName}',
            maxLines: 2,
            textScaleFactor: 1.0,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: SizeConfig.blockSizeHorizontal * 3,
                fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "${episodeObject.episodeObject['podcast_name']}",
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ScrollablePositionedList.builder(
                itemCount: transcript.length + 1,
                itemBuilder: (context, index) {
                  // print(itemPositionsListener.itemPositions.value.toString());
                  if (index == currentIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(8),
                              right: Radius.circular(8)),
                        ),
                        selectedTileColor: Colors.black54,
                        selected: snippet.contains(transcript[index]),
                        onTap: () {
                          setState(() {
                            _selectionFunction(index);
                          });
                        },
                        title: Text(
                          '${transcript[index]['msg'].toString().trimLeft().trimRight()}',
                          style: TextStyle(
                              height: 1.8,
                              fontSize: SizeConfig.safeBlockHorizontal * 6,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    );
                  } else {
                    if (index == transcript.length) {
                      return SizedBox(
                        height: 300,
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(8)),
                          ),
                          onTap: () {
                            setState(() {
                              _selectionFunction(index);
                            });
                          },
                          selectedTileColor: Colors.black54,
                          selected: snippet.contains(transcript[index]),
                          title: Text(
                            '${transcript[index]['msg'].toString().trimLeft().trimRight()}',
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 6,
                                fontWeight: FontWeight.w600,
                                height: 1.8,
                                color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                      );
                    }
                  }
                },
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xff161616),
                  ),

                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      snippet.length == 0
                          ? SizedBox()
                          : Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        snippet = [];
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                        Color(0xff5d5da8),
                                        Colors.red
                                      ])),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text("CANCEL"),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context,
                                          CupertinoPageRoute(
                                              builder: (context) {
                                        return EditSnippet(
                                          snippetString: snippetString,
                                          snippet: snippet,
                                        );
                                      }));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                        Color(0xff5d5da8),
                                        Color(0xff5bc3ef)
                                      ])),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text("CREATE CLIP"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      SizedBox(
                        height: 20,
                      ),
                      episodeObject.audioPlayer.builderRealtimePlayingInfos(
                          builder: (context, infos) {
                        if (infos == null) {
                          return SizedBox(
                            height: 0,
                          );
                        } else {
                          return Seekbar(
                            dominantColor: dominantColor,
                            currentPosition: infos.currentPosition,
                            duration: infos.duration,
                            episodeName: episodeObject.episodeName,
                            seekTo: (to) {
                              episodeObject.audioPlayer.seek(to);
                              itemScrollController.jumpTo(
                                index: currentIndex,

                                // curve: Curves.easeInCirc,
                              );
                            },
                          );
                        }
                      }),
                      episodeObject.audioPlayer.builderRealtimePlayingInfos(
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
                                  child: Icon(Icons.pause),
                                  backgroundColor: Colors.blue,
                                  onPressed: () {
                                    episodeObject.pause();
                                    setState(() {
                                      playerState = PlayerState.paused;
                                    });
                                  });
                            } else {
                              return FloatingActionButton(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.play_arrow_rounded),
                                  onPressed: () {
                                    // play(url);
                                    episodeObject.resume();
                                    setState(() {
                                      playerState = PlayerState.playing;
                                    });
                                  });
                            }
                          }
                        }
                      }),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                  // color: Colors.blue,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class EditSnippet extends StatefulWidget {
  String snippetString;
  List snippet;
  var snippetObject;
  bool isEditing;

  EditSnippet({this.snippetString, this.snippet});

  @override
  _EditSnippetState createState() => _EditSnippetState();
}

class _EditSnippetState extends State<EditSnippet> {
  TextEditingController controller;

  postreq.Interceptor intercept = postreq.Interceptor();

  String title;

  void addCLip() async {
    String url = 'https://api.aureal.one/private/createSnippet';
    var episodeObject = Provider.of<PlayerChange>(context, listen: false);
    var map = Map<String, dynamic>();
    map['episode_id'] = episodeObject.episodeObject['id'];
    map['words'] = widget.snippetString;
    map['start_time'] = widget.snippet[0]['start_time'];
    map['end_time'] = widget.snippet[widget.snippet.length - 1]['end_time'];
    map['title'] = title;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      Navigator.push(context, CupertinoPageRoute(builder: (context) {
        return ClipScreen();
      }));
    } catch (e) {
      print(e);
    }
  }

  String snippetText = '';
  @override
  void initState() {
    // TODO: implement initState
    controller = TextEditingController(
        text: "${widget.snippetString.trimLeft().trimRight()}");
    super.initState();
    setState(() {
      snippetText = widget.snippetString.trimRight().trimLeft();
    });
  }

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        title: Text(
          "Edit Clip",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Color(0xff222222),
                            borderRadius: BorderRadius.circular(5)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CachedNetworkImage(
                                imageUrl: episodeObject.episodeObject['image'],
                                imageBuilder: (context, imageProvider) {
                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.width / 6,
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${episodeObject.episodeObject['name']}",
                                        maxLines: 1,
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        "${episodeObject.episodeObject['podcast_name']}",
                                        textScaleFactor: 1.0,
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                title = value;
                              });
                            },
                            decoration: InputDecoration(
                                labelText: 'Give your snippet a title',
                                labelStyle: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 5)),
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 6),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "(Optional)",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          maxLength: 200,
                          onChanged: (value) {
                            setState(() {
                              snippetText = value;
                            });
                            print(snippetText);
                          },
                          controller: controller,
                          maxLines: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigator.push(context,
                      //     CupertinoPageRoute(builder: (context) {
                      //   return SnippetShare(snippet: snippetText);
                      // }));
                      addCLip();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Color(0xffe8e8e8),
                          borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        child: Text(
                          "Create",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: Color(0xff161616),
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SnippetShare extends StatefulWidget {
  var snippet;

  var episodeDetails;

  SnippetShare({@required this.snippet, @required this.episodeDetails});

  @override
  _SnippetShareState createState() => _SnippetShareState();
}

class _SnippetShareState extends State<SnippetShare> {
  ScreenshotController squareScreenshotController = ScreenshotController();
  ScreenshotController rectScreenshotController = ScreenshotController();

  Future<dynamic> ShowCapturedWidget(
      BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: true,
      context: context,
      builder: (context) {
        return Container(
          color: Color(0xff161616).withOpacity(0.7),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                height: MediaQuery.of(context).size.height * 0.75,
                width: MediaQuery.of(context).size.width * 0.75,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.memory(
                      capturedImage,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          onPressed: () {},
                          child: Icon(FontAwesomeIcons.square),
                        ),
                        FloatingActionButton(
                          onPressed: () {},
                          child: Icon(FontAwesomeIcons.react),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  bool isSquare = false;

  @override
  Widget build(BuildContext context) {
    var episodeObject = Provider.of<PlayerChange>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.black54,
                child: Icon(Icons.crop_square),
                onPressed: () {
                  setState(() {
                    isSquare = true;
                  });
                },
              ),
              FloatingActionButton(
                backgroundColor: Colors.black54,
                child: Icon(Icons.crop_16_9_outlined),
                onPressed: () {
                  // rectScreenshotController
                  //     .capture(delay: Duration(milliseconds: 10))
                  //     .then((capturedImage) async {
                  //   ShowCapturedWidget(context, capturedImage);
                  // }).catchError((onError) {
                  //   print(onError);
                  // });
                  setState(() {
                    isSquare = false;
                  });
                },
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () async {
                if (isSquare == true) {
                  // await squareScreenshotController
                  //     .capture(delay: Duration(milliseconds: 10))
                  //     .then((capturedImage) async {
                  //
                  //   // ShowCapturedWidget(context, capturedImage);
                  // }).catchError((onError) {
                  //   print(onError);
                  // });
                  await squareScreenshotController
                      .capture(delay: const Duration(milliseconds: 10))
                      .then((Uint8List image) async {
                    if (image != null) {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final imagePath =
                          await File('${directory.path}/image.png').create();
                      await imagePath.writeAsBytes(image);

                      /// Share Plugin
                      await Share.shareFiles([imagePath.path],
                          text:
                              "${widget.snippet['words'].toString().trimLeft().trimRight()} \n https://aureal.one/episode/${widget.episodeDetails['episode_id']} \n #YourVoiceIsworthSomething #Aureal");
                    }
                  });
                } else {
                  await rectScreenshotController
                      .capture(delay: const Duration(milliseconds: 10))
                      .then((Uint8List image) async {
                    if (image != null) {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final imagePath =
                          await File('${directory.path}/image.png').create();
                      await imagePath.writeAsBytes(image);

                      /// Share Plugin
                      await Share.shareFiles([imagePath.path],
                          text:
                              "${widget.snippet['words'].toString().trimLeft().trimRight()} \n https://aureal.one/episode/${widget.episodeDetails['episode_id']} \n #YourVoiceIsworthSomething #Aureal");
                    }
                  });
                  // await rectScreenshotController
                  //     .capture(delay: Duration(milliseconds: 10))
                  //     .then((capturedImage) async {
                  //
                  //   // ShowCapturedWidget(context, capturedImage);
                  // }).catchError((onError) {
                  //   print(onError);
                  // });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Color(0xff161616),
                ),
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Text(
                      "Share",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            isSquare == true
                ? Center(
                    child: Screenshot(
                      controller: squareScreenshotController,
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                              Color(0xff5d5da8),
                              Color(0xff5bc3ef)
                            ])),
                        width: MediaQuery.of(context).size.width * 1.1,
                        height: MediaQuery.of(context).size.width * 1.1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(10),
                                        topLeft: Radius.circular(10))),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 30),
                                  child: Column(
                                    children: [
                                      Icon(FontAwesomeIcons.quoteLeft),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 20),
                                        child: Text(
                                          "${widget.snippet['words']}",
                                          textScaleFactor: 1.0,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  5,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Icon(FontAwesomeIcons.quoteRight),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20, left: 40, right: 40),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10))),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8, bottom: 8, top: 8),
                                      child: Row(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: widget.episodeDetails[
                                                'podcast_image'],
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover),
                                                ),
                                              );
                                            },
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${widget.episodeDetails['episode_name']}",
                                                    maxLines: 1,
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff222222),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3),
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    "${widget.episodeDetails['podcast_name']}",
                                                    textScaleFactor: 1.0,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff222222),
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            2.5),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 5,
                                      bottom: 5,
                                      child: Image.asset(
                                        'assets/images/Favicon.png',
                                        cacheHeight: (MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                4)
                                            .floor(),
                                        height: 30,
                                        width: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Screenshot(
                    controller: rectScreenshotController,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xff5d5da8), Color(0xff5bc3ef)])),
                      child: Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      topLeft: Radius.circular(10))),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 30),
                                child: Column(
                                  children: [
                                    Icon(FontAwesomeIcons.quoteLeft),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 20),
                                      child: Text(
                                        "${widget.snippet['words']}",
                                        textScaleFactor: 1.0,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    5,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Icon(FontAwesomeIcons.quoteRight),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 20, left: 40, right: 40),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10))),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, right: 8, bottom: 8, top: 8),
                                    child: Row(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: widget
                                              .episodeDetails['podcast_image'],
                                          imageBuilder:
                                              (context, imageProvider) {
                                            return Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  6,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  6,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover),
                                              ),
                                            );
                                          },
                                        ),
                                        Flexible(
                                          child: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${widget.episodeDetails['episode_name']}",
                                                  maxLines: 1,
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      color: Color(0xff222222),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          3),
                                                ),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  "${widget.episodeDetails['podcast_name']}",
                                                  textScaleFactor: 1.0,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Color(0xff222222),
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          2.5),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 5,
                                    bottom: 5,
                                    child: Image.asset(
                                      'assets/images/Favicon.png',
                                      cacheHeight:
                                          (MediaQuery.of(context).size.height /
                                                  4)
                                              .floor(),
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10))),
                              height: MediaQuery.of(context).size.height / 3.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "#YourVoiceIsWorthSomething",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    "aureal.one",
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 4),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      )),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class ClipScreen extends StatefulWidget {
  @override
  _ClipScreenState createState() => _ClipScreenState();
}

class _ClipScreenState extends State<ClipScreen> {
  postreq.Interceptor intercept = postreq.Interceptor();

  var clips = [];

  void edit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  }

  void delete(var snippetId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/deleteSnippet';

    var map = Map<String, dynamic>();
    map['snippet_id'] = snippetId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  void getClips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getSnippet?user_id=${prefs.getString('userId')}";
    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          clips = jsonDecode(response.body)['snippets'];
          for (var v in clips) {
            v['isPlaying'] = false;
          }
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getClips();
  }

  int currentIndex = 0;

  ScrollController controller = ScrollController();

  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Your Clips",
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
          textScaleFactor: 1.0,
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        // child: ListView(
        //   children: [
        //     for (var v in clips) Text("${v.toString()}"),
        //     // Padding(
        //     //   padding: const EdgeInsets.all(15),
        //     //   child: Container(
        //     //     decoration: BoxDecoration(
        //     //         color: Colors.blue,
        //     //         borderRadius: BorderRadius.circular(10)),
        //     //     child: Column(
        //     //       mainAxisSize: MainAxisSize.min,
        //     //       children: [
        //     //         ListTile(
        //     //           leading: CachedNetworkImage(
        //     //             imageUrl: v['episode']['episode_image'],
        //     //             imageBuilder: (context, imageProvider) {
        //     //               return Container(
        //     //                 height: MediaQuery.of(context).size.width / 7,
        //     //                 width: MediaQuery.of(context).size.width / 7,
        //     //                 decoration: BoxDecoration(
        //     //                     borderRadius: BorderRadius.circular(5),
        //     //                     image: DecorationImage(
        //     //                         image: imageProvider, fit: BoxFit.cover)),
        //     //               );
        //     //             },
        //     //           ),
        //     //           title: Text(
        //     //             "${v['episode']['episode_name']}",
        //     //             maxLines: 2,
        //     //             overflow: TextOverflow.ellipsis,
        //     //             // textAlign: TextAlign.center,
        //     //             textScaleFactor: 1.0,
        //     //             style: TextStyle(
        //     //                 fontSize: SizeConfig.safeBlockHorizontal * 3,
        //     //                 fontWeight: FontWeight.bold),
        //     //           ),
        //     //         ),
        //     //         for (var a in v['snippet'])
        //     //           ListTile(
        //     //             leading: InkWell(
        //     //                 onTap: () {
        //     //                   if (a['isPlaying'] == false) {
        //     //                     audioPlayer.open(Audio.network(a['url']));
        //     //                     setState(() {
        //     //                       a['isPlaying'] = true;
        //     //                     });
        //     //                   } else {
        //     //                     setState(() {
        //     //                       a['isPlaying'] = false;
        //     //                     });
        //     //                     audioPlayer.stop();
        //     //                   }
        //     //                 },
        //     //                 child: Icon(a['isPlaying'] == true
        //     //                     ? Icons.pause
        //     //                     : Icons.play_circle_fill)),
        //     //           )
        //     //       ],
        //     //     ),
        //     //   ),
        //     // )
        //   ],
        // ),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 9 / 14,
          children: [
            for (var v in clips)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xff222222)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            CachedNetworkImage(
                              imageUrl: v['podcast_image'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  height: MediaQuery.of(context).size.width / 4,
                                  width: MediaQuery.of(context).size.width / 4,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
                                );
                              },
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "${v['episode_name']}",
                              textScaleFactor: 0.75,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                                onTap: () {
                                  if (v['isPlaying'] == false) {
                                    audioPlayer.open(Audio.network(v['url']));
                                    setState(() {
                                      v['isPlaying'] = true;
                                    });
                                  } else {
                                    setState(() {
                                      v['isPlaying'] = false;
                                    });
                                    audioPlayer.stop();
                                  }
                                },
                                child: Icon(v['isPlaying'] == true
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill)),
                            InkWell(
                                onTap: () {
                                  showBarModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              title: Text(
                                                "${v['episode_name']}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textScaleFactor: 1.0,
                                                style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3),
                                              ),
                                              trailing: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: CachedNetworkImage(
                                                  imageBuilder:
                                                      (context, imageProvider) {
                                                    return Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              10,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              10,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          image: DecorationImage(
                                                              image:
                                                                  imageProvider,
                                                              fit: BoxFit
                                                                  .cover)),
                                                    );
                                                  },
                                                  imageUrl: v['podcast_image'],
                                                ),
                                              ),
                                            ),
                                            Divider(),
                                            ListTile(
                                              onTap: () {
                                                delete(v['id']);
                                                Navigator.pop(context);
                                                getClips();
                                              },
                                              title: Text(
                                                "Delete",
                                                textScaleFactor: 1.0,
                                                style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3),
                                              ),
                                            ),
                                            ListTile(
                                              title: Text(
                                                "Share",
                                                textScaleFactor: 1.0,
                                                style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3),
                                              ),
                                            )
                                          ],
                                        );
                                      });
                                },
                                child: Icon(Icons.more_vert))
                          ],
                        )
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

class EditClip extends StatefulWidget {
  var episodeDetails;

  var clipDetails;

  EditClip({@required this.episodeDetails, @required this.clipDetails});

  @override
  _EditClipState createState() => _EditClipState();
}

class _EditClipState extends State<EditClip> {
  String title;

  TextEditingController titleController = TextEditingController();
  TextEditingController clipController = TextEditingController();

  postreq.Interceptor intercept = postreq.Interceptor();

  void editClip(var snippetId, var snippetTitle, var snippetWords) async {
    String url = "https://api.aureal.one/private/updateSnippet";

    var map = Map<String, dynamic>();

    map['snippet_id'] = snippetId;
    map['title'] = snippetTitle;
    map['words'] = snippetWords;

    FormData formData = FormData.fromMap(map);

    print(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      Navigator.pop(context, true);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      titleController.text =
          widget.clipDetails['title'].toString().trimRight().trimLeft();
      clipController.text =
          widget.clipDetails['words'].toString().trimLeft().trimRight();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Clip",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Color(0xff222222),
                            borderRadius: BorderRadius.circular(5)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CachedNetworkImage(
                                imageUrl: widget.episodeDetails['episode']
                                    ['podcast_image'],
                                imageBuilder: (context, imageProvider) {
                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.width / 6,
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${widget.episodeDetails['episode']['episode_name']}",
                                        maxLines: 1,
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        "${widget.episodeDetails['episode']['podcast_name']}",
                                        textScaleFactor: 1.0,
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: titleController,
                            onChanged: (value) {
                              setState(() {
                                title = value;
                              });
                            },
                            decoration: InputDecoration(
                                labelText: 'Title',
                                labelStyle: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 5)),
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 6),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "(Optional)",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: clipController,
                          maxLength: 200,
                          onChanged: (value) {
                            // setState(() {
                            //   snippetText = value;
                            // });
                            // print(snippetText);
                          },
                          // controller: controller,
                          maxLines: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigator.push(context,
                      //     CupertinoPageRoute(builder: (context) {
                      //   return SnippetShare(snippet: snippetText);
                      // }));
                      // addCLip();

                      editClip(widget.clipDetails['id'], titleController.text,
                          clipController.text);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Color(0xffe8e8e8),
                          borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        child: Text(
                          "Update",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: Color(0xff161616),
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SongSelector extends StatelessWidget {
  final Playing playing;
  final List<Audio> audios;
  final Function(Audio) onSelected;
  final Function(List<Audio>) onPlaylistSelected;

  const SongSelector(
      {this.playing, this.audios, this.onSelected, this.onPlaylistSelected});

  Widget _image(Audio item) {
    if (item.metas.image == null) {
      return SizedBox(height: 40, width: 40);
    }

    return item.metas.image?.type == ImageType.network
        ? Image.network(
            item.metas.image.path,
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          )
        : Image.asset(
            item.metas.image.path,
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          );
  }

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    return Container(
      color: Color(0xff222222),
      height: MediaQuery.of(context).size.height,
      child: ListView.builder(
        shrinkWrap: true,
        // physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, position) {
          final item = audios[position];
          final isPlaying = item.path == playing?.audio.assetAudioPath;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
                selectedTileColor: Color(0xff161616),
                selected: currentlyPlaying
                            .audioPlayer.current.value.audio.audio.metas.id ==
                        currentlyPlaying.playList[position].metas.id
                    ? true
                    : false,
                leading: Material(
                  clipBehavior: Clip.antiAlias,
                  child: _image(item),
                ),
                title: Text(item.metas.title.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xffe8e8e8),
                    )),
                onTap: () {
                  onSelected(item);
                }),
          );
        },
        itemCount: audios.length,
      ),
    );
  }
}
