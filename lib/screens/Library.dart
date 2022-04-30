import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/buttonPages/Downloads.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Home.dart';
import 'Profiles/CreatePlaylist.dart';
import 'Profiles/PlaylistView.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ListTile(
            //   onTap: () {
            //     Navigator.push(context, CupertinoPageRoute(builder: (context) {
            //       return History();
            //     }));
            //   },
            //   title: Text("History"),
            //   trailing: Icon(Icons.arrow_forward_ios),
            //   //  subtitle:Text("Your PlayList"),
            //   leading: Icon(Icons.history),
            //   contentPadding: EdgeInsets.all(5),
            //   horizontalTitleGap: 5,
            // ),
            ListTile(
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) {
                  return PlayListScreen();
                }));
              },
              title: Text("PlayList"),
              trailing: Icon(Icons.arrow_forward_ios),
              //   subtitle:Text("Your PlayList"),
              leading: Icon(Icons.play_arrow),
              contentPadding: EdgeInsets.all(5),
              horizontalTitleGap: 5,
            ),
            ListTile(
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) {
                  return DownloadPage();
                }));
              },
              title: Text("Downloads"),
              trailing: Icon(Icons.arrow_forward_ios),
              //  subtitle:Text("Your PlayList"),
              leading: Icon(Icons.download_outlined),
              contentPadding: EdgeInsets.all(5),
              horizontalTitleGap: 5,
            ),
            ListTile(
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) {
                  return ClipScreen();
                }));
              },
              title: Text("Clips"),
              trailing: Icon(Icons.arrow_forward_ios),
              // subtitle:Text("Your PlayList"),
              leading: Icon(Icons.text_snippet),
              contentPadding: EdgeInsets.all(5),
              horizontalTitleGap: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class PlayListScreen extends StatefulWidget {
  @override
  _PlayListScreenState createState() => _PlayListScreenState();
}

class _PlayListScreenState extends State<PlayListScreen> {
  Dio dio = Dio();

  List playlist = [];

  SharedPreferences prefs;
  Future getPlaylist() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getPlaylist/${prefs.getString('userId')}";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print(response.data);

        return response.data['playlists'];

        print(playlist);
        print(playlist[0]['episodes_images'].length);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  Future deletePlaylist(var playlistObject) async {
    String url = "https://api.aureal.one/private/deletePlaylist";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['playlist_id'] = playlistObject['id'];

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      return response;
    } catch (e) {
      print(e);
    }
  }

  Future myFuture;

  @override
  void initState() {
    // TODO: implement initState
    myFuture = getPlaylist();
    super.initState();
  }

  void sharePlaylist(int playlistId, var playlistObject) async {
    await FlutterShare.share(
        title: '${playlistObject['playlist_name']}',
        text:
            "Here's my playlist for you https://aureal.one/playlist/$playlistId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            "Your Playlists",
            textScaleFactor: 1.0,
            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.4),
          ),
        ),
        body: FutureBuilder(
            future: myFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.length == 0) {
                  return Container(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width / 2,
                                height: MediaQuery.of(context).size.width / 2,
                                child: Image.asset('assets/images/Mascot.png'),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Snap! you don't have any playlists yet.",
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 5),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Icon(Icons.download_outlined),
                              ),
                              Text(
                                "You can start creating and curating your own playlists Just start listening and add them.",
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(context,
                                  CupertinoPageRoute(builder: (context) {
                                return Home();
                              }));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: kSecondaryColor)
                                  //  color: kSecondaryColor,
                                  ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_forward_ios),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text(
                                      'Browse',
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 100,
                          )
                        ],
                      ),
                    ),
                  );
                } else {
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (var v in snapshot.data)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                              onTap: () {
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return PlaylistView(
                                    playlistId: v['id'],
                                  );
                                }));
                              },
                              leading: CircleAvatar(
                                radius: 25,
                                child: int.parse(v['episodes_count']) != 0
                                    ? (int.parse(v['episodes_count']) < 4
                                        ? CachedNetworkImage(
                                            imageUrl: v['episodes_images'][0],
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover)),
                                              );
                                            },
                                          )
                                        : Container(
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl:
                                                          v['episodes_images']
                                                              [0],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: 25,
                                                          width: 25,
                                                          // color: Colors.white,
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
                                                      imageUrl:
                                                          v['episodes_images']
                                                              [1],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: 25,
                                                          width: 25,
                                                          // color: Colors.white,
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
                                                      imageUrl:
                                                          v['episodes_images']
                                                              [2],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: 25,
                                                          width: 25,
                                                          // color: Colors.white,
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
                                                      imageUrl:
                                                          v['episodes_images']
                                                              [3],
                                                      imageBuilder: (context,
                                                          imageProvider) {
                                                        return Container(
                                                          height: 25,
                                                          width: 25,
                                                          // color: Colors.white,
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
                                          ))
                                    : SizedBox(),
                              ),
                              title: Text("${v['playlist_name']}"),
                              subtitle: Text("${v['episodes_count']} episodes"),
                              trailing: InkWell(
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
                                                  leading:
                                                      v['episodes_images']
                                                                  .length <
                                                              4
                                                          ? CircleAvatar(
                                                              radius: 25,
                                                              child:
                                                                  CachedNetworkImage(
                                                                imageUrl:
                                                                    v['episodes_images']
                                                                        [0],
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
                                                                              v['episodes_images'][0],
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              width: 25,
                                                                              height: 25,
                                                                              decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                            );
                                                                          },
                                                                        ),
                                                                        CachedNetworkImage(
                                                                          imageUrl:
                                                                              v['episodes_images'][1],
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
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
                                                                          imageUrl:
                                                                              v['episodes_images'][2],
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              width: 25,
                                                                              height: 25,
                                                                              decoration: BoxDecoration(image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                                            );
                                                                          },
                                                                        ),
                                                                        CachedNetworkImage(
                                                                          imageUrl:
                                                                              v['episodes_images'][3],
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
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
                                                      "${v['playlist_name']}"),
                                                  subtitle: Text(
                                                      "${v['episodes_count']} episodes"),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                Divider(),
                                                ListTile(
                                                  // onTap: () {
                                                  //   List<Audio> playable = [];
                                                  //   for (var v in playlistData) {
                                                  //     playable.add(Audio.network(
                                                  //       v['url'],
                                                  //       metas: Metas(
                                                  //         id: '${v['id']}',
                                                  //         title: '${v['name']}',
                                                  //         artist: '${v['author']}',
                                                  //         album: '${v['podcast_name']}',
                                                  //         // image: MetasImage.network('https://www.google.com')
                                                  //         image: MetasImage.network(
                                                  //             '${v['image'] == null ? v['podcast_image'] : v['image']}'),
                                                  //       ),
                                                  //     ));
                                                  //   }
                                                  //   playable.shuffle();
                                                  //   currentlyPlaying.playList = playable;
                                                  //   currentlyPlaying.audioPlayer.open(
                                                  //       Playlist(
                                                  //           audios:
                                                  //               currentlyPlaying.playList,
                                                  //           startIndex: 0),
                                                  //       showNotification: true);
                                                  // },
                                                  leading: Icon(Icons.shuffle),
                                                  title: Text("Shuffle play"),
                                                ),
                                                ListTile(
                                                  onTap: () {
                                                    showBarModalBottomSheet(
                                                        context: context,
                                                        builder: (context) {
                                                          return Createplaylist(
                                                              playlist_id:
                                                                  v['id']);
                                                        });
                                                  },
                                                  leading:
                                                      Icon(Icons.playlist_add),
                                                  title:
                                                      Text("Add to Playlist"),
                                                ),
                                                ListTile(
                                                  onTap: () {
                                                    sharePlaylist(v['id'], v);
                                                  },
                                                  leading:
                                                      Icon(Icons.ios_share),
                                                  title: Text("Share"),
                                                ),
                                                // playlistDetails['id'] ==
                                                //         prefs.getString("userId")
                                                //     ? ListTile(
                                                //         onTap: () async {
                                                //           await deletePlaylist(v)
                                                //               .then((value) async{
                                                //                 await getPlaylist();
                                                //             Navigator.pop(context);
                                                //           });
                                                //         },
                                                //         leading: Icon(Icons.delete),
                                                //         title: Text("Delete playlist"),
                                                //       )
                                                //     : SizedBox(),
                                              ],
                                            ),
                                          );
                                        });
                                  },
                                  child: Icon(Icons.more_vert))),
                        ),
                    ],
                  );
                }
              } else {
                return CircularProgressIndicator.adaptive();
              }
            }));
  }
}
