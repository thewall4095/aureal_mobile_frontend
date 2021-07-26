import 'dart:convert';

import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../RouteAnimation.dart';
import 'PodcastView.dart';

class CategoryView extends StatefulWidget {
  static const String id = "CategoryView";

  var categoryObject;

  CategoryView({@required this.categoryObject});

  @override
  _CategoryViewState createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  var result = [];

  bool isLoading = false;

  ScrollController controller = ScrollController();

  int pageNumber = 1;

  void getCategoryPodcasts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&user_id=${prefs.getString('userId')}';
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
        'https://api.aureal.one/public/categorySearch?category_ids=${widget.categoryObject['id']}&user_id=${prefs.getString('userId')}&page=$pageNumber}';
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

  @override
  void initState() {
    // TODO: implement initState
    getCategoryPodcasts();
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        getCategoryPodcastsPaginated();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          '${widget.categoryObject['name']}',
          textScaleFactor:
              mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
//      body: ListView(
//        controller: controller,
//        children: [
//          Container(
//            child: Column(
//              children: [
//                for (var v in result)
//                  GestureDetector(
//                    onTap: () {
//                      Navigator.push(context,
//                          MaterialPageRoute(builder: (context) {
//                        return PodcastView(v);
//                      }));
//                    },
//                    child: Padding(
//                      padding: const EdgeInsets.all(8.0),
//                      child: Container(
//                        width: double.infinity,
//                        child: Row(
//                          children: <Widget>[
//                            Container(
//                              height: 80,
//                              width: 80,
//                              child: FadeInImage.assetNetwork(
//                                  placeholder: 'assets/images/Thumbnail.png',
//                                  image: '${v['image']}'),
//                              decoration: BoxDecoration(),
//                            ),
//                            SizedBox(width: 10),
//                            Expanded(
//                              child: Column(
//                                crossAxisAlignment: CrossAxisAlignment.start,
//                                children: <Widget>[
//                                  Text(
//                                    "${v['name']}",
//                                    maxLines: 2,
//                                    overflow: TextOverflow.ellipsis,
//                                    style: TextStyle(
//                                        color: Colors.white,
//                                        fontSize:
//                                            SizeConfig.safeBlockHorizontal *
//                                                3.5,
//                                        fontWeight: FontWeight.w400),
//                                  ),
//                                  SizedBox(
//                                    height: 3,
//                                  ),
//                                  Text(
//                                    v['author'],
//                                    maxLines: 2,
//                                    overflow: TextOverflow.ellipsis,
//                                    style: TextStyle(
//                                        color: Colors.grey,
//                                        fontSize:
//                                            SizeConfig.safeBlockHorizontal * 3),
//                                  ),
//                                  SizedBox(
//                                    height: 5,
//                                  ),
////                                        Wrap(
////                                          runSpacing: 10,
////                                          spacing: 10,
////                                          runAlignment: WrapAlignment.start,
////                                          children: <Widget>[
////                                            for (var v in podcasts[index]
////                                                ['major_tags'])
////                                              Container(
////                                                decoration: BoxDecoration(
////                                                    borderRadius:
////                                                        BorderRadius.circular(
////                                                            15),
////                                                    color: kSecondaryColor),
////                                                child: Padding(
////                                                  padding: const EdgeInsets
////                                                          .symmetric(
////                                                      horizontal: 8,
////                                                      vertical: 5),
////                                                  child: Text(
////                                                    v['name'],
////                                                    style: TextStyle(
////                                                        color: Colors.grey,
////                                                        fontSize: 13),
////                                                  ),
////                                                ),
////                                              )
////                                          ],
////                                        )
//                                ],
//                              ),
//                            )
//                          ],8
//                        ),
//                      ),
//                    ),
//                  ),
//                isLoading == false
//                    ? SizedBox(
//                        height: 0,
//                        width: 0,
//                      )
//                    : SpinKitPulse(
//                        color: Colors.blue,
//                      ),
//              ],
//            ),
//          ),
//        ],
//      ),
      body: CategoryViewContent(result: result, controller: controller,),
    );
  }
}

class CategoryViewContent extends StatefulWidget {
  var categoryObject;

  List result;
  ScrollController controller;

  CategoryViewContent({@required this.result, @required this.controller,@required this.categoryObject});

  @override
  _CategoryViewContentState createState() => _CategoryViewContentState();
}

class _CategoryViewContentState extends State<CategoryViewContent> {
  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);

    return ListView.builder(
        controller: widget.controller,
        itemCount: widget.result.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == widget.result.length) {
            return Container(
              height: 10,
              width: double.infinity,
              child: LinearProgressIndicator(
                minHeight: 10,
                backgroundColor: Colors.blue,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff6249EF)),
              ),
            );
          } else {
            return WidgetANimator(
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return PodcastView(widget.result[index]['id']);
                  }));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          new BoxShadow(
                            color: Colors.black54.withOpacity(0.2),
                            blurRadius: 10.0,
                          ),
                        ],
                        color: themeProvider.isLightTheme == true
                            ? Colors.white
                            : Color(0xff222222),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),

                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height /10,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10,left: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CachedNetworkImage(
                                    imageBuilder:
                                        (context, imageProvider) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                        ),
                                        width: MediaQuery.of(
                                            context)
                                            .size
                                            .width /
                                            7,
                                        height: MediaQuery.of(
                                            context)
                                            .size
                                            .width /
                                            7,
                                      );
                                    },
                                    imageUrl: '${widget.result[index]['image']}',
                                    fit: BoxFit.cover,
                                    // memCacheHeight:
                                    //     MediaQuery.of(
                                    //             context)
                                    //         .size
                                    //         .width
                                    //         .ceil(),
                                    width: MediaQuery.of(
                                        context)
                                        .size
                                        .width /
                                        7,
                                    height: MediaQuery.of(
                                        context)
                                        .size
                                        .width /
                                        7,
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),

                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20,bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "${widget.result[index]['name']}",
                                  textScaleFactor: mediaQueryData.textScaleFactor
                                      .clamp(0.5, 1.3)
                                      .toDouble(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    // color: Colors.white,
                                      fontSize:
                                      SizeConfig.safeBlockHorizontal * 3.5,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  "${widget.result[index]['author']}",
                                  textScaleFactor: mediaQueryData.textScaleFactor
                                      .clamp(0.5, 0.9)
                                      .toDouble(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    //  color: Colors.grey,
                                      fontSize:
                                      SizeConfig.safeBlockHorizontal * 3),
                                ),
                                SizedBox(
                                  height: 5,
                                ),

                              ],
                            ),
                          )
                        ],
                      )

//                             Row(
//                               children: <Widget>[
//                                 Container(
//                                   height: 80,
//                                   width: 80,
//                                   child:  CachedNetworkImage(
//                                     imageBuilder:
//                                         (context, imageProvider) {
//                                       return Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius: BorderRadius.circular(10),
//                                           image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
//                                         ),
//                                         height: MediaQuery.of(context).size.width,
//                                         width: MediaQuery.of(context).size.width,
//                                       );
//                                     },
//                                     imageUrl: '${result[index]['image']}',
//                                     fit: BoxFit.cover,
//                                     // memCacheHeight:
//                                     //     MediaQuery.of(
//                                     //             context)
//                                     //         .size
//                                     //         .width
//                                     //         .ceil(),
//                                     memCacheHeight: MediaQuery.of(context)
//                                         .size
//                                         .height
//                                         .floor(),
//
//                                     errorWidget: (context, url, error) =>
//                                         Icon(Icons.error),
//                                   ),),
//
//                                 SizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: <Widget>[
//                                       Text(
//                                         "${result[index]['name']}",
//                                         textScaleFactor: mediaQueryData.textScaleFactor
//                                             .clamp(0.5, 1.3)
//                                             .toDouble(),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: TextStyle(
//                                           // color: Colors.white,
//                                             fontSize:
//                                             SizeConfig.safeBlockHorizontal * 3.5,
//                                             fontWeight: FontWeight.w400),
//                                       ),
//                                       SizedBox(
//                                         height: 4,
//                                       ),
//                                       Text(
//                                         result[index]['author'],
//                                         textScaleFactor: mediaQueryData.textScaleFactor
//                                             .clamp(0.5, 0.9)
//                                             .toDouble(),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: TextStyle(
//                                           //  color: Colors.grey,
//                                             fontSize:
//                                             SizeConfig.safeBlockHorizontal * 3),
//                                       ),
//                                       SizedBox(
//                                         height: 5,
//                                       ),
// //                                        Wrap(
// //                                          runSpacing: 10,
// //                                          spacing: 10,
// //                                          runAlignment: WrapAlignment.start,
// //                                          children: <Widget>[
// //                                            for (var v in podcasts[index]
// //                                                ['major_tags'])
// //                                              Container(
// //                                                decoration: BoxDecoration(
// //                                                    borderRadius:
// //                                                        BorderRadius.circular(
// //                                                            15),
// //                                                    color: kSecondaryColor),
// //                                                child: Padding(
// //                                                  padding: const EdgeInsets
// //                                                          .symmetric(
// //                                                      horizontal: 8,
// //                                                      vertical: 5),
// //                                                  child: Text(
// //                                                    v['name'],
// //                                                    style: TextStyle(
// //                                                        color: Colors.grey,
// //                                                        fontSize: 13),
// //                                                  ),
// //                                                ),
// //                                              )
// //                                          ],
// //                                        )
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),

                  ),
                ),
              ),
            );
          }

        });
  }
}

