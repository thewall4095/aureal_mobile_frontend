import 'dart:math';

import 'package:auditory/PlayerState.dart';
import 'package:auditory/screens/Profiles/CategoryView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'FollowingPage.dart';
import 'Profiles/PodcastView.dart';

// class DiscoverPage extends StatefulWidget {
//   @override
//   _DiscoverPageState createState() => _DiscoverPageState();
// }
//
// class _DiscoverPageState extends State<DiscoverPage> {
//
//
//   SharedPreferences prefs;
//   Dio dio = Dio();
//   CancelToken _cancel = CancelToken();
//
//   Future getDiscoverStructure() async {
//     prefs = await SharedPreferences.getInstance();
//     String url = "https://api.aureal.one/public/explore?user_id=${prefs.getString('userId')}";
//
//     try{
//       var response = await dio.get(url, cancelToken: _cancel);
//       if(response.statusCode == 200){
//         print(response.data);
//         return response.data['data'];
//       }else{
//         print(response.statusCode);
//       }
//     }catch(e){
//
//     }
//   }
//
//   Future generalisedApiCall(String apicall) async {
//     Dio dio = Dio(
//
//     );
//     prefs = await SharedPreferences.getInstance();
//     String url = "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}";
//
//     try{
//       var response = await dio.get(url, cancelToken: _cancel);
//       if(response.statusCode == 200){
//         return response.data['data'];
//       }
//     }catch(e){
//       print(e);
//     }
//
//   }
//
//   Widget _discoverFeedBuilder(BuildContext context, var data){
//
//     var episodeObject = Provider.of<PlayerChange>(context);
//     var currentlyPlaying = Provider.of<PlayerChange>(context);
//
//     switch(data['type']){
//       case 'podcast':
//         return PodcastWidget(data: data);
//         break;
//       case 'episode':
//         return EpisodeWidget(data: data);
//         break;
//
//       case "playlist":
//         return PlaylistWidget(data: data);
//         break;
//       case 'snippet':
//         return SnippetWidget(data: data);
//         break;
//       case 'user':
//         return FutureBuilder(
//           future: generalisedApiCall(data['api']),
//           builder: (context, snapshot){
//             return Container(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(15),
//                     child: Text("${data['name']}", style: TextStyle(
//                         fontSize: SizeConfig.safeBlockHorizontal * 5,
//                         fontWeight: FontWeight.bold
//                     )),
//                   ),
//                   Text("${snapshot.data}"),
//                 ],
//               ),
//             );
//           },
//         );
//         break;
//       case 'featured':
//         return FeaturedBuilder(data: data);
//     }
//   }
//
//
//
//   @override
//   void initState() {
//     // TODO: implement initState
//
//
//     super.initState();
//   }
//
//
//
//   String creator = '';
//
//   SharedPreferences pref;
//
//   @override
//   Widget build(BuildContext context) {
//
//
//     Future<bool> _onBackPressed() async {
//       SystemNavigator.pop();
//       return true; // return true if the route to be popped
//     }
//
//
//     return WillPopScope(
//       onWillPop: _onBackPressed,
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           return Scaffold(
//             extendBody: true,
//             body: FutureBuilder(
//               future: getDiscoverStructure(),
//               builder: (context, snapshot){
//                 return ListView.builder(itemBuilder: (context, int index){
//                   return
//                 });
//               },
//             ),
//             // ),
//           );
//         },
//       ),
//     );
//   }
// }

class DiscoverScreen extends StatefulWidget {
  DiscoverScreen();

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  String creator = '';

  SharedPreferences pref;

  SharedPreferences prefs;

  Dio dio = Dio();

  CancelToken _cancel = CancelToken();

  Future getDiscoverStructure() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/explore?user_id=${prefs.getString('userId')}";

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

  Widget _feedBuilder(BuildContext context, var data) {
    SharedPreferences prefs;

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

    var episodeObject = Provider.of<PlayerChange>(context);
    var currentlyPlaying = Provider.of<PlayerChange>(context);

    List colors = [Colors.red, Colors.green, Colors.yellow];
    Random random = Random();

    switch (data['type']) {
      case 'podcast':
        return PodcastWidget(data: data);
        break;
      case 'episode':
        return EpisodeWidget(data: data);
        // return Container();
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
        return FeaturedBuilder(data: data);
        break;
      case 'category':
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
                                        width: 3,
                                        color: Colors.primaries[index])),
                                color: Color(0xff1a1a1a)),
                            child: Center(
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(context,
                                      CupertinoPageRoute(builder: (context) {
                                    return CategoryView(
                                      categoryObject: snapshot.data[index],
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

  Future discoverFeed;

  @override
  void initState() {
    discoverFeed = getDiscoverStructure();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: discoverFeed,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              shrinkWrap: true,
              addAutomaticKeepAlives: true,
              itemBuilder: (context, int index) {
                if (index == snapshot.data.length) {
                  return SizedBox(
                    height: 150,
                  );
                } else {
                  return _feedBuilder(context, snapshot.data[index]);
                }
              },
              itemCount: snapshot.data.length + 1,
            );
          } else {
            return SizedBox();
          }
        },
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class FeaturedBuilder extends StatelessWidget {
  final data;
  int category_id;

  FeaturedBuilder({@required this.data, this.category_id});

  CancelToken _cancel = CancelToken();

  SharedPreferences prefs;

  Future generalisedApiCall(String apicall) async {
    prefs = await SharedPreferences.getInstance();

    Dio dio = Dio();
    prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/$apicall?pageSize=5&user_id=${prefs.getString('userId')}&category_id=${category_id}";

    try {
      var response = await dio.get(url, cancelToken: _cancel);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: generalisedApiCall(data['api']),
      builder: (context, snapshot) {
        try {
          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text("${data['name']}",
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.bold)),
                  trailing: Text(
                    "See more",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // SizedBox(height: 10,),
                Container(
                  width: double.infinity,
                  // height: SizeConfig.blockSizeVertical * 2,
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.width),
                  child: CarouselSlider(
                    options: CarouselOptions(
                        height: MediaQuery.of(context).size.width,
                        autoPlay: true,
                        enableInfiniteScroll: true,
                        viewportFraction: 1.0,
//
                        aspectRatio: 3 / 3,
                        pauseAutoPlayOnTouch: true,
                        enlargeCenterPage: false),
                    items: [
                      for (var v in snapshot.data)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) =>
                                          PodcastView(v['id'])));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    errorWidget: (context, url, error) {
                                      return AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: NetworkImage(
                                                      placeholderUrl),
                                                  fit: BoxFit.cover),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height:
                                              MediaQuery.of(context).size.width,
                                        ),
                                      );
                                    },
                                    imageBuilder: (context, imageProvider) {
                                      return AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover),
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height:
                                              MediaQuery.of(context).size.width,
                                        ),
                                      );
                                    },
                                    memCacheHeight:
                                        (MediaQuery.of(context).size.height)
                                            .floor(),
                                    imageUrl: v['image'],
                                    placeholder: (context, imageProvider) {
                                      return AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/Thumbnail.png'),
                                                  fit: BoxFit.cover)),
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.38,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.38,
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        gradient: LinearGradient(
                                            colors: [
                                              Colors.black,
                                              Colors.transparent
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter)),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: ListTile(
                                            title: Text(
                                              v['name'],
                                              maxLines: 1,
                                              textScaleFactor: 1.0,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      5,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              v['author'],
                                              maxLines: 2,
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3,
                                                  color: Color(0xffe777777)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          return Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text("${data['name']}",
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 5,
                          fontWeight: FontWeight.bold)),
                  trailing: Text(
                    "See more",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: double.infinity,
                  height: SizeConfig.blockSizeVertical * 2,
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.width * 1.1),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: NetworkImage(placeholderUrl),
                              fit: BoxFit.cover),
                          borderRadius: BorderRadius.circular(3)),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
