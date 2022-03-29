import 'dart:convert';
import 'dart:io';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/screens/recorderApp/RecorderDashboard.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:provider/provider.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:assets_audio_player/assets_audio_player.dart';

class AddBackgroundMusic extends StatefulWidget {
  var libraryObject;

  AddBackgroundMusic({this.libraryObject});

  static const String id = 'backgroundMusic';

  @override
  _AddBackgroundMusicState createState() => _AddBackgroundMusicState();
}

class _AddBackgroundMusicState extends State<AddBackgroundMusic> {
  postreq.Interceptor intercept = postreq.Interceptor();

  AssetsAudioPlayer player = AssetsAudioPlayer();

  Dio dio = Dio();

  bool isAdded = false;
  bool isRemoved = false;

  String currentBackgroundMusic;
  double musicDuration;
  String previewUrl;
  bool isGettingData = false;
  int associationId;

  var currentlyPlaying;

  var backgroundMusicList = [];
  bool isPlaying = false;

  void getMusic() async {
    setState(() {
      isGettingData = true;
      associationId =
          (widget.libraryObject['association_id'].runtimeType).toString() ==
                  'String'
              ? int.parse(widget.libraryObject['association_id'])
              : widget.libraryObject['association_id'];
    });
    print(associationId);
    String url = 'https://api.aureal.one/public/getSound';
    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['allSounds'];
      setState(() {
        backgroundMusicList = data;
        isGettingData = false;
        for (var v in backgroundMusicList) {
          v['isPlaying'] = isPlaying;
        }
      });

      if (widget.libraryObject['SoundId'] != null) {
        var v = backgroundMusicList
            .where((f) => f['id'] == widget.libraryObject['SoundId'])
            .toList();
//        print(widget.libraryObject['background_sound_id']);
//      print(v.length);
        setState(() {
          currentBackgroundMusic = v[0]['name'];
          musicDuration = double.parse(v[0]['duration']);
        });
      }
    } else {
      print(response.statusCode);
    }
  }

  bool isLoading;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    player.stop();
  }

  void addBackgroundMusic(
      {int libraryId,
      int backgroundMusicId,
      int episodeId,
      String backgroundMusicName,
      double backgroundMusicDuration,
      int associationId}) async {
    setState(() {
      isLoading = true;
    });

    String url = "https://api.aureal.one/private/addBackgroundSound";

    var map = Map<String, dynamic>();
    map['library_id'] = libraryId;
    map['sound_id'] = backgroundMusicId;
    map['editor_id'] = widget.libraryObject['editor_id'];
    map['association_id'] = associationId;

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.data);
    if (response.statusCode == 200) {
      setState(() {
        currentBackgroundMusic = backgroundMusicName;
        musicDuration = backgroundMusicDuration;
        previewUrl = response.data['library']['url'];
        isAdded = true;
        isLoading = false;
      });
      Navigator.pop(context);
      Navigator.pop(context, response.data['library']);
    }
  }

  void removeBackgroundMusic({int libraryId, int episodeId}) async {
    setState(() {
      isLoading = true;
    });

    String url = "https://api.aureal.one/private/removeBackgroundSound";

    var map = Map<String, dynamic>();
    map['library_id'] = libraryId;
    map['episode_id'] = episodeId;
    map['association_id'] = associationId;

    FormData formData = FormData.fromMap(map);
    print(map.toString());

    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
    setState(() {
      musicDuration = null;
      isRemoved = true;
      isLoading = false;
    });
    Navigator.pop(context, response.data['library']);
  }

  Future _play(String url, var v) async {
    await player.stop();
    player.open(Audio(url));
    setState(() {
      currentlyPlaying = v;
      currentlyPlaying['isPlaying'] = true;
    });
  }

  Future _stop(var v) async {
    player.stop();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMusic();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text(
          'Add background music',
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
        centerTitle: true,
      ),
      body: isGettingData == true
          ? ListView.builder(
              itemCount: 100,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 5),
                    child: Shimmer.fromColors(
                      baseColor: Colors.white,
                      highlightColor: Colors.white30,
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey, width: 2)),
                        height: 80,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 25,
                                  ),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2,
                                        height: 8,
                                        color: Colors.white30,
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        height: 8,
                                        color: Colors.white30,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              Icon(Icons.more_vert)
                            ],
                          ),
                        ),
                      ),
                    ));
              })
          : ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Current Music',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                        ),
                      ),
                      widget.libraryObject['SoundId'] == null
                          ? Container(
                              height: 80,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey, width: 2)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      backgroundColor: Colors.white30,
                                      radius: 15,
                                      child: Icon(
                                        Icons.clear,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    Text(
                                      "No background music",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            player.open(Audio(previewUrl));
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: kPrimaryColor,
                                            radius: 25,
                                            child: Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              currentBackgroundMusic,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3.4,
                                              ),
                                            ),
//                                            Text(
//                                              '${DurationCalculator(musicDuration)}',
//                                              style: TextStyle(
//                                                  fontWeight: FontWeight.w400,
//                                                  fontSize: SizeConfig
//                                                          .safeBlockHorizontal *
//                                                      3),
//                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: <Widget>[
                                        IconButton(
                                          onPressed: () {
                                            removeBackgroundMusic(
                                                libraryId:
                                                    widget.libraryObject['id'],
                                                episodeId: widget.libraryObject[
                                                    'editor_id']);
                                          },
                                          icon: Icon(
                                            FontAwesomeIcons.timesCircle,
                                            color: Colors.black,
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Music',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                        ),
                      ),
                      for (var v in backgroundMusicList)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      GestureDetector(
                                        onTap: () async {
//                                          _play(v['url']);
                                          if (player.isPlaying == true) {
                                            await _stop(currentlyPlaying);
                                          } else {
                                            _play(v['url'], v);
                                          }
                                        },
                                        child: CircleAvatar(
                                          key: ValueKey(v),
                                          backgroundColor: kPrimaryColor,
                                          radius: 25,
                                          child: v['isPlaying'] == false
                                              ? Icon(Icons.play_arrow,
                                                  color: Colors.white)
                                              : Icon(
                                                  Icons.pause,
                                                  color: Colors.white,
                                                ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            v['name'],
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3.2),
                                          ),
                                          Text(
                                            '${DurationCalculator(v['duration'])}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return Dialog(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30)),
                                                    height: 100,
                                                    width: double.infinity,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  vertical: 10),
                                                          child: Text(
                                                            'Adding Music to Recording segment',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .black54,
                                                                fontSize: SizeConfig
                                                                        .safeBlockHorizontal *
                                                                    3.5),
                                                          ),
                                                        ),
                                                        Container(
                                                          color: Colors.white,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                            child:
                                                                LinearProgressIndicator(
                                                              backgroundColor:
                                                                  Colors.blue,
                                                              minHeight: 10,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Color(
                                                                          0xff6249EF)),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              });
//                                          print(
//                                              widget.libraryObject.toString());
                                          print(associationId);
                                          addBackgroundMusic(
                                              libraryId:
                                                  widget.libraryObject['id'],
                                              backgroundMusicId: v['id'],
                                              episodeId: widget
                                                  .libraryObject['editor_id'],
                                              backgroundMusicDuration:
                                                  double.parse(
                                                      v['duration'].toString()),
                                              backgroundMusicName: v['name'],
                                              associationId: associationId);
                                        },
                                        icon: Icon(
                                          Icons.add_circle,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                              context: context,
                                              builder: (context) {
                                                return Container(
                                                  height: 120,
                                                  child: Container(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 20),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        20),
                                                            child: Text(
                                                                "Audio Options"),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
//                                                    deleteLibraryElement(
//                                                        v['id']);
                                                              print(
                                                                  "element deleted: ${v['id']}");
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Row(
                                                              children: <
                                                                  Widget>[
                                                                Icon(
                                                                    Icons.star),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Text(
                                                                  "Add to favourites",
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          18),
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
                                        icon: Icon(
                                          Icons.more_vert,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
