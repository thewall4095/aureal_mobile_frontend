import 'dart:convert';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PublicProfile extends StatefulWidget {
  String userId;

  PublicProfile({@required this.userId});

  @override
  _PublicProfileState createState() => _PublicProfileState();
}

class _PublicProfileState extends State<PublicProfile>
    with TickerProviderStateMixin {
  var userData;

  void getProfileData(String userId) async {
    String url = 'https://api.aureal.one/public/users?user_id=${widget.userId}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(
            "//////////////////////////////////////////////////${response.body}");
        setState(() {
          userData = jsonDecode(response.body)['users'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  TabController _controller;

  bool isPodcastListLoading;

  @override
  void initState() {
    // TODO: implement initState
    getProfileData(widget.userId);
    _controller = TabController(vsync: this, length: 5);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.ios_share),
                  onPressed: () {
                    print("profile pressed");
                  },
                )
              ],
              expandedHeight: MediaQuery.of(context).size.height / 2,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: userData['img'],
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.width / 5.5,
                                  width:
                                      MediaQuery.of(context).size.width / 5.5,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover)),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${userData['fullname']}",
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 5,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text("@${userData['username']}"),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Text(
                                  "Neque porro quisquam est qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit..."),
                            ),
                            Row(
                              children: [
                                RichText(
                                    text: TextSpan(
                                        text: "1.4M ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                        children: [
                                      TextSpan(
                                          text: "Followers",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal)),
                                    ])),
                                SizedBox(
                                  width: 20,
                                ),
                                RichText(
                                    text: TextSpan(
                                        text: "1.4M ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                        children: [
                                      TextSpan(
                                          text: "Followers",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal)),
                                    ])),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Icon(FontAwesomeIcons.instagram),
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Icon(FontAwesomeIcons.twitter),
                                  ),
                                  Icon(FontAwesomeIcons.linkedin)
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(colors: [
                                    Color(0xff5d5da8),
                                    Color(0xff5bc3ef)
                                  ])),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 10),
                                child: Text("Follow"),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 16,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    color: Color(0xff161616),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TabBar(
                          enableFeedback: true,
                          isScrollable: true,
                          controller: _controller,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: [
                            Tab(
                              text: 'Home',
                            ),
                            Tab(
                              text: 'Podcast',
                            ),
                            Tab(
                              text: 'Live Rooms',
                            ),
                            Tab(
                              text: 'Clips',
                            ),
                            Tab(
                              text: 'Snippets',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ];
        },
        body: TabBarView(
          controller: _controller,
          children: [
            Container(),
            Container(),
            Container(),
            Container(),
            Container(),
          ],
        ),
      ),
    );
  }
}
