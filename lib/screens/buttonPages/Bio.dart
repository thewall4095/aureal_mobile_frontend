import 'dart:convert';
import 'dart:io';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bio extends StatefulWidget {
  static const String id = 'Bio';

  String bio;
  String fullname;
  String displayPicture;

  // var bioObject;

  Bio({@required this.bio, this.fullname, this.displayPicture});

  @override
  _BioState createState() => _BioState();
}

class _BioState extends State<Bio> {
  postreq.Interceptor intercept = postreq.Interceptor();
  TextEditingController fullNameTextEditingControler = TextEditingController();
  TextEditingController bioTextEditingControler = TextEditingController();
  final _scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  bool isImageLoading = false;
  final picker = ImagePicker();

  File _image;

  Dio dio = Dio();
  String displayUrl;
  String fullname = '';
  String bio = '';
  bool buttonState;
  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.image;
  bool loadingBuilder;
  String displayPicture;

  void activeButtonState() {
    if (fullname != null && bio != null) {
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

    await _upload();
    setState(() {
      isImageLoading = false;
    });
  }

  void _openFileExplorer() async {
    setState(() => _loadingPath = true);
    try {
      if (_multiPick) {
        _path = null;
        // _paths = await FilePicker.platform.pickFiles(
        //     type: _pickingType,
        //     allowedExtensions: (_extension?.isNotEmpty ?? false)
        //         ? _extension?.replaceAll(' ', '')?.split(',')
        //         : null);
        _paths = (await FilePicker.platform.pickFiles(
            type: _pickingType,
            allowedExtensions: (_extension?.isNotEmpty ?? false)
                ? _extension?.replaceAll(' ', '')?.split(',')
                : null)) as Map<String, String>;
      } else {
        _paths = null;
        // _path = await FilePicker.platform.pickFiles(
        //     type: _pickingType,
        //     allowedExtensions: (_extension?.isNotEmpty ?? false)
        //         ? _extension?.replaceAll(' ', '')?.split(',')
        //         : null);
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
    setState(() {
      isLoading = true;
    });
    setState(() {
      isImageLoading = true;
    });
    var map = Map<String, dynamic>();
//    map['duration'] = '00000';
    map['imageBlob'] =
        await MultipartFile.fromFile(_image.path); //_audioBytes.toString();

    FormData formData = FormData.fromMap(map);
    var response = await dio.post("https://api.aureal.one/public/getImageUrl",
        data: formData);
    print(response.data.toString());
    setState(() {
      displayUrl = response.data['imageUrl']['url'];
      print(displayUrl);
    });
    setState(() {
      isLoading = false;
    });
    setState(() {
      isImageLoading = false;
    });
  }

  void updateUserDetails() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString('userId'));
    String url = 'https://api.aureal.one/private/updateUser';
    var map = Map<String, dynamic>();

    if (fullname != '') {
      map['fullname'] = fullname;
    } else {
      map['fullname'] = widget.fullname;
    }

    if (bio != '') {
      map['settings_Account_Bio'] = bio;
    } else {
      map['settings_Account_Bio'] = widget.bio;
    }

    if (displayUrl != '') {
      map['img'] = displayUrl;
    } else {
      map['img'] = widget.displayPicture;
      //isImageLoading = false;
    }

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      var data = jsonDecode(response)['user'];
      prefs.setString('displayPicture', data['img']);
      print(response.runtimeType);
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
    Navigator.pop(context, "done");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fullNameTextEditingControler.text = widget.fullname;
    bioTextEditingControler.text = widget.bio;
  }

  Future<void> _pullRefreshEpisodes() async {
    // getCommunityEposidesForUser();
    await updateUserDetails();
    await getImageFile();
    await activeButtonState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldGlobalKey,
      // backgroundColor: kPrimaryColor,
      appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.navigate_before,
            //     color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Edit Profile',
          textScaleFactor: 0.75,
          // style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          isImageLoading == true
              ? SizedBox(
                  height: 0,
                  width: 0,
                )
              : FlatButton(
                  onPressed: () {
                    updateUserDetails();
                  },
                  child: Text(
                    "Save",
                    textScaleFactor: 0.75,
                    //     style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: displayUrl == null
                        ? BoxDecoration(
                            image: DecorationImage(
                              image: widget.displayPicture != null
                                  ? CachedNetworkImageProvider(
                                      widget.displayPicture)
                                  // ? NetworkImage(widget.displayPicture)
                                  : AssetImage('assets/images/person.png'),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          )
                        : BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(displayUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                    height: 100,
                    width: 100,
                    child: isImageLoading == true
                        ? SpinKitPulse(
                            color: Colors.blue,
                          )
                        : SizedBox(
                            height: 0,
                            width: 0,
                          ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      getImageFile();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Text(
                        "Edit",
                        textScaleFactor: 0.75,
                        style: TextStyle(
                            //   color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          //  color: kSecondaryColor
                        ),
                        child: Center(
                            // child: TextField(
                            //   controller: fullNameTextEditingControler,
                            //   style: TextStyle(color: Colors.white54),
                            //   onChanged: (value) {
                            //     setState(() {
                            //       fullname = value;
                            //     });
                            //     activeButtonState();
                            //   },
                            //   decoration: InputDecoration(
                            //       //  hintText: widget.fullname,
                            //       hintStyle: TextStyle(
                            //         color: Colors.white54,
                            //       ),
                            //       contentPadding:
                            //           EdgeInsets.fromLTRB(10, 0, 10, 10)),
                            // ),
                            //  child: TextFormField(
                            //    initialValue: widget.fullname,
                            //    controller: fullNameTextEditingControler,
                            //    onChanged: (value) {
                            //      setState(() {
                            //        fullname = value;
                            //      });
                            //      activeButtonState();
                            //    },
                            // //   style: TextStyle(color: Color(0xffe8e8e8)),
                            //    decoration: InputDecoration(
                            //      disabledBorder: OutlineInputBorder(),
                            //      labelText: 'Full Name',
                            //  //    labelStyle: TextStyle(color: Color(0xffe8e8e8)),
                            //      border: OutlineInputBorder(),
                            //    ),
                            //  ),
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kSecondaryColor),
                          borderRadius: BorderRadius.circular(8),
                          //    color: kSecondaryColor,
                        ),
                        width: double.infinity,
                        height: 80,
                        child: TextFormField(
                          maxLines: 6,
                          initialValue: widget.bio,
                          controller: bioTextEditingControler,
                          onChanged: (value) {
                            setState(() {
                              bio = value;
                            });
                            activeButtonState();
                          },
                          // style: TextStyle(color: Color(0xffe8e8e8)),
                          decoration: InputDecoration(
                            disabledBorder: OutlineInputBorder(),
                            labelText: 'Bio',
                            //   labelStyle: TextStyle(color: Color(0xffe8e8e8)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        // child: TextField(
                        //   controller: bioTextEditingControler,
                        //   style: TextStyle(color: Colors.white54),
                        //   maxLines: 6,
                        //   onChanged: (value) {
                        //     setState(() {
                        //       bio = value;
                        //     });
                        //     activeButtonState();
                        //   },
                        //   decoration: InputDecoration(
                        //       //   hintText: widget.bio,
                        //       hintStyle: TextStyle(
                        //         color: Colors.white54,
                        //       ),
                        //       border: InputBorder.none,
                        //       contentPadding: EdgeInsets.symmetric(
                        //           horizontal: 10, vertical: 10)),
                        // ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
