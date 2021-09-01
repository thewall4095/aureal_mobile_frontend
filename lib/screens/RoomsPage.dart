import 'dart:convert';
import 'dart:io';

import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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

  List rooms = [];

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
          "displayName": prefs.getString('userName'),
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
          onPressed: () {
            showBarModalBottomSheet(
                context: context,
                builder: (context) {
                  return CreateRoom();
                });
          },
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
            rooms.length == 0
                ? ListView.builder(
                    controller: _controller,
                    itemCount: 50,
                    itemBuilder: (context, int index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 7.5),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0xff222222),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Color(0xff161616)),
                                        height: 15,
                                        width: 60,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Container(
                                        height: 15,
                                        width: 60,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Color(0xff161616)),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  child: Container(
                                    height: (MediaQuery.of(context).size.width /
                                            9) *
                                        2.1,
                                    child: GridView.builder(
                                      scrollDirection: Axis.horizontal,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: MediaQuery.of(context)
                                                    .orientation ==
                                                Orientation.landscape
                                            ? 3
                                            : 2,
                                        crossAxisSpacing: 5,
                                        mainAxisSpacing: 5,
                                        childAspectRatio: (1 / 1),
                                      ),
                                      itemBuilder: (context, index) {
                                        return CircleAvatar(
                                          backgroundColor: Color(0xff161616),
                                        );
                                      },
                                      itemCount: 10,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    height: 15,
                                    width:
                                        MediaQuery.of(context).size.width / 5,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xff161616)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Container(
                                    height: 50,
                                    width: MediaQuery.of(context).size.width *
                                        0.60,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xff161616)),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Color(0xff161616)),
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  height: 10,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width / 5,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Color(0xff161616)),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                : ListView.builder(
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: kPrimaryColor,
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.stream,
                                                size: SizeConfig
                                                        .safeBlockHorizontal *
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
                                        height:
                                            (MediaQuery.of(context).size.width /
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
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            10,
                                                    width:
                                                        MediaQuery.of(context)
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
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
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3),
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

class CreateRoom extends StatefulWidget {
  @override
  _CreateRoomState createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {
  var navigatorValue;

  Dio dio = Dio();

  void startTheLiveStream() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/addNewRoom';

    var map = Map<String, dynamic>();

    if (selectedCommunity.toString().toLowerCase().contains('title') == true) {
      map['community_id'] = selectedCommunity['id'];
    }

    map['toHive'] = publishToHive;
    map['to_recording'] = enableRecording;
    map['description'] = _nameOfPodcast;
    map['hostuserid'] = prefs.getString('userId');
    map['title'] = _roomName;
    if (pickedSchedule != null) {
      map['scheduledtime'] = pickedSchedule;
    }

    FormData formData = FormData.fromMap(map);
    try {
      var response = await dio.post(url, data: formData);
      print(response.data);
    } catch (e) {
      print(e);
    }

    //TODO
    //community_id
    //to_hive
    //to_recording
    //scheduleAt
    //Create a page with getRoomDetails -----> Room Screen
  }

  String _roomName;
  String _nameOfPodcast;
  bool enableRecording = false;
  bool publishToHive = false;

  var selectedCommunity = Map<String, dynamic>();

  var pickedSchedule;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xff161616),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Name of Room",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                        decoration: BoxDecoration(
                            color: Color(0xff222222),
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextField(
                            decoration:
                                InputDecoration(border: InputBorder.none),
                            onChanged: (value) {
                              setState(() {
                                _roomName = value;
                              });
                            },
                          ),
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'What do you want to talk about',
                      style:
                          TextStyle(color: Color(0xffe8e8e8).withOpacity(0.5)),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Name of the show or podcast",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                        decoration: BoxDecoration(
                            color: Color(0xff222222),
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextField(
                            decoration:
                                InputDecoration(border: InputBorder.none),
                            onChanged: (value) {
                              setState(() {
                                _nameOfPodcast = value;
                              });
                            },
                          ),
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Leave it empty of you don't have one",
                      style:
                          TextStyle(color: Color(0xffe8e8e8).withOpacity(0.5)),
                    )
                  ],
                ),
              ),
              ListTile(
                onTap: () {
                  showBarModalBottomSheet(
                      enableDrag: true,
                      context: context,
                      builder: (context) {
                        return CommunitySelector();
                      }).then((value) {
                    setState(() {
                      navigatorValue = value;
                      if (navigatorValue[1] == true) {
                        selectedCommunity['title'] = navigatorValue[0][1];
                        selectedCommunity['id'] = navigatorValue[0][0];
                        print(selectedCommunity);
                      } else {
                        selectedCommunity = navigatorValue[0];
                        print(selectedCommunity);
                      }
                    });
                  });
                },
                contentPadding: EdgeInsets.zero,
                title: Text("Select a community"),
                subtitle: Text("Choose an audience for this room"),
                trailing: selectedCommunity.containsKey('title') == false
                    ? IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                  color: Color(0xff222222),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 14,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text("${selectedCommunity['title']}"),
                                  ],
                                ),
                              )),
                          Icon(Icons.arrow_forward_ios)
                        ],
                      ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Enable Recording"),
                subtitle:
                    Text("You can use this recording to add to your shows"),
                trailing: Switch(
                  value: enableRecording,
                  onChanged: (value) {
                    setState(() {
                      enableRecording = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Publish on Hive"),
                subtitle:
                    Text("You can use this recording to add to your shows"),
                trailing: Switch(
                  value: publishToHive,
                  onChanged: (value) {
                    print(value);
                    setState(() {
                      publishToHive = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ),
              ListTile(
                onTap: () async {
                  DateTime pickedDate;
                  TimeOfDay pickedTime;
                  pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030));
                  pickedTime = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now());
                  print(pickedDate.toString());
                  print(pickedTime.toString());
                  print(pickedTime
                      .toString()
                      .split('(')[1]
                      .toString()
                      .split(')')[0]);
                  setState(() {
                    pickedSchedule =
                        "${DateFormat('EE MMM d yyyy').format(pickedDate)} ${pickedTime.hour}:${pickedTime.minute}:00 GMT+${DateTime.now().timeZoneOffset.toString().split(':')[0]}${DateTime.now().timeZoneOffset.toString().split(':')[1]}";
                  });
                  print(pickedSchedule);
                  print(DateTime.now().timeZoneOffset);
                  print("${pickedDate.weekday}");
                  print(pickedSchedule);
                },
                contentPadding: EdgeInsets.zero,
                title: Text("Schedule you room"),
                subtitle: Text(
                  pickedSchedule == null
                      ? "Leave it empty if you want to start immediately"
                      : "Your room is Scheduled at $pickedSchedule",
                  style: TextStyle(
                      color: pickedSchedule == null
                          ? Color(0xffe8e8e8)
                          : Colors.blue),
                ),
                trailing: pickedSchedule == null
                    ? IconButton(
                        icon: Icon(Icons.schedule_outlined),
                      )
                    : IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            pickedSchedule = null;
                          });
                        },
                      ),
              ),
              SizedBox(
                height: 30,
              ),
              Center(
                child: InkWell(
                  onTap: () {
                    startTheLiveStream();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 12),
                      child: Text(
                        pickedSchedule == null ? "Go Live" : "Schedule",
                        textScaleFactor: 1.0,
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunitySelector extends StatefulWidget {
  @override
  _CommunitySelectorState createState() => _CommunitySelectorState();
}

class _CommunitySelectorState extends State<CommunitySelector>
    with TickerProviderStateMixin {
  var selectedCommunity;

  bool isLoading = false;

  TabController _tabController;

  List searchResults = [];

  List _allCommunities = [];

  List _followedCommunities = [];

  void getFollowedCommunities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getFollowedCommunities?hive_username=${prefs.getString('HiveUserName')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _followedCommunities =
              jsonDecode(response.body)['followed_hive_communities'];
          print(_followedCommunities);
          for (var v in _followedCommunities) {
            v[3] = false;
          }
        });
        print(response.body);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getHiveCommunities() async {
    setState(() {
      isLoading = true;
    });
    String url = 'https://api.aureal.one/public/getHiveCommunities';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          _allCommunities = jsonDecode(response.body)['hive_communities'];
          for (var v in _allCommunities) {
            v['isSelected'] = false;
          }
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void searchForCommunity(String query) async {
    if (_tabController.index == 0) {
      for (var v in _followedCommunities) {
        if (v[1].toString().toLowerCase().contains(query.toLowerCase()) ==
            true) {
          setState(() {
            searchResults.add(v);
          });
        }
        print(searchResults.toSet().toList());
      }
    }
    if (_tabController.index == 1) {
      for (var v in _allCommunities) {
        if (v['title'].toString().toLowerCase().contains(query.toLowerCase()) ==
            true) {
          setState(() {
            searchResults.add(v);
          });
          print(searchResults.toSet().toList());
        }
      }
    }
    if (_tabController.indexIsChanging == true) {
      setState(() {
        searchResults = [];
      });
    }
  }

  String queryValue;

  @override
  void initState() {
    getHiveCommunities();
    getFollowedCommunities();
    // TODO: implement initState
    _tabController = TabController(vsync: this, length: 2);
    super.initState();
  }

  bool value = false;
  bool isFollowed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   elevation: 0,
      //   title: Text(
      //     "Select a Hive Community",
      //     textScaleFactor: 1.0,
      //     style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
      //   ),
      // ),
      // body: Container(
      //   child: Padding(
      //     padding: const EdgeInsets.all(15),
      //     child: Column(
      //       children: [
      //         Container(
      //           decoration: BoxDecoration(
      //               color: Color(0xff222222),
      //               borderRadius: BorderRadius.circular(8)),
      //           child: Padding(
      //             padding: const EdgeInsets.symmetric(horizontal: 15),
      //             child: TextField(
      //               decoration: InputDecoration(border: InputBorder.none),
      //               onChanged: (value) {
      //                 if (value.length > 3) {
      //                   getHiveCommunities(value);
      //                 }
      //               },
      //             ),
      //           ),
      //         ),
      //         Column(
      //           children: [
      //             for (var v in searchResults)
      //               ListTile(
      //                 title: Text("${v['title']}"),
      //               )
      //           ],
      //         )
      //       ],
      //     ),
      //   ),
      // ),
      body: NestedScrollView(
        physics: BouncingScrollPhysics(),
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              centerTitle: true,
              title: Text(
                "Select a group",
                textScaleFactor: 1.0,
                style:
                    TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
              ),
              // expandedHeight: MediaQuery.of(context).size.height / 4,
              bottom: PreferredSize(
                preferredSize:
                    Size.fromHeight(MediaQuery.of(context).size.height / 5),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Select an audience for this room"),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xff222222),
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: TextField(
                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(top: 15),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.search)),
                              onChanged: (value) {
                                setState(() {
                                  queryValue = value;
                                });
                                if (value.length > 2) {
                                  searchForCommunity(value);
                                } else {
                                  setState(() {
                                    searchResults = [];
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.label,
                            isScrollable: true,
                            controller: _tabController,
                            tabs: [
                              Tab(
                                text: 'My Groups',
                              ),
                              Tab(
                                text: 'All Groups',
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          child: TabBarView(
            controller: _tabController,
            children: [
              Container(
                child: queryValue != null &&
                        queryValue != '' &&
                        _tabController.index == 0
                    ? ListView(children: [
                        for (var v in searchResults.toSet().toList())
                          ListTile(
                            leading: CircleAvatar(
                              child: Icon(Icons.group),
                            ),
                            title: Text("${v[1]}"),
                            trailing: Radio(
                                activeColor: Colors.blue,
                                value: v[3],
                                groupValue: true,
                                onChanged: (value) {
                                  setState(() {
                                    v[3] = true;
                                    selectedCommunity = v;
                                    isFollowed = true;
                                  });
                                  Navigator.pop(
                                      context, [selectedCommunity, true]);
                                }),
                          ),
                      ])
                    : ListView(
                        children: [
                          for (var v in _followedCommunities)
                            ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.group),
                              ),
                              title: Text("${v[1]}"),
                              trailing: Radio(
                                  activeColor: Colors.blue,
                                  value: v[3],
                                  groupValue: true,
                                  onChanged: (value) {
                                    setState(() {
                                      v[3] = true;
                                      selectedCommunity = v;
                                      isFollowed = true;
                                    });
                                    Navigator.pop(
                                        context, [selectedCommunity, true]);
                                  }),
                            ),
                        ],
                      ),
              ),
              Container(
                child: queryValue != null &&
                        queryValue != '' &&
                        _tabController.index == 1
                    ? ListView(
                        children: [
                          for (var v in searchResults.toSet().toList())
                            ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.group),
                              ),
                              title: Text("${v['title']}"),
                              trailing: Radio(
                                  activeColor: Colors.blue,
                                  value: v['isSelected'],
                                  groupValue: true,
                                  onChanged: (value) {
                                    setState(() {
                                      v['isSelected'] = true;
                                      selectedCommunity = v;
                                    });
                                    Navigator.pop(
                                        context, [selectedCommunity, false]);
                                  }),
                            ),
                        ],
                      )
                    : ListView(
                        children: [
                          for (var v in _allCommunities)
                            ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.group),
                              ),
                              title: Text("${v['title']}"),
                              trailing: Radio(
                                  activeColor: Colors.blue,
                                  value: v['isSelected'],
                                  groupValue: true,
                                  onChanged: (value) {
                                    setState(() {
                                      v['isSelected'] = true;
                                      selectedCommunity = v;
                                    });
                                    Navigator.pop(
                                        context, [selectedCommunity, false]);
                                  }),
                            ),
                        ],
                      ),
              )
            ],
          ),
        ),
      ),
      // body: CustomScrollView(
      //   slivers: [
      //     SliverAppBar(
      //       leading: IconButton(
      //         icon: Icon(Icons.close),
      //         onPressed: () {
      //           Navigator.pop(context);
      //         },
      //       ),
      //       centerTitle: true,
      //       title: Text(
      //         "Select a community",
      //         textScaleFactor: 1.0,
      //         style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
      //       ),
      //       expandedHeight: MediaQuery.of(context).size.height / 5,
      //       flexibleSpace: FlexibleSpaceBar(
      //         background: Container(
      //
      //           child: Padding(
      //             padding: const EdgeInsets.all(15),
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.end,
      //               mainAxisSize: MainAxisSize.min,
      //               children: [
      //                 Padding(
      //                   padding: const EdgeInsets.all(8.0),
      //                   child: Text("Select an audience for this room"),
      //                 ),
      //                 SizedBox(
      //                   height: 10,
      //                 ),
      //                 Container(
      //                   decoration: BoxDecoration(
      //                       color: Color(0xff222222),
      //                       borderRadius: BorderRadius.circular(8)),
      //                   child: Padding(
      //                     padding: const EdgeInsets.symmetric(horizontal: 15),
      //                     child: TextField(
      //                       decoration:
      //                           InputDecoration(border: InputBorder.none),
      //                       onChanged: (value) {
      //                         if (value.length > 3) {
      //                           getHiveCommunities(value);
      //                         }
      //                       },
      //                     ),
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ),
      //       ),
      //     )
      //   ],
      // ),
    );
  }
}
