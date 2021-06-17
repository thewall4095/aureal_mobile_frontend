import 'dart:async';
import 'dart:convert';
// import 'dart:html';

import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/CommunityService.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/screens/BottomPlayer.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/screens/Player/PDFviewer.dart';
import 'package:auditory/screens/Player/VideoPlayer.dart';
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

enum Follow { followed, unfollowed }

class CommunityProfileView extends StatefulWidget {
  var communityObject;
  CommunityProfileView({@required this.communityObject});

  @override
  _CommunityProfileViewState createState() => _CommunityProfileViewState();
}

class _CommunityProfileViewState extends State<CommunityProfileView>
    with TickerProviderStateMixin {
  TabController _tabController;
  ScrollController _scrollController;

  bool followstate = false;

  CommunityService service = CommunityService();
  void share(var v) async {
    String sharableLink;

    await FlutterShare.share(
        title: '${v['title']}',
        text:
            "Hey There, I'm listening to ${v['name']} on Aureal, here's the link for you https://api.aureal.one/podcast/${v['podcast_id']}");
  }

  List episodes = [];

  Follow followState = Follow.unfollowed;

  AnimationController _animationController;
  bool isPlaying = false;

  int pageNumber = 1;

  void getCommunityEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCommunityEpisodes?community_id=${widget.communityObject['id']}&user_id=${prefs.getString('userId')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          episodes = jsonDecode(response.body)['EpisodeResult'];
          followstate = jsonDecode(response.body)['follows'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getCommunityEpisodesPaginated() async {
    print("pagination Starting");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCommunityEpisodes?community_id=${widget.communityObject['id']}&page=${pageNumber}&user_id=${prefs.getString('userId')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          episodes = episodes + jsonDecode(response.body)['EpisodeResult'];
          pageNumber = pageNumber + 1;
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
    _tabController = TabController(length: 1, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        getCommunityEpisodesPaginated();
      }
    });

    getCommunityEpisodes();
    // TODO: implement initState
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var community = Provider.of<CommunityProvider>(context);
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    SizeConfig().init(context);
    return Scaffold(
      bottomSheet: BottomPlayer(),
      //   backgroundColor: kPrimaryColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            //    backgroundColor: kPrimaryColor,
            pinned: true,
            expandedHeight: MediaQuery.of(context).size.height / 2.2,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                child: Column(
                  children: [
                    Expanded(
                        child: Stack(
                      children: [
                        Container(
                          foregroundDecoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                            ///  kPrimaryColor.withOpacity(0.8),
                            kSecondaryColor.withOpacity(0.8)
                          ])),
                          child: Container(
                            width: double.infinity,
                            child: FadeInImage.assetNetwork(
                              placeholder: 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                              image:
                                  '${widget.communityObject['bannerImageUrl']}',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        width: 2, color: Colors.white)),
                                child: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: widget.communityObject[
                                              'profileImageUrl'] ==
                                          null
                                      ? AssetImage(
                                          'assets/images/Thumbnail.png')
                                      : NetworkImage(widget
                                          .communityObject['profileImageUrl']),
                                  radius: 35,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    )),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: kSecondaryColor),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.blockSizeVertical * 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${widget.communityObject['name']}',
                                        textScaleFactor: 0.75,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    4.5),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        followstate == true
                                            ? InkWell(
                                                onTap: () async {
                                                  setState(() {
                                                    followstate = false;
                                                  });
                                                  await service
                                                      .unSubScribeCommunity(
                                                          communityId: widget
                                                                  .communityObject[
                                                              'id']);
                                                  community
                                                      .getAllCommunitiesForUser();
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color:
                                                              Colors.white30)),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    child: Text(
                                                      "Followed",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : InkWell(
                                                onTap: () async {
                                                  setState(() {
                                                    followstate = true;
                                                  });
                                                  await service.subscribeCommunity(
                                                      communityId: widget
                                                              .communityObject[
                                                          'id']);
                                                  community
                                                      .getAllCommunitiesForUser();
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      //  color: kPrimaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Icon(
                                                          Icons.add,
                                                          color: Colors.white,
                                                          size: 10,
                                                        ),
                                                        Text(
                                                          'Follow',
                                                          textScaleFactor: 0.75,
                                                          style: TextStyle(
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  3,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  "Some people follows this and other are online",
                                  textScaleFactor: 0.75,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 2.8),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  '${widget.communityObject['description']}',
                                  textScaleFactor: 0.75,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.white30,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: Container(
                height: 50,
                width: double.infinity,
                //  color: kPrimaryColor,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      text: 'Episodes',
                    )
                  ],
                ),
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            for (var v in episodes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return EpisodeView(episodeId: v['id']);
                    }));
                  },
                  child: Container(
                    decoration: BoxDecoration(color: kSecondaryColor),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${v['author']} . ${timeago.format(DateTime.parse(v['updatedAt']))}',
                            textScaleFactor: 0.75,
                            style: TextStyle(color: Colors.white),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Text(
                                          '${v['name']}',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4.5,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Text(
                                          '${v['podcast_name']}',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              color: Colors.blueAccent),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Text(
                                          '${v['summary']}',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.5)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: InkWell(
                                    onTap: () {
                                      print(
                                          v['url'].toString().contains('.mp4'));
                                      if (v['url']
                                                  .toString()
                                                  .contains('.mp4') ==
                                              true ||
                                          v['url']
                                                  .toString()
                                                  .contains('.m4v') ==
                                              true ||
                                          v['url']
                                                  .toString()
                                                  .contains('.flv') ==
                                              true ||
                                          v['url']
                                                  .toString()
                                                  .contains('.f4v') ==
                                              true ||
                                          v['url']
                                                  .toString()
                                                  .contains('.ogv') ==
                                              true ||
                                          v['url']
                                                  .toString()
                                                  .contains('.ogx') ==
                                              true ||
                                          v['url']
                                                  .toString()
                                                  .contains('.wmv') ==
                                              true ||
                                          v['url']
                                                  .toString()
                                                  .contains('.webm') ==
                                              true) {
                                        currentlyPlaying.stop();
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return PodcastVideoPlayer(
                                            episodeObject: v,
                                          );
                                        }));
                                      } else {
                                        if (v['url']
                                            .toString()
                                            .contains('.pdf')) {
                                          // Navigator.push(context,
                                          //     MaterialPageRoute(
                                          //         builder: (context) {
                                          //   return PDFviewer(
                                          //     episodeObject: v,
                                          //   );
                                          // }));
                                          print(v['url']);
                                        } else {
                                          currentlyPlaying.stop();
                                          currentlyPlaying.episodeObject = v;
                                          print(currentlyPlaying.episodeObject
                                              .toString());
                                          currentlyPlaying.play();
                                        }
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      height: 120,
                                      width: 120,
                                      child: FadeInImage.assetNetwork(
                                          placeholder:
                                         ' https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                          image: v['image'] == null
                                              ? 'assets/images/Thumbnail.png'
                                              : v['image']),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            Future.delayed(
                                                Duration(milliseconds: 2000),
                                                () {
                                              upvoteEpisode(
                                                  permlink: v['permlink'],
                                                  episode_id: v['id']);
                                              Navigator.of(context).pop(true);
                                            });
                                            return Dialog(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/animatedtick.gif',
                                                      height: 100,
                                                      width: 100,
                                                    ),
                                                    Text(
                                                      "Upvote Done",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                          fontSize: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        FontAwesomeIcons.chevronCircleUp,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      '${v['votes']}',
                                      textScaleFactor: 0.75,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.5),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            Future.delayed(
                                                Duration(milliseconds: 2000),
                                                () {
                                              downVoteEpisode(
                                                  permlink: v['permlink'],
                                                  episode_id: v['id']);
                                              Navigator.of(context).pop(true);
                                            });
                                            return Dialog(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/images/animatedtick.gif',
                                                      height: 100,
                                                      width: 100,
                                                    ),
                                                    Text(
                                                      "Upvote Done",
                                                      textScaleFactor: 0.75,
                                                      style: TextStyle(
                                                          fontSize: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        FontAwesomeIcons.chevronCircleDown,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Text(
                                      '\$ ${v['payout_value'].toString().split(' ')[0]}',
                                      textScaleFactor: 0.75,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.5),
                                    ),
                                  )
                                ],
                              ),
                              IconButton(
                                onPressed: () async {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return Comments(
                                      episodeObject: v,
                                    );
                                  }));
                                },
                                icon: Icon(
                                  Icons.comment_rounded,
                                  color: Colors.white,
                                  size: SizeConfig.safeBlockHorizontal * 4.2,
                                ),
                              ),
                              IconButton(
                                  icon: Icon(
                                    FontAwesomeIcons.shareAlt,
                                    size: SizeConfig.safeBlockHorizontal * 4.2,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    share(v);
                                  }),
                              SizedBox(
                                width: 0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 100,
            ),
          ]))
        ],
      ),
    );
  }
}
