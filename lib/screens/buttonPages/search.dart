import 'dart:convert';

import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/screens/Profiles/CategoryView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SearchProvider.dart';

class Search extends StatefulWidget {
  static const String id = "Search";

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with SingleTickerProviderStateMixin {
  ScrollController _controller = ScrollController();

  TabController _tabController;

  TextEditingController _textController;
  final List<String> colors = <String>[
    'red',
    'blue',
    'green',
    'yellow',
    'orange'
  ];
  String query = '';

  int pageNumber = 1;

  var searchEpisodes = [];
  var searchPodcasts = [];

  bool loading = false;

  void getMoreSearch() async {
    setState(() {
      loading = true;
      pageNumber = pageNumber + 1;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/search?user_id=${prefs.getString('userId')}&word=${query}&page=$pageNumber';
    http.Response response = await http.get(Uri.parse(url));

    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        // searchEpisodes =
        //     searchEpisodes + jsonDecode(response.body)['EpisodeList'];
        searchPodcasts =
            searchPodcasts + jsonDecode(response.body)['PodcastList'];
      });
    } else {
      print(response.statusCode);
    }
    setState(() {
      loading = false;
    });
  }

  void getSearch(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/search?user_id=${prefs.getString('userId')}&word=${query}';

    http.Response response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        if (jsonDecode(response.body)['EpisodeList'] != null) {
          searchEpisodes = jsonDecode(response.body)['EpisodeList'];
        } else {
          searchEpisodes = [];
        }

        if (jsonDecode(response.body)['PodcastList'] != null) {
          searchPodcasts = jsonDecode(response.body)['PodcastList'];
        } else {
          searchPodcasts = [];
        }
      });
    } else {
      print(response.statusCode);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _textController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);

    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        getMoreSearch();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _tabController.dispose();
    _controller.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {}
}

class SearchFunctionality extends SearchDelegate {
  List<Color> colors1 = [
    //Colors.blue,
    Colors.yellow,
    Colors.pink,
  ];

  Future getSearch() async {
    final TextEditingController _textController = new TextEditingController();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/public/search?word=$query";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        return response.body;
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    // throw UnimplementedError();

    return <Widget>[
      IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            close(context, Search());
          }
          //    query = '';
          //     },
          )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    // throw UnimplementedError();
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // TODO: implement buildResults
    // throw UnimplementedError();
    var search = Provider.of<SearchProvider>(context);
    //  search.getSearch(query);
    //return ResultsSection(
    //query: query,
    // );
    return Container(
      color: themeProvider.isLightTheme == true ? Colors.white : Colors.black,
      child: FutureBuilder(
          future: getSearch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // print(query);
              print(snapshot.data);
              return ResultsSection(
                data: snapshot.data,
                query: query,
              );
            } else {
              return Center(
                  child: Container(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(
                          backgroundColor: Colors.black,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xffffffff)))));
            }
          }),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ThemeData(
      primaryColor:
          themeProvider.isLightTheme == true ? Colors.white : kPrimaryColor,
      primaryIconTheme: IconThemeData(
        color:
            themeProvider.isLightTheme != true ? Colors.white : kPrimaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: Theme.of(context).textTheme.title.copyWith(
              color: themeProvider.isLightTheme != true
                  ? Colors.white
                  : kPrimaryColor,
            ),
      ),
      textTheme: TextTheme(
        title: TextStyle(
          color:
              themeProvider.isLightTheme != true ? Colors.white : kPrimaryColor,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    // throw UnimplementedError();

    // return Container();
    var categories = Provider.of<CategoriesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    Container(
      color: themeProvider.isLightTheme == true ? Colors.white : Colors.black,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        children: [
          for (var v in categories.categoryList)
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return CategoryView(
                      categoryObject: v,
                    );
                  }));
                },
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          v['name'],
                          textScaleFactor: 0.75,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
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

class ResultsSection extends StatefulWidget {
  var data;
  String query;

  ResultsSection({@required this.data, @required this.query});

  @override
  _ResultsSectionState createState() => _ResultsSectionState();
}

class _ResultsSectionState extends State<ResultsSection>
    with TickerProviderStateMixin {
  TabController _controller;
  ScrollController _podcastScrollController;
  ScrollController _episodeScrollController;
  ScrollController _communityScrollController;

  int podcastPageNumber = 1;
  int episodePageNumber = 1;
  int communityPageNumber = 1;
  List episodeResult = [];
  List podcastResult = [];
  List communityResult = [];
  bool isPodcastLoading = false;
  bool isEpisodeLoading = false;
  bool isCommunityLoading = false;

  // void getMoreSearchCommunity({String query}) async {
  //   setState(() {
  //     isCommunityLoading = true;
  //   });
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String url =
  //       "https://api.aureal.one/public/search?word=$query&page=$communityPageNumber";
  //
  //   http.Response response = await http.get(Uri.parse(url));
  //   print(response.body);
  //   if (response.statusCode == 200) {
  //     setState(() {
  //       communityResult.addAll(jsonDecode(response.body)['CommunityList']);
  //       communityResult.toSet().toList();
  //       communityPageNumber = communityPageNumber + 1;
  //     });
  //   }
  //   setState(() {
  //     isCommunityLoading = false;
  //   });
  // }

  void getMoreSearchPodcast({String query}) async {
    setState(() {
      isPodcastLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/search?word=$query&page=$podcastPageNumber";

    http.Response response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        podcastResult.addAll(jsonDecode(response.body)['PodcastList']);
        podcastResult.toSet().toList();
        podcastPageNumber = podcastPageNumber + 1;
      });
    }
    setState(() {
      isPodcastLoading = false;
    });
  }

  // void getMoreSearchEpisodes({String query}) async {
  //   setState(() {
  //     isEpisodeLoading = true;
  //   });
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String url =
  //       "https://api.aureal.one/public/search?user_id=${prefs.getString('userId')}&word=$query&page=$episodePageNumber";
  //
  //   http.Response response = await http.get(Uri.parse(url));
  //   print(response.body);
  //   if (response.statusCode == 200) {
  //     setState(() {
  //       episodeResult.addAll(jsonDecode(response.body)['EpisodeList']);
  //       episodeResult.toSet().toList();
  //       episodePageNumber = episodePageNumber + 1;
  //     });
  //   }
  //   setState(() {
  //     isEpisodeLoading = false;
  //   });
  // }

  @override
  void initState() {
    // TODO: implement initState
    _controller = TabController(length: 1, vsync: this);
    _podcastScrollController = ScrollController();
    _episodeScrollController = ScrollController();
    _communityScrollController = ScrollController();
    print(widget.data);

    podcastResult = jsonDecode(widget.data)['PodcastList'];
    episodeResult = jsonDecode(widget.data)['EpisodeList'];
    communityResult = jsonDecode(widget.data)['CommunityList'];

    _podcastScrollController.addListener(() {
      if (_podcastScrollController.position.pixels ==
          _podcastScrollController.position.maxScrollExtent) {
        getMoreSearchPodcast(query: widget.query);
      }
    });

    _episodeScrollController.addListener(() {
      if (_episodeScrollController.position.pixels ==
          _episodeScrollController.position.maxScrollExtent) {
        // getMoreSearchEpisodes(query: widget.query);
      }
    });

    _communityScrollController.addListener(() {
      if (_communityScrollController.position.pixels ==
          _communityScrollController.position.maxScrollExtent) {
        // getMoreSearchCommunity(query: widget.query);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Container(
        color: themeProvider.isLightTheme == true ? Colors.white : Colors.black,
        child: Column(
          children: [
            Expanded(
              child: Container(
                child: podcastResult != null && podcastResult.length == 0
                    ? Stack(children: <Widget>[
                        Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage("assets/images/search.png"),
                                  fit: BoxFit.contain)),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      "No Data Found",
                                      textScaleFactor: 0.75,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 350,
                                  )
                                ],
                              ),
                            ])
                      ])
                    : ListView.builder(
                        controller: _podcastScrollController,
                        itemCount: podcastResult.length + 1,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == podcastResult.length) {
                            return isPodcastLoading == false
                                ? SizedBox(
                                    height: 0,
                                    width: 0,
                                  )
                                : Container(
                                    height: 10,
                                    width: double.infinity,
                                    child: LinearProgressIndicator(
                                      minHeight: 10,
                                      backgroundColor: Colors.blue,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xff6249EF)),
                                    ),
                                  );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return PodcastView(
                                        podcastResult[index]['id']);
                                  }));
                                },
                                // child: Container(
                                //   width: double.infinity,
                                //   child: Row(
                                //     crossAxisAlignment:
                                //         CrossAxisAlignment.start,
                                //     children: <Widget>[
                                //       ClipRRect(
                                //         //ClipRRect
                                //         child: FadeInImage.assetNetwork(
                                //             height: 80,
                                //             width: 80,
                                //             fit: BoxFit.cover,
                                //             placeholder:
                                //                 'assets/images/Thumbnail.png',
                                //             image: podcastResult[index]
                                //                         ['image'] ==
                                //                     null
                                //                 ? 'assets/images/Thumbnail.png'
                                //                 : podcastResult[index]
                                //                     ['image']),
                                //       ),
                                //       SizedBox(width: 10),
                                //       Expanded(
                                //         child: Column(
                                //           crossAxisAlignment:
                                //               CrossAxisAlignment.start,
                                //           mainAxisSize: MainAxisSize.max,
                                //           mainAxisAlignment:
                                //               MainAxisAlignment.center,
                                //           children: <Widget>[
                                //             Text(
                                //               "${podcastResult[index]['name']}",
                                //               textScaleFactor: 0.75,
                                //               maxLines: 2,
                                //               overflow: TextOverflow.ellipsis,
                                //               style: TextStyle(
                                //                   color: themeProvider
                                //                               .isLightTheme !=
                                //                           true
                                //                       ? Colors.white
                                //                       : kPrimaryColor,
                                //                   fontSize: SizeConfig
                                //                           .safeBlockHorizontal *
                                //                       4,
                                //                   fontWeight:
                                //                       FontWeight.normal),
                                //             ),
                                //             SizedBox(
                                //               height: 3,
                                //             ),
                                //             Text(
                                //               podcastResult[index]['author'],
                                //               textScaleFactor: 0.75,
                                //               maxLines: 2,
                                //               overflow: TextOverflow.ellipsis,
                                //               style: TextStyle(
                                //                   color: themeProvider
                                //                               .isLightTheme !=
                                //                           true
                                //                       ? Colors.white
                                //                           .withOpacity(0.5)
                                //                       : kPrimaryColor
                                //                           .withOpacity(0.5),
                                //                   fontSize: SizeConfig
                                //                           .safeBlockHorizontal *
                                //                       4),
                                //             ),
                                //           ],
                                //         ),
                                //       )
                                //     ],
                                //   ),
                                // ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        new BoxShadow(
                                          color:
                                              Colors.black54.withOpacity(0.2),
                                          blurRadius: 10.0,
                                        ),
                                      ],
                                      color: themeProvider.isLightTheme == true
                                          ? Colors.white
                                          : Color(0xff222222),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    width: double.infinity,
                                    child: Row(
                                      children: [
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              5,
                                          child: CachedNetworkImage(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5,
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover),
                                                ),
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                              );
                                            },
                                            imageUrl: podcastResult[index]
                                                        ['image'] ==
                                                    null
                                                ? 'assets/images/Thumbnail.png'
                                                : podcastResult[index]['image'],
                                            fit: BoxFit.cover,
                                            // memCacheHeight:
                                            //     MediaQuery.of(
                                            //             context)
                                            //         .size
                                            //         .width
                                            //         .ceil(),
                                            memCacheHeight:
                                                MediaQuery.of(context)
                                                    .size
                                                    .height
                                                    .floor(),

                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 10),
                                          child: Container(
                                            //   height: double.infinity,
                                            width: 240,
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${podcastResult[index]['name']}",
                                                    textScaleFactor:
                                                        mediaQueryData
                                                            .textScaleFactor
                                                            .clamp(1, 1.3)
                                                            .toDouble(),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: themeProvider
                                                                    .isLightTheme !=
                                                                true
                                                            ? Colors.white
                                                            : kPrimaryColor,
                                                        // fontSize: SizeConfig
                                                        //         .safeBlockHorizontal *
                                                        //     ,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                  Text(
                                                    '${podcastResult[index]['author']}',
                                                    textScaleFactor:
                                                        mediaQueryData
                                                            .textScaleFactor
                                                            .clamp(0.5, 1.3)
                                                            .toDouble(),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: themeProvider
                                                                  .isLightTheme !=
                                                              true
                                                          ? Colors.white
                                                              .withOpacity(0.5)
                                                          : kPrimaryColor
                                                              .withOpacity(0.5),
                                                      // fontSize: SizeConfig
                                                      //         .safeBlockHorizontal *
                                                      //     4
                                                    ),
                                                  ),
                                                ]),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }),
              ),
            ),
            // Expanded(
            //     child: TabBarView(
            //   controller: _controller,
            //   children: [
            //     Container(
            //       child: podcastResult != null && podcastResult.length == 0
            //           ? Stack(children: <Widget>[
            //               Container(
            //                 height: double.infinity,
            //                 width: double.infinity,
            //                 decoration: BoxDecoration(
            //                     image: DecorationImage(
            //                         image:
            //                             AssetImage("assets/images/search.png"),
            //                         fit: BoxFit.contain)),
            //               ),
            //               Column(
            //                   mainAxisAlignment: MainAxisAlignment.end,
            //                   children: <Widget>[
            //                     Row(
            //                       mainAxisAlignment: MainAxisAlignment.center,
            //                       children: <Widget>[
            //                         Flexible(
            //                           child: Text(
            //                             "No Data Found",
            //                             textScaleFactor: 0.75,
            //                             style: TextStyle(
            //                               color: Colors.grey,
            //                               fontSize:
            //                                   SizeConfig.safeBlockHorizontal *
            //                                       5,
            //                               fontWeight: FontWeight.w600,
            //                             ),
            //                           ),
            //                         ),
            //                         SizedBox(
            //                           height: 350,
            //                         )
            //                       ],
            //                     ),
            //                   ])
            //             ])
            //           : ListView.builder(
            //               controller: _podcastScrollController,
            //               itemCount: podcastResult.length + 1,
            //               itemBuilder: (BuildContext context, int index) {
            //                 if (index == podcastResult.length) {
            //                   return isPodcastLoading == false
            //                       ? SizedBox(
            //                           height: 0,
            //                           width: 0,
            //                         )
            //                       : Container(
            //                           height: 10,
            //                           width: double.infinity,
            //                           child: LinearProgressIndicator(
            //                             minHeight: 10,
            //                             backgroundColor: Colors.blue,
            //                             valueColor:
            //                                 AlwaysStoppedAnimation<Color>(
            //                                     Color(0xff6249EF)),
            //                           ),
            //                         );
            //                 } else {
            //                   return Padding(
            //                     padding: const EdgeInsets.symmetric(
            //                         vertical: 10, horizontal: 10),
            //                     child: GestureDetector(
            //                       onTap: () {
            //                         Navigator.push(context,
            //                             MaterialPageRoute(builder: (context) {
            //                           return PodcastView(
            //                               podcastResult[index]['id']);
            //                         }));
            //                       },
            //                       child: Container(
            //                         width: double.infinity,
            //                         child: Row(
            //                           crossAxisAlignment:
            //                               CrossAxisAlignment.start,
            //                           children: <Widget>[
            //                             ClipRRect(
            //                               //ClipRRect
            //                               child: FadeInImage.assetNetwork(
            //                                   height: 80,
            //                                   width: 80,
            //                                   fit: BoxFit.cover,
            //                                   placeholder:
            //                                       'assets/images/Thumbnail.png',
            //                                   image: podcastResult[index]
            //                                               ['image'] ==
            //                                           null
            //                                       ? 'assets/images/Thumbnail.png'
            //                                       : podcastResult[index]
            //                                           ['image']),
            //                             ),
            //                             SizedBox(width: 10),
            //                             Expanded(
            //                               child: Column(
            //                                 crossAxisAlignment:
            //                                     CrossAxisAlignment.start,
            //                                 children: <Widget>[
            //                                   Text(
            //                                     "${podcastResult[index]['name']}",
            //                                     textScaleFactor: 0.75,
            //                                     maxLines: 2,
            //                                     overflow: TextOverflow.ellipsis,
            //                                     style: TextStyle(
            //                                         color: themeProvider
            //                                                     .isLightTheme !=
            //                                                 true
            //                                             ? Colors.white
            //                                             : kPrimaryColor,
            //                                         fontSize: SizeConfig
            //                                                 .safeBlockHorizontal *
            //                                             4,
            //                                         fontWeight:
            //                                             FontWeight.normal),
            //                                   ),
            //                                   SizedBox(
            //                                     height: 3,
            //                                   ),
            //                                   Text(
            //                                     podcastResult[index]['author'],
            //                                     textScaleFactor: 0.75,
            //                                     maxLines: 2,
            //                                     overflow: TextOverflow.ellipsis,
            //                                     style: TextStyle(
            //                                         color: themeProvider
            //                                                     .isLightTheme !=
            //                                                 true
            //                                             ? Colors.white
            //                                                 .withOpacity(0.5)
            //                                             : kPrimaryColor
            //                                                 .withOpacity(0.5),
            //                                         fontSize: SizeConfig
            //                                                 .safeBlockHorizontal *
            //                                             4),
            //                                   ),
            //                                   SizedBox(
            //                                     height: 5,
            //                                   ),
            //                                 ],
            //                               ),
            //                             )
            //                           ],
            //                         ),
            //                       ),
            //                     ),
            //                   );
            //                 }
            //               }),
            //     ),
            //     // Container(
            //     //   child: episodeResult != null && episodeResult.length == 0
            //     //       ? Stack(children: <Widget>[
            //     //           Container(
            //     //             height: double.infinity,
            //     //             width: double.infinity,
            //     //             decoration: BoxDecoration(
            //     //                 image: DecorationImage(
            //     //                     image:
            //     //                         AssetImage("assets/images/search.png"),
            //     //                     fit: BoxFit.contain)),
            //     //           ),
            //     //           Column(
            //     //               mainAxisAlignment: MainAxisAlignment.end,
            //     //               children: <Widget>[
            //     //                 Row(
            //     //                   mainAxisAlignment: MainAxisAlignment.center,
            //     //                   children: <Widget>[
            //     //                     Flexible(
            //     //                         child: Text("No Data Found",
            //     //                             textScaleFactor: 0.75,
            //     //                             style: TextStyle(
            //     //                               color: Colors.grey,
            //     //                               fontSize: SizeConfig
            //     //                                       .safeBlockHorizontal *
            //     //                                   5,
            //     //                               fontWeight: FontWeight.w600,
            //     //                             ))),
            //     //                     SizedBox(
            //     //                       height: 350,
            //     //                     )
            //     //                   ],
            //     //                 )
            //     //               ])
            //     //         ])
            //     //       : ListView.builder(
            //     //           controller: _episodeScrollController,
            //     //           itemCount: episodeResult.length + 1,
            //     //           itemBuilder: (BuildContext context, int index) {
            //     //             if (index == episodeResult.length) {
            //     //               return isEpisodeLoading == false
            //     //                   ? SizedBox(
            //     //                       height: 0,
            //     //                       width: 0,
            //     //                     )
            //     //                   : Container(
            //     //                       height: 10,
            //     //                       width: double.infinity,
            //     //                       child: LinearProgressIndicator(
            //     //                         minHeight: 10,
            //     //                         backgroundColor: Colors.black,
            //     //                         valueColor:
            //     //                             AlwaysStoppedAnimation<Color>(
            //     //                                 Color(0xffffffff)),
            //     //                       ),
            //     //                     );
            //     //             } else {
            //     //               return Padding(
            //     //                 padding: const EdgeInsets.symmetric(
            //     //                     vertical: 10, horizontal: 10),
            //     //                 child: GestureDetector(
            //     //                   onTap: () {
            //     //                     Navigator.push(context,
            //     //                         MaterialPageRoute(builder: (context) {
            //     //                       return EpisodeView(
            //     //                           episodeId: episodeResult[index]
            //     //                               ['id']);
            //     //                     }));
            //     //                   },
            //     //                   child: Container(
            //     //                     width: double.infinity,
            //     //                     child: Row(
            //     //                       crossAxisAlignment:
            //     //                           CrossAxisAlignment.start,
            //     //                       children: <Widget>[
            //     //                         ClipRRect(
            //     //                           //ClipRRect
            //     //                           child: FadeInImage.assetNetwork(
            //     //                               height: 80,
            //     //                               width: 80,
            //     //                               fit: BoxFit.cover,
            //     //                               placeholder:
            //     //                                   'assets/images/Thumbnail.png',
            //     //                               image: episodeResult[index]
            //     //                                           ['image'] ==
            //     //                                       null
            //     //                                   ? 'assets/images/Thumbnail.png'
            //     //                                   : episodeResult[index]
            //     //                                       ['image']),
            //     //                         ),
            //     //                         SizedBox(width: 10),
            //     //                         Expanded(
            //     //                           child: Column(
            //     //                             crossAxisAlignment:
            //     //                                 CrossAxisAlignment.start,
            //     //                             children: <Widget>[
            //     //                               Text(
            //     //                                 "${episodeResult[index]['name']}",
            //     //                                 textScaleFactor: 0.75,
            //     //                                 maxLines: 2,
            //     //                                 overflow: TextOverflow.ellipsis,
            //     //                                 style: TextStyle(
            //     //                                     color: themeProvider
            //     //                                                 .isLightTheme !=
            //     //                                             true
            //     //                                         ? Colors.white
            //     //                                         : kPrimaryColor,
            //     //                                     fontSize: SizeConfig
            //     //                                             .safeBlockHorizontal *
            //     //                                         4,
            //     //                                     fontWeight:
            //     //                                         FontWeight.normal),
            //     //                               ),
            //     //                               SizedBox(
            //     //                                 height: 3,
            //     //                               ),
            //     //                               Text(
            //     //                                 episodeResult[index]['author'],
            //     //                                 textScaleFactor: 0.75,
            //     //                                 maxLines: 2,
            //     //                                 overflow: TextOverflow.ellipsis,
            //     //                                 style: TextStyle(
            //     //                                     color: themeProvider
            //     //                                                 .isLightTheme !=
            //     //                                             true
            //     //                                         ? Colors.white
            //     //                                             .withOpacity(0.5)
            //     //                                         : kPrimaryColor
            //     //                                             .withOpacity(0.5),
            //     //                                     fontSize: SizeConfig
            //     //                                             .safeBlockHorizontal *
            //     //                                         4),
            //     //                               ),
            //     //                               SizedBox(
            //     //                                 height: 5,
            //     //                               ),
            //     //                             ],
            //     //                           ),
            //     //                         )
            //     //                       ],
            //     //                     ),
            //     //                   ),
            //     //                 ),
            //     //               );
            //     //             }
            //     //           }),
            //     // ),
            //     // Container(
            //     //   child: communityResult != null &&
            //     //           communityResult.length == 0
            //     //       ? Stack(children: <Widget>[
            //     //           Container(
            //     //             height: double.infinity,
            //     //             width: double.infinity,
            //     //             decoration: BoxDecoration(
            //     //                 image: DecorationImage(
            //     //                     image: AssetImage(
            //     //                         "assets/images/search.png"),
            //     //                     fit: BoxFit.contain)),
            //     //           ),
            //     //           Column(
            //     //               mainAxisAlignment: MainAxisAlignment.end,
            //     //               children: <Widget>[
            //     //                 Row(
            //     //                   mainAxisAlignment: MainAxisAlignment.center,
            //     //                   children: <Widget>[
            //     //                     Flexible(
            //     //                         child: Text("No Data Found",
            //     //                             textScaleFactor: 0.75,
            //     //                             style: TextStyle(
            //     //                               color: Colors.grey,
            //     //                               fontSize: SizeConfig
            //     //                                       .safeBlockHorizontal *
            //     //                                   5,
            //     //                               fontWeight: FontWeight.w600,
            //     //                             ))),
            //     //                     SizedBox(
            //     //                       height: 350,
            //     //                     ),
            //     //                   ],
            //     //                 )
            //     //               ])
            //     //         ])
            //     //       : ListView.builder(
            //     //           controller: _communityScrollController,
            //     //           itemCount: communityResult.length + 1,
            //     //           itemBuilder: (BuildContext context, int index) {
            //     //             if (index == communityResult.length) {
            //     //               return isCommunityLoading == false
            //     //                   ? SizedBox(
            //     //                       height: 0,
            //     //                       width: 0,
            //     //                     )
            //     //                   : Container(
            //     //                       height: 10,
            //     //                       width: double.infinity,
            //     //                       child: LinearProgressIndicator(
            //     //                         minHeight: 10,
            //     //                         backgroundColor: Colors.blue,
            //     //                         valueColor:
            //     //                             AlwaysStoppedAnimation<Color>(
            //     //                                 Color(0xff6249EF)),
            //     //                       ),
            //     //                     );
            //     //             } else {
            //     //               return InkWell(
            //     //                   onTap: () {
            //     //                     Navigator.push(context,
            //     //                         MaterialPageRoute(builder: (context) {
            //     //                       return CommunityProfileView(
            //     //                           communityObject:
            //     //                               communityResult[index]);
            //     //                     }));
            //     //                   },
            //     //                   child: Padding(
            //     //                     padding: EdgeInsets.all(
            //     //                         SizeConfig.safeBlockHorizontal * 3),
            //     //                     child: Container(
            //     //                       width: double.infinity,
            //     //                       height:
            //     //                           MediaQuery.of(context).size.height,
            //     //                       child: GridView.count(
            //     //                           crossAxisCount: 3,
            //     //                           mainAxisSpacing:
            //     //                               SizeConfig.safeBlockHorizontal *
            //     //                                   5,
            //     //                           crossAxisSpacing:
            //     //                               SizeConfig.blockSizeVertical *
            //     //                                   1,
            //     //                           children: [
            //     //                             Container(
            //     //                               decoration: BoxDecoration(
            //     //                                   borderRadius:
            //     //                                       BorderRadius.circular(
            //     //                                           10),
            //     //                                   border: Border.all(
            //     //                                       color:
            //     //                                           kSecondaryColor)),
            //     //                               child: Column(
            //     //                                 mainAxisAlignment:
            //     //                                     MainAxisAlignment.center,
            //     //                                 children: [
            //     //                                   CircleAvatar(
            //     //                                     backgroundColor:
            //     //                                         Colors.transparent,
            //     //                                     backgroundImage: communityResult[
            //     //                                                     index][
            //     //                                                 'profileImageUrl'] ==
            //     //                                             null
            //     //                                         ? AssetImage(
            //     //                                             'assets/images/Favicon.png')
            //     //                                         : NetworkImage(
            //     //                                             communityResult[
            //     //                                                     index][
            //     //                                                 'profileImageUrl']),
            //     //                                   ),
            //     //                                   SizedBox(
            //     //                                     height: 10,
            //     //                                   ),
            //     //                                   Padding(
            //     //                                     padding: const EdgeInsets
            //     //                                             .symmetric(
            //     //                                         horizontal: 10),
            //     //                                     child: Text(
            //     //                                       communityResult[index]
            //     //                                           ['name'],
            //     //                                       textScaleFactor: 0.75,
            //     //                                       maxLines: 2,
            //     //                                       overflow: TextOverflow
            //     //                                           .ellipsis,
            //     //                                       textAlign:
            //     //                                           TextAlign.center,
            //     //                                       style: TextStyle(
            //     //                                           color: Colors.white,
            //     //                                           fontSize: SizeConfig
            //     //                                                   .safeBlockHorizontal *
            //     //                                               3),
            //     //                                     ),
            //     //                                   )
            //     //                                 ],
            //     //                               ),
            //     //                             ),
            //     //                           ]),
            //     //                     ),
            //     //                   ));
            //     //             }
            //     //           }),
            //     // ),
            //   ],
            // ))
          ],
        ),
      ),
    );
  }
}

// class SearchCategoryView extends StatefulWidget {
//   // var categoryObject;
//   //
//   // SearchCategoryView({@required this.categoryObject});
//
//   @override
//   _SearchCategoryViewState createState() => _SearchCategoryViewState();
// }
//
// class _SearchCategoryViewState extends State<SearchCategoryView> {
//   var  searchCategory = [];
//   int pageNumber = 0;
//   PageController _pageController = PageController();
//   int selectedIndex = 0;
// // void getCategoryView()async{
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   String url =" https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&user_id=${prefs.getString('userId')}";
// //   try {
// //     http.Response response = await http.get(Uri.parse(url));
// //     if (response.statusCode == 200) {
// //       print(response.body);
// //       setState(() {
// //         searchCategory = jsonDecode(response.body)['PodcastList'];
// //       });
// //     }
// //   } catch (e) {
// //     print(e);
// //   }
// // }
// //
// //   void getCategoryPodcastsPaginated() async {
// //
// //     SharedPreferences prefs = await SharedPreferences.getInstance();
// //     String url =
// //         'https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&user_id=${prefs.getString('userId')}&page=$pageNumber}';
// //     try {
// //       http.Response response = await http.get(Uri.parse(url));
// //       if (response.statusCode == 200) {
// //         print(response.body);
// //         setState(() {
// //           searchCategory = searchCategory + jsonDecode(response.body)['PodcastList'];
// //           pageNumber = pageNumber + 1;
// //         });
// //       }
// //     } catch (e) {
// //       print(e);
// //     }
// //   }
//
//   @override
//   Widget build(BuildContext context) {
//     var categories = Provider.of<CategoriesProvider>(context);
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Row(
//           children: [
//             SizedBox(
//               width: 150,
//               child: ListView.separated(
//                   itemCount: categories.categoryList.length,
//                   scrollDirection: Axis.vertical,
//                   separatorBuilder: (BuildContext context, int index) {
//                     return SizedBox(height: 5);
//                   },
//                   itemBuilder: (BuildContext context, int index) {
//                     return GestureDetector(
//                       onTap: () {
//                         setState((){
//                           selectedIndex = index;
//                           _pageController.jumpToPage(index);
//                         });
//                       },
//                       child: Container(
//                         child: Row(
//                           children: [
//                             AnimatedContainer(
//                                 duration: Duration(milliseconds: 500),
//                                 color: Colors.blue,
//                                 height: (selectedIndex == index) ? 15 : 0,
//                                 width: 2),
//                             Expanded(
//                               child: AnimatedContainer(
//                                 duration: Duration(milliseconds: 500),
//                                 alignment: Alignment.center,
//                                 height: 50,
//                                 color: (selectedIndex == index)
//                                     ? Colors.blueGrey.withOpacity(0.2)
//                                     : Colors.transparent,
//                                 child: Text(
//                                   categories.categoryList[index]['name']
//                                       .toString(),
//                                   textAlign: TextAlign.start,
//                                   textScaleFactor: 0.75,
//                                   style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize:
//                                       SizeConfig.safeBlockHorizontal * 4),
//                                 ),
//                               ),
//                             )
//                           ],
//                         ),
//                       ),
//                     );
//                   }),
//             ),
//             Expanded(
//                 child: Container(
//                   child: PageView(
//                     scrollDirection: Axis.vertical,
//                     controller: _pageController,
//                     children: [
//                       for (var v in categories.categoryList)
//                         for (var i = 0; i <categories.categoryList.length; i--)
//                           Container(
//                             color: Colors.black,
//                             // child: CategoryView(categoryObject:v),
//                           )
//                     ],
//                   ),
//                 ))
//           ],
//         ),
//       ),
//     );
//   }
// }
