// import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/screens/buttonPages/search.dart';
import 'package:auditory/utilities/Share.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../PlayerState.dart';
import 'Comments.dart';
import 'CreatePlaylist.dart';
import 'EpisodeView.dart';
import 'PodcastView.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:html/parser.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;

class PlaylistView extends StatefulWidget {
  final playlistId;

  PlaylistView({@required this.playlistId});

  @override
  _PlaylistViewState createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  int page = 0;

  Dio dio = Dio();

  List playlistData = [];
  var playlistDetails;

  var playlistRawData;

  SharedPreferences prefs;

  ScrollController controller = ScrollController();

  void share1({var episodeObject}) async {
    // String sharableLink;
    await FlutterShare.share(
        title: '${episodeObject['podcast_name']}',
        text:
            "Hey There, I'm listening to ${episodeObject['name']} from ${episodeObject['podcast_name']} on Aureal, \n \nhere's the link for you https://aureal.one/episode/${episodeObject['id']}");
  }

  void getPlaylistData() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getPlaylistEpisodes/${widget.playlistId}?page=$page&pageSize=15&user_id=${prefs.getString('userId')}";

    print(url);
    try {
      var response = await dio.get(url);
      print(response.data);
      if (response.statusCode == 200) {
        if (page == 0) {
          setState(() {
            playlistRawData = response.data;
            playlistName = response.data['playlist_details']['playlist_name'];
            description = response.data['playlist_details']['description'];
            playlistDetails = response.data['playlist_details'];
            playlistData = playlistData = response.data['episodes'];
            playlistDetails['ifFollows'] = false;
            page += 1;
          });
        } else {
          setState(() {
            playlistData = playlistData + response.data['episodes'];
            page += 1;
          });
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  Future updatePlaylist() async {
    String url = "https://api.aureal.one/private/updatePlaylist";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString("userId");
    map['playlist_id'] = widget.playlistId;
    map['playlist_name'] = playlistName;
    map['isPublic'] = isPublic;
    if (description != null || description.length == 0) {
      map['description'] = description;
    }

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  Future followPlaylist() async {
    String url = "https://api.aureal.one/private/followPlaylist";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('user_id');
    map['playlist_id'] = widget.playlistId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      return response;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future removeFromPlaylist(int episodeId) async {
    String url = "https://api.aureal.one/private/removeFromPlaylist";
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['playlist_id'] = widget.playlistId;
    map['episode_id'] = episodeId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      return response;
    } catch (e) {
      print(e);
    }
  }

  Future deletePlaylist() async {
    String url = "https://api.aureal.one/private/deletePlaylist";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['playlist_id'] = widget.playlistId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      return response;
    } catch (e) {
      print(e);
    }
  }

  RegExp htmlMatch = RegExp(r'(\w+)');

  @override
  void initState() {
    // TODO: implement initState
    getPlaylistData();
    super.initState();

    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        getPlaylistData();
      }
    });
  }

  //TODO: Share your playlist function
  void sharePlaylist() async {
    await FlutterShare.share(
        title: '${playlistDetails['playlist_name']}',
        text:
            "Here's my playlist for you https://aureal.one/playlist/${widget.playlistId}");
  }

  //TODO: Downloads for playlist

  bool isEditing = false;
  bool isPublic = true;

  String playlistName;
  String description;

  bool isLoading = true;

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
        bottomSheet: BottomPlayer(),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            isEditing == true
                ? IconButton(
                    icon: Icon(
                      Icons.done,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      updatePlaylist().then((value) {
                        getPlaylistData();
                        setState(() {
                          isEditing = false;
                        });
                      });
                    },
                  )
                : IconButton(
                    icon: Icon(
                      Icons.search,
                      //     color: Colors.white,
                    ),
                    onPressed: () async {
                      await showSearch(
                          context: context, delegate: SearchFunctionality());
                    },
                  ),
          ],
        ),
        body: ModalProgressHUD(
          inAsyncCall: isLoading,
          color: Color(0xff161616),
          child: isLoading == true
              ? Container(
                  color: Color(0xff161616),
                )
              : NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (overscroll) {
                    overscroll.disallowGlow();
                    return true;
                  },
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      if (isEditing == false)
                        Column(
                          children: [
                            Container(
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: playlistData.length < 4
                                        ? CachedNetworkImage(
                                            imageUrl: playlistData[0]['image'],
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2.5,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2.5,
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover)),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2.5,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2.5,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl: playlistData[0]
                                                          ['image'],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                    ),
                                                    CachedNetworkImage(
                                                      imageUrl: playlistData[1]
                                                          ['image'],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl: playlistData[2]
                                                          ['image'],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                    ),
                                                    CachedNetworkImage(
                                                      imageUrl: playlistData[3]
                                                          ['image'],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              5,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${playlistDetails['playlist_name']}",
                                          textScaleFactor: mediaQueryData
                                              .textScaleFactor
                                              .clamp(0.5, 0.9)
                                              .toDouble(),
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  5,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                              text: "by  ",
                                              style: TextStyle(
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3,
                                                  color: Color(0xffe8e8e8)
                                                      .withOpacity(0.5)),
                                              children: [
                                                TextSpan(
                                                    text:
                                                        "${playlistDetails['username']}",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Color(0xffe8e8e8),
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3))
                                              ]),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                              text: "Playlist",
                                              style: TextStyle(
                                                  color: Color(0xffe8e8e8)
                                                      .withOpacity(0.5),
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      " . ${playlistRawData['episodes_count']} episodes",
                                                  style: TextStyle(
                                                      color: Color(0xffe8e8e8)
                                                          .withOpacity(0.5),
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          3),
                                                )
                                              ]),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15),
                                          child: Row(
                                            children: [
                                              playlistDetails['id'] ==
                                                      prefs.getString('userId')
                                                  ? InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          isEditing = true;
                                                        });
                                                      },
                                                      child: Icon(
                                                        Icons.edit,
                                                        size: 20,
                                                      ),
                                                    )
                                                  : InkWell(
                                                      onTap: () {
                                                        followPlaylist()
                                                            .then((value) {
                                                          setState(() {
                                                            playlistDetails[
                                                                    'ifFollows'] =
                                                                true;
                                                          });
                                                        });
                                                      },
                                                      child: playlistDetails[
                                                                  'ifFollows'] ==
                                                              true
                                                          ? Icon(
                                                              Icons
                                                                  .playlist_add_check,
                                                              color:
                                                                  Colors.blue,
                                                            )
                                                          : Icon(Icons
                                                              .add_to_photos_outlined)),
                                              SizedBox(
                                                width: 20,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  sharePlaylist();
                                                },
                                                child: Icon(
                                                  Icons.ios_share,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 20,
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  showBarModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return Container(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              ListTile(
                                                                leading: playlistRawData['episodes_images']
                                                                            .length <
                                                                        4
                                                                    ? CircleAvatar(
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        radius:
                                                                            25,
                                                                        child:
                                                                            CachedNetworkImage(
                                                                          imageUrl:
                                                                              playlistRawData['episodes_images'][0],
                                                                        ),
                                                                      )
                                                                    : CircleAvatar(
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        radius:
                                                                            25,
                                                                        child:
                                                                            Container(
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  CachedNetworkImage(
                                                                                    imageUrl: playlistRawData['episodes_images'][0],
                                                                                    imageBuilder: (context, imageProvider) {
                                                                                      return Container(
                                                                                        width: 25,
                                                                                        height: 25,
                                                                                        decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                  CachedNetworkImage(
                                                                                    imageUrl: playlistRawData['episodes_images'][1],
                                                                                    imageBuilder: (context, imageProvider) {
                                                                                      return Container(
                                                                                        width: 25,
                                                                                        height: 25,
                                                                                        decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Row(
                                                                                children: [
                                                                                  CachedNetworkImage(
                                                                                    imageUrl: playlistRawData['episodes_images'][2],
                                                                                    imageBuilder: (context, imageProvider) {
                                                                                      return Container(
                                                                                        width: 25,
                                                                                        height: 25,
                                                                                        decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                  CachedNetworkImage(
                                                                                    imageUrl: playlistRawData['episodes_images'][3],
                                                                                    imageBuilder: (context, imageProvider) {
                                                                                      return Container(
                                                                                        width: 25,
                                                                                        height: 25,
                                                                                        decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                ],
                                                                              )
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                title: Text(
                                                                    "${playlistDetails['playlist_name']}"),
                                                                subtitle: Text(
                                                                    "${playlistRawData['episodes_count']} episodes"),
                                                              ),
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              Divider(),
                                                              ListTile(
                                                                onTap: () {
                                                                  List<Audio>
                                                                      playable =
                                                                      [];
                                                                  for (var v
                                                                      in playlistData) {
                                                                    playable.add(
                                                                        Audio
                                                                            .network(
                                                                      v['url'],
                                                                      metas:
                                                                          Metas(
                                                                        id: '${v['id']}',
                                                                        title:
                                                                            '${v['name']}',
                                                                        artist:
                                                                            '${v['author']}',
                                                                        album:
                                                                            '${v['podcast_name']}',
                                                                        // image: MetasImage.network('https://www.google.com')
                                                                        image: MetasImage.network(
                                                                            '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                                      ),
                                                                    ));
                                                                  }
                                                                  playable
                                                                      .shuffle();
                                                                  currentlyPlaying
                                                                          .playList =
                                                                      playable;
                                                                  currentlyPlaying.audioPlayer.open(
                                                                      Playlist(
                                                                          audios: currentlyPlaying
                                                                              .playList,
                                                                          startIndex:
                                                                              0),
                                                                      showNotification:
                                                                          true);
                                                                },
                                                                leading: Icon(
                                                                    Icons
                                                                        .shuffle),
                                                                title: Text(
                                                                    "Shuffle play"),
                                                              ),
                                                              ListTile(
                                                                onTap: () {
                                                                  showBarModalBottomSheet(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) {
                                                                        return Createplaylist(
                                                                            playlist_id:
                                                                                widget.playlistId);
                                                                      });
                                                                },
                                                                leading: Icon(Icons
                                                                    .playlist_add),
                                                                title: Text(
                                                                    "Add to Playlist"),
                                                              ),
                                                              ListTile(
                                                                onTap: () {
                                                                  sharePlaylist();
                                                                },
                                                                leading: Icon(Icons
                                                                    .ios_share),
                                                                title: Text(
                                                                    "Share"),
                                                              ),
                                                              playlistDetails[
                                                                          'id'] ==
                                                                      prefs.getString(
                                                                          "userId")
                                                                  ? ListTile(
                                                                      onTap:
                                                                          () async {
                                                                        await deletePlaylist()
                                                                            .then((value) {
                                                                          Navigator.pop(
                                                                              context);
                                                                          Navigator.pop(
                                                                              context);
                                                                        });
                                                                      },
                                                                      leading: Icon(
                                                                          Icons
                                                                              .delete),
                                                                      title: Text(
                                                                          "Delete playlist"),
                                                                    )
                                                                  : SizedBox(),
                                                            ],
                                                          ),
                                                        );
                                                      });
                                                },
                                                child: Icon(
                                                  Icons.more_vert,
                                                  size: 20,
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                height: 40,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          List<Audio> playable = [];
                                          for (var v in playlistData) {
                                            playable.add(Audio.network(
                                              v['url'],
                                              metas: Metas(
                                                id: '${v['id']}',
                                                title: '${v['name']}',
                                                artist: '${v['author']}',
                                                album: '${v['podcast_name']}',
                                                // image: MetasImage.network('https://www.google.com')
                                                image: MetasImage.network(
                                                    '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                              ),
                                            ));
                                          }
                                          playable.shuffle();
                                          currentlyPlaying.playList = playable;
                                          currentlyPlaying.audioPlayer.open(
                                              Playlist(
                                                  audios:
                                                      currentlyPlaying.playList,
                                                  startIndex: 0),
                                              showNotification: true);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Color(0xffe8e8e8)),
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Center(
                                              child:
                                                  Text.rich(TextSpan(children: [
                                                // WidgetSpan(
                                                //   child: Icon(Icons.play_arrow),
                                                // ),
                                                TextSpan(
                                                    text: "SHUFFLE",
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff161616)))
                                              ])),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          List<Audio> playable = [];
                                          for (var v in playlistData) {
                                            playable.add(Audio.network(
                                              v['url'],
                                              metas: Metas(
                                                id: '${v['id']}',
                                                title: '${v['name']}',
                                                artist: '${v['author']}',
                                                album: '${v['podcast_name']}',
                                                // image: MetasImage.network('https://www.google.com')
                                                image: MetasImage.network(
                                                    '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                              ),
                                            ));
                                          }
                                          currentlyPlaying.playList = playable;
                                          currentlyPlaying.audioPlayer.open(
                                              Playlist(
                                                  audios:
                                                      currentlyPlaying.playList,
                                                  startIndex: 0),
                                              showNotification: true);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Color(0xffe8e8e8))),
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Center(
                                              child:
                                                  Text.rich(TextSpan(children: [
                                                // WidgetSpan(child: Icon(Icons.play_arrow)),
                                                TextSpan(
                                                    text: "PLAY",
                                                    style: TextStyle())
                                              ])),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              TextField(
                                onChanged: (value) {
                                  setState(() {
                                    playlistName = value;
                                  });
                                },
                                controller: nameController..text = playlistName,
                                decoration: InputDecoration(labelText: "Title"),
                              ),
                              TextField(
                                onChanged: (value) {
                                  setState(() {
                                    description = value;
                                  });
                                },
                                controller: descriptionController
                                  ..text = description,
                                decoration: InputDecoration(
                                    labelText: "Description(optional)"),
                              ),
                              SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text("Is public"),
                                  value: isPublic,
                                  onChanged: (value) {
                                    setState(() {
                                      isPublic = value;
                                    });
                                  })
                              // Row(
                              //   children: [TextField(), TextField()],
                              // ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var v in playlistData)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                onTap: () {
                                  List<Audio> playable = [];
                                  for (var v in playlistData) {
                                    playable.add(Audio.network(
                                      v['url'],
                                      metas: Metas(
                                        id: '${v['id']}',
                                        title: '${v['name']}',
                                        artist: '${v['author']}',
                                        album: '${v['podcast_name']}',
                                        // image: MetasImage.network('https://www.google.com')
                                        image: MetasImage.network(
                                            '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                      ),
                                    ));
                                  }
                                  currentlyPlaying.playList = playable;
                                  currentlyPlaying.audioPlayer.open(
                                      Playlist(
                                          audios: currentlyPlaying.playList,
                                          startIndex: playlistData.indexOf(v)),
                                      showNotification: true);
                                },
                                leading: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  radius: 25,
                                  child: CachedNetworkImage(
                                    imageUrl: v['image'],
                                  ),
                                ),
                                title: Text(
                                  "${v['name']}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                    "${v['podcast_name']} • ${DurationCalculator(v['duration'])}"),
                                trailing: InkWell(
                                    onTap: () {
                                      showBarModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return Container(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: CircleAvatar(
                                                      radius: 25,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      child: CachedNetworkImage(
                                                        imageUrl: v['image'],
                                                      ),
                                                    ),
                                                    title: Text(
                                                      "${v['name']}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: Text(
                                                        "${v['podcast_name']} • ${DurationCalculator(v['duration'])}"),
                                                  ),
                                                  Divider(),
                                                  ListTile(
                                                    onTap: () {
                                                      List<Audio> playable = [];
                                                      for (var v
                                                          in playlistData) {
                                                        playable
                                                            .add(Audio.network(
                                                          v['url'],
                                                          metas: Metas(
                                                            id: '${v['id']}',
                                                            title:
                                                                '${v['name']}',
                                                            artist:
                                                                '${v['author']}',
                                                            album:
                                                                '${v['podcast_name']}',
                                                            // image: MetasImage.network('https://www.google.com')
                                                            image: MetasImage
                                                                .network(
                                                                    '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                          ),
                                                        ));
                                                      }
                                                      currentlyPlaying
                                                          .playList = playable;
                                                      currentlyPlaying.audioPlayer.open(
                                                          Playlist(
                                                              audios:
                                                                  currentlyPlaying
                                                                      .playList,
                                                              startIndex:
                                                                  playlistData
                                                                      .indexOf(
                                                                          v)),
                                                          showNotification:
                                                              true);
                                                    },
                                                    leading: Icon(
                                                        Icons.play_circle_fill),
                                                    title: Text("Play"),
                                                  ),
                                                  ListTile(
                                                    onTap: () {
                                                      showBarModalBottomSheet(
                                                          context: context,
                                                          builder: (context) {
                                                            return Createplaylist(
                                                                episodeId:
                                                                    v['id']);
                                                          });
                                                    },
                                                    leading: Icon(
                                                        Icons.playlist_add),
                                                    title:
                                                        Text("Add to playlist"),
                                                  ),
                                                  playlistDetails['id'] ==
                                                          prefs.getString(
                                                              'userId')
                                                      ? ListTile(
                                                          onTap: () async {
                                                            await removeFromPlaylist(
                                                                    v['id'])
                                                                .then((value) {
                                                              setState(() {
                                                                page = 0;
                                                              });
                                                              getPlaylistData();
                                                              Navigator.pop(
                                                                  context);
                                                            });
                                                          },
                                                          leading: Icon(
                                                              Icons.delete),
                                                          title: Text(
                                                              "Remove from playlist"),
                                                        )
                                                      : SizedBox(),
                                                  ListTile(
                                                    onTap: () {
                                                      Navigator.push(context,
                                                          CupertinoPageRoute(
                                                              builder:
                                                                  (context) {
                                                        return PodcastView(
                                                            v['podcast_id']);
                                                      }));
                                                    },
                                                    leading:
                                                        Icon(Icons.podcasts),
                                                    title:
                                                        Text("Go to podcast"),
                                                  ),
                                                  ListTile(
                                                    onTap: () {
                                                      share1(episodeObject: v);
                                                    },
                                                    leading:
                                                        Icon(Icons.ios_share),
                                                    title: Text("Share"),
                                                  )
                                                ],
                                              ),
                                            );
                                          });
                                    },
                                    child: Icon(Icons.more_vert)),
                              ),
                            ),
                          SizedBox(
                            height: 100,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
        ));
  }
}

Dio dio = Dio();

Future relatedPlaylist({int podcastId, int episodeId}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url =
      "https://api.aureal.one/private/getPrevNextEpisode/$podcastId/$episodeId?type=next";

  try {
    var response = await dio.get(url);
    if (response.statusCode == 200) {
      return response.data;
    } else {
      print(response.statusCode);
      return false;
    }
  } catch (e) {
    print(e);
  }
}
