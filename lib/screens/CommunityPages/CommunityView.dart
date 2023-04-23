import 'dart:io';

import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/CommunityService.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/screens/CommunityPages/EditCommunity.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityView extends StatefulWidget {
  var communityObject;
  CommunityView({ this.communityObject});

  static const String id = "CommunityView";
  @override
  _CommunityViewState createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  Dio dio = Dio();

  CommunityService service = CommunityService();

  void share(var v) async {
    String sharableLink;

    await FlutterShare.share(
        title: '${v['title']}',
        text:
            "Hey There, I'm listening to ${v['name']} on Aureal, here's the link for you https://api.aureal.one/podcast/${v['podcast_id']}");
  }

  File _image;
  final picker = ImagePicker();
  String communityAlbumArt;
  String communityBanner;

  void editCommunity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/editCommunity";
    var map = Map<String, dynamic>();
    map['community_id'] = widget.communityObject['id'];
    map['user_id'] = prefs.getString('userId');
    map['profile_image_url'] = communityAlbumArt;
    map['banner_image_url'] = communityBanner;
    map['description'] = widget.communityObject['description'];

    print(map.toString());

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        print(response.data);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future getBannerArtImageFile() async {
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

    if (this.mounted) {
      setState(() {
        if (pickedFile != null) {
          _image = File('$fileName');
        } else {
          print('No file selected');
        }
      });
    }

    _communityBannerUpload();
    editCommunity();
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

  Future getAlbumArtImageFile() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    File croppedFile = (await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        )) as File;

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

  bool isCreator;

  bool follows;

  var communityData;

  List communityEpisodes = [];

  String bannerImage;
  String albumArt;

  var episodes = [];

  void getCommunityData() async {
    setState(() {
      bannerImage = widget.communityObject['bannerImageUrl'];
      albumArt = widget.communityObject['profileImageUrl'];
    });
    communityData = await service.getCommunityEpisodes(
        communityId: widget.communityObject['id']);
    communityEpisodes = communityData['EpisodeResult'];
    setState(() {
      isCreator = communityData['ifCreated'];
    });

    setState(() {
      follows = communityData['follows'];
    });

    print(communityData.toString());
  }

  @override
  void initState() {
    _tabController = TabController(length: 1, vsync: this);
    getCommunityData();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var communities = Provider.of<CommunityProvider>(context);
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    SizeConfig().init(context);
    return LayoutBuilder(
      builder: (context, contraints) {
        return Scaffold(
          appBar: AppBar(
              //    backgroundColor: Colors.transparent,
              ),
          bottomSheet: BottomPlayer(),
          body: Container(
            child: ListView(
              physics: BouncingScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height / 3.6,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              //     color: Colors.blue,
                              height: MediaQuery.of(context).size.height / 5,
                              width: double.infinity,
                              child: CachedNetworkImage(
                                height: MediaQuery.of(context).size.height / 5,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                imageUrl: widget.communityObject[
                                            'bannerImageUrl'] ==
                                        null
                                    ? placeholderUrl
                                    : widget.communityObject['bannerImageUrl'],
                              ),
                            )
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                    height:
                                        MediaQuery.of(context).size.width / 4,
                                    //     color: Colors.white,
                                    child: CachedNetworkImage(
                                      imageUrl: widget.communityObject[
                                                  'profileImageUrl'] ==
                                              null
                                          ? placeholderUrl
                                          : widget.communityObject[
                                              'profileImageUrl'],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      follows == null
                                          ? SizedBox(
                                              height: 0,
                                              width: 0,
                                            )
                                          : (follows == true
                                              ? InkWell(
                                                  onTap: () async {
                                                    await service
                                                        .unSubScribeCommunity(
                                                            communityId: widget
                                                                    .communityObject[
                                                                'id']);
                                                    setState(() {
                                                      follows = false;
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      // color: kSecondaryColor,
                                                      border: Border.all(
                                                          width: 2,
                                                          // color: kSecondaryColor
                                                          color: Color(
                                                              0xff171b27)),
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 5,
                                                          horizontal: 30),
                                                      child: Center(
                                                        child: Text(
                                                          'Leave',
                                                          textScaleFactor: 0.75,
                                                          style: TextStyle(
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  4),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : InkWell(
                                                  onTap: () async {
                                                    await service
                                                        .subscribeCommunity(
                                                            communityId: widget
                                                                    .communityObject[
                                                                'id']);
                                                    setState(() {
                                                      follows = true;
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        width: 2,
                                                        color: kSecondaryColor,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 5,
                                                          horizontal: 30),
                                                      child: Center(
                                                        child: Text(
                                                          'Join',
                                                          textScaleFactor: 0.75,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  4),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      // Icon(
                                      //   Icons.more_vert,
                                      //   color: Color(0xffe8e8e8),
                                      // ),

                                      isCreator == null
                                          ? SizedBox(
                                              width: 0,
                                            )
                                          : Theme(
                                              data: ThemeData.dark(),
                                              child: isCreator == false
                                                  ? PopupMenuButton(
                                                      icon:
                                                          Icon(Icons.more_vert),
                                                      color: Colors.blue,
                                                      itemBuilder: (BuildContext
                                                          context) {
                                                        return <PopupMenuEntry>[
                                                          const PopupMenuItem(
                                                              child: ListTile(
                                                            leading: Icon(
                                                                Icons.share),
                                                            title: Text(
                                                              'Share',
                                                              textScaleFactor:
                                                                  1.0,
                                                            ),
                                                          ))
                                                        ];
                                                      },
                                                    )
                                                  : PopupMenuButton(
                                                      icon: Icon(
                                                        Icons.more_vert,
                                                        color: Colors.blue,
                                                      ),
                                                      itemBuilder: (BuildContext
                                                          context) {
                                                        return <PopupMenuEntry>[
                                                          PopupMenuItem(
                                                            child: ListTile(
                                                              onTap: () {
                                                                Navigator.push(
                                                                    context,
                                                                    CupertinoPageRoute(
                                                                        builder:
                                                                            (context) {
                                                                  return EditCommunity(
                                                                      communityObject:
                                                                          widget
                                                                              .communityObject);
                                                                }));
                                                              },
                                                              leading: Icon(
                                                                Icons.edit,
                                                              ),
                                                              title: Text(
                                                                'Edit',
                                                                textScaleFactor:
                                                                    1.0,
                                                              ),
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            child: ListTile(
                                                              leading: Icon(
                                                                Icons.share,
                                                              ),
                                                              title: Text(
                                                                'Share',
                                                                textScaleFactor:
                                                                    1.0,
                                                              ),
                                                            ),
                                                          ),
                                                        ];
                                                      }),
                                            ),
                                    ],
                                  )

                                  // ListTile(
                                  //   title: Text(
                                  //       '${widget.communityObject['name']}'),
                                  // )
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "${widget.communityObject['name']}",
                      textScaleFactor: 0.75,
                      style: TextStyle(
                          //   color: Color(0xffe8e8e8),
                          fontSize: SizeConfig.safeBlockHorizontal * 6),
                    ),
                    subtitle: widget.communityObject['description'] == null
                        ? SizedBox(
                            height: 0,
                            width: 0,
                          )
                        : Text(
                            '${widget.communityObject['description']}',
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                //    color: Color(0xffe8e8e8),
                                fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                          ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                for (var v in communityEpisodes)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (context) {
                          return EpisodeView(episodeId: v['id']);
                        }));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: kSecondaryColor))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  //   color: Colors.white,
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: MediaQuery.of(context).size.width / 8,
                                  child: CachedNetworkImage(
                                    imageUrl: v['image'],
                                    // memCacheHeight:
                                    //     MediaQuery.of(
                                    //             context)
                                    //         .size
                                    //         .width
                                    //         .ceil(),
                                    memCacheHeight: MediaQuery.of(context)
                                        .size
                                        .height
                                        .floor(),
                                    placeholder: (context, url) => Container(
                                      child: Image.asset(
                                          'assets/images/Thumbnail.png'),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),
                                ),
                                SizedBox(width: SizeConfig.screenWidth / 26),
                                Container(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['podcast_name'],
                                        textScaleFactor: 0.75,
                                        style: TextStyle(
                                            //        color: Color(0xffe8e8e8),
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    5.5,
                                            fontWeight: FontWeight.normal),
                                      ),
                                      Text(
                                        v['duration'].toString(),
                                        textScaleFactor: 0.75,
                                        style: TextStyle(
                                            //   color: Color(0xffe8e8e8),
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    3.5),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['name'],
                                      textScaleFactor: 0.75,
                                      style: TextStyle(
                                          // color: Color(0xffe8e8e8),
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  4.5,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: Text(
                                        v['summary'],
                                        textScaleFactor: 0.75,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            //       color: Color(0xffe8e8e8),
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          await upvoteEpisode(
                                              permlink: v['permlink'],
                                              episode_id: v['id']);
                                          setState(() {
                                            v['ifVoted'] = !v['ifVoted'];
                                          });
                                        },
                                        child: Container(
                                          decoration: v['ifVoted'] == true
                                              ? BoxDecoration(
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        Color(0xff5bc3ef),
                                                        Color(0xff5d5da8)
                                                      ]),
                                                  borderRadius:
                                                      BorderRadius.circular(30))
                                              : BoxDecoration(
                                                  border: Border.all(
                                                      color: kSecondaryColor),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  FontAwesomeIcons
                                                      .chevronCircleUp,
                                                  size: 18,
                                                  // color: Color(0xffe8e8e8),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Text(
                                                    v['votes'].toString(),
                                                    textScaleFactor: 0.75,
                                                    style: TextStyle(),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 4),
                                                  child: Text(
                                                    '\$${v['payout_value'].toString().split(' ')[0]}',
                                                    textScaleFactor: 0.75,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: SizeConfig.screenWidth / 30,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(context,
                                              CupertinoPageRoute(
                                                  builder: (context) {
                                            return Comments(
                                              episodeObject: v,
                                            );
                                          }));
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: kSecondaryColor),
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.mode_comment_outlined,
                                                  size: 18,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Text(
                                                    v['comments_count']
                                                        .toString(),
                                                    textScaleFactor: 0.75,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // IconButton(
                                      //   icon: Icon(
                                      //     Icons
                                      //         .playlist_add_rounded,
                                      //     color:
                                      //         Color(0xffe8e8e8),
                                      //   ),
                                      // ),
                                      IconButton(
                                        icon: Icon(
                                          FontAwesomeIcons.shareAlt,
                                          size: SizeConfig.safeBlockHorizontal *
                                              4,
                                          //  color: Color(0xffe8e8e8),
                                        ),
                                        onPressed: () async {
                                          share(v);
                                        },
                                      )
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
        );
      },
    );
  }
}
