import 'dart:convert';
import 'dart:ui';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Profiles/EditPodcast.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Distribution.dart';
import 'EditEpisode.dart';

class EditablePodcastProfile extends StatefulWidget {
  var podcastObject;

  EditablePodcastProfile(this.podcastObject);

  @override
  _EditablePodcastProfileState createState() => _EditablePodcastProfileState();
}

class _EditablePodcastProfileState extends State<EditablePodcastProfile>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 1);

    getPodcastData();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _tabController.dispose();
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  var episodeList = [];
  bool isEpisodeListLoading = true;
  int pageNumber = 1;

  void getPodcastData() async {
    isEpisodeListLoading = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/podcast?podcast_id=${widget.podcastObject['id']}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      isEpisodeListLoading = false;

      if (response.statusCode == 200) {
        setState(() {
          episodeList = jsonDecode(response.body)['podcasts'][0]['Episodes'];
        });

//        setState(() {
//          hiveToken = prefs.getString('access_token');
//          print(hiveToken);
//        });

        print(episodeList);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  getMoreEpisodes() async {
    print('getting more episodes');
    String url =
        'https://api.aureal.one/public/podcast?podcast_id=${widget.podcastObject['id']}&page=$pageNumber';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          episodeList = episodeList +
              jsonDecode(response.body)['podcasts'][0]['Episodes'];
          pageNumber = pageNumber + 1;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void deleteEpisode({int episodeId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/delete';
    var map = Map<String, dynamic>();
    map['id'] = prefs.getString('userId');
    map['episode_id'] = episodeId;

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.toString());
  }

  void unPublishEpisode({int episodeId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/updateEpisode';
    var map = Map<String, dynamic>();
    map['id'] = prefs.getString('userId');
    map['episode_id'] = episodeId;
    map['status'] = false;

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);
    print(response.toString());
  }

  void publishEpisode({int episodeId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/updateEpisode';
    var map = Map<String, dynamic>();
    map['id'] = prefs.getString('userId');
    map['episode_id'] = episodeId;
    map['status'] = true;

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: kSecondaryColor,
            expandedHeight: MediaQuery.of(context).size.height / 2.5,
            flexibleSpace: FlexibleSpaceBar(
                background: Container(
              child: Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 6,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height / 6,
                          decoration: BoxDecoration(
                            color: Color(0xff2a3147),
//                            image: DecorationImage(
//                                image:
//                                    NetworkImage(widget.podcastObject['image']),
//                                fit: BoxFit.cover),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.blue.withOpacity(0.0),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.blue, width: 2)),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundImage: NetworkImage(
                                          widget.podcastObject['image']),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      print("Edit Podcast Clicked");
                                      Navigator.push(context,
                                          CupertinoPageRoute(
                                              builder: (context) {
                                        return EditPodcast(
                                          podcastObject: widget.podcastObject,
                                        );
                                      }));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border:
                                              Border.all(color: Colors.blue)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3, horizontal: 8),
                                        child: Text(
                                          "Edit Podcast",
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: SizeConfig
                                                      .blockSizeHorizontal *
                                                  3),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  widget.podcastObject['name'],
                                  textScaleFactor: 0.75,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize:
                                          SizeConfig.blockSizeHorizontal * 5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            widget.podcastObject['followers'].toString() +
                                " Followers" +
                                " . Created on: ${widget.podcastObject['createdAt']}",
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: SizeConfig.blockSizeHorizontal * 3),
                          ),
                        ),
                        Text(
                          widget.podcastObject['description'],
                          textScaleFactor: 0.75,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: SizeConfig.blockSizeHorizontal * 3),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context,
                                  CupertinoPageRoute(builder: (context) {
                                return Distribution(
                                  podcastObject: widget.podcastObject,
                                );
                              }));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xff2a3147),
                              ),
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    'Distribution',
                                    textScaleFactor: 0.75,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.blockSizeHorizontal *
                                                3.5),
                                  ),
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
            )),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: Container(
                color: Color(0xff2a3147),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        text: 'Episodes',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            isEpisodeListLoading == true
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SpinKitCircle(
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    color: kSecondaryColor,
                    child: Column(
                      children: <Widget>[
                        for (var v in episodeList)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              onTap: () {
                                print(v);
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (context) {
                                  return EditEpisode(
                                    episodeObject: v,
                                    podcastId: widget.podcastObject['id'],
                                  );
                                }));
                              },
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(v['image']),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  v['payout_value'] == null
                                      ? Text(
                                          "Not Published on Hive",
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: SizeConfig
                                                      .blockSizeHorizontal *
                                                  3),
                                        )
                                      : Text(
                                          'Current Payout: ${v['payout_value']}',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3),
                                        ),
                                  Text(
                                    v['status'] == true
                                        ? 'Published'
                                        : 'Not Published',
                                    textScaleFactor: 0.75,
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize:
                                            SizeConfig.blockSizeHorizontal * 3),
                                  )
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Container(
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  top: BorderSide(
                                                      color: Colors.blue,
                                                      width: 10))),
                                          height: 75,
                                          child: Column(
                                            children: [
                                              ListTile(
                                                onTap: () {
                                                  if (v['status'] == true) {
                                                    unPublishEpisode(
                                                        episodeId: v['id']);
                                                    setState(() {
                                                      v['status'] = false;
                                                    });
                                                  } else {
                                                    publishEpisode(
                                                        episodeId: v['id']);
                                                    setState(() {
                                                      v['status'] = true;
                                                    });
                                                  }
                                                  Navigator.pop(context);
                                                },
                                                title: Text(
                                                  v['status'] == true
                                                      ? 'Unpublish'
                                                      : 'Publish',
                                                  textScaleFactor: 0.75,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: SizeConfig
                                                              .blockSizeHorizontal *
                                                          4),
                                                ),
                                              )
                                            ],
                                          ),
                                        );
                                      });
                                },
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                v['name'],
                                textScaleFactor: 0.75,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ])),
        ],
//        controller: _controller,
      ),
//      bottomSheet: BottomPlayer(),
    );
  }
}
