import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:line_icons/line_icon.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../PlayerState.dart';
import 'Comments.dart';
import 'EpisodeView.dart';
import 'PodcastView.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:html/parser.dart';

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
            playlistDetails = response.data['playlist_details'];
            playlistData = playlistData = response.data['episodes'];
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

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
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
        body: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowGlow();
            return true;
          },
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: [
              Container(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: playlistData.length < 4
                          ? CachedNetworkImage(
                              imageUrl: playlistData[0]['image'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  width:
                                      MediaQuery.of(context).size.width / 2.5,
                                  height:
                                      MediaQuery.of(context).size.width / 2.5,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
                                );
                              },
                            )
                          : Container(
                              width: MediaQuery.of(context).size.width / 2.5,
                              height: MediaQuery.of(context).size.width / 2.5,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: playlistData[0]['image'],
                                        imageBuilder: (context, imageProvider) {
                                          return Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover)),
                                          );
                                        },
                                      ),
                                      CachedNetworkImage(
                                        imageUrl: playlistData[1]['image'],
                                        imageBuilder: (context, imageProvider) {
                                          return Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover)),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: playlistData[2]['image'],
                                        imageBuilder: (context, imageProvider) {
                                          return Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover)),
                                          );
                                        },
                                      ),
                                      CachedNetworkImage(
                                        imageUrl: playlistData[3]['image'],
                                        imageBuilder: (context, imageProvider) {
                                          return Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${playlistDetails['playlist_name']}",
                            textScaleFactor: mediaQueryData.textScaleFactor
                                .clamp(0.5, 0.9)
                                .toDouble(),
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 5,
                                fontWeight: FontWeight.bold),
                          ),
                          RichText(
                            text: TextSpan(
                                text: "by  ",
                                style: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 3,
                                    color: Color(0xffe8e8e8).withOpacity(0.5)),
                                children: [
                                  TextSpan(
                                      text: "${playlistDetails['username']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xffe8e8e8),
                                          decoration: TextDecoration.underline,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3))
                                ]),
                          ),
                          RichText(
                            text: TextSpan(
                                text: "Playlist",
                                style: TextStyle(
                                    color: Color(0xffe8e8e8).withOpacity(0.5),
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 3),
                                children: [
                                  TextSpan(
                                    text:
                                        " . ${playlistRawData['episodes_count']} episodes",
                                    style: TextStyle(
                                        color:
                                            Color(0xffe8e8e8).withOpacity(0.5),
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  )
                                ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              children: [
                                InkWell(
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                InkWell(
                                  child: Icon(
                                    LineIcons.download,
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
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                ListTile(
                                                  leading: playlistRawData[
                                                                  'episodes_images']
                                                              .length <
                                                          4
                                                      ? CircleAvatar(
                                                          radius: 25,
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl:
                                                                playlistRawData[
                                                                    'episodes_images'][0],
                                                          ),
                                                        )
                                                      : CircleAvatar(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          radius: 25,
                                                          child: Container(
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    CachedNetworkImage(
                                                                      imageUrl:
                                                                          playlistRawData['episodes_images']
                                                                              [
                                                                              0],
                                                                      imageBuilder:
                                                                          (context,
                                                                              imageProvider) {
                                                                        return Container(
                                                                          width:
                                                                              25,
                                                                          height:
                                                                              25,
                                                                          decoration:
                                                                              BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                        );
                                                                      },
                                                                    ),
                                                                    CachedNetworkImage(
                                                                      imageUrl:
                                                                          playlistRawData['episodes_images']
                                                                              [
                                                                              1],
                                                                      imageBuilder:
                                                                          (context,
                                                                              imageProvider) {
                                                                        return Container(
                                                                          width:
                                                                              25,
                                                                          height:
                                                                              25,
                                                                          decoration:
                                                                              BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    CachedNetworkImage(
                                                                      imageUrl:
                                                                          playlistRawData['episodes_images']
                                                                              [
                                                                              2],
                                                                      imageBuilder:
                                                                          (context,
                                                                              imageProvider) {
                                                                        return Container(
                                                                          width:
                                                                              25,
                                                                          height:
                                                                              25,
                                                                          decoration:
                                                                              BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                        );
                                                                      },
                                                                    ),
                                                                    CachedNetworkImage(
                                                                      imageUrl:
                                                                          playlistRawData['episodes_images']
                                                                              [
                                                                              3],
                                                                      imageBuilder:
                                                                          (context,
                                                                              imageProvider) {
                                                                        return Container(
                                                                          width:
                                                                              25,
                                                                          height:
                                                                              25,
                                                                          decoration:
                                                                              BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
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
                        child: Container(
                          decoration: BoxDecoration(color: Color(0xffe8e8e8)),
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Center(
                              child: Text.rich(TextSpan(children: [
                                // WidgetSpan(
                                //   child: Icon(Icons.play_arrow),
                                // ),
                                TextSpan(
                                    text: "SHUFFLE",
                                    style: TextStyle(color: Color(0xff161616)))
                              ])),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffe8e8e8))),
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Center(
                              child: Text.rich(TextSpan(children: [
                                // WidgetSpan(child: Icon(Icons.play_arrow)),
                                TextSpan(text: "PLAY", style: TextStyle())
                              ])),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        leading: CircleAvatar(
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
                                        children: [],
                                      ),
                                    );
                                  });
                            },
                            child: Icon(Icons.more_vert)),
                      ),
                    ),
                ],
              )
            ],
          ),
        ));
  }
}
