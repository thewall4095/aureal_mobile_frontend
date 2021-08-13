import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auditory/Accounts/HiveAccount.dart';
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
import '../RouteAnimation.dart';
import 'Bio.dart';
import 'Downloads.dart';
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
        "https://play.google.com/store/apps/details?id=com.titandlt.auditory";

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
          data = jsonDecode(response.body)['users'];
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
        isProfileLoading = false;
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
    //   //       MaterialPageRoute(
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
                    : NestedScrollView(
                        headerSliverBuilder:
                            (BuildContext context, bool innerBoxIsScrolled) {
                          return [
                            SliverAppBar(
                              pinned: true,
                              floating: true,
                              actions: [
                                IconButton(onPressed: (){
                              Navigator.push(context,
                              SlideRightRoute(widget: Settings()));

                                }, icon: Icon(Icons.settings))
                              ],
                              expandedHeight:
                                  MediaQuery.of(context).size.height / 2.5,
                              flexibleSpace: FlexibleSpaceBar(
                                  background: Container(
                                    child: Stack(
                                alignment: AlignmentDirectional.bottomCenter,
                                children: [
                                    Positioned(
                                      top: MediaQuery.of(context).size.height/7,
                                      child: Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                new BoxShadow(
                                                  color: Colors
                                                      .black54
                                                      .withOpacity(
                                                      0.2),
                                                  blurRadius: 10.0,
                                                ),
                                              ],
                                              color: themeProvider
                                                  .isLightTheme ==
                                                  true
                                                  ? Colors.white
                                                  : Color(0xff222222),
                                          ),
                                          height:
                                              MediaQuery.of(context).size.height /
                                                  3.5,
                                          width: MediaQuery.of(context).size.width /
                                              1.2,
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height:MediaQuery.of(context).size.height/40,  // height: 55,
                                                ),
                                                Text(
                                                  "$userName",
                                                  textScaleFactor: 1.0,
                                                  style: TextStyle(
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          7),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: prefs.getString(
                                                      'HiveUserName') ==
                                                      null
                                                      ? ShaderMask(
                                                    shaderCallback: (Rect bounds) {
                                                      return LinearGradient(
                                                          colors: [
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
                                                // Padding(
                                                //   padding:
                                                //       const EdgeInsets.symmetric(
                                                //           vertical: 10),
                                                //   child: Text(
                                                //     "$bio",
                                                //     textScaleFactor: 1.0,
                                                //   ),
                                                // ),

                                                Container(
                                                  // decoration: BoxDecoration(
                                                  //     boxShadow: [
                                                  //       new BoxShadow(
                                                  //         color: Colors
                                                  //             .black54
                                                  //             .withOpacity(
                                                  //             0.2),
                                                  //         blurRadius: 10.0,
                                                  //       ),
                                                  //     ],
                                                  //     color: themeProvider
                                                  //         .isLightTheme ==
                                                  //         true
                                                  //         ? Colors.white
                                                  //         : Color(0xff222222),
                                                  //     borderRadius:
                                                  //     BorderRadius
                                                  //         .circular(15),
                                                  //   ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      data['instagram'] == null ||
                                                              data['instagram'] ==
                                                                  ''
                                                          ? SizedBox()
                                                          : IconButton(
                                                              icon: Icon(
                                                                  FontAwesomeIcons
                                                                      .instagram),
                                                              iconSize: 15,
                                                              onPressed: () {
                                                                launcher.launchInBrowser(
                                                                    data[
                                                                        'instagram'],
                                                                    );
                                                              },
                                                            ),
                                                      data['twitter'] == null ||
                                                              data['twitter'] ==
                                                                  ''
                                                          ? SizedBox()
                                                          : IconButton(
                                                              icon: Icon(
                                                                  FontAwesomeIcons
                                                                      .twitter),
                                                        iconSize: 15,
                                                              onPressed: () {
                                                                launcher.launchInBrowser(
                                                                    data[
                                                                        'twitter']);
                                                              },
                                                            ),
                                                      data['linkedin'] == null ||
                                                              data['linkedin'] ==
                                                                  ''
                                                          ? SizedBox()
                                                          : IconButton(
                                                              icon: Icon(
                                                                  FontAwesomeIcons
                                                                      .linkedin),
                                                        iconSize: 15,
                                                              onPressed: () {
                                                                launcher.launchInBrowser(
                                                                    data[
                                                                        'linkedin']);
                                                              },
                                                            ),
                                                      data['website'] == null ||
                                                              data['website'] ==
                                                                  ''
                                                          ? SizedBox()
                                                          : IconButton(
                                                              icon: Icon(
                                                                  FontAwesomeIcons
                                                                      .externalLinkSquareAlt),
                                                        iconSize: 15,
                                                              onPressed: () {
                                                                launcher.launchInBrowser(
                                                                    data[
                                                                        'website']);
                                                              },
                                                            )
                                                    ],
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: MediaQuery.of(context).size.height/20,
                                      left: MediaQuery.of(context).size.height/6,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(context,
                                              MaterialPageRoute(
                                                  builder: (context) {
                                            return Bio();
                                          }));
                                        },
                                        child: CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                            displayPicture == null
                                                ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                                : displayPicture,
                                          ),
                                          radius: 55,
                                        ),
                                      ),
                                    )
                                    // Container(
                                    //   width: MediaQuery.of(context).size.width * 0.65,
                                    //   height:
                                    //       MediaQuery.of(context).size.height * 0.4,
                                    //   decoration: BoxDecoration(
                                    //       image: DecorationImage(
                                    //           image: AssetImage(
                                    //               'assets/images/ProfileCircle.png'),
                                    //           fit: BoxFit.contain)),
                                    // ),
                                    // Container(
                                    //   child: Padding(
                                    //     padding: const EdgeInsets.symmetric(
                                    //         horizontal: 15),
                                    //     child: Column(
                                    //       crossAxisAlignment:
                                    //           CrossAxisAlignment.start,
                                    //       children: [
                                    //         SizedBox(
                                    //           height:
                                    //               MediaQuery.of(context).size.height /
                                    //                   9,
                                    //         ),
                                    //         // GestureDetector(
                                    //         //   onTap: () {
                                    //         //     Navigator.push(context,
                                    //         //         MaterialPageRoute(builder: (context) {
                                    //         //       return Bio();
                                    //         //     }));
                                    //         //   },
                                    //         //   child: Container(
                                    //         //       height:
                                    //         //           MediaQuery.of(context).size.width / 4,
                                    //         //       width:
                                    //         //           MediaQuery.of(context).size.width / 4,
                                    //         //       child: CachedNetworkImage(
                                    //         //         maxHeightDiskCache: MediaQuery.of(context)
                                    //         //             .size
                                    //         //             .height
                                    //         //             .toInt(),
                                    //         //         imageBuilder: (context, imageProvider) {
                                    //         //           return Container(
                                    //         //             decoration: BoxDecoration(
                                    //         //               shape: BoxShape.circle,
                                    //         //               //   borderRadius: BorderRadius.circular(10),
                                    //         //               image: DecorationImage(
                                    //         //                   image: imageProvider,
                                    //         //                   fit: BoxFit.cover),
                                    //         //             ),
                                    //         //             height:
                                    //         //                 MediaQuery.of(context).size.width,
                                    //         //             width:
                                    //         //                 MediaQuery.of(context).size.width,
                                    //         //           );
                                    //         //         },
                                    //         //         imageUrl: displayPicture == null
                                    //         //             ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                    //         //             : displayPicture,
                                    //         //         fit: BoxFit.cover,
                                    //         //         memCacheHeight: MediaQuery.of(context)
                                    //         //             .size
                                    //         //             .height
                                    //         //             .floor(),
                                    //         //         errorWidget: (context, url, error) =>
                                    //         //             Icon(Icons.error),
                                    //         //       )),
                                    //         // ),
                                    //         GestureDetector(
                                    //           onTap: () {
                                    //             Navigator.push(context,
                                    //                 MaterialPageRoute(
                                    //                     builder: (context) {
                                    //               return Bio();
                                    //             }));
                                    //           },
                                    //           child: CircleAvatar(
                                    //             backgroundColor: Colors.blue,
                                    //             backgroundImage:
                                    //                 CachedNetworkImageProvider(
                                    //               displayPicture == null
                                    //                   ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                                    //                   : displayPicture,
                                    //             ),
                                    //             radius: 55,
                                    //           ),
                                    //         ),
                                    //         SizedBox(
                                    //           height: 30,
                                    //         ),
                                    //         Text(
                                    //           "$userName",
                                    //           textScaleFactor: 1.0,
                                    //           style: TextStyle(
                                    //               fontSize:
                                    //                   SizeConfig.safeBlockHorizontal *
                                    //                       7),
                                    //         ),
                                    //         Padding(
                                    //           padding: const EdgeInsets.symmetric(
                                    //               vertical: 10),
                                    //           child: prefs.getString(
                                    //                       'HiveUserName') ==
                                    //                   null
                                    //               ? ShaderMask(
                                    //                   shaderCallback: (Rect bounds) {
                                    //                     return LinearGradient(
                                    //                         colors: [
                                    //                           Color(0xff52BFF9),
                                    //                           Color(0xff6048F6)
                                    //                         ]).createShader(bounds);
                                    //                   },
                                    //                   child: InkWell(
                                    //                     onTap: () {
                                    //                       showBarModalBottomSheet(
                                    //                           context: context,
                                    //                           builder: (context) {
                                    //                             return HiveDetails();
                                    //                           });
                                    //                     },
                                    //                     child: Text(
                                    //                       "Connect Your Hive Account",
                                    //                       textScaleFactor: 1.0,
                                    //                     ),
                                    //                   ),
                                    //                 )
                                    //               : Text(
                                    //                   '@${prefs.getString('HiveUserName')}',
                                    //                   textScaleFactor: 1.0,
                                    //                   style: TextStyle(
                                    //                       color: Color(0xff777777)),
                                    //                 ),
                                    //         ),
                                    //         Padding(
                                    //           padding: const EdgeInsets.symmetric(
                                    //               vertical: 10),
                                    //           child: Text(
                                    //             "$bio",
                                    //             textScaleFactor: 1.0,
                                    //           ),
                                    //         ),
                                    //
                                    //         Padding(
                                    //           padding: const EdgeInsets.symmetric(
                                    //               vertical: 10),
                                    //           child: Row(
                                    //             children: [
                                    //               data['instagram'] == null ||
                                    //                       data['instagram'] == 'null'
                                    //                   ? SizedBox()
                                    //                   : IconButton(
                                    //                       icon: Icon(FontAwesomeIcons
                                    //                           .instagram),
                                    //                       onPressed: () {
                                    //                         launcher.launchInBrowser(
                                    //                             data['instagram']);
                                    //                       },
                                    //                     ),
                                    //               data['twitter'] == null ||
                                    //                       data['twitter'] == 'null'
                                    //                   ? SizedBox()
                                    //                   : IconButton(
                                    //                       icon: Icon(FontAwesomeIcons
                                    //                           .twitter),
                                    //                       onPressed: () {
                                    //                         launcher.launchInBrowser(
                                    //                             data['twitter']);
                                    //                       },
                                    //                     ),
                                    //               data['linkedin'] == null ||
                                    //                       data['linkedin'] == 'null'
                                    //                   ? SizedBox()
                                    //                   : IconButton(
                                    //                       icon: Icon(FontAwesomeIcons
                                    //                           .linkedin),
                                    //                       onPressed: () {
                                    //                         launcher.launchInBrowser(
                                    //                             data['linkedin']);
                                    //                       },
                                    //                     ),
                                    //               data['website'] == null ||
                                    //                       data['website'] == 'null'
                                    //                   ? SizedBox()
                                    //                   : IconButton(
                                    //                       icon: Icon(FontAwesomeIcons
                                    //                           .externalLinkSquareAlt),
                                    //                       onPressed: () {
                                    //                         launcher.launchInBrowser(
                                    //                             data['website']);
                                    //                       },
                                    //                     )
                                    //             ],
                                    //           ),
                                    //         ),
                                    //         // Padding(
                                    //         //   padding: const EdgeInsets.symmetric(
                                    //         //       vertical: 10),
                                    //         //   child: Row(
                                    //         //     children: [
                                    //         //       Padding(
                                    //         //         padding: const EdgeInsets.only(
                                    //         //             right: 10),
                                    //         //         child: Container(
                                    //         //           decoration: BoxDecoration(
                                    //         //               border: Border.all(
                                    //         //                   color:
                                    //         //                       Color(0xff777777)),
                                    //         //               borderRadius:
                                    //         //                   BorderRadius.circular(
                                    //         //                       20)),
                                    //         //           child: Padding(
                                    //         //             padding: const EdgeInsets
                                    //         //                     .symmetric(
                                    //         //                 horizontal: 10,
                                    //         //                 vertical: 8),
                                    //         //             child: Text("232 Following"),
                                    //         //           ),
                                    //         //         ),
                                    //         //       ),
                                    //         //       Padding(
                                    //         //         padding: const EdgeInsets.only(
                                    //         //             right: 6),
                                    //         //         child: Container(
                                    //         //           decoration: BoxDecoration(
                                    //         //               border: Border.all(
                                    //         //                   color:
                                    //         //                       Color(0xff777777)),
                                    //         //               borderRadius:
                                    //         //                   BorderRadius.circular(
                                    //         //                       20)),
                                    //         //           child: Padding(
                                    //         //             padding: const EdgeInsets
                                    //         //                     .symmetric(
                                    //         //                 horizontal: 10,
                                    //         //                 vertical: 8),
                                    //         //             child: Text("232 Followers"),
                                    //         //           ),
                                    //         //         ),
                                    //         //       ),
                                    //         //     ],
                                    //         //   ),
                                    //         // )
                                    //       ],
                                    //     ),
                                    //   ),
                                    // )
                                ],
                              ),
                                  )),
                            ),
                            // SliverList(
                            //   delegate: SliverChildListDelegate([
                            //
                            //     // Padding(
                            //     //   padding: const EdgeInsets.symmetric(
                            //     //       horizontal: 15, vertical: 20),
                            //     //   child: Column(
                            //     //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     //     children: [
                            //     //       Divider(
                            //     //         color: kSecondaryColor,
                            //     //       ),
                            //     //       Padding(
                            //     //         padding: const EdgeInsets.symmetric(
                            //     //             horizontal: 10),
                            //     //         child: Column(
                            //     //           crossAxisAlignment:
                            //     //               CrossAxisAlignment.start,
                            //     //           children: [
                            //     //             // Container(
                            //     //             //   width: double.infinity,
                            //     //             //   decoration: BoxDecoration(
                            //     //             //       border: Border(
                            //     //             //           bottom:
                            //     //             //               BorderSide(color: kSecondaryColor))),
                            //     //             //   child: Padding(
                            //     //             //     padding: const EdgeInsets.symmetric(vertical: 15),
                            //     //             //     child: InkWell(
                            //     //             //       onTap: () {
                            //     //             //         Navigator.push(context,
                            //     //             //             MaterialPageRoute(builder: (context) {
                            //     //             //           return CreateCommunity();
                            //     //             //         })).then((value) async {
                            //     //             //           await _pullRefreshEpisodes();
                            //     //             //         });
                            //     //             //       },
                            //     //             //       child: Text(
                            //     //             //         "Add your community",
                            //     //             //         textScaleFactor: mediaQueryData.textScaleFactor
                            //     //             //             .clamp(0.2, 1)
                            //     //             //             .toDouble(),
                            //     //             //         style: TextStyle(
                            //     //             //           fontSize: SizeConfig.safeBlockHorizontal * 4,
                            //     //             //           //      color: Color(0xffe8e8e8),
                            //     //             //         ),
                            //     //             //       ),
                            //     //             //     ),
                            //     //             //   ),
                            //     //             // ),
                            //     //             // Container(
                            //     //             //   width: double.infinity,
                            //     //             //   decoration: BoxDecoration(
                            //     //             //     border: Border(
                            //     //             //       bottom: BorderSide(
                            //     //             //         color: kSecondaryColor,
                            //     //             //       ),
                            //     //             //     ),
                            //     //             //   ),
                            //     //             //   child: Padding(
                            //     //             //     padding: const EdgeInsets.symmetric(
                            //     //             //         vertical: 15),
                            //     //             //     child: InkWell(
                            //     //             //       onTap: () {
                            //     //             //         Navigator.push(context,
                            //     //             //             MaterialPageRoute(
                            //     //             //                 builder: (context) {
                            //     //             //           return Rewards();
                            //     //             //         }));
                            //     //             //       },
                            //     //             //       child: Text(
                            //     //             //         "Your rewards",
                            //     //             //         textScaleFactor: 1.0,
                            //     //             //         style: TextStyle(
                            //     //             //           //    color: Color(0xffe8e8e8),
                            //     //             //           fontSize: SizeConfig
                            //     //             //                   .safeBlockHorizontal *
                            //     //             //               4,
                            //     //             //         ),
                            //     //             //       ),
                            //     //             //     ),
                            //     //             //   ),
                            //     //             // ),
                            //     //             // Container(
                            //     //             //   width: double.infinity,
                            //     //             //   decoration: BoxDecoration(
                            //     //             //     border: Border(
                            //     //             //       bottom: BorderSide(
                            //     //             //         color: kSecondaryColor,
                            //     //             //       ),
                            //     //             //     ),
                            //     //             //   ),
                            //     //             //   child: Padding(
                            //     //             //     padding: const EdgeInsets.symmetric(
                            //     //             //         vertical: 15),
                            //     //             //     child: InkWell(
                            //     //             //       onTap: () {
                            //     //             //         showBarModalBottomSheet(
                            //     //             //             context: context,
                            //     //             //             builder: (context) {
                            //     //             //               return DownloadPage();
                            //     //             //             });
                            //     //             //       },
                            //     //             //       child: Text(
                            //     //             //         "Library",
                            //     //             //         textScaleFactor: 1.0,
                            //     //             //         style: TextStyle(
                            //     //             //           //        color: Color(0xffe8e8e8),
                            //     //             //           fontSize: SizeConfig
                            //     //             //                   .safeBlockHorizontal *
                            //     //             //               4,
                            //     //             //         ),
                            //     //             //       ),
                            //     //             //     ),
                            //     //             //   ),
                            //     //             // ),
                            //     //             Container(
                            //     //               width: double.infinity,
                            //     //               decoration: BoxDecoration(
                            //     //                 border: Border(
                            //     //                   bottom: BorderSide(
                            //     //                     color: kSecondaryColor,
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //               child: Padding(
                            //     //                 padding: const EdgeInsets.symmetric(
                            //     //                     vertical: 15),
                            //     //                 child: InkWell(
                            //     //                   onTap: () {
                            //     //                     showBarModalBottomSheet(
                            //     //                         context: context,
                            //     //                         builder: (context) {
                            //     //                           return Container(
                            //     //                             height: MediaQuery.of(
                            //     //                                     context)
                            //     //                                 .size
                            //     //                                 .height,
                            //     //                             // child: InAppWebView(
                            //     //                             //     gestureRecognizers:
                            //     //                             //         gestureRecognizers,
                            //     //                             //     initialFile:
                            //     //                             //         'https://wallet.hive.blog/@${prefs.getString('HiveUserName')}'),
                            //     //                             child: WebView(
                            //     //                               gestureRecognizers:
                            //     //                                   Set()
                            //     //                                     ..add(
                            //     //                                       Factory<
                            //     //                                           VerticalDragGestureRecognizer>(
                            //     //                                         () =>
                            //     //                                             VerticalDragGestureRecognizer(),
                            //     //                                       ), // or null
                            //     //                                     ),
                            //     //                               gestureNavigationEnabled:
                            //     //                                   true,
                            //     //                               javascriptMode:
                            //     //                                   JavascriptMode
                            //     //                                       .unrestricted,
                            //     //                               initialUrl:
                            //     //                                   'https://wallet.hive.blog/@${prefs.getString('HiveUserName')}',
                            //     //                             ),
                            //     //                           );
                            //     //                         });
                            //     //                   },
                            //     //                   child: Text(
                            //     //                     "Your wallet",
                            //     //                     textScaleFactor: 1.0,
                            //     //                     style: TextStyle(
                            //     //                       //        color: Color(0xffe8e8e8),
                            //     //                       fontSize: SizeConfig
                            //     //                               .safeBlockHorizontal *
                            //     //                           4,
                            //     //                     ),
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //             ),
                            //     //             Container(
                            //     //               width: double.infinity,
                            //     //               decoration: BoxDecoration(
                            //     //                 border: Border(
                            //     //                   bottom: BorderSide(
                            //     //                     color: kSecondaryColor,
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //               child: Padding(
                            //     //                 padding: const EdgeInsets.symmetric(
                            //     //                     vertical: 15),
                            //     //                 child: InkWell(
                            //     //                   onTap: () {
                            //     //                     hiveUserName == null
                            //     //                         ? Navigator
                            //     //                             .pushNamedAndRemoveUntil(
                            //     //                                 context,
                            //     //                                 HiveAccount.id,
                            //     //                                 (route) => false)
                            //     //                         : print('nothing');
                            //     //                   },
                            //     //                   child: Text(
                            //     //                     hiveUserName != null
                            //     //                         ? "Connected with your Hive Account ( @${hiveUserName} )"
                            //     //                         : "Connect your Hive Account",
                            //     //                     textScaleFactor: 1.0,
                            //     //                     style: TextStyle(
                            //     //                       //     color: Color(0xffe8e8e8),
                            //     //                       fontSize: SizeConfig
                            //     //                               .safeBlockHorizontal *
                            //     //                           4,
                            //     //                     ),
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //             ),
                            //     //             Container(
                            //     //               width: double.infinity,
                            //     //               decoration: BoxDecoration(
                            //     //                 border: Border(
                            //     //                   bottom: BorderSide(
                            //     //                     color: kSecondaryColor,
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //               child: Padding(
                            //     //                 padding: const EdgeInsets.symmetric(
                            //     //                     vertical: 15),
                            //     //
                            //     //                 child: InkWell(
                            //     //                   onTap: () {
                            //     //                     showBarModalBottomSheet(
                            //     //                         context: context,
                            //     //                         builder: (context) {
                            //     //                           return Settings();
                            //     //                         });
                            //     //                   },
                            //     //                   child: Text(
                            //     //                     "Setting",
                            //     //                     textScaleFactor: 1.0,
                            //     //                     style: TextStyle(
                            //     //                       //  color: Color(0xffe8e8e8),
                            //     //                       fontSize: SizeConfig
                            //     //                               .safeBlockHorizontal *
                            //     //                           4,
                            //     //                     ),
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //             ),
                            //     //             Container(
                            //     //               width: double.infinity,
                            //     //               decoration: BoxDecoration(
                            //     //                 border: Border(
                            //     //                   bottom: BorderSide(
                            //     //                     color: kSecondaryColor,
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //               child: Padding(
                            //     //                 padding: const EdgeInsets.symmetric(
                            //     //                     vertical: 15),
                            //     //                 child: InkWell(
                            //     //                   onTap: () {
                            //     //                     logout();
                            //     //                     prefs.clear();
                            //     //                   },
                            //     //                   child: Text(
                            //     //                     "Sign Out",
                            //     //                     textScaleFactor: 1.0,
                            //     //                     style: TextStyle(
                            //     //                       //    color: Color(0xffe8e8e8),
                            //     //                       fontSize: SizeConfig
                            //     //                               .safeBlockHorizontal *
                            //     //                           4,
                            //     //                     ),
                            //     //                   ),
                            //     //                 ),
                            //     //               ),
                            //     //             ),
                            //     //             // SignInButton(Buttons.Google,
                            //     //             //     text: 'Sign Out of Google',
                            //     //             //     onPressed: () => authBloc.logout())
                            //     //           ],
                            //     //         ),
                            //     //       ),
                            //     //     ],
                            //     //   ),
                            //     // )
                            //   ]),
                            //  ),
                          ];
                        },
                        body: RefreshIndicator(
                          onRefresh: _pullRefresh,
                          child: Container(
                            child: ListView(children: [
                              Container(
                                height: MediaQuery.of(context).size.height * 0.26,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Your Podcasts",
                                        textScaleFactor: 1.0,
                                        style: TextStyle(
                                            fontSize:
                                                SizeConfig.safeBlockHorizontal *
                                                    5),
                                      ),
                                      Container(
                                        height: MediaQuery.of(context).size.height *
                                            0.2,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: [
                                            for (var v in podcastList)
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(
                                                    15, 8, 0, 8),
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(context,
                                                        MaterialPageRoute(
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
                                                                color: Colors
                                                                    .black54
                                                                    .withOpacity(
                                                                        0.2),
                                                                blurRadius: 10.0,
                                                              ),
                                                            ],
                                                            color: themeProvider
                                                                        .isLightTheme ==
                                                                    true
                                                                ? Colors.white
                                                                : Color(0xff222222),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(15),
                                                          ),
                                                          width:
                                                              MediaQuery.of(context)
                                                                      .size
                                                                      .width /
                                                                  4.5,
                                                          height:
                                                              MediaQuery.of(context)
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
                                                                  .symmetric(
                                                              vertical: 8),
                                                          child:
                                                              Text("${v['name']}"),
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
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
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
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                            horizontal: 5),
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
                                ),
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
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        SlideRightRoute(
                                            widget: ReferralProgram()));
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
                                              "Invite ",
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
                                              "Invite friends and earn rewards",
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
                              // ReferralDashboard(),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(context,
                                        SlideRightRoute(widget: Rewards()));
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
                                              "Your rewards",
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
                                              "Check your rewards",
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
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: InkWell(
                                  onTap: () {
                                    showBarModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return Container(
                                            height: MediaQuery.of(context)
                                                .size
                                                .height,
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
                              //           SlideRightRoute(widget: Settings()));
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
                        // child: Container(
                        //   height: MediaQuery.of(context).size.height,
                        //   child: ListView(children: [
                        //     Container(
                        //       child: Padding(
                        //         padding: const EdgeInsets.all(10),
                        //         child: Row(
                        //           children: [
                        //             GestureDetector(
                        //               onTap: () {
                        //                 Navigator.push(context,
                        //                     MaterialPageRoute(builder: (context) {
                        //                   return Bio();
                        //                 }));
                        //               },
                        //               child: Container(
                        //                   height: MediaQuery.of(context).size.width / 5,
                        //                   width: MediaQuery.of(context).size.width / 5,
                        //                   child: CachedNetworkImage(
                        //                     maxHeightDiskCache: MediaQuery.of(context)
                        //                         .size
                        //                         .height
                        //                         .toInt(),
                        //                     imageBuilder: (context, imageProvider) {
                        //                       return Container(
                        //                         decoration: BoxDecoration(
                        //                           shape: BoxShape.circle,
                        //                           //   borderRadius: BorderRadius.circular(10),
                        //                           image: DecorationImage(
                        //                               image: imageProvider,
                        //                               fit: BoxFit.cover),
                        //                         ),
                        //                         height:
                        //                             MediaQuery.of(context).size.width,
                        //                         width:
                        //                             MediaQuery.of(context).size.width,
                        //                       );
                        //                     },
                        //                     imageUrl: displayPicture == null
                        //                         ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                        //                         : displayPicture,
                        //                     fit: BoxFit.cover,
                        //                     memCacheHeight: MediaQuery.of(context)
                        //                         .size
                        //                         .height
                        //                         .floor(),
                        //                     errorWidget: (context, url, error) =>
                        //                         Icon(Icons.error),
                        //                   )),
                        //             ),
                        //             SizedBox(
                        //               height: 20,
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //     ),
                        //     Padding(
                        //         padding: const EdgeInsets.all(15),
                        //         child: Column(
                        //             crossAxisAlignment: CrossAxisAlignment.start,
                        //             children: [
                        //               Padding(
                        //                 padding: const EdgeInsets.only(bottom: 10),
                        //                 child: GestureDetector(
                        //                   onTap: () {},
                        //                   child: Text(
                        //                     "$userName",
                        //                     //'$fullName',
                        //                     textScaleFactor: mediaQueryData
                        //                         .textScaleFactor
                        //                         .clamp(0.2, 1.3)
                        //                         .toDouble(),
                        //                     style: TextStyle(
                        //                         //         color: Color(0xffe8e8e8),
                        //                         fontSize:
                        //                             SizeConfig.safeBlockHorizontal *
                        //                                 6.5,
                        //                         fontWeight: FontWeight.bold),
                        //                   ),
                        //                 ),
                        //               ),
                        //               Column(
                        //                   crossAxisAlignment: CrossAxisAlignment.start,
                        //                   children: [
                        //                     Padding(
                        //                       padding:
                        //                           const EdgeInsets.only(bottom: 10),
                        //                       child: GestureDetector(
                        //                         onTap: () {},
                        //                         child: Text(
                        //                           "@$userName",
                        //                           textScaleFactor: mediaQueryData
                        //                               .textScaleFactor
                        //                               .clamp(0.2, 1.0)
                        //                               .toDouble(),
                        //                           style: TextStyle(
                        //                             //         color: Color(0xffe8e8e8),
                        //                             fontSize:
                        //                                 SizeConfig.safeBlockHorizontal *
                        //                                     3,
                        //                           ),
                        //                         ),
                        //                       ),
                        //                     ),
                        //
                        //                     Column(
                        //                       crossAxisAlignment:
                        //                           CrossAxisAlignment.start,
                        //                       children: [
                        //                         Padding(
                        //                           padding:
                        //                               const EdgeInsets.only(bottom: 20),
                        //                           child: Text(
                        //                             'A product designer in search of all things blissful',
                        //                             textScaleFactor: mediaQueryData
                        //                                 .textScaleFactor
                        //                                 .clamp(0.2, 1)
                        //                                 .toDouble(),
                        //                             style: TextStyle(
                        //                                 //     color: Color(0xffe8e8e8),
                        //                                 fontSize: SizeConfig
                        //                                         .safeBlockHorizontal *
                        //                                     4),
                        //                           ),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                     Column(
                        //                       children: [
                        //                         Container(
                        //                           child: Row(
                        //                             crossAxisAlignment:
                        //                                 CrossAxisAlignment.center,
                        //                             mainAxisAlignment:
                        //                                 MainAxisAlignment.spaceBetween,
                        //                             children: <Widget>[
                        //                               Container(
                        //                                   decoration: BoxDecoration(
                        //                                       border: Border.all(
                        //                                           color:
                        //                                               kSecondaryColor),
                        //                                       borderRadius:
                        //                                           BorderRadius.circular(
                        //                                               30)),
                        //                                   child: Padding(
                        //                                       padding:
                        //                                           const EdgeInsets.all(
                        //                                               10),
                        //                                       child: Row(children: [
                        //                                         Text(
                        //                                           "22 Followers",
                        //                                         ),
                        //                                       ]))),
                        //                               Container(
                        //                                   decoration: BoxDecoration(
                        //                                       border: Border.all(
                        //                                           color:
                        //                                               kSecondaryColor),
                        //                                       borderRadius:
                        //                                           BorderRadius.circular(
                        //                                               30)),
                        //                                   child: Padding(
                        //                                       padding:
                        //                                           const EdgeInsets.all(
                        //                                               10),
                        //                                       child: Row(children: [
                        //                                         Text(
                        //                                           "22 Following",
                        //                                         ),
                        //                                       ]))),
                        //                               InkWell(
                        //                                 onTap: () => launch(
                        //                                     'https://instagram.com/'),
                        //                                 child: Container(
                        //                                     decoration: BoxDecoration(
                        //                                         border: Border.all(
                        //                                             color:
                        //                                                 kSecondaryColor),
                        //                                         borderRadius:
                        //                                             BorderRadius
                        //                                                 .circular(30)),
                        //                                     child: Padding(
                        //                                         padding:
                        //                                             const EdgeInsets
                        //                                                 .all(10),
                        //                                         child: Row(children: [
                        //                                           Text("  i ")
                        //                                         ]))),
                        //                               ),
                        //                               InkWell(
                        //                                 onTap: () => launch(
                        //                                     'https://www.facebook.com/'),
                        //                                 child: Container(
                        //                                     decoration: BoxDecoration(
                        //                                         border: Border.all(
                        //                                             color:
                        //                                                 kSecondaryColor),
                        //                                         borderRadius:
                        //                                             BorderRadius
                        //                                                 .circular(30)),
                        //                                     child: Padding(
                        //                                         padding:
                        //                                             const EdgeInsets
                        //                                                 .all(10),
                        //                                         child: Row(children: [
                        //                                           Text("  f ")
                        //                                         ]))),
                        //                               ),
                        //                               InkWell(
                        //                                 onTap: () => launch(
                        //                                     'https://twitter.com/home'),
                        //                                 child: Container(
                        //                                     decoration: BoxDecoration(
                        //                                         border: Border.all(
                        //                                             color:
                        //                                                 kSecondaryColor),
                        //                                         borderRadius:
                        //                                             BorderRadius
                        //                                                 .circular(30)),
                        //                                     child: Padding(
                        //                                         padding:
                        //                                             const EdgeInsets
                        //                                                 .all(10),
                        //                                         child: Row(children: [
                        //                                           Text("  t ")
                        //                                         ]))),
                        //                               ),
                        //                               InkWell(
                        //                                 onTap: () => launch(
                        //                                     'https://docs.flutter.io/flutter/services/UrlLauncher-class.html'),
                        //                                 child: Container(
                        //                                     decoration: BoxDecoration(
                        //                                         border: Border.all(
                        //                                             color:
                        //                                                 kSecondaryColor),
                        //                                         borderRadius:
                        //                                             BorderRadius
                        //                                                 .circular(30)),
                        //                                     child: Padding(
                        //                                         padding:
                        //                                             const EdgeInsets
                        //                                                 .all(10),
                        //                                         child: Row(children: [
                        //                                           Text(" w ")
                        //                                         ]))),
                        //                               ),
                        //                             ],
                        //                           ),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                     // Column(
                        //                     //   crossAxisAlignment: CrossAxisAlignment.start,
                        //                     //   children: [
                        //                     //     Padding(
                        //                     //       padding: const EdgeInsets.all(10),
                        //                     //       child: Text(
                        //                     //         "Your Communities",
                        //                     //         textScaleFactor: mediaQueryData.textScaleFactor
                        //                     //             .clamp(0.2, 1)
                        //                     //             .toDouble(),
                        //                     //         style: TextStyle(
                        //                     //           //         color: Color(0xffe8e8e8),
                        //                     //           fontSize: SizeConfig.safeBlockHorizontal * 5,
                        //                     //         ),
                        //                     //       ),
                        //                     //     ),
                        //                     //     Container(
                        //                     //       constraints: BoxConstraints(
                        //                     //           maxHeight:
                        //                     //               MediaQuery.of(context).size.height / 5.6),
                        //                     //       child: ListView(
                        //                     //         scrollDirection: Axis.horizontal,
                        //                     //         children: [
                        //                     //           for (var v in communities.userCreatedCommunities)
                        //                     //             Padding(
                        //                     //               padding: const EdgeInsets.all(8.0),
                        //                     //               child: InkWell(
                        //                     //                 onTap: () {
                        //                     //                   Navigator.push(context,
                        //                     //                       MaterialPageRoute(builder: (context) {
                        //                     //                     return CommunityView(communityObject: v);
                        //                     //                   }));
                        //                     //                 },
                        //                     //                 child: Column(
                        //                     //                   crossAxisAlignment:
                        //                     //                       CrossAxisAlignment.start,
                        //                     //                   mainAxisAlignment: MainAxisAlignment.start,
                        //                     //                   children: [
                        //                     //                     Container(
                        //                     //                       //color: Color(0xffe8e8e8),
                        //                     //                       width:
                        //                     //                           MediaQuery.of(context).size.width /
                        //                     //                               4,
                        //                     //                       height:
                        //                     //                           MediaQuery.of(context).size.width /
                        //                     //                               4,
                        //                     //                       child: CachedNetworkImage(
                        //                     //                         imageUrl: v['profileImageUrl'] == null
                        //                     //                             ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                        //                     //                             : v['profileImageUrl'],
                        //                     //                         memCacheHeight: MediaQuery.of(context)
                        //                     //                             .size
                        //                     //                             .height
                        //                     //                             .floor(),
                        //                     //                         placeholder: (context, url) =>
                        //                     //                             Container(
                        //                     //                           child: Image.asset(
                        //                     //                               'assets/images/Thumbnail.png'),
                        //                     //                         ),
                        //                     //                         errorWidget: (context, url, error) =>
                        //                     //                             Icon(Icons.error),
                        //                     //                       ),
                        //                     //                     ),
                        //                     //                     Padding(
                        //                     //                       padding: const EdgeInsets.symmetric(
                        //                     //                           vertical: 10),
                        //                     //                       child: Container(
                        //                     //                         width: MediaQuery.of(context)
                        //                     //                                 .size
                        //                     //                                 .width /
                        //                     //                             4,
                        //                     //                         child: Text(
                        //                     //                           v['name'],
                        //                     //                           textScaleFactor: mediaQueryData
                        //                     //                               .textScaleFactor
                        //                     //                               .clamp(0.2, 0.9)
                        //                     //                               .toDouble(),
                        //                     //                           overflow: TextOverflow.ellipsis,
                        //                     //                           maxLines: 2,
                        //                     //                           style: TextStyle(
                        //                     //                             //    color: Colors.white,
                        //                     //                             fontSize: SizeConfig
                        //                     //                                     .safeBlockHorizontal *
                        //                     //                                 4,
                        //                     //                           ),
                        //                     //                         ),
                        //                     //                       ),
                        //                     //                     ),
                        //                     //                   ],
                        //                     //                 ),
                        //                     //               ),
                        //                     //             ),
                        //                     //           Padding(
                        //                     //             padding: const EdgeInsets
                        //                     //                 .fromLTRB(
                        //                     //                 15, 8, 0, 8),
                        //                     //             child: Column(
                        //                     //               crossAxisAlignment:
                        //                     //               CrossAxisAlignment
                        //                     //                   .start,
                        //                     //               children: <Widget>[
                        //                     //                 GestureDetector(
                        //                     //                     onTap: () {
                        //                     //                         Navigator.push(context,
                        //                     //                         MaterialPageRoute(builder: (context) {
                        //                     //                         return CreateCommunity();
                        //                     //                         })).then((value) async {
                        //                     //                         await _pullRefreshEpisodes();
                        //                     //                         });
                        //                     //                     },
                        //                     //                     child:   Container(
                        //                     //                       child: Center(
                        //                     //                         child: Column(
                        //                     //                           mainAxisAlignment:
                        //                     //                           MainAxisAlignment
                        //                     //                               .center,
                        //                     //                           children: [
                        //                     //                             Icon(
                        //                     //                               Icons.add,
                        //                     //                               color: Color(
                        //                     //                                   0xffe8e8e8),
                        //                     //                             ),
                        //                     //
                        //                     //                               Text(
                        //                     //                                 "Add more",
                        //                     //                                 textScaleFactor:
                        //                     //                                 1.0,
                        //                     //                                 style: TextStyle(
                        //                     //                                     color:
                        //                     //                                     Color(0xffe8e8e8),
                        //                     //                                     fontSize: SizeConfig.safeBlockHorizontal * 4),
                        //                     //                               ),
                        //                     //
                        //                     //                           ],
                        //                     //                         ),
                        //                     //                       ),
                        //                     //                       color: Color(
                        //                     //                           0xff3a3a3a),
                        //                     //                       width:
                        //                     //                       MediaQuery.of(context).size.width /
                        //                     //                           4,
                        //                     //                       height:
                        //                     //                       MediaQuery.of(context).size.width /
                        //                     //                           4,
                        //                     //
                        //                     //                     ))],
                        //                     //             ),
                        //                     //           ),
                        //                     //         ],
                        //                     //       ),
                        //                     //     ),
                        //                     //
                        //                     //     Padding(
                        //                     //       padding: const EdgeInsets.symmetric(horizontal: 5),
                        //                     //       child: Divider(
                        //                     //         color: kSecondaryColor,
                        //                     //       ),
                        //                     //     )
                        //                     //   ],
                        //                     // ),
                        //                     SizedBox(
                        //                       height: 30,
                        //                     ),
                        //                     Column(
                        //                       crossAxisAlignment:
                        //                           CrossAxisAlignment.start,
                        //                       children: [
                        //                         Padding(
                        //                           padding: const EdgeInsets.all(10),
                        //                           child: Text(
                        //                             "Your podcasts",
                        //                             textScaleFactor: mediaQueryData
                        //                                 .textScaleFactor
                        //                                 .clamp(0.2, 1)
                        //                                 .toDouble(),
                        //                             style: TextStyle(
                        //                                 //   color: Color(0xffe8e8e8),
                        //                                 fontSize: SizeConfig
                        //                                         .safeBlockHorizontal *
                        //                                     7,
                        //                                 fontWeight: FontWeight.bold),
                        //                           ),
                        //                         ),
                        //                         Container(
                        //                           constraints: BoxConstraints(
                        //                               maxHeight: MediaQuery.of(context)
                        //                                       .size
                        //                                       .height /
                        //                                   4),
                        //                           decoration: BoxDecoration(
                        //                             borderRadius:
                        //                                 BorderRadius.circular(10),
                        //                           ),
                        //                           child: ListView(
                        //                             scrollDirection: Axis.horizontal,
                        //                             children: [
                        //                               for (var v in podcastList)
                        //                                 Padding(
                        //                                   padding:
                        //                                       const EdgeInsets.all(8.0),
                        //                                   child: InkWell(
                        //                                     onTap: () {
                        //                                       Navigator.push(context,
                        //                                           MaterialPageRoute(
                        //                                               builder:
                        //                                                   (context) {
                        //                                         return PodcastView(
                        //                                             v['id']);
                        //                                       }));
                        //                                     },
                        //                                     child: Column(
                        //                                       crossAxisAlignment:
                        //                                           CrossAxisAlignment
                        //                                               .start,
                        //                                       mainAxisAlignment:
                        //                                           MainAxisAlignment
                        //                                               .start,
                        //                                       children: [
                        //                                         Container(
                        //                                           //   color: Color(0xffe8e8e8),
                        //                                           width: MediaQuery.of(
                        //                                                       context)
                        //                                                   .size
                        //                                                   .width /
                        //                                               4,
                        //                                           height: MediaQuery.of(
                        //                                                       context)
                        //                                                   .size
                        //                                                   .width /
                        //                                               4,
                        //                                           child:
                        //                                               CachedNetworkImage(
                        //                                             imageBuilder: (context,
                        //                                                 imageProvider) {
                        //                                               return Container(
                        //                                                 decoration:
                        //                                                     BoxDecoration(
                        //                                                   borderRadius:
                        //                                                       BorderRadius
                        //                                                           .circular(
                        //                                                               10),
                        //                                                   image: DecorationImage(
                        //                                                       image:
                        //                                                           imageProvider,
                        //                                                       fit: BoxFit
                        //                                                           .cover),
                        //                                                 ),
                        //                                                 height: MediaQuery.of(
                        //                                                         context)
                        //                                                     .size
                        //                                                     .width,
                        //                                                 width: MediaQuery.of(
                        //                                                         context)
                        //                                                     .size
                        //                                                     .width,
                        //                                               );
                        //                                             },
                        //                                             imageUrl: displayPicture ==
                        //                                                     null
                        //                                                 ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
                        //                                                 : displayPicture,
                        //                                             fit: BoxFit.cover,
                        //                                             // memCacheHeight:
                        //                                             //     MediaQuery.of(
                        //                                             //             context)
                        //                                             //         .size
                        //                                             //         .width
                        //                                             //         .ceil(),
                        //                                             memCacheHeight:
                        //                                                 MediaQuery.of(
                        //                                                         context)
                        //                                                     .size
                        //                                                     .height
                        //                                                     .floor(),
                        //                                             placeholder:
                        //                                                 (context,
                        //                                                         url) =>
                        //                                                     Container(
                        //                                               child: Image.network(
                        //                                                   'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'),
                        //                                             ),
                        //                                             errorWidget:
                        //                                                 (context, url,
                        //                                                         error) =>
                        //                                                     Icon(Icons
                        //                                                         .error),
                        //                                           ),
                        //                                         ),
                        //                                         Container(
                        //                                           width: MediaQuery.of(
                        //                                                       context)
                        //                                                   .size
                        //                                                   .width /
                        //                                               4,
                        //                                           child: Padding(
                        //                                             padding:
                        //                                                 const EdgeInsets
                        //                                                         .symmetric(
                        //                                                     vertical:
                        //                                                         10),
                        //                                             child: Text(
                        //                                               v['name'],
                        //                                               textScaleFactor:
                        //                                                   mediaQueryData
                        //                                                       .textScaleFactor
                        //                                                       .clamp(
                        //                                                           0.2,
                        //                                                           1)
                        //                                                       .toDouble(),
                        //                                               overflow:
                        //                                                   TextOverflow
                        //                                                       .ellipsis,
                        //                                               maxLines: 2,
                        //                                               style: TextStyle(
                        //                                                 //     color: Colors.white,
                        //                                                 fontSize: SizeConfig
                        //                                                         .safeBlockHorizontal *
                        //                                                     4,
                        //                                               ),
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ],
                        //                                     ),
                        //                                   ),
                        //                                 ),
                        //                               Padding(
                        //                                 padding:
                        //                                     const EdgeInsets.fromLTRB(
                        //                                         15, 8, 0, 8),
                        //                                 child: Column(
                        //                                   crossAxisAlignment:
                        //                                       CrossAxisAlignment.start,
                        //                                   children: <Widget>[
                        //                                     GestureDetector(
                        //                                         onTap: () async {
                        //                                           if (prefs.getString(
                        //                                                   'HiveUserName') ==
                        //                                               null) {
                        //                                             showBarModalBottomSheet(
                        //                                                 context:
                        //                                                     context,
                        //                                                 builder:
                        //                                                     (context) {
                        //                                                   return HiveDetails();
                        //                                                 });
                        //                                           } else {
                        //                                             showBarModalBottomSheet(
                        //                                                 context:
                        //                                                     context,
                        //                                                 builder:
                        //                                                     (context) {
                        //                                                   return EmailVerificationDialog(
                        //                                                     username: prefs
                        //                                                         .getString(
                        //                                                             'userName'),
                        //                                                   );
                        //                                                 });
                        //                                           }
                        //                                         },
                        //                                         child: Container(
                        //                                           child: Center(
                        //                                             child: Column(
                        //                                               mainAxisAlignment:
                        //                                                   MainAxisAlignment
                        //                                                       .center,
                        //                                               children: [
                        //                                                 Icon(
                        //                                                   Icons.add,
                        //                                                   color: Color(
                        //                                                       0xffe8e8e8),
                        //                                                 ),
                        //                                               ],
                        //                                             ),
                        //                                           ),
                        //                                           color:
                        //                                               Color(0xff3a3a3a),
                        //                                           width: MediaQuery.of(
                        //                                                       context)
                        //                                                   .size
                        //                                                   .width /
                        //                                               4,
                        //                                           height: MediaQuery.of(
                        //                                                       context)
                        //                                                   .size
                        //                                                   .width /
                        //                                               4,
                        //                                         )),
                        //                                     Padding(
                        //                                       padding:
                        //                                           const EdgeInsets.only(
                        //                                               left: 9),
                        //                                       child: Text(
                        //                                         "add a podcast",
                        //                                         textScaleFactor: 0.8,
                        //                                         style: TextStyle(
                        //                                             color: Colors.grey,
                        //                                             fontSize: SizeConfig
                        //                                                     .safeBlockHorizontal *
                        //                                                 4),
                        //                                       ),
                        //                                     ),
                        //                                   ],
                        //                                 ),
                        //                               ),
                        //                             ],
                        //                           ),
                        //      ),
                        //                       ],
                        //                     ),
                        //                     Column(
                        //                         crossAxisAlignment:
                        //                             CrossAxisAlignment.start,
                        //                         children: [
                        //                           Padding(
                        //                             padding: const EdgeInsets.all(10),
                        //                             child: Text(
                        //                               "Your Rooms",
                        //                               textScaleFactor: mediaQueryData
                        //                                   .textScaleFactor
                        //                                   .clamp(0.2, 1)
                        //                                   .toDouble(),
                        //                               style: TextStyle(
                        //                                   //   color: Color(0xffe8e8e8),
                        //                                   fontSize: SizeConfig
                        //                                           .safeBlockHorizontal *
                        //                                       7,
                        //                                   fontWeight: FontWeight.bold),
                        //                             ),
                        //                           ),
                        //                           Container(
                        //                             width: double.infinity,
                        //                             height:
                        //                                 SizeConfig.blockSizeVertical *
                        //                                     32,
                        //                             constraints: BoxConstraints(
                        //                                 minHeight:
                        //                                     MediaQuery.of(context)
                        //                                             .size
                        //                                             .height *
                        //                                         0.17),
                        //                             child: ListView(
                        //                               scrollDirection: Axis.horizontal,
                        //                               children: [
                        //                                 Padding(
                        //                                   padding:
                        //                                       const EdgeInsets.fromLTRB(
                        //                                           15, 8, 0, 8),
                        //                                   child: Container(
                        //                                     decoration: BoxDecoration(
                        //                                         color:
                        //                                             Color(0xff222222),
                        //                                         borderRadius:
                        //                                             BorderRadius
                        //                                                 .circular(8)),
                        //                                     width:
                        //                                         MediaQuery.of(context)
                        //                                                 .size
                        //                                                 .width *
                        //                                             0.60,
                        //                                     child: Column(
                        //                                       crossAxisAlignment:
                        //                                           CrossAxisAlignment
                        //                                               .start,
                        //                                       mainAxisSize:
                        //                                           MainAxisSize.min,
                        //                                       children: [
                        //                                         CachedNetworkImage(
                        //                                           imageBuilder: (context,
                        //                                               imageProvider) {
                        //                                             return Container(
                        //                                               decoration: BoxDecoration(
                        //                                                   image: DecorationImage(
                        //                                                       image:
                        //                                                           imageProvider,
                        //                                                       fit: BoxFit
                        //                                                           .cover),
                        //                                                   borderRadius:
                        //                                                       BorderRadius
                        //                                                           .circular(
                        //                                                               8)),
                        //                                               width: MediaQuery.of(
                        //                                                           context)
                        //                                                       .size
                        //                                                       .width *
                        //                                                   0.90,
                        //                                               height: MediaQuery.of(
                        //                                                           context)
                        //                                                       .size
                        //                                                       .width *
                        //                                                   0.38,
                        //                                             );
                        //                                           },
                        //                                           memCacheHeight:
                        //                                               (MediaQuery.of(
                        //                                                           context)
                        //                                                       .size
                        //                                                       .height)
                        //                                                   .floor(),
                        //                                           imageUrl:
                        //                                               'https://cdn.akamai.steamstatic.com/steam/apps/697810/header.jpg?t=1619649861',
                        //                                           fit: BoxFit.fitHeight,
                        //                                         ),
                        //                                         Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .fromLTRB(
                        //                                                   8, 8, 8, 0),
                        //                                           child: Text(
                        //                                             "Room title can take up to two lines here",
                        //                                             maxLines: 2,
                        //                                             textScaleFactor:
                        //                                                 1.0,
                        //                                             style: TextStyle(
                        //                                                 color: Color(
                        //                                                     0xffe8e8e8)),
                        //                                           ),
                        //                                         ),
                        //                                         SizedBox(height: 20),
                        //                                         Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .fromLTRB(
                        //                                                   8, 0, 8, 8),
                        //                                           child: new Container(
                        //                                             child: Row(
                        //                                               crossAxisAlignment:
                        //                                                   CrossAxisAlignment
                        //                                                       .center,
                        //                                               mainAxisAlignment:
                        //                                                   MainAxisAlignment
                        //                                                       .spaceBetween,
                        //                                               children: <
                        //                                                   Widget>[
                        //                                                 Container(
                        //                                                     decoration: BoxDecoration(
                        //                                                         border: Border.all(
                        //                                                             color:
                        //                                                                 kSecondaryColor),
                        //                                                         borderRadius:
                        //                                                             BorderRadius.circular(30)),
                        //                                                     child: Padding(
                        //                                                         padding: const EdgeInsets.all(10),
                        //                                                         child: Row(children: [
                        //                                                           Text(
                        //                                                               "Time",
                        //                                                               style: TextStyle(color: Colors.white)),
                        //                                                         ]))),
                        //                                                 Icon(
                        //                                                   Icons
                        //                                                       .ac_unit_outlined,
                        //                                                   color: Colors
                        //                                                       .blue,
                        //                                                 )
                        //                                               ],
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ],
                        //                                     ),
                        //                                   ),
                        //                                 )
                        //                               ],
                        //                             ),
                        //                           ),
                        //                           SizedBox(height: 30),
                        //                           Column(
                        //                               crossAxisAlignment:
                        //                                   CrossAxisAlignment.start,
                        //                               children: [
                        //                                 Padding(
                        //                                   padding:
                        //                                       const EdgeInsets.all(10),
                        //                                   child: Text(
                        //                                     "Your Referral Programme dashboard",
                        //                                     textScaleFactor:
                        //                                         mediaQueryData
                        //                                             .textScaleFactor
                        //                                             .clamp(0.2, 1)
                        //                                             .toDouble(),
                        //                                     style: TextStyle(
                        //                                         //   color: Color(0xffe8e8e8),
                        //                                         fontSize: SizeConfig
                        //                                                 .safeBlockHorizontal *
                        //                                             5,
                        //                                         fontWeight:
                        //                                             FontWeight.bold),
                        //                                   ),
                        //                                 ),
                        //                                 Container(
                        //                                   height: 230,
                        //                                   child: Padding(
                        //                                     padding:
                        //                                         const EdgeInsets.all(
                        //                                             20),
                        //                                     child: Container(
                        //                                       decoration: BoxDecoration(
                        //                                           color: themeProvider
                        //                                                       .isLightTheme ==
                        //                                                   true
                        //                                               ? Colors.white
                        //                                               : Color(
                        //                                                   0xff222222),
                        //                                           border: Border.all(
                        //                                               color:
                        //                                                   kSecondaryColor),
                        //                                           borderRadius:
                        //                                               BorderRadius
                        //                                                   .circular(
                        //                                                       10)),
                        //                                       child: Padding(
                        //                                         padding:
                        //                                             const EdgeInsets
                        //                                                 .all(15),
                        //                                         child: Column(
                        //                                           crossAxisAlignment:
                        //                                               CrossAxisAlignment
                        //                                                   .start,
                        //                                           //mainAxisAlignment: MainAxisAlignment.center,
                        //                                           children: [
                        //                                             Text(
                        //                                               "Your Invite Link",
                        //                                               textScaleFactor:
                        //                                                   1.0,
                        //                                               style: TextStyle(
                        //                                                   fontSize:
                        //                                                       SizeConfig
                        //                                                               .safeBlockHorizontal *
                        //                                                           3.5),
                        //                                             ),
                        //                                             SizedBox(
                        //                                               height: 10,
                        //                                             ),
                        //                                             Row(
                        //                                               mainAxisAlignment:
                        //                                                   MainAxisAlignment
                        //                                                       .spaceEvenly,
                        //                                               children: [
                        //                                                 Container(
                        //                                                   decoration: BoxDecoration(
                        //                                                       border: Border.all(color: kSecondaryColor),
                        //                                                       //  color: Colors.blue,
                        //                                                       // color: Colors.blue,
                        //                                                       borderRadius: BorderRadius.circular(20)),
                        //                                                   child:
                        //                                                       Padding(
                        //                                                     padding: const EdgeInsets
                        //                                                             .symmetric(
                        //                                                         horizontal:
                        //                                                             20,
                        //                                                         vertical:
                        //                                                             10),
                        //                                                     child: Text(
                        //                                                       "https://aureal.one/referral",
                        //                                                       style: TextStyle(
                        //                                                           fontSize:
                        //                                                               SizeConfig.safeBlockHorizontal * 4),
                        //                                                     ),
                        //                                                   ),
                        //                                                 ),
                        //                                                 Row(
                        //                                                   children: [
                        //                                                     Container(
                        //                                                       decoration:
                        //                                                           BoxDecoration(
                        //                                                         border: Border.all(
                        //                                                             color:
                        //                                                                 kSecondaryColor),
                        //                                                         shape: BoxShape
                        //                                                             .circle,
                        //                                                         color: themeProvider.isLightTheme ==
                        //                                                                 true
                        //                                                             ? Colors.white
                        //                                                             : Color(0xff222222),
                        //                                                       ),
                        //                                                       child:
                        //                                                           Padding(
                        //                                                         padding:
                        //                                                             const EdgeInsets.all(5),
                        //                                                         child: Icon(
                        //                                                             Icons.copy),
                        //                                                       ),
                        //                                                     ),
                        //                                                     SizedBox(
                        //                                                       width: 15,
                        //                                                     ),
                        //                                                     Container(
                        //                                                       decoration:
                        //                                                           BoxDecoration(
                        //                                                         border: Border.all(
                        //                                                             color:
                        //                                                                 kSecondaryColor),
                        //                                                         shape: BoxShape
                        //                                                             .circle,
                        //                                                       ),
                        //                                                       child:
                        //                                                           Padding(
                        //                                                         padding:
                        //                                                             const EdgeInsets.all(5),
                        //                                                         child: Icon(
                        //                                                             Icons.share),
                        //                                                       ),
                        //                                                     )
                        //                                                   ],
                        //                                                 )
                        //                                               ],
                        //                                             ),
                        //                                             SizedBox(
                        //                                               height: 20,
                        //                                             ),
                        //                                             Row(
                        //                                               mainAxisAlignment:
                        //                                                   MainAxisAlignment
                        //                                                       .start,
                        //                                               children: [
                        //                                                 Container(
                        //                                                   height: MediaQuery.of(
                        //                                                               context)
                        //                                                           .size
                        //                                                           .width /
                        //                                                       7,
                        //                                                   width: 2,
                        //                                                   decoration: BoxDecoration(
                        //                                                       gradient: LinearGradient(
                        //                                                           colors: [
                        //                                                         Color(
                        //                                                             0xff5d5da8),
                        //                                                         Color(
                        //                                                             0xff5bc3ef)
                        //                                                       ],
                        //                                                           begin: Alignment
                        //                                                               .bottomCenter,
                        //                                                           end: Alignment
                        //                                                               .topCenter)),
                        //                                                 ),
                        //                                                 Padding(
                        //                                                   padding:
                        //                                                       const EdgeInsets
                        //                                                           .all(5),
                        //                                                   child: Column(
                        //                                                     crossAxisAlignment:
                        //                                                         CrossAxisAlignment
                        //                                                             .start,
                        //                                                     children: [
                        //                                                       Text(
                        //                                                         "234",
                        //                                                         textScaleFactor:
                        //                                                             1.0,
                        //                                                         style: TextStyle(
                        //                                                             fontSize: SizeConfig.safeBlockHorizontal *
                        //                                                                 4.5,
                        //                                                             fontWeight:
                        //                                                                 FontWeight.w700),
                        //                                                       ),
                        //                                                       SizedBox(
                        //                                                         height:
                        //                                                             10,
                        //                                                       ),
                        //                                                       Text(
                        //                                                           "Links Shared")
                        //                                                     ],
                        //                                                   ),
                        //                                                 ),
                        //                                                 SizedBox(
                        //                                                   width: 15,
                        //                                                 ),
                        //                                                 Container(
                        //                                                   height: MediaQuery.of(
                        //                                                               context)
                        //                                                           .size
                        //                                                           .width /
                        //                                                       7,
                        //                                                   width: 2,
                        //                                                   decoration: BoxDecoration(
                        //                                                       gradient: LinearGradient(
                        //                                                           colors: [
                        //                                                         Color(
                        //                                                             0xff5d5da8),
                        //                                                         Color(
                        //                                                             0xff5bc3ef)
                        //                                                       ],
                        //                                                           begin: Alignment
                        //                                                               .bottomCenter,
                        //                                                           end: Alignment
                        //                                                               .topCenter)),
                        //                                                 ),
                        //                                                 Padding(
                        //                                                   padding:
                        //                                                       const EdgeInsets
                        //                                                           .all(5),
                        //                                                   child: Column(
                        //                                                     crossAxisAlignment:
                        //                                                         CrossAxisAlignment
                        //                                                             .start,
                        //                                                     children: [
                        //                                                       Text(
                        //                                                         "234",
                        //                                                         textScaleFactor:
                        //                                                             1.0,
                        //                                                         style: TextStyle(
                        //                                                             fontSize: SizeConfig.safeBlockHorizontal *
                        //                                                                 4.5,
                        //                                                             fontWeight:
                        //                                                                 FontWeight.w700),
                        //                                                       ),
                        //                                                       SizedBox(
                        //                                                         height:
                        //                                                             10,
                        //                                                       ),
                        //                                                       Text(
                        //                                                           "Creators Signed Up")
                        //                                                     ],
                        //                                                   ),
                        //                                                 ),
                        //                                                 SizedBox(
                        //                                                   width: 15,
                        //                                                 ),
                        //                                                 Container(
                        //                                                   height: MediaQuery.of(
                        //                                                               context)
                        //                                                           .size
                        //                                                           .width /
                        //                                                       7,
                        //                                                   width: 2,
                        //                                                   decoration: BoxDecoration(
                        //                                                       gradient: LinearGradient(
                        //                                                           colors: [
                        //                                                         Color(
                        //                                                             0xff5d5da8),
                        //                                                         Color(
                        //                                                             0xff5bc3ef)
                        //                                                       ],
                        //                                                           begin: Alignment
                        //                                                               .bottomCenter,
                        //                                                           end: Alignment
                        //                                                               .topCenter)),
                        //                                                 ),
                        //                                                 Padding(
                        //                                                   padding:
                        //                                                       const EdgeInsets
                        //                                                           .all(10),
                        //                                                   child: Column(
                        //                                                     crossAxisAlignment:
                        //                                                         CrossAxisAlignment
                        //                                                             .start,
                        //                                                     children: [
                        //                                                       Text(
                        //                                                         "234",
                        //                                                         textScaleFactor:
                        //                                                             1.0,
                        //                                                         style: TextStyle(
                        //                                                             fontSize: SizeConfig.safeBlockHorizontal *
                        //                                                                 4,
                        //                                                             fontWeight:
                        //                                                                 FontWeight.w700),
                        //                                                       ),
                        //                                                       SizedBox(
                        //                                                         height:
                        //                                                             10,
                        //                                                       ),
                        //                                                       Text(
                        //                                                           "Rewards")
                        //                                                     ],
                        //                                                   ),
                        //                                                 ),
                        //                                               ],
                        //                                             )
                        //                                           ],
                        //                                         ),
                        //                                       ),
                        //                                     ),
                        //                                   ),
                        //                                 ),
                        //                                 Divider(
                        //                                   color: kSecondaryColor,
                        //                                 ),
                        //                                 Padding(
                        //                                   padding: const EdgeInsets
                        //                                           .symmetric(
                        //                                       horizontal: 10),
                        //                                   child: Column(
                        //                                     crossAxisAlignment:
                        //                                         CrossAxisAlignment
                        //                                             .start,
                        //                                     children: [
                        //                                       // Container(
                        //                                       //   width: double.infinity,
                        //                                       //   decoration: BoxDecoration(
                        //                                       //       border: Border(
                        //                                       //           bottom:
                        //                                       //               BorderSide(color: kSecondaryColor))),
                        //                                       //   child: Padding(
                        //                                       //     padding: const EdgeInsets.symmetric(vertical: 15),
                        //                                       //     child: InkWell(
                        //                                       //       onTap: () {
                        //                                       //         Navigator.push(context,
                        //                                       //             MaterialPageRoute(builder: (context) {
                        //                                       //           return CreateCommunity();
                        //                                       //         })).then((value) async {
                        //                                       //           await _pullRefreshEpisodes();
                        //                                       //         });
                        //                                       //       },
                        //                                       //       child: Text(
                        //                                       //         "Add your community",
                        //                                       //         textScaleFactor: mediaQueryData.textScaleFactor
                        //                                       //             .clamp(0.2, 1)
                        //                                       //             .toDouble(),
                        //                                       //         style: TextStyle(
                        //                                       //           fontSize: SizeConfig.safeBlockHorizontal * 4,
                        //                                       //           //      color: Color(0xffe8e8e8),
                        //                                       //         ),
                        //                                       //       ),
                        //                                       //     ),
                        //                                       //   ),
                        //                                       // ),
                        //                                       Container(
                        //                                         width: double.infinity,
                        //                                         decoration:
                        //                                             BoxDecoration(
                        //                                           border: Border(
                        //                                             bottom: BorderSide(
                        //                                               color:
                        //                                                   kSecondaryColor,
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                         child: Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .symmetric(
                        //                                                   vertical: 15),
                        //                                           child: InkWell(
                        //                                             onTap: () {
                        //                                               Navigator.push(
                        //                                                   context,
                        //                                                   MaterialPageRoute(
                        //                                                       builder:
                        //                                                           (context) {
                        //                                                 return Rewards();
                        //                                               }));
                        //                                             },
                        //                                             child: Text(
                        //                                               "Your rewards",
                        //                                               textScaleFactor:
                        //                                                   mediaQueryData
                        //                                                       .textScaleFactor
                        //                                                       .clamp(
                        //                                                           0.2,
                        //                                                           1)
                        //                                                       .toDouble(),
                        //                                               style: TextStyle(
                        //                                                 //    color: Color(0xffe8e8e8),
                        //                                                 fontSize: SizeConfig
                        //                                                         .safeBlockHorizontal *
                        //                                                     4,
                        //                                               ),
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ),
                        //                                       Container(
                        //                                         width: double.infinity,
                        //                                         decoration:
                        //                                             BoxDecoration(
                        //                                           border: Border(
                        //                                             bottom: BorderSide(
                        //                                               color:
                        //                                                   kSecondaryColor,
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                         child: Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .symmetric(
                        //                                                   vertical: 15),
                        //                                           child: InkWell(
                        //                                             onTap: () {
                        //                                               showBarModalBottomSheet(
                        //                                                   context:
                        //                                                       context,
                        //                                                   builder:
                        //                                                       (context) {
                        //                                                     return DownloadPage();
                        //                                                   });
                        //                                             },
                        //                                             child: Text(
                        //                                               "Library",
                        //                                               textScaleFactor:
                        //                                                   mediaQueryData
                        //                                                       .textScaleFactor
                        //                                                       .clamp(
                        //                                                           0.2,
                        //                                                           1)
                        //                                                       .toDouble(),
                        //                                               style: TextStyle(
                        //                                                 //        color: Color(0xffe8e8e8),
                        //                                                 fontSize: SizeConfig
                        //                                                         .safeBlockHorizontal *
                        //                                                     4,
                        //                                               ),
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ),
                        //                                       Container(
                        //                                         width: double.infinity,
                        //                                         decoration:
                        //                                             BoxDecoration(
                        //                                           border: Border(
                        //                                             bottom: BorderSide(
                        //                                               color:
                        //                                                   kSecondaryColor,
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                         child: Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .symmetric(
                        //                                                   vertical: 15),
                        //                                           child: InkWell(
                        //                                             onTap: () {
                        //                                               showBarModalBottomSheet(
                        //                                                   context:
                        //                                                       context,
                        //                                                   builder:
                        //                                                       (context) {
                        //                                                     return Container(
                        //                                                       height: MediaQuery.of(
                        //                                                               context)
                        //                                                           .size
                        //                                                           .height,
                        //                                                       // child: InAppWebView(
                        //                                                       //     gestureRecognizers:
                        //                                                       //         gestureRecognizers,
                        //                                                       //     initialFile:
                        //                                                       //         'https://wallet.hive.blog/@${prefs.getString('HiveUserName')}'),
                        //                                                       child:
                        //                                                           WebView(
                        //                                                         gestureRecognizers:
                        //                                                             Set()
                        //                                                               ..add(
                        //                                                                 Factory<VerticalDragGestureRecognizer>(
                        //                                                                   () => VerticalDragGestureRecognizer(),
                        //                                                                 ), // or null
                        //                                                               ),
                        //                                                         gestureNavigationEnabled:
                        //                                                             true,
                        //                                                         javascriptMode:
                        //                                                             JavascriptMode.unrestricted,
                        //                                                         initialUrl:
                        //                                                             'https://wallet.hive.blog/@${prefs.getString('HiveUserName')}',
                        //                                                       ),
                        //                                                     );
                        //                                                   });
                        //                                             },
                        //                                             child: Text(
                        //                                               "Your wallet",
                        //                                               textScaleFactor:
                        //                                                   mediaQueryData
                        //                                                       .textScaleFactor
                        //                                                       .clamp(
                        //                                                           0.2,
                        //                                                           1)
                        //                                                       .toDouble(),
                        //                                               style: TextStyle(
                        //                                                 //        color: Color(0xffe8e8e8),
                        //                                                 fontSize: SizeConfig
                        //                                                         .safeBlockHorizontal *
                        //                                                     4,
                        //                                               ),
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ),
                        //                                       Container(
                        //                                         width: double.infinity,
                        //                                         decoration:
                        //                                             BoxDecoration(
                        //                                           border: Border(
                        //                                             bottom: BorderSide(
                        //                                               color:
                        //                                                   kSecondaryColor,
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                         child: Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .symmetric(
                        //                                                   vertical: 15),
                        //                                           child: InkWell(
                        //                                             onTap: () {
                        //                                               hiveUserName ==
                        //                                                       null
                        //                                                   ? Navigator.pushNamedAndRemoveUntil(
                        //                                                       context,
                        //                                                       HiveAccount
                        //                                                           .id,
                        //                                                       (route) =>
                        //                                                           false)
                        //                                                   : print(
                        //                                                       'nothing');
                        //                                             },
                        //                                             child: Text(
                        //                                               hiveUserName !=
                        //                                                       null
                        //                                                   ? "Connected with your Hive Account ( @${hiveUserName} )"
                        //                                                   : "Connect your Hive Account",
                        //                                               textScaleFactor:
                        //                                                   mediaQueryData
                        //                                                       .textScaleFactor
                        //                                                       .clamp(
                        //                                                           0.2,
                        //                                                           1)
                        //                                                       .toDouble(),
                        //                                               style: TextStyle(
                        //                                                 //     color: Color(0xffe8e8e8),
                        //                                                 fontSize: SizeConfig
                        //                                                         .safeBlockHorizontal *
                        //                                                     4,
                        //                                               ),
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ),
                        //                                       Container(
                        //                                         width: double.infinity,
                        //                                         decoration:
                        //                                             BoxDecoration(
                        //                                           border: Border(
                        //                                             bottom: BorderSide(
                        //                                               color:
                        //                                                   kSecondaryColor,
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                         child: Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .symmetric(
                        //                                                   vertical: 15),
                        //                                           child: InkWell(
                        //                                             onTap: () {
                        //                                               showBarModalBottomSheet(
                        //                                                   context:
                        //                                                       context,
                        //                                                   builder:
                        //                                                       (context) {
                        //                                                     return Settings();
                        //                                                   });
                        //                                             },
                        //                                             child: Text(
                        //                                               "Setting",
                        //                                               textScaleFactor:
                        //                                                   mediaQueryData
                        //                                                       .textScaleFactor
                        //                                                       .clamp(
                        //                                                           0.2,
                        //                                                           1)
                        //                                                       .toDouble(),
                        //                                               style: TextStyle(
                        //                                                 //  color: Color(0xffe8e8e8),
                        //                                                 fontSize: SizeConfig
                        //                                                         .safeBlockHorizontal *
                        //                                                     4,
                        //                                               ),
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ),
                        //                                       Container(
                        //                                         width: double.infinity,
                        //                                         decoration:
                        //                                             BoxDecoration(
                        //                                           border: Border(
                        //                                             bottom: BorderSide(
                        //                                               color:
                        //                                                   kSecondaryColor,
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                         child: Padding(
                        //                                           padding:
                        //                                               const EdgeInsets
                        //                                                       .symmetric(
                        //                                                   vertical: 15),
                        //                                           child: InkWell(
                        //                                             onTap: () {
                        //                                               logout();
                        //                                               prefs.clear();
                        //                                             },
                        //                                             child: Text(
                        //                                               "Sign Out",
                        //                                               textScaleFactor:
                        //                                                   mediaQueryData
                        //                                                       .textScaleFactor
                        //                                                       .clamp(
                        //                                                           0.2,
                        //                                                           1)
                        //                                                       .toDouble(),
                        //                                               style: TextStyle(
                        //                                                 //    color: Color(0xffe8e8e8),
                        //                                                 fontSize: SizeConfig
                        //                                                         .safeBlockHorizontal *
                        //                                                     4,
                        //                                               ),
                        //                                             ),
                        //                                           ),
                        //                                         ),
                        //                                       ),
                        //                                       // SignInButton(Buttons.Google,
                        //                                       //     text: 'Sign Out of Google',
                        //                                       //     onPressed: () => authBloc.logout())
                        //                                     ],
                        //                                   ),
                        //                                 ),
                        //                                 SizedBox(
                        //                                   height: 100,
                        //                                 ),
                        //                               ])
                        //                         ]),
                        //                   ])
                        //             ]))
                        //   ]),
                        // ),
                      )),
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
