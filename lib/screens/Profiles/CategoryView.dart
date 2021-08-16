import 'dart:convert';

import 'package:auditory/screens/buttonPages/search.dart';
import 'package:auditory/screens/buttonPages/settings/Prefrences.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../CategoriesProvider.dart';
import '../../SearchProvider.dart';
import '../RouteAnimation.dart';
import 'PodcastView.dart';

class CategoryView extends StatefulWidget {
  static const String id = "CategoryView";
  var data;
  String query;

  var  categoryObject;

  CategoryView({@required this.categoryObject, this.query, this.data});

  @override
  _CategoryViewState createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView>
    with SingleTickerProviderStateMixin {
  var result = [];
  var explorePodcasts = [];
  var searchCategory = [];
  bool _isExploreLoading = false;
  var newPodcasts = [];
  bool isLoading = false;
  ScrollController _explorePodcastScroller;
  final _controller = TextEditingController();
  ScrollController controller = ScrollController();
  String query = '';
  int pageNumber = 1;
  int CategoryPageNumber = 1;
  int newpage = 1;
  int explorPage = 1;

  bool isCategoryPageLoading = true;

  void explorePodcast() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/explorePodcasts?type=new&page=${explorPage}&user_id=${prefs
        .getString('userId')}&category_ids=${widget.categoryObject['id']}";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          explorePodcasts = jsonDecode(response.body)['podcasts'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void explorePagination() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/explorePodcasts?user_id=${prefs
        .getString('userId')}&category_ids=${widget
        .categoryObject['id']}&page=$explorPage&pageSize=10";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          explorePodcasts =
              explorePodcasts + jsonDecode(response.body)['podcasts'];
          explorPage = explorPage + 1;
        });
      }
    } catch (e) {
      print(e);
    }
  await  getColor(explorePodcasts[0]['image']);
    setState(() {
      _isExploreLoading = false;
    });
  }

  void newPodcast() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/explorePodcasts?page=${newpage}&pageSize=10&user_id=${prefs
        .getString('userId')}&category_ids=${widget.categoryObject['id']}";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          newPodcasts = newPodcasts + jsonDecode(response.body)['podcasts'];
          newpage = newpage + 1;
        });
      }
    } catch (e) {
      print(e);

      setState(() {
        isLoading = false;
      });
    }
  }

  void newPodcastget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/explorePodcasts?user_id=${prefs
        .getString('userId')}&category_ids=${widget.categoryObject['id']}";
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          newPodcasts = jsonDecode(response.body)['podcasts'];
          print(newPodcasts.length);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void getCategoryPodcasts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/categorySearch?category_ids=${widget
        .categoryObject['id']}&user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          result = jsonDecode(response.body)['PodcastList'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void getCategoryPodcastsPaginated() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/categorySearch?category_ids=${widget
        .categoryObject['id']}&user_id=${prefs.getString(
        'userId')}&page=$pageNumber}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          result = result + jsonDecode(response.body)['PodcastList'];
          pageNumber = pageNumber + 1;
        });
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

// Future search()async{
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String url =
//       'https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&word=$query&user_id=${prefs.getString('userId')}';
//   try {
//     http.Response response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       setState(() {
//         searchCategory = jsonDecode(response.body)['PodcastList'];
//         searchCategory.addAll(jsonDecode(response.body)['PodcastList']);
//         searchCategory.toSet().toList();
//
//       });
//     }
//   } catch (e) {
//     print(e);
//   }
// }


  @override
  void initState() {
    // TODO: implement initState

    getCategoryPodcasts();
    newPodcastget();
    explorePodcast();
    explorePagination();

    _explorePodcastScroller = ScrollController();
    _explorePodcastScroller.addListener(() {
      if (_explorePodcastScroller.position.pixels ==_explorePodcastScroller.position.maxScrollExtent) {
        explorePagination();
      }
    });
    // setState(() {
    //  isLoading = true;
    //});
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        newPodcast();
      }
    });


    super.initState();
  }

  var dominantColor = 0xff222222;

  int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
    r = (r < 0) ? -r : r;
    g = (g < 0) ? -g : g;
    b = (b < 0) ? -b : b;
    opacity = (opacity < 0) ? -opacity : opacity;
    opacity = (opacity > 1) ? 255 : opacity * 255;
    r = (r > 255) ? 255 : r;
    g = (g > 255) ? 255 : g;
    b = (b > 255) ? 255 : b;
    int a = opacity.toInt();
    return int.parse(
        '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b
            .toRadixString(16)}');
  }

  void getColor(String url) async {
    getColorFromUrl(url).then((value) {
      setState(() {
        dominantColor = hexOfRGBA(value[0], value[1], value[2]);
        print(dominantColor.toString());

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Color(dominantColor),
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    var categories = Provider.of<CategoriesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    SizeConfig().init(context);
    return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
             controller: controller,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  expandedHeight: MediaQuery
                      .of(context)
                      .size
                      .height / 3.8,
                  flexibleSpace: Container(
                    child: FlexibleSpaceBar(
                      background: Container(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height,
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [ Color(dominantColor), Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${widget.categoryObject['name']}',
                                    textScaleFactor: mediaQueryData
                                        .textScaleFactor
                                        .clamp(0.5, 1)
                                        .toDouble(),
                                    style: TextStyle(
                                        fontSize: SizeConfig.safeBlockHorizontal *
                                            8,
                                        fontWeight: FontWeight.w700),
                                  ),

                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                ),
                SliverToBoxAdapter(
                  child:
                    Column(
                      children: [
                        Text(
                          "Top Podcasts",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 20,),
                        Container(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height / 3,
                          //width: MediaQuery.of(context).size.width/5,
                          child: ListView.builder(
                            controller: _explorePodcastScroller,
                            scrollDirection: Axis.horizontal,
                            itemCount: explorePodcasts.length + 1,
                            itemBuilder: (context, index) {
                              if( index == explorePodcasts.length){
                                return   Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Shimmer.fromColors(
                                      baseColor: themeProvider.isLightTheme == false
                                          ? kPrimaryColor
                                          : Colors.white,
                                      highlightColor: themeProvider.isLightTheme == false
                                          ? Color(0xff3a3a3a)
                                          : Colors.white,
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: Container(
                                              decoration:
                                              BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                                color: kSecondaryColor,),

                                              height:
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .height / 8,
                                              width: MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width / 4,
                                            ),
                                          ),
                                  SizedBox(width: 30),
                                 Column(
                                   children: [
                                     Container(
                                       color: kPrimaryColor,
                                        height:
                                        MediaQuery
                                            .of(context)
                                            .size
                                            .height /50,
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width / 4,),
                                     SizedBox(height: 5,),
                                     Container(
                                       color: kPrimaryColor,
                                       height:
                                       MediaQuery
                                           .of(context)
                                           .size
                                           .height / 50,
                                       width: MediaQuery
                                           .of(context)
                                           .size
                                           .width / 4,),
                                   ],
                                 )
                                        ],
                                      ),
                                  ));
                              }
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                        return PodcastView(
                                            explorePodcasts[index]['id']);
                                      }));
                                },
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: Container(
                                        height:
                                        MediaQuery
                                            .of(context)
                                            .size
                                            .height / 8,
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width / 4,
                                        child:  Container(
                                          child:   CachedNetworkImage(
                                            imageBuilder:
                                                (context,
                                                imageProvider) {
                                              return Container(
                                                decoration:
                                                BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                                  image: DecorationImage(
                                                      image:
                                                      imageProvider,
                                                      fit: BoxFit
                                                          .cover),
                                                ),
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                    4,
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                    4,
                                              );
                                            },
                                            imageUrl:
                                            explorePodcasts[index]['image'],
                                            memCacheWidth:
                                            (MediaQuery.of(context)
                                                .size
                                                .width)
                                                .floor(),
                                            memCacheHeight:
                                            (MediaQuery.of(context)
                                                .size
                                                .width)
                                                .floor(),
                                            placeholder:
                                                (context,
                                                url) =>
                                                Container(
                                                  width: MediaQuery.of(
                                                      context)
                                                      .size
                                                      .width /
                                                      4,
                                                  height: MediaQuery.of(
                                                      context)
                                                      .size
                                                      .width /
                                                      4,
                                                  child: Image
                                                      .asset(
                                                      'assets/images/Thumbnail.png'),
                                                ),
                                            errorWidget: (context,
                                                url,
                                                error) =>
                                                Icon(Icons
                                                    .error),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 30),
                                    Expanded(
                                      child: Container(
                                        height:
                                        MediaQuery
                                            .of(context)
                                            .size
                                            .height / 8,
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width / 4,
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              "${explorePodcasts[index]['name']}",
                                              textScaleFactor: mediaQueryData
                                                  .textScaleFactor
                                                  .clamp(0.5, 1)
                                                  .toDouble(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                // color: Colors.white,
                                                  fontSize:
                                                  SizeConfig.safeBlockHorizontal *
                                                      3.5,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            SizedBox(
                                              height: 4,
                                            ),
                                            Text(
                                              explorePodcasts[index]['author'],
                                              textScaleFactor: mediaQueryData
                                                  .textScaleFactor
                                                  .clamp(0.5, 0.8)
                                                  .toDouble(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                //  color: Colors.grey,
                                                  fontSize:
                                                  SizeConfig.safeBlockHorizontal *
                                                      3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                SliverList(
                    delegate: SliverChildListDelegate([
                      Center(
                        child: Text(
                          'New Podcasts',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(height: 20,)
                    ]
                    )),
                // Text("Greed"),
                SliverGrid(
                  gridDelegate:SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 205.0,
                    mainAxisSpacing: 40.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index){
                    if (index == newPodcasts.length ){
                      return  Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Shimmer.fromColors(
                            baseColor: themeProvider.isLightTheme == false
                                ? kPrimaryColor
                                : Colors.white,
                            highlightColor: themeProvider.isLightTheme == false
                                ? Color(0xff3a3a3a)
                                : Colors.white,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Container(
                                    decoration:
                                    BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(
                                          10),
                                      color: kSecondaryColor,),

                                    height: MediaQuery
                                        .of(context)
                                        .size
                                        .height /6,
                                    width: MediaQuery
                                        .of(context)
                                        .size
                                        .width / 2.8,
                                  ),
                                ),
                                SizedBox(width: 30),
                                Column(
                                  children: [
                                    Container(
                                      color: kPrimaryColor,
                                      height:
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height /50,
                                      width: MediaQuery
                                          .of(context)
                                          .size
                                          .width / 4,),
                                    SizedBox(height: 5,),
                                    Container(
                                      color: kPrimaryColor,
                                      height:
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height / 50,
                                      width: MediaQuery
                                          .of(context)
                                          .size
                                          .width / 4,),
                                  ],
                                )
                              ],
                            ),
                          ));
                    } return GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                                return PodcastView(newPodcasts[index]['id']);
                              }));
                        },
                        child:
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Container(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height /6,
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width / 2.8,
                                  child:  CachedNetworkImage(
                                    imageBuilder:
                                        (context,
                                        imageProvider) {
                                      return Container(
                                        decoration:
                                        BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(
                                              10),
                                          image: DecorationImage(
                                              image:
                                              imageProvider,
                                              fit: BoxFit
                                                  .cover),
                                        ),
                                        width: MediaQuery.of(context)
                                            .size
                                            .width /
                                            4,
                                        height: MediaQuery.of(context)
                                            .size
                                            .width /
                                            4,
                                      );
                                    },
                                    imageUrl:
                                    newPodcasts[index]['image'],
                                    memCacheWidth:
                                    (MediaQuery.of(context)
                                        .size
                                        .width)
                                        .floor(),
                                    memCacheHeight:
                                    (MediaQuery.of(context)
                                        .size
                                        .width)
                                        .floor(),
                                    placeholder:
                                        (context,
                                        url) =>
                                        Container(
                                          width: MediaQuery.of(
                                              context)
                                              .size
                                              .width /
                                              4,
                                          height: MediaQuery.of(
                                              context)
                                              .size
                                              .width /
                                              4,
                                          child: Image
                                              .asset(
                                              'assets/images/Thumbnail.png'),
                                        ),
                                    errorWidget: (context,
                                        url,
                                        error) =>
                                        Icon(Icons
                                            .error),
                                  ),
                                ),
                              ),
                              SizedBox(width: 30),
                              Expanded(
                                child: Container(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height / 7,
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width / 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        "${newPodcasts[index]['name']}",
                                        textScaleFactor: mediaQueryData
                                            .textScaleFactor
                                            .clamp(0.5, 1)
                                            .toDouble(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          // color: Colors.white,
                                            fontSize:
                                            SizeConfig.safeBlockHorizontal * 3.5,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        newPodcasts[index]['author'],
                                        textScaleFactor: mediaQueryData
                                            .textScaleFactor
                                            .clamp(0.5, 0.9)
                                            .toDouble(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          //  color: Colors.grey,
                                            fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                      ),

                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),

                      );

                    },

                    childCount: newPodcasts.length + 1,

                  ),
                ),
              ],
            ),
          ),
        );
  }
}
// class SearchCategorys extends StatefulWidget {
//   static const String id = "CategoryView";
//   var data;
//   String query;
//
//   var categoryObject;
//
//   SearchCategorys({@required this.categoryObject, this.query, this.data});
//
//   @override
//   _SearchCategorysState createState() => _SearchCategorysState();
// }
//
// class _SearchCategorysState extends State<SearchCategorys> {
//   var result = [];
//
//   bool isLoading = false;
//
//   final _controller = TextEditingController();
//   ScrollController controller = ScrollController();
//   String query = '';
//   int pageNumber = 1;
//
//   bool isCategoryPageLoading = true;
//   void getCategoryPodcasts() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         'https://api.aureal.one/public/categorySearch?category_ids=${widget
//         .categoryObject['id']}&user_id=${prefs.getString('userId')}';
//     try {
//       http.Response response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         print(response.body);
//         setState(() {
//           result = jsonDecode(response.body)['PodcastList'];
//         });
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   void getCategoryPodcastsPaginated() async {
//     setState(() {
//       isLoading = true;
//     });
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         'https://api.aureal.one/public/categorySearch?category_ids=${widget
//         .categoryObject['id']}&user_id=${prefs.getString(
//         'userId')}&page=$pageNumber}';
//     try {
//       http.Response response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         print(response.body);
//         setState(() {
//           result = result + jsonDecode(response.body)['PodcastList'];
//           pageNumber = pageNumber + 1;
//         });
//       }
//     } catch (e) {
//       print(e);
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   Future searchResult(String query) {
//     result = result.where((result) {
//       final titleLower = result['name'].toLowerCase();
//       final authorLower = result['author'].toLowerCase();
//       final searchLower = query.toLowerCase();
//
//       return titleLower.contains(searchLower) ||
//           authorLower.contains(searchLower);
//     }).toList();
//
//     setState(() {
//       this.query = query;
//       this.result = result;
//     });
//   }
//   @override
//   void initState() {
//     // TODO: implement initState
//     getCategoryPodcasts();
//     // controller.addListener(() {
//     //   if (controller.position.pixels ==
//     //       controller.position.maxScrollExtent) {
//     //     explorePagination();
//     //   }
//     //   // });
//     //   // }
//     // });
//     // controller.addListener(() {
//     //   if (controller.position.pixels == controller.position.maxScrollExtent) {
//     //     getCategoryPodcastsPaginated();
//     controller.addListener(() {
//       if (controller.position.pixels == controller.position.maxScrollExtent) {
//         getCategoryPodcastsPaginated();
//       }
//     });
//
//     super.initState();
//   }
  // @override
  // Widget build(BuildContext context) {
  //   var categories = Provider.of<CategoriesProvider>(context);
  //   return Scaffold(
  //     appBar: AppBar(
  //       elevation: 0,
  //       backgroundColor: Colors.transparent,
  //     ),
  //     body: ListView.builder(
  //         controller: controller,
  //         itemCount: result.length + 1,
  //         itemBuilder: (BuildContext context, int index) {
  //           return index == 0 ? _searchBr() : _categorieslistview(index - 1);
  //         }),
  //   );
  // }

//
//   _searchBr() {
//     return Container(
//       margin: EdgeInsets.only(top: 10),
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
//       decoration: BoxDecoration(
//         color: Colors.black.withAlpha(10),
//         borderRadius: BorderRadius.all(
//           Radius.circular(20),
//         ),
//       ),
//
//       child: TextField(
//         controller: _controller,
//         decoration: InputDecoration(
//           icon: Icon(Icons.search,),
//           suffixIcon: result != null
//               ? GestureDetector(
//             child: Icon(Icons.close, color: Colors.white70,),
//             onTap: () {
//               Navigator.pop(context);
//               query = '';
//             },
//           )
//               : null,
//           hintText: "search",
//           border: InputBorder.none,
//         ),
//         onChanged: searchResult,
//       ),
//     );
//   }
//   _categorieslistview(index) {
//     final mediaQueryData = MediaQuery.of(context);
//     return WidgetANimator(
//       ListView.builder(
//         itemCount: result.length,
//         controller: controller,
//         itemBuilder: (BuildContext context, int index) {
// //
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) {
//                 return PodcastView(result[index]['id']);
//               }));
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Container(
//                 width: double.infinity,
//                 child: Row(
//                   children: <Widget>[
//                     Container(
//                       height: 80,
//                       width: 80,
//                       child: CachedNetworkImage(
//                         imageBuilder: (context, imageProvider) {
//                           return Container(
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10),
//                               image: DecorationImage(
//                                   image: imageProvider, fit: BoxFit.cover),
//                             ),
//                             height: MediaQuery
//                                 .of(context)
//                                 .size
//                                 .width,
//                             width: MediaQuery
//                                 .of(context)
//                                 .size
//                                 .width,
//                           );
//                         },
//                         imageUrl: '${result[index]['image']}',
//                         fit: BoxFit.cover,
//
//                         memCacheHeight: MediaQuery
//                             .of(context)
//                             .size
//                             .height
//                             .floor(),
//
//                         errorWidget: (context, url, error) => Icon(Icons.error),
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: <Widget>[
//                           Text(
//                             "${result[index]['name']}",
//                             textScaleFactor: mediaQueryData.textScaleFactor
//                                 .clamp(0.5, 1.3)
//                                 .toDouble(),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               // color: Colors.white,
//                                 fontSize: SizeConfig.safeBlockHorizontal * 3.5,
//                                 fontWeight: FontWeight.w400),
//                           ),
//                           SizedBox(
//                             height: 4,
//                           ),
//                           Text(
//                             result[index]['author'],
//                             textScaleFactor: mediaQueryData.textScaleFactor
//                                 .clamp(0.5, 0.9)
//                                 .toDouble(),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               //  color: Colors.grey,
//                                 fontSize: SizeConfig.safeBlockHorizontal * 3),
//                           ),
//                           SizedBox(
//                             height: 5,
//                           ),
//
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }
//       ),
//     );
//   }
//
// }


  //   return Scaffold(
  //     appBar: AppBar(
  //       elevation: 0,
  //       backgroundColor: Colors.transparent,
  //       title: Text(
  //         '${widget.categoryObject['name']}',
  //         textScaleFactor:
  //             mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
  //         style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
  //       ),
  //     ),
  //     body: ListView.builder(
  //         controller: controller,
  //         itemCount: result.length + 1,
  //         itemBuilder: (BuildContext context, int index) {
  //           return index == 0 ? _searchBr() : _categorieslistview(index - 1);
  //         }),
  //   );
  // }

//