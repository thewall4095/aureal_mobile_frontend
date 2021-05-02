import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayer/audioplayer.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:file_picker/file_picker.dart';

enum PlayerState {
  playing,
  paused,
}

class Sounds extends StatefulWidget {
  @override
  _SoundsState createState() => _SoundsState();
}

class _SoundsState extends State<Sounds> {
  postreq.Interceptor intercept = postreq.Interceptor();

  var loggedInUser;
  var episodeList = [];
  String token;

  var soundCategories = [];

  Dio dio = Dio();

  List soundsData;
  bool isLoading;

  PlayerState playerstate = PlayerState.paused;

  Widget _playIcon = Icon(Icons.play_arrow);

  var soundList = [];
  var customSounds = [];

  ////////////////Implementing file picker

  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.audio;
  TextEditingController _controller = new TextEditingController();

  void _openFileExplorer() async {
    setState(() => _loadingPath = true);
    try {
      if (_multiPick) {
        _path = null;
        _paths = (await FilePicker.platform.pickFiles(
            type: _pickingType,
            allowedExtensions: (_extension?.isNotEmpty ?? false)
                ? _extension?.replaceAll(' ', '')?.split(',')
                : null)) as Map<String, String>;
        // _paths = await FilePicker.platform.pickFiles(
        //     type: _pickingType,
        //     allowedExtensions: (_extension?.isNotEmpty ?? false)
        //         ? _extension?.replaceAll(' ', '')?.split(',')
        //         : null);
      } else {
        _paths = null;
        _path = (await FilePicker.platform.pickFiles(
            type: _pickingType,
            allowedExtensions: (_extension?.isNotEmpty ?? false)
                ? _extension?.replaceAll(' ', '')?.split(',')
                : null)) as String;
        // _path = await FilePicker.platform.pickFiles(
        //     type: _pickingType,
        //     allowedExtensions: (_extension?.isNotEmpty ?? false)
        //         ? _extension?.replaceAll(' ', '')?.split(',')
        //         : null);
      }
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) return;
    setState(() {
      _loadingPath = false;
      _fileName = _path != null
          ? _path.split('/').last
          : _paths != null
              ? _paths.keys.toString()
              : '...';
    });
    print(_fileName);
    print(_path);

    await _upload();
    getData();
  }

  Future _upload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/addCustomSound';

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
//    map['name'] = _fileName;
//    map['duration'] = '00000';
    map['soundBlob'] = await MultipartFile.fromFile(_path,
        filename: _fileName); //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
//    getCurrentUser();
  }

  /////////////////////////////////////////////////////////////////---------------Get Data--------------///////////////////////////////////////////////////////
  void getCurrentUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getString('userId') != null) {
        setState(() {
          loggedInUser = prefs.getString('userId');
          token = prefs.getString('token');
        });
      }
    } catch (e) {
      print(e);
    }
  }

  /////////////////////////////////////////////////////////////////---------------Get Data--------------//////////////////////////////////////////////////////////

  void getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer ${prefs.getString('token')}"
    };

    setState(() {
      isLoading = true;
    });
//    getCurrentUser();
    http.Response response = await http.get(
        Uri.parse(
            'https://api.aureal.one/public/getSound?user_id=${prefs.getString('userId')}'),
        headers: header);

    if (response.statusCode == 200) {
      var data = json.decode(response.body)['allSounds'];
      var data1 = json.decode(response.body)['customSounds'];
      for (var v in data) {
        v['isPlaying'] = false;
        soundCategories.add(v['category']);
      }
      print(soundCategories.toSet().toList());
      for (var v in data1) {
        v['isPlaying'] = false;
      }
      print(data);
      setState(() {
        soundList = data;
        customSounds = data1;
      });
      getEpisodesList();
      setState(() {
        isLoading = false;
      });
    } else {
      print(response.statusCode);
    }
  }

  //////////////////////////////////////////////////////////////-----------------_play Audio---------------////////////////////////////////////////////////////////
  void _play(String url) {
    AudioPlayer player = AudioPlayer();
    player.play(url, isLocal: false);
//    setState(() {
//      print(_recording.path);
//    });
  }

  //////////////////////////////////////////////////////////////-----------------Pause Audio---------------////////////////////////////////////////////////////

  Future _pause() async {
    AudioPlayer player = AudioPlayer();
    player.pause();
  }

  //////////////////////////////////////////////////////////////-----------------Stop Audio---------------////////////////////////////////////////////////////

  void _stop() {
    AudioPlayer player = AudioPlayer();
    player.stop();
  }

  //////////////////////////////////////////////////////////////-----------------Add Sounds to Editor---------------////////////////////////////////////////////////////

  void postSound(int id, int eID) async {
    String url = "https://api.aureal.one/private/addSound";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['sound_id'] = id;
    map['episode_id'] = eID;
    //_audioBytes.toString();

    print(map.toString());
//    print(map['library_id']);
//    print(map['episode_id']);

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);

    print(response.data.toString());
  }

  void getEpisodesList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer ${prefs.getString('token')}"
    };

    String url =
        "https://api.aureal.one/private/episode?user_id=${prefs.getString('userId')}";

    http.Response response = await http.get(Uri.parse(url), headers: header);
    print(response.body);

    var data = json.decode(response.body)['episodes'];
    setState(() {
      episodeList = data ?? [];
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.navigate_before,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        title: Text(
          "Sounds",
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _openFileExplorer();
                },
                child: Text(
                  "Import",
                  style: TextStyle(color: kActiveColor),
                ),
              ),
            ),
          )
        ],
      ),
      body: isLoading == true
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
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Custom Sounds',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    for (var v in customSounds)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        if (v['isPlaying'] == false) {
                                          _play(v['url']);
                                          setState(() {
                                            v['isPlaying'] = true;
                                          });
                                        } else {
                                          _stop();
                                          setState(() {
                                            v['isPlaying'] = false;
                                          });
                                        }
                                      },
                                      child: CircleAvatar(
                                        radius: 25,
                                        child: Icon(
                                          v['isPlaying'] == false
                                              ? Icons.play_arrow
                                              : Icons.pause,
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
                                          v['name'].toString().split('.')[0],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          v['duration'].toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                            context: context,
                                            builder: (context) {
                                              return Scaffold(
                                                  body: SafeArea(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 20.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 30),
                                                        child: Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              "Select Episodes to add this segment",
                                                              style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            )),
                                                      ),
                                                      SizedBox(
                                                        height: 20,
                                                      ),
                                                      Expanded(
                                                        child: ListView(
                                                          scrollDirection:
                                                              Axis.vertical,
                                                          children: <Widget>[
                                                            for (var a
                                                                in episodeList)
                                                              Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      vertical:
                                                                          10),
                                                                  child:
                                                                      GestureDetector(
                                                                    onTap: () {
//                                                              setState(() {
//                                                                episodeId =
//                                                                    v['id'];
//                                                              });
                                                                      print(v[
                                                                          'id']);
                                                                      print(a[
                                                                          'id']);
                                                                      postSound(
                                                                          v['id'],
                                                                          a['id']);
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      decoration: BoxDecoration(
                                                                          borderRadius: BorderRadius.circular(
                                                                              10),
                                                                          color:
                                                                              kActiveColor.withOpacity(0.5)),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(8.0),
                                                                        child:
                                                                            Row(
                                                                          children: <
                                                                              Widget>[
                                                                            CircleAvatar(
                                                                              backgroundColor: kActiveColor,
                                                                              backgroundImage: a['url'] == null ? null : NetworkImage(a['url']),
                                                                            ),
                                                                            SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: <Widget>[
                                                                                Text(
                                                                                  a['name'],
                                                                                  style: TextStyle(fontSize: 18),
                                                                                ),
                                                                                Text("Last Update at: ${a['updatedAt'].toString()}")
                                                                              ],
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ))
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ));
                                            });
                                        print("add button is pressed");
//                                postLibrary(v['id'], episodeId);
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
                                                                  vertical: 20),
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
                                                            children: <Widget>[
                                                              Icon(Icons.star),
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
                      ),
                    for (var t in soundCategories.toSet().toList())
                      Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  t,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: <Widget>[
                              for (var v in soundList)
                                v['category'] != t
                                    ? SizedBox(
                                        height: 0,
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 0, 20, 10),
                                        child: Container(
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    GestureDetector(
                                                      onTap: () {
                                                        if (v['isPlaying'] ==
                                                            false) {
                                                          _play(v['url']);
                                                          setState(() {
                                                            v['isPlaying'] =
                                                                true;
                                                          });
                                                        } else {
                                                          _stop();
                                                          setState(() {
                                                            v['isPlaying'] =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                      child: CircleAvatar(
                                                        radius: 25,
                                                        child: Icon(
                                                          v['isPlaying'] ==
                                                                  false
                                                              ? Icons.play_arrow
                                                              : Icons.pause,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        Text(
                                                          v['name'],
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          v['duration']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: <Widget>[
                                                    IconButton(
                                                      onPressed: () {
                                                        showModalBottomSheet(
                                                            context: context,
                                                            builder: (context) {
                                                              return Scaffold(
                                                                  body:
                                                                      SafeArea(
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          20.0),
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: <
                                                                        Widget>[
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 30),
                                                                        child: Align(
                                                                            alignment: Alignment.centerLeft,
                                                                            child: Text(
                                                                              "Select Episodes to add this segment",
                                                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                            )),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            ListView(
                                                                          scrollDirection:
                                                                              Axis.vertical,
                                                                          children: <
                                                                              Widget>[
                                                                            for (var a
                                                                                in episodeList)
                                                                              Padding(
                                                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                                                  child: GestureDetector(
                                                                                    onTap: () {
//                                                              setState(() {
//                                                                episodeId =
//                                                                    v['id'];
//                                                              });
                                                                                      print(v['id']);
                                                                                      print(a['id']);
                                                                                      postSound(v['id'], a['id']);
                                                                                      Navigator.pop(context);
                                                                                    },
                                                                                    child: Container(
                                                                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: kActiveColor.withOpacity(0.5)),
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.all(8.0),
                                                                                        child: Row(
                                                                                          children: <Widget>[
                                                                                            CircleAvatar(
                                                                                              backgroundColor: kActiveColor,
                                                                                              backgroundImage: a['url'] == null ? null : NetworkImage(a['url']),
                                                                                            ),
                                                                                            SizedBox(
                                                                                              width: 10,
                                                                                            ),
                                                                                            Column(
                                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                                              children: <Widget>[
                                                                                                Text(
                                                                                                  a['name'],
                                                                                                  style: TextStyle(fontSize: 18),
                                                                                                ),
                                                                                                Text("Last Update at: ${a['updatedAt'].toString()}")
                                                                                              ],
                                                                                            )
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ))
                                                                          ],
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ));
                                                            });
                                                        print(
                                                            "add button is pressed");
//                                postLibrary(v['id'], episodeId);
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
                                                                child:
                                                                    Container(
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        left:
                                                                            20),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: <
                                                                          Widget>[
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.symmetric(vertical: 20),
                                                                          child:
                                                                              Text("Audio Options"),
                                                                        ),
                                                                        GestureDetector(
                                                                          onTap:
                                                                              () {
//                                                    deleteLibraryElement(
//                                                        v['id']);
                                                                            print("element deleted: ${v['id']}");
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              Row(
                                                                            children: <Widget>[
                                                                              Icon(Icons.star),
                                                                              SizedBox(
                                                                                width: 10,
                                                                              ),
                                                                              Text(
                                                                                "Add to favourites",
                                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                                      ),
                            ],
                          )
                        ],
                      ),
                  ],
                )
              ],
            ),
    );
  }
}

//class Sound {
////  final int id;
////  final String name;
////  final String Category;
////  final String duration;
////  final String url;
////
////  Sound(this.id, this.Category, this.duration, this.name, this.url);
////}

class Sound {
  List<AllSounds> allSounds;

  Sound({this.allSounds});

  Sound.fromJson(Map<String, dynamic> json) {
    if (json['allSounds'] != null) {
      allSounds = new List<AllSounds>();
      json['allSounds'].forEach((v) {
        allSounds.add(new AllSounds.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.allSounds != null) {
      data['allSounds'] = this.allSounds.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AllSounds {
  int id;
  String name;
  String category;
  String duration;
  String url;
  String createdAt;
  String updatedAt;

  AllSounds(
      {this.id,
      this.name,
      this.category,
      this.duration,
      this.url,
      this.createdAt,
      this.updatedAt});

  AllSounds.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    category = json['category'];
    duration = json['duration'];
    url = json['url'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['category'] = this.category;
    data['duration'] = this.duration;
    data['url'] = this.url;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
