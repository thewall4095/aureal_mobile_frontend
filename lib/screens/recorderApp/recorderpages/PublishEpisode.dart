import 'dart:convert';
import 'dart:io';

import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/SelectedCommunitiesProvider.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'SelectCommunities.dart';
import 'SelectTags.dart';
import 'SelectedC'
    ''
    'ommunitiesWrap.dart';

class Publish extends StatefulWidget {
  // UserID,
  // EpisodeID,
  // EditorJSON,
  // Description,
  // EpisodeName,
  // Image

  var userId;
  var currentEpisodeId;
  var currentPodcastId;
  Publish({this.userId, this.currentEpisodeId, this.currentPodcastId});

  @override
  _PublishState createState() => _PublishState();
}

class _PublishState extends State<Publish> {
  File _image;
  final picker = ImagePicker();

  Dio dio = Dio();
  String author;
  String currentPodcast = '';
  int currentPodcastId;
  String podcastName;
  String episodeName = '';
  String description = '';
  int _inputHeight = 50;
  var podcastList = [];
  var userId;
  var currentEpisodeID;
  String albumartUrl;
  bool buttonState;
  bool isImageUploading = false;
  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.image;
  TextEditingController _controller = new TextEditingController();

  final TextEditingController _textEditingController = TextEditingController();

  void setData() {
    setState(() {
      userId = widget.userId;
      currentEpisodeID = widget.currentEpisodeId;
    });
  }

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

  ////////////////////--------Pick Image --------------////////////////////////

  Future getImageFile() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));

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

  void _upload() async {
    setState(() {
      isImageUploading = true;
    });
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
      isImageUploading = false;
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
    setData();
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

  void createPodcast(
    String name,
  ) async {
    var map = Map<String, dynamic>();
    map['user_id'] = userId;
    map['name'] = name;
    //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    var response = await dio.post("https://api.aureal.one/public/createPodcast",
        data: formData);
    print(response.data.toString());
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    _textEditingController.addListener(_inputHeight);
    getPodcasts();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var selectedCommunities = Provider.of<SelectedCommunityProvider>(context);
    CommunityProvider communities = Provider.of<CommunityProvider>(context);
    if (communities.isFetchedallCommunities == false) {
      communities.getAllCommunity();
    }
    if (communities.isFetcheduserCreatedCommunities == false) {
      communities.getUserCreatedCommunities();
    }
    if (communities.isFetcheduserCommunities == false) {
      communities.getAllCommunitiesForUser();
    }
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Publish Episode',
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ListView(
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        "Select Episode Image",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                      ),
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
                            child: _image == null
                                // ? Image.asset('assets/images/Thumbnail.png')
                                ? IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.edit,
                                        color: Colors.grey, size: 40),
                                  )
                                : Stack(
                                    children: [
                                      Image.file(
                                        _image,
                                        fit: BoxFit.cover,
                                      ),
                                      isImageUploading != true
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
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white),
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
                          "Episode Title",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          height: 90,
                          width: double.infinity,
                          child: TextField(
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3),
                            onChanged: (value) {
                              activeButtonState();
                              print(value);
                              setState(() {
                                episodeName = value;
                                activeButtonState();
                              });
                            },
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(10),
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                    color: Colors.grey.withOpacity(1.0),
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 3),
                                hintText:
                                    'Be descriptive to let your audience know what they are looking forward to..'),
                            maxLength: 100,
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Description",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Container(
                      height: 230,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white),
                      child: TextField(
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(10),
                          hintStyle: TextStyle(
                              color: Colors.grey.withOpacity(1.0),
                              fontSize: SizeConfig.safeBlockHorizontal * 3),
                          hintText:
                              'Have more details mentioned about what your episode is about or you think what listeners will know..',
                          border: InputBorder.none,
                        ),
                        maxLines: 15,
                        maxLength: 2000,
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
                  height: SizeConfig.safeBlockVertical * 2,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: CommunitiesWrapper()),
                ),
                SizedBox(
                  height: 10,
                ),
                InkWell(
                  onTap: () {
                    showBarModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Scaffold(
                            body: Container(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: SizeConfig.safeBlockVertical * 3,
                                  ),
                                  Container(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return LinearGradient(colors: [
                                                Color(0xffE73B57),
                                                Color(0xff6048F6)
                                              ]).createShader(bounds);
                                            },
                                            child: Text(
                                              "Select upto 5 communities to publish",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SelectCommunities(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: kSecondaryColor,
                    ),
                    width: double.infinity,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          selectedCommunities.selectedCommunities.length > 0
                              ? "Select More Communities"
                              : "Select Communities",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: SizeConfig.safeBlockVertical * 2,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // child: SelectTagWrapper(),
                ),
                // SizedBox(
                //   height: 10,
                //   ),
                InkWell(
                  onTap: () {
                    showBarModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Scaffold(
                            body: Container(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: SizeConfig.safeBlockVertical * 1,
                                  ),
                                  Container(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 1),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return LinearGradient(colors: [
                                                Color(0xffE73B57),
                                                Color(0xff6048F6)
                                              ]).createShader(bounds);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SelectTags(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: kSecondaryColor,
                    ),
                    width: double.infinity,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Tags",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 10,
                ),
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      buttonState == true
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return SelectTags(
                                    userID: userId,
                                    currentPodcastId: widget.currentPodcastId,
                                    currentEpisodeId: currentEpisodeID,
                                    episodeTitle: episodeName,
                                    episodeDescription: description,
                                    episodeNumber: 1,
                                    author: author,
                                    episodeImage: albumartUrl,
                                  );
                                }));
                                print(currentEpisodeID.toString());
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(35)),
                                    gradient: LinearGradient(colors: [
                                      Color(0xffE73B57),
                                      Color(0xff6048F6)
                                    ])),
                                width: double.infinity,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      "Publish now",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.2),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 0,
                              height: 0,
                            )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
