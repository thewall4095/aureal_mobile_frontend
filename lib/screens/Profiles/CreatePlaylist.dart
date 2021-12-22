import 'dart:convert';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:fluttertoast/fluttertoast.dart' as toast;

class Createplaylist extends StatefulWidget {
  int episodeId;
  int playlist_id;
  Createplaylist({this.episodeId, this.playlist_id});

  @override
  _CreateplaylistState createState() => _CreateplaylistState();
}

class _CreateplaylistState extends State<Createplaylist> {
  Dio dio = Dio();

  List playlist = [];

  postreq.Interceptor intercept = postreq.Interceptor();

  Future addFullPlaylist(int toPlaylistId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String url = "https://api.aureal.one/private/addToPlaylist";
    var map = Map<String, dynamic>();
    map['playlist_id'] = toPlaylistId;
    map['user_id'] = prefs.getString('userId');
    map['from_playlist_id'] = widget.playlist_id;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      toast.Fluttertoast.showToast(msg: "Added to playlist");
      return response;
    } catch (e) {
      print(e);
      return true;
    }
  }

  void getPlaylist() async {
    print("/////////////// This is get Playlist");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getPlaylist/${prefs.getString("userId")}";

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

  Future addToPlaylist({int id, episodeId}) async {
    print("/////////////////This is add to Playlist");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/addToPlaylist";

    var map = Map<String, dynamic>();
    map['playlist_id'] = id;
    map['episode_id'] = episodeId;
    map['userId'] = prefs.getString('userId');

    print(map);

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      toast.Fluttertoast.showToast(msg: "Added to playlist");
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

  bool isPublic = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add to Playlist",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.4),
        ),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Container(
              child: ListView(
                children: [
                  for (var v in playlist)
                    ListTile(
                      onTap: () {
                        if (widget.playlist_id == null) {
                          addToPlaylist(
                                  id: v['id'], episodeId: widget.episodeId)
                              .then((value) {
                            Navigator.pop(context);
                          });
                        } else {
                          addFullPlaylist(v['id']);
                        }
                      },
                      title: Text("${v['playlist_name']}"),
                      trailing: v['ispublic'] == true
                          ? Icon(Icons.public)
                          : Icon(Icons.lock),
                    ),
                ],
              ),
            )),
            ListTile(
              onTap: () async {
                print("Create Playlist clicked");
                showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
                      return CreatePlaylistDialog();
                    }).then((value) async {
                  if (value != null) {
                    print("/////////////////////////////////////// $value");
                    print(value.runtimeType);
                    if (widget.playlist_id == null) {
                      await addToPlaylist(
                              episodeId: widget.episodeId,
                              id: jsonDecode(value.toString())['data'][0]['id'])
                          .then((value) {
                        Navigator.pop(context);
                      });
                    } else {
                      addFullPlaylist(
                              jsonDecode(value.toString())['data'][0]['id'])
                          .then((value) {
                        Navigator.pop(context);
                      });
                    }
                  }
                });
              },
              selected: true,
              selectedTileColor: Color(0xff222222),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Color(0xffe8e8e8),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text("NEW PLAYLIST")
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePlaylistDialog extends StatefulWidget {
  @override
  _CreatePlaylistDialogState createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  bool isPublic = true;

  String name;

  postreq.Interceptor intercept = postreq.Interceptor();

  Future createPlaylist() async {
    print("///////////////////this is create Playlist");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/createPlaylist";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['playlist_name'] = name;
    map['ispublic'] = isPublic;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      Navigator.pop(context, response);
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      backgroundColor: Color(0xff161616),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Create a new playlist",
              textScaleFactor: 1.0,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.safeBlockHorizontal * 4),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  name = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle:
                    TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.6),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Public"),
                value: isPublic,
                onChanged: (value) {
                  setState(() {
                    isPublic = value;
                  });
                }),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "CANCEL",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: () {
                    createPlaylist();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "CREATE",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
