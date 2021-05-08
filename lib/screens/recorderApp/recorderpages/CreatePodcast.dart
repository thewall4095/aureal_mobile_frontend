import 'dart:convert';
import 'dart:ui';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image/image.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class CreatePodcast extends StatefulWidget {
  static const String id = "Create Podcast";

  @override
  _CreatePodcastState createState() => _CreatePodcastState();
}

class _CreatePodcastState extends State<CreatePodcast> {
  final GlobalKey<ScaffoldState> _createPodcastKey =
      new GlobalKey<ScaffoldState>();
  File _image;

  final picker = ImagePicker();

  bool isImageLoading = false;

  Dio dio = Dio();
  postreq.Interceptor req = postreq.Interceptor();

  bool _explicitContent = true;

  /* */

  String language = 'English';
  String name;
  String description;
  int categoryId = 0;
  int languageId = 15;
  var categories = [];
  var languages = [];
  var categoryName = 'Uncategorised';
  String podcastArtUrl;

  bool buttonState;

  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.image;
  TextEditingController _controller = new TextEditingController();

  void showInSnackBar(String value) {
    _createPodcastKey.currentState.showSnackBar(new SnackBar(
        backgroundColor: Colors.red,
        content: new Text(
          value,
          style: TextStyle(color: Colors.white),
        )));
  }

  void activeButtonState() {
    if (name != null &&
        description != null &&
        categoryId != 0 &&
        podcastArtUrl != null &&
        languageId != null) {
      setState(() {
        buttonState = true;
      });
    } else {
      setState(() {
        buttonState = false;
      });
    }
  }

  Future getImageFile() async {
    setState(() {
      isImageLoading = true;
    });
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

    var optimisedImage = decodeImage(croppedFile.readAsBytesSync());

    var newImage = copyResize(optimisedImage, width: 1401);
    final directory = await getTemporaryDirectory();

    String fileName =
        '${directory.path}/OptimisedImage + ${DateTime.now()}.png';

    File('$fileName').writeAsBytesSync(encodePng(newImage));
    setState(() {
      if (pickedFile != null) {
        _image = File('$fileName');
      } else {
        print('No file selected');
      }
    });

    _upload();
    setState(() {
      isImageLoading = false;
    });
  }

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
  }

  void _upload() async {
    setState(() {});
    var map = Map<String, dynamic>();
//    map['duration'] = '00000';
    map['imageBlob'] =
        await MultipartFile.fromFile(_image.path); //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    var response = await dio.post("https://api.aureal.one/public/getImageUrl",
        data: formData);
    print(response.data.toString());
    setState(() {
      podcastArtUrl = response.data['imageUrl']['url'];
      print(podcastArtUrl);
    });
  }

  void getCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/getCategory';

    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        categories = jsonDecode(response.body)['allCategory'];
      });
      print(categories.toString());
    }
  }

  void getLanguage() async {
    String url = 'https://api.aureal.one/public/getLanguage';

    http.Response response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        languages = jsonDecode(response.body)['lang'];
      });
      print(languages.toString());
    } else {
      print(response.statusCode);
    }
  }

  void createPodcast() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString('userId'));
    String url = 'https://api.aureal.one/private/createPodcast';

    var map = Map<String, dynamic>();

    map['name'] = name;
    map['image'] = podcastArtUrl;
    map['description'] = description;
    map['user_id'] = prefs.getString('userId');
    map['category_id'] = categoryId;
    map['language_id'] = languageId;
    map['explicit_content'] = _explicitContent;

    print(map.toString());

    FormData formData = FormData.fromMap(map);

    var response = await req.postRequest(formData, url);
    print(response.toString());
    Navigator.pop(context, response.toString());
  }

  void _onChanged(bool value) {
    setState(() {
      _explicitContent = value;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCategories();
    getLanguage();
    languageId = 15;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        key: _createPodcastKey,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          title: Text(
            "Create Podcast",
            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                print(
                    '$name $podcastArtUrl $description $categoryId $languageId');
                if (name == null ||
                    podcastArtUrl == null ||
                    description == null ||
                    categoryId == null ||
                    languageId == null) {
                  showInSnackBar('Some Fields are missing');
                } else {
                  print('create podcast called');
                  createPodcast();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: Container(
                    decoration: (name == null ||
                            podcastArtUrl == null ||
                            description == null ||
                            categoryId == null ||
                            languageId == null)
                        ? BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(15))
                        : BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Text(
                        "Save",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ModalProgressHUD(
                    inAsyncCall: isImageLoading,
                    child: Container(
                      decoration: podcastArtUrl == null
                          ? BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            )
                          : BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(podcastArtUrl))),
                      height: 100,
                      width: 100,
                      child: podcastArtUrl == null
                          ? SpinKitPulse(
                              color: Colors.white,
                            )
                          : SizedBox(
                              height: 0,
                              width: 0,
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: SizeConfig.safeBlockVertical * 3,
              ),
              GestureDetector(
                onTap: () {
                  getImageFile();
                  activeButtonState();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 85),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: kActiveColor,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 10),
                        child: Text(
                          "Update podcast art",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 25,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Podcast info",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 4),
                ),
              ),
              Text(
                "Podcast name",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.safeBlockHorizontal * 3.2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                  ),
                  width: double.infinity,
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: TextField(
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                        onChanged: (value) {
                          setState(() {
                            if (value == '') {
                              name = null;
                            } else {
                              name = value;
                            }
                          });
                          activeButtonState();
                        },
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 8)),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Description",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.safeBlockHorizontal * 3.2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  width: double.infinity,
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                      onChanged: (value) {
                        setState(() {
                          if (value != '') {
                            description = value;
                          } else {
                            description = null;
                          }
                        });
                        activeButtonState();
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                      ),
                      maxLines: 5,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Podcast category",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.safeBlockHorizontal * 3.2),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                      isDismissible: true,
                      enableDrag: true,
                      context: context,
                      builder: (context) {
//
                        return Container(
                          color: Colors.white,
                          child: ListView(children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  height: 10,
                                ),
                                for (var v in categories)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        categoryId = v['id'];
                                        categoryName = v['name'];
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
//                                              width: double.infinity,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 10),
                                                child: Text(
                                                  v['name'],
                                                  style: TextStyle(
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          4,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ]),
                        );
                      });
                  activeButtonState();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                    ),
                    height: 40,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '$categoryName',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                          ),
                          Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Language",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.safeBlockHorizontal * 3.2),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                      isDismissible: true,
                      enableDrag: true,
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white,
                          child: ListView(children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  height: 10,
                                ),
                                for (var v in languages)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        languageId = v['id'];
                                        language = v['name'];
                                      });

                                      Navigator.pop(context);
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 10),
                                              child: Text(
                                                v['name'],
                                                style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        4,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ]),
                        );
                      });
                  activeButtonState();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                    ),
                    width: double.infinity,
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '$language',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                          ),
                          Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Options",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Explicit content",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                  ),
                  Switch(
                    inactiveTrackColor: Colors.white30,
                    value: _explicitContent,
                    onChanged: (bool value) {
                      _onChanged(value);
                      activeButtonState();
                    },
                  ),
                ],
              )
            ],
          ),
        ));
  }
}
