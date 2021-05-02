import 'dart:convert';

import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/screens/recorderApp/recorderpages/CreatePodcast.dart';
import 'package:auditory/screens/recorderApp/recorderpages/PublishEpisode.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class SelectPodcast extends StatefulWidget {
  static const String id = "Select Podcast";

  var userId;
  var currentEpisodeId;

  SelectPodcast({this.userId, this.currentEpisodeId});

  @override
  _SelectPodcastState createState() => _SelectPodcastState();
}

class _SelectPodcastState extends State<SelectPodcast> {
  var podcastList = [];
  bool isLoading;

  void getPodcasts() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/podcast?user_id=${prefs.getString('userId')}';
    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['podcasts'];
      setState(() {
        podcastList = data;
      });
      print(podcastList);
    } else {
      print("Some error occurred");
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPodcasts();
  }

  @override
  Widget build(BuildContext context) {
    var communities = Provider.of<CommunityProvider>(context);
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Select Podcast",
          style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        color: kPrimaryColor,
        child: podcastList.length == 0
            ? Stack(
                children: <Widget>[
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image:
                                AssetImage('assets/images/CreatePodcast.png'),
                            fit: BoxFit.contain)),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "Hey!, You don't have a podcast yet, Please create one here",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.safeBlockHorizontal * 3),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, CreatePodcast.id)
                                .then((value) {
                              getPodcasts();
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 1)),
                            child: Center(
                              child: Text(
                                "Create Podcast",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      )
                    ],
                  )
                ],
              )
            : Stack(
                children: <Widget>[
                  ListView(
                    children: <Widget>[
                      for (var v in podcastList)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Publish(
                                  userId: widget.userId,
                                  currentEpisodeId: widget.currentEpisodeId,
                                  currentPodcastId: v['id'],
                                );
                              }));
                            },
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  height: SizeConfig.safeBlockVertical * 30,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                          image: NetworkImage(v['image']),
                                          fit: BoxFit.cover)),
                                ),
                                Container(
                                  height: SizeConfig.safeBlockVertical * 30,
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.5),
                                            Colors.white.withOpacity(0.5)
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight),
                                      borderRadius: BorderRadius.circular(8),
                                      color: kSecondaryColor),
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      children: <Widget>[
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
//                                    Container(
//                                      height: 60,
//                                      width: 60,
//                                      decoration: BoxDecoration(
//                                          borderRadius:
//                                              BorderRadius.circular(3),
//                                          image: DecorationImage(
//                                              image: v['image'] != ''
//                                                  ? NetworkImage(v['image'])
//                                                  : AssetImage(
//                                                      'assets/images/Favicon.png'),
//                                              fit: BoxFit.cover),
//                                          color: Colors.white),
//                                    ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      v['name'],
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                    // Text(
                                                    //   v['author'],
                                                    //   style: TextStyle(
                                                    //       color: Colors.white,
                                                    //       fontSize: 14),
                                                    // )
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, CreatePodcast.id)
                                .then((value) {
                              getPodcasts();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            height: 50,
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                "Create New Podcast",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      )
                    ],
                  )
                ],
              ),
      ),
    );
  }
}
