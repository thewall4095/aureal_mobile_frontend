import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auditory/Services/EmailVerificationDialog.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/LoginSignup/Auth.dart';
import 'package:auditory/screens/LoginSignup/WelcomeScreen.dart';
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/screens/Profiles/PodcastView.dart';
import 'package:auditory/screens/buttonPages/Referralprogram.dart';
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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../Home.dart';
import '../RewardsScreen.dart';
import 'Bio.dart';
import 'Settings.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              child: TweenAnimationBuilder(
                  tween: Tween(begin: 0.0, end: 0.9),
                  duration: Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return ShaderMask(
                        shaderCallback: (rect) {
                          return RadialGradient(
                                  radius: value * 5,
                                  colors: [
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                    Colors.transparent
                                  ],
                                  stops: [10, 1, 1, 1.0],
                                  center: FractionalOffset(0.1, 0.0))
                              .createShader(rect);
                        },
                        child: Profile());
                  }),
            );
          },
        ));
  }
}

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
        "https://play.google.com/store/apps/details?id=co.titandlt.aureal";

    await FlutterShare.share(
        title: "I downloaded Aureal you can too",
        text: "Download this from $sharableLink");
  }

  var data;
  var selectedCategories = [];

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
        print(response.body);
        setState(() {
          data = (jsonDecode(response.body)['users'] == null
              ? ""
              : jsonDecode(response.body)['users']);
          fullName = jsonDecode(response.body)['users']['fullname'] == null
              ? ""
              : jsonDecode(response.body)['users']['fullname'];
          // prefs.setString(
          //     'FullName', jsonDecode(response.body)['users']['fullname']);
          userName = (jsonDecode(response.body)['users']['username'] == null
              ? ""
              : jsonDecode(response.body)['users']['username']);
          prefs.setString(
              'userName', jsonDecode(response.body)['users']['username']);
          prefs.setString('HiveUserName',
              jsonDecode(response.body)['users']['hive_username']);
          displayPicture = jsonDecode(response.body)['users']['img'];
          status = jsonDecode(response.body)['users']['settings']['Account']
              ['Presence'];
          bio = (jsonDecode(response.body)['users']['settings']['Account']
                      ['Bio'] ==
                  null
              ? ""
              : jsonDecode(response.body)['users']['settings']['Account']
                  ['Bio']);
          hiveUserName = prefs.getString('HiveUserName');
          email = (jsonDecode(response.body)['users']['email'] == null
              ? ""
              : jsonDecode(response.body)['users']['email']);
        });
        setState(() {
          isLoading = false;
          isProfileLoading = false;
        });
      }
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
      print(data.toString());

      setState(() {
        podcastList = data;
      });
    } catch (e) {
      print(e);
    }
  }

  bool isProfileLoading = true;

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
    // var communities = Provider.of<CommunityProvider>(context);
    // if (communities.isFetchedallCommunities == false) {
    //   communities.getAllCommunity();
    // }
    // if (communities.isFetcheduserCreatedCommunities == false) {
    //   communities.getUserCreatedCommunities();
    // }
    // if (communities.isFetcheduserCommunities == false) {
    //   communities.getAllCommunitiesForUser();
    // }
    // Future<void> _pullRefreshEpisodes() async {
    //   await communities.getAllCommunitiesForUser();
    //   await communities.getUserCreatedCommunities();
    //   await communities.getAllCommunity();
    // }

    // @override
    // void initState() {
    //   // var authBloc = Provider.of<AuthBloc>(context, listen: false);
    //   // loginStateSubscription = authBloc.currentUser.listen((fbUser) {
    //   //   if (fbUser == null) {
    //   //     Navigator.of(context).pushReplacement(
    //   //       CupertinoPageRoute(
    //   //         builder: (context) => Home(),
    //   //       ),
    //   //     );
    //   //   }
    //   // });
    //   super.initState();
    // }
    //
    // @override
    // void dispose() {
    //   loginStateSubscription.cancel();
    //   super.dispose();
    // }

    Future<void> _pullRefresh() async {
      print('proceedd');

      await (getUserDetails());
    }

    Future<bool> _onBackPressed() async {
      Navigator.pushNamedAndRemoveUntil(
          context, Home.id, ModalRoute.withName("/"));
      return false; // return true if the route to be popped
    }

    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    Launcher launcher = Launcher();
    final mediaQueryData = MediaQuery.of(context);
    final authBloc = Provider.of<AuthBloc>(context);
    final user = FirebaseAuth.instance.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        return WillPopScope(
            onWillPop: _onBackPressed,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  "Profile",
                  textScaleFactor: 1.0,
                  style:
                      TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
                ),
              ),
              // appBar: AppBar(
              //   backgroundColor: Colors.transparent,
              //   elevation: 0,
              //   leading: IconButton(
              //     icon: Icon(Icons.arrow_back),
              //   ),
              //   actions: [
              //     IconButton(
              //       icon: Icon(Icons.more_vert_outlined),
              //     )
              //   ],
              // ),
              resizeToAvoidBottomInset: true,
              body: ModalProgressHUD(
                inAsyncCall: isProfileLoading,
                child: isProfileLoading == true
                    ? Container()
                    : RefreshIndicator(
                        onRefresh: _pullRefresh,
                        child: ListView(children: [
                          // Container(
                          //   color: Color(0xff161616),
                          //   child: Column(
                          //     children: [
                          //       Container(
                          //         height:
                          //             (MediaQuery.of(context).size.height / 3) *
                          //                 (0.45),
                          //         decoration: BoxDecoration(
                          //             gradient: LinearGradient(colors: [
                          //           Color(0xff5d5da8),
                          //           Color(0xff5bc3ef)
                          //         ])),
                          //       ),
                          //       Container(
                          //         child: Padding(
                          //           padding: const EdgeInsets.all(20),
                          //           child: Container(
                          //             child: Column(
                          //               mainAxisSize: MainAxisSize.min,
                          //               children: [
                          //                 Row(
                          //                   crossAxisAlignment:
                          //                       CrossAxisAlignment.start,
                          //                   children: [
                          //                     CachedNetworkImage(
                          //                       imageUrl: data['img'] == null
                          //                           ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                          //                           : data['img'],
                          //                       imageBuilder:
                          //                           (context, imageProvider) {
                          //                         return Container(
                          //                           height:
                          //                               MediaQuery.of(context)
                          //                                       .size
                          //                                       .width /
                          //                                   5,
                          //                           width:
                          //                               MediaQuery.of(context)
                          //                                       .size
                          //                                       .width /
                          //                                   5,
                          //                           decoration: BoxDecoration(
                          //                               shape: BoxShape.circle,
                          //                               border: Border.all(
                          //                                   color: Colors
                          //                                       .blueAccent,
                          //                                   width: 2),
                          //                               image: DecorationImage(
                          //                                   image:
                          //                                       imageProvider,
                          //                                   fit: BoxFit.cover)),
                          //                         );
                          //                       },
                          //                     ),
                          //                     SizedBox(
                          //                       width: 20,
                          //                     ),
                          //                     Column(
                          //                       crossAxisAlignment:
                          //                           CrossAxisAlignment.start,
                          //                       children: [
                          //                         Text(
                          //                           "${data['fullname']}",
                          //                           style: TextStyle(
                          //                               fontSize: SizeConfig
                          //                                       .safeBlockHorizontal *
                          //                                   5,
                          //                               fontWeight:
                          //                                   FontWeight.w600),
                          //                         ),
                          //                         Text("@${data['username']}"),
                          //                         // Padding(
                          //                         //   padding: const EdgeInsets.symmetric(vertical: 8),
                          //                         //   child: InkWell(
                          //                         //     onTap: () {
                          //                         //       follow();
                          //                         //     },
                          //                         //     child: ifFollowed == true
                          //                         //         ? ShaderMask(
                          //                         //       shaderCallback: (Rect bounds) {
                          //                         //         return LinearGradient(colors: [
                          //                         //           Color(0xff5d5da8),
                          //                         //           Color(0xff5bc3ef)
                          //                         //         ]).createShader(bounds);
                          //                         //       },
                          //                         //       child: Row(
                          //                         //         mainAxisSize: MainAxisSize.min,
                          //                         //         children: [
                          //                         //           Icon(Icons.check_circle),
                          //                         //           Padding(
                          //                         //             padding:
                          //                         //             const EdgeInsets.all(5.0),
                          //                         //             child: Text("Followed"),
                          //                         //           ),
                          //                         //         ],
                          //                         //       ),
                          //                         //     )
                          //                         //         : Row(
                          //                         //       mainAxisSize: MainAxisSize.min,
                          //                         //       children: [
                          //                         //         Icon(Icons.add_circle),
                          //                         //         Padding(
                          //                         //           padding: const EdgeInsets.all(5.0),
                          //                         //           child: Text("Follow"),
                          //                         //         ),
                          //                         //       ],
                          //                         //     ),
                          //                         //   ),
                          //                         // ),
                          //                         // SizedBox(
                          //                         //   height: 10,
                          //                         // ),
                          //                         // Row(
                          //                         //   children: [
                          //                         //     InkWell(
                          //                         //       onTap: () {
                          //                         //         showBarModalBottomSheet(
                          //                         //             context: context,
                          //                         //             builder: (context) {
                          //                         //               return Followers();
                          //                         //             });
                          //                         //       },
                          //                         //       child: Column(
                          //                         //         mainAxisSize: MainAxisSize.min,
                          //                         //         crossAxisAlignment:
                          //                         //         CrossAxisAlignment.start,
                          //                         //         children: [
                          //                         //           Text(
                          //                         //             "${userData['followers']}",
                          //                         //             style: TextStyle(
                          //                         //                 fontSize:
                          //                         //                 SizeConfig.safeBlockHorizontal *
                          //                         //                     4.5,
                          //                         //                 fontWeight: FontWeight.bold),
                          //                         //           ),
                          //                         //           Text(
                          //                         //             "Followers",
                          //                         //             textScaleFactor: 1.0,
                          //                         //             style: TextStyle(
                          //                         //                 fontSize:
                          //                         //                 SizeConfig.safeBlockHorizontal *
                          //                         //                     2.5),
                          //                         //           )
                          //                         //         ],
                          //                         //       ),
                          //                         //     ),
                          //                         //     SizedBox(
                          //                         //       width: 20,
                          //                         //     ),
                          //                         //     InkWell(
                          //                         //       onTap: () {
                          //                         //         showBarModalBottomSheet(
                          //                         //             context: context,
                          //                         //             builder: (context) {
                          //                         //               return Scaffold(
                          //                         //                 appBar: AppBar(
                          //                         //                   title: Text(
                          //                         //                     "Followers",
                          //                         //                     textScaleFactor: 1.0,
                          //                         //                     style: TextStyle(
                          //                         //                         fontSize: SizeConfig
                          //                         //                             .safeBlockHorizontal *
                          //                         //                             4),
                          //                         //                   ),
                          //                         //                 ),
                          //                         //               );
                          //                         //             });
                          //                         //       },
                          //                         //       child: Column(
                          //                         //         mainAxisSize: MainAxisSize.min,
                          //                         //         crossAxisAlignment:
                          //                         //         CrossAxisAlignment.start,
                          //                         //         children: [
                          //                         //           Text(
                          //                         //             "${userData['following']}",
                          //                         //             style: TextStyle(
                          //                         //                 fontSize:
                          //                         //                 SizeConfig.safeBlockHorizontal *
                          //                         //                     4.5,
                          //                         //                 fontWeight: FontWeight.bold),
                          //                         //           ),
                          //                         //           Text(
                          //                         //             "Following",
                          //                         //             textScaleFactor: 1.0,
                          //                         //             style: TextStyle(
                          //                         //                 fontSize:
                          //                         //                 SizeConfig.safeBlockHorizontal *
                          //                         //                     2.5),
                          //                         //           )
                          //                         //         ],
                          //                         //       ),
                          //                         //     ),
                          //                         //   ],
                          //                         // )
                          //                       ],
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ],
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          Container(
                            // decoration: BoxDecoration(
                            //   borderRadius: BorderRadius.circular(10),
                            //   boxShadow: [
                            //     new BoxShadow(
                            //       color: Colors.black54.withOpacity(0.2),
                            //       blurRadius: 10.0,
                            //     ),
                            //   ],
                            //   color: Color(0xff222222),
                            // ),
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.push(context,
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return Bio();
                                        }));
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        radius: 55,
                                        child: CachedNetworkImage(
                                          imageUrl: data['img'] == null
                                              ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                              : data['img'],
                                          imageBuilder:
                                              (context, imageProvider) {
                                            return Container(
                                              height: 55,
                                              width: 55,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.blueAccent,
                                                      width: 2),
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover)),
                                            );
                                          },
                                        ),
                                      ),
                                      title: Text(
                                        "$userName",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    5),
                                      ),
                                      subtitle: prefs
                                                  .getString('HiveUserName') ==
                                              null
                                          ? ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                return LinearGradient(colors: [
                                                  Color(0xff52BFF9),
                                                  Color(0xff6048F6)
                                                ]).createShader(bounds);
                                              },
                                              child: InkWell(
                                                onTap: () {
                                                  showBarModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return HiveDetails();
                                                      });
                                                },
                                                child: Text(
                                                  "Connect Your Hive Account",
                                                  textScaleFactor: 1.0,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              '@${prefs.getString('HiveUserName')}',
                                              textScaleFactor: 1.0,
                                              style: TextStyle(
                                                  color: Color(0xff777777)),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Container(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          data['instagram'] == null ||
                                                  data['instagram'] == ''
                                              ? SizedBox()
                                              : IconButton(
                                                  icon: Icon(FontAwesomeIcons
                                                      .instagram),
                                                  iconSize: 20,
                                                  onPressed: () {
                                                    launcher.launchInBrowser(
                                                      data['instagram'],
                                                    );
                                                  },
                                                ),
                                          data['twitter'] == null ||
                                                  data['twitter'] == ''
                                              ? SizedBox()
                                              : IconButton(
                                                  icon: Icon(
                                                      FontAwesomeIcons.twitter),
                                                  iconSize: 20,
                                                  onPressed: () {
                                                    launcher.launchInBrowser(
                                                        data['twitter']);
                                                  },
                                                ),
                                          data['linkedin'] == null ||
                                                  data['linkedin'] == ''
                                              ? SizedBox()
                                              : IconButton(
                                                  icon: Icon(FontAwesomeIcons
                                                      .linkedin),
                                                  iconSize: 20,
                                                  onPressed: () {
                                                    launcher.launchInBrowser(
                                                        data['linkedin']);
                                                  },
                                                ),
                                          data['website'] == null ||
                                                  data['website'] == ''
                                              ? SizedBox()
                                              : IconButton(
                                                  icon: Icon(FontAwesomeIcons
                                                      .externalLinkSquareAlt),
                                                  iconSize: 20,
                                                  onPressed: () {
                                                    launcher.launchInBrowser(
                                                        data['website']);
                                                  },
                                                )
                                        ],
                                      ),
                                    ),
                                  ),
                                  // SizedBox(
                                  //   height: MediaQuery.of(context)
                                  //           .size
                                  //           .height /
                                  //       50, // height: 55,
                                  // ),
                                  // Text(
                                  //   "$userName",
                                  //   textScaleFactor: 1.0,
                                  //   style: TextStyle(
                                  //       fontSize: SizeConfig
                                  //               .safeBlockHorizontal *
                                  //           5),
                                  // ),
                                  // Padding(
                                  //   padding: const EdgeInsets.all(8.0),
                                  //   child: prefs.getString(
                                  //               'HiveUserName') ==
                                  //           null
                                  //       ? ShaderMask(
                                  //           shaderCallback:
                                  //               (Rect bounds) {
                                  //             return LinearGradient(
                                  //                 colors: [
                                  //                   Color(0xff52BFF9),
                                  //                   Color(0xff6048F6)
                                  //                 ]).createShader(bounds);
                                  //           },
                                  //           child: InkWell(
                                  //             onTap: () {
                                  //               showBarModalBottomSheet(
                                  //                   context: context,
                                  //                   builder: (context) {
                                  //                     return HiveDetails();
                                  //                   });
                                  //             },
                                  //             child: Text(
                                  //               "Connect Your Hive Account",
                                  //               textScaleFactor: 1.0,
                                  //             ),
                                  //           ),
                                  //         )
                                  //       : Text(
                                  //           '@${prefs.getString('HiveUserName')}',
                                  //           textScaleFactor: 1.0,
                                  //           style: TextStyle(
                                  //               color: Color(0xff777777)),
                                  //         ),
                                  // ),
                                ]),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Text(
                                  "Your Podcasts",
                                  textScaleFactor: 1.0,
                                  style: TextStyle(
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 5),
                                ),
                              ),
                              Container(
                                height:
                                    MediaQuery.of(context).size.height / 6.2,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (var v in podcastList)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 8),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(context,
                                                CupertinoPageRoute(
                                                    builder: (context) {
                                              return PodcastView(v['id']);
                                            }));
                                          },
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                4.5,
                                            child: Column(
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
                                                    color: themeProvider
                                                                .isLightTheme ==
                                                            true
                                                        ? Colors.white
                                                        : Color(0xff222222),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      4.5,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      4.5,
                                                  child: CachedNetworkImage(
                                                    imageUrl: v['image'],
                                                    imageBuilder: (context,
                                                        imageProvider) {
                                                      return Container(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            4.5,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            4.5,
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            image: DecorationImage(
                                                                image:
                                                                    imageProvider,
                                                                fit: BoxFit
                                                                    .cover)),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: Text("${v['name']}"),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 8, 0, 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: () async {
                                              if (prefs.getString(
                                                      'HiveUserName') ==
                                                  null) {
                                                showBarModalBottomSheet(
                                                    context: context,
                                                    builder: (context) {
                                                      return HiveDetails();
                                                    });
                                              } else {
                                                showBarModalBottomSheet(
                                                    context: context,
                                                    builder: (context) {
                                                      return EmailVerificationDialog(
                                                        username:
                                                            prefs.getString(
                                                                'userName'),
                                                      );
                                                    });
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  new BoxShadow(
                                                    color: Colors.black54
                                                        .withOpacity(0.2),
                                                    blurRadius: 10.0,
                                                  ),
                                                ],
                                                color: themeProvider
                                                            .isLightTheme ==
                                                        true
                                                    ? Colors.white
                                                    : Color(0xff222222),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4.5,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  4.5,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 5),
                                            child: Text("Add a podcast"),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Padding(
                                    //   padding:
                                    //       const EdgeInsets.fromLTRB(15, 8, 0, 8),
                                    //   child: Column(
                                    //     children: [
                                    //
                                    //       Container(
                                    //         decoration: BoxDecoration(
                                    //             color: Color(0xff222222),
                                    //             borderRadius:
                                    //                 BorderRadius.circular(10)),
                                    //         width:
                                    //             MediaQuery.of(context).size.width /
                                    //                 4.5,
                                    //         height:
                                    //             MediaQuery.of(context).size.width /
                                    //                 4.5,
                                    //         child: Icon(Icons.add),
                                    //       ),
                                    //       Padding(
                                    //         padding: const EdgeInsets.all(8.0),
                                    //         child: Text("Add a podcast"),
                                    //       )
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Container(
                          //   height: MediaQuery.of(context).size.height * 0.26,
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       Padding(
                          //         padding: const EdgeInsets.symmetric(
                          //             horizontal: 15, vertical: 10),
                          //         child: Text(
                          //           "Your Live Rooms",
                          //           textScaleFactor: 1.0,
                          //           style: TextStyle(
                          //               fontSize: SizeConfig.safeBlockHorizontal * 5),
                          //         ),
                          //       ),
                          //       Container(
                          //         height: MediaQuery.of(context).size.height * 0.2,
                          //         child: ListView(
                          //           scrollDirection: Axis.horizontal,
                          //           children: [
                          //             Padding(
                          //               padding:
                          //                   const EdgeInsets.fromLTRB(15, 8, 0, 8),
                          //               child: Column(
                          //                 children: [
                          //                   Container(
                          //                     decoration: BoxDecoration(
                          //                         color: themeProvider
                          //                             .isLightTheme ==
                          //                             true
                          //                             ? Color(0xffE8E8E8)
                          //                             : Color(0xff222222),
                          //                         borderRadius:
                          //                             BorderRadius.circular(10)),
                          //                     width:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     height:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     child: Icon(Icons.add),
                          //                   ),
                          //                   Padding(
                          //                     padding: const EdgeInsets.all(8.0),
                          //                     child: Text("Add a podcast"),
                          //                   )
                          //                 ],
                          //               ),
                          //             ),
                          //             Padding(
                          //               padding:
                          //                   const EdgeInsets.fromLTRB(15, 8, 0, 8),
                          //               child: Column(
                          //                 children: [
                          //                   Container(
                          //                     decoration: BoxDecoration(
                          //                         color: Color(0xff222222),
                          //                         borderRadius:
                          //                             BorderRadius.circular(10)),
                          //                     width:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     height:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     child: Icon(Icons.add),
                          //                   ),
                          //                   Padding(
                          //                     padding: const EdgeInsets.all(8.0),
                          //                     child: Text("Add a podcast"),
                          //                   )
                          //                 ],
                          //               ),
                          //             ),
                          //             Padding(
                          //               padding:
                          //                   const EdgeInsets.fromLTRB(15, 8, 0, 8),
                          //               child: Column(
                          //                 children: [
                          //                   Container(
                          //                     decoration: BoxDecoration(
                          //                         color: Color(0xff222222),
                          //                         borderRadius:
                          //                             BorderRadius.circular(10)),
                          //                     width:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     height:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     child: Icon(Icons.add),
                          //                   ),
                          //                   Padding(
                          //                     padding: const EdgeInsets.all(8.0),
                          //                     child: Text("Add a podcast"),
                          //                   )
                          //                 ],
                          //               ),
                          //             ),
                          //             Padding(
                          //               padding:
                          //                   const EdgeInsets.fromLTRB(15, 8, 0, 8),
                          //               child: Column(
                          //                 children: [
                          //                   Container(
                          //                     decoration: BoxDecoration(
                          //                         color: themeProvider
                          //                             .isLightTheme ==
                          //                             true
                          //                             ? Color(0xffE8E8E8)
                          //                             : Color(0xff222222),
                          //                         borderRadius:
                          //                             BorderRadius.circular(10)),
                          //                     width:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     height:
                          //                         MediaQuery.of(context).size.width /
                          //                             4.5,
                          //                     child: Icon(Icons.add),
                          //                   ),
                          //                   Padding(
                          //                     padding: const EdgeInsets.all(8.0),
                          //                     child: Text("Add a podcast"),
                          //                   )
                          //                 ],
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => ReferralProgram()));
                            },
                            title: Text(
                              "Invite ",
                              textScaleFactor: mediaQueryData.textScaleFactor
                                  .clamp(0.5, 1.5)
                                  .toDouble(),
                              style: TextStyle(
                                  //  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.safeBlockHorizontal * 4),
                            ),
                            trailing:
                                Icon(Icons.arrow_forward_ios_rounded, size: 15),
                            subtitle: Text(
                              "Invite friends and earn rewards",
                              textScaleFactor: mediaQueryData.textScaleFactor
                                  .clamp(0.5, 0.8)
                                  .toDouble(),
                              style: TextStyle(
                                  //       color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 3.4),
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => Rewards()));
                            },
                            title: Text(
                              "Your rewards",
                              textScaleFactor: mediaQueryData.textScaleFactor
                                  .clamp(0.5, 1.5)
                                  .toDouble(),
                              style: TextStyle(
                                  //  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.safeBlockHorizontal * 4),
                            ),
                            trailing:
                                Icon(Icons.arrow_forward_ios_rounded, size: 15),
                            subtitle: Text(
                              "Check your rewards",
                              textScaleFactor: mediaQueryData.textScaleFactor
                                  .clamp(0.5, 0.8)
                                  .toDouble(),
                              style: TextStyle(
                                  //       color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 3.4),
                            ),
                          ),

                          // Padding(
                          //   padding: const EdgeInsets.all(15.0),
                          //   child: InkWell(
                          //     onTap: () {
                          //       Navigator.push(
                          //           context,
                          //           CupertinoPageRoute(
                          //               builder: (context) =>
                          //                   ReferralProgram()));
                          //     },
                          //     child: Container(
                          //       child: Row(
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Column(
                          //             crossAxisAlignment:
                          //                 CrossAxisAlignment.start,
                          //             children: <Widget>[
                          //               Text(
                          //                 "Invite ",
                          //                 textScaleFactor: mediaQueryData
                          //                     .textScaleFactor
                          //                     .clamp(0.5, 1.5)
                          //                     .toDouble(),
                          //                 style: TextStyle(
                          //                     //  color: Colors.white,
                          //                     fontWeight: FontWeight.w700,
                          //                     fontSize: SizeConfig
                          //                             .safeBlockHorizontal *
                          //                         4),
                          //               ),
                          //               SizedBox(height: 5),
                          //               Text(
                          //                 "Invite friends and earn rewards",
                          //                 textScaleFactor: mediaQueryData
                          //                     .textScaleFactor
                          //                     .clamp(0.5, 0.8)
                          //                     .toDouble(),
                          //                 style: TextStyle(
                          //                     //       color: Colors.white70,
                          //                     fontWeight: FontWeight.w300,
                          //                     fontSize: SizeConfig
                          //                             .safeBlockHorizontal *
                          //                         3.4),
                          //               )
                          //             ],
                          //           ),
                          //           Icon(Icons.arrow_forward_ios_rounded,
                          //               size: 15)
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // ReferralDashboard(),
                          // Padding(
                          //   padding: const EdgeInsets.all(15.0),
                          //   child: InkWell(
                          //     onTap: () {
                          //       Navigator.push(
                          //           context,
                          //           CupertinoPageRoute(
                          //               builder: (context) => Rewards()));
                          //     },
                          //     child: Container(
                          //       child: Row(
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Column(
                          //             crossAxisAlignment:
                          //                 CrossAxisAlignment.start,
                          //             children: <Widget>[
                          //               Text(
                          //                 "Your rewards",
                          //                 textScaleFactor: mediaQueryData
                          //                     .textScaleFactor
                          //                     .clamp(0.5, 1.5)
                          //                     .toDouble(),
                          //                 style: TextStyle(
                          //                     //  color: Colors.white,
                          //                     fontWeight: FontWeight.w700,
                          //                     fontSize: SizeConfig
                          //                             .safeBlockHorizontal *
                          //                         4),
                          //               ),
                          //               SizedBox(height: 5),
                          //               Text(
                          //                 "Check your rewards",
                          //                 textScaleFactor: mediaQueryData
                          //                     .textScaleFactor
                          //                     .clamp(0.5, 0.8)
                          //                     .toDouble(),
                          //                 style: TextStyle(
                          //                     //       color: Colors.white70,
                          //                     fontWeight: FontWeight.w300,
                          //                     fontSize: SizeConfig
                          //                             .safeBlockHorizontal *
                          //                         3.4),
                          //               )
                          //             ],
                          //           ),
                          //           Icon(Icons.arrow_forward_ios_rounded,
                          //               size: 15)
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
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
                              child: Container(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          "Your wallet",
                                          textScaleFactor: mediaQueryData
                                              .textScaleFactor
                                              .clamp(0.5, 1.5)
                                              .toDouble(),
                                          style: TextStyle(
                                              //  color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Hive wallet",
                                          textScaleFactor: mediaQueryData
                                              .textScaleFactor
                                              .clamp(0.5, 0.8)
                                              .toDouble(),
                                          style: TextStyle(
                                              //       color: Colors.white70,
                                              fontWeight: FontWeight.w300,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3.4),
                                        )
                                      ],
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 15)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.all(15.0),
                          //   child: GestureDetector(
                          //     onTap: () {
                          //       Navigator.push(context,
                          //           CupertinoPageRoute(widget: Settings()));
                          //     },
                          //     child: Container(
                          //       child: Row(
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Column(
                          //             crossAxisAlignment:
                          //                 CrossAxisAlignment.start,
                          //             children: <Widget>[
                          //               Text(
                          //                 "Setting",
                          //                 textScaleFactor: mediaQueryData
                          //                     .textScaleFactor
                          //                     .clamp(0.5, 1.5)
                          //                     .toDouble(),
                          //                 style: TextStyle(
                          //                     //  color: Colors.white,
                          //                     fontWeight: FontWeight.w700,
                          //                     fontSize: SizeConfig
                          //                             .safeBlockHorizontal *
                          //                         4),
                          //               ),
                          //               SizedBox(height: 5),
                          //               Text(
                          //                 "Categories , Languages",
                          //                 textScaleFactor: mediaQueryData
                          //                     .textScaleFactor
                          //                     .clamp(0.5, 0.8)
                          //                     .toDouble(),
                          //                 style: TextStyle(
                          //                     //       color: Colors.white70,
                          //                     fontWeight: FontWeight.w300,
                          //                     fontSize: SizeConfig
                          //                             .safeBlockHorizontal *
                          //                         3.4),
                          //               )
                          //             ],
                          //           ),
                          //           Icon(
                          //             Icons.arrow_forward_ios_rounded,
                          //             size: 15,
                          //           )
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ]),
                      ),
              ),
            ));
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
