import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auditory/Accounts/HiveAccount.dart';
import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/Services/EmailVerificationDialog.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/LoginSignup/Auth.dart';
import 'package:auditory/screens/LoginSignup/WelcomeScreen.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/screens/RewardsScreen.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../Home.dart';
import 'Bio.dart';
import 'Downloads.dart';
import 'Settings.dart';

class Profile extends StatefulWidget {
  static const String id = 'Profile';

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  StreamSubscription<User> loginStateSubscription;
  TabController _tabController;
  final Set<Factory> gestureRecognizers =
      [Factory(() => EagerGestureRecognizer())].toSet();
  String hiveUserName;
  bool isLoading = true;
  String userId;
  String fullName = '';
  String userName;
  String displayPicture;
  String status = '';
  String bio = "";
  bool isEpisodeListLoading = true;
  var episodeList = [];
  bool isPodcastListLoading = true;
  var podcastList = [];
  String email;
  String rssFeed;
  bool loading = false;

  SharedPreferences prefs;

  postreq.Interceptor intercept = postreq.Interceptor();
  Dio dio = Dio();

  void updateUser() async {
    String url = 'https://api.aureal.one/private/updateUser';
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

  ScrollController _scrollController = ScrollController();

  void removeHiveUser() async {
    String url = 'https://api.aureal.one/public/removeHiveUser';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    setState(() {
      prefs.setString('HiveUserName', null);
      prefs.setString('access_token', null);
      prefs.setString('expires_in', null);
    });
  }

  AuthService service = AuthService();

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await service.logout();
    prefs.clear();
    if (!prefs.containsKey('userId')) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Welcome.id, (Route<dynamic> route) => false);
    }
  }

  void share() async {
    String sharableLink =
        "https://play.google.com/store/apps/details?id=com.titandlt.auditory";

    await FlutterShare.share(
        title: "I downloaded Aureal you can too",
        text: "Download this from $sharableLink");
  }

  void getUserDetails() async {
    setState(() {
      isLoading = true;
    });
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/private/users?user_id=${prefs.getString('userId')}';
    Map<String, String> header = {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      'encoding': 'encoding',
//      'Authorization': "Bearer $token"
      HttpHeaders.authorizationHeader: "Bearer ${prefs.getString('token')}"
    };

    try {
      http.Response response = await http.get(Uri.parse(url), headers: header);
      if (response.statusCode == 200) {
        setState(() {
          fullName = jsonDecode(response.body)['users']['fullname'];
          prefs.setString(
              'FullName', jsonDecode(response.body)['users']['fullname']);
          userName = jsonDecode(response.body)['users']['username'];
          prefs.setString(
              'userName', jsonDecode(response.body)['users']['username']);
          prefs.setString('HiveUserName',
              jsonDecode(response.body)['users']['hive_username']);
          // displayPicture = jsonDecode(response.body)['users']['img'];
          status = jsonDecode(response.body)['users']['settings']['Account']
              ['Presence'];
          bio =
              jsonDecode(response.body)['users']['settings']['Account']['Bio'];
          hiveUserName = prefs.getString('HiveUserName');
          email = jsonDecode(response.body)['users']['email'];
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  void getLocalData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      displayPicture = pref.getString('displayPicture');
    });
  }

  void getEpisodes() async {
//     isEpisodeListLoading = true;
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     Map<String, String> header = {
//       'Accept': 'application/json',
//       'Content-Type': 'application/json; charset=utf-8',
//       'encoding': 'encoding',
// //      'Authorization': "Bearer $token"
//       HttpHeaders.authorizationHeader: "Bearer ${prefs.getString('token')}"
//     };
//
//     print(header.toString());
//
//     print("initialising get episode");
//     String url =
//         "https://api.aureal.one/private/episode?user_id=${prefs.getString('userId')}";
//
//     try {
//       http.Response response = await http.get(url, headers: header);
//       print(response.body);
//       isEpisodeListLoading = false;
//       var data = json.decode(response.body);
//       setState(() {
//         episodeList = data['episodes'];
//       });
//     } catch (e) {
//       print(e);
//     }
  }

  void getPodcasts() async {
    setState(() {
      isPodcastListLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/private/getSubmittedRssFeeds?user_id=${prefs.getString('userId')}';
    try {
      print('came here too');
      print(url);

      var response = await intercept.getRequest(url);
      print(url);
      setState(() {
        print('came here too');

        isPodcastListLoading = false;
      });
      print('came here too');

      var data = response['podcasts'];
      print('came here too');

      setState(() {
        podcastList = data;
      });
      // var episodes = [];
      // if (podcastList != null && podcastList.length > 0) {
      //   print(podcastList[0].toString());
      //   podcastList.forEach((element) {
      //     print('came here too');
      //     element['Episodes'].forEach((episode) {
      //       episodes.add(episode);
      //     });
      //   });
      // }
      // setState(() {
      //   episodeList = episodes;
      // });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    setState(() {
      isLoading = true;
    });
    getLocalData();
    getPodcasts();
    getUserDetails();
    getEpisodes();
    setState(() {
      isLoading = false;
    });
    // TODO: implement initState

    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  Future getData() async {
    String url = "https://api.aureal.one/public/episode";

    http.Response response = await http.get(Uri.parse(url));

    var data = json.decode(response.body)['episodes'];
    return data;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var communities = Provider.of<CommunityProvider>(context);
    if (communities.isFetchedallCommunities == false) {
      communities.getAllCommunity();
    }
    if (communities.isFetcheduserCreatedCommunities == false) {
      communities.getUserCreatedCommunities();
    }
    if (communities.isFetcheduserCommunities == false) {
      communities.getAllCommunitiesForUser();
    }
    Future<void> _pullRefreshEpisodes() async {
      await communities.getAllCommunitiesForUser();
      await communities.getUserCreatedCommunities();
      await communities.getAllCommunity();
    }

    @override
    void initState() {
      // var authBloc = Provider.of<AuthBloc>(context, listen: false);
      // loginStateSubscription = authBloc.currentUser.listen((fbUser) {
      //   if (fbUser == null) {
      //     Navigator.of(context).pushReplacement(
      //       MaterialPageRoute(
      //         builder: (context) => Home(),
      //       ),
      //     );
      //   }
      // });
      super.initState();
    }

    @override
    void dispose() {
      loginStateSubscription.cancel();
      super.dispose();
    }

    Future<void> _pullRefresh() async {
      print('proceedd');

      await (getUserDetails());
    }

    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);

    final mediaQueryData = MediaQuery.of(context);
    final authBloc = Provider.of<AuthBloc>(context);
    final user = FirebaseAuth.instance.currentUser;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            // backgroundColor: Colors.transparent,
            title: Text(
              'My Profile',
              textScaleFactor:
                  mediaQueryData.textScaleFactor.clamp(0.2, 1).toDouble(),
              style: TextStyle(
                  //    color: Color(0xffe8e8e8),
                  fontSize: SizeConfig.safeBlockHorizontal * 7,
                  fontWeight: FontWeight.bold),
            ),
          ),
          body: Container(
            child: RefreshIndicator(
              onRefresh: _pullRefresh,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.width / 4,
                          width: MediaQuery.of(context).size.width / 4,
                          child: CachedNetworkImage(
                            imageUrl: displayPicture == null
                                ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                : displayPicture,
                            memCacheHeight:
                                MediaQuery.of(context).size.height.floor(),
                            errorWidget: (BuildContext context, url, error) {
                              return Container();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$userName",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1.3)
                                    .toDouble(),
                                style: TextStyle(
                                    //         color: Color(0xffe8e8e8),
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 5.5,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, Bio.id);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Color(0xff171b27),
                                      ),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 5),
                                    child: Text(
                                      'Edit Profile',
                                      textScaleFactor: mediaQueryData
                                          .textScaleFactor
                                          .clamp(0.2, 1)
                                          .toDouble(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.5),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            'Bio',
                            textScaleFactor: mediaQueryData.textScaleFactor
                                .clamp(0.2, 1)
                                .toDouble(),
                            style: TextStyle(
                                //   color: Color(0xffe8e8e8),
                                fontSize: SizeConfig.safeBlockHorizontal * 5,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '$bio',
                            textScaleFactor: mediaQueryData.textScaleFactor
                                .clamp(0.2, 1)
                                .toDouble(),
                            style: TextStyle(
                                //     color: Color(0xffe8e8e8),
                                fontSize: SizeConfig.safeBlockHorizontal * 4),
                          ),
                        ),
                        Divider(
                          color: Color(0xff171b27),
                        )
                      ],
                    ),
                  ),
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Padding(
                  //       padding: const EdgeInsets.all(10),
                  //       child: Text(
                  //         "Your Communities",
                  //         textScaleFactor: mediaQueryData.textScaleFactor
                  //             .clamp(0.2, 1)
                  //             .toDouble(),
                  //         style: TextStyle(
                  //           //         color: Color(0xffe8e8e8),
                  //           fontSize: SizeConfig.safeBlockHorizontal * 5,
                  //         ),
                  //       ),
                  //     ),
                  //     Container(
                  //       constraints: BoxConstraints(
                  //           maxHeight:
                  //               MediaQuery.of(context).size.height / 5.6),
                  //       child: ListView(
                  //         scrollDirection: Axis.horizontal,
                  //         children: [
                  //           for (var v in communities.userCreatedCommunities)
                  //             Padding(
                  //               padding: const EdgeInsets.all(8.0),
                  //               child: InkWell(
                  //                 onTap: () {
                  //                   Navigator.push(context,
                  //                       MaterialPageRoute(builder: (context) {
                  //                     return CommunityView(communityObject: v);
                  //                   }));
                  //                 },
                  //                 child: Column(
                  //                   crossAxisAlignment:
                  //                       CrossAxisAlignment.start,
                  //                   mainAxisAlignment: MainAxisAlignment.start,
                  //                   children: [
                  //                     Container(
                  //                       //color: Color(0xffe8e8e8),
                  //                       width:
                  //                           MediaQuery.of(context).size.width /
                  //                               4,
                  //                       height:
                  //                           MediaQuery.of(context).size.width /
                  //                               4,
                  //                       child: CachedNetworkImage(
                  //                         imageUrl: v['profileImageUrl'] == null
                  //                             ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                  //                             : v['profileImageUrl'],
                  //                         memCacheHeight: MediaQuery.of(context)
                  //                             .size
                  //                             .height
                  //                             .floor(),
                  //                         placeholder: (context, url) =>
                  //                             Container(
                  //                           child: Image.asset(
                  //                               'assets/images/Thumbnail.png'),
                  //                         ),
                  //                         errorWidget: (context, url, error) =>
                  //                             Icon(Icons.error),
                  //                       ),
                  //                     ),
                  //                     Padding(
                  //                       padding: const EdgeInsets.symmetric(
                  //                           vertical: 10),
                  //                       child: Container(
                  //                         width: MediaQuery.of(context)
                  //                                 .size
                  //                                 .width /
                  //                             4,
                  //                         child: Text(
                  //                           v['name'],
                  //                           textScaleFactor: mediaQueryData
                  //                               .textScaleFactor
                  //                               .clamp(0.2, 0.9)
                  //                               .toDouble(),
                  //                           overflow: TextOverflow.ellipsis,
                  //                           maxLines: 2,
                  //                           style: TextStyle(
                  //                             //    color: Colors.white,
                  //                             fontSize: SizeConfig
                  //                                     .safeBlockHorizontal *
                  //                                 4,
                  //                           ),
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //           Padding(
                  //             padding: const EdgeInsets
                  //                 .fromLTRB(
                  //                 15, 8, 0, 8),
                  //             child: Column(
                  //               crossAxisAlignment:
                  //               CrossAxisAlignment
                  //                   .start,
                  //               children: <Widget>[
                  //                 GestureDetector(
                  //                     onTap: () {
                  //                         Navigator.push(context,
                  //                         MaterialPageRoute(builder: (context) {
                  //                         return CreateCommunity();
                  //                         })).then((value) async {
                  //                         await _pullRefreshEpisodes();
                  //                         });
                  //                     },
                  //                     child:   Container(
                  //                       child: Center(
                  //                         child: Column(
                  //                           mainAxisAlignment:
                  //                           MainAxisAlignment
                  //                               .center,
                  //                           children: [
                  //                             Icon(
                  //                               Icons.add,
                  //                               color: Color(
                  //                                   0xffe8e8e8),
                  //                             ),
                  //
                  //                               Text(
                  //                                 "Add more",
                  //                                 textScaleFactor:
                  //                                 1.0,
                  //                                 style: TextStyle(
                  //                                     color:
                  //                                     Color(0xffe8e8e8),
                  //                                     fontSize: SizeConfig.safeBlockHorizontal * 4),
                  //                               ),
                  //
                  //                           ],
                  //                         ),
                  //                       ),
                  //                       color: Color(
                  //                           0xff3a3a3a),
                  //                       width:
                  //                       MediaQuery.of(context).size.width /
                  //                           4,
                  //                       height:
                  //                       MediaQuery.of(context).size.width /
                  //                           4,
                  //
                  //                     ))],
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 5),
                  //       child: Divider(
                  //         color: Color(0xff171b27),
                  //       ),
                  //     )
                  //   ],
                  // ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "Your podcasts and episodes",
                          textScaleFactor: mediaQueryData.textScaleFactor
                              .clamp(0.2, 1)
                              .toDouble(),
                          style: TextStyle(
                            //   color: Color(0xffe8e8e8),
                            fontSize: SizeConfig.safeBlockHorizontal * 5,
                          ),
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height / 5.6),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (var v in podcastList)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) {
                                      return PodcastView(v['id']);
                                    }));
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        //   color: Color(0xffe8e8e8),
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        child: CachedNetworkImage(
                                          imageUrl: v['image'] == null
                                              ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                              : v['image'],
                                          memCacheHeight: MediaQuery.of(context)
                                              .size
                                              .height
                                              .floor(),
                                          placeholder: (context, url) =>
                                              Container(
                                            child: Image.asset(
                                                'assets/images/Thumbnail.png'),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error),
                                        ),
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            v['name'],
                                            textScaleFactor: mediaQueryData
                                                .textScaleFactor
                                                .clamp(0.2, 1)
                                                .toDouble(),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(
                                              //     color: Colors.white,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 8, 0, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  GestureDetector(
                                      onTap: () async {
                                        await showBarModalBottomSheet(
                                            context: context,
                                            builder: (context) {
                                              return EmailVerificationDialog(
                                                  username: prefs
                                                      .getString('userName'));
                                            });
                                      },
                                      child: Container(
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add,
                                                color: Color(0xffe8e8e8),
                                              ),
                                              Text(
                                                "Add more",
                                                textScaleFactor: 1.0,
                                                style: TextStyle(
                                                    color: Color(0xffe8e8e8),
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        4),
                                              ),
                                            ],
                                          ),
                                        ),
                                        color: Color(0xff3a3a3a),
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                4,
                                      ))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom:
                                      BorderSide(color: Color(0xff171b27)))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: InkWell(
                              onTap: () async {
                                await showBarModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return EmailVerificationDialog(
                                        username: prefs.getString('userName'),
                                      );
                                    });
                              },
                              child: Text(
                                "Add your podcast",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                  //      color: Color(0xffe8e8e8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Container(
                        //   width: double.infinity,
                        //   decoration: BoxDecoration(
                        //       border: Border(
                        //           bottom:
                        //               BorderSide(color: Color(0xff171b27)))),
                        //   child: Padding(
                        //     padding: const EdgeInsets.symmetric(vertical: 15),
                        //     child: InkWell(
                        //       onTap: () {
                        //         Navigator.push(context,
                        //             MaterialPageRoute(builder: (context) {
                        //           return CreateCommunity();
                        //         })).then((value) async {
                        //           await _pullRefreshEpisodes();
                        //         });
                        //       },
                        //       child: Text(
                        //         "Add your community",
                        //         textScaleFactor: mediaQueryData.textScaleFactor
                        //             .clamp(0.2, 1)
                        //             .toDouble(),
                        //         style: TextStyle(
                        //           fontSize: SizeConfig.safeBlockHorizontal * 4,
                        //           //      color: Color(0xffe8e8e8),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xff171b27),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return Rewards();
                                }));
                              },
                              child: Text(
                                "Your rewards",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                  //    color: Color(0xffe8e8e8),
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xff171b27),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: InkWell(
                              onTap: () {
                                showBarModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return DownloadPage();
                                    });
                              },
                              child: Text(
                                "Library",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                  //        color: Color(0xffe8e8e8),
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xff171b27),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: InkWell(
                              onTap: () {
                                showBarModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.height,
                                        // child: InAppWebView(
                                        //     gestureRecognizers:
                                        //         gestureRecognizers,
                                        //     initialFile:
                                        //         'https://wallet.hive.blog/@${prefs.getString('HiveUserName')}'),
                                        child: WebView(
                                          gestureRecognizers: Set()
                                            ..add(
                                              Factory<
                                                  VerticalDragGestureRecognizer>(
                                                () =>
                                                    VerticalDragGestureRecognizer(),
                                              ), // or null
                                            ),
                                          gestureNavigationEnabled: true,
                                          javascriptMode:
                                              JavascriptMode.unrestricted,
                                          initialUrl:
                                              'https://wallet.hive.blog/@${prefs.getString('HiveUserName')}',
                                        ),
                                      );
                                    });
                              },
                              child: Text(
                                "Your wallet",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                  //        color: Color(0xffe8e8e8),
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xff171b27),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: InkWell(
                              onTap: () {
                                hiveUserName == null
                                    ? Navigator.pushNamedAndRemoveUntil(context,
                                        HiveAccount.id, (route) => false)
                                    : print('nothing');
                              },
                              child: Text(
                                hiveUserName != null
                                    ? "Connected with your Hive Account ( @${hiveUserName} )"
                                    : "Connect your Hive Account",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                  //     color: Color(0xffe8e8e8),
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xff171b27),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: InkWell(
                              onTap: () {
                                showBarModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return Settings();
                                    });
                              },
                              child: Text(
                                "Setting",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                  //  color: Color(0xffe8e8e8),
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xff171b27),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: InkWell(
                              onTap: () {
                                logout();
                                prefs.clear();
                              },
                              child: Text(
                                "Log Out",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                  //    color: Color(0xffe8e8e8),
                                  fontSize: SizeConfig.safeBlockHorizontal * 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // SignInButton(Buttons.Google,
                        //     text: 'Sign Out of Google',
                        //     onPressed: () => authBloc.logout())
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RSSDialog extends StatefulWidget {
  @override
  _RSSDialogState createState() => _RSSDialogState();
}

class _RSSDialogState extends State<RSSDialog> {
  bool loading = false;
  Dio dio = Dio();

  String rssFeed;
  Function function;
  String errorMessage;

  void createFromRss() async {
    setState(() {
      loading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/createFromRss';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['url'] = rssFeed;

    FormData formData = FormData.fromMap(map);

    var response = await dio.post(url, data: formData);
//    print(response..data.runtimeType);
//    print(response.toString());
    if (response.data['msg'] != null) {
      setState(() {
        errorMessage = response.data['msg'].toString();
      });
    } else {
      Navigator.pushNamedAndRemoveUntil(context, Home.id, (route) => false);
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    return Container(
        height: 180,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () async {
                    await createFromRss();
//                    Navigator.pushNamedAndRemoveUntil(
//                        context, Home.id, (route) => false);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xff6048F6), Color(0xff51C9F9)]),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: loading == true
                            ? SpinKitPulse(
                                color: Colors.white,
                              )
                            : Text(
                                "Done",
                                textScaleFactor: mediaQueryData.textScaleFactor
                                    .clamp(0.2, 1)
                                    .toDouble(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 3),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          rssFeed = value;
                        });
                      },
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: SizeConfig.safeBlockHorizontal * 3),
                      decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(left: 10),
                          hintStyle: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3,
                          ),
                          border: InputBorder.none,
                          hintText: 'Paste your RSS feed here'),
                    ),
                  ),
                ),
                errorMessage == null
                    ? SizedBox(
                        height: 0,
                      )
                    : Text(
                        '$errorMessage',
                        textScaleFactor: mediaQueryData.textScaleFactor
                            .clamp(0.2, 1)
                            .toDouble(),
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                      ),
              ],
            )
          ],
        ));
  }
}

class ImportPodcast extends StatefulWidget {
  @override
  _ImportPodcastState createState() => _ImportPodcastState();
}

class _ImportPodcastState extends State<ImportPodcast> {
  final GlobalKey<ScaffoldState> _RSSImportKey = new GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  postreq.Interceptor intercept = postreq.Interceptor();
  Dio dio = Dio();

  bool isLoading = false;

  void sendOTP() async {
    setState(() {
      isLoading = true;
    });

    String url = "https://api.aureal.one/private/sendOTPMailVerify";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['url'] = _RSSController.text;

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);

    setState(() {
      isLoading = false;
    });
  }

  void showInSnackBar(String value) {
    final mediaQueryData = MediaQuery.of(context);
    _RSSImportKey.currentState.showSnackBar(new SnackBar(
        backgroundColor: Colors.blue,
        content: new Text(
          value,
          textScaleFactor:
              mediaQueryData.textScaleFactor.clamp(0.2, 1).toDouble(),
          style: TextStyle(color: Colors.white),
        )));
  }

  void verifyOTP() async {
    setState(() {
      isLoading = true;
    });
    String url = 'https://api.aureal.one/public/verifyOTP';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['otp'] = _OTPController.text;

    FormData formData = FormData.fromMap(map);

    Dio dio = Dio();
    var response = await dio.post(url, data: formData);

    if (response.data['msg'] != null) {
      setState(() {
        isLoading = false;
      });
      showInSnackBar('${response.data['msg']}');
    } else {
      createFromRss();
      setState(() {
        isLoading = false;
      });
      setState(() {
        _selectedIndex = 2;
      });
    }
  }

  String newRSSFeed;

  Widget _createPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        return _RSSTextField();
        break;

      case 1:
        return _VerifyOTP();
        break;

      case 2:
        return _GetRSSFeed();
        break;
    }
  }

  TextEditingController _RSSController = TextEditingController();
  TextEditingController _OTPController = TextEditingController();

  void createFromRss() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/createFromRss';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['url'] = _RSSController.text;

    FormData formData = FormData.fromMap(map);

    var response = await dio.post(url, data: formData);
    if (response.data['msg'] != null) {
      // print(response.data['msg'].toString());
    } else {
      setState(() {
        newRSSFeed = response.data['podcast']['feedUrl'];
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget _RSSTextField() {
    final mediaQueryData = MediaQuery.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Please paste the RSS link here, you can get this from your hosting provider",
          textScaleFactor:
              mediaQueryData.textScaleFactor.clamp(0.2, 1).toDouble(),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
        SizedBox(
          height: SizeConfig.safeBlockVertical * 2,
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(30)),
          child: TextField(
            decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15)),
            controller: _RSSController,
          ),
        ),
        SizedBox(
          height: SizeConfig.safeBlockVertical * 2,
        ),
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
          child: IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: Colors.white,
            ),
            onPressed: () async {
              await sendOTP();
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
        )
      ],
    );
  }

  Widget _VerifyOTP() {
    final mediaQueryData = MediaQuery.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Please enter the OTP you've received on your registered email id",
          textScaleFactor:
              mediaQueryData.textScaleFactor.clamp(0.2, 1).toDouble(),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
        SizedBox(
          height: SizeConfig.safeBlockVertical * 2,
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(30)),
          child: TextField(
            controller: _OTPController,
            decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15)),
          ),
        ),
        SizedBox(
          height: SizeConfig.safeBlockVertical * 2,
        ),
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
          child: IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: Colors.white,
            ),
            onPressed: () {
              verifyOTP();
            },
          ),
        )
      ],
    );
  }

  Widget _GetRSSFeed() {
    final mediaQueryData = MediaQuery.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Welcome to Aureal! Here's your new RSS feed, Copy this link and paste it across platforms",
          textScaleFactor:
              mediaQueryData.textScaleFactor.clamp(0.2, 1).toDouble(),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
        SizedBox(
          height: SizeConfig.safeBlockVertical * 2,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30), color: kSecondaryColor),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              '$newRSSFeed',
              textScaleFactor:
                  mediaQueryData.textScaleFactor.clamp(0.2, 1).toDouble(),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.safeBlockHorizontal * 4),
            ),
          ),
        ),
        SizedBox(
          height: SizeConfig.safeBlockVertical * 2,
        ),
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xff6048F6), Color(0xff51C9F9)])),
          child: IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: newRSSFeed));
              showInSnackBar('Copied to Clipboard');
            },
            icon: Icon(
              Icons.copy,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: SizeConfig.safeBlockVertical * 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _RSSImportKey,
      appBar: AppBar(
        leading: _selectedIndex == 0
            ? SizedBox(
                width: 0,
              )
            : IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_selectedIndex > 0) {
                      _selectedIndex = _selectedIndex - 1;
                    }
                  });
                },
              ),
        elevation: 0,
        backgroundColor: kPrimaryColor,
        title: Text(""),
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _createPage(context, _selectedIndex)),
              isLoading == false
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xff6249EF)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
