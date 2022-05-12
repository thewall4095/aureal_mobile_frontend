import 'dart:math';

import 'package:auditory/screens/Home.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../PlayerState.dart';
import '../DiscoverPage.dart';
import '../FollowingPage.dart';

// class CategoryView extends StatefulWidget {
//   static const String id = "CategoryView";
//   var data;
//   String query;
//
//   var categoryObject;
//
//   CategoryView({@required this.categoryObject, this.query, this.data});
//
//   @override
//   _CategoryViewState createState() => _CategoryViewState();
// }
//
// class _CategoryViewState extends State<CategoryView>
//     with SingleTickerProviderStateMixin {
//   var result = [];
//   var explorePodcasts = [];
//   var searchCategory = [];
//   bool _isExploreLoading = false;
//   var newPodcasts = [];
//   bool isLoading = false;
//   ScrollController _explorePodcastScroller;
//   final _controller = TextEditingController();
//   ScrollController controller = ScrollController();
//   String query = '';
//   int pageNumber = 1;
//   int CategoryPageNumber = 1;
//   int newpage = 1;
//   int explorPage = 1;
//
//   bool isCategoryPageLoading = true;
//
//   void explorePodcast() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         "https://api.aureal.one/public/explorePodcasts?type=new&page=${explorPage}&user_id=${prefs.getString('userId')}&category_ids=${widget.categoryObject['id']}";
//     try {
//       http.Response response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         print(response.body);
//         setState(() {
//           explorePodcasts = jsonDecode(response.body)['podcasts'];
//         });
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   void explorePagination() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         "https://api.aureal.one/public/explorePodcasts?user_id=${prefs.getString('userId')}&category_ids=${widget.categoryObject['id']}&page=$explorPage&pageSize=10";
//     try {
//       http.Response response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         print(response.body);
//         setState(() {
//           explorePodcasts =
//               explorePodcasts + jsonDecode(response.body)['podcasts'];
//           explorPage = explorPage + 1;
//         });
//       }
//     } catch (e) {
//       print(e);
//     }
//     await getColor(explorePodcasts[0]['image']);
//     setState(() {
//       _isExploreLoading = false;
//     });
//   }
//
//   void newPodcast() async {
//     setState(() {
//       isLoading = true;
//     });
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         "https://api.aureal.one/public/explorePodcasts?page=${newpage}&pageSize=10&user_id=${prefs.getString('userId')}&category_ids=${widget.categoryObject['id']}";
//     try {
//       http.Response response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         print(response.body);
//         setState(() {
//           newPodcasts = newPodcasts + jsonDecode(response.body)['podcasts'];
//           newpage = newpage + 1;
//         });
//       }
//     } catch (e) {
//       print(e);
//
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void newPodcastget() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         "https://api.aureal.one/public/explorePodcasts?user_id=${prefs.getString('userId')}&category_ids=${widget.categoryObject['id']}";
//     try {
//       http.Response response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         print(response.body);
//         setState(() {
//           newPodcasts = jsonDecode(response.body)['podcasts'];
//           print(newPodcasts.length);
//         });
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   void getCategoryPodcasts() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url =
//         'https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&user_id=${prefs.getString('userId')}';
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
//         'https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&user_id=${prefs.getString('userId')}&page=$pageNumber}';
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
// // Future search()async{
// //   SharedPreferences prefs = await SharedPreferences.getInstance();
// //   String url =
// //       'https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&word=$query&user_id=${prefs.getString('userId')}';
// //   try {
// //     http.Response response = await http.get(Uri.parse(url));
// //     if (response.statusCode == 200) {
// //       setState(() {
// //         searchCategory = jsonDecode(response.body)['PodcastList'];
// //         searchCategory.addAll(jsonDecode(response.body)['PodcastList']);
// //         searchCategory.toSet().toList();
// //
// //       });
// //     }
// //   } catch (e) {
// //     print(e);
// //   }
// // }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//
//     getCategoryPodcasts();
//     newPodcastget();
//     explorePodcast();
//     explorePagination();
//
//     _explorePodcastScroller = ScrollController();
//     _explorePodcastScroller.addListener(() {
//       if (_explorePodcastScroller.position.pixels ==
//           _explorePodcastScroller.position.maxScrollExtent) {
//         explorePagination();
//       }
//     });
//     // setState(() {
//     //  isLoading = true;
//     //});
//     controller.addListener(() {
//       if (controller.position.pixels == controller.position.maxScrollExtent) {
//         newPodcast();
//       }
//     });
//
//     super.initState();
//   }
//
//   var dominantColor = 0xff222222;
//
//   int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
//     r = (r < 0) ? -r : r;
//     g = (g < 0) ? -g : g;
//     b = (b < 0) ? -b : b;
//     opacity = (opacity < 0) ? -opacity : opacity;
//     opacity = (opacity > 1) ? 255 : opacity * 255;
//     r = (r > 255) ? 255 : r;
//     g = (g > 255) ? 255 : g;
//     b = (b > 255) ? 255 : b;
//     int a = opacity.toInt();
//     return int.parse(
//         '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}');
//   }
//
//   void getColor(String url) async {
//     getColorFromUrl(url).then((value) {
//       setState(() {
//         dominantColor = hexOfRGBA(value[0], value[1], value[2]);
//         print(dominantColor.toString());
//
//         SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
//           statusBarColor: Color(dominantColor),
//         ));
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final mediaQueryData = MediaQuery.of(context);
//     var categories = Provider.of<CategoriesProvider>(context);
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     SizeConfig().init(context);
//     return Stack(children: [
//       Scaffold(
//         appBar: AppBar(
//           title: Text( "${widget.categoryObject['name']}"),
//           centerTitle: true,
//           elevation: 1,
//           // bottom: PreferredSize(
//           //   preferredSize: Size.fromHeight(MediaQuery.of(context).size.height/15),
//           //   child: Expanded(
//           //     child: Padding(
//           //       padding: const EdgeInsets.all(15),
//           //       child: Row(
//           //         mainAxisAlignment: MainAxisAlignment.start,
//           //         children: [
//           //           Text(
//           //             "${widget.categoryObject['name']}",
//           //
//           //             style: TextStyle(
//           //                 fontSize: MediaQuery.of(context).size.height/40),
//           //           ),
//           //         ],
//           //       ),
//           //     ),
//           //   ),
//           // ),
//         ),
//         body: SafeArea(
//           child: CustomScrollView(
//             controller: controller,
//             slivers: [
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: MediaQuery.of(context).size.height/35),
//                       Text(
//                         "Top Podcasts",
//                         style:
//                             TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
//                       ),
//                       SizedBox(
//                         height:  MediaQuery.of(context).size.height/35,
//                       ),
//                       Container(
//                         height: MediaQuery.of(context).size.height / 4,
//                         //width: MediaQuery.of(context).size.width/5,
//                         child: ListView.builder(
//                           controller: _explorePodcastScroller,
//                           scrollDirection: Axis.horizontal,
//                           itemCount: explorePodcasts.length + 1,
//                           itemBuilder: (context, index) {
//                             if (index == explorePodcasts.length) {
//                               return Shimmer.fromColors(
//                                 baseColor: themeProvider.isLightTheme == false
//                                     ? kPrimaryColor
//                                     : Colors.white,
//                                 highlightColor:
//                                     themeProvider.isLightTheme == false
//                                         ? Color(0xff3a3a3a)
//                                         : Colors.white,
//                                 child: Column(
//                                   children: [
//                                     Padding(
//                                       padding: const EdgeInsets.all(15.0),
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius:
//                                               BorderRadius.circular(10),
//                                           color: kSecondaryColor,
//                                         ),
//                                         height: MediaQuery.of(context)
//                                                 .size
//                                                 .height /
//                                             8,
//                                         width: MediaQuery.of(context)
//                                                 .size
//                                                 .width /
//                                             4,
//                                       ),
//                                     ),
//                                     SizedBox(width: 30),
//                                     Column(
//                                       children: [
//                                         Container(
//                                           color: kPrimaryColor,
//                                           height: MediaQuery.of(context)
//                                                   .size
//                                                   .height /
//                                               50,
//                                           width: MediaQuery.of(context)
//                                                   .size
//                                                   .width /
//                                               4,
//                                         ),
//                                         SizedBox(
//                                           height: 5,
//                                         ),
//                                         Container(
//                                           color: kPrimaryColor,
//                                           height: MediaQuery.of(context)
//                                                   .size
//                                                   .height /
//                                               50,
//                                           width: MediaQuery.of(context)
//                                                   .size
//                                                   .width /
//                                               4,
//                                         ),
//                                       ],
//                                     )
//                                   ],
//                                 ),
//                               );
//                             }
//                             return GestureDetector(
//                               onTap: () {
//                                 Navigator.push(context,
//                                     CupertinoPageRoute(builder: (context) {
//                                   return PodcastView(
//                                       explorePodcasts[index]['id']);
//                                 }));
//                               },
//                               child: Column(
//                                 children: <Widget>[
//                                   Padding(
//                                     padding: const EdgeInsets.all(15.0),
//                                     child: Container(
//                                       height:
//                                           MediaQuery.of(context).size.height / 8,
//                                       width:
//                                           MediaQuery.of(context).size.width / 4,
//                                       child: Container(
//                                         child: CachedNetworkImage(
//                                           imageBuilder: (context, imageProvider) {
//                                             return Container(
//                                               decoration: BoxDecoration(
//                                                 borderRadius:
//                                                     BorderRadius.circular(10),
//                                                 image: DecorationImage(
//                                                     image: imageProvider,
//                                                     fit: BoxFit.cover),
//                                               ),
//                                               width: MediaQuery.of(context)
//                                                       .size
//                                                       .width /
//                                                   4,
//                                               height: MediaQuery.of(context)
//                                                       .size
//                                                       .width /
//                                                   4,
//                                             );
//                                           },
//                                           imageUrl: explorePodcasts[index]
//                                               ['image'],
//                                           memCacheWidth:
//                                               (MediaQuery.of(context).size.width)
//                                                   .floor(),
//                                           memCacheHeight:
//                                               (MediaQuery.of(context).size.width)
//                                                   .floor(),
//                                           placeholder: (context, url) =>
//                                               Container(
//                                             width: MediaQuery.of(context)
//                                                     .size
//                                                     .width /
//                                                 4,
//                                             height: MediaQuery.of(context)
//                                                     .size
//                                                     .width /
//                                                 4,
//                                             child: Image.asset(
//                                                 'assets/images/Thumbnail.png'),
//                                           ),
//                                           errorWidget: (context, url, error) =>
//                                               Icon(Icons.error),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: 30),
//                                   Expanded(
//                                     child: Container(
//                                       height:
//                                           MediaQuery.of(context).size.height / 8,
//                                       width:
//                                           MediaQuery.of(context).size.width / 4,
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.center,
//                                         children: <Widget>[
//                                           Text(
//                                             "${explorePodcasts[index]['name']}",
//                                             textScaleFactor: mediaQueryData
//                                                 .textScaleFactor
//                                                 .clamp(0.5, 1)
//                                                 .toDouble(),
//                                             maxLines: 1,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: TextStyle(
//                                                 // color: Colors.white,
//                                                 fontSize: SizeConfig
//                                                         .safeBlockHorizontal *
//                                                     3.5,
//                                                 fontWeight: FontWeight.w400),
//                                           ),
//                                           SizedBox(
//                                             height: 4,
//                                           ),
//                                           Text(
//                                             explorePodcasts[index]['author'],
//                                             textScaleFactor: mediaQueryData
//                                                 .textScaleFactor
//                                                 .clamp(0.5, 0.8)
//                                                 .toDouble(),
//                                             maxLines: 1,
//                                             overflow: TextOverflow.ellipsis,
//                                             textAlign: TextAlign.center,
//                                             style: TextStyle(
//                                                 //  color: Colors.grey,
//                                                 fontSize: SizeConfig
//                                                         .safeBlockHorizontal *
//                                                     3),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SliverList(
//                   delegate: SliverChildListDelegate([
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     'New Podcasts',
//                     style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
//                   ),
//                 ),
//                 SizedBox(
//                   height:  MediaQuery.of(context).size.height/35,
//                 )
//               ])),
//               // Text("Greed"),
//               SliverGrid(
//                 gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//                   maxCrossAxisExtent:MediaQuery.of(context).size.height/3,
//                   mainAxisSpacing:0,
//                   crossAxisSpacing: 0,
//                   childAspectRatio: 0.9,
//                 ),
//                 delegate: SliverChildBuilderDelegate(
//                   (BuildContext context, int index) {
//                     if (index == newPodcasts.length) {
//                       return Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           child: Shimmer.fromColors(
//                             baseColor: themeProvider.isLightTheme == false
//                                 ? kPrimaryColor
//                                 : Colors.white,
//                             highlightColor: themeProvider.isLightTheme == false
//                                 ? Color(0xff3a3a3a)
//                                 : Colors.white,
//                             child: Column(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.all(15.0),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(10),
//                                       color: kSecondaryColor,
//                                     ),
//                                     height:
//                                         MediaQuery.of(context).size.height / 6,
//                                     width:
//                                         MediaQuery.of(context).size.width / 2.8,
//                                   ),
//                                 ),
//                                 SizedBox(width: 30),
//                                 Column(
//                                   children: [
//                                     Container(
//                                       color: kPrimaryColor,
//                                       height:
//                                           MediaQuery.of(context).size.height /
//                                               50,
//                                       width:
//                                           MediaQuery.of(context).size.width / 4,
//                                     ),
//                                     SizedBox(
//                                       height: 5,
//                                     ),
//                                     Container(
//                                       color: kPrimaryColor,
//                                       height:
//                                           MediaQuery.of(context).size.height /
//                                               50,
//                                       width:
//                                           MediaQuery.of(context).size.width / 4,
//                                     ),
//                                   ],
//                                 )
//                               ],
//                             ),
//                           ));
//                     }
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.push(context,
//                             CupertinoPageRoute(builder: (context) {
//                           return PodcastView(newPodcasts[index]['id']);
//                         }));
//                       },
//                       child: Column(
//                         children: <Widget>[
//                           Padding(
//                             padding: const EdgeInsets.all(15.0),
//                             child: Container(
//                               height: MediaQuery.of(context).size.height / 6,
//                               width: MediaQuery.of(context).size.width / 2.8,
//                               child: CachedNetworkImage(
//                                 imageBuilder: (context, imageProvider) {
//                                   return Container(
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(10),
//                                       image: DecorationImage(
//                                           image: imageProvider,
//                                           fit: BoxFit.cover),
//                                     ),
//                                     width:
//                                         MediaQuery.of(context).size.width / 4,
//                                     height:
//                                         MediaQuery.of(context).size.width / 4,
//                                   );
//                                 },
//                                 imageUrl: newPodcasts[index]['image'],
//                                 memCacheWidth:
//                                     (MediaQuery.of(context).size.width).floor(),
//                                 memCacheHeight:
//                                     (MediaQuery.of(context).size.width).floor(),
//                                 placeholder: (context, url) => Container(
//                                   width: MediaQuery.of(context).size.width / 4,
//                                   height: MediaQuery.of(context).size.width / 4,
//                                   child: Image.asset(
//                                       'assets/images/Thumbnail.png'),
//                                 ),
//                                 errorWidget: (context, url, error) =>
//                                     Icon(Icons.error),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 30),
//                           Expanded(
//                             child: Container(
//                               height: MediaQuery.of(context).size.height / 7,
//                               width: MediaQuery.of(context).size.width / 3,
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: <Widget>[
//                                   Text(
//                                     "${newPodcasts[index]['name']}",
//                                     textScaleFactor: mediaQueryData
//                                         .textScaleFactor
//                                         .clamp(0.5, 1)
//                                         .toDouble(),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: TextStyle(
//                                         // color: Colors.white,
//                                         fontSize:
//                                             SizeConfig.safeBlockHorizontal *
//                                                 3.5,
//                                         fontWeight: FontWeight.w400),
//                                   ),
//                                   SizedBox(
//                                     height: 4,
//                                   ),
//                                   Text(
//                                     newPodcasts[index]['author'],
//                                     textScaleFactor: mediaQueryData
//                                         .textScaleFactor
//                                         .clamp(0.5, 0.9)
//                                         .toDouble(),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                         //  color: Colors.grey,
//                                         fontSize:
//                                             SizeConfig.safeBlockHorizontal * 3),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                   childCount: newPodcasts.length + 1,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ]);
//   }
// }
class CategoryView extends StatelessWidget {
  final categoryObject;
  CategoryView({@required this.categoryObject});

  SharedPreferences prefs;
  Dio dio = Dio();

  CancelToken _cancel = CancelToken();

  Future getCategoryStructure({var categoryObject}) async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/explore?category_id=${categoryObject['id']}&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        print(response.data);
        return response.data['data'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future generalisedApiCall(String apicall) async {
    Dio dio = Dio();
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print(e);
    }
  }

  // Future getCategories() async {
  //
  //   String url = "https://api.aureal.one/public/getCategory";
  //   try{
  //     var response = await dio.get(url, cancelToken: _cancel);
  //     if(response.statusCode == 200){
  //       print(response.data);
  //       return response.data['allCategory'];
  //     }
  //   }catch(e){
  //     print(e);
  //   }
  //
  //
  // }

  Widget _feedBuilder(BuildContext context, var data) {
    SharedPreferences prefs;
    CancelToken _cancel = CancelToken();

    Future generalisedApiCall(String apicall) async {
      Dio dio = Dio();
      prefs = await SharedPreferences.getInstance();
      String url =
          "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}&category_id=${categoryObject['id']}";

      print(url);

      try {
        var response = await dio.get(url, cancelToken: _cancel);
        if (response.statusCode == 200) {
          return response.data['data'];
        }
      } catch (e) {
        print(e);
      }
    }

    var episodeObject = Provider.of<PlayerChange>(context);
    var currentlyPlaying = Provider.of<PlayerChange>(context);

    List colors = [Colors.red, Colors.green, Colors.yellow];
    Random random = Random();

    switch (data['type']) {
      case 'podcast':
        return PodcastWidget(data: data);
        break;
      case 'episode':
        return EpisodeWidget(
          data: data,
          categoryId: categoryObject['id'],
        );
        break;
      case "playlist":
        return PlaylistWidget(data: data);
        break;
      case 'snippet':
        return SnippetWidget(data: data);
        break;
      case 'user':
        return FutureBuilder(
          future: generalisedApiCall(data['api']),
          builder: (context, snapshot) {
            return Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text("${data['name']}",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 5,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text("${snapshot.data}"),
                ],
              ),
            );
          },
        );
        break;
      case 'featured':
        return FeaturedBuilder(
          data: data,
          category_id: categoryObject['id'],
        );
        break;
      case 'subcategory':
        return FutureBuilder(
          future: generalisedApiCall(data['api']),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("${data['name']}",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 5,
                            fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height / 2.8,
                    child: GridView.builder(
                      itemCount: snapshot.data.length,
                      scrollDirection: Axis.horizontal,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          childAspectRatio: 1 / 4),
                      itemBuilder: (context, int index) {
                        // return Container(child: Text("${snapshot.data[index]['name']}"),);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(
                                        width: 3, color: Colors.primaries[4])),
                                color: Color(0xff1a1a1a)),
                            child: Center(
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(context,
                                      CupertinoPageRoute(builder: (context) {
                                    return SubCategoryView(
                                      data: snapshot.data[index],
                                    );
                                  }));
                                },
                                title: Text(
                                  "${snapshot.data[index]['name']}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("${data['name']}",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 5,
                            fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height / 2.8,
                      width: double.infinity,
                      color: Color(0xff1a1a1a),
                    ),
                  ),
                ],
              );
            }
          },
        );
        break;
      case 'videoepisode':
        return VideoListWidget(data: data);
        break;
      default:
        return Container();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("${categoryObject['name']}"),
      ),
      body: Stack(
        children: [
          Container(
            // height: MediaQuery.of(context).size.height,
            child: FutureBuilder(
              future: getCategoryStructure(categoryObject: categoryObject),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    addAutomaticKeepAlives: true,
                    itemBuilder: (context, int index) {
                      return _feedBuilder(context, snapshot.data[index]);
                    },
                    itemCount: snapshot.data.length,
                  );
                } else {
                  return SizedBox();
                }
              },
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: BottomPlayer())
        ],
      ),
    );
  }
}
