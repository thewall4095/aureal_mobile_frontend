import 'dart:io';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/screens/recorderApp/RecorderDashboard.dart';
import 'package:auditory/screens/recorderApp/recorderpages/selectPodcast.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'SoundEditor/SoundEditor.dart';
import 'package:audioplayer/audioplayer.dart';
import 'PublishEpisode.dart';
import 'AddBackgroundMusic.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Record extends StatefulWidget {
  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<Record> with SingleTickerProviderStateMixin {
  bool loading = true;

  String token;
  bool isUploading;

  postreq.Interceptor intercept = postreq.Interceptor();

  Dio dio = Dio();

  TabController _tabController;
  bool isAdded;

  String loggedInUser;

  bool isPlaying = false;

  var podcastList = [];

  var editorData = [];
  var editorId;
  var episodeList;
  String currentEpisode = '';
  var currentEpisodeId;
//  bool initApiCall = true;
  String newSegmentName;
  String previewUrl;
  String author;

  bool episodeStatus;

  bool isRearranging = false;

  void getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
    print(token);
  }

  void getPodcasts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/podcast?user_id=${prefs.getString('userId')}';
    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['podcasts'];
      setState(() {
        podcastList = data;
      });
      print(podcastList);
    } else {
      print("Some error occurred");
    }
  }

  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.any;
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

    await _upload();
//    getCurrentUser();
  }

  Future _upload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_path != null) {
      setState(() {
        isUploading = true;
      });
      showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Add to episode",
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          fontWeight: FontWeight.w700),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
//                      child: Container(
//                        decoration: BoxDecoration(
//                            borderRadius: BorderRadius.circular(10),
//                            gradient: LinearGradient(
//                                colors: [Color(0xff6048F6), Color(0xff37A1F7)],
//                                begin: Alignment.centerLeft,
//                                end: Alignment.centerRight)),
//                        height: 10,
//                        width: double.infinity,
//                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.blue,
                        minHeight: 10,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xff6249EF)),
                      ),
                    ),
                    Text(
                      "This recording will be added to the episode",
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: SizeConfig.safeBlockHorizontal * 3),
                    ),
                    SizedBox(
                      height: 20,
                    )
//                    Padding(
//                      padding: const EdgeInsets.all(15.0),
//                      child: Container(
//                        decoration: BoxDecoration(
//                            border: Border.all(
//                                color: Colors.black54,
//                                width: 2)),
//                        child: TextField(
//                          onChanged: (value) {
//                            setState(() {
//                              name = value;
//                            });
//                          },
//                          style: TextStyle(
//                              color: Colors.black54,
//                              fontWeight: FontWeight.w700,
//                              fontSize: 17),
//                          decoration: InputDecoration(
//                              hintText:
//                              'What will this recording be called?',
//                              hintStyle: TextStyle(
//                                  color: Colors.grey,
//                                  fontSize: SizeConfig
//                                      .safeBlockHorizontal *
//                                      2.8,
//                                  fontWeight:
//                                  FontWeight.w600),
//                              contentPadding:
//                              EdgeInsets.symmetric(
//                                  horizontal: 15),
//                              border: InputBorder.none),
//                        ),
//                      ),
//                    ),
//                    GestureDetector(
//                      onTap: () async {
//                        print("Save Button Pressed");
//                        if (name != null) {
//                          pr.show();
//                          setState(() {
//                            isLoading = true;
//                          });
//                          await _upload();
//                          setState(() {
//                            isLoading = false;
//                          });
//                          pr.hide();
//                          Navigator.pop(context);
//                          Navigator.pushNamed(
//                              context, RecorderDashboard.id);
//                        }
//                      },
//                      child: Container(
//                        decoration: BoxDecoration(
//                            color: kActiveColor,
//                            borderRadius: BorderRadius.only(
//                                bottomRight:
//                                Radius.circular(10),
//                                bottomLeft:
//                                Radius.circular(10))),
//                        height: 50,
//                        width: double.infinity,
//                        child: Center(
//                          child: Text(
//                            "Add recording to episode",
//                            style: TextStyle(
//                                color: Colors.white,
//                                fontSize: SizeConfig
//                                    .safeBlockHorizontal *
//                                    2.8,
//                                fontWeight: FontWeight.w500),
//                          ),
//                        ),
//                      ),
//                    )
                  ],
                ),
              ),
            );
          });

      String url = 'https://api.aureal.one/private/upload';

      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['name'] = _fileName;
//    map['duration'] = '00000';
      map['soundBlob'] = await MultipartFile.fromFile(_path,
          filename: _fileName); //_audioBytes.toString();

      print(
          '////////////////////////////////////////////////////////////////////////');

      print(map['soundBlob']);

      FormData formData = FormData.fromMap(map);

      var response = await intercept.postRequest(formData, url);
      print(response.data.toString());

      await postLibrary(
          id: jsonDecode(response.toString())['library']['id'],
          eID: currentEpisodeId);
      setState(() {
        isUploading = false;
      });
      getData();
      Navigator.pop(context);
    }

    print(
        '///////////////////////////////////////////////////////////////////////////////////////////////');

//    await getCurrentUser();
  }

  void postLibrary({int id, int eID}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/addLibrary";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['library_id'] = id;
    map['episode_id'] = eID;
    //_audioBytes.toString();

    print(map['library_id']);
    print(map['episode_id']);

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
  }

  void previewEpisode({int episodeID, var editorData}) async {
    String url = "https://api.aureal.one/private/previewEpisode";

    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['episode_id'] = episodeID;
    var key = "";
    setState(() {
      isRearranging = false;
    });
    for (var v in editorData) {
      key += v['type'] + '_' + v['id'].toString() + '@';
    }
    map['merge_ids'] = key;
    print(map.toString());
    print(editorData.toString());
    FormData formData = FormData.fromMap(map);

    print(map.toString());

    var response = await intercept.postRequest(formData, url);

//    var response = await dio
//        .post(, data: formData);
    print(response.toString());
    var data = response.data['episode']['url'];
    print(data.toString());

    setState(() {
      previewUrl = data.toString();
    });
  }
  //////////////////////////////////////////////////////////////////-------------------------Player -----------------------///////////////////////////////////////////////////////////////////////////////////////////////////

  Future _play(String url) async {
    AudioPlayer audioplayer = AudioPlayer();
    audioplayer.play(url, isLocal: false);
  }

  //////////////////////////////////////////////////////////////////////////////---------What Happens on Reorder-------------//////////////////////////////////////////////////////////////////

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      var item = editorData.removeAt(oldIndex);
      editorData.insert(newIndex, item);
      isRearranging = true;
    });
  }

  //////////////////////////////////////////////////////////////////////////////---------Get Data for Editor-------------//////////////////////////////////////////////////////////////////

  void getData() async {
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer $token"
    };

    print(currentEpisodeId);
    String url =
        'https://api.aureal.one/private/getEditor?user_id=${loggedInUser}&episode_id=${currentEpisodeId}';
    http.Response response = await http.get(Uri.parse(url), headers: header);
    print(response.body);

    var data = jsonDecode(response.body)['library_arr'];
    for (var v in data) {
      v['isPlaying'] = false;
    }
    setState(() {
      editorData = data ?? [];
    });
    editorData = data ?? [];
    print(editorData.runtimeType);
  }

  //////////////////////////////////////////////////////////////////////////////---------Get Editing Episode-------------//////////////////////////////////////////////////////////////////

  void getEpisodes(bool initApiCall) async {
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
    setState(() {
      episodeList = data['episodes'];
      if (episodeList.length != 0) {
//        if (episodeList[episodeList.length - 1]['status'] != true) {
//          currentEpisode = episodeList[episodeList.length - 1]['name'];
//          prefs.setString('currentEpisodeName', currentEpisode);
//          currentEpisodeId = episodeList[episodeList.length - 1]['id'];
//          prefs.setString('currentEpisodeId', currentEpisodeId.toString());
//          episodeStatus = episodeList[episodeList.length - 1]['status'];
//        } else {
//          _initEpisode();
//        }
        currentEpisodeId = episodeList[0]['id'];
        prefs.setString('currentEpisodeName', currentEpisode);
        currentEpisode = episodeList[0]['name'];
        prefs.setString('currentEpisodeId', currentEpisodeId.toString());
        episodeStatus = episodeList[0]['status'];
        prefs.setString('editorId', episodeList[0]['editor_id'].toString());
        editorId = prefs.getString('editorId');
      } else {
        _initEpisode();
      }
    });
    await getData();

    prefs.setString('currentEpisodeId', currentEpisodeId.toString());
  }

  //////////////////////////////////////////////////////////////////////////////---------To Create New Episode-------------//////////////////////////////////////////////////////////////////

  void _initEpisode() async {
    print('initializing init episodes');

    print(
        '********************************************************************InitEpisode is getting called***************************************************');

    String url = "https://api.aureal.one/private/initEpisode";

    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.toString());
    setState(() {
      currentEpisodeId = response.data['new_episode']['id'];
      currentEpisode = response.data['new_episode']['name'];
      episodeStatus = response.data['new_episode']['status'];
      editorId = response.data['new_episode']['editor_id'];
    });
    getEpisodes(true);
  }

  //////////////////////////////////////////////////////////////////////////////---------Delete Editor Element-------------//////////////////////////////////////////////////////////////////

  void deleteEditorElement({int id, String category, int associationId}) async {
    String url = "https://api.aureal.one/private/deleteElement";
    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['editor_id'] = id;
    map['association_id'] = associationId;
    map['category'] = category;
    //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    print(map.toString());
    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
    var data = response.data['editor'];
    print(data);
    getData();
  }

  //////////////////////////////////////////////////////////--------Get Current User----------////////////////////////////////////////////////////////////////////////////////

  void getCurrentuser() async {
    setState(() {
      loading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      if (prefs.containsKey('userId')) {
        setState(() {
          loggedInUser = prefs.getString('userId');
        });
        await getEpisodes(true);
//        await getPodcasts();
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      loading = false;
    });
  }

  ///////////////////////////////////////////////////////////////--------------To Rename Segment------------------//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  void renameSegment(int id, String newName) async {
    String url = "https://api.aureal.one/private/updateLibrary";

    var map = Map<String, dynamic>();
    map['library_id'] = id;
    map['name'] = newName;
    //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);
    print(response.data.toString());
//    var data = response.data['editor'];
//    setState(() {
//      editorData = data;
//    });
    getData();
  }

////////////////////////////////////////////////////////////////-------------To Delete Episode---------------------//////////////////////////////////////////////////////////////////////

  void deleteEpisode(int id) async {
    //user it to delete one of the episodes in the list of episodes
    var map = Map<String, dynamic>();
    map['user_id'] = loggedInUser;
    map['episode_id'] = id;
    //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    var response = await dio.post("https://api.aureal.one/public/deleteEpisode",
        data: formData);
    print(response.data.toString());
//    var data = response.data['editor'];
//    setState(() {
//      editorData = data;
//    });
    getEpisodes(true);
  }

  void _stop() {
    AudioPlayer player = AudioPlayer();
    player.stop();
  }

///////////////////////////////////////////////////////////////-----------------UI Development----------------------////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentuser();
  }

//  @override
//  void dispose() {
//    // TODO: implement dispose
//    super.dispose();
//  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: isRearranging == false
          ? AppBar(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              leading: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Scaffold(
                            body: SafeArea(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: GestureDetector(
                                    onTap: () {
                                      _initEpisode();
                                      Navigator.pop(context);
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Icon(
                                          Icons.add_circle,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          "New Episode",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4,
                                              fontWeight: FontWeight.w600),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Previous Episodes",
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3,
                                          color: Colors.white),
                                    )),
                                Expanded(
                                  child: ListView(
                                    scrollDirection: Axis.vertical,
                                    children: <Widget>[
                                      for (var v in episodeList)
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  currentEpisode = v['name'];
                                                  currentEpisodeId = v['id'];
                                                  episodeStatus = v['status'];
                                                  print(currentEpisode);
                                                });
                                                getData();
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: kSecondaryColor),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: <Widget>[
                                                      CircleAvatar(
                                                        backgroundColor:
                                                            kActiveColor,
                                                        backgroundImage:
                                                            v['image'] == null
                                                                ? null
                                                                : NetworkImage(
                                                                    v['image']),
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                            v['name'],
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          Text(
                                                            "Last Update at: ${v['updatedAt'].toString().split('T')[0]}",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey),
                                                          )
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
                },
                icon: Icon(
                  Icons.add_circle,
                  color: kActiveColor,
                  size: 35,
                ),
              ),
              title: Text(
                "$currentEpisode",
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 4,
                    color: Colors.white),
              ),
              centerTitle: true,
              actions: <Widget>[
                episodeStatus == true
                    ? SizedBox(
                        width: 0,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            if (previewUrl == null) {
                              previewEpisode(
                                  episodeID: currentEpisodeId,
                                  editorData: editorData);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  maintainState: false,
                                  builder: (context) {
                                    return SelectPodcast(
                                      userId: loggedInUser,
                                      currentEpisodeId: currentEpisodeId,
                                    );
                                  }),
                            );
//                publishEpisode(currentEpisodeId, editorData);
                            print("Publish Button selected");
                          },
                          child: Center(
                            child: editorData.length == 0
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Text(
                                      "Publish",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: kActiveColor),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: Text(
                                        "Publish",
                                        style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
              ],
            )
          : AppBar(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              automaticallyImplyLeading: false,
              title: Container(
                decoration: BoxDecoration(
                    color: kActiveColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isRearranging = false;
                            });
                          },
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Rearrange Segments",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
//                          previewEpisode(episodeId: currentEpisodeId, editorData: editorData);
                          previewEpisode(
                              episodeID: currentEpisodeId,
                              editorData: editorData);
                        },
                        child: Text(
                          "Save",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.8),
                        ),
                      ),
                    )
                  ],
                ),
              )),
      body: loading == true
          ? Center(
              child: Container(
                child: SpinKitPulse(
                  color: Colors.blue,
                ),
              ),
            )
          : Container(
              child: editorData.length == 0
                  ? Stack(
                      children: <Widget>[
                        Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/startNow.png'),
                                  fit: BoxFit.contain)),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    "This episode doesn't have any recordings yet",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  height: 100,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    "Upload your Episode or Click on Circle Icon to Record",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3,
                                        fontWeight: FontWeight.w600),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 100,
                              child: Center(
                                  child: Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _openFileExplorer();
                                    },
                                    icon: Icon(
                                      Icons.cloud_upload,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  Text(
                                    "Upload your episode",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize:
                                            SizeConfig.blockSizeHorizontal * 3),
                                  )
                                ],
                              )),
                            )
                          ],
                        )
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              previewUrl != null
                                  ? GestureDetector(
                                      onTap: () {
                                        if (isPlaying == false) {
                                          _play(previewUrl);
                                          setState(() {
                                            isPlaying = true;
                                          });
                                        } else {
                                          _stop();
                                          setState(() {
                                            isPlaying = false;
                                          });
                                        }
                                      },
                                      child: Row(
                                        children: <Widget>[
                                          Icon(
                                            isPlaying == false
                                                ? Icons.play_circle_outline
                                                : Icons.pause_circle_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Preview",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3),
                                          )
                                        ],
                                      ),
                                    )
                                  : SizedBox(
                                      height: 0,
                                    ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ReorderableListView(
                            scrollDirection: Axis.vertical,
                            onReorder: _onReorder,
                            children: <Widget>[
                              for (final v in editorData)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 0),
                                  ),
                                  key: ValueKey(v),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 5, 20, 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.white),
                                      height: 80,
                                      child: Stack(
                                        children: [
                                          v['previous_library_id'] != null
                                              ? Icon(
                                                  Icons.music_note,
                                                  size: 20,
                                                  color: Colors.blue,
                                                )
                                              : SizedBox(
                                                  height: 0,
                                                  width: 0,
                                                ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
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
                                                      child: Center(
                                                        child: Container(
                                                          height: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              12,
                                                          width: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              12,
                                                          decoration: v[
                                                                      'previous_library_id'] !=
                                                                  null
                                                              ? BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  gradient:
                                                                      LinearGradient(
                                                                          colors: [
                                                                        Color(
                                                                            0xff6048F6),
                                                                        Color(
                                                                            0xff51C9F9)
                                                                      ]))
                                                              : BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Colors
                                                                      .blue),
                                                          child: Icon(
                                                            v['isPlaying'] ==
                                                                    false
                                                                ? Icons
                                                                    .play_arrow
                                                                : Icons.pause,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 15,
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: <Widget>[
                                                        Text(
                                                          v['name'].toString(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  3.4,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Text(
                                                          '${DurationCalculator(v['duration'])}',
                                                          style: TextStyle(
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  3),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        showModalBottomSheet(
                                                            context: context,
                                                            builder: (context) {
                                                              return Container(
                                                                height: SizeConfig
                                                                        .safeBlockVertical *
                                                                    40,
                                                                child:
                                                                    Container(
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .symmetric(
                                                                        horizontal:
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
                                                                              Text(
                                                                            "Editing Options",
                                                                            style:
                                                                                TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                                          ),
                                                                        ),
                                                                        ListTile(
                                                                          onTap:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                            showDialog(
                                                                                context: context,
                                                                                builder: (context) {
                                                                                  return AlertDialog(
                                                                                    title: Text(
                                                                                      "Rename Segment",
                                                                                      style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
                                                                                    ),
                                                                                    content: TextField(
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
                                                                                          renameSegment(v['id'], newSegmentName);
                                                                                          print("new name changed to: $newSegmentName");
                                                                                          Navigator.pop(context);
                                                                                        },
                                                                                        elevation: 0,
                                                                                        textColor: Colors.white,
                                                                                        child: Text('Save'),
                                                                                      ),
                                                                                      RaisedButton(
                                                                                        color: Colors.redAccent,
                                                                                        onPressed: () {
                                                                                          print("Cancel Button Pressed");
                                                                                        },
                                                                                        elevation: 0,
                                                                                        child: Text("Cancel"),
                                                                                      )
                                                                                    ],
                                                                                  );
                                                                                });
                                                                          },
                                                                          title:
                                                                              Text(
                                                                            "Rename recording",
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          leading:
                                                                              Icon(
                                                                            Icons.mode_edit,
                                                                          ),
                                                                        ),
                                                                        ListTile(
                                                                          onTap:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                            deleteEditorElement(
                                                                                id: v['editor_id'],
                                                                                category: v['type'],
                                                                                associationId: v['association_id']);
                                                                          },
                                                                          title:
                                                                              Text(
                                                                            "Delete Segment",
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          leading:
                                                                              Icon(
                                                                            Icons.delete,
                                                                          ),
                                                                        ),
                                                                        ListTile(
                                                                          onTap:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                            Navigator.push(context, MaterialPageRoute(builder:
                                                                                (context) {
                                                                              print(loggedInUser.runtimeType);
                                                                              print(v['id'].runtimeType);
                                                                              print(v['duration'].runtimeType);
                                                                              print(v['url'].runtimeType);
                                                                              return SoundEditor(
                                                                                userId: loggedInUser,
                                                                                libraryId: v['id'],
                                                                                soundDuration: double.parse(v['duration'].toString()),
                                                                                audioUrl: v['url'],
                                                                                episodeId: int.parse(currentEpisodeId.toString()),
                                                                                associationId: v['association_id'],
                                                                              );
                                                                            })).then((value) =>
                                                                                getCurrentuser());
                                                                          },
                                                                          title:
                                                                              Text(
                                                                            "Edit Segment",
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          leading:
                                                                              Icon(
                                                                            Icons.graphic_eq,
                                                                          ),
                                                                        ),
                                                                        ListTile(
                                                                          onTap:
                                                                              () async {
                                                                            Navigator.pop(context);

                                                                            Navigator.push(context,
                                                                                MaterialPageRoute(builder: (context) {
                                                                              return AddBackgroundMusic(
                                                                                libraryObject: v,
                                                                              );
                                                                            })).then((value) {
                                                                              int index = editorData.indexOf(v);
                                                                              if (value != null) {
                                                                                getCurrentuser();
                                                                              }
                                                                            });
                                                                          },
                                                                          title:
                                                                              Text(
                                                                            "Edit background Music",
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          leading:
                                                                              Icon(
                                                                            Icons.music_note,
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
                                                    ),
                                                  ],
                                                )
                                              ],
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
                      ],
                    ),
            ),
    );
  }
}
