import 'package:auditory/screens/History.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/buttonPages/Downloads.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            ListTile(
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) {
                  return History();
                }));
              },
              title: Text("History"),
              trailing: Icon(Icons.arrow_forward_ios),
              //  subtitle:Text("Your PlayList"),
              leading: Icon(Icons.history),
              contentPadding: EdgeInsets.all(5),
              horizontalTitleGap: 5,
            ),
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

  void getPlaylist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getPlaylist/${prefs.getString('userId')}";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print(response.data);
        setState(() {
          playlist = response.data['playlists'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getPlaylist();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Your Playlists",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.4),
        ),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          SizedBox(
            height: 20,
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              child: Stack(
                children: [
                  Container(
                    color: Colors.blue,
                  ),
                  Center(child: Icon(Icons.add))
                ],
              ),
            ),
            title: Text("New Playlist"),
          ),
          for (var v in playlist)
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
                    child: v['episodes_images'].length < 4
                        ? CachedNetworkImage(
                            imageUrl: v['episodes_images'][0],
                            imageBuilder: (context, imageProvider) {
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
                                      imageUrl: v['episodes_images'][0],
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          height: 25,
                                          width: 25,
                                          // color: Colors.white,
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover)),
                                        );
                                      },
                                    ),
                                    CachedNetworkImage(
                                      imageUrl: v['episodes_images'][1],
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          height: 25,
                                          width: 25,
                                          // color: Colors.white,
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
                                      imageUrl: v['episodes_images'][2],
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          height: 25,
                                          width: 25,
                                          // color: Colors.white,
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover)),
                                        );
                                      },
                                    ),
                                    CachedNetworkImage(
                                      imageUrl: v['episodes_images'][3],
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          height: 25,
                                          width: 25,
                                          // color: Colors.white,
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
                  title: Text("${v['playlist_name']}"),
                  subtitle: Text("${v['episodes_count']} episodes"),
                  trailing: Icon(Icons.more_vert)),
            ),
        ],
      ),
    );
  }
}
