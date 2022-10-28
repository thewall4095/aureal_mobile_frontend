import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:async/async.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/CommunityService.dart';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/data/Datasource.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PlaylistView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/Share.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:miniplayer/miniplayer.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart' as pro;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../PlayerState.dart';
import 'Clips.dart';
import 'Onboarding/HiveDetails.dart';
import 'Profiles/CategoryView.dart';
import 'Profiles/Comments.dart';
import 'RouteAnimation.dart';
import 'buttonPages/settings/Theme-.dart';

// final selectedVideoProvider = rp.StateProvider<Video>((ref) => null);

// enum FeedbackType {
//   success,
//   error,
//   warning,
//   selection,
//   impact,
//   heavy,
//   medium,
//   light
// }

class Feed extends StatefulWidget {
  Feed();

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> with AutomaticKeepAliveClientMixin {
  // Future checkforSubscriptions() async {
  CancelToken _cancel = CancelToken();

  final String baseUrl = "https://api.aureal.one/public";

  var feedStructure = [];

  RegExp htmlMatch = RegExp(r'(\w+)');

  Future getFeed() async {
    Dio dio = Dio();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recommended?page=0&pageSize=5&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {}
    } catch (e) {
      print(e);
    }
  }

  // Future getFeedStructure(BuildContext context) async {
  SharedPreferences prefs;

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio();
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _feedBuilder(BuildContext context, var data) {
    switch (data['type']) {
      case 'podcast':
        return PodcastWidget(data: data);
        break;
      case 'episode':
        return EpisodeWidget(data: data);
        break;

      case "playlist":
        return PlaylistWidget(data: data);
        break;
      case 'snippet':
        return SnippetWidget(data: data);
        break;
      case 'user':
        return FutureBuilder(
          future: generalisedApiCall(data['api']),
          builder: (context, snapshot) {
            return Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text("${data['name']}",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 5,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text("${snapshot.data}"),
                ],
              ),
            );
          },
        );
        break;
      case 'videoepisode':
        return VideoListWidget(data: data);
        break;
      default:
        return Container();
        break;
    }
  }

  Future feed;

  @override
  void initState() {
    // TODO: implement initState
    feed = getFeed();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Material(
        child: FutureBuilder(
          future: feed,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  itemCount: snapshot.data.length + 1,
                  itemBuilder: (context, int index) {
                    if (index == snapshot.data.length) {
                      return SizedBox(
                        height: 50,
                      );
                    } else {
                      return _feedBuilder(context, snapshot.data[index]);
                    }
                  });
            } else {
              return SizedBox(
                  // height: MediaQuery.of(context).size.height / 25,
                  );
            }
          },
        ),
      );

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class VideoCard extends StatelessWidget {
  final Video video;
  final episodeObject;
  const VideoCard({@required this.video, this.episodeObject});

  @override
  Widget build(BuildContext context) {
    final episodeObject = Provider.of<PlayerChange>(context);
    return GestureDetector(
      onTap: () {
        episodeObject.audioPlayer.stop();
        episodeObject.isVideo = true;
        episodeObject.episodeObject = episodeObject;
        episodeObject.videoSource = video;
        episodeObject.miniplayerController
            .animateToHeight(state: PanelState.MAX);
        // episodeObject.betterPlayerController
        //     .setupDataSource(BetterPlayerDataSource(
        //   BetterPlayerDataSourceType.network,
        //   episodeObject.videoSource.url,
        //   notificationConfiguration: BetterPlayerNotificationConfiguration(
        //     showNotification: true,
        //     title: "${episodeObject.videoSource.title}",
        //     author: "${episodeObject.videoSource.author}",
        //     imageUrl: "${episodeObject.videoSource.episodeImage}",
        //   ),
        // ));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                child: FadeInImage(
                  placeholder: AssetImage('assets/placeholder.gif'),
                  image: Image.network(
                    video.episodeImage == null
                        ? video.thumbnailUrl
                        : video.episodeImage,
                    gaplessPlayback: true,
                    cacheHeight: (MediaQuery.of(context).size.width).floor(),
                    cacheWidth: (MediaQuery.of(context).size.width).floor(),
                  ).image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // child: CachedNetworkImage(
            //   imageUrl: video.episodeImage,
            //   errorWidget: (context, url, e) {
            //     return Container(
            //       width: double.infinity,
            //       constraints: BoxConstraints(
            //           maxWidth: MediaQuery.of(context).size.width,
            //           maxHeight: MediaQuery.of(context).size.height / 3),
            //       decoration: BoxDecoration(
            //           image: DecorationImage(
            //               image: CachedNetworkImageProvider(placeholderUrl),
            //               fit: BoxFit.cover)),
            //     );
            //   },
            //   placeholder: (context, url) {
            //     return Container(
            //       width: double.infinity,
            //       constraints: BoxConstraints(
            //           maxWidth: MediaQuery.of(context).size.width,
            //           maxHeight: MediaQuery.of(context).size.height / 3),
            //       decoration: BoxDecoration(
            //           image: DecorationImage(
            //               image: CachedNetworkImageProvider(placeholderUrl),
            //               fit: BoxFit.cover)),
            //     );
            //   },
            //   imageBuilder: (context, imageProvider) {
            //     return Container(
            //       width: double.infinity,
            //       constraints: BoxConstraints(
            //           maxWidth: MediaQuery.of(context).size.width,
            //           maxHeight: MediaQuery.of(context).size.height / 3),
            //       decoration: BoxDecoration(
            //           image: DecorationImage(
            //               image: imageProvider, fit: BoxFit.cover)),
            //     );
            //   },
            // ),
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              child: Image.network(
                video.thumbnailUrl,
                cacheHeight: 100,
                cacheWidth: 100,
              ),
            ),
            title: Text(
              "${video.title}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${video.album}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}

class VideoListWidget extends StatelessWidget {
  final data;

  VideoListWidget({@required this.data});

  SharedPreferences prefs;

  CancelToken _cancel = CancelToken();

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio();
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=10&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: generalisedApiCall(data['api']),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            height: MediaQuery.of(context).size.height / 2.5,
            child: Column(
              children: [
                ListTile(
                  title: Text("${data['name']}",
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.bold)),
                  trailing: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                                colors: [Color(0xff5bc3ef), Color(0xff5d5da8)])
                            .createShader(bounds);
                      },
                      child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) {
                                  return SeeMore(data: data);
                                },
                              ),
                            );
                          },
                          child: Text(
                            "See more",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ))),
                ),
                Flexible(
                  child: ListView.builder(
                    itemCount: snapshot.data.length,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: VideoCard(
                              episodeObject: snapshot.data[index],
                              video: Video(
                                  id: snapshot.data[index]['id'],
                                  title: snapshot.data[index]['name'],
                                  author: snapshot.data[index]['author'],
                                  permlink: snapshot.data[index]['permlink'],
                                  thumbnailUrl: snapshot.data[index]
                                      ['podcast_image'],
                                  episodeImage: snapshot.data[index]['image'],
                                  author_id: snapshot.data[index]
                                      ['author_user_id'],
                                  podcastid: snapshot.data[index]['podcast_id'],
                                  album: snapshot.data[index]['podcast_name'],
                                  url: snapshot.data[index]['url'],
                                  createdAt: snapshot.data[index]
                                      ['published_at'])),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            height: MediaQuery.of(context).size.height / 4,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < 10; i++)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Color(0xff080808),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      },
    );
  }
}

class EpisodeWidget extends StatefulWidget {
  final data;
  final categoryId;

  EpisodeWidget({@required this.data, this.categoryId});

  @override
  _EpisodeWidgetState createState() => _EpisodeWidgetState();
}

class _EpisodeWidgetState extends State<EpisodeWidget>
    with AutomaticKeepAliveClientMixin {
  Future myFuture;

  SharedPreferences prefs;

  RegExp htmlMatch = RegExp(r'(\w+)');

  CancelToken _cancel = CancelToken();

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio();
    prefs = await SharedPreferences.getInstance();
    print(widget.categoryId);
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=10&user_id=${prefs.getString('userId')}";
    if (widget.categoryId != null) {
      url = url + "&category_ids=${widget.categoryId}";
    }
    print(url);

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      print(response.data['data']);
      playListGenerator(data: response.data['data']);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print(e);
    }
  }

  List<Audio> playlist;

  void playListGenerator({List data}) async {
    List<Audio> playable = [];
    for (int i = 0; i < data.length; i++) {
      var v = data[i];
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

    playlist = playable;
    print(playlist);
    // episodeObject.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    myFuture = generalisedApiCall(widget.data['api']);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var currentlyPlaying = Provider.of<PlayerChange>(context);
    // var episodeObject = Provider.of<PlayerChange>(context);
    return FutureBuilder(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length == 0) {
            return SizedBox();
          } else {
            try {
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text("${widget.data['name']}",
                          style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5,
                              fontWeight: FontWeight.bold)),
                      trailing: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(colors: [
                              Color(0xff5bc3ef),
                              Color(0xff5d5da8)
                            ]).createShader(bounds);
                          },
                          child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) {
                                      return SeeMore(data: widget.data);
                                    },
                                  ),
                                );
                              },
                              child: Text(
                                "See more",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ))),
                    ),
                    ColumnBuilder(
                        itemBuilder: (context, int index) {
                          return EpisodeCard(
                            data: snapshot.data[index],
                            index: index,
                            playlist: playlist,
                          );
                        },
                        itemCount: snapshot.data.length)
                  ],
                ),
              );
            } catch (e) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("${widget.data['name']}",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 5,
                            fontWeight: FontWeight.bold)),
                  ),
                  for (int i = 0; i < 6; i++)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Color(0xff080808)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 7,
                                    height:
                                        MediaQuery.of(context).size.width / 7,
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration:
                                            BoxDecoration(color: Colors.black),
                                        height: 16,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Container(
                                        decoration:
                                            BoxDecoration(color: Colors.black),
                                        height: 8,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                      )
                                    ],
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Container(
                                    color: Colors.black,
                                    height: 10,
                                    width: MediaQuery.of(context).size.width),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Container(
                                    color: Colors.black,
                                    height: 10,
                                    width:
                                        MediaQuery.of(context).size.width / 2),
                              ),
                              SizedBox(
                                height: 6,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Container(
                                    color: Colors.black,
                                    height: 6,
                                    width: MediaQuery.of(context).size.width),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Container(
                                    color: Colors.black,
                                    height: 6,
                                    width: MediaQuery.of(context).size.width *
                                        0.75),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.black,
                                      ),
                                      height: 25,
                                      width:
                                          MediaQuery.of(context).size.width / 8,
                                      //    color: kSecondaryColor,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.black,
                                        ),
                                        height: 25,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                8,
                                        //    color: kSecondaryColor,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.black,
                                        ),
                                        height: 20,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                8,
                                        //    color: kSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }
          }
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("${widget.data['name']}",
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                        fontWeight: FontWeight.bold)),
              ),
              for (int i = 0; i < 6; i++)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xff080808)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width / 7,
                                height: MediaQuery.of(context).size.width / 7,
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration:
                                        BoxDecoration(color: Colors.black),
                                    height: 16,
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    decoration:
                                        BoxDecoration(color: Colors.black),
                                    height: 8,
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                  )
                                ],
                              )
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 10,
                                width: MediaQuery.of(context).size.width),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 10,
                                width: MediaQuery.of(context).size.width / 2),
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 6,
                                width: MediaQuery.of(context).size.width),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 6,
                                width:
                                    MediaQuery.of(context).size.width * 0.75),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.black,
                                  ),
                                  height: 25,
                                  width: MediaQuery.of(context).size.width / 8,
                                  //    color: kSecondaryColor,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.black,
                                    ),
                                    height: 25,
                                    width:
                                        MediaQuery.of(context).size.width / 8,
                                    //    color: kSecondaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.black,
                                    ),
                                    height: 20,
                                    width:
                                        MediaQuery.of(context).size.width / 8,
                                    //    color: kSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class ColumnBuilder extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final VerticalDirection verticalDirection;
  final int itemCount;

  const ColumnBuilder({
    Key key,
    @required this.itemBuilder,
    @required this.itemCount,
    this.mainAxisAlignment: MainAxisAlignment.start,
    this.mainAxisSize: MainAxisSize.max,
    this.crossAxisAlignment: CrossAxisAlignment.center,
    this.verticalDirection: VerticalDirection.down,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Column(
      crossAxisAlignment: this.crossAxisAlignment,
      mainAxisSize: this.mainAxisSize,
      mainAxisAlignment: this.mainAxisAlignment,
      verticalDirection: this.verticalDirection,
      children: new List.generate(
          this.itemCount, (index) => this.itemBuilder(context, index)).toList(),
    );
  }
}

class EpisodeCard extends StatelessWidget {
  final data;
  final index;
  List<Audio> playlist;

  EpisodeCard({@required this.data, this.index, this.playlist});

  SharedPreferences prefs;

  RegExp htmlMatch = RegExp(r'(\w+)');

  CancelToken _cancel = CancelToken();

  @override
  Widget build(BuildContext context) {
    final episodeObject = pro.Provider.of<PlayerChange>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => EpisodeView(episodeId: data['id'])));
        },
        child: Container(
          decoration: BoxDecoration(
            color: kSecondaryColor,
            borderRadius: BorderRadius.circular(5),
          ),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                data['isvideo'] == true
                    ? InkWell(
                        onTap: () {
                          episodeObject.audioPlayer.stop();
                          episodeObject.isVideo = true;
                          episodeObject.episodeObject = data;
                          episodeObject.videoSource = Video(
                              id: data['id'],
                              title: data['name'],
                              thumbnailUrl: data['podcast_image'],
                              episodeImage: data['image'],
                              author: data['author'],
                              url: data['url'],
                              album: data['podcast_name'],
                              podcastid: data['podcast_id'],
                              author_id: data['author_user_id'],
                              createdAt: data['published_at']);
                          episodeObject.miniplayerController
                              .animateToHeight(state: PanelState.MAX);
                          // episodeObject.betterPlayerController
                          //     .setupDataSource(BetterPlayerDataSource(
                          //   BetterPlayerDataSourceType.network,
                          //   episodeObject.videoSource.url,
                          //   notificationConfiguration:
                          //       BetterPlayerNotificationConfiguration(
                          //     showNotification: true,
                          //     title: "${episodeObject.videoSource.title}",
                          //     author: "${episodeObject.videoSource.author}",
                          //     imageUrl:
                          //         "${episodeObject.videoSource.thumbnailUrl}",
                          //   ),
                          // ));
                        },
                        // child: CachedNetworkImage(
                        //   imageBuilder: (context, imageProvider) {
                        //     return Stack(
                        //       children: [
                        //         AspectRatio(
                        //           aspectRatio: 1.0,
                        //           child: Container(
                        //             foregroundDecoration: BoxDecoration(
                        //                 gradient: LinearGradient(
                        //                     begin: Alignment.bottomLeft,
                        //                     end: Alignment.topRight,
                        //                     colors: [
                        //                   Colors.black.withOpacity(0.8),
                        //                   Colors.transparent
                        //                 ])),
                        //             decoration: BoxDecoration(
                        //               borderRadius: BorderRadius.circular(3),
                        //               image: DecorationImage(
                        //                   image: imageProvider,
                        //                   fit: BoxFit.cover),
                        //             ),
                        //             width: double.infinity,
                        //             height:
                        //                 MediaQuery.of(context).size.width / 8,
                        //           ),
                        //         ),
                        //         AspectRatio(
                        //             aspectRatio: 1.0,
                        //             child: Container(
                        //                 width: double.infinity,
                        //                 child: Center(
                        //                     child: Icon(
                        //                   Icons.play_circle_fill,
                        //                   size: 80,
                        //                   color: Colors.white.withOpacity(0.9),
                        //                 ))))
                        //       ],
                        //     );
                        //   },
                        //   imageUrl: data['image'] == null
                        //       ? data['podcast_image']
                        //       : data['image'],
                        //   memCacheWidth:
                        //       MediaQuery.of(context).size.width.floor(),
                        //   memCacheHeight:
                        //       MediaQuery.of(context).size.width.floor(),
                        //   placeholder: (context, url) => Stack(
                        //     children: [
                        //       AspectRatio(
                        //         aspectRatio: 1.0,
                        //         child: Container(
                        //           width: double.infinity,
                        //           decoration: BoxDecoration(
                        //               image: DecorationImage(
                        //                   image: CachedNetworkImageProvider(
                        //                       placeholderUrl),
                        //                   fit: BoxFit.cover)),
                        //         ),
                        //       ),
                        //       AspectRatio(
                        //           aspectRatio: 1.0,
                        //           child: Container(
                        //               width: double.infinity,
                        //               child: Center(
                        //                   child: Icon(
                        //                 Icons.play_circle_fill,
                        //                 size: 80,
                        //                 color: Colors.white.withOpacity(0.9),
                        //               ))))
                        //     ],
                        //   ),
                        //   errorWidget: (context, url, error) {
                        //     return Stack(
                        //       children: [
                        //         AspectRatio(
                        //           aspectRatio: 1.0,
                        //           child: Container(
                        //               width: double.infinity,
                        //               decoration: BoxDecoration(
                        //                   image: DecorationImage(
                        //                       image: CachedNetworkImageProvider(
                        //                           placeholderUrl),
                        //                       fit: BoxFit.cover))),
                        //         ),
                        //         AspectRatio(
                        //             aspectRatio: 1.0,
                        //             child: Container(
                        //                 width: double.infinity,
                        //                 child: Center(
                        //                     child: Icon(
                        //                   Icons.play_circle_fill,
                        //                   size: 80,
                        //                   color: Colors.white.withOpacity(0.9),
                        //                 ))))
                        //       ],
                        //     );
                        //   },
                        // ),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.38,
                            child: FadeInImage(
                              placeholder: AssetImage('assets/placeholder.gif'),
                              image: Image.network(
                                data['image'] == null
                                    ? data['podcast_image']
                                    : data['image'],
                                gaplessPlayback: true,
                                cacheHeight:
                                    (MediaQuery.of(context).size.width).floor(),
                                cacheWidth:
                                    (MediaQuery.of(context).size.width).floor(),
                              ).image,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(),

                // Row(
                //   children: [
                //     Container(
                //       width: MediaQuery.of(context).size.width / 8,
                //       height: MediaQuery.of(context).size.width / 8,
                //       child: AspectRatio(
                //         aspectRatio: 1.0,
                //         child: Container(
                //           width: MediaQuery.of(context).size.width / 8,
                //           height: MediaQuery.of(context).size.width / 8,
                //           child: FadeInImage(
                //             placeholder: AssetImage('assets/placeholder.gif'),
                //             image: Image.network(
                //               data['image'] == null
                //                   ? data['podcast_image']
                //                   : data['image'],
                //               gaplessPlayback: true,
                //               cacheHeight:
                //                   (MediaQuery.of(context).size.width * 0.32)
                //                       .floor(),
                //               cacheWidth:
                //                   (MediaQuery.of(context).size.width * 0.32)
                //                       .floor(),
                //             ).image,
                //           ),
                //         ),
                //       ),
                //     ),
                //     // CachedNetworkImage(
                //     //   imageBuilder: (context, imageProvider) {
                //     //     return Container(
                //     //       decoration: BoxDecoration(
                //     //         borderRadius: BorderRadius.circular(3),
                //     //         image: DecorationImage(
                //     //             image: imageProvider, fit: BoxFit.cover),
                //     //       ),
                //     //       width: MediaQuery.of(context).size.width / 8,
                //     //       height: MediaQuery.of(context).size.width / 8,
                //     //     );
                //     //   },
                //     //   imageUrl: data['image'] == null
                //     //       ? data['podcast_image']
                //     //       : data['image'],
                //     //   memCacheWidth: MediaQuery.of(context).size.width.floor(),
                //     //   memCacheHeight: MediaQuery.of(context).size.width.floor(),
                //     //   placeholder: (context, url) => Container(
                //     //     width: MediaQuery.of(context).size.width / 8,
                //     //     height: MediaQuery.of(context).size.width / 8,
                //     //     child: Image.asset('assets/images/Thumbnail.png'),
                //     //   ),
                //     //   errorWidget: (context, url, error) => Icon(Icons.error),
                //     // ),
                //     SizedBox(width: SizeConfig.screenWidth / 26),
                //     Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         GestureDetector(
                //           onTap: () {
                //             Navigator.push(
                //                 context,
                //                 CupertinoPageRoute(
                //                     builder: (context) =>
                //                         PodcastView(data['podcast_id'])));
                //           },
                //           child: Text(
                //             data['podcast_name'],
                //             textScaleFactor: 0.8,
                //             style: TextStyle(
                //                 // color: Color(
                //                 //     0xffe8e8e8),
                //                 fontSize: SizeConfig.safeBlockHorizontal * 4,
                //                 fontWeight: FontWeight.bold),
                //           ),
                //         ),
                //         Text(
                //           '${timeago.format(DateTime.parse(data['published_at']))}',
                //           textScaleFactor: 0.8,
                //           style: TextStyle(
                //               // color: Color(
                //               //     0xffe8e8e8),
                //               fontSize: SizeConfig.safeBlockHorizontal * 3),
                //         ),
                //       ],
                //     )
                //   ],
                // ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 20,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 8,
                      height: MediaQuery.of(context).size.width / 8,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 8,
                          child: FadeInImage(
                            placeholder: AssetImage('assets/placeholder.gif'),
                            image: Image.network(
                              data['image'] == null
                                  ? data['podcast_image']
                                  : data['image'],
                              gaplessPlayback: true,
                              cacheHeight:
                                  (MediaQuery.of(context).size.width * 0.32)
                                      .floor(),
                              cacheWidth:
                                  (MediaQuery.of(context).size.width * 0.32)
                                      .floor(),
                            ).image,
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    data['podcast_name'],
                    textScaleFactor: 0.8,
                    style: TextStyle(
                        // color: Color(
                        //     0xffe8e8e8),
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${timeago.format(DateTime.parse(data['published_at']))}',
                    textScaleFactor: 0.8,
                    style: TextStyle(
                        // color: Color(
                        //     0xffe8e8e8),
                        fontSize: SizeConfig.safeBlockHorizontal * 3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'],
                          textScaleFactor: 0.8,
                          style: TextStyle(
                              // color: Color(
                              //     0xffe8e8e8),
                              fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                              fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: data['summary'] == null
                              ? SizedBox(width: 0, height: 0)
                              : (htmlMatch.hasMatch(data['summary']) == true
                                  ? Text(
                                      parse(data['summary']).body.text,
                                      textScaleFactor: 0.8,
                                      maxLines: 2,
                                      style: TextStyle(
                                          // color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.2),
                                    )
                                  : Text(
                                      '${data['summary']}',
                                      textScaleFactor: 1.0,
                                      style: TextStyle(
                                          //      color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.2),
                                    )),
                        )
                      ],
                    ),
                  ),
                ),
                PlaybackButtons(
                  data: data,
                  index: index,
                  playlist: playlist,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaybackButtons extends StatefulWidget {
  final data;

  final int index;

  List<Audio> playlist;

  PlaybackButtons({@required this.data, this.index, this.playlist});

  @override
  _PlaybackButtonsState createState() => _PlaybackButtonsState();
}

class _PlaybackButtonsState extends State<PlaybackButtons>
    with AutomaticKeepAliveClientMixin {
  SharedPreferences prefs;

  var episodeData;

  bool isPlaying = false;

  Future getLocalPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      episodeData = widget.data;
      episodeData['isLoading'] = false;
    });

    return episodeData;
  }

  Future getVotingValue() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://rpc.ecency.com";
    print(url);
    var map = Map<String, dynamic>();
    map = {
      "jsonrpc": "2.0",
      "method": "bridge.get_post",
      "params": {
        'author': episodeData['author_hiveusername'],
        'permlink': episodeData['permlink'],
        'observer': ""
      },
      "id": 0
    };
    print(map);

    try {
      await dio.post(url, data: map).then((value) async {
        // print(value.data);
        if (value.data['result'] != null) {
          // print("${
          //     {
          //       'hive_earnings': value.data['result']['payout'],
          //       'net_votes': value.data['result']['active_votes'].length,
          //       'ifVoted': getIfVoted(value.data['result']['active_votes']),}
          //
          // }");
          var responsedata = {
            'hive_earnings': value.data['result']['payout'],
            'net_votes': value.data['result']['active_votes'].length,
            'ifVoted': await getIfVoted(value.data['result']['active_votes']),
            'isLoading': false,
          };
          setState(() {
            data = responsedata;
          });

          // return responsedata;
        }
      });
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  Future getIfVoted(List activeVotes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('HiveUserName') != null) {
      if (activeVotes
          .toString()
          .contains("${prefs.getString("HiveUserName")}")) {
        return true;
      } else {
        return false;
      }
    }
  }


  Future getComments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://rpc.ecency.com";
    print(url);
    var map = Map<String, dynamic>();
    map = {
      "jsonrpc": "2.0",
      "method": "bridge.get_discussion",
      "params": {
        'author': episodeData['author_hiveusername'],
        'permlink': episodeData['permlink'],
        'observer': ""
      },
      "id": 0
    };

    try{
      await dio.post(url, data: map).then((value) {
        print('///////////////////////////////////////////////////${value}');

        setState(() {
          commentData = value.data['result'];
        });

      });
    }catch(e){
      print(e);
    }
  }

  var data = Map<String, dynamic>();

  var commentData = Map<String, dynamic>();

  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    getLocalPreferences().then((value) {
      if (episodeData['permlink'] != null) {
        getVotingValue();
        getComments();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // var currentlyPlaying = Provider.of<PlayerChange>(context);
    var episodeObject = pro.Provider.of<PlayerChange>(context);
    try {
      return Container(
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (episodeData['permlink'] == null
                    ? SizedBox(
                        height: 0,
                      )
                    : (isLoading == true
                        ? Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Container(
                              height: 25,
                              width: MediaQuery.of(context).size.width / 6,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Color(0xffe8e8e8).withOpacity(0.5),
                                      width: 0.5),
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              Vibrate.feedback(FeedbackType.impact);
                              if (prefs.getString('HiveUserName') != null) {
                                setState(() {
                                  data['isLoading'] = true;
                                });
                                double _value = 50.0;

                                showModalBottomSheet(
                                    backgroundColor: Colors.transparent,
                                    context: context,
                                    builder: (context) {
                                      return ClipRect(
                                        child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaY: 15.0,
                                              sigmaX: 15.0,
                                            ),
                                            child: Container(
                                              child: UpvoteEpisode(
                                                  permlink:
                                                      widget.data['permlink'],
                                                  episode_id:
                                                      widget.data['id']),
                                            )),
                                      );
                                    }).then((value) {
                                  setState(() {
                                    data['net_votes'] = data['net_votes'] + 1;
                                    data['ifVoted'] = !data['ifVoted'];
                                  });
                                });

                                setState(() {
                                  data['isLoading'] = false;
                                });
                              } else {
                                showBarModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return HiveDetails();
                                    });
                              }
                            },
                            child: Container(
                              decoration: data['ifVoted'] == true
                                  ? BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        Color(0xff5bc3ef),
                                        Color(0xff5d5da8)
                                      ]),
                                      borderRadius: BorderRadius.circular(30))
                                  : BoxDecoration(
                                      border:
                                          Border.all(color: kSecondaryColor),
                                      borderRadius: BorderRadius.circular(30)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: Row(
                                  children: [
                                    data['isLoading'] == true
                                        ? Container(
                                            height: 17,
                                            width: 18,
                                            child: SpinKitPulse(
                                              color: Colors.blue,
                                            ),
                                          )
                                        : Icon(
                                            FontAwesomeIcons.chevronCircleUp,
                                            size: 15,
                                            // color:
                                            //     Color(0xffe8e8e8),
                                          ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        "${data['net_votes'] != null ? data['net_votes'] : ""}",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(fontSize: 12
                                            // color:
                                            //     Color(0xffe8e8e8)
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        '\$${data['hive_earnings'] != null ? data['hive_earnings'] : ""}',
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                          fontSize: 12,

                                          // color:
                                          //     Color(0xffe8e8e8)
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ))),
                episodeData['permlink'] == null
                    ? SizedBox(
                        height: 0,
                      )
                    : GestureDetector(
                        onTap: () {
                          if (prefs.getString('HiveUserName') != null) {
                            Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) => Comments(
                                          episodeObject: episodeData,

                                        )));
                          } else {
                            showBarModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return HiveDetails();
                                });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: kSecondaryColor),
                                borderRadius: BorderRadius.circular(30)),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.mode_comment_outlined,
                                    size: 14,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7),
                                    child: Text(
                                      "${commentData.keys.length }",
                                      textScaleFactor: 1.0,
                                      style: TextStyle(fontSize: 10
                                          // color:
                                          //     Color(0xffe8e8e8)
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                // episodeData['permlink'] == null ? SizedBox() : FutureBuilder(future: getComments(),builder: (context, snapshot){
                //   // return Container(child: Text("${snapshot.data}"),);
                //   if(snapshot.hasData){
                //     return Container(child: Text("${snapshot.data}"),);
                //   }else{
                //     return SizedBox();
                //   }
                // },),

                widget.data['isvideo'] == true
                    ? SizedBox()
                    : Container(
                        child: GestureDetector(
                          // splashColor: Colors.blue,
                          // splashFactory: InkRipple.splashFactory,

                          onTap: () {
                            setState(() {
                              isPlaying = true;
                            });
                            FeedbackType _vibtype = FeedbackType.impact;
                            Vibrate.feedback(FeedbackType.impact);

                            episodeObject.isVideo = false;
                            // episodeObject.betterPlayerController.pause();
                            if (widget.playlist == null) {
                              episodeObject.stop();
                              episodeObject.episodeObject = episodeData;
                              print(episodeObject.episodeObject.toString());
                              episodeObject.play();
                            } else {
                              showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  barrierColor: Colors.transparent,
                                  isDismissible: true,
                                  // bounce: true,
                                  context: context,
                                  builder: (context) {
                                    return Player2();
                                  });

                              episodeObject.audioPlayer
                                  .open(
                                      Playlist(
                                          audios: widget.playlist,
                                          startIndex: widget.index),
                                      showNotification: true)
                                  .then((value) {});
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 60),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(color: kSecondaryColor),
                                  borderRadius: BorderRadius.circular(30)),
                              child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline,
                                        size: 15,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          DurationCalculator(
                                              widget.data['duration']),
                                          textScaleFactor: 0.75,
                                          // style: TextStyle(
                                          //      color: Color(0xffe8e8e8)
                                          //     ),
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
            GestureDetector(
              onTap: () {
                share(episodeObject: widget.data);
              },
              child: Icon(
                Icons.ios_share,
                // size: 14,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return SizedBox(
        height: 0,
      );
    }
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class PodcastWidget extends StatefulWidget {
  final data;

  PodcastWidget({@required this.data});

  @override
  State<PodcastWidget> createState() => _PodcastWidgetState();
}

class _PodcastWidgetState extends State<PodcastWidget>
    with AutomaticKeepAliveClientMixin {
  AsyncMemoizer _memoizer = AsyncMemoizer();

  SharedPreferences prefs;

  CancelToken _cancel = CancelToken();

  Future generalisedApiCall(String apicall) async {
    return this._memoizer.runOnce(() async {
      Dio dio = Dio();
      prefs = await SharedPreferences.getInstance();
      String url =
          "https://api.aureal.one/public/$apicall?pageSize=10&user_id=${prefs.getString('userId')}";

      try {
        var response = await dio.get(url, cancelToken: _cancel);
        if (response.statusCode == 200) {
          return response.data['data'];
        }
      } catch (e) {
        print(e);
      }
    });
  }

  Future myFuture;

  @override
  void initState() {
    // TODO: implement initState
    myFuture = generalisedApiCall(widget.data['api']);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length == 0) {
            return SizedBox();
          } else {
            return Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("${widget.data['name']}",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 5,
                            fontWeight: FontWeight.bold)),
                    trailing: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(colors: [
                            Color(0xff5bc3ef),
                            Color(0xff5d5da8)
                          ]).createShader(bounds);
                        },
                        child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) {
                                    return SeeMore(data: widget.data);
                                  },
                                ),
                              );
                            },
                            child: Text(
                              "See more",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ))),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: double.infinity,
                    height: SizeConfig.blockSizeVertical * 25,
                    constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.17),
                    child: ListView.builder(
                      shrinkWrap: true,
                      addAutomaticKeepAlives: true,
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, int index) {
                        return PodcastCard(data: snapshot.data[index]);
                      },
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                  // Text("${snapshot.data}"),
                ],
              ),
            );
          }
        } else {
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text("${widget.data['name']}",
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.bold)),
                  trailing: Text(
                    "See more",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: double.infinity,
                  height: SizeConfig.blockSizeVertical * 25,
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.17),
                  child: ListView.builder(
                    shrinkWrap: true,
                    addAutomaticKeepAlives: true,
                    itemCount: 10,
                    itemBuilder: (context, int index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 0, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            // x
                            borderRadius: BorderRadius.circular(15),
                          ),
                          width: MediaQuery.of(context).size.width * 0.38,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CachedNetworkImage(
                                errorWidget: (context, url, error) {
                                  return Container(
                                    decoration: BoxDecoration(
                                        color: Color(0xff080808),
                                        // image: DecorationImage(
                                        //     image: NetworkImage(
                                        //         placeholderUrl),
                                        //     fit: BoxFit
                                        //         .cover),
                                        borderRadius: BorderRadius.circular(3)),
                                    width: MediaQuery.of(context).size.width *
                                        0.38,
                                    height: MediaQuery.of(context).size.width *
                                        0.38,
                                  );
                                },
                                imageBuilder: (context, imageProvider) {
                                  return Container(
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover),
                                        borderRadius: BorderRadius.circular(3)),
                                    width: MediaQuery.of(context).size.width *
                                        0.38,
                                    height: MediaQuery.of(context).size.width *
                                        0.38,
                                  );
                                },
                                memCacheHeight:
                                    (MediaQuery.of(context).size.height)
                                        .floor(),
                                imageUrl: placeholderUrl,
                                placeholder: (context, imageProvider) {
                                  return Container(
                                    decoration:
                                        BoxDecoration(color: Color(0xff080808)),
                                    height: MediaQuery.of(context).size.width *
                                        0.38,
                                    width: MediaQuery.of(context).size.width *
                                        0.38,
                                  );
                                },
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class PlaylistWidget extends StatelessWidget {
  final data;

  PlaylistWidget({@required this.data});

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio();
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";
    print(url); //TODO: Delete this print statement later

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print(e);
    }
  }

  SharedPreferences prefs;

  CancelToken _cancel = CancelToken();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: generalisedApiCall(data['api']),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length == 0) {
            return SizedBox();
          } else {
            try {
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text("${data['name']}",
                          style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5,
                              fontWeight: FontWeight.bold)),
                      trailing: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(colors: [
                              Color(0xff5bc3ef),
                              Color(0xff5d5da8)
                            ]).createShader(bounds);
                          },
                          child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) {
                                      return SeeMore(data: data);
                                    },
                                  ),
                                );
                              },
                              child: Text(
                                "See more",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ))),
                    ),
                    Container(
                      width: double.infinity,
                      height: SizeConfig.blockSizeVertical * 25,
                      constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.17),
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, int index) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 0, 8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return PlaylistView(
                                      playlistId: snapshot.data[index]['id']);
                                }));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width / 3,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    int.parse(snapshot.data[index]
                                                ['episodes_count']) <=
                                            4
                                        ? CachedNetworkImage(
                                            imageUrl: snapshot.data[index]
                                                ['episodes_images'][0],
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    3,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    3,
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover)),
                                              );
                                            },
                                          )
                                        : Container(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                      imageUrl: snapshot
                                                              .data[index][
                                                          'episodes_images'][0],
                                                    ),
                                                    CachedNetworkImage(
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                      imageUrl: snapshot
                                                              .data[index][
                                                          'episodes_images'][1],
                                                    )
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                      imageUrl: snapshot
                                                              .data[index][
                                                          'episodes_images'][2],
                                                    ),
                                                    CachedNetworkImage(
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover)),
                                                        );
                                                      },
                                                      imageUrl: snapshot
                                                              .data[index][
                                                          'episodes_images'][3],
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Text(
                                        "${snapshot.data[index]['playlist_name']}",
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: snapshot.data.length,
                      ),
                    ),
                  ],
                ),
              );
            } catch (e) {
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text("${data['name']}",
                          style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5,
                              fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      width: double.infinity,
                      height: SizeConfig.blockSizeVertical * 25,
                      constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.17),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, int index) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 0, 8),
                            child: Container(
                              width: MediaQuery.of(context).size.width / 3,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height:
                                        MediaQuery.of(context).size.width / 3,
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    decoration:
                                        BoxDecoration(color: Color(0xff080808)),
                                  )
                                  // Padding(
                                  //   padding: const EdgeInsets.symmetric(vertical: 5),
                                  //   child: Text("${snapshot.data[index]['playlist_name']}", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4,fontWeight: FontWeight.bold),),
                                  // )
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: snapshot.data.length,
                      ),
                    ),
                  ],
                ),
              );
            }
          }
        } else {
          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text("${data['name']}",
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: double.infinity,
                  height: SizeConfig.blockSizeVertical * 25,
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.17),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, int index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 0, 8),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.width / 3,
                                width: MediaQuery.of(context).size.width / 3,
                                decoration:
                                    BoxDecoration(color: Color(0xff080808)),
                              )
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(vertical: 5),
                              //   child: Text("${snapshot.data[index]['playlist_name']}", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4,fontWeight: FontWeight.bold),),
                              // )
                            ],
                          ),
                        ),
                      );
                    },
                    itemCount: 10,
                    shrinkWrap: true,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class SnippetWidget extends StatelessWidget {
  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio();
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";
    print(url); //TODO: Delete this print statement later

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print(e);
    }
  }

  SharedPreferences prefs;

  CancelToken _cancel = CancelToken();
  final data;

  SnippetWidget({@required this.data});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: generalisedApiCall(data['api']),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text("${data['name']}",
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.bold)),
                  trailing: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                                colors: [Color(0xff5bc3ef), Color(0xff5d5da8)])
                            .createShader(bounds);
                      },
                      child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) {
                                  return SeeMore(data: data);
                                },
                              ),
                            );
                          },
                          child: Text(
                            "See more",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ))),
                ),
                Container(
                  height: SizeConfig.blockSizeVertical * 32,
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.17),
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context,
                                CupertinoPageRoute(builder: (context) {
                              return SnippetStoryView(
                                data: snapshot.data,
                                index: index,
                              );
                            }));
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Stack(
                              children: [
                                Container(
                                  foregroundDecoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter),
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                            snapshot.data[index]
                                                ['podcast_image']),
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                Container(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            "${snapshot.data[index]['episode_name']}",
                                            maxLines: 2,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            "${snapshot.data[index]['podcast_name']}",
                                            maxLines: 1,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: snapshot.data.length,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  "${data['name']}",
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: SizeConfig.blockSizeVertical * 32,
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.17),
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          // Navigator.push(context, CupertinoPageRoute(builder: (context){
                          //   return SnippetStoryView(data: snapshot.data,  index: index,);
                          // }));
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Stack(
                            children: [
                              Container(
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter),
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xff080808),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: 10,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class SnippetStoryView extends StatefulWidget {
  final data;
  int index;

  SnippetStoryView({@required this.data, this.index});

  @override
  _SnippetStoryViewState createState() => _SnippetStoryViewState();
}

class _SnippetStoryViewState extends State<SnippetStoryView> {
  PageController _pageController;

  // AssetsAudioPlayer audioplayer = AssetsAudioPlayer();
  int currentIndex;

  var snippetPlayer;
  var episodeObject;

  Future getSnippetPlayer(BuildContext context) async {
    snippetPlayer = await pro.Provider.of<PlayerChange>(context, listen: false);
  }

  @override
  void initState() {
    _pageController = PageController(
        viewportFraction: 1.0, keepPage: true, initialPage: widget.index);
    // TODO: implement initState
    super.initState();

    getSnippetPlayer(context).then((value) {
      pro.Provider.of<PlayerChange>(context, listen: false).audioPlayer.stop();
      // pro.Provider.of<PlayerChange>(context, listen: false)
      //     .betterPlayerController
      //     .pause();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    snippetPlayer.snippetPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: widget.data.length,
            pageSnapping: true,
            controller: _pageController,
            itemBuilder: (context, int index) {
              currentIndex = index;
              return SwipeCard(
                clipObject: widget.data[index],
              );
            }),
      ),
    );
  }
}

class SubCategoryView extends StatefulWidget {
  final data;

  SubCategoryView({@required this.data});

  @override
  _SubCategoryViewState createState() => _SubCategoryViewState();
}

class _SubCategoryViewState extends State<SubCategoryView> {
  ScrollController _controller = ScrollController();

  SharedPreferences prefs;
  Dio dio = Dio();
  CancelToken _cancel = CancelToken();

  int page = 0;

  List feedData = [];

  Future getData() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/subcategoryPodcasts/${widget.data['id']}?pageSize=16&page=$page&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        if (page == 0) {
          setState(() {
            feedData = response.data['data'];
            page = page + 1;
          });
        } else {
          setState(() {
            feedData = feedData + response.data['data'];
            page = page + 1;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState

    getData();

    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        getData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.data['name']}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GridView.builder(
          controller: _controller,
          itemCount: feedData.length + 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                MediaQuery.of(context).orientation == Orientation.landscape
                    ? 3
                    : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: (1 / 1.36),
          ),
          itemBuilder: (context, int index) {
            if (index > feedData.length - 1) {
              return AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xff121212),
                    borderRadius: BorderRadius.circular(3),
                    image: DecorationImage(
                        image: CachedNetworkImageProvider(placeholderUrl),
                        fit: BoxFit.contain),
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (context) {
                      return PodcastView(feedData[index]['id']);
                    }));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedNetworkImage(
                        placeholder: (context, String url) {
                          return AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: Color(0xff121212),
                                    borderRadius: BorderRadius.circular(3)),
                              ));
                        },
                        imageUrl: feedData[index]['image'],
                        imageBuilder: (context, imageProvider) {
                          return AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  image: DecorationImage(
                                      image: imageProvider, fit: BoxFit.cover)),
                            ),
                          );
                        },
                        errorWidget: (context, url, error) => AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        placeholderUrl),
                                    fit: BoxFit.cover)),
                          ),
                        ),
                      ),
                      // SizedBox(height: 5,),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "${feedData[index]['name']}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${feedData[index]['author']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
    );
  }
}

class SeeMore extends StatefulWidget {
  final data;

  SeeMore({@required this.data});

  @override
  State<SeeMore> createState() => _SeeMoreState();
}

class _SeeMoreState extends State<SeeMore> {
  ScrollController _controller = ScrollController();

  SharedPreferences prefs;

  Dio dio = Dio();
  CancelToken _cancel = CancelToken();

  List feedData = [];
  int page = 0;

  List<Audio> playlist;

  void playListGenerator({List data}) async {
    var episodeObject = pro.Provider.of<PlayerChange>(context, listen: false);
    List<Audio> playable = [];
    for (int i = 0; i < data.length; i++) {
      var v = data[i];
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

    playlist = playable;
    // episodeObject.dispose();
  }

  Future getData({var apicall}) async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=16&page=$page&user_id=${prefs.getString('userId')}";
    print(url);

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        print(response.data);
        if (page == 0) {
          setState(() {
            feedData = response.data['data'];
            page = page + 1;
            if (widget.data['type'] == 'episode' ||
                widget.data['type'] == null) {
              playListGenerator(data: feedData);
            }
          });
        } else {
          setState(() {
            feedData = feedData + response.data['data'];
            page = page + 1;
            if (widget.data['type'] == 'episode' ||
                widget.data['type'] == null) {
              playListGenerator(data: feedData);
            }
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getData(apicall: widget.data['api']);
    super.initState();

    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        getData(apicall: widget.data['api']);
      }
    });
  }

  Widget _feedBuilder(BuildContext context, var data) {
    print(data['type']);
    switch (data['type']) {
      case "podcast":
        return GridView.builder(
            controller: _controller,
            itemCount: feedData.length + 2,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.of(context).orientation == Orientation.landscape
                      ? 3
                      : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: (1 / 1.36),
            ),
            itemBuilder: (context, int index) {
              if (index > feedData.length - 1) {
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Color(0xff121212),
                        borderRadius: BorderRadius.circular(3),
                        image: DecorationImage(
                            image: CachedNetworkImageProvider(placeholderUrl),
                            fit: BoxFit.contain)),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          CupertinoPageRoute(builder: (context) {
                        return PodcastView(feedData[index]['id']);
                      }));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedNetworkImage(
                          placeholder: (context, String url) {
                            return AspectRatio(
                                aspectRatio: 1.0,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: Color(0xff121212),
                                      borderRadius: BorderRadius.circular(3)),
                                ));
                          },
                          imageUrl: feedData[index]['image'],
                          imageBuilder: (context, imageProvider) {
                            return AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover)),
                              ),
                            );
                          },
                          errorWidget: (context, url, error) => AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  image: DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          placeholderUrl),
                                      fit: BoxFit.cover)),
                            ),
                          ),
                        ),
                        // SizedBox(height: 5,),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "${feedData[index]['name']}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${feedData[index]['author']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            });
        break;
      case "episode":
        return ListView.builder(
            controller: _controller,
            itemCount: feedData.length + 1,
            itemBuilder: (context, int index) {
              if (index > feedData.length - 1) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xff080808)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width / 7,
                                height: MediaQuery.of(context).size.width / 7,
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration:
                                        BoxDecoration(color: Colors.black),
                                    height: 16,
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Container(
                                    decoration:
                                        BoxDecoration(color: Colors.black),
                                    height: 8,
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                  )
                                ],
                              )
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 10,
                                width: MediaQuery.of(context).size.width),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 10,
                                width: MediaQuery.of(context).size.width / 2),
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 6,
                                width: MediaQuery.of(context).size.width),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                                color: Colors.black,
                                height: 6,
                                width:
                                    MediaQuery.of(context).size.width * 0.75),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.black,
                                  ),
                                  height: 25,
                                  width: MediaQuery.of(context).size.width / 8,
                                  //    color: kSecondaryColor,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.black,
                                    ),
                                    height: 25,
                                    width:
                                        MediaQuery.of(context).size.width / 8,
                                    //    color: kSecondaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.black,
                                    ),
                                    height: 20,
                                    width:
                                        MediaQuery.of(context).size.width / 8,
                                    //    color: kSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return EpisodeCard(
                  data: feedData[index],
                  index: index,
                  playlist: playlist,
                );
              }
            });
        break;
      default:
        return Container();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("${widget.data['name']}"),
        ),
        body: Stack(children: [
          _feedBuilder(context, widget.data),
          Align(alignment: Alignment.bottomCenter, child: BottomPlayer())
        ]));
  }
}

class PodcastCard extends StatelessWidget {
  final data;
  PodcastCard({@required this.data});

  void podcastShare() async {
    await FlutterShare.share(
        title: '${data['name']}',
        text:
            "Hey There, I'm listening to ${data['name']} on Aureal, here's the link for you https://aureal.one/podcast/${data['id']}");
  }

  void follow() async {
    print("Follow function started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/follow';
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['podcast_id'] = data['id'];

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 0, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => PodcastView(data['id'])));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          width: MediaQuery.of(context).size.width * 0.38,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.38,
                  child: FadeInImage(
                    placeholder: AssetImage('assets/placeholder.gif'),
                    image: Image.network(
                      data['image'],
                      gaplessPlayback: true,
                      cacheHeight:
                          (MediaQuery.of(context).size.width * 0.76).floor(),
                      cacheWidth:
                          (MediaQuery.of(context).size.width * 0.76).floor(),
                    ).image,
                  ),
                ),
              ),
              // CachedNetworkImage(
              //   errorWidget: (context, url, error) {
              //     return Container(
              //       decoration: BoxDecoration(
              //           image: DecorationImage(
              //               image: NetworkImage(placeholderUrl),
              //               fit: BoxFit.cover),
              //           borderRadius: BorderRadius.circular(3)),
              //       width: MediaQuery.of(context).size.width * 0.38,
              //       height: MediaQuery.of(context).size.width * 0.38,
              //     );
              //   },
              //   imageBuilder: (context, imageProvider) {
              //     return Container(
              //       decoration: BoxDecoration(
              //           image: DecorationImage(
              //               image: imageProvider, fit: BoxFit.cover),
              //           borderRadius: BorderRadius.circular(3)),
              //       width: MediaQuery.of(context).size.width * 0.38,
              //       height: MediaQuery.of(context).size.width * 0.38,
              //     );
              //   },
              //   memCacheHeight: (MediaQuery.of(context).size.height).floor(),
              //   imageUrl: data['image'],
              //   placeholder: (context, imageProvider) {
              //     return Container(
              //       decoration: BoxDecoration(
              //           image: DecorationImage(
              //               image: CachedNetworkImageProvider(placeholderUrl),
              //               fit: BoxFit.cover)),
              //       height: MediaQuery.of(context).size.width * 0.38,
              //       width: MediaQuery.of(context).size.width * 0.38,
              //     );
              //   },
              // ),
              SizedBox(
                height: 5,
              ),
              Text(
                data['name'],
                maxLines: 1,
                textScaleFactor: 1.0,
                overflow: TextOverflow.ellipsis,
                // style:
                //     TextStyle(color: Color(0xffe8e8e8)),
              ),
              Text(
                data['author'],
                maxLines: 2,
                textScaleFactor: 1.0,
                style: TextStyle(
                    fontSize: SizeConfig.safeBlockHorizontal * 2.5,
                    color: Color(0xffe777777)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowingPage extends StatefulWidget {
  @override
  _FollowingPageState createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage>
    with TickerProviderStateMixin {
  AnimationController animationController;

  String word;
  String author;
  String displayPicture;
  bool isLoading;
  String hiveUserName;
  var _firstPress = true;
  String communityName;
  String communityDescription;

  var followingList;

  Launcher launcher = Launcher();

  CommunityProvider communities;

  var currentlyPlaying = null;

  void getLocalData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      displayPicture = pref.getString('displayPicture');
      hiveUserName = pref.getString('HiveUserName');
    });
  }

  bool paginationLoading = false;

  bool _canBeDragged;

  ScrollController _scrollController;

  void getData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = true;
    });
  }

  SharedPreferences prefs;

  int count = 0;

  CommunityService service;

  int pageNumber = 0;

  void toggle() {
    animationController.isDismissed
        ? animationController.forward()
        : animationController.reverse();
  }

  var episodes = [];

  TabController _tabController;
  RegExp htmlMatch = RegExp(r'(\w+)');

  List favPodcast = [];

  int followedPodPageNumber = 0;

  void getFollowedPodcasts() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/followedPodcasts?user_id=${prefs.getString('userId')}&page=$followedPodPageNumber";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        if (followedPodPageNumber == 0) {
          setState(() {
            favPodcast = jsonDecode(response.body)['podcasts'];
            followedPodPageNumber = followedPodPageNumber + 1;
          });
        } else {
          setState(() {
            favPodcast = favPodcast + jsonDecode(response.body)['podcasts'];
            followedPodPageNumber = followedPodPageNumber + 1;
          });
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    print("Following podcasts done");

    setState(() {
      isLoading = false;
    });
  }

  int pagenumber = 0;

  List hiveEpisodes = [];

  void getHiveFollowedEpisode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/browseHiveEpisodesTest?user_id=${prefs.getString('userId')}&page=$pageNumber&pageSize=10";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        if (pageNumber != 0) {
          setState(() {
            isPaginationLoading = true;
            hiveEpisodes =
                hiveEpisodes + jsonDecode(response.body)['EpisodeResult'];
            pageNumber = pageNumber + 1;
          });
        } else {
          setState(() {
            hiveEpisodes = jsonDecode(response.body)['EpisodeResult'];
          });
          setState(() {
            for (var v in hiveEpisodes) {
              v['isLoading'] = false;
            }
            pageNumber = pageNumber + 1;
          });
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      hiveEpisodeLoading = false;
      isPaginationLoading = false;
      isFollowingPageLoading = false;
    });
  }

  bool isPaginationLoading = true;
  bool isFollowingPageLoading = true;

  ScrollController _podcastScrollController;

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
//    getCurrentUser();

    getData();
    getFollowedPodcasts();
    getHiveFollowedEpisode();
    _podcastScrollController = ScrollController();

    _podcastScrollController.addListener(() {
      if (_podcastScrollController.position.pixels ==
          _podcastScrollController.position.maxScrollExtent) {
        print("pagination happening");
        getFollowedPodcasts();
      }
    });

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        getHiveFollowedEpisode();
      }
    });
    getLocalData();

    _tabController = TabController(length: 2, vsync: this);
    // TODO: implement initState
    super.initState();
  }

  bool hiveEpisodeLoading = true;

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    var categories = pro.Provider.of<CategoriesProvider>(context);

    Future<void> _pullRefreshEpisodes() async {
      getFollowedPodcasts();
      getHiveFollowedEpisode();

      // await getFollowedPodcasts();
    }

    Future<bool> _onBackPressed() async {
      Navigator.pushNamedAndRemoveUntil(
          context, Home.id, ModalRoute.withName("/"));
      return false; // return true if the route to be popped
    }

    final themeProvider = pro.Provider.of<ThemeProvider>(context);
    RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();
    var episodeObject = pro.Provider.of<PlayerChange>(context);
    final mediaQueryData = MediaQuery.of(context);
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: NestedScrollView(
          physics: BouncingScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Colors.black,
                automaticallyImplyLeading: false,
                expandedHeight: 30,
                pinned: true,
                //     backgroundColor: kPrimaryColor,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(20),
                  child: Container(
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Row(
                              children: [
                                for (var v in categories.categoryList)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context,
                                          CupertinoPageRoute(
                                              builder: (context) {
                                        return CategoryView(categoryObject: v);
                                      }));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: kSecondaryColor),
                                            // color: Color(0xff3a3a3a),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 3),
                                          child: Center(
                                            child: Text(
                                              v['name'],
                                              textScaleFactor: mediaQueryData
                                                  .textScaleFactor
                                                  .clamp(0.5, 1.1)
                                                  .toDouble(),
                                              style: TextStyle(
                                                  //  color:
                                                  // Color(0xffe8e8e8),
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3.4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ];
          },
          body: RefreshIndicator(
            onRefresh: _pullRefreshEpisodes,
            child: ListView(
              controller: _scrollController,
              children: [
                Container(
                  child: WidgetANimator(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: Text(
                        //     "Your Favourites",
                        //     textScaleFactor: mediaQueryData
                        //         .textScaleFactor
                        //         .clamp(0.5, 1.3)
                        //         .toDouble(),
                        //     style: TextStyle(
                        //       //    color: Color(0xffe8e8e8),
                        //         fontSize:
                        //         SizeConfig.safeBlockHorizontal *
                        //             7,
                        //         fontWeight: FontWeight.bold),
                        //   ),
                        // ),
                        favPodcast == null
                            ? Container(
                                width: double.infinity,
                                height: MediaQuery.of(context).size.height / 5,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _podcastScrollController,
                                  children: [
                                    for (int i = 0; i < 10; i++)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          child: Column(
                                            children: [
                                              Container(
                                                child: Icon(Icons.add),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Color(0xff080808),
                                                ),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    4,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    4,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Color(0xff080808)),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      4,
                                                  height: 12,
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color: Color(0xff080808)),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    4,
                                                height: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                4.2,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: [
                                            for (var v in favPodcast)
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (context) =>
                                                              PodcastView(
                                                                  v['id'])));
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      CachedNetworkImage(
                                                        imageBuilder: (context,
                                                            imageProvider) {
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover),
                                                            ),
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
                                                          );
                                                        },
                                                        imageUrl: v['image'],
                                                        memCacheWidth:
                                                            (MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width)
                                                                .floor(),
                                                        memCacheHeight:
                                                            (MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width)
                                                                .floor(),
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
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
                                                          child: Image.asset(
                                                              'assets/images/Thumbnail.png'),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(Icons.error),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                vertical: 10),
                                                        child: Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                v['name'],
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  // color: Colors.white,
                                                                  fontSize:
                                                                      SizeConfig
                                                                              .safeBlockHorizontal *
                                                                          4,
                                                                ),
                                                              ),
                                                              Text(
                                                                v['author'],
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            0.9)
                                                                        .toDouble(),
                                                                maxLines: 2,
                                                                style: TextStyle(
                                                                    // color:
                                                                    //     Colors.white,
                                                                    fontSize: SizeConfig.safeBlockHorizontal * 3),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )),
                                  ],
                                ),
                              ),
                        hiveEpisodeLoading == true
                            ? Column(
                                children: [
                                  for (int i = 0; i < 50; i++)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Color(0xff080808)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            7,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            7,
                                                    decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Color(
                                                                    0xff161616)),
                                                        height: 16,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            3,
                                                      ),
                                                      SizedBox(
                                                        height: 5,
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Color(
                                                                    0xff161616)),
                                                        height: 8,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            4,
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Colors.black,
                                                    height: 10,
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Colors.black,
                                                    height: 10,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            2),
                                              ),
                                              SizedBox(
                                                height: 6,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Colors.black,
                                                    height: 6,
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 3),
                                                child: Container(
                                                    color: Colors.black,
                                                    height: 6,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.75),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 20),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: Colors.black,
                                                      ),
                                                      height: 25,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                      //    color: kSecondaryColor,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          color: Colors.black,
                                                        ),
                                                        height: 25,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            8,
                                                        //    color: kSecondaryColor,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          color: Colors.black,
                                                        ),
                                                        height: 20,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            8,
                                                        //    color: kSecondaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    for (var v in hiveEpisodes)
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                  builder: (context) =>
                                                      EpisodeView(
                                                          episodeId: v['id'])));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    new BoxShadow(
                                                      color: Colors.black54
                                                          .withOpacity(0.2),
                                                      blurRadius: 10.0,
                                                    ),
                                                  ],
                                                  color: themeProvider
                                                              .isLightTheme ==
                                                          true
                                                      ? Colors.white
                                                      : Color(0xff080808),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                width: double.infinity,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 20,
                                                      horizontal: 20),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          CachedNetworkImage(
                                                            imageBuilder: (context,
                                                                imageProvider) {
                                                              return Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  image: DecorationImage(
                                                                      image:
                                                                          imageProvider,
                                                                      fit: BoxFit
                                                                          .cover),
                                                                ),
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    7,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    7,
                                                              );
                                                            },
                                                            imageUrl:
                                                                v['image'],
                                                            memCacheWidth:
                                                                MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width
                                                                    .floor(),
                                                            memCacheHeight:
                                                                MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width
                                                                    .floor(),
                                                            placeholder:
                                                                (context,
                                                                        url) =>
                                                                    Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  7,
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  7,
                                                              child: Image.asset(
                                                                  'assets/images/Thumbnail.png'),
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                        error) =>
                                                                    Icon(Icons
                                                                        .error),
                                                          ),
                                                          SizedBox(
                                                              width: SizeConfig
                                                                      .screenWidth /
                                                                  26),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      CupertinoPageRoute(
                                                                          builder: (context) =>
                                                                              PodcastView(v['podcast_id'])));
                                                                },
                                                                child: Text(
                                                                  v['podcast_name'],
                                                                  textScaleFactor: mediaQueryData
                                                                      .textScaleFactor
                                                                      .clamp(
                                                                          0.1,
                                                                          1.2)
                                                                      .toDouble(),
                                                                  style: TextStyle(
                                                                      // color: Color(
                                                                      //     0xffe8e8e8),
                                                                      fontSize: SizeConfig.safeBlockHorizontal * 5,
                                                                      fontWeight: FontWeight.normal),
                                                                ),
                                                              ),
                                                              Text(
                                                                '${timeago.format(DateTime.parse(v['published_at']))}',
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            0.9)
                                                                        .toDouble(),
                                                                style: TextStyle(
                                                                    // color: Color(
                                                                    //     0xffe8e8e8),
                                                                    fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                vertical: 10),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                v['name'],
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.5,
                                                                            1)
                                                                        .toDouble(),
                                                                style: TextStyle(
                                                                    // color: Color(
                                                                    //     0xffe8e8e8),
                                                                    fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                                                                    fontWeight: FontWeight.bold),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        10),
                                                                child: v['summary'] ==
                                                                        null
                                                                    ? SizedBox(
                                                                        width:
                                                                            0,
                                                                        height:
                                                                            0)
                                                                    : (htmlMatch.hasMatch(v['summary']) ==
                                                                            true
                                                                        ? Text(
                                                                            parse(v['summary']).body.text,
                                                                            textScaleFactor:
                                                                                mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                            maxLines:
                                                                                2,
                                                                            style: TextStyle(
                                                                                // color: Colors.white,
                                                                                fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                          )
                                                                        : Text(
                                                                            '${v['summary']}',
                                                                            textScaleFactor:
                                                                                mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                            style: TextStyle(
                                                                                //      color: Colors.white,
                                                                                fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                          )),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                GestureDetector(
                                                                  onTap:
                                                                      () async {
                                                                    if (prefs.getString(
                                                                            'HiveUserName') !=
                                                                        null) {
                                                                      setState(
                                                                          () {
                                                                        v['isLoading'] =
                                                                            true;
                                                                      });
                                                                      double
                                                                          _value =
                                                                          50.0;
                                                                      showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return Dialog(
                                                                                backgroundColor: Colors.transparent,
                                                                                child: UpvoteEpisode(permlink: v['permlink'], episode_id: v['id']));
                                                                          }).then((value) async {
                                                                        print(
                                                                            value);
                                                                      });
                                                                      setState(
                                                                          () {
                                                                        v['ifVoted'] =
                                                                            !v['ifVoted'];
                                                                      });
                                                                      setState(
                                                                          () {
                                                                        v['isLoading'] =
                                                                            false;
                                                                      });
                                                                    } else {
                                                                      showBarModalBottomSheet(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return HiveDetails();
                                                                          });
                                                                    }
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    decoration: v['ifVoted'] ==
                                                                            true
                                                                        ? BoxDecoration(
                                                                            gradient:
                                                                                LinearGradient(colors: [
                                                                              Color(0xff5bc3ef),
                                                                              Color(0xff5d5da8)
                                                                            ]),
                                                                            borderRadius: BorderRadius.circular(
                                                                                30))
                                                                        : BoxDecoration(
                                                                            border:
                                                                                Border.all(color: kSecondaryColor),
                                                                            borderRadius: BorderRadius.circular(30)),
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                              .symmetric(
                                                                          vertical:
                                                                              5,
                                                                          horizontal:
                                                                              5),
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          v['isLoading'] == true
                                                                              ? Container(
                                                                                  height: 17,
                                                                                  width: 18,
                                                                                  child: SpinKitPulse(
                                                                                    color: Colors.blue,
                                                                                  ),
                                                                                )
                                                                              : Icon(
                                                                                  FontAwesomeIcons.chevronCircleUp,
                                                                                  size: 15,
                                                                                  // color:
                                                                                  //     Color(0xffe8e8e8),
                                                                                ),
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 8),
                                                                            child:
                                                                                Text(
                                                                              v['votes'].toString(),
                                                                              textScaleFactor: 1.0,
                                                                              style: TextStyle(fontSize: 12
                                                                                  // color:
                                                                                  //     Color(0xffe8e8e8)
                                                                                  ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding:
                                                                                const EdgeInsets.only(right: 4),
                                                                            child:
                                                                                Text(
                                                                              '\$${v['payout_value'].toString().split(' ')[0]}',
                                                                              textScaleFactor: 1.0,
                                                                              style: TextStyle(
                                                                                fontSize: 12,

                                                                                // color:
                                                                                //     Color(0xffe8e8e8)
                                                                              ),
                                                                            ),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    if (prefs.getString(
                                                                            'HiveUserName') !=
                                                                        null) {
                                                                      Navigator.push(
                                                                          context,
                                                                          CupertinoPageRoute(
                                                                              builder: (context) => Comments(
                                                                                    episodeObject: v,
                                                                                  )));
                                                                    } else {
                                                                      showBarModalBottomSheet(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return HiveDetails();
                                                                          });
                                                                    }
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                            8.0),
                                                                    child:
                                                                        Container(
                                                                      decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                              color:
                                                                                  kSecondaryColor),
                                                                          borderRadius:
                                                                              BorderRadius.circular(30)),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(4.0),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.mode_comment_outlined,
                                                                              size: 14,
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 7),
                                                                              child: Text(
                                                                                v['comments_count'].toString(),
                                                                                textScaleFactor: 1.0,
                                                                                style: TextStyle(fontSize: 10
                                                                                    // color:
                                                                                    //     Color(0xffe8e8e8)
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    print(v
                                                                        .toString()
                                                                        .contains(
                                                                            '.mp4'));
                                                                    if (v.toString().contains('.mp4') == true ||
                                                                        v.toString().contains('.m4v') ==
                                                                            true ||
                                                                        v.toString().contains('.flv') ==
                                                                            true ||
                                                                        v.toString().contains('.f4v') ==
                                                                            true ||
                                                                        v.toString().contains('.ogv') ==
                                                                            true ||
                                                                        v.toString().contains('.ogx') ==
                                                                            true ||
                                                                        v.toString().contains('.wmv') ==
                                                                            true ||
                                                                        v.toString().contains('.webm') ==
                                                                            true) {
                                                                      currentlyPlaying
                                                                          .stop();
                                                                      // Navigator.push(
                                                                      //     context,
                                                                      //     CupertinoPageRoute(builder:
                                                                      //         (context) {
                                                                      //   return PodcastVideoPlayer(
                                                                      //       episodeObject:
                                                                      //           v);
                                                                      // }));
                                                                    } else {
                                                                      if (v.toString().contains(
                                                                              '.pdf') ==
                                                                          true) {
                                                                        // Navigator.push(
                                                                        //     context,
                                                                        //     CupertinoPageRoute(
                                                                        // der:
                                                                        //             (context) {
                                                                        //   return PDFviewer(
                                                                        //       episodeObject:
                                                                        //           v);
                                                                        // }));
                                                                      } else {
                                                                        List<Audio>
                                                                            playable =
                                                                            [];
                                                                        for (var v
                                                                            in hiveEpisodes) {
                                                                          playable
                                                                              .add(Audio.network(
                                                                            v['url'],
                                                                            metas:
                                                                                Metas(
                                                                              id: '${v['id']}',
                                                                              title: '${v['name']}',
                                                                              artist: '${v['author']}',
                                                                              album: '${v['podcast_name']}',
                                                                              // image: MetasImage.network('https://www.google.com')
                                                                              image: MetasImage.network('${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                                            ),
                                                                          ));
                                                                        }
                                                                        episodeObject.playList =
                                                                            playable;
                                                                        episodeObject.audioPlayer.open(
                                                                            Playlist(
                                                                                audios: episodeObject.playList,
                                                                                startIndex: hiveEpisodes.indexOf(v)),
                                                                            showNotification: true);
                                                                      }
                                                                    }
                                                                  },
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            60),
                                                                    child:
                                                                        Container(
                                                                      decoration: BoxDecoration(
                                                                          border: Border.all(
                                                                              color:
                                                                                  kSecondaryColor),
                                                                          borderRadius:
                                                                              BorderRadius.circular(30)),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(5),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.play_circle_outline,
                                                                              size: 15,
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                              child: Text(
                                                                                DurationCalculator(v['duration']),
                                                                                textScaleFactor: 0.75,
                                                                                // style: TextStyle(
                                                                                //      color: Color(0xffe8e8e8)
                                                                                //     ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                share(
                                                                    episodeObject:
                                                                        v);
                                                              },
                                                              child: Icon(
                                                                Icons.ios_share,
                                                                // size: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    for (int i = 0; i < 2; i++)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Color(0xff080808)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              7,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              7,
                                                      decoration: BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                  color: Color(
                                                                      0xff161616)),
                                                          height: 16,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              3,
                                                        ),
                                                        SizedBox(
                                                          height: 5,
                                                        ),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                  color: Color(
                                                                      0xff161616)),
                                                          height: 8,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Colors.black,
                                                      height: 10,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Colors.black,
                                                      height: 10,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              2),
                                                ),
                                                SizedBox(
                                                  height: 6,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Colors.black,
                                                      height: 6,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Container(
                                                      color: Colors.black,
                                                      height: 6,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.75),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 20),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          color: Colors.black,
                                                        ),
                                                        height: 25,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            8,
                                                        //    color: kSecondaryColor,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 10),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            color: Color(
                                                                0xff161616),
                                                          ),
                                                          height: 25,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                          //    color: kSecondaryColor,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 10),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            color: Color(
                                                                0xff161616),
                                                          ),
                                                          height: 20,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                          //    color: kSecondaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Episode {
  final String episodeName; //Stream Name
  final String podcastName; //Category Name
  final String authorName; //Streamer Name
  final String listens; //views
  final String value; //value in USD

  Episode(
      {this.episodeName,
      this.podcastName,
      this.authorName,
      this.listens,
      this.value});
}

class Podcast {
  final String podcastName;
  final String authorName;
  final String category;
  final String listens;
  final String value;

  Podcast(
      {this.podcastName,
      this.authorName,
      this.category,
      this.listens,
      this.value});
}

class PodcastViewBuilder extends StatefulWidget {
  var podcastData;

  PodcastViewBuilder(@required this.podcastData);

  @override
  _PodcastViewBuilderState createState() => _PodcastViewBuilderState();
}

class _PodcastViewBuilderState extends State<PodcastViewBuilder> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
