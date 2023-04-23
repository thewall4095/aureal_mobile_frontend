import 'dart:convert';

import 'package:auditory/BrowseProvider.dart';
import 'package:auditory/FilterState.dart';
import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/Sort%20&%20Filter.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({Key key}) : super(key: key);

  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  ScrollController _scrollController = ScrollController();
  ScrollController _scrollControllerPodcasts = ScrollController();

  String displayPicture;
  int count = 0;

  var podcasts = [];
  var episodes = [];
  var selectedTags = [];
  bool isLoading;
  bool recommendations;
  String hiveUserName;

  int episodePageNumber = 1;
  int podcastPageNumber = 1;

  bool episodePaginationLoading = false;
  bool podcastPaginationLoading = false;

  Launcher launcher = Launcher();

  String getTagsText(tags) {
    if (tags.length != 0) {
      String textToShow = '';
      for (var i = 0; i < tags.length; i++) {
        textToShow += '#' + tags[i] + '  ';
      }
      return textToShow;
    } else {
      return '';
    }
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String durationToShow = twoDigitHours != '00' ? (twoDigitHours + ':') : '';
    durationToShow += twoDigitMinutes != '00' ? (twoDigitMinutes + ':') : '';
    durationToShow += twoDigitSeconds;
    // return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    return durationToShow;
  }

  void getLocalData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    print(pref.getString('token'));
    setState(() {
      displayPicture = pref.getString('displayPicture');
      hiveUserName = pref.getString('HiveUserName');
    });
  }

  void browseEpisodesPaginated() async {
    print("the function has initiated");

    setState(() {
      episodePaginationLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/browseEpisode?user_id=${prefs.getString('userId')}&page=$episodePageNumber&sort=${prefs.getString('sort')}';
    print(prefs.getString('userId'));

    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['EpisodeResult'];
      setState(() {
        // episodes = episodes + data;

        episodes.addAll(data);
        episodes = episodes.toSet().toList();
        episodePageNumber = episodePageNumber + 1;
      });
    }
    setState(() {
      episodePaginationLoading = false;
    });
  }

  void browsePodcastPaginated() async {
    print("Podcast Function is starting");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/browsePodcast?user_id=${prefs.getString('userId')}&page=$podcastPageNumber&sort=${prefs.getString('sort')}";

    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['PodcastResult'];
      setState(() {
        podcasts.addAll(data);
        podcasts = podcasts.toSet().toList();
        podcastPageNumber = podcastPageNumber + 1;
      });
    } else {
      print(response.statusCode);
    }
  }

  void init() async {
    setState(() {
      isLoading = true;
    });
    getLocalData();
    // await browseEpisodes();
    // await browsePodcasts();

    // setState(() {
    //   isLoading = false;
    // });

    _scrollControllerPodcasts.addListener(() {
      if (_scrollControllerPodcasts.position.pixels ==
          _scrollControllerPodcasts.position.maxScrollExtent) {
        browsePodcastPaginated();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        browseEpisodesPaginated();
      }
    });
  }

  @override
  void initState() {
    init();
    // TODO: implement initState
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    var filterConfig = Provider.of<SortFilterPreferences>(context);

    BrowseProvider browseEpisodesListData =
        Provider.of<BrowseProvider>(context);
    if (browseEpisodesListData.isFetchedBrowseEpisodesList == false) {
      browseEpisodesListData.getBrowseEpisodesList();
    }

    BrowseProvider browsePodcastsListData =
        Provider.of<BrowseProvider>(context);
    if (browsePodcastsListData.isFetchedBrowsePodcastsList == false) {
      browsePodcastsListData.getBrowsePodcastsList();
    }

    Future<void> _pullRefresh() async {
      await browseEpisodesListData.getBrowseEpisodesList();
      await browsePodcastsListData.getBrowsePodcastsList();
    }

    setState(() {
      episodes = browseEpisodesListData.browseEpisodesList;
      podcasts = browsePodcastsListData.browsePodcastsList;
    });

    SizeConfig().init(context);
    return Scaffold(
      // bottomSheet: DraggableScrollableSheet(
      //   initialChildSize: 0.2,
      //   maxChildSize: 1,
      //   minChildSize: 0.2,
      //   builder: (context, ScrollController controller) {
      //     // return Player();
      //     return Container(
      //       child: ListView(
      //         controller: controller,
      //         children: [
      //           Column(
      //             children: [
      //               for (int i = 0; i < 20; i++)
      //                 Padding(
      //                   padding: const EdgeInsets.all(8.0),
      //                   child: Container(
      //                     width: double.infinity,
      //                     height: 100,
      //                     color: Colors.blue,
      //                   ),
      //                 ),
      //             ],
      //           )
      //         ],
      //       ),
      //     );
      //   },
      // ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // SliverAppBar(
            //   backgroundColor: kPrimaryColor,
            //   title: hiveUserName == null
            //       ? GestureDetector(
            //           onTap: () {
            //             Navigator.pushNamed(context, HiveAccount.id);
            //           },
            //           child: ShaderMask(
            //               shaderCallback: (Rect bounds) {
            //                 return LinearGradient(colors: [
            //                   Color(0xffE73B57),
            //                   Color(0xff6048F6)
            //                 ]).createShader(bounds);
            //               },
            //               child: Text(
            //                 "Not connected to Hive",
            //                 style: TextStyle(
            //                     color: Colors.white,
            //                     fontWeight: FontWeight.normal,
            //                     fontSize: SizeConfig.safeBlockHorizontal * 4),
            //               )),
            //         )
            //       : GestureDetector(
            //           onTap: () {
            //             Navigator.pushNamed(context, HiveWallet.id);
            //           },
            //           child: ShaderMask(
            //             shaderCallback: (Rect bounds) {
            //               return LinearGradient(colors: [
            //                 Color(0xff6048F6),
            //                 Color(0xff51C9F9)
            //               ]).createShader(bounds);
            //             },
            //             child: Text(
            //               'Connected To Hive',
            //               style: TextStyle(
            //                   color: Colors.white,
            //                   fontWeight: FontWeight.normal,
            //                   fontSize: SizeConfig.safeBlockHorizontal * 4),
            //             ),
            //           ),
            //         ),
            //   leading: IconButton(
            //     icon: displayPicture != null
            //         ? Container(
            //             decoration: BoxDecoration(
            //                 shape: BoxShape.circle,
            //                 border: Border.all(color: Colors.white, width: 2)),
            //             child: CircleAvatar(
            //               radius: 14,
            //               backgroundImage: NetworkImage(displayPicture),
            //             ),
            //           )
            //         : Container(
            //             decoration: BoxDecoration(
            //                 shape: BoxShape.circle,
            //                 border: Border.all(color: Colors.white, width: 2)),
            //             child: CircleAvatar(
            //               backgroundColor: Colors.transparent,
            //               radius: 14,
            //               backgroundImage: AssetImage('assets/images/user.png'),
            //             ),
            //           ),
            //     onPressed: () {
            //       Navigator.pushNamed(context, Profile.id);
            //     },
            //   ),
            //   actions: <Widget>[
            //     IconButton(
            //       icon: Icon(
            //         Icons.supervised_user_circle,
            //         color: Colors.white,
            //       ),
            //       onPressed: () {
            //         launcher.launchInBrowser('https://discord.gg/cdsFJtpbzs');
            //       },
            //     ),
            //     IconButton(
            //       icon: Icon(
            //         Icons.notifications_none,
            //         color: Colors.white,
            //       ),
            //       onPressed: () {
            //         Navigator.pushNamed(context, NotificationPage.id);
            //       },
            //     ),
            //     IconButton(
            //       icon: Icon(
            //         Icons.search,
            //         color: Colors.white,
            //       ),
            //       onPressed: () {
            //         showSearch(
            //             context: context, delegate: SearchFunctionality());
            //       },
            //     )
            //   ],
            //   expandedHeight: 170,
            //   pinned: true,
            //   flexibleSpace: FlexibleSpaceBar(
            //     background: Container(
            //       padding: EdgeInsets.fromLTRB(16, 0, 0, 64),
            //       height: 100,
            //       alignment: Alignment.bottomLeft,
            //       child: Text('Browse',
            //           style: TextStyle(
            //               fontSize: SizeConfig.safeBlockHorizontal * 6,
            //               fontWeight: FontWeight.bold,
            //               color: Colors.white)),
            //     ),
            //   ),
            //   bottom: PreferredSize(
            //     preferredSize: Size.fromHeight(40),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         Align(
            //           alignment: Alignment.centerLeft,
            //           child: TabBar(
            //             controller: _tabController,
            //             isScrollable: true,
            //             indicatorSize: TabBarIndicatorSize.label,
            //             indicatorColor: kActiveColor,
            //             labelColor: kActiveColor,
            //             unselectedLabelColor: Colors.white,
            //             labelStyle: TextStyle(
            //                 fontSize: SizeConfig.safeBlockHorizontal * 4),
            //             tabs: <Widget>[
            //               Tab(
            //                 text: "Podcasts",
            //               ),
            //               Tab(
            //                 text: "Episodes",
            //               ),
            //             ],
            //           ),
            //         ),
            //         Padding(
            //           padding: const EdgeInsets.symmetric(horizontal: 15),
            //           child: GestureDetector(
            //             onTap: () {
            //               showModalBottomSheet(
            //                   backgroundColor: kPrimaryColor,
            //                   context: context,
            //                   builder: (context) {
            //                     return Container(
            //                       child: Column(
            //                         children: [
            //                           SortFilter(),
            //                           Padding(
            //                             padding: const EdgeInsets.symmetric(
            //                                 horizontal: 10, vertical: 10),
            //                             child: GestureDetector(
            //                               onTap: () async {
            //                                 Navigator.pop(context);
            //                                 // setState(() {
            //                                 //   isLoading = true;
            //                                 // });
            //                                 await getLocalData();
            //                                 // await browseEpisodes();
            //                                 // await browsePodcasts();
            //                                 // setState(() {
            //                                 //   isLoading = false;
            //                                 // });
            //                               },
            //                               child: Container(
            //                                 decoration: BoxDecoration(
            //                                     borderRadius:
            //                                         BorderRadius.circular(6),
            //                                     color: kSecondaryColor),
            //                                 width: double.infinity,
            //                                 child: Padding(
            //                                   padding:
            //                                       const EdgeInsets.all(8.0),
            //                                   child: Center(
            //                                     child: Text(
            //                                       'Apply',
            //                                       style: TextStyle(
            //                                           color: Colors.white,
            //                                           fontSize: SizeConfig
            //                                                   .safeBlockHorizontal *
            //                                               4,
            //                                           fontWeight:
            //                                               FontWeight.w600),
            //                                     ),
            //                                   ),
            //                                 ),
            //                               ),
            //                             ),
            //                           )
            //                         ],
            //                       ),
            //                     );
            //                   });
            //             },
            //             child: Icon(
            //               Icons.filter_list,
            //               color: Colors.white,
            //             ),
            //           ),
            //         )
            //       ],
            //     ),
            //   ),
            // ),
          ];
        },
        body: ModalProgressHUD(
          inAsyncCall: (!browseEpisodesListData.isFetchedBrowseEpisodesList) ||
              (!browsePodcastsListData.isFetchedBrowsePodcastsList),
          //    color: kPrimaryColor,
          child: Column(
            children: [
              Container(
                height: SizeConfig.safeBlockVertical * 6,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: Colors.transparent,
                        // indicatorSize: TabBarIndicatorSize.label,
                        // indicatorColor: kActiveColor,
                        labelColor: kActiveColor,
                        unselectedLabelColor: Colors.white,
                        labelStyle: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4),
                        tabs: <Widget>[
                          Tab(
                            text: "Podcasts",
                          ),
                          Tab(
                            text: "Episodes",
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                              //  backgroundColor: kPrimaryColor,
                              context: context,
                              builder: (context) {
                                return Container(
                                  child: Column(
                                    children: [
                                      SortFilter(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        child: GestureDetector(
                                          onTap: () async {
                                            Navigator.pop(context);
                                            // setState(() {
                                            //   isLoading = true;
                                            // });
                                            await getLocalData();
                                            // await browseEpisodes();
                                            // await browsePodcasts();
                                            // setState(() {
                                            //   isLoading = false;
                                            // });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: kSecondaryColor),
                                            width: double.infinity,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Center(
                                                child: Text(
                                                  'Apply',
                                                  textScaleFactor: 0.75,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          4,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              });
                        },
                        child: Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    Container(
                        child: RefreshIndicator(
                      onRefresh: _pullRefresh,
                      child: ListView.builder(
                          controller: _scrollControllerPodcasts,
                          itemCount: podcasts.length,
                          itemBuilder: (BuildContext context, int index) {
                            if (podcastPaginationLoading == true &&
                                index == podcasts.length - 1) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    backgroundColor: Colors.blue,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xff6249EF)),
                                  ),
                                ),
                              );
                            } else {
                              print(index);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(context,
                                        CupertinoPageRoute(builder: (context) {
                                      return PodcastView(podcasts[index]['id']);
                                    }));
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        ClipRRect(
                                          //ClipRRect
                                          // child: FadeInImage.assetNetwork(
                                          //     height: 80,
                                          //     width: 80,
                                          //     fit: BoxFit.cover,
                                          //     placeholder:
                                          //         'assets/images/Thumbnail.png',
                                          //     image: podcasts[index]['image'] ==
                                          //             null
                                          //         ? 'assets/images/Thumbnail.png'
                                          //         : podcasts[index]['image']),

                                          child: CachedNetworkImage(
                                            height: 80,
                                            width: 80,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 80,
                                              width: 80,
                                              child: Image.asset(
                                                  'assets/images/Thumbnail.png'),
                                            ),
                                            imageUrl: podcasts[index]
                                                        ['image'] ==
                                                    null
                                                ? 'assets/images/Thumbnail.png'
                                                : podcasts[index]['image'],
                                            memCacheHeight:
                                                MediaQuery.of(context)
                                                    .size
                                                    .height
                                                    .floor(),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                "${podcasts[index]['name']}",
                                                textScaleFactor: 0.75,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        4,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                              SizedBox(
                                                height: 3,
                                              ),
                                              Text(
                                                podcasts[index]['author'],
                                                textScaleFactor: 0.75,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        4),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          }),
                    )),
                    Container(
                      child: RefreshIndicator(
                        onRefresh: _pullRefresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: episodes.length,
                          itemBuilder: (BuildContext context, int index) {
                            if (episodePaginationLoading == true &&
                                index == episodes.length - 1) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    backgroundColor: Colors.blue,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xff6249EF)),
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              child: Container(
                                  width: double.infinity,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipRRect(
                                          //ClipRRect
                                          // child: FadeInImage.assetNetwork(
                                          //     height: 80,
                                          //     width: 80,
                                          //     fit: BoxFit.cover,
                                          //     placeholder:
                                          //         'assets/images/Thumbnail.png',
                                          //     image: episodes[index]['image']),
                                          child: CachedNetworkImage(
                                            height: 80,
                                            width: 80,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 80,
                                              width: 80,
                                              child: Image.asset(
                                                  'assets/images/Thumbnail.png'),
                                            ),
                                            imageUrl: episodes[index]
                                                        ['image'] ==
                                                    null
                                                ? 'assets/images/Thumbnail.png'
                                                : episodes[index]['image'],
                                            memCacheHeight:
                                                MediaQuery.of(context)
                                                    .size
                                                    .height
                                                    .floor(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(context,
                                                    CupertinoPageRoute(builder:
                                                        (BuildContext context) {
                                                  return EpisodeView(
                                                    episodeId: episodes[index]
                                                        ['id'],
                                                  );
                                                }));
                                              },
                                              child: Text(
                                                episodes[index]['name'],
                                                textScaleFactor: 0.75,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        4,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                            Text(
                                              episodes[index]['podcast_name'],
                                              textScaleFactor: 0.75,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      4,
                                                  color: Colors.grey,
                                                  fontWeight:
                                                      FontWeight.normal),
                                            ),
                                            Text(
                                              '${episodes[index]['author']} | ${_printDuration(Duration(seconds: int.parse(episodes[index]['duration'].toString().split('.')[0])))}',
                                              maxLines: 2,
                                              textScaleFactor: 0.75,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              getTagsText(
                                                  episodes[index]['Tags']),
                                              textScaleFactor: 0.75,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                                  // ],
                                  // ),
                                  ),
                            );
                          },
                        ),
                      ),

                      // Categories
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
