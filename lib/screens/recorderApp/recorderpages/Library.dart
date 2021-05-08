import 'dart:convert';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'dart:io';

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  postreq.Interceptor intercept = postreq.Interceptor();

  bool isLoading;

  String token;

  Dio dio = new Dio();
  var loggedInUser;
  var library = [];
  bool isPlaying;
  String newSegmentName;
  int episodeId;
  var episodeList = [];
  String currentEpisode = '';
  int currentEpisodeId;

  // Implementing file picker
  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.audio;
  TextEditingController _controller = new TextEditingController();

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

  ////////////////////////////////////////////////////////////////////////------------File Explorer----------------//////////////////////////////////////////////////////////////////

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
    getCurrentUser();
  }

  //////////////////////////////////////////////////////////////////-----------------------Upload Audio to server ---------------------//////////////////////////////////////////////////////////////////
  Future _upload() async {
    String url = 'https://api.aureal.one/private/upload';

    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['name'] = _fileName;
//    map['duration'] = '00000';
    map['soundBlob'] = await MultipartFile.fromFile(_path,
        filename: _fileName); //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
    await getCurrentUser();
  }

  //////////////////////////////////////////////////////////////////-------------------------Get Logged In User -----------------------///////////////////////////////////////////////////////////////////////////////////////////////////

  void getCurrentUser() async {
    setState(() {});
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('userId')) {
        setState(() {
          loggedInUser = prefs.getString('userId');
          token = prefs.getString('token');
          currentEpisodeId = int.parse(prefs.getString('currentEpisodeId'));
          currentEpisode = prefs.getString('currentEpisodeName');
        });
        getData();
        getEpisodesList();
      }
    } catch (e) {
      print(e);
    }
  }

  void getData() async {
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer $token"
    };

    setState(() {
      isLoading = true;
    });
    String url =
        'https://api.aureal.one/private/library?user_id=${loggedInUser}';
    http.Response response = await http.get(Uri.parse(url), headers: header);

    print(response.body);

    var data = jsonDecode(response.body)['library'];
    print(loggedInUser);
    print(data);
    for (var v in data) {
      v['isPlaying'] = false;
    }
    print(data.toString());

    setState(() {
      library = data ?? [];
      isLoading = false;
    });
  }

  //////////////////////////////////////////////////////////////////-------------------------Delete element from editor -----------------------///////////////////////////////////////////////////////////////////////////////////////////////////

  void deleteLibraryElement(int id) async {
    String url = "https://api.aureal.one/private/deleteLibrary";

    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['library_id'] = id;
    //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
//    print(map);
    var response = await intercept.postRequest(formData, url);

    print(response.data.toString());
    getData();
  }

  void renameLibElement(var id, String newName) async {
    String url = 'https://api.aureal.one/private/updateLibrary';
    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['library_id'] = id;
    map['name'] = newName;
    //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    print(map);
    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());

//    var data = response.data;
//
//    setState(() {
//      library = data['library'];
//    });
    getCurrentUser();
  }

  void postLibrary({int id, int eID}) async {
    String url = "https://api.aureal.one/private/addLibrary";

    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['library_id'] = id;
    map['episode_id'] = eID;
    //_audioBytes.toString();

    print(map['library_id']);
    print(map['episode_id']);

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
  }

  void getEpisodesList() async {
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer $token"
    };

    String url =
        "https://api.aureal.one/private/episode?user_id=${loggedInUser}";

    http.Response response = await http.get(Uri.parse(url), headers: header);
    print(response.body);

    var data = json.decode(response.body)['episodes'];
    setState(() {
      episodeList = data ?? [];
    });
  }

//  void setData() {
//    setState(() {
//      library = widget.libraryList;
//      episodeList = widget.episodeList;
//    });
//  }

  @override
  void initState() {
    // TODO: implement initState
    getCurrentUser();

    super.initState();
    _controller.addListener(() => _extension = _controller.text);
  }

//  @override
//  void dispose() {
//    // TODO: implement dispose
//    super.dispose();
//  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        title: Text(
          "Library",
          style: TextStyle(
              fontSize: SizeConfig.safeBlockHorizontal * 4,
              color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.clear,
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () async {
                await _openFileExplorer();
              },
              child: Center(
                  child: Text(
                "import",
                style: TextStyle(
                  color: kActiveColor,
                  fontSize: SizeConfig.safeBlockHorizontal * 3,
                ),
              )),
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
          : library.length == 0
              ? Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                        image: AssetImage('assets/images/startNow.png'),
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Hello there, I'm an astronaut and I need recordings to escape, Record now.",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                          ),
                          SizedBox(
                            height: 100,
                          ),
                        ],
                      ),
                    )
                  ],
                )
              : ListView(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        for (var v in library)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  v['previous_library_id'] != null
                                      ? Icon(
                                          Icons.music_note,
                                          color: Colors.blue,
                                          size: 20,
                                        )
                                      : SizedBox(
                                          width: 0,
                                          height: 0,
                                        ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          child: Row(
                                            children: <Widget>[
                                              GestureDetector(
                                                onTap: () {
                                                  if (v['isPlaying'] == false) {
                                                    _play(v['url']);
                                                  } else {
                                                    _stop();
                                                  }

                                                  if (v['isPlaying'] == false) {
                                                    setState(() {
                                                      v['isPlaying'] = true;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      v['isPlaying'] = false;
                                                    });
                                                  }
                                                },
                                                child: v['isPlaying'] == false
                                                    ? Container(
                                                        height: SizeConfig
                                                                .safeBlockHorizontal *
                                                            12,
                                                        width: SizeConfig
                                                                .safeBlockHorizontal *
                                                            12,
                                                        decoration: v[
                                                                    'previous_library_id'] ==
                                                                null
                                                            ? BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color:
                                                                    Colors.blue)
                                                            : BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                gradient:
                                                                    LinearGradient(
                                                                        colors: [
                                                                      Color(
                                                                          0xff6048F6),
                                                                      Color(
                                                                          0xff51C9F9)
                                                                    ])),
                                                        child: Icon(
                                                          Icons.play_arrow,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : CircleAvatar(
                                                        radius: 25,
                                                        child: Icon(
                                                          Icons.pause,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      v['name']
                                                          .toString()
                                                          .split('.')[0],
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3.4,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      v['duration']
                                                              .toString()
                                                              .split('.')[0] +
                                                          " Sec",
                                                      style: TextStyle(
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
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
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
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
                                                                            .only(
                                                                        top:
                                                                            30),
                                                                child: Text(
                                                                  "Add to episode",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          SizeConfig.safeBlockHorizontal *
                                                                              4,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                                ),
                                                              ),
                                                              Column(
                                                                children: <
                                                                    Widget>[
                                                                  Text(
                                                                    "This episode will be added to your current episode",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            SizeConfig.safeBlockHorizontal *
                                                                                3,
                                                                        color: Colors
                                                                            .black54),
                                                                  ),
                                                                  Text(
                                                                    "$currentEpisode",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black54,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
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
                                                                            onTap:
                                                                                () {
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
                                                                                                            postLibrary(
//
                                                                                                                id: v['id'],
                                                                                                                eID: a['id']);
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
                                                                                                                style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4, color: Colors.white),
                                                                                                              ),
                                                                                                              subtitle: Text(
                                                                                                                "Last Update at: ${a['updatedAt'].toString().split('T')[0]}",
                                                                                                                style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3, color: Colors.white.withOpacity(0.8)),
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
                                                                            child:
                                                                                Icon(
                                                                              Icons.settings,
                                                                              color: Colors.black54,
                                                                            )),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      postLibrary(
                                                                          id: v[
                                                                              'id'],
                                                                          eID:
                                                                              currentEpisodeId);
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      decoration: BoxDecoration(
                                                                          color:
                                                                              kActiveColor,
                                                                          borderRadius: BorderRadius.only(
                                                                              bottomLeft: Radius.circular(10),
                                                                              bottomRight: Radius.circular(10))),
                                                                      height:
                                                                          50,
                                                                      width: double
                                                                          .infinity,
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            Text(
                                                                          "Add recording to episode",
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize: SizeConfig.safeBlockHorizontal * 2.8),
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
                                                        height: SizeConfig
                                                                .safeBlockVertical *
                                                            25,
                                                        child: Container(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 20),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: <
                                                                  Widget>[
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      vertical:
                                                                          20),
                                                                  child: Text(
                                                                    "Audio Options",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            SizeConfig.safeBlockHorizontal *
                                                                                3),
                                                                  ),
                                                                ),
                                                                ListTile(
                                                                  onTap: () {
                                                                    deleteLibraryElement(
                                                                        v['id']);
                                                                    print(
                                                                        "element deleted: ${v['id']}");
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  leading: Icon(
                                                                    Icons
                                                                        .delete_forever,
                                                                  ),
                                                                  title: Text(
                                                                    "Delete permanently",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .redAccent,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            SizeConfig.safeBlockHorizontal *
                                                                                4),
                                                                  ),
                                                                ),
                                                                ListTile(
                                                                  onTap: () {
                                                                    Navigator.pop(
                                                                        context);
                                                                    showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (context) {
                                                                          return AlertDialog(
                                                                            title:
                                                                                Text(
                                                                              "Save Recording",
                                                                              style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
                                                                            ),
                                                                            content:
                                                                                TextField(
                                                                              onChanged: (value) {
                                                                                setState(() {
                                                                                  newSegmentName = value;
                                                                                });
                                                                              },
                                                                              decoration: InputDecoration(
                                                                                contentPadding: EdgeInsets.only(top: 15),
                                                                              ),
                                                                            ),
                                                                            actions: <Widget>[
                                                                              RaisedButton(
                                                                                color: kActiveColor,
                                                                                onPressed: () {
                                                                                  renameLibElement(v['id'], newSegmentName);

                                                                                  Navigator.pop(context);
                                                                                },
                                                                                elevation: 0,
                                                                                textColor: Colors.white,
                                                                                child: Text(
                                                                                  'Save',
                                                                                  style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
                                                                                ),
                                                                              ),
                                                                              RaisedButton(
                                                                                color: Colors.redAccent,
                                                                                onPressed: () {
                                                                                  Navigator.pop(context);
                                                                                  print("Cancel Button Pressed");
                                                                                },
                                                                                elevation: 0,
                                                                                child: Text(
                                                                                  "Cancel",
                                                                                  style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
                                                                                ),
                                                                              )
                                                                            ],
                                                                          );
                                                                        });
//                                                      Navigator.pop(context);
                                                                  },
                                                                  leading: Icon(
                                                                      Icons
                                                                          .edit),
                                                                  title: Text(
                                                                    "Rename Segment",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            SizeConfig.safeBlockHorizontal *
                                                                                4),
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
                                  )
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
    );
  }
}
