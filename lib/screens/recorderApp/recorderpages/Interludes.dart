import 'dart:convert';
import 'dart:io';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayer/audioplayer.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:file_picker/file_picker.dart';
import 'package:collection/collection.dart';

class Interludes extends StatefulWidget {
  @override
  _InterludesState createState() => _InterludesState();
}

class _InterludesState extends State<Interludes> {
  postreq.Interceptor intercept = postreq.Interceptor();

  String token;

  String currentEpisode;
  int currentEpisodeId;

  var loggedInUser;
  var episodeList = [];

  var interludeCategories = [];

  Dio dio = Dio();

  bool isLoading;

  //Impementing filepicker

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
      } else {
        _paths = null;
        _path = (await FilePicker.platform.pickFiles(
            type: _pickingType,
            allowedExtensions: (_extension?.isNotEmpty ?? false)
                ? _extension?.replaceAll(' ', '')?.split(',')
                : null)) as String;
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

    _upload();
    getData();
  }

  Future _upload() async {
    String url = 'https://api.aureal.one/private/addCustomInterlude';

    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
//    map['name'] = _fileName;
//    map['duration'] = '00000';
    map['interludeBlob'] = await MultipartFile.fromFile(_path,
        filename: _fileName); //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
//    getCurrentUser();
  }

//  List soundsData;

//  PlayerState playerstate = PlayerState.paused;

  Widget _playIcon = Icon(Icons.play_arrow);

  var interludeList = [];
  var customInterludes = [];

  /////////////////////////////////////////////////////////////////---------------Get Data--------------///////////////////////////////////////////////////////

  void getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      if (prefs.containsKey('userId')) {
        setState(() {
          loggedInUser = prefs.getString('userId');
        });
      }
    } catch (e) {
      print(e);
    }
  }

  /////////////////////////////////////////////////////////////////---------------Get Data--------------//////////////////////////////////////////////////////////

  void getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = true;
    });
    getCurrentUser();
    http.Response response = await http.get(Uri.parse(
        'https://api.aureal.one/public/getInterlude?user_id=${prefs.getString(('userId'))}'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body)['allInterludes'];
      var data1 = json.decode(response.body)['customInterludes'];

      for (var v in data) {
        v['isPlaying'] = false;
        interludeCategories.add(v['category']);
      }
      for (var v in data1) {
        v['isPlaying'] = false;
      }
      print(response.body.toString());
      setState(() {
        interludeList = data;
        customInterludes = data1;
        currentEpisode = prefs.getString('currentEpisodeName');
        currentEpisodeId = int.parse(prefs.getString('currentEpisodeId'));
      });
      getEpisodes();
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

  void _stop() {
    AudioPlayer player = AudioPlayer();
    player.stop();
  }

  //////////////////////////////////////////////////////////////-----------------Pause Audio---------------////////////////////////////////////////////////////

  Future _pause() async {
    AudioPlayer player = AudioPlayer();
    player.pause();
  }

  //////////////////////////////////////////////////////////////-----------------Stop Audio---------------////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////-----------------Add Sounds to Editor---------------////////////////////////////////////////////////////

  void postInterlude(int id, int eID) async {
    String url = "https://api.aureal.one/private/addInterlude";
    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['interlude_id'] = id;
    map['episode_id'] = eID;
    //_audioBytes.toString();

    print(map.toString());
//    print(map['library_id']);
//    print(map['episode_id']);

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
  }

//  void getEpisodesList() async {
//    String url =
//        "https://api.aureal.one/public/episode?user_id=${loggedInUser}";
//
//    http.Response response = await http.get(Uri.parse(url));
//    print(response.body);
//
//    var data = json.decode(response.body)['episodes'];
//    setState(() {
//      episodeList = data ?? [];
//    });
//  }

  void getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
    print(token);
  }

  void getEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await getLocalData();
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer $token"
    };

    print(loggedInUser);

    print(header.toString());

    print("initialising get episode");
    String url =
        "https://api.aureal.one/private/episode?user_id=${loggedInUser}";
    http.Response response = await http.get(Uri.parse(url), headers: header);
    print(response.body);

    var data = json.decode(response.body);
    if (response.statusCode == 200) {
      setState(() {
        episodeList = data['episodes'];
      });
    } else {
      print(response.statusCode.toString());
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
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
          "Transitions",
          style: TextStyle(
            color: Colors.white,
            fontSize: SizeConfig.safeBlockHorizontal * 4,
          ),
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
                  style: TextStyle(
                    color: kActiveColor,
                    fontSize: SizeConfig.safeBlockHorizontal * 3,
                  ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Custom Transitions",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.safeBlockHorizontal * 3),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    for (var v in customInterludes)
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
                                          v['name'].toString().split(".")[0],
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3.4,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${DurationCalculator(v['duration'])}',
                                          style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3,
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
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  height: 200,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 30),
                                                        child: Text(
                                                          "Add to episode",
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                      Column(
                                                        children: <Widget>[
                                                          Text(
                                                            "This episode will be added to ",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black54),
                                                          ),
                                                          Text(
                                                            "${currentEpisode}",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        8),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <
                                                                  Widget>[
                                                                GestureDetector(
                                                                    onTap: () {
                                                                      Navigator.pop(
                                                                          context);
                                                                      showModalBottomSheet(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return Scaffold(
                                                                                backgroundColor: Colors.white,
                                                                                body: SafeArea(
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                                                                    child: Column(
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      children: <Widget>[
                                                                                        Padding(
                                                                                          padding: const EdgeInsets.only(top: 30),
                                                                                          child: Align(
                                                                                              alignment: Alignment.centerLeft,
                                                                                              child: Text(
                                                                                                "Select Episodes to add this segment",
                                                                                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black54),
                                                                                              )),
                                                                                        ),
                                                                                        SizedBox(
                                                                                          height: 20,
                                                                                        ),
                                                                                        Expanded(
                                                                                          child: ListView(
                                                                                            scrollDirection: Axis.vertical,
                                                                                            children: <Widget>[
                                                                                              for (var a in episodeList)
                                                                                                Padding(
                                                                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                                                                    child: GestureDetector(
                                                                                                      onTap: () {
//
                                                                                                        print(v['id']);
                                                                                                        print(a['id']);
                                                                                                        postInterlude(
//
                                                                                                            v['id'],
                                                                                                            a['id']);
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
                                                                                                                  Text("Last Update at: ${a['updatedAt'].toString().split('T')[0]}")
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
//
                                                                    },
                                                                    child: Icon(
                                                                      Icons
                                                                          .settings,
                                                                      color: Colors
                                                                          .black54,
                                                                    )),
                                                              ],
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              postInterlude(
                                                                  v['id'],
                                                                  currentEpisodeId);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color:
                                                                      kActiveColor,
                                                                  borderRadius: BorderRadius.only(
                                                                      bottomLeft:
                                                                          Radius.circular(
                                                                              10),
                                                                      bottomRight:
                                                                          Radius.circular(
                                                                              10))),
                                                              height: 50,
                                                              width: double
                                                                  .infinity,
                                                              child: Center(
                                                                child: Text(
                                                                  "Add recording to episode",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          15),
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });
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
                    for (var t in interludeCategories.toSet().toList())
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
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: <Widget>[
                              for (var v in interludeList)
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
                                                          v['name']
                                                              .toString()
                                                              .split(".")[0],
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          softWrap: true,
                                                          style: TextStyle(
                                                            fontSize: SizeConfig
                                                                    .safeBlockHorizontal *
                                                                3.4,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${DurationCalculator(v['duration'])}',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
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
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                child:
                                                                    Container(
                                                                  decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10)),
                                                                  height: 200,
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: <
                                                                        Widget>[
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 30),
                                                                        child:
                                                                            Text(
                                                                          "Add to episode",
                                                                          style: TextStyle(
                                                                              fontSize: 18,
                                                                              fontWeight: FontWeight.w600),
                                                                        ),
                                                                      ),
                                                                      Column(
                                                                        children: <
                                                                            Widget>[
                                                                          Text(
                                                                            "This episode will be added to ",
                                                                            style:
                                                                                TextStyle(color: Colors.black54),
                                                                          ),
                                                                          Text(
                                                                            "${currentEpisode}",
                                                                            style:
                                                                                TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                                                                          ),
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                                            child:
                                                                                Row(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: <Widget>[
                                                                                GestureDetector(
                                                                                    onTap: () {
                                                                                      Navigator.pop(context);
                                                                                      showModalBottomSheet(
                                                                                          context: context,
                                                                                          builder: (context) {
                                                                                            return Scaffold(
                                                                                                body: SafeArea(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                                                                                child: Column(
                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                  children: <Widget>[
                                                                                                    Padding(
                                                                                                      padding: const EdgeInsets.only(top: 30),
                                                                                                      child: Align(
                                                                                                          alignment: Alignment.centerLeft,
                                                                                                          child: Text(
                                                                                                            "Select Episodes to add this segment",
                                                                                                            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5, fontWeight: FontWeight.w400, color: Colors.white),
                                                                                                          )),
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      height: 20,
                                                                                                    ),
                                                                                                    Expanded(
                                                                                                      child: ListView(
                                                                                                        scrollDirection: Axis.vertical,
                                                                                                        children: <Widget>[
                                                                                                          for (var a in episodeList)
                                                                                                            Padding(
                                                                                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                                                                                child: GestureDetector(
                                                                                                                  onTap: () {
//
                                                                                                                    print(v['id']);
                                                                                                                    print(a['id']);
                                                                                                                    postInterlude(
//
                                                                                                                        v['id'],
                                                                                                                        a['id']);
                                                                                                                    Navigator.pop(context);
                                                                                                                  },
                                                                                                                  child: Container(
                                                                                                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
                                                                                                                    child: ListTile(
                                                                                                                      leading: CircleAvatar(
                                                                                                                        backgroundColor: Colors.white,
                                                                                                                        backgroundImage: a['url'] == null ? AssetImage('assets/images/Thumbnail.png') : NetworkImage(a['url']),
                                                                                                                      ),
                                                                                                                      title: Text(
                                                                                                                        a['name'],
                                                                                                                        style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5, color: Colors.white),
                                                                                                                      ),
                                                                                                                      subtitle: Text(
                                                                                                                        "Last Update at: ${a['updatedAt'].toString().split('T')[0]}",
                                                                                                                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: SizeConfig.safeBlockHorizontal * 3),
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
//
                                                                                    },
                                                                                    child: Icon(
                                                                                      Icons.settings,
                                                                                      color: Colors.black54,
                                                                                    )),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          GestureDetector(
                                                                            onTap:
                                                                                () {
                                                                              postInterlude(v['id'], currentEpisodeId);
                                                                              Navigator.pop(context);
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              decoration: BoxDecoration(color: kActiveColor, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
                                                                              height: 50,
                                                                              width: double.infinity,
                                                                              child: Center(
                                                                                child: Text(
                                                                                  "Add recording to episode",
                                                                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          )
                                                                        ],
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                            });
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
                                                                        ListTile(
                                                                          onTap:
                                                                              () {
//                                                    deleteLibraryElement(
//                                                        v['id']);
                                                                            print("element deleted: ${v['id']}");
                                                                            Navigator.pop(context);
                                                                          },
                                                                          leading:
                                                                              Icon(Icons.stars),
                                                                          title:
                                                                              Text(
                                                                            "Add to favourites",
                                                                            style:
                                                                                TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                                          ),
                                                                        )
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
                      )
                  ],
                )
              ],
            ),
    );
  }
}
