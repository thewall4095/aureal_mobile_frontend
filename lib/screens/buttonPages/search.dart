import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import 'package:auditory/Services/DurationCalculator.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/screens/FollowingPage.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Profiles/Comments.dart';
import 'package:auditory/screens/Profiles/EpisodeView.dart';
import 'package:auditory/screens/Profiles/publicUserProfile.dart';
import 'package:auditory/utilities/getRoomDetails.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:html/parser.dart';
import 'package:auditory/CategoriesProvider.dart';
import 'package:auditory/screens/Profiles/CategoryView.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jitsi_meet/feature_flag/feature_flag_enum.dart' as featureflags;
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:line_icons/line_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SearchProvider.dart';

// class Search extends StatefulWidget {
//   static const String id = "Search";
//
//   @override
//   _SearchState createState() => _SearchState();
// }
//
// class _SearchState extends State<Search> with SingleTickerProviderStateMixin {
//   ScrollController _controller = ScrollController();
//
//   TabController _tabController;
//
//   TextEditingController _textController;
//   final List<String> colors = <String>[
//     'red',
//     'blue',
//     'green',
//     'yellow',
//     'orange'
//   ];
//   String query = '';
//
//   int pageNumber = 1;
//
//   var searchEpisodes = [];
//   var searchPodcasts = [];
//
//   bool loading = false;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _textController = TextEditingController();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     _tabController.dispose();
//     _controller.dispose();
//     _textController.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {}
// }

class SearchFunctionality extends SearchDelegate {
  Future getSearch() async {
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

  CancelToken _cancel = CancelToken();

  Future getPodcast() async {
    Dio dio = Dio();

    // if (_pagePodcast != 0) {
    //   cancelToken.cancel();
    // }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/search?word=$query&loggedinuser${prefs.getString('userId')}&page=0";

    try {
      var response = await dio.get(url);
      if(response.statusCode == 200){
        return response.data['PodcastList'];
      }

    } catch (e) {
      print(e);
    }

  }

  Future getUsers() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/userSearch?word=$query&loggedinuser=${prefs.getString('userId')}&page=0&pageSize=10";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        return response.data['users'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }

  }

  Future getEpisodes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/searchEpisodes?word=$query&loggedinuser=${prefs.getString('userId')}&page=0";
    print(url);
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        return response.data['episodes'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    print("Episode Search Ended");
  }



  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    // throw UnimplementedError();

    return <Widget>[
      IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            close(context, true);
          }
          //    query = '';
          //     },
          )
    ];
  }

  Future getSearchSnippets() async {
    String url = "";
    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }
  }

  Future getPlaylistSearch() async {
    String url = "";
    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){
      print(e);
    }
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

  RegExp htmlMatch = RegExp(r'(\w+)');

  @override
  Widget buildResults(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // TODO: implement buildResults
    // throw UnimplementedError();
    var search = Provider.of<SearchResultProvider>(context, listen: false);

    return Container(
      color: themeProvider.isLightTheme == true ? Colors.white : Colors.black,

      child: Container(
        height: MediaQuery.of(context).size.height,
        color: Color(0xff161616),
        child: ListView(
          shrinkWrap: true,
          children: [
            FutureBuilder(
              future: getPodcast(),
              builder: (context, snapshot){
                try{
                    return Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ListTile(title: Text("${data['name']}", style: TextStyle(
                          //     fontSize: SizeConfig.safeBlockHorizontal * 5,
                          //     fontWeight: FontWeight.bold
                          // )),trailing: ShaderMask(shaderCallback: (Rect bounds){
                          //   return LinearGradient(colors: [Color(
                          //       0xff5bc3ef),
                          //     Color(
                          //         0xff5d5da8)]).createShader(bounds);
                          // },child: GestureDetector(onTap: (){
                          //   Navigator.push(context, CupertinoPageRoute(builder: (context){
                          //     return SeeMore(data: data);
                          //   },),);
                          // },child: Text("See more", style: TextStyle(fontWeight: FontWeight.bold),))),),
                          // SizedBox(height: 10,),
                          ListTile(
                            title: Text("Podcasts", textScaleFactor: 1.0, style: TextStyle(
                          color: Colors.white,
                          fontSize:
                          SizeConfig.safeBlockHorizontal * 4,
                          fontWeight: FontWeight.bold),),
                          ),
                          Container(
                            width: double.infinity,
                            height: SizeConfig.blockSizeVertical * 25,
                            constraints: BoxConstraints(
                                minHeight:
                                MediaQuery.of(context).size.height *
                                    0.17),
                            child: ListView.builder(
                              addAutomaticKeepAlives: true,
                              itemCount: snapshot.data.length,
                              itemBuilder: (context, int index){
                                return Padding(
                                  padding:
                                  const EdgeInsets.fromLTRB(
                                      15, 0, 0, 8),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                              builder: (context) =>
                                                  PodcastView(
                                                      snapshot.data[index]['id'])));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        // x
                                        borderRadius:
                                        BorderRadius.circular(
                                            15),
                                      ),
                                      width: MediaQuery.of(context)
                                          .size
                                          .width *
                                          0.38,
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        mainAxisSize:
                                        MainAxisSize.min,
                                        children: [
                                          CachedNetworkImage(
                                            errorWidget: (context,
                                                url, error) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: NetworkImage(
                                                            "https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png"),
                                                        fit: BoxFit
                                                            .cover),
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        3)),
                                                width: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width *
                                                    0.38,
                                                height: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width *
                                                    0.38,
                                              );
                                            },
                                            imageBuilder: (context,
                                                imageProvider) {
                                              return Container(
                                                // child: Column(
                                                //   crossAxisAlignment: CrossAxisAlignment.end,
                                                //   mainAxisAlignment: MainAxisAlignment.start,
                                                //   children: [
                                                //     Padding(
                                                //       padding: const EdgeInsets.all(3),
                                                //       child: InkWell(
                                                //         onTap: (){
                                                //           showModalBottomSheet(
                                                //               context: context,
                                                //               builder: (context) {
                                                //                 return Column(
                                                //                   mainAxisSize: MainAxisSize.min,
                                                //                   children: [
                                                //                     Padding(
                                                //                       padding:
                                                //                       const EdgeInsets.symmetric(vertical: 10),
                                                //                       child: ListTile(
                                                //                         leading: CachedNetworkImage(
                                                //                           memCacheHeight:
                                                //                           (MediaQuery.of(context).size.width /
                                                //                               2)
                                                //                               .floor(),
                                                //                           imageUrl: data['image'],
                                                //                           imageBuilder: (context, imageProvider) {
                                                //                             return Container(
                                                //                               height: 50,
                                                //                               width: 50,
                                                //                               decoration: BoxDecoration(
                                                //                                   borderRadius:
                                                //                                   BorderRadius.circular(5),
                                                //                                   image: DecorationImage(
                                                //                                       image: imageProvider,
                                                //                                       fit: BoxFit.cover)),
                                                //                             );
                                                //                           },
                                                //                         ),
                                                //                         title: Text(
                                                //                           "${data['name']}",
                                                //                           style: TextStyle(
                                                //                               fontWeight: FontWeight.w600),
                                                //                         ),
                                                //                         subtitle: Text("${data['author']}"),
                                                //                       ),
                                                //                     ),
                                                //                     Divider(),
                                                //                     ListTile(
                                                //                       leading: Icon(Icons.ios_share),
                                                //                       title: Text("Share"),
                                                //                       onTap: () {
                                                //                         podcastShare();
                                                //                       },
                                                //                     ),
                                                //                     ListTile(
                                                //                       onTap: () {
                                                //                         follow();
                                                //                         // setState(() {
                                                //                         //   if (followState == FollowState.follow) {
                                                //                         //     followState = FollowState.following;
                                                //                         //   } else {
                                                //                         //     followState = FollowState.follow;
                                                //                         //   }
                                                //                         // });
                                                //                         Navigator.pop(context);
                                                //                       },
                                                //                       leading: Icon(Icons.add_circle_outline),
                                                //                       title: Text("Subscribe"),
                                                //                     ),
                                                //                     // ListTile(
                                                //                     //   leading: Icon(Icons.notification_add),
                                                //                     //   title: Text("Get Notified"),
                                                //                     // ),
                                                //                     //     ListTile(
                                                //                     //       onTap:() {
                                                //                     //
                                                //                     // },
                                                //                     //       leading: Icon(Icons.playlist_add),
                                                //                     //       title: Text("Add to podcast playlist"),
                                                //                     //     ),
                                                //                     // ListTile(
                                                //                     //   leading: Icon(Icons.animation),
                                                //                     //   title: Text("More like these"),
                                                //                     // ),
                                                //                     // ListTile(
                                                //                     //   leading: Icon(Icons.send),
                                                //                     //   title: Text("Invite this podcast to Aureal"),
                                                //                     // ),
                                                //                   ],
                                                //                 );
                                                //               });
                                                //         },
                                                //         child: ClipOval(
                                                //
                                                //           child: BackdropFilter(
                                                //             filter:  ImageFilter.blur(
                                                //             sigmaY: 10.0,
                                                //             sigmaX: 10.0,
                                                //           ),
                                                //             child: Container(decoration: BoxDecoration(shape: BoxShape.circle), child: Padding(
                                                //               padding: const EdgeInsets.all(2),
                                                //               child: Icon(Icons.more_vert_outlined, color: Colors.white.withOpacity(0.7),),
                                                //             )),
                                                //           ),
                                                //         ),
                                                //       ),
                                                //     ),
                                                //   ],
                                                // ),
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image:
                                                        imageProvider,
                                                        fit: BoxFit
                                                            .cover),
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        3)),
                                                width: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width *
                                                    0.38,
                                                height: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width *
                                                    0.38,
                                              );
                                            },
                                            memCacheHeight:
                                            (MediaQuery.of(
                                                context)
                                                .size
                                                .height)
                                                .floor(),
                                            imageUrl:snapshot.data[index]['image'],

                                            placeholder: (context,
                                                imageProvider) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: AssetImage(
                                                            'assets/images/Thumbnail.png'),
                                                        fit: BoxFit
                                                            .cover)),
                                                height: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width *
                                                    0.38,
                                                width: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width *
                                                    0.38,
                                              );
                                            },
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            snapshot.data[index]['name'],
                                            maxLines: 1,
                                            textScaleFactor: 1.0,
                                            overflow: TextOverflow
                                                .ellipsis,
                                            style:
                                                TextStyle(color: Color(0xffe8e8e8)),
                                          ),
                                          Text(
                                            snapshot.data[index]['author'],
                                            maxLines: 2,
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                fontSize: SizeConfig
                                                    .safeBlockHorizontal *
                                                    2.5,
                                                color: Color(
                                                    0xffe777777)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              scrollDirection: Axis.horizontal,

                            ),
                          ),
                          // Text("${snapshot.data}"),
                        ],
                      ),
                    );
                  }catch(e){
                    return Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Container(
                          width: double.infinity,
                          height: SizeConfig.blockSizeVertical * 25,
                          constraints: BoxConstraints(
                              minHeight:
                              MediaQuery.of(context).size.height *
                                  0.17),
                          child: ListView.builder(

                            addAutomaticKeepAlives: true,

                            itemCount: 10,
                            itemBuilder: (context, int index){
                              return Padding(
                                padding:
                                const EdgeInsets.fromLTRB(
                                    15, 0, 0, 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    // x
                                    borderRadius:
                                    BorderRadius.circular(
                                        15),
                                  ),
                                  width: MediaQuery.of(context)
                                      .size
                                      .width *
                                      0.38,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      CachedNetworkImage(
                                        errorWidget: (context,
                                            url, error) {
                                          return Container(
                                            decoration: BoxDecoration(
                                                color: Color(0xff222222),
                                                // image: DecorationImage(
                                                //     image: NetworkImage(
                                                //         "https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png"),
                                                //     fit: BoxFit
                                                //         .cover),
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    3)),
                                            width: MediaQuery.of(
                                                context)
                                                .size
                                                .width *
                                                0.38,
                                            height: MediaQuery.of(
                                                context)
                                                .size
                                                .width *
                                                0.38,
                                          );
                                        },
                                        imageBuilder: (context,
                                            imageProvider) {
                                          return Container(
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image:
                                                    imageProvider,
                                                    fit: BoxFit
                                                        .cover),
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    3)),
                                            width: MediaQuery.of(
                                                context)
                                                .size
                                                .width *
                                                0.38,
                                            height: MediaQuery.of(
                                                context)
                                                .size
                                                .width *
                                                0.38,
                                          );
                                        },
                                        memCacheHeight:
                                        (MediaQuery.of(
                                            context)
                                            .size
                                            .height)
                                            .floor(),
                                        imageUrl: 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                                        placeholder: (context,
                                            imageProvider) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              // image: DecorationImage(
                                              //     image: AssetImage(
                                              //         'assets/images/Thumbnail.png'),
                                              //     fit: BoxFit
                                              //         .cover),
                                                color: Color(0xff222222)
                                            ),
                                            height: MediaQuery.of(
                                                context)
                                                .size
                                                .width *
                                                0.38,
                                            width: MediaQuery.of(
                                                context)
                                                .size
                                                .width *
                                                0.38,
                                          );
                                        },
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),

                                    ],
                                  ),
                                ),
                              );
                            },
                            scrollDirection: Axis.horizontal,

                          ),
                        ),
                      ],
                    );
                  }


              },
            ),
            FutureBuilder(
              future: getEpisodes(),
              builder: (context, snapshot){
                try{
                  if(snapshot.hasData){
                    return ColumnBuilder(itemCount: snapshot.data.length,itemBuilder: (context, int index){
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) =>
                                        EpisodeView(
                                            episodeId: snapshot.data[index]['id'])));
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  // boxShadow: [
                                  //   new BoxShadow(
                                  //     color: Colors.black54
                                  //         .withOpacity(0.2),
                                  //     blurRadius: 10.0,
                                  //   ),
                                  // ],
                                  // border: Border(bottom: BorderSide(width: 0.5,color: Color(0xffe8e8e8).withOpacity(0.5))),
                                  color:
                                  Color(0xff222222),
                                  borderRadius:
                                  BorderRadius.circular(5),
                                ),
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 15,
                                      horizontal: 15),
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                    children: [
                                      Row(
                                        children: [
                                          CachedNetworkImage(
                                            imageBuilder: (context,
                                                imageProvider) {
                                              return Container(
                                                decoration:
                                                BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      3),
                                                  image: DecorationImage(
                                                      image:
                                                      imageProvider,
                                                      fit: BoxFit
                                                          .cover),
                                                ),
                                                width: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width /
                                                    8,
                                                height: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width /
                                                    8,
                                              );
                                            },
                                            imageUrl:
                                            snapshot.data[index]['image'] == null ? snapshot.data[index]['podcast_image'] : snapshot.data[index]['image'],
                                            memCacheWidth:
                                            MediaQuery.of(
                                                context)
                                                .size
                                                .width
                                                .floor(),
                                            memCacheHeight:
                                            MediaQuery.of(
                                                context)
                                                .size
                                                .width
                                                .floor(),
                                            placeholder:
                                                (context,
                                                url) =>
                                                Container(
                                                  width: MediaQuery.of(
                                                      context)
                                                      .size
                                                      .width /
                                                      8,
                                                  height: MediaQuery.of(
                                                      context)
                                                      .size
                                                      .width /
                                                      8,
                                                  child: Image.asset(
                                                      'assets/images/Thumbnail.png'),
                                                ),
                                            errorWidget:
                                                (context, url,
                                                error) =>
                                                Icon(Icons
                                                    .error),
                                          ),
                                          SizedBox(
                                              width: SizeConfig
                                                  .screenWidth /
                                                  26),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        CupertinoPageRoute(
                                                            builder: (context) =>
                                                                PodcastView(snapshot.data[index]['podcast_id'])));
                                                  },
                                                  child: Text(
                                                    snapshot.data[index]['podcast_name'],
                                                    textScaleFactor: 0.8,
                                                    style: TextStyle(
                                                      color: Color(
                                                          0xffe8e8e8),
                                                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                Text(
                                                  '${timeago.format(DateTime.parse(snapshot.data[index]['published_at']))}',
                                                  textScaleFactor: 0.8,
                                                  style: TextStyle(
                                                    color: Color(
                                                        0xffe8e8e8),
                                                      fontSize: SizeConfig.safeBlockHorizontal * 3),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      Padding(
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                            vertical: 15),
                                        child: Container(
                                          width:
                                          double.infinity,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              Text(
                                                snapshot.data[index]['name'],
                                                textScaleFactor:
                                                0.8,
                                                style: TextStyle(
                                                  color: Color(
                                                      0xffe8e8e8),
                                                    fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    vertical:
                                                    10),
                                                child: snapshot.data[index]['summary'] ==
                                                    null
                                                    ? SizedBox(
                                                    width:
                                                    0,
                                                    height:
                                                    0)
                                                    : (htmlMatch.hasMatch(snapshot.data[index]['summary']) ==
                                                    true
                                                    ? Text(
                                                  parse(snapshot.data[index]['summary']).body.text,
                                                  textScaleFactor:
                                                  0.8,
                                                  maxLines:
                                                  2,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                      fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                )
                                                    : Text(
                                                  '${snapshot.data[index]['summary']}',
                                                  textScaleFactor:
                                                  1.0,
                                                  style: TextStyle(
                                                         color: Colors.white,
                                                      fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                )),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),

                                      // PlaybackButtons(data: snapshot.data[index], index: index, playlist: playlist,)

                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },);
                  }else{
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < 6; i++)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  color: Color(0xff222222)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          width:
                                          MediaQuery.of(context)
                                              .size
                                              .width /
                                              7,
                                          height:
                                          MediaQuery.of(context)
                                              .size
                                              .width /
                                              7,
                                          decoration: BoxDecoration(
                                              color:
                                              Color(0xff161616),
                                              borderRadius:
                                              BorderRadius
                                                  .circular(10)),
                                        ),
                                        SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            Container(
                                              decoration:
                                              BoxDecoration(
                                                  color: Color(
                                                      0xff161616)),
                                              height: 16,
                                              width: MediaQuery.of(
                                                  context)
                                                  .size
                                                  .width /
                                                  3,
                                            ),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Container(
                                              decoration:
                                              BoxDecoration(
                                                  color: Color(
                                                      0xff161616)),
                                              height: 8,
                                              width: MediaQuery.of(
                                                  context)
                                                  .size
                                                  .width /
                                                  4,
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 3),
                                      child: Container(
                                          color: Color(0xff161616),
                                          height: 10,
                                          width:
                                          MediaQuery.of(context)
                                              .size
                                              .width),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 3),
                                      child: Container(
                                          color: Color(0xff161616),
                                          height: 10,
                                          width:
                                          MediaQuery.of(context)
                                              .size
                                              .width /
                                              2),
                                    ),
                                    SizedBox(
                                      height: 6,
                                    ),
                                    // Padding(
                                    //   padding: const EdgeInsets.only(
                                    //       top: 3),
                                    //   child: Container(
                                    //       color: Color(0xff161616),
                                    //       height: 6,
                                    //       width:
                                    //       MediaQuery.of(context)
                                    //           .size
                                    //           .width),
                                    // ),
                                    // Padding(
                                    //   padding: const EdgeInsets.only(
                                    //       top: 3),
                                    //   child: Container(
                                    //       color: Color(0xff161616),
                                    //       height: 6,
                                    //       width:
                                    //       MediaQuery.of(context)
                                    //           .size
                                    //           .width *
                                    //           0.75),
                                    // ),
                                    // Padding(
                                    //   padding:
                                    //   const EdgeInsets.symmetric(
                                    //       vertical: 20),
                                    //   child: Row(
                                    //     mainAxisAlignment:
                                    //     MainAxisAlignment.start,
                                    //     children: [
                                    //       Container(
                                    //         decoration: BoxDecoration(
                                    //           borderRadius:
                                    //           BorderRadius
                                    //               .circular(10),
                                    //           color:
                                    //           Color(0xff161616),
                                    //         ),
                                    //         height: 25,
                                    //         width:
                                    //         MediaQuery.of(context)
                                    //             .size
                                    //             .width /
                                    //             8,
                                    //         //    color: kSecondaryColor,
                                    //       ),
                                    //       Padding(
                                    //         padding:
                                    //         const EdgeInsets.only(
                                    //             left: 10),
                                    //         child: Container(
                                    //           decoration:
                                    //           BoxDecoration(
                                    //             borderRadius:
                                    //             BorderRadius
                                    //                 .circular(10),
                                    //             color:
                                    //             Color(0xff161616),
                                    //           ),
                                    //           height: 25,
                                    //           width: MediaQuery.of(
                                    //               context)
                                    //               .size
                                    //               .width /
                                    //               8,
                                    //           //    color: kSecondaryColor,
                                    //         ),
                                    //       ),
                                    //       Padding(
                                    //         padding:
                                    //         const EdgeInsets.only(
                                    //             left: 10),
                                    //         child: Container(
                                    //           decoration:
                                    //           BoxDecoration(
                                    //             borderRadius:
                                    //             BorderRadius
                                    //                 .circular(8),
                                    //             color:
                                    //             Color(0xff161616),
                                    //           ),
                                    //           height: 20,
                                    //           width: MediaQuery.of(
                                    //               context)
                                    //               .size
                                    //               .width /
                                    //               8,
                                    //           //    color: kSecondaryColor,
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // )
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );

                  }

                }catch(e){
                  return SizedBox();
                }
              },
            ),
            FutureBuilder(future: getUsers(),builder: (context, snapshot){
              try{
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        "Podcasters for you",
                        textScaleFactor: 1.0,
                        style: TextStyle(
                          color: Colors.white,
                            fontSize:
                            SizeConfig.safeBlockHorizontal * 4,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      height:
                      MediaQuery.of(context).size.height / 5,
                      // child: ListView(
                      //   scrollDirection: Axis.horizontal,
                      //   children: [
                      //     for (var v in peopleRecommendation)
                      //       Padding(
                      //         padding: const EdgeInsets.all(10),
                      //         child: InkWell(
                      //           onTap: () {
                      //             Navigator.push(context,
                      //                 CupertinoPageRoute(
                      //                     builder: (context) {
                      //                       return PublicProfile(
                      //                         userId: v['id'],
                      //                       );
                      //                     }));
                      //           },
                      //           child: Column(
                      //             mainAxisSize: MainAxisSize.min,
                      //             children: [
                      //               CachedNetworkImage(
                      //                 imageBuilder:
                      //                     (context, imageProvider) {
                      //                   return Container(
                      //                     decoration: BoxDecoration(
                      //                       shape: BoxShape.circle,
                      //                       image: DecorationImage(
                      //                           image:
                      //                           imageProvider,
                      //                           fit: BoxFit.cover),
                      //                     ),
                      //                     width:
                      //                     MediaQuery.of(context)
                      //                         .size
                      //                         .width /
                      //                         4,
                      //                     height:
                      //                     MediaQuery.of(context)
                      //                         .size
                      //                         .width /
                      //                         4,
                      //                   );
                      //                 },
                      //                 imageUrl: v['img'],
                      //                 memCacheWidth:
                      //                 MediaQuery.of(context)
                      //                     .size
                      //                     .width
                      //                     .floor(),
                      //                 memCacheHeight:
                      //                 MediaQuery.of(context)
                      //                     .size
                      //                     .width
                      //                     .floor(),
                      //                 placeholder: (context, url) =>
                      //                     Container(
                      //                       width:
                      //                       MediaQuery.of(context)
                      //                           .size
                      //                           .width /
                      //                           7,
                      //                       height:
                      //                       MediaQuery.of(context)
                      //                           .size
                      //                           .width /
                      //                           7,
                      //                       child: Image.asset(
                      //                           'assets/images/Thumbnail.png'),
                      //                     ),
                      //                 errorWidget: (context, url,
                      //                     error) =>
                      //                     Container(
                      //                         width:
                      //                         MediaQuery.of(
                      //                             context)
                      //                             .size
                      //                             .width /
                      //                             4,
                      //                         height: MediaQuery.of(
                      //                             context)
                      //                             .size
                      //                             .width /
                      //                             4,
                      //                         child: Icon(
                      //                           Icons.error,
                      //                           color: Color(
                      //                               0xffe8e8e8),
                      //                         )),
                      //               ),
                      //               Padding(
                      //                 padding:
                      //                 const EdgeInsets.only(
                      //                     top: 10),
                      //                 child: Container(
                      //                   width:
                      //                   MediaQuery.of(context)
                      //                       .size
                      //                       .width /
                      //                       4,
                      //                   child: Text(
                      //                     "${v['username']}",
                      //                     textAlign:
                      //                     TextAlign.center,
                      //                     maxLines: 2,
                      //                     overflow:
                      //                     TextOverflow.ellipsis,
                      //                     style: TextStyle(
                      //                         color: Color(
                      //                             0xffe8e8e8)),
                      //                   ),
                      //                 ),
                      //               )
                      //             ],
                      //           ),
                      //         ),
                      //       )
                      //   ],
                      // ),
                      child: ListView.builder(scrollDirection: Axis.horizontal,itemCount: snapshot.data.length,itemBuilder: (context, int index){
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context,
                                  CupertinoPageRoute(
                                      builder: (context) {
                                        return PublicProfile(
                                          userId: snapshot.data[index]['id'],
                                        );
                                      }));
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CachedNetworkImage(
                                  imageBuilder:
                                      (context, imageProvider) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                            image:
                                            imageProvider,
                                            fit: BoxFit.cover),
                                      ),
                                      width:
                                      MediaQuery.of(context)
                                          .size
                                          .width /
                                          4,
                                      height:
                                      MediaQuery.of(context)
                                          .size
                                          .width /
                                          4,
                                    );
                                  },
                                  imageUrl: snapshot.data[index]['img'],
                                  memCacheWidth:
                                  MediaQuery.of(context)
                                      .size
                                      .width
                                      .floor(),
                                  memCacheHeight:
                                  MediaQuery.of(context)
                                      .size
                                      .width
                                      .floor(),
                                  placeholder: (context, url) =>
                                      Container(
                                        width:
                                        MediaQuery.of(context)
                                            .size
                                            .width /
                                            7,
                                        height:
                                        MediaQuery.of(context)
                                            .size
                                            .width /
                                            7,
                                        child: Image.asset(
                                            'assets/images/Thumbnail.png'),
                                      ),
                                  errorWidget: (context, url,
                                      error) =>
                                      Container(
                                          width:
                                          MediaQuery.of(
                                              context)
                                              .size
                                              .width /
                                              4,
                                          height: MediaQuery.of(
                                              context)
                                              .size
                                              .width /
                                              4,
                                          child: Icon(
                                            Icons.error,
                                            color: Color(
                                                0xffe8e8e8),
                                          )),
                                ),
                                Padding(
                                  padding:
                                  const EdgeInsets.only(
                                      top: 10),
                                  child: Container(
                                    width:
                                    MediaQuery.of(context)
                                        .size
                                        .width /
                                        4,
                                    child: Text(
                                      "${snapshot.data[index]['username']}",
                                      textAlign:
                                      TextAlign.center,
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Color(
                                              0xffe8e8e8)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              }catch(e){
                return Container();
              }

            }),
            FutureBuilder(
              future: getPlaylistSearch(),
              builder: (context, snapshot){
                return Container();
              },
            ),
            FutureBuilder(
              future: getSearchSnippets(),
              builder: (context, snapshot){
                return Container();
              },
            ),

          ],
        ),
      )
    );
  }

  MaterialColor primaryBlack = MaterialColor(
    0XFF000000,
    <int, Color>{
      50: Color(0xFF000000),
      100: Color(0xFF000000),
      200: Color(0xFF000000),
      300: Color(0xFF000000),
      400: Color(0xFF000000),
      500: Color(0XFF000000),
      600: Color(0xFF000000),
      700: Color(0xFF000000),
      800: Color(0xFF000000),
      900: Color(0xFF000000),
    },
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      primaryColor: Color(0xff161616),
      primarySwatch: primaryBlack,
      primaryIconTheme: IconThemeData(
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle:
            Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),
      ),
      textTheme: TextTheme(
        headline6: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  List _icons = [
    LineIcons.palette,
    LineIcons.briefcase,
    LineIcons.laughFaceWithBeamingEyes,
    LineIcons.fruitApple,
    LineIcons.cloudWithAChanceOfMeatball,
    LineIcons.businessTime,
    LineIcons.hourglass,
    LineIcons.swimmingPool,
    LineIcons.baby,
    LineIcons.beer,
    LineIcons.music,
    LineIcons.newspaper,
    LineIcons.twitter,
    LineIcons.atom,
    LineIcons.globe,
    LineIcons.footballBall,
    LineIcons.alternateGithub,
    LineIcons.dungeon,
    LineIcons.television
  ];

  Dio dio = Dio();
  // CancelToken _cancel = CancelToken();

  Future getCategories() async {
    String url = "https://api.aureal.one/public/getCategory";
    print(url);

    try{
      var response = await dio.get(url, cancelToken: _cancel);
      if(response.statusCode == 200){
        print(response.data);
        return response.data['allCategory'];
      }
    }catch(e){

    }

  }

  Future getSubCategories() async {
    String url = "https://api.aureal.one/public/getSubcategory";

    try{
      var response = await dio.get(url,cancelToken:  _cancel);
      if(response.statusCode == 200){
        return response.data['data'];
      }
    }catch(e){

    }

  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    // throw UnimplementedError();


    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height
      ),
      color: Colors.black,
      height: MediaQuery.of(context).size.height,
      child: ListView(
        shrinkWrap: true,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: SizeConfig.safeBlockHorizontal * 5),),),
              FutureBuilder(
                future: getCategories(),
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return Container(

                      child: GridView.builder(shrinkWrap: true,physics: NeverScrollableScrollPhysics(),itemCount: snapshot.data.length,gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          childAspectRatio: 4 / 1.3), itemBuilder: (context, int index){
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(left: BorderSide(width: 3,color: Colors.primaries[index])),
                                color: Color(0xff222222)
                            ),
                            child: Center(
                              child: ListTile(
                                onTap: (){
                                  Navigator.push(context, CupertinoPageRoute(builder: (context){
                                    return CategoryView(categoryObject: snapshot.data[index],);
                                  }));
                                },
                                title: Text("${snapshot.data[index]['name']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }else{
                    return Container(

                      child: GridView.builder(shrinkWrap: true,physics: NeverScrollableScrollPhysics(),itemCount: 18,gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          childAspectRatio: 4 / 1.3), itemBuilder: (context, int index){
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(left: BorderSide(width: 3,color: Colors.primaries[index])),
                                color: Color(0xff222222)
                            ),
                            child: Center(
                              child: ListTile(
                                onTap: (){
                                  // Navigator.push(context, CupertinoPageRoute(builder: (context){
                                  //   return CategoryView(categoryObject: snapshot.data[index],);
                                  // }));
                                },
                                title: Text("", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }

                },
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text("Sub Categories", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: SizeConfig.safeBlockHorizontal * 5),),),
              FutureBuilder(
                future: getSubCategories(),
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return Container(
                      child: GridView.builder(shrinkWrap: true,physics: NeverScrollableScrollPhysics(),itemCount: snapshot.data.length,gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          childAspectRatio: 4 / 1.3), itemBuilder: (context, int index){
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(left: BorderSide(width: 3,color: Colors.blue)),
                                color: Color(0xff222222)
                            ),
                            child: Center(
                              child: ListTile(
                                onTap: (){
                                  Navigator.push(context, CupertinoPageRoute(builder: (context){
                                    return SubCategoryView(data: snapshot.data[index],);
                                  }));
                                },
                                title: Text("${snapshot.data[index]['name']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }else{
                    return Container(
                      child: GridView.builder(shrinkWrap: true,physics: NeverScrollableScrollPhysics(),itemCount: 60,gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          childAspectRatio: 4 / 1.3), itemBuilder: (context, int index){
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(left: BorderSide(width: 3,color: Colors.blue)),
                                color: Color(0xff222222)
                            ),
                            child: Center(
                              child: ListTile(
                                onTap: (){
                                  // Navigator.push(context, CupertinoPageRoute(builder: (context){
                                  //   return SubCategoryView(data: snapshot.data[index],);
                                  // }));
                                },
                                title: Text("", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }
                },
              ),
            ],
          )
          ],

      ),
    );
  }
}


class ResultsSection extends StatefulWidget {
  String query;

  ResultsSection({@required this.query});

  @override
  _ResultsSectionState createState() => _ResultsSectionState();
}

class _ResultsSectionState extends State<ResultsSection>
    with TickerProviderStateMixin {
  TabController _controller;
  ScrollController _podcastScrollController;
  ScrollController _episodeScrollController;
  ScrollController _communityScrollController;
  ScrollController _roomScrollController;
  ScrollController _userScrollController;

  int podcastPageNumber = 1;
  int episodePageNumber = 1;
  int communityPageNumber = 1;
  List episodeResult = [];
  List podcastResult = [];
  List communityResult = [];
  bool isPodcastLoading = false;
  bool isEpisodeLoading = false;
  bool isCommunityLoading = false;

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

  void getMoreSearchEpisodes({String query}) async {
    setState(() {
      isEpisodeLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/search?user_id=${prefs.getString('userId')}&word=$query&page=$episodePageNumber";

    http.Response response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        episodeResult.addAll(jsonDecode(response.body)['EpisodeList']);
        episodeResult.toSet().toList();
        episodePageNumber = episodePageNumber + 1;
      });
    }
    setState(() {
      isEpisodeLoading = false;
    });
  }

  int userPage = 0;
  List userSearch = [];

  Dio dio = Dio();
  CancelToken cancelToken = CancelToken();

  void searchPeople({String query}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/userSearch?word=$query&loggedinuser=${prefs.getString('userId')}&page=$userPage";

    try {
      var response = await dio.get(url, cancelToken: cancelToken);
      print(response.data);
    } catch (e) {
      print(e);
    }
  }

  SharedPreferences prefs;

  void getLocalData() async {
    prefs = await SharedPreferences.getInstance();
    var search = Provider.of<SearchResultProvider>(context, listen: false);
    search.query = widget.query;
  }

  @override
  void initState() {
    var search = Provider.of<SearchResultProvider>(context, listen: false);
    getLocalData();
    // TODO: implement initState
    _controller = TabController(length: 5, vsync: this);
    _podcastScrollController = ScrollController();
    _episodeScrollController = ScrollController();
    _communityScrollController = ScrollController();
    _userScrollController = ScrollController();
    _roomScrollController = ScrollController();

    _podcastScrollController.addListener(() {
      if (_podcastScrollController.position.pixels ==
          _podcastScrollController.position.maxScrollExtent) {
        search.pagePodcast = search.pagePodcast + 1;
      }
    });

    _episodeScrollController.addListener(() {
      if (_episodeScrollController.position.pixels ==
          _episodeScrollController.position.maxScrollExtent) {
        search.pageEpisode = search.pageEpisode + 1;
      }
    });

    _roomScrollController.addListener(() {
      if (_roomScrollController.position.pixels ==
          _roomScrollController.position.maxScrollExtent) {
        search.pageRoom = search.pageRoom + 1;
      }
    });

    _userScrollController.addListener(() {
      if (_userScrollController.position.pixels ==
          _userScrollController.position.maxScrollExtent) {
        search.pagePeople = search.pagePeople + 1;
      }
    });

    _communityScrollController.addListener(() {
      if (_communityScrollController.position.pixels ==
          _communityScrollController.position.maxScrollExtent) {
        search.pageCommunity = search.pageCommunity + 1;
      }
    });

    super.initState();
  }

  RegExp htmlMatch = RegExp(r'(\w+)');

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    var search = Provider.of<SearchResultProvider>(context);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: TabBar(
            isScrollable: true,
            controller: _controller,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(
                text: "Top Results",
              ),
              Tab(
                text: "Podcast",
              ),
              Tab(
                text: "People",
              ),
              Tab(
                text: "Episodes",
              ),
              // Tab(
              //   text: "Communities",
              // ),
              Tab(
                text: 'Rooms',
              )
            ],
          ),
        ),
        body: ModalProgressHUD(
          color: Color(0xff161616),
          inAsyncCall: search.isLoading,
          child: search.isLoading == true
              ? Container()
              : TabBarView(
                  controller: _controller,
                  children: [
                    Container(
                      child: ListView(
                        children: [
                          search.podcastResult.length == 0
                              ? SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    color: Color(0xff161616),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15),
                                          child: Text(
                                            "Podcasts",
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    4,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              5,
                                          child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: [
                                              Builder(
                                                builder: (context) {
                                                  if (search.podcastResult
                                                          .length >=
                                                      7) {
                                                    return Row(children: [
                                                      for (int i = 0;
                                                          i < 7;
                                                          i++)
                                                        InkWell(
                                                          onTap: () {
                                                            Navigator.push(
                                                                context,
                                                                CupertinoPageRoute(
                                                                    builder:
                                                                        (context) {
                                                              return PodcastView(
                                                                  search.podcastResult[
                                                                      i]['id']);
                                                            }));
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                CachedNetworkImage(
                                                                  imageBuilder:
                                                                      (context,
                                                                          imageProvider) {
                                                                    return Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(10),
                                                                        image: DecorationImage(
                                                                            image:
                                                                                imageProvider,
                                                                            fit:
                                                                                BoxFit.cover),
                                                                      ),
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          4,
                                                                      height:
                                                                          MediaQuery.of(context).size.width /
                                                                              4,
                                                                    );
                                                                  },
                                                                  imageUrl: search
                                                                          .podcastResult[i]
                                                                      ['image'],
                                                                  memCacheWidth:
                                                                      MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width
                                                                          .floor(),
                                                                  memCacheHeight:
                                                                      MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width
                                                                          .floor(),
                                                                  placeholder: (context,
                                                                          url) =>
                                                                      Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        7,
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        7,
                                                                    child: Image
                                                                        .asset(
                                                                            'assets/images/Thumbnail.png'),
                                                                  ),
                                                                  errorWidget: (context,
                                                                          url,
                                                                          error) =>
                                                                      Container(
                                                                          width: MediaQuery.of(context).size.width /
                                                                              4,
                                                                          height: MediaQuery.of(context).size.width /
                                                                              4,
                                                                          child:
                                                                              Icon(
                                                                            Icons.error,
                                                                            color:
                                                                                Color(0xffe8e8e8),
                                                                          )),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      top: 10),
                                                                  child:
                                                                      Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        4,
                                                                    child: Text(
                                                                      "${search.podcastResult[i]['name']}",
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: TextStyle(
                                                                          color:
                                                                              Color(0xffe8e8e8)),
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                    ]);
                                                  } else {
                                                    return Row(
                                                      children: [
                                                        for (var v in search
                                                            .podcastResult)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10),
                                                            child: InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                    context,
                                                                    CupertinoPageRoute(
                                                                        builder:
                                                                            (context) {
                                                                  return PodcastView(
                                                                      v['id']);
                                                                }));
                                                              },
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  CachedNetworkImage(
                                                                    imageBuilder:
                                                                        (context,
                                                                            imageProvider) {
                                                                      return Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          borderRadius:
                                                                              BorderRadius.circular(10),
                                                                          image: DecorationImage(
                                                                              image: imageProvider,
                                                                              fit: BoxFit.cover),
                                                                        ),
                                                                        width:
                                                                            MediaQuery.of(context).size.width /
                                                                                4,
                                                                        height:
                                                                            MediaQuery.of(context).size.width /
                                                                                4,
                                                                      );
                                                                    },
                                                                    imageUrl: v[
                                                                        'image'],
                                                                    memCacheWidth: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width
                                                                        .floor(),
                                                                    memCacheHeight: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width
                                                                        .floor(),
                                                                    placeholder:
                                                                        (context,
                                                                                url) =>
                                                                            Container(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          7,
                                                                      height:
                                                                          MediaQuery.of(context).size.width /
                                                                              7,
                                                                      child: Image
                                                                          .asset(
                                                                              'assets/images/Thumbnail.png'),
                                                                    ),
                                                                    errorWidget: (context,
                                                                            url,
                                                                            error) =>
                                                                        Container(
                                                                            width: MediaQuery.of(context).size.width /
                                                                                4,
                                                                            height: MediaQuery.of(context).size.width /
                                                                                4,
                                                                            child:
                                                                                Icon(
                                                                              Icons.error,
                                                                              color: Color(0xffe8e8e8),
                                                                            )),
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        top:
                                                                            10),
                                                                    child:
                                                                        Container(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          4,
                                                                      child:
                                                                          Text(
                                                                        "${v['name']}",
                                                                        maxLines:
                                                                            2,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: TextStyle(
                                                                            color:
                                                                                Color(0xffe8e8e8)),
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          color: Color(0xffe8e8e8),
                                        ),
                                        ListTile(
                                          onTap: () {
                                            _controller.index = 1;
                                          },
                                          leading: Text(
                                            "See All",
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward,
                                            color: Color(0xffe8e8e8),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                          search.episodeResult.length == 0
                              ? SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    color: Color(0xff161616),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15),
                                          child: Text(
                                            "Episode",
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    4,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Builder(builder: (context) {
                                          try {
                                            if (search.episodeResult.length >=
                                                7) {
                                              return Column(
                                                children: [
                                                  for (int i = 0; i < 5; i++)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 10,
                                                          vertical: 10),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          InkWell(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  CupertinoPageRoute(
                                                                      builder:
                                                                          (context) {
                                                                return EpisodeView(
                                                                    episodeId: search
                                                                            .episodeResult[i]
                                                                        ['id']);
                                                              }));
                                                            },
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                boxShadow: [
                                                                  new BoxShadow(
                                                                    color: Colors
                                                                        .black54
                                                                        .withOpacity(
                                                                            0.2),
                                                                    blurRadius:
                                                                        10.0,
                                                                  ),
                                                                ],
                                                                color: Color(
                                                                    0xff222222),
                                                                // color: themeProvider.isLightTheme == true
                                                                //     ? Colors.white
                                                                //     : Color(0xff222222),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              width: double
                                                                  .infinity,
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        20,
                                                                    horizontal:
                                                                        20),
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        CachedNetworkImage(
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: BorderRadius.circular(10),
                                                                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                                                              ),
                                                                              width: MediaQuery.of(context).size.width / 7,
                                                                              height: MediaQuery.of(context).size.width / 7,
                                                                            );
                                                                          },
                                                                          imageUrl:
                                                                              search.episodeResult[i]['image'],
                                                                          memCacheWidth: MediaQuery.of(context)
                                                                              .size
                                                                              .width
                                                                              .floor(),
                                                                          memCacheHeight: MediaQuery.of(context)
                                                                              .size
                                                                              .width
                                                                              .floor(),
                                                                          placeholder: (context, url) =>
                                                                              Container(
                                                                            width:
                                                                                MediaQuery.of(context).size.width / 7,
                                                                            height:
                                                                                MediaQuery.of(context).size.width / 7,
                                                                            child:
                                                                                Image.asset('assets/images/Thumbnail.png'),
                                                                          ),
                                                                          errorWidget: (context, url, error) =>
                                                                              Icon(Icons.error),
                                                                        ),
                                                                        SizedBox(
                                                                            width:
                                                                                SizeConfig.screenWidth / 26),
                                                                        Expanded(
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              GestureDetector(
                                                                                onTap: () {
                                                                                  Navigator.push(context, CupertinoPageRoute(builder: (context) => PodcastView(search.episodeResult[i]['podcast_id'])));
                                                                                },
                                                                                child: Text(
                                                                                  '${search.episodeResult[i]['podcast_name']}',
                                                                                  textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.1, 1.2).toDouble(),
                                                                                  style: TextStyle(color: Color(0xffe8e8e8), fontSize: SizeConfig.safeBlockHorizontal * 5, fontWeight: FontWeight.normal),
                                                                                ),
                                                                              ),
                                                                              // Text(
                                                                              //   '${timeago.format(DateTime.parse(v['published_at']))}',
                                                                              //   textScaleFactor: mediaQueryData
                                                                              //       .textScaleFactor
                                                                              //       .clamp(
                                                                              //       0.5,
                                                                              //       0.9)
                                                                              //       .toDouble(),
                                                                              //   style: TextStyle(
                                                                              //     // color: Color(
                                                                              //     //     0xffe8e8e8),
                                                                              //       fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                                              // ),
                                                                            ],
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .symmetric(
                                                                          vertical:
                                                                              10),
                                                                      child:
                                                                          Container(
                                                                        width: double
                                                                            .infinity,
                                                                        child:
                                                                            Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              search.episodeResult[i]['name'],
                                                                              textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                              style: TextStyle(color: Color(0xffe8e8e8), fontSize: SizeConfig.safeBlockHorizontal * 4.5, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                                                              child: search.episodeResult[i]['summary'] == null
                                                                                  ? SizedBox(width: 0, height: 0)
                                                                                  : (htmlMatch.hasMatch(search.episodeResult[i]['summary']) == true
                                                                                      ? Text(
                                                                                          parse(search.episodeResult[i]['summary']).body.text,
                                                                                          textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                                          maxLines: 2,
                                                                                          style: TextStyle(color: Color(0xffe8e8e8).withOpacity(0.5), fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                                        )
                                                                                      : Text(
                                                                                          '${search.episodeResult[i]['summary']}',
                                                                                          textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                                          style: TextStyle(color: Color(0xffe8e8e8).withOpacity(0.5), fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                                        )),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              search.episodeResult[i]['permlink'] == null
                                                                                  ? SizedBox()
                                                                                  : InkWell(
                                                                                      onTap: () async {
                                                                                        if (prefs.getString('HiveUserName') != null) {
                                                                                          setState(() {
                                                                                            search.episodeResult[i]['isLoading'] = true;
                                                                                          });
                                                                                          double _value = 50.0;
                                                                                          showDialog(
                                                                                              context: context,
                                                                                              builder: (context) {
                                                                                                return Dialog(backgroundColor: Colors.transparent, child: UpvoteEpisode(permlink: search.episodeResult[i]['permlink'], episode_id: search.episodeResult[i]['id']));
                                                                                              }).then((value) async {
                                                                                            print(value);
                                                                                          });
                                                                                          setState(() {
                                                                                            search.episodeResult[i]['ifVoted'] = !search.episodeResult[i]['ifVoted'];
                                                                                          });
                                                                                          setState(() {
                                                                                            search.episodeResult[i]['isLoading'] = false;
                                                                                          });
                                                                                        } else {
                                                                                          showBarModalBottomSheet(
                                                                                              context: context,
                                                                                              builder: (context) {
                                                                                                return HiveDetails();
                                                                                              });
                                                                                        }
                                                                                      },
                                                                                      child: Container(
                                                                                        decoration: search.episodeResult[i]['ifVoted'] == true ? BoxDecoration(gradient: LinearGradient(colors: [Color(0xff5bc3ef), Color(0xff5d5da8)]), borderRadius: BorderRadius.circular(30)) : BoxDecoration(border: Border.all(color: kSecondaryColor), borderRadius: BorderRadius.circular(30)),
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                                                                          child: Row(
                                                                                            children: [
                                                                                              search.episodeResult[i]['isLoading'] == true
                                                                                                  ? Container(
                                                                                                      height: 17,
                                                                                                      width: 18,
                                                                                                      child: SpinKitPulse(
                                                                                                        color: Colors.blue,
                                                                                                      ),
                                                                                                    )
                                                                                                  : Icon(
                                                                                                      FontAwesomeIcons.chevronCircleUp,
                                                                                                      size: 15,
                                                                                                      color: Color(0xffe8e8e8),
                                                                                                    ),
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                                                child: Text(
                                                                                                  search.episodeResult[i]['votes'].toString(),
                                                                                                  textScaleFactor: 1.0,
                                                                                                  style: TextStyle(
                                                                                                    fontSize: 12,
                                                                                                    color: Color(0xffe8e8e8),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.only(right: 4),
                                                                                                child: Text(
                                                                                                  '\$${search.episodeResult[i]['payout_value'].toString().split(' ')[0]}',
                                                                                                  textScaleFactor: 1.0,
                                                                                                  style: TextStyle(fontSize: 12, color: Color(0xffe8e8e8)),
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                              search.episodeResult[i]['permlink'] == null
                                                                                  ? SizedBox()
                                                                                  : InkWell(
                                                                                      onTap: () {
                                                                                        if (prefs.getString('HiveUserName') != null) {
                                                                                          Navigator.push(
                                                                                              context,
                                                                                              CupertinoPageRoute(
                                                                                                  builder: (context) => Comments(
                                                                                                        episodeObject: search.episodeResult[i],
                                                                                                      )));
                                                                                        } else {
                                                                                          showBarModalBottomSheet(
                                                                                              context: context,
                                                                                              builder: (context) {
                                                                                                return HiveDetails();
                                                                                              });
                                                                                        }
                                                                                      },
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.all(8.0),
                                                                                        child: Container(
                                                                                          decoration: BoxDecoration(border: Border.all(color: kSecondaryColor), borderRadius: BorderRadius.circular(30)),
                                                                                          child: Padding(
                                                                                            padding: const EdgeInsets.all(4.0),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                Icon(
                                                                                                  Icons.mode_comment_outlined,
                                                                                                  size: 14,
                                                                                                  color: Color(0xffe8e8e8),
                                                                                                ),
                                                                                                Padding(
                                                                                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                                                                                  child: Text(
                                                                                                    search.episodeResult[i]['comments_count'].toString(),
                                                                                                    textScaleFactor: 1.0,
                                                                                                    style: TextStyle(fontSize: 10, color: Color(0xffe8e8e8)),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  // print(v
                                                                                  //     .toString()
                                                                                  //     .contains('.mp4'));
                                                                                  // if (v
                                                                                  //             .toString()
                                                                                  //             .contains('.mp4') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.m4v') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.flv') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.f4v') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.ogv') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.ogx') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.wmv') ==
                                                                                  //         true ||
                                                                                  //     v.toString().contains(
                                                                                  //             '.webm') ==
                                                                                  //         true) {
                                                                                  //   currentlyPlaying.stop();
                                                                                  //   Navigator.push(context,
                                                                                  //       CupertinoPageRoute(
                                                                                  //           builder: (context) {
                                                                                  //     return PodcastVideoPlayer(
                                                                                  //         episodeObject: v);
                                                                                  //   }));
                                                                                  // } else {
                                                                                  //   if (v
                                                                                  //           .toString()
                                                                                  //           .contains('.pdf') ==
                                                                                  //       true) {
                                                                                  //     // Navigator.push(
                                                                                  //     //     context,
                                                                                  //     //     CupertinoPageRoute(
                                                                                  //     // der:
                                                                                  //     //             (context) {
                                                                                  //     //   return PDFviewer(
                                                                                  //     //       episodeObject:
                                                                                  //     //           v);
                                                                                  //     // }));
                                                                                  //   } else {
                                                                                  //     currentlyPlaying.stop();
                                                                                  //     currentlyPlaying
                                                                                  //         .episodeObject = v;
                                                                                  //     print(currentlyPlaying
                                                                                  //         .episodeObject
                                                                                  //         .toString());
                                                                                  //     currentlyPlaying.play();
                                                                                  //     Navigator.push(context,
                                                                                  //         CupertinoPageRoute(
                                                                                  //             builder: (context) {
                                                                                  //       return Player();
                                                                                  //     }));
                                                                                  //   }
                                                                                  // }
                                                                                },
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.only(right: 60),
                                                                                  child: Container(
                                                                                    decoration: BoxDecoration(border: Border.all(color: kSecondaryColor), borderRadius: BorderRadius.circular(30)),
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsets.all(5),
                                                                                      child: Row(
                                                                                        children: [
                                                                                          Icon(
                                                                                            Icons.play_circle_outline,
                                                                                            size: 15,
                                                                                            color: Color(0xffe8e8e8),
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                                            child: Text(
                                                                                              DurationCalculator(search.episodeResult[i]['duration']),
                                                                                              textScaleFactor: 0.75,
                                                                                              style: TextStyle(color: Color(0xffe8e8e8)),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              // share(episodeObject: v);
                                                                            },
                                                                            child:
                                                                                Icon(
                                                                              Icons.ios_share,
                                                                              // size: 14,
                                                                              color: Color(0xffe8e8e8),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              );
                                            } else {
                                              return Column(
                                                children: [
                                                  for (var v
                                                      in search.episodeResult)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 10,
                                                          vertical: 10),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          InkWell(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  CupertinoPageRoute(
                                                                      builder:
                                                                          (context) {
                                                                return EpisodeView(
                                                                  episodeId:
                                                                      v['id'],
                                                                );
                                                              }));
                                                            },
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                boxShadow: [
                                                                  new BoxShadow(
                                                                    color: Colors
                                                                        .black54
                                                                        .withOpacity(
                                                                            0.2),
                                                                    blurRadius:
                                                                        10.0,
                                                                  ),
                                                                ],
                                                                color: Color(
                                                                    0xff222222),
                                                                // color: themeProvider.isLightTheme == true
                                                                //     ? Colors.white
                                                                //     : Color(0xff222222),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              width: double
                                                                  .infinity,
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        20,
                                                                    horizontal:
                                                                        20),
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        CachedNetworkImage(
                                                                          imageBuilder:
                                                                              (context, imageProvider) {
                                                                            return Container(
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: BorderRadius.circular(10),
                                                                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                                                              ),
                                                                              width: MediaQuery.of(context).size.width / 7,
                                                                              height: MediaQuery.of(context).size.width / 7,
                                                                            );
                                                                          },
                                                                          imageUrl:
                                                                              v['image'],
                                                                          memCacheWidth: MediaQuery.of(context)
                                                                              .size
                                                                              .width
                                                                              .floor(),
                                                                          memCacheHeight: MediaQuery.of(context)
                                                                              .size
                                                                              .width
                                                                              .floor(),
                                                                          placeholder: (context, url) =>
                                                                              Container(
                                                                            width:
                                                                                MediaQuery.of(context).size.width / 7,
                                                                            height:
                                                                                MediaQuery.of(context).size.width / 7,
                                                                            child:
                                                                                Image.asset('assets/images/Thumbnail.png'),
                                                                          ),
                                                                          errorWidget: (context, url, error) =>
                                                                              Icon(Icons.error),
                                                                        ),
                                                                        SizedBox(
                                                                            width:
                                                                                SizeConfig.screenWidth / 26),
                                                                        Expanded(
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              GestureDetector(
                                                                                onTap: () {
                                                                                  Navigator.push(context, CupertinoPageRoute(builder: (context) => PodcastView(v['podcast_id'])));
                                                                                },
                                                                                child: Text(
                                                                                  '${v['podcast_name']}',
                                                                                  textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.1, 1.2).toDouble(),
                                                                                  style: TextStyle(color: Color(0xffe8e8e8), fontSize: SizeConfig.safeBlockHorizontal * 5, fontWeight: FontWeight.normal),
                                                                                ),
                                                                              ),
                                                                              // Text(
                                                                              //   '${timeago.format(DateTime.parse(v['published_at']))}',
                                                                              //   textScaleFactor: mediaQueryData
                                                                              //       .textScaleFactor
                                                                              //       .clamp(
                                                                              //       0.5,
                                                                              //       0.9)
                                                                              //       .toDouble(),
                                                                              //   style: TextStyle(
                                                                              //     // color: Color(
                                                                              //     //     0xffe8e8e8),
                                                                              //       fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                                              // ),
                                                                            ],
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .symmetric(
                                                                          vertical:
                                                                              10),
                                                                      child:
                                                                          Container(
                                                                        width: double
                                                                            .infinity,
                                                                        child:
                                                                            Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              v['name'],
                                                                              textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                              style: TextStyle(color: Color(0xffe8e8e8), fontSize: SizeConfig.safeBlockHorizontal * 4.5, fontWeight: FontWeight.bold),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                                                              child: v['summary'] == null
                                                                                  ? SizedBox(width: 0, height: 0)
                                                                                  : (htmlMatch.hasMatch(v['summary']) == true
                                                                                      ? Text(
                                                                                          parse(v['summary']).body.text,
                                                                                          textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                                          maxLines: 2,
                                                                                          style: TextStyle(color: Color(0xffe8e8e8).withOpacity(0.5), fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                                        )
                                                                                      : Text(
                                                                                          '${v['summary']}',
                                                                                          textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                                                                          style: TextStyle(color: Color(0xffe8e8e8).withOpacity(0.5), fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                                        )),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              v['permlink'] == null
                                                                                  ? SizedBox()
                                                                                  : InkWell(
                                                                                      onTap: () async {
                                                                                        if (prefs.getString('HiveUserName') != null) {
                                                                                          setState(() {
                                                                                            v['isLoading'] = true;
                                                                                          });
                                                                                          double _value = 50.0;
                                                                                          showDialog(
                                                                                              context: context,
                                                                                              builder: (context) {
                                                                                                return Dialog(backgroundColor: Colors.transparent, child: UpvoteEpisode(permlink: v['permlink'], episode_id: v['id']));
                                                                                              }).then((value) async {
                                                                                            print(value);
                                                                                          });
                                                                                          setState(() {
                                                                                            v['ifVoted'] = !v['ifVoted'];
                                                                                          });
                                                                                          setState(() {
                                                                                            v['isLoading'] = false;
                                                                                          });
                                                                                        } else {
                                                                                          showBarModalBottomSheet(
                                                                                              context: context,
                                                                                              builder: (context) {
                                                                                                return HiveDetails();
                                                                                              });
                                                                                        }
                                                                                      },
                                                                                      child: Container(
                                                                                        decoration: v['ifVoted'] == true ? BoxDecoration(gradient: LinearGradient(colors: [Color(0xff5bc3ef), Color(0xff5d5da8)]), borderRadius: BorderRadius.circular(30)) : BoxDecoration(border: Border.all(color: kSecondaryColor), borderRadius: BorderRadius.circular(30)),
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                                                                          child: Row(
                                                                                            children: [
                                                                                              v['isLoading'] == true
                                                                                                  ? Container(
                                                                                                      height: 17,
                                                                                                      width: 18,
                                                                                                      child: SpinKitPulse(
                                                                                                        color: Colors.blue,
                                                                                                      ),
                                                                                                    )
                                                                                                  : Icon(
                                                                                                      FontAwesomeIcons.chevronCircleUp,
                                                                                                      size: 15,
                                                                                                      color: Color(0xffe8e8e8),
                                                                                                    ),
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                                                child: Text(
                                                                                                  v['votes'].toString(),
                                                                                                  textScaleFactor: 1.0,
                                                                                                  style: TextStyle(
                                                                                                    fontSize: 12,
                                                                                                    color: Color(0xffe8e8e8),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              Padding(
                                                                                                padding: const EdgeInsets.only(right: 4),
                                                                                                child: Text(
                                                                                                  '\$${v['payout_value'].toString().split(' ')[0]}',
                                                                                                  textScaleFactor: 1.0,
                                                                                                  style: TextStyle(fontSize: 12, color: Color(0xffe8e8e8)),
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                              v['permlink'] == null
                                                                                  ? SizedBox()
                                                                                  : InkWell(
                                                                                      onTap: () {
                                                                                        if (prefs.getString('HiveUserName') != null) {
                                                                                          Navigator.push(
                                                                                              context,
                                                                                              CupertinoPageRoute(
                                                                                                  builder: (context) => Comments(
                                                                                                        episodeObject: v,
                                                                                                      )));
                                                                                        } else {
                                                                                          showBarModalBottomSheet(
                                                                                              context: context,
                                                                                              builder: (context) {
                                                                                                return HiveDetails();
                                                                                              });
                                                                                        }
                                                                                      },
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.all(8.0),
                                                                                        child: Container(
                                                                                          decoration: BoxDecoration(border: Border.all(color: kSecondaryColor), borderRadius: BorderRadius.circular(30)),
                                                                                          child: Padding(
                                                                                            padding: const EdgeInsets.all(4.0),
                                                                                            child: Row(
                                                                                              children: [
                                                                                                Icon(
                                                                                                  Icons.mode_comment_outlined,
                                                                                                  size: 14,
                                                                                                  color: Color(0xffe8e8e8),
                                                                                                ),
                                                                                                Padding(
                                                                                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                                                                                  child: Text(
                                                                                                    v['comments_count'].toString(),
                                                                                                    textScaleFactor: 1.0,
                                                                                                    style: TextStyle(fontSize: 10, color: Color(0xffe8e8e8)),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  // print(v
                                                                                  //     .toString()
                                                                                  //     .contains('.mp4'));
                                                                                  // if (v
                                                                                  //             .toString()
                                                                                  //             .contains('.mp4') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.m4v') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.flv') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.f4v') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.ogv') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.ogx') ==
                                                                                  //         true ||
                                                                                  //     v
                                                                                  //             .toString()
                                                                                  //             .contains('.wmv') ==
                                                                                  //         true ||
                                                                                  //     v.toString().contains(
                                                                                  //             '.webm') ==
                                                                                  //         true) {
                                                                                  //   currentlyPlaying.stop();
                                                                                  //   Navigator.push(context,
                                                                                  //       CupertinoPageRoute(
                                                                                  //           builder: (context) {
                                                                                  //     return PodcastVideoPlayer(
                                                                                  //         episodeObject: v);
                                                                                  //   }));
                                                                                  // } else {
                                                                                  //   if (v
                                                                                  //           .toString()
                                                                                  //           .contains('.pdf') ==
                                                                                  //       true) {
                                                                                  //     // Navigator.push(
                                                                                  //     //     context,
                                                                                  //     //     CupertinoPageRoute(
                                                                                  //     // der:
                                                                                  //     //             (context) {
                                                                                  //     //   return PDFviewer(
                                                                                  //     //       episodeObject:
                                                                                  //     //           v);
                                                                                  //     // }));
                                                                                  //   } else {
                                                                                  //     currentlyPlaying.stop();
                                                                                  //     currentlyPlaying
                                                                                  //         .episodeObject = v;
                                                                                  //     print(currentlyPlaying
                                                                                  //         .episodeObject
                                                                                  //         .toString());
                                                                                  //     currentlyPlaying.play();
                                                                                  //     Navigator.push(context,
                                                                                  //         CupertinoPageRoute(
                                                                                  //             builder: (context) {
                                                                                  //       return Player();
                                                                                  //     }));
                                                                                  //   }
                                                                                  // }
                                                                                },
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.only(right: 60),
                                                                                  child: Container(
                                                                                    decoration: BoxDecoration(border: Border.all(color: kSecondaryColor), borderRadius: BorderRadius.circular(30)),
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsets.all(5),
                                                                                      child: Row(
                                                                                        children: [
                                                                                          Icon(
                                                                                            Icons.play_circle_outline,
                                                                                            size: 15,
                                                                                            color: Color(0xffe8e8e8),
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                                            child: Text(
                                                                                              DurationCalculator(v['duration']),
                                                                                              textScaleFactor: 0.75,
                                                                                              style: TextStyle(color: Color(0xffe8e8e8)),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              // share(episodeObject: v);
                                                                            },
                                                                            child:
                                                                                Icon(
                                                                              Icons.ios_share,
                                                                              // size: 14,
                                                                              color: Color(0xffe8e8e8),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              );
                                            }
                                          } catch (e) {
                                            return SizedBox();
                                          }
                                        }),
                                        Divider(
                                          color: Color(0xffe8e8e8),
                                        ),
                                        ListTile(
                                          onTap: () {
                                            _controller.index = 3;
                                          },
                                          leading: Text(
                                            "See All",
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward,
                                            color: Color(0xffe8e8e8),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                          search.peopleResult.length == 0
                              ? SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    color: Color(0xff161616),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15),
                                          child: Text(
                                            "People",
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    4,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              5,
                                          child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: [
                                              for (var v in search.peopleResult)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.push(context,
                                                          CupertinoPageRoute(
                                                              builder:
                                                                  (context) {
                                                        return PublicProfile(
                                                          userId: v['id'],
                                                        );
                                                      }));
                                                    },
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        CachedNetworkImage(
                                                          imageBuilder: (context,
                                                              imageProvider) {
                                                            return Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                image: DecorationImage(
                                                                    image:
                                                                        imageProvider,
                                                                    fit: BoxFit
                                                                        .cover),
                                                              ),
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
                                                            );
                                                          },
                                                          imageUrl: v['img'],
                                                          memCacheWidth:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width
                                                                  .floor(),
                                                          memCacheHeight:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width
                                                                  .floor(),
                                                          placeholder:
                                                              (context, url) =>
                                                                  Container(
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
                                                            child: Image.asset(
                                                                'assets/images/Thumbnail.png'),
                                                          ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Container(
                                                                  width: MediaQuery.of(context)
                                                                          .size
                                                                          .width /
                                                                      4,
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width /
                                                                      4,
                                                                  child: Icon(
                                                                    Icons.error,
                                                                    color: Color(
                                                                        0xffe8e8e8),
                                                                  )),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 10),
                                                          child: Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                4,
                                                            child: Text(
                                                              "${v['username']}",
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0xffe8e8e8)),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          color: Color(0xffe8e8e8),
                                        ),
                                        ListTile(
                                          onTap: () {
                                            _controller.index = 2;
                                          },
                                          leading: Text(
                                            "See All",
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward,
                                            color: Color(0xffe8e8e8),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                          search.communityResult.length == 0
                              ? SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    color: Color(0xff161616),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15),
                                          child: Text(
                                            "Communities",
                                            textScaleFactor: 1.0,
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8),
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    4,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              5,
                                          child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: [
                                              for (var v
                                                  in search.communityResult)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color:
                                                            Color(0xff222222)),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      child: Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.6,
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            CachedNetworkImage(
                                                              imageBuilder:
                                                                  (context,
                                                                      imageProvider) {
                                                                return Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(5),
                                                                    image: DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover),
                                                                  ),
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width /
                                                                      6,
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width /
                                                                      6,
                                                                );
                                                              },
                                                              imageUrl: v['profileImageUrl'] ==
                                                                      null
                                                                  ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                                  : v['profileImageUrl'],
                                                              memCacheWidth:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width
                                                                      .floor(),
                                                              memCacheHeight:
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width
                                                                      .floor(),
                                                              placeholder:
                                                                  (context,
                                                                          url) =>
                                                                      Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    6,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    6,
                                                                child: Image.asset(
                                                                    'assets/images/Thumbnail.png'),
                                                              ),
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  Container(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          4,
                                                                      height:
                                                                          MediaQuery.of(context).size.width /
                                                                              4,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .error,
                                                                        color: Color(
                                                                            0xffe8e8e8),
                                                                      )),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top:
                                                                            10),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Text(
                                                                      "${v['name']}",
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: TextStyle(
                                                                          color:
                                                                              Color(0xffe8e8e8)),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            5),
                                                                    Text(
                                                                      "${v['description']}",
                                                                      maxLines:
                                                                          2,
                                                                      style: TextStyle(
                                                                          color:
                                                                              Color(0xffe8e8e8).withOpacity(0.5)),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          color: Color(0xffe8e8e8),
                                        ),
                                        ListTile(
                                          onTap: () {
                                            _controller.index = 4;
                                          },
                                          leading: Text(
                                            "See All",
                                            style: TextStyle(
                                                color: Color(0xffe8e8e8)),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward,
                                            color: Color(0xffe8e8e8),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    search.podcastResult.length == 0
                        ? Container(
                            child: Center(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    FontAwesomeIcons.ghost,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "WOW! Such Empty",
                                  style: TextStyle(color: Color(0xffe8e8e8)),
                                )
                              ],
                            )),
                          )
                        : Container(
                            height: MediaQuery.of(context).size.height,
                            child: ListView(
                              controller: _podcastScrollController,
                              shrinkWrap: true,
                              children: [
                                for (var v in search.podcastResult)
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(context,
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return PodcastView(v['id']);
                                        }));
                                      },
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          CachedNetworkImage(
                                            errorWidget: (context, url,
                                                    error) =>
                                                Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            6,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            6,
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Color(0xffe8e8e8),
                                                    )),
                                            placeholder: (context, url) {
                                              return Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                decoration: BoxDecoration(
                                                  color: Color(0xff222222),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                              );
                                            },
                                            imageUrl: v['image'],
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    6,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    image: DecorationImage(
                                                        image: imageProvider,
                                                        fit: BoxFit.cover)),
                                              );
                                            },
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${v['name']}",
                                                    textScaleFactor: 1.0,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xffe8e8e8),
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3.5,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    "${v['author']}",
                                                    textScaleFactor: 1.0,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        color: Color(0xffe8e8e8)
                                                            .withOpacity(0.5),
                                                        fontSize: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                    search.peopleResult.length == 0
                        ? Container(
                            child: Center(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    FontAwesomeIcons.ghost,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "WOW! Such Empty",
                                  style: TextStyle(color: Color(0xffe8e8e8)),
                                )
                              ],
                            )),
                          )
                        : Container(
                            height: MediaQuery.of(context).size.height,
                            child: ListView(
                              controller: _userScrollController,
                              shrinkWrap: true,
                              children: [
                                for (var v in search.peopleResult)
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(context,
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return PublicProfile(
                                            userId: v['id'],
                                          );
                                        }));
                                      },
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CachedNetworkImage(
                                                  imageUrl: v['img'] == null
                                                      ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                      : v['img'],
                                                  imageBuilder:
                                                      (context, imageProvider) {
                                                    return Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          image: DecorationImage(
                                                              image:
                                                                  imageProvider,
                                                              fit: BoxFit
                                                                  .cover)),
                                                    );
                                                  },
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            15),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "${v['username']}",
                                                          textScaleFactor: 1.0,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xffe8e8e8),
                                                              fontSize: SizeConfig
                                                                      .safeBlockHorizontal *
                                                                  3.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        v['fullname'] == null
                                                            ? SizedBox()
                                                            : Text(
                                                                "${v['fullname']}",
                                                                textScaleFactor:
                                                                    1.0,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                    color: Color(
                                                                            0xffe8e8e8)
                                                                        .withOpacity(
                                                                            0.5),
                                                                    fontSize:
                                                                        SizeConfig.safeBlockHorizontal *
                                                                            3),
                                                              )
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              followUser(authorUserId: v['id']);
                                              setState(() {
                                                v['ifFollowsAuthor'] =
                                                    !v['ifFollowsAuthor'];
                                              });
                                            },
                                            icon: v['ifFollowsAuthor'] == true
                                                ? Icon(
                                                    Icons.verified_user,
                                                    color: Color(0xffe8e8e8),
                                                  )
                                                : Icon(
                                                    Icons.person_add,
                                                    color: Color(0xffe8e8e8),
                                                  ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                    //podcast
                    search.episodeResult.length == 0
                        ? Container(
                            child: Center(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    FontAwesomeIcons.ghost,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "WOW! Such Empty",
                                  style: TextStyle(color: Color(0xffe8e8e8)),
                                )
                              ],
                            )),
                          )
                        : Container(
                            height: MediaQuery.of(context).size.height,
                            child: ListView(
                              controller: _episodeScrollController,
                              shrinkWrap: true,
                              children: [
                                for (var v in search.episodeResult)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(context,
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return EpisodeView(
                                            episodeId: v['id'],
                                          );
                                        }));
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                new BoxShadow(
                                                  color: Colors.black54
                                                      .withOpacity(0.2),
                                                  blurRadius: 10.0,
                                                ),
                                              ],
                                              color: Color(0xff161616),
                                              // color: themeProvider.isLightTheme == true
                                              //     ? Colors.white
                                              //     : Color(0xff222222),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            width: double.infinity,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20,
                                                      horizontal: 20),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CachedNetworkImage(
                                                        imageBuilder: (context,
                                                            imageProvider) {
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              image: DecorationImage(
                                                                  image:
                                                                      imageProvider,
                                                                  fit: BoxFit
                                                                      .cover),
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
                                                        imageUrl: v['image'],
                                                        memCacheWidth:
                                                            MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width
                                                                .floor(),
                                                        memCacheHeight:
                                                            MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width
                                                                .floor(),
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
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
                                                          child: Image.asset(
                                                              'assets/images/Thumbnail.png'),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(Icons.error),
                                                      ),
                                                      SizedBox(
                                                          width: SizeConfig
                                                                  .screenWidth /
                                                              26),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () {
                                                                Navigator.push(
                                                                    context,
                                                                    CupertinoPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                PodcastView(v['podcast_id'])));
                                                              },
                                                              child: Text(
                                                                '${v['podcast_name']}',
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textScaleFactor:
                                                                    mediaQueryData
                                                                        .textScaleFactor
                                                                        .clamp(
                                                                            0.1,
                                                                            1.2)
                                                                        .toDouble(),
                                                                style: TextStyle(
                                                                    color: Color(
                                                                        0xffe8e8e8),
                                                                    fontSize:
                                                                        SizeConfig.safeBlockHorizontal *
                                                                            5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal),
                                                              ),
                                                            ),
                                                            // Text(
                                                            //   '${timeago.format(DateTime.parse(v['published_at']))}',
                                                            //   textScaleFactor: mediaQueryData
                                                            //       .textScaleFactor
                                                            //       .clamp(
                                                            //       0.5,
                                                            //       0.9)
                                                            //       .toDouble(),
                                                            //   style: TextStyle(
                                                            //     // color: Color(
                                                            //     //     0xffe8e8e8),
                                                            //       fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                                                            // ),
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 10),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            v['name'],
                                                            textScaleFactor:
                                                                mediaQueryData
                                                                    .textScaleFactor
                                                                    .clamp(
                                                                        0.5, 1)
                                                                    .toDouble(),
                                                            style: TextStyle(
                                                                color: Color(
                                                                    0xffe8e8e8),
                                                                fontSize: SizeConfig
                                                                        .safeBlockHorizontal *
                                                                    4.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    vertical:
                                                                        10),
                                                            child: v['summary'] ==
                                                                    null
                                                                ? SizedBox(
                                                                    width: 0,
                                                                    height: 0)
                                                                : (htmlMatch.hasMatch(
                                                                            v['summary']) ==
                                                                        true
                                                                    ? Text(
                                                                        parse(v['summary'])
                                                                            .body
                                                                            .text,
                                                                        textScaleFactor: mediaQueryData
                                                                            .textScaleFactor
                                                                            .clamp(0.5,
                                                                                1)
                                                                            .toDouble(),
                                                                        maxLines:
                                                                            2,
                                                                        style: TextStyle(
                                                                            color:
                                                                                Color(0xffe8e8e8).withOpacity(0.5),
                                                                            fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                      )
                                                                    : Text(
                                                                        '${v['summary']}',
                                                                        textScaleFactor: mediaQueryData
                                                                            .textScaleFactor
                                                                            .clamp(0.5,
                                                                                1)
                                                                            .toDouble(),
                                                                        style: TextStyle(
                                                                            color:
                                                                                Color(0xffe8e8e8).withOpacity(0.5),
                                                                            fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                                                      )),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            v['permlink'] ==
                                                                    null
                                                                ? SizedBox()
                                                                : InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      if (prefs.getString(
                                                                              'HiveUserName') !=
                                                                          null) {
                                                                        setState(
                                                                            () {
                                                                          v['isLoading'] =
                                                                              true;
                                                                        });
                                                                        double
                                                                            _value =
                                                                            50.0;
                                                                        showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (context) {
                                                                              return Dialog(backgroundColor: Colors.transparent, child: UpvoteEpisode(permlink: v['permlink'], episode_id: v['id']));
                                                                            }).then((value) async {
                                                                          print(
                                                                              value);
                                                                        });
                                                                        setState(
                                                                            () {
                                                                          v['ifVoted'] =
                                                                              !v['ifVoted'];
                                                                        });
                                                                        setState(
                                                                            () {
                                                                          v['isLoading'] =
                                                                              false;
                                                                        });
                                                                      } else {
                                                                        showBarModalBottomSheet(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (context) {
                                                                              return HiveDetails();
                                                                            });
                                                                      }
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      decoration: v['ifVoted'] ==
                                                                              true
                                                                          ? BoxDecoration(
                                                                              gradient: LinearGradient(colors: [
                                                                                Color(0xff5bc3ef),
                                                                                Color(0xff5d5da8)
                                                                              ]),
                                                                              borderRadius: BorderRadius.circular(
                                                                                  30))
                                                                          : BoxDecoration(
                                                                              border: Border.all(color: kSecondaryColor),
                                                                              borderRadius: BorderRadius.circular(30)),
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                5,
                                                                            horizontal:
                                                                                5),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            v['isLoading'] == true
                                                                                ? Container(
                                                                                    height: 17,
                                                                                    width: 18,
                                                                                    child: SpinKitPulse(
                                                                                      color: Colors.blue,
                                                                                    ),
                                                                                  )
                                                                                : Icon(
                                                                                    FontAwesomeIcons.chevronCircleUp,
                                                                                    size: 15,
                                                                                    color: Color(0xffe8e8e8),
                                                                                  ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                                                              child: Text(
                                                                                v['votes'].toString(),
                                                                                textScaleFactor: 1.0,
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  color: Color(0xffe8e8e8),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(right: 4),
                                                                              child: Text(
                                                                                '\$${v['payout_value'].toString().split(' ')[0]}',
                                                                                textScaleFactor: 1.0,
                                                                                style: TextStyle(fontSize: 12, color: Color(0xffe8e8e8)),
                                                                              ),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                            v['permlink'] ==
                                                                    null
                                                                ? SizedBox()
                                                                : InkWell(
                                                                    onTap: () {
                                                                      if (prefs.getString(
                                                                              'HiveUserName') !=
                                                                          null) {
                                                                        Navigator.push(
                                                                            context,
                                                                            CupertinoPageRoute(
                                                                                builder: (context) => Comments(
                                                                                      episodeObject: v,
                                                                                    )));
                                                                      } else {
                                                                        showBarModalBottomSheet(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (context) {
                                                                              return HiveDetails();
                                                                            });
                                                                      }
                                                                    },
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              8.0),
                                                                      child:
                                                                          Container(
                                                                        decoration: BoxDecoration(
                                                                            border:
                                                                                Border.all(color: kSecondaryColor),
                                                                            borderRadius: BorderRadius.circular(30)),
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              const EdgeInsets.all(4.0),
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Icon(
                                                                                Icons.mode_comment_outlined,
                                                                                size: 14,
                                                                                color: Color(0xffe8e8e8),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 7),
                                                                                child: Text(
                                                                                  v['comments_count'].toString(),
                                                                                  textScaleFactor: 1.0,
                                                                                  style: TextStyle(fontSize: 10, color: Color(0xffe8e8e8)),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                            InkWell(
                                                              onTap: () {

                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            60),
                                                                child:
                                                                    Container(
                                                                  decoration: BoxDecoration(
                                                                      border: Border.all(
                                                                          color:
                                                                              kSecondaryColor),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              30)),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(5),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .play_circle_outline,
                                                                          size:
                                                                              15,
                                                                          color:
                                                                              Color(0xffe8e8e8),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.symmetric(horizontal: 8),
                                                                          child:
                                                                              Text(
                                                                            DurationCalculator(v['duration']),
                                                                            textScaleFactor:
                                                                                0.75,
                                                                            style:
                                                                                TextStyle(color: Color(0xffe8e8e8)),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        InkWell(
                                                          onTap: () {
                                                            // share(episodeObject: v);
                                                          },
                                                          child: Icon(
                                                            Icons.ios_share,
                                                            // size: 14,
                                                            color: Color(
                                                                0xffe8e8e8),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                for (int i = 0; i < 2; i++)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Color(0xff222222)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      7,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      7,
                                                  decoration: BoxDecoration(
                                                      color: Color(0xff161616),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                ),
                                                SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          color: Color(
                                                              0xff161616)),
                                                      height: 16,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              3,
                                                    ),
                                                    SizedBox(
                                                      height: 5,
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          color: Color(
                                                              0xff161616)),
                                                      height: 8,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              4,
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: Container(
                                                  color: Color(0xff161616),
                                                  height: 10,
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: Container(
                                                  color: Color(0xff161616),
                                                  height: 10,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2),
                                            ),
                                            SizedBox(
                                              height: 6,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: Container(
                                                  color: Color(0xff161616),
                                                  height: 6,
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 3),
                                              child: Container(
                                                  color: Color(0xff161616),
                                                  height: 6,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.75),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Color(0xff161616),
                                                    ),
                                                    height: 25,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            8,
                                                    //    color: kSecondaryColor,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color:
                                                            Color(0xff161616),
                                                      ),
                                                      height: 25,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                      //    color: kSecondaryColor,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        color:
                                                            Color(0xff161616),
                                                      ),
                                                      height: 20,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              8,
                                                      //    color: kSecondaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),


                    search.roomResult.length == 0
                        ? Container(
                            child: Center(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    FontAwesomeIcons.ghost,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "WOW! Such Empty",
                                  style: TextStyle(color: Color(0xffe8e8e8)),
                                )
                              ],
                            )),
                          )
                        : Container(
                            height: MediaQuery.of(context).size.height,
                            child: ListView(
                              controller: _roomScrollController,
                              shrinkWrap: true,
                              children: [
                                for (var v in search.roomResult)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 7.5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Color(0xff222222),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: kPrimaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.group,
                                                        size: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3,
                                                        color: Colors.blue,
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        v['communities'] != null
                                                            ? "community"
                                                            : 'general',
                                                        textScaleFactor: 1.0,
                                                        style: TextStyle(
                                                            fontSize: SizeConfig
                                                                    .blockSizeHorizontal *
                                                                2.5),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            v['roomParticipants'] == null
                                                ? SizedBox(
                                                    height: 10,
                                                  )
                                                : Container(
                                                    height:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width /
                                                                9) *
                                                            2.1,
                                                    child: GridView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 2,
                                                              mainAxisSpacing:
                                                                  10,
                                                              crossAxisSpacing:
                                                                  5,
                                                              childAspectRatio:
                                                                  1 / 1),
                                                      children: [
                                                        for (var a in v[
                                                            'roomParticipants'])
                                                          CachedNetworkImage(
                                                            imageUrl:
                                                                a['user_image'],
                                                            memCacheHeight:
                                                                (MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        2)
                                                                    .ceil(),
                                                            imageBuilder: (context,
                                                                imageProvider) {
                                                              return Container(
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    10,
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    10,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  image: DecorationImage(
                                                                      image:
                                                                          imageProvider,
                                                                      fit: BoxFit
                                                                          .cover),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                            v['description'] == null
                                                ? SizedBox()
                                                : Text(
                                                    "${v['description']}",
                                                    textScaleFactor: 1.0,
                                                    style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: SizeConfig
                                                                .blockSizeHorizontal *
                                                            2.8),
                                                  ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5),
                                              child: Text(
                                                "${v['title']}",
                                                textScaleFactor: 1.0,
                                                style: TextStyle(
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        5,
                                                    fontWeight:
                                                        FontWeight.w800),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: kPrimaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.stream,
                                                        size: SizeConfig
                                                                .safeBlockHorizontal *
                                                            3,
                                                        color: Colors.blue,
                                                      ),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                        'LIVE',
                                                        textScaleFactor: 1.0,
                                                        style: TextStyle(
                                                            fontSize: SizeConfig
                                                                    .blockSizeHorizontal *
                                                                2.5),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 15,
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                SharedPreferences prefs =
                                                    await SharedPreferences
                                                        .getInstance();
                                                if (v['hostuserid'] !=
                                                    prefs.getString('userId')) {
                                                  addRoomParticipant(
                                                      roomid: v['roomid']);
                                                } else {
                                                  hostJoined(v['roomid']);
                                                }
                                                getRoomDetails(v['roomid'])
                                                    .then((value) {
                                                  _joinMeeting(
                                                      roomId: value['roomid'],
                                                      roomName: value['title'],
                                                      hostUserId:
                                                          value['hostuserid']);
                                                });
                                                // await _joinMeeting(
                                                //     roomId: v['roomid'],
                                                //     roomName: v['title'],
                                                //     hostUserId: v['hostuserid']);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  color: Color(0xff191919),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 15,
                                                      vertical: 15),
                                                  child: Text("join room"),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                  ],
                ),
        ));
  }
}

class SearchResultProvider extends ChangeNotifier {
  int _currentTabIndex = 0;

  int _pagePodcast = 0;
  int _pageEpisode = 0;
  int _pageRoom = 0;
  int _pageCommunity = 0;
  int _pagePeople = 0;

  List _episodeResult = [];
  List _podcastResult = [];
  List _roomResult = [];
  List _communityResult = [];
  List _peopleResult = [];

  bool _isLoading = true;

  //All the getters

  bool get isLoading => _isLoading;

  int get currentTabIndex => _currentTabIndex;

  int get pagePodcast => _pagePodcast;
  int get pageEpisode => _pageEpisode;
  int get pageRoom => _pageRoom;
  int get pageCommunity => _pageCommunity;
  int get pagePeople => _pagePeople;

  List get episodeResult => _episodeResult;
  List get podcastResult => _podcastResult;
  List get roomResult => _roomResult;
  List get communityResult => _communityResult;
  List get peopleResult => _peopleResult;

  String get query => _query;

  //All the setters

  set isLoading(bool newValue) {
    _isLoading = newValue;
    print("Loading parameter changed");
    notifyListeners();
  }

  void getInitialSearch() async {
    isLoading = true;
    await getCommunities();
    await getEpisode();
    await getPeople();
    await getPodcast();
    await getRooms();
    isLoading = false;
  }

  set query(String newValue) {
    reset();
    _query = newValue;

    getInitialSearch();

    // notifyListeners();
  }

  set currentTabIndex(int newValue) {
    _currentTabIndex = newValue;

    notifyListeners();
  }

  set episodeResult(var newValue) {
    _episodeResult = newValue;

    notifyListeners();
  }

  set podcastResult(var newValue) {
    _podcastResult = newValue;

    notifyListeners();
  }

  set roomResult(var newValue) {
    _roomResult = newValue;

    notifyListeners();
  }

  set communityResult(var newValue) {
    _communityResult = newValue;

    notifyListeners();
  }

  set peopleResult(var newValue) {
    _peopleResult = newValue;

    notifyListeners();
  }

  set pagePodcast(int newValue) {
    _pagePodcast = newValue;

    getPodcast();
    notifyListeners();
  }

  set pageEpisode(int newValue) {
    _pageEpisode = newValue;

    getEpisode();

    notifyListeners();
  }

  set pageRoom(int newValue) {
    _pageRoom = newValue;

    getRooms();

    notifyListeners();
  }

  set pagePeople(int newValue) {
    _pagePeople = newValue;

    getPeople();

    notifyListeners();
  }

  set pageCommunity(int newValue) {
    _pageCommunity = newValue;

    getCommunities();

    notifyListeners();
  }

  String _query;

  Dio dio = Dio();

  CancelToken cancelToken = CancelToken();

  void reset() {
    currentTabIndex = 0;

    pagePodcast = 0;
    pageEpisode = 0;
    pageRoom = 0;
    pageCommunity = 0;
    pagePeople = 0;

    episodeResult = [];
    podcastResult = [];
    roomResult = [];
    communityResult = [];
    peopleResult = [];
  }

  void getRooms() async {
    // if (_pageRoom != 0) {
    //   cancelToken.cancel();
    // }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/searchRooms?word=$_query&loggedinuser=${prefs.getString('userId')}&page=$_pageRoom";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        if (pageRoom == 0) {
          _roomResult = response.data['rooms'];
        } else {
          _roomResult = _roomResult + response.data['rooms'];
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    print("Rooms Search Ended");
  }

  void getEpisode() async {
    // if (_pageEpisode != 0) {
    //   cancelToken.cancel();
    // }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/searchEpisodes?word=$_query&loggedinuser=${prefs.getString('userId')}&page=$_pageEpisode";
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        if (pageEpisode == 0) {
          _episodeResult = response.data['episodes'];
        } else {
          _episodeResult = _episodeResult + response.data['episodes'];
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getPodcast() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/search?word=$_query&loggedinuser${prefs.getString('userId')}&page=$_pagePodcast";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print(response.data);
        if (pagePodcast == 0) {
          _podcastResult = response.data['PodcastList'];
        } else {
          _podcastResult = _podcastResult + response.data['PodcastList'];
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
    print("Podcast Search Ended");
  }

  void getPeople() async {
    // if (_pagePeople != 0) {
    //   cancelToken.cancel();
    // }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/userSearch?word=$_query&loggedinuser=${prefs.getString('userId')}&page=$_pagePeople";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        print(response.data);
        if (pagePeople == 0) {
          _peopleResult = response.data['users'];
        } else {
          _peopleResult = _peopleResult + response.data['users'];
        }
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getCommunities() async {
    // if (_pageCommunity != 0) {
    //   cancelToken.cancel();
    // }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/searchCommunity?word=$_query&loggedinuser=${prefs.getString('userId')}&page=$pageCommunity";

    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        if (pageCommunity == 0) {
          _communityResult = response.data['allCommunity'];
        } else {
          _communityResult = communityResult + response.data['allCommunity'];
        }

        print(response.data);
      } else {
        print(response.statusCode);
      }
    } catch (e) {}
    print("Community Search Ended");
  }
}

_joinMeeting({String roomId, String roomName, String hostUserId}) async {
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
    ..userDisplayName = prefs.getString("HiveUserName")
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
              eventName: 'onConferenceTerminated',
              callback: (dynamic message) {
                if (hostUserId == prefs.getString("userId")) {
                  hostLeft(roomId);
                }
                debugPrint("readyToClose callback");
              }),
        ]),
  );
}

void subscribe(int podcastId) async {
  Dio dio = Dio();

  print("Follow function started");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = 'https://api.aureal.one/public/follow';
  var map = Map<String, dynamic>();

  map['user_id'] = prefs.getString('userId');
  map['podcast_id'] = podcastId;

  FormData formData = FormData.fromMap(map);

  try {
    var response = await dio.post(url, data: formData);
    print(response.toString());
  } catch (e) {
    print(e);
  }
}

void followUser({String authorUserId}) async {
  postreq.Interceptor intercept = postreq.Interceptor();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = "https://api.aureal.one/private/followAuthor";

  var map = Map<String, dynamic>();
  map['user_id'] = prefs.getString("userId");
  map['author_user_id'] = authorUserId;

  FormData formData = FormData.fromMap(map);

  try {
    var response = await intercept.postRequest(formData, url);
  } catch (e) {}
}

class ResultSection extends StatelessWidget {
  final query;
  ResultSection({@required this.query});



  @override
  Widget build(BuildContext context) {
    var searchResult = Provider.of<SearchResultProvider>(context, listen: false);
    searchResult.query = query;
    return Scaffold(
      body: Container(color: Color(0xff161616),
      child: ListView(
        shrinkWrap: true,
        children: [

        ],
      ),),
    );
  }
}

