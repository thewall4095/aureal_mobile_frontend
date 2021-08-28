import 'dart:convert';
import 'dart:io';

import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Home.dart';

class RoomsPage extends StatefulWidget {
  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> with TickerProviderStateMixin {
  int pageNumber = 0;
  bool upDirection = true;
  ScrollController _controller;

  void getRooms() async {
    print("Rooms getting called");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getRooms?page=$pageNumber&pageSize=14';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          rooms = jsonDecode(response.body)['data'];
        });
        print(response.body);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  TabController _tabController;

  var rooms;

  bool isAudioOnly = true;
  bool isAudioMuted = true;
  bool isVideoMuted = true;

  _onAudioOnlyChanged(bool value) {
    setState(() {
      isAudioOnly = value;
    });
  }

  _onAudioMutedChanged(bool value) {
    setState(() {
      isAudioMuted = value;
    });
  }

  _onVideoMutedChanged(bool value) {
    setState(() {
      isVideoMuted = value;
    });
  }

  _joinMeeting({String roomId, String roomName, String displayName}) async {
    // Enable or disable any feature flag here
    // If feature flag are not provided, default values will be used
    // Full list of feature flags (and defaults) available in the README
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
      FeatureFlagEnum.CHAT_ENABLED: false,
    };
    if (!kIsWeb) {
      // Here is an example, disabling features for each platform
      if (Platform.isAndroid) {
        // Disable ConnectionService usage on Android to avoid issues (see README)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        // Disable PIP on iOS as it looks weird
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var options = JitsiMeetingOptions(room: roomId)
      ..serverURL = 'https://sessions.aureal.one'
      ..subject = roomName
      ..userDisplayName = displayName
      ..userEmail = 'emailText.text'
      // ..iosAppBarRGBAColor = iosAppBarRGBAColor.text
      ..audioOnly = true
      ..audioMuted = isAudioMuted
      ..videoMuted = isVideoMuted
      ..featureFlags.addAll(featureFlags)
      ..webOptions = {
        "roomName": roomName,
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "userInfo": {
          "displayName": 'Shubham',
          'avatarUrl': prefs.getString('displayPicture')
        }
      };

    debugPrint("JitsiMeetingOptions: $options");
    await JitsiMeet.joinMeeting(
      options,
      listener: JitsiMeetingListener(
          onConferenceWillJoin: (message) {
            debugPrint("${options.room} will join with message: $message");
          },
          onConferenceJoined: (message) {
            debugPrint("${options.room} joined with message: $message");
          },
          onConferenceTerminated: (message) {
            debugPrint("${options.room} terminated with message: $message");
          },
          genericListeners: [
            JitsiGenericListener(
                eventName: 'readyToClose',
                callback: (dynamic message) {
                  debugPrint("readyToClose callback");
                }),
          ]),
    );
  }

  void _onConferenceWillJoin(message) {
    debugPrint("_onConferenceWillJoin broadcasted with message: $message");
  }

  void _onConferenceJoined(message) {
    debugPrint("_onConferenceJoined broadcasted with message: $message");
  }

  void _onConferenceTerminated(message) {
    debugPrint("_onConferenceTerminated broadcasted with message: $message");
  }

  _onError(error) {
    debugPrint("_onError broadcasted: $error");
  }

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    _controller = ScrollController();

    _tabController = TabController(length: 2, vsync: this);
    getRooms();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    Launcher launcher = Launcher();

    Future<void> _pullRefresh() async {
      print('proceed');
    }

    Future<bool> _onBackPressed() async {
      Navigator.pushNamedAndRemoveUntil(
          context, Home.id, ModalRoute.withName("/"));
      return false; // return true if the route to be popped
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (_controller.position.userScrollDirection ==
            ScrollDirection.reverse) {
          setState(() {
            upDirection = false;
          });
        } else if (_controller.position.userScrollDirection ==
            ScrollDirection.forward) {
          setState(() {
            upDirection = true;
          });
        }
        return true;
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: null,
          label: Text('Create Room'),
          icon: Icon(Icons.add),
          isExtended: !upDirection,
        ),
        appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
            title: TabBar(
              isScrollable: true,
              automaticIndicatorColorAdjustment: true,
              indicatorSize: TabBarIndicatorSize.label,
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'All',
                ),
                Tab(
                  text: 'My Groups',
                )
              ],
            )),
        backgroundColor: Colors.transparent,
        body: TabBarView(
          controller: _tabController,
          children: [
            ListView.builder(
                controller: _controller,
                itemCount: rooms.length,
                itemBuilder: (context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 7.5),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xff222222),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: kPrimaryColor,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.stream,
                                            size:
                                                SizeConfig.safeBlockHorizontal *
                                                    3.5,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text('LIVE'),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            rooms[index]['roomParticipants'] == null
                                ? SizedBox()
                                : Container(
                                    height: (MediaQuery.of(context).size.width /
                                            9) *
                                        2.1,
                                    child: GridView(
                                      scrollDirection: Axis.horizontal,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              mainAxisSpacing: 10,
                                              crossAxisSpacing: 5,
                                              childAspectRatio: 1 / 1),
                                      children: [
                                        for (var v in rooms[index]
                                            ['roomParticipants'])
                                          CachedNetworkImage(
                                            imageUrl: v['user_image'],
                                            memCacheHeight:
                                                (MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        2)
                                                    .ceil(),
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    10,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                "${rooms[index]['title']}",
                                textScaleFactor: 1.0,
                                style: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 5,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                            Text(
                              "Unkle Bonehead & 377 people are here",
                              textScaleFactor: 1.0,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Color(0xffe8e8e8).withOpacity(0.5),
                                  fontSize: SizeConfig.safeBlockHorizontal * 3),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            InkWell(
                              onTap: () async {
                                await _joinMeeting(
                                  roomId: rooms[index]['roomid'],
                                  roomName: rooms[index]['title'],
                                );
                                print(
                                    'https://sessions.aureal.one/${rooms[index]['roomid']}');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Color(0xff191919),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 15),
                                  child: Text("join room"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            Container(),
          ],
        ),
      ),
    );
  }
}
