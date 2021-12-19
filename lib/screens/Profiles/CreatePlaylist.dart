import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;

class Createplaylist extends StatefulWidget {
  int episodeId;

  Createplaylist({@required this.episodeId});

  @override
  _CreateplaylistState createState() => _CreateplaylistState();
}

class _CreateplaylistState extends State<Createplaylist> {
  Dio dio = Dio();

  List playlist = [];

  postreq.Interceptor intercept = postreq.Interceptor();

  void getPlaylist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getPlaylist/${prefs.getString("userId")}";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print(response.data);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future createPlaylist({String playlistName}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/createPlaylist";

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['playlist_name'] = playlistName;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      return response;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future addToPlaylist({int id, episodeId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/private/addToPlayist";

    var map = Map<String, dynamic>();
    map['playlist_id'] = id;
    map['episode_id'] = episodeId;
    map['userId'] = prefs.getString('userId');

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
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
                children: [],
              ),
            )),
            ListTile(
              onTap: () async {
                print("Create Playlist clicked");
                showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) {
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
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 4),
                              ),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: "Title",
                                  labelStyle: TextStyle(
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3.6),
                                ),
                              ),
                              SwitchListTile(
                                  title: Text("Public"),
                                  value: isPublic,
                                  onChanged: (value) {
                                    setState(() {
                                      isPublic = value;
                                    });
                                  })
                            ],
                          ),
                        ),
                      );
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
