import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DiscoverProvider.dart';
import 'FollowingPage.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/Player.dart';
import 'Player/VideoPlayer.dart';
import 'Profiles/Comments.dart';
import 'Profiles/EpisodeView.dart';
import 'Profiles/PodcastView.dart';

class History extends StatefulWidget {
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  var recentlyPlayed = [];
  var homeData = [];

  SharedPreferences pref;

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    DiscoverProvider discoverData = Provider.of<DiscoverProvider>(context);
    if (discoverData.isFetcheddiscoverList == false) {
      discoverData.getDiscoverProvider();
    }

    setState(() {
      homeData = discoverData.discoverList;
    });
    for (var v in homeData) {
      if (v['Key'] == 'general_episode') {
        setState(() {
          recentlyPlayed = v['data'];
          for (var v in recentlyPlayed) {
            v['isLoading'] = false;
          }
        });
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("History"),
      ),
      body: recentlyPlayed.length == 0
          ? Container(
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
                              "No Clips..!",
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 5),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Icon(Icons.download_outlined),
                        ),
                        Text("You can now add your favrate Clips.")
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return FollowingPage();
                            });
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
                                        SizeConfig.safeBlockHorizontal * 4),
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
            )
          : ListView(
              children: [
                for (var a in recentlyPlayed)
                  InkWell(
                    onTap: () {
                      print(a.toString().contains('.mp4'));
                      if (a.toString().contains('.mp4') == true ||
                          a.toString().contains('.m4v') == true ||
                          a.toString().contains('.flv') == true ||
                          a.toString().contains('.f4v') == true ||
                          a.toString().contains('.ogv') == true ||
                          a.toString().contains('.ogx') == true ||
                          a.toString().contains('.wmv') == true ||
                          a.toString().contains('.webm') == true) {
                        currentlyPlaying.stop();
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (context) {
                          return PodcastVideoPlayer(episodeObject: a);
                        }));
                      } else {
                        if (a.toString().contains('.pdf') == true) {
                        } else {
                          currentlyPlaying.stop();
                          currentlyPlaying.episodeObject = a;
                          print(currentlyPlaying.episodeObject.toString());
                          currentlyPlaying.play();
                          Navigator.push(context,
                              CupertinoPageRoute(builder: (context) {
                            return Player();
                          }));
                        }
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width / 6,
                              height: MediaQuery.of(context).size.width / 6,
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageBuilder: (context, imageProvider) {
                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                6,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover),
                                        ),
                                      );
                                    },
                                    memCacheHeight:
                                        (MediaQuery.of(context).size.height)
                                            .floor(),
                                    imageUrl: a['image'] != null
                                        ? a['image']
                                        : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                    placeholder: (context, imageProvider) {
                                      return Container(
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/Thumbnail.png'),
                                                fit: BoxFit.cover)),
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.38,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.38,
                                      );
                                    },
                                  ),

                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 2,
                                height: MediaQuery.of(context).size.width / 6,
                                child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5),
                                            child: GestureDetector(
                                              onTap: () {
                                                // Navigator.push(context, CupertinoPageRoute(widget: EpisodeView(episodeId: a['id'])));
                                                Navigator.push(context,
                                                    CupertinoPageRoute(
                                                        builder: (context) {
                                                  return EpisodeView(
                                                    episodeId: a['id'],
                                                  );
                                                }));
                                              },
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(context,
                                                      CupertinoPageRoute(
                                                          builder: (context) {
                                                    return PodcastView(
                                                        a['podcast_id']);
                                                  }));
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(
                                                    a['name'].toString(),
                                                    overflow: TextOverflow.clip,
                                                    maxLines: 2,
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3.2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            a['podcast_name'].toString(),
                                            textScaleFactor: 1.0,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Color(0xff777777),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    2.8),
                                          ),
                                        ],
                                      ),
                                    ]),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            ),
    );
  }
}
