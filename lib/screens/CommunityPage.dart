import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'Home.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
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

    Launcher launcher = Launcher();

    Future<void> _pullRefresh() async {
      print('proceedd');

      await communities.getAllCommunitiesForUser();
      await communities.getUserCreatedCommunities();
      await communities.getAllCommunity();
    }
    Future<bool> _onBackPressed() async {
      Navigator.pushNamedAndRemoveUntil(
          context,
          Home.id,
          ModalRoute.withName("/")
      );
      return false; // return true if the route to be popped
    }
    return WillPopScope(
      onWillPop:_onBackPressed ,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return WillPopScope(
            onWillPop:_onBackPressed ,
            child: Scaffold(
              // body: RefreshIndicator(
              //   onRefresh: _pullRefresh,
              //   child: Container(
              //     child: ListView(
              //       children: [
              //         Container(
              //           width: double.infinity,
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Padding(
              //                 padding: const EdgeInsets.symmetric(
              //                     horizontal: 10, vertical: 10),
              //                 child: Text(
              //                   "Your Favourites",
              //                   textScaleFactor: 0.75,
              //                   style: TextStyle(
              //                      // color: Color(0xffe8e8e8),
              //                       fontSize: SizeConfig.safeBlockHorizontal * 7.2,
              //                       fontWeight: FontWeight.bold),
              //                 ),
              //               ),
              //               Container(
              //                 constraints: BoxConstraints(
              //                   maxHeight: 200,
              //                 ),
              //                 child: ListView(
              //                   scrollDirection: Axis.horizontal,
              //                   children: [
              //                     for (var v in communities.userCommunities)
              //                       Padding(
              //                         padding: const EdgeInsets.all(8.0),
              //                         child: InkWell(
              //                           onTap: () {
              //                             Navigator.push(context,
              //                                 MaterialPageRoute(builder: (context) {
              //                               return CommunityView(
              //                                   communityObject: v);
              //                             }));
              //                           },
              //                           child: Column(
              //                             crossAxisAlignment:
              //                                 CrossAxisAlignment.start,
              //                             mainAxisAlignment:
              //                                 MainAxisAlignment.start,
              //                             children: [
              //                               Container(
              //                              //   color: Color(0xffe8e8e8),
              //                                 width: MediaQuery.of(context)
              //                                         .size
              //                                         .width /
              //                                     4,
              //                                 height: MediaQuery.of(context)
              //                                         .size
              //                                         .width /
              //                                     4,
              //                                 child: CachedNetworkImage(
              //                                   imageUrl: v['profileImageUrl'] ==
              //                                           null
              //                                       ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
              //                                       : v['profileImageUrl'],
              //                                   memCacheHeight:
              //                                       MediaQuery.of(context)
              //                                           .size
              //                                           .height
              //                                           .floor(),
              //                                   placeholder: (context, url) =>
              //                                       Container(
              //                                     child: Image.asset(
              //                                         'assets/images/Thumbnail.png'),
              //                                   ),
              //                                   errorWidget:
              //                                       (context, url, error) =>
              //                                           Icon(Icons.error),
              //                                 ),
              //                               ),
              //                               Padding(
              //                                 padding: const EdgeInsets.symmetric(
              //                                     vertical: 10),
              //                                 child: Container(
              //                                   width: MediaQuery.of(context)
              //                                           .size
              //                                           .width /
              //                                       4,
              //                                   child: Column(
              //                                     crossAxisAlignment:
              //                                         CrossAxisAlignment.start,
              //                                     children: [
              //                                       Text(
              //                                         v['name'],
              //                                         textScaleFactor: 0.75,
              //                                         overflow:
              //                                             TextOverflow.ellipsis,
              //                                         maxLines: 2,
              //                                         style: TextStyle(
              //                                  //         color: Colors.white,
              //                                           fontSize: SizeConfig
              //                                                   .safeBlockHorizontal *
              //                                               4,
              //                                         ),
              //                                       ),
              //                                       // Text(
              //                                       //   v['author'],
              //                                       //   style: TextStyle(
              //                                       //       color: Colors.white,
              //                                       //       fontSize: SizeConfig
              //                                       //               .safeBlockHorizontal *
              //                                       //           3),
              //                                       // )
              //                                     ],
              //                                   ),
              //                                 ),
              //                               ),
              //                             ],
              //                           ),
              //                         ),
              //                       )
              //                   ],
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //         // Container(
              //         //   width: double.infinity,
              //         //   child: Column(
              //         //     crossAxisAlignment: CrossAxisAlignment.start,
              //         //     children: [
              //         //       Padding(
              //         //         padding: const EdgeInsets.symmetric(
              //         //             horizontal: 10, vertical: 10),
              //         //         child: Text(
              //         //           "Created Communities",
              //         //           textScaleFactor: 0.75,
              //         //           style: TextStyle(
              //         //            //   color: Color(0xffe8e8e8),
              //         //               fontSize: SizeConfig.safeBlockHorizontal * 7.2,
              //         //               fontWeight: FontWeight.bold),
              //         //         ),
              //         //       ),
              //         //       Container(
              //         //         constraints: BoxConstraints(maxHeight: 200),
              //         //         child: ListView(
              //         //           scrollDirection: Axis.horizontal,
              //         //           children: [
              //         //             for (var v in communities.userCreatedCommunities)
              //         //               Padding(
              //         //                 padding: const EdgeInsets.all(8.0),
              //         //                 child: InkWell(
              //         //                   onTap: () {
              //         //                     Navigator.push(context,
              //         //                         MaterialPageRoute(builder: (context) {
              //         //                       return CommunityView(
              //         //                         communityObject: v,
              //         //                       );
              //         //                     }));
              //         //                   },
              //         //                   child: Column(
              //         //                     crossAxisAlignment:
              //         //                         CrossAxisAlignment.start,
              //         //                     mainAxisAlignment:
              //         //                         MainAxisAlignment.start,
              //         //                     children: [
              //         //                       Container(
              //         //                         width: MediaQuery.of(context)
              //         //                                 .size
              //         //                                 .width /
              //         //                             4,
              //         //                         height: MediaQuery.of(context)
              //         //                                 .size
              //         //                                 .width /
              //         //                             4,
              //         //                   //      color: Color(0xffe8e8e8),
              //         //                         child: CachedNetworkImage(
              //         //                           imageUrl: v['profileImageUrl'] ==
              //         //                                   null
              //         //                               ? 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png'
              //         //                               : v['profileImageUrl'],
              //         //                           memCacheHeight:
              //         //                               MediaQuery.of(context)
              //         //                                   .size
              //         //                                   .height
              //         //                                   .floor(),
              //         //                           placeholder: (context, url) =>
              //         //                               Container(
              //         //                             child: Image.asset(
              //         //                                 'assets/images/Thumbnail.png'),
              //         //                           ),
              //         //                           errorWidget:
              //         //                               (context, url, error) =>
              //         //                                   Icon(Icons.error),
              //         //                         ),
              //         //                       ),
              //         //                       Padding(
              //         //                         padding: const EdgeInsets.symmetric(
              //         //                             vertical: 10),
              //         //                         child: Container(
              //         //                           width: MediaQuery.of(context)
              //         //                                   .size
              //         //                                   .width /
              //         //                               4,
              //         //                           child: Column(
              //         //                             crossAxisAlignment:
              //         //                                 CrossAxisAlignment.start,
              //         //                             children: [
              //         //                               Text(
              //         //                                 v['name'],
              //         //                                 textScaleFactor: 0.75,
              //         //                                 overflow:
              //         //                                     TextOverflow.ellipsis,
              //         //                                 maxLines: 2,
              //         //                                 style: TextStyle(
              //         //                                //   color: Colors.white,
              //         //                                   fontSize: SizeConfig
              //         //                                           .safeBlockHorizontal *
              //         //                                       4,
              //         //                                 ),
              //         //                               ),
              //         //                               // Text(
              //         //                               //   v['author'],
              //         //                               //   style: TextStyle(
              //         //                               //       color: Colors.white,
              //         //                               //       fontSize: SizeConfig
              //         //                               //               .safeBlockHorizontal *
              //         //                               //           3),
              //         //                               // )
              //         //                             ],
              //         //                           ),
              //         //                         ),
              //         //                       ),
              //         //                     ],
              //         //                   ),
              //         //                 ),
              //         //               )
              //         //           ],
              //         //         ),
              //         //       ),
              //         //     ],
              //         //   ),
              //         // ),
              //         Container(
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Padding(
              //                 padding: const EdgeInsets.symmetric(
              //                     horizontal: 10, vertical: 10),
              //                 child: Text(
              //                   "All Communities",
              //                   textScaleFactor: 0.75,
              //                   style: TextStyle(
              //                   //    color: Color(0xffe8e8e8),
              //                       fontSize: SizeConfig.safeBlockHorizontal * 7.2,
              //                       fontWeight: FontWeight.bold),
              //                 ),
              //               ),
              //               Container(
              //                 child: Column(
              //                   children: [
              //                     for (var v in communities.allCommunities)
              //                       Container(
              //                         child: Column(
              //                           children: [
              //                             ListTile(
              //                               onTap: () {
              //                                 Navigator.push(context,
              //                                     MaterialPageRoute(
              //                                         builder: (context) {
              //                                   return CommunityView(
              //                                       communityObject: v);
              //                                 }));
              //                               },
              //                               contentPadding: EdgeInsets.symmetric(
              //                                   horizontal: 10),
              //                               leading: AspectRatio(
              //                                 aspectRatio: 1,
              //                                 child: Container(
              //                               //    color: Color(0xffe8e8e8),
              //                                   height: MediaQuery.of(context)
              //                                           .size
              //                                           .width /
              //                                       6,
              //                                   width: MediaQuery.of(context)
              //                                           .size
              //                                           .width /
              //                                       6,
              //                                   child: CachedNetworkImage(
              //                                     fit: BoxFit.cover,
              //                                     placeholder: (context, url) =>
              //                                         Container(
              //                                       child: Image.asset(
              //                                           'assets/images/Thumbnail.png'),
              //                                     ),
              //                                     imageUrl: v['profileImageUrl'] ==
              //                                             null
              //                                         ? 'assets/images/Thumbnail.png'
              //                                         : v['profileImageUrl'],
              //                                     memCacheHeight:
              //                                         MediaQuery.of(context)
              //                                             .size
              //                                             .height
              //                                             .floor(),
              //                                   ),
              //                                 ),
              //                               ),
              //                               title: Padding(
              //                                 padding: const EdgeInsets.symmetric(
              //                                     vertical: 5),
              //                                 child: Text(
              //                                   '${v['name']}',
              //                                   textScaleFactor: 0.75,
              //                                   maxLines: 1,
              //                                   overflow: TextOverflow.ellipsis,
              //                                   style: TextStyle(
              //                                    //   color: Color(0xffe8e8e8),
              //                                       fontSize: SizeConfig
              //                                               .safeBlockHorizontal *
              //                                           5),
              //                                 ),
              //                               ),
              //                               subtitle: Text(
              //                                 "${v['description']}",
              //                                 textScaleFactor: 0.75,
              //                                 style: TextStyle(
              //                                 //    color: Color(0xffe8e8e8)
              //                                       ),
              //                               ),
              //                             ),
              //                             Padding(
              //                               padding: const EdgeInsets.symmetric(
              //                                   horizontal: 10),
              //                               child: Container(
              //                                 child: Row(
              //                                   children: [],
              //                                 ),
              //                               ),
              //                             )
              //                           ],
              //                         ),
              //                       )
              //                   ],
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //         SizedBox(
              //           height: 100,
              //         ),
              //
              //         // Container(
              //         //   child: Column(
              //         //     children: [
              //         //       for (var v in hiveEpisodes)
              //         //         InkWell(
              //         //           onTap: () {
              //         //             Navigator.push(context,
              //         //                 MaterialPageRoute(builder: (context) {
              //         //               return EpisodeView(v, v['podcast_name']);
              //         //             }));
              //         //           },
              //         //           child: Padding(
              //         //             padding: const EdgeInsets.symmetric(horizontal: 10),
              //         //             child: Container(
              //         //               decoration: BoxDecoration(
              //         //                   border: Border(
              //         //                       top: BorderSide(color: Color(0xff3a3a3a)),
              //         //                       bottom: BorderSide(
              //         //                           color: Color(0xff3a3a3a), width: 1))),
              //         //               width: double.infinity,
              //         //               child: Padding(
              //         //                 padding: const EdgeInsets.symmetric(vertical: 20),
              //         //                 child: Column(
              //         //                   mainAxisAlignment: MainAxisAlignment.center,
              //         //                   children: [
              //         //                     Row(
              //         //                       children: [
              //         //                         Container(
              //         //                           color: Colors.white,
              //         //                           width:
              //         //                               MediaQuery.of(context).size.width / 7,
              //         //                           height:
              //         //                               MediaQuery.of(context).size.width / 7,
              //         //                           child: CachedNetworkImage(
              //         //                             imageUrl: v['image'],
              //         //                             // memCacheHeight:
              //         //                             //     MediaQuery.of(
              //         //                             //             context)
              //         //                             //         .size
              //         //                             //         .width
              //         //                             //         .ceil(),
              //         //                             memCacheHeight: MediaQuery.of(context)
              //         //                                 .size
              //         //                                 .height
              //         //                                 .floor(),
              //         //                             placeholder: (context, url) =>
              //         //                                 Container(
              //         //                               child: Image.asset(
              //         //                                   'assets/images/Thumbnail.png'),
              //         //                             ),
              //         //                             errorWidget: (context, url, error) =>
              //         //                                 Icon(Icons.error),
              //         //                           ),
              //         //                         ),
              //         //                         SizedBox(
              //         //                             width: SizeConfig.screenWidth / 26),
              //         //                         Container(
              //         //                           child: Column(
              //         //                             crossAxisAlignment:
              //         //                                 CrossAxisAlignment.start,
              //         //                             children: [
              //         //                               Text(
              //         //                                 v['podcast_name'],
              //         //                                 style: TextStyle(
              //         //                                     color: Color(0xffe8e8e8),
              //         //                                     fontSize: SizeConfig
              //         //                                             .safeBlockHorizontal *
              //         //                                         5.5,
              //         //                                     fontWeight: FontWeight.normal),
              //         //                               ),
              //         //                               Text(
              //         //                                 v['duration'].toString(),
              //         //                                 style: TextStyle(
              //         //                                     color: Color(0xffe8e8e8),
              //         //                                     fontSize: SizeConfig
              //         //                                             .safeBlockHorizontal *
              //         //                                         3.5),
              //         //                               ),
              //         //                             ],
              //         //                           ),
              //         //                         )
              //         //                       ],
              //         //                     ),
              //         //                     Padding(
              //         //                       padding:
              //         //                           const EdgeInsets.symmetric(vertical: 10),
              //         //                       child: Container(
              //         //                         width: double.infinity,
              //         //                         child: Column(
              //         //                           crossAxisAlignment:
              //         //                               CrossAxisAlignment.start,
              //         //                           children: [
              //         //                             Text(
              //         //                               v['name'],
              //         //                               style: TextStyle(
              //         //                                   color: Color(0xffe8e8e8),
              //         //                                   fontSize: SizeConfig
              //         //                                           .safeBlockHorizontal *
              //         //                                       4.5,
              //         //                                   fontWeight: FontWeight.bold),
              //         //                             ),
              //         //                             Padding(
              //         //                               padding: const EdgeInsets.symmetric(
              //         //                                   vertical: 10),
              //         //                               child: Text(
              //         //                                 v['summary'],
              //         //                                 maxLines: 2,
              //         //                                 overflow: TextOverflow.ellipsis,
              //         //                                 style: TextStyle(
              //         //                                     color: Color(0xffe8e8e8),
              //         //                                     fontSize: SizeConfig
              //         //                                             .safeBlockHorizontal *
              //         //                                         4),
              //         //                               ),
              //         //                             )
              //         //                           ],
              //         //                         ),
              //         //                       ),
              //         //                     ),
              //         //                     Container(
              //         //                       width: double.infinity,
              //         //                       child: Row(
              //         //                         mainAxisAlignment:
              //         //                             MainAxisAlignment.spaceBetween,
              //         //                         children: [
              //         //                           Row(
              //         //                             mainAxisAlignment:
              //         //                                 MainAxisAlignment.spaceBetween,
              //         //                             children: [
              //         //                               Container(
              //         //                                 decoration: BoxDecoration(
              //         //                                     color: kSecondaryColor,
              //         //                                     borderRadius:
              //         //                                         BorderRadius.circular(30)),
              //         //                                 child: Padding(
              //         //                                   padding:
              //         //                                       const EdgeInsets.all(5.0),
              //         //                                   child: Row(
              //         //                                     children: [
              //         //                                       Icon(
              //         //                                         FontAwesomeIcons
              //         //                                             .chevronCircleUp,
              //         //                                         size: 18,
              //         //                                         color: Color(0xffe8e8e8),
              //         //                                       ),
              //         //                                       Padding(
              //         //                                         padding: const EdgeInsets
              //         //                                                 .symmetric(
              //         //                                             horizontal: 8),
              //         //                                         child: GestureDetector(
              //         //                                           onTap: () {
              //         //                                             upvote(
              //         //                                                 permlink:
              //         //                                                     v['permlink'],
              //         //                                                 episode_id:
              //         //                                                     v['id']);
              //         //                                           },
              //         //                                           child: Text(
              //         //                                             v['votes'],
              //         //                                             style: TextStyle(
              //         //                                                 color: Color(
              //         //                                                     0xffe8e8e8)),
              //         //                                           ),
              //         //                                         ),
              //         //                                       ),
              //         //                                       Padding(
              //         //                                         padding:
              //         //                                             const EdgeInsets.only(
              //         //                                                 right: 4),
              //         //                                         child: Text(
              //         //                                           '\$${v['payout_value'].toString().split(' ')[0]}',
              //         //                                           style: TextStyle(
              //         //                                               color: Color(
              //         //                                                   0xffe8e8e8)),
              //         //                                         ),
              //         //                                       )
              //         //                                     ],
              //         //                                   ),
              //         //                                 ),
              //         //                               ),
              //         //                               SizedBox(
              //         //                                 width: SizeConfig.screenWidth / 30,
              //         //                               ),
              //         //                               Container(
              //         //                                 decoration: BoxDecoration(
              //         //                                     color: kSecondaryColor,
              //         //                                     borderRadius:
              //         //                                         BorderRadius.circular(30)),
              //         //                                 child: Padding(
              //         //                                   padding:
              //         //                                       const EdgeInsets.all(5.0),
              //         //                                   child: Row(
              //         //                                     children: [
              //         //                                       Icon(
              //         //                                         Icons.mode_comment_outlined,
              //         //                                         size: 18,
              //         //                                         color: Color(0xffe8e8e8),
              //         //                                       ),
              //         //                                       Padding(
              //         //                                         padding: const EdgeInsets
              //         //                                                 .symmetric(
              //         //                                             horizontal: 8),
              //         //                                         child: Text(
              //         //                                           v['comments_count']
              //         //                                               .toString(),
              //         //                                           style: TextStyle(
              //         //                                               color: Color(
              //         //                                                   0xffe8e8e8)),
              //         //                                         ),
              //         //                                       ),
              //         //                                     ],
              //         //                                   ),
              //         //                                 ),
              //         //                               )
              //         //                             ],
              //         //                           ),
              //         //                           Row(
              //         //                             children: [
              //         //                               // IconButton(
              //         //                               //   icon: Icon(
              //         //                               //     Icons
              //         //                               //         .playlist_add_rounded,
              //         //                               //     color:
              //         //                               //         Color(0xffe8e8e8),
              //         //                               //   ),
              //         //                               // ),
              //         //                               IconButton(
              //         //                                 icon: Icon(
              //         //                                   FontAwesomeIcons.shareAlt,
              //         //                                   size: SizeConfig
              //         //                                           .safeBlockHorizontal *
              //         //                                       4,
              //         //                                   color: Color(0xffe8e8e8),
              //         //                                 ),
              //         //                                 onPressed: () async {
              //         //                                   share(v);
              //         //                                 },
              //         //                               )
              //         //                             ],
              //         //                           )
              //         //                         ],
              //         //                       ),
              //         //                     ),
              //         //                   ],
              //         //                 ),
              //         //               ),
              //         //             ),
              //         //           ),
              //         //         ),
              //         //     ],
              //         //   ),
              //         // )
              //       ],
              //     ),
              //   ),
              // ),
              body: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.width / 2,
                          child: Image.asset('assets/images/Mascot.png'),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Aureal live rooms are coming soon!",
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 5),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Icon(Icons.wifi_tethering),
                        ),
                        Text(
                            "We'd love your feedbacks and suggestions in our discord.")
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        launcher.launchInBrowser('https://discord.gg/WJav6sKvZj');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(
                            0xff171b27))
                        //  color: kSecondaryColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FontAwesomeIcons.discord),
                              SizedBox(
                                width: 8.0,
                              ),
                              Text(
                                'Join our discord channel',
                                style: TextStyle(
                                    fontSize: SizeConfig.safeBlockHorizontal * 4),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
