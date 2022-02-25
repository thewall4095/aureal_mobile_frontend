import 'dart:convert';
import 'dart:io';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bio extends StatefulWidget {
  static const String id = 'Bio';

  String bio;
  String fullname;
  String displayPicture;

  var bioObject;

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

  var data;

  void getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/private/users?user_id=${prefs.getString('userId')}';
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer ${prefs.getString('token')}"
    };

    try {
      http.Response response = await http.get(Uri.parse(url), headers: header);
      if (response.statusCode == 200) {
        print(response.body);
        if (this.mounted) {
          setState(() {
            data = jsonDecode(response.body)['users'];
            prefs.setString(
                'FullName', jsonDecode(response.body)['users']['fullname']);

            prefs.setString(
                'userName', jsonDecode(response.body)['users']['username']);
            displayPicture = jsonDecode(response.body)['users']['img'];
            // status = jsonDecode(response.body)['users']['settings']['Account']
            // ['Presence'];

            prefs.getString('HiveUserName');
            // jsonDecode(response.body)['users']['email'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
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

  TextEditingController _descriptionController = TextEditingController();

  String instagram = '';
  String twitter = '';
  String linkedin = '';

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
      map['settings_Account_Bio'] = bio + '\n' + description;
    } else {
      map['settings_Account_Bio'] = widget.bio;
    }

    if (displayUrl != '') {
      map['img'] = displayUrl;
    } else {
      map['img'] = widget.displayPicture;
      //isImageLoading = false;
    }

    if (linkedin != '') {
      map['linkedin'] = linkedin;
    }

    if (instagram != '') {
      map['instagram'] = instagram;
    } else {
      map['instagram'] = data['instagram'];
    }

    if (twitter != '') {
      map['twitter'] = twitter;
    } else {
      map['twitter'] = data['twitter'];
    }

    if (website != '') {
      map['website'] = website;
    } else {
      map['website'] = data['website'];
    }

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      var data = jsonDecode(response.toString())['user'];
      prefs.setString('displayPicture', data['img']);
      // print(response.toStrin());
      print(response.runtimeType);
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
    Navigator.pop(context, "done");
  }

  String description = '';
  String website = '';

  @override
  void initState() {
    // TODO: implement initState
    getUserDetails();
    super.initState();
    fullNameTextEditingControler.text = widget.fullname;
    bioTextEditingControler.text = widget.bio;

  }

  void init(){
    setState(() {
      isLoading = true;
    });
    getUserDetails();
    setState(() {
      isLoading = false;
    });

  }

  Future<void> _pullRefreshEpisodes() async {
    // getCommunityEposidesForUser();
    await updateUserDetails();
    await getImageFile();
    await activeButtonState();
  }

  AppBar _appBar() {
    return AppBar(
      //   backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }




  @override
  Widget build(BuildContext context) {
    try{
      return Scaffold(
        key: _scaffoldGlobalKey,
        body: ModalProgressHUD(
          inAsyncCall: isLoading,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
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
                      : IconButton(
                      onPressed: () {
                        updateUserDetails();
                      },
                      icon: Icon(FontAwesomeIcons.check))
                ],
                pinned: true,
                expandedHeight: MediaQuery.of(context).size.height / 3.5,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff5d5da8), Color(0xff5bc3ef)])
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        Center(

                        ),
                        CachedNetworkImage(imageUrl: displayUrl == null ? placeholderUrl : displayUrl, imageBuilder: (context, imageProvider){
                          return Container(
                            width: MediaQuery.of(context).size.width / 3,
                            height: MediaQuery.of(context).size.width / 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add_a_photo),
                              onPressed: (){
                                getImageFile();
                              },
                            ),
                          );
                        },),

                        Divider(
                          color: kSecondaryColor,
                        ),
                        //     SizedBox(height: 10)
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                      child: TextFormField(
                        decoration: InputDecoration(  hintText: data['bio'] != null
                            ? data['bio']
                            : 'Bio', labelText: 'Bio'),
                        //       controller: bioTextEditingControler,
                        autofocus: true,
                        maxLines: null,
                        initialValue: data['bio'],
                        onChanged: (value) {
                          setState(() {

                            bio = value;
                          });
                          activeButtonState();
                        },

                      ),

                    ),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                      child: TextField(
                        decoration: InputDecoration(
                            hintText:
                            'Write a show description about you, this will be there on your podcast page',
                            labelText: 'Description'),
                        maxLines: null,
                        onChanged: ((value) {
                          setState(() {
                            description = value;
                            //_phoneController.text = value;
                          });
                        }),
                      ),
                    ),
                    SizedBox(height: 30),
                    Divider(),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                      child: Text("Profile Information"),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          TextFormField(
                            keyboardType: TextInputType.url,
                            initialValue: data['instagram'],
                            onChanged: (value) {
                              setState(() {
                                instagram = value;
                              });
                            },
                            decoration: InputDecoration(
                                icon: Icon(FontAwesomeIcons.instagram),
                                hintText: data['instagram'] != null
                                    ? data['instagram']
                                    : 'https://instagram.com/john_snow'),
                          ),
                          TextFormField(
                            keyboardType: TextInputType.url,
                            initialValue: data['twitter'],
                            onChanged: (value) {
                              setState(() {
                                twitter = value;
                              });
                            },
                            decoration: InputDecoration(
                                icon: Icon(FontAwesomeIcons.twitter),
                                hintText:
                                '${data['twitter'] == null ? 'https://twitter.com/@john_snow' : data['twitter']} '),
                          ),
                          TextFormField(

                            initialValue: data['linkedin'] ,
                            onChanged: (value) {
                              setState(() {
                                linkedin = value;
                              });
                            },
                            decoration: InputDecoration(
                                icon: Icon(FontAwesomeIcons.linkedinIn),
                                hintText:
                                '${data['linkedin'] != null ? data['linkedin'] : 'https://linkedin/com/john_snow'}'),
                          ),
                          TextFormField(
                            keyboardType: TextInputType.url,
                            initialValue:  data['website'],
                            onChanged: (value) {
                              setState(() {
                                website = value;
                              });
                            },
                            decoration: InputDecoration(
                                icon: Icon(FontAwesomeIcons.link),
                                hintText: data['website'] == null
                                    ? 'https://aureal.one'
                                    : data['website']),
                          ),
                        ],
                      ),
                    )
                  ]))
            ],
          ),
        ),
      );
    }catch(e){
      return Scaffold(body: Container(),);
    }

  }

  Widget oldWidget() {
    return SafeArea(
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
                SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {},
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
                      decoration: BoxDecoration(
                        border: Border.all(color: kSecondaryColor),
                        borderRadius: BorderRadius.circular(8),
                        //    color: kSecondaryColor,
                      ),
                      width: double.infinity,
                      height: 80,
                      child: TextFormField(
                        maxLines: 6,
                        initialValue: widget.fullname,
                        controller: fullNameTextEditingControler,
                        onChanged: (value) {
                          setState(() {
                            fullname = value;
                          });
                          activeButtonState();
                        },
                        // style: TextStyle(color: Color(0xffe8e8e8)),
                        decoration: InputDecoration(
                          disabledBorder: OutlineInputBorder(),
                          labelText: 'Profile Name',
                          hintText: widget.fullname,
                          //   labelStyle: TextStyle(color: Color(0xffe8e8e8)),
                          border: OutlineInputBorder(),
                        ),

                        // Container(
                        //   width: double.infinity,
                        //   height: 80,
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(8),
                        //     //  color: kSecondaryColor
                        //   ),
                        //   child: TextField(
                        //     controller: fullNameTextEditingControler,
                        //     style: TextStyle(color: Colors.white54),
                        //     onChanged: (value) {
                        //       setState(() {
                        //         fullname = value;
                        //       });
                        //       activeButtonState();
                        //     },
                        //     decoration: InputDecoration(
                        //          hintText: widget.fullname,
                        //         hintStyle: TextStyle(
                        //           color: Colors.white,
                        //         ),
                        //         contentPadding:
                        //             EdgeInsets.fromLTRB(10, 0, 10, 10)),
                      ),
                    ),
                    SizedBox(
                      height: 20,
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
    );
  }
}
