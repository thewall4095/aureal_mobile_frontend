import 'dart:convert';
import 'dart:io';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Home.dart';

class EditEpisode extends StatefulWidget {
  var episodeObject;
  int podcastId;

  EditEpisode({ this.episodeObject,  this.podcastId});

  @override
  _EditEpisodeState createState() => _EditEpisodeState();
}

class _EditEpisodeState extends State<EditEpisode> {
  File _image;
  final picker = ImagePicker();

  Dio dio = Dio();
  String author;
  String currentPodcast = '';
  int currentPodcastId;
  String podcastName;
  String episodeName;
  String description;
  int _inputHeight = 50;
  var podcastList = [];
  var userId;
  var currentEpisodeID;
  String albumartUrl;
  bool buttonState;

  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.image;
  TextEditingController _controller = new TextEditingController();

  final TextEditingController _textEditingController = TextEditingController();

//  void setData() {
//    setState(() {
//      userId = widget.userId;
//      currentEpisodeID = widget.currentEpisodeId;
//    });
//  }

  void activeButtonState() {
    if (episodeName != '' && description != '') {
      setState(() {
        buttonState = true;
      });
    } else {
      setState(() {
        buttonState = false;
      });
    }
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  ////////////////////--------Pick Image --------------////////////////////////

  Future getImageFile() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    File croppedFile = (await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],)) as File;

    var optimisedImage = img.decodeImage(croppedFile.readAsBytesSync());

    var newImage = img.copyResize(optimisedImage, width: 1401);

    final directory = await getTemporaryDirectory();

    String fileName =
        '${directory.path}/OptimisedImage + ${DateTime.now()}.png';

    File('$fileName').writeAsBytesSync(img.encodePng(newImage));

    setState(() {
      if (pickedFile != null) {
        _image = File('$fileName');
      } else {
        print('No file selected');
      }
    });

    _upload();
  }

  ///////////////////--------Open File Explorer---------//////////////////////

//  void _openFileExplorer() async {
//    setState(() => _loadingPath = true);
//    try {
//      if (_multiPick) {
//        _path = null;
//        _paths = await FilePicker.platform.pickFiles(
//            type: _pickingType,
//            allowedExtensions: (_extension?.isNotEmpty ?? false)
//                ? _extension?.replaceAll(' ', '')?.split(',')
//                : null);
//      } else {
//        _paths = null;
//        _path = await FilePicker.platform.pickFiles(
//            type: _pickingType,
//            allowedExtensions: (_extension?.isNotEmpty ?? false)
//                ? _extension?.replaceAll(' ', '')?.split(',')
//                : null);
//      }
//    } on PlatformException catch (e) {
//      print("Unsupported operation" + e.toString());
//    }
//    if (!mounted) return;
//    setState(() {
//      _loadingPath = false;
//      _fileName = _path != null
//          ? _path.split('/').last
//          : _paths != null ? _paths.keys.toString() : '...';
//    });
//    print(_fileName);
//    print(_path);
//
//    _upload();
//  }

  void updateEpisode() async {
    String url = 'https://api.aureal.one/private/updateEpisode';

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = widget.episodeObject['id'];
    map['name'] =
        episodeName == null ? widget.episodeObject['name'] : episodeName;
    map['summary'] =
        description == null ? widget.episodeObject['summary'] : description;
    map['image'] =
        albumartUrl == null ? widget.episodeObject['image'] : albumartUrl;
    map['status'] = false;

    FormData formData = FormData.fromMap(map);

    print(map.toString());

    var response =  intercept.postRequest(formData, url);
    print(response.toString());

     publishEpisode(status: true);
  }

  void publishEpisode({bool status}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/publishEpisode";
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = widget.episodeObject['id'];
    map['podcast_id'] = widget.podcastId;
    map['status'] = status;

    FormData formData = FormData.fromMap(map);

    print(map.toString());

    var response = await intercept.postRequest(formData, url);
    print(response.toString());
    Navigator.popAndPushNamed(context, Home.id);
  }

  void _upload() async {
    var map = Map<String, dynamic>();
//    map['duration'] = '00000';
//    map['imageBlob'] = await MultipartFile.fromFile(_image.path,
//        filename: _image.toString()); //_audioBytes.toString();

    map['imageBlob'] = await MultipartFile.fromFile(_image.path);

    FormData formData = FormData.fromMap(map);
    print(formData.toString());
    var response = await dio.post("https://api.aureal.one/public/getImageUrl",
        data: formData);
    print(response.data.toString());
    setState(() {
      albumartUrl = response.data['imageUrl']['url'];
      print(albumartUrl);
    });
  }

  void previewEpisode(int episodeID, var editorData) async {
    var map = Map<String, dynamic>();
    map['user_id'] = userId;
    map['episode_id'] = episodeID;
    var key = "";
    for (var v in editorData) {
      key += v['type'] + '_' + v['id'].toString() + '@';
    }
    map['merge_ids'] = key;
    print(map.toString());
    print(editorData.toString());
    FormData formData = FormData.fromMap(map);

    print(map.toString());

    var response = await dio
        .post("https://api.aureal.one/public/previewEpisode", data: formData);
    print(response.toString());
  }

  /////////////////////////////////////////////////////////////////////--------get podcasts-------------////////////////////////////////////////////////////////////

  void getPodcasts() async {
    String url = 'https://api.aureal.one/public/podcast?user_id=$userId';
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

  ////////////////////////////////////////////////////////////////////---------create Podcast ------------///////////////////////////////////////////////////////////

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    _textEditingController.addListener(_inputHeight);
    print(widget.episodeObject.toString());
    print(widget.podcastId);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      //  backgroundColor: kPrimaryColor,
      appBar: AppBar(
        elevation: 0,
        // backgroundColor: kPrimaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Edit Episode',
          textScaleFactor: 0.75,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: ListView(
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Episode title",
                  textScaleFactor: 0.75,
                  style: TextStyle(
                      //  color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                ),
                SizedBox(
                  height: 5,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: kSecondaryColor),
                      // color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  height: 100,
                  width: double.infinity,
                  child: TextField(
                    style:
                        TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
                    onChanged: (value) {
                      activeButtonState();
                      print(value);
                      setState(() {
                        episodeName = value;
                        activeButtonState();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: widget.episodeObject['name'],
                      contentPadding: EdgeInsets.all(10),
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.8),
                          fontSize: SizeConfig.safeBlockHorizontal * 3),
                    ),
                    maxLength: 100,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Description",
                  textScaleFactor: 0.75,
                  style: TextStyle(
                      //  color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                ),
                SizedBox(
                  height: 5,
                ),
                Container(
                  height: 330,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: kSecondaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    style:
                        TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10),
                      hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.8),
                          fontSize: SizeConfig.safeBlockHorizontal * 3),
                      hintText: widget.episodeObject['summary'],
                      border: InputBorder.none,
                    ),
                    maxLines: 60,
                    maxLength: 4000,
                    onChanged: (value) {
                      setState(() {
                        description = value;
                        activeButtonState();
                      });
                    },
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Customise",
                  textScaleFactor: 0.75,
                  style: TextStyle(
                      // color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        getImageFile();
                      },
                      child: Container(
                        child: albumartUrl == null
                            ?
                            // Image.network(
                            //     widget.episodeObject['image'] != null &&
                            //             widget.episodeObject['image'] != ''
                            //         ? widget.episodeObject['image']
                            //         : 'assets/images/Thumbnail.png',
                            //     fit: BoxFit.cover,
                            //   )
                            Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: widget.episodeObject['image'] !=
                                                null &&
                                            widget.episodeObject['image'] != ''
                                        ? NetworkImage(
                                            widget.episodeObject['image'])
                                        : AssetImage(
                                            'assets/images/Thumbnail.png'),
                                    fit: BoxFit.cover,
                                    // colorFilter:
                                    //     ColorFilter
                                    //         .srgbToLinearGamma()
                                  ),
                                  shape: BoxShape.rectangle,
                                  // border: Border.all(
                                  //     color: Colors
                                  //         .blueAccent,
                                  //     width: 2),
                                ),
                              )
                            : Stack(
                                children: [
                                  Image.file(
                                    _image,
                                    fit: BoxFit.cover,
                                  ),
                                  albumartUrl != null
                                      ? SizedBox(
                                          height: 0,
                                        )
                                      : SpinKitPulse(
                                          color: Colors.blue,
                                        )
                                ],
                              ),
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          //border: Border.all(color: kSecondaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),

                GestureDetector(
                  onTap: () {
                    updateEpisode();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kSecondaryColor),
                      //   color: kActiveColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          "Update Episode",
                          textScaleFactor: 0.75,
                          style: TextStyle(
                              //color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                        ),
                      ),
                    ),
                  ),
                ),

//                Padding(
//                  padding: const EdgeInsets.all(10),
//                  child: Center(
//                    child: GestureDetector(
//                      onTap: () {
//                        DatePicker.showDatePicker(context,
//                            theme: DatePickerTheme(
//                              containerHeight: 210.0,
//                            ),
//                            showTitleActions: true,
//                            minTime: DateTime.now(),
//                            maxTime: DateTime(2030, 12, 31), onConfirm: (date) {
////                              print('confirm $date');
////                              _date = '${date.year} - ${date.month} - ${date.day}';
//                          setState(() {});
//                        }, currentTime: DateTime.now(), locale: LocaleType.en);
//                      },
//                      child: Text(
//                        "Change publish date",
//                        style: TextStyle(color: Colors.white),
//                      ),
//                    ),
//                  ),
//                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
