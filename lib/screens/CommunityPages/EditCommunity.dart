import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:shared_preferences/shared_preferences.dart';

List tags = [];
List selectedTags = [];

String query;

class EditCommunity extends StatefulWidget {
  var communityObject;

  EditCommunity({@required this.communityObject});

  @override
  _EditCommunityState createState() => _EditCommunityState();
}

class _EditCommunityState extends State<EditCommunity> {
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  postreq.Interceptor interceptor = postreq.Interceptor();

  void createCommunity() async {
    String url = 'https://api.aureal.one/public/addCommunity';
  }

  Timer _timehandle;

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  void addCommunity({String communityName, String description}) async {
    postreq.Interceptor intercept = postreq.Interceptor();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/addCommunity';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['community_name'] = communityName;
    map['description'] = description;

    String tag = '';

    for (var v in selectedTags.toSet().toList()) {
      tag = tag + '${v['id']}' + '_';
    }

    map['tags'] = tag;

    FormData formData = FormData.fromMap(map);
    try {
      print(map.toString());
      var response = await intercept.postRequest(formData, url);
      print(jsonDecode(response.toString())['community']['name']);

      if (response.data['msg'] == null) {
        await editCommunity(
            communityId: jsonDecode(response.toString())['community']['id'],
            communityAlbumArt: communityAlbumArt,
            bannerImage: communityBanner,
            communityDescription: jsonDecode(response.toString())['community']
                ['description']);
      } else {
        print(jsonDecode(response.toString())['msg']);
      }
    } catch (e) {
      print(e);
    }
  }

  void createTag(String tagTobeCreated) async {
    var map = Map<String, dynamic>();

    map['name'] = tagTobeCreated;

    FormData formData = FormData.fromMap(map);
    var response =
        await dio.post('https://api.aureal.one/public/addTag', data: formData);
    print(response.toString());
  }

  String bannerImage;
  String albumArt;
  String communityAlbumArt;
  String communityBanner;
  final picker = ImagePicker();
  File _image;

  String query;

  Dio dio = Dio();

  void editCommunity(
      {int communityId,
      String bannerImage,
      String communityAlbumArt,
      String communityDescription}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/editCommunity";
    var map = Map<String, dynamic>();
    map['community_id'] = communityId;
    map['user_id'] = prefs.getString('userId');
    map['profile_image_url'] = communityAlbumArt;
    map['banner_image_url'] = bannerImage;
    map['description'] = communityDescription;

    print('/////////////////////////////////////////////////////////////');
    print(map.toString());

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        print(response.toString());
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    Navigator.pop(context);
  }

  Future getBannerArtImageFile() async {
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

    await _communityBannerUpload();
    // await editCommunity();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _timehandle.cancel();
    super.dispose();
  }

  void _communityBannerUpload() async {
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
      communityBanner = response.data['imageUrl']['url'];
      print(communityBanner);
    });
  }

  CancelableOperation cancelableOperation;

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancelableOperation?.cancel();
    cancelableOperation = CancelableOperation.fromFuture(future, onCancel: () {
      print('Operation Cancelled');
    });
    return cancelableOperation.value;
  }

  Future getAlbumArtImageFile() async {
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

    await _communityAlbumupload();
  }

  void _communityAlbumupload() async {
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
      communityAlbumArt = response.data['imageUrl']['url'];
      print(communityAlbumArt);
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Create community",
              textScaleFactor: 0.75,
              style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
            ),
          ),
          body: SafeArea(
            child: Container(
              child: ListView(
                children: [
                  Column(
                    children: [
                      Column(
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height / 3.6,
                                  child: Stack(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          widget.communityObject[
                                                      'bannerImageUrl'] ==
                                                  null
                                              ? InkWell(
                                                  onTap: () async {
                                                    await getBannerArtImageFile();
                                                  },
                                                  child: Container(
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color: Color(
                                                                  0xff171b27))),
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height /
                                                              5,
                                                      width: double.infinity,
                                                      child: Icon(
                                                        Icons.add,
                                                        // color:
                                                        //     Color(0xffe8e8e8),
                                                      )),
                                                )
                                              : InkWell(
                                                  onTap: () async {
                                                    await getBannerArtImageFile();
                                                  },
                                                  child: Container(
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color: Color(
                                                                  0xff171b27))),
                                                      //  color: Colors.blue,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height /
                                                              5,
                                                      width: double.infinity,
                                                      child: CachedNetworkImage(
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height /
                                                            5,
                                                        imageUrl: widget
                                                                .communityObject[
                                                            'bannerImageUrl'],
                                                        memCacheHeight:
                                                            MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height
                                                                .floor(),
                                                      )),
                                                )
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // widget.communityObject[
                                                //             'profileImageUrl'] ==
                                                communityAlbumArt == null
                                                    ? InkWell(
                                                        onTap: () async {
                                                          await getAlbumArtImageFile();
                                                        },
                                                        child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                    //   color: Colors.white,
                                                                    border: Border.all(
                                                                        color: Color(
                                                                            0xff171b27))),
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                4,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                4,
                                                            //    color: Colors.white,
                                                            child: Icon(
                                                              Icons.add,
                                                            )),
                                                      )
                                                    : InkWell(
                                                        onTap: () async {
                                                          await getAlbumArtImageFile();
                                                        },
                                                        child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                                    // color: Colors
                                                                    //     .white,
                                                                    border: Border.all(
                                                                        color: Color(
                                                                            0xff171b27))),
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                4,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                4,
                                                            child:
                                                                CachedNetworkImage(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  4,
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  4,
                                                              fit: BoxFit.cover,
                                                              imageUrl:
                                                                  communityAlbumArt,
                                                              memCacheHeight:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height
                                                                      .floor(),
                                                            )),
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xff171b27))),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: TextField(
                                        enabled: false,
                                        controller: nameController,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3.5),
                                        decoration: InputDecoration(
                                            hintStyle: TextStyle(
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3.5),
                                            hintText:
                                                '${widget.communityObject['name']}',
                                            border: InputBorder.none),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xff171b27))),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: TextField(
                                        controller: descriptionController,
                                        maxLines: 8,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3.5),
                                        decoration: InputDecoration(
                                            hintStyle: TextStyle(
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3.5),
                                            hintText:
                                                '${widget.communityObject['description']}',
                                            border: InputBorder.none),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ListTile(
                          //   title: SimpleAutoCompleteTextField(
                          //     key: key,
                          //     suggestions: suggestions,
                          //     textChanged: (text) async {
                          //       if (text != null) {
                          //         Timer(Duration(seconds: 1), () async {
                          //           suggestions.addAll((await getTags(text)));
                          //         });
                          //       }
                          //     },
                          //   ),
                          // )

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: [
                                for (var v in selectedTags.toSet().toList())
                                  Chip(
                                    label: Text(
                                      v['name'],
                                      textScaleFactor: 0.75,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        selectedTags.remove(v);
                                      });
                                    },
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    showBarModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return _TagListView();
                                        });
                                  },
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xff171b27)),
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 8),
                                        child: Text(
                                          "Add tag",
                                          textScaleFactor: 0.75,
                                          style: TextStyle(),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 50,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          width: 2, color: Color(0xff171b27)
                                          // color: Color(0xff171b27),
                                          ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 25),
                                      child: Text(
                                        "Discard",
                                        textScaleFactor: 0.75,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                InkWell(
                                  onTap: () async {
                                    // addCommunity(
                                    //     communityName: nameController.text,
                                    //     description:
                                    //         descriptionController.text);
                                    editCommunity(
                                        communityId:
                                            widget.communityObject['id'],
                                        communityAlbumArt: communityAlbumArt,
                                        bannerImage: communityBanner,
                                        communityDescription:
                                            descriptionController.text == ''
                                                ? widget.communityObject[
                                                    'description']
                                                : descriptionController.text);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          width: 2, color: Color(0xff171b27)
                                          // color: Color(0xff171b27),
                                          ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 25),
                                      child: Text(
                                        "Continue",
                                        textScaleFactor: 0.75,
                                        style: TextStyle(
                                            color: Color(0xff3a3a3a),
                                            fontWeight: FontWeight.w700,
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TagListView extends StatefulWidget {
  @override
  __TagListViewState createState() => __TagListViewState();
}

class __TagListViewState extends State<_TagListView> {
  void getTags(String query) async {
    String url = "https://api.aureal.one/public/getTag?word=$query";

    Future.delayed(Duration(seconds: 1), () async {
      try {
        http.Response response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          setState(() {
            tags = jsonDecode(response.body)['allTags'];
          });
        } else {
          print("error loading tags");
        }
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
          onChanged: (value) {
            setState(() {
              query = value;
            });
          },
          onSubmitted: (value) async {
            await getTags(query);
          },
          decoration: InputDecoration(
            hintStyle: TextStyle(),
            hintText: 'Search for tags',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await getTags(query);
            },
            icon: Icon(
              Icons.done,
            ),
          )
        ],
      ),
      body: Container(
        child: ListView(
          children: [
            for (var v in tags)
              ListTile(
                onTap: () {
                  if (selectedTags.contains(v) == true) {
                    setState(() {
                      selectedTags.remove(v);
                    });
                  } else {
                    setState(() {
                      selectedTags.add(v);
                    });
                  }
                },
                title: Text(
                  v['name'],
                  textScaleFactor: 0.75,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
