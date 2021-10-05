import 'package:auditory/PlayerState.dart';
import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DiscoverProvider.dart';
import 'Onboarding/HiveDetails.dart';
import 'Player/Player.dart';
import 'Player/VideoPlayer.dart';
import 'Profiles/Comments.dart';
import 'Profiles/EpisodeView.dart';
import 'Profiles/PodcastView.dart';


class History extends StatefulWidget {
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  var recentlyPlayed = [];
  var homeData = [];

  SharedPreferences pref;
  @override
  Widget build(BuildContext context) {
    var currentlyPlaying = Provider.of<PlayerChange>(context);
    DiscoverProvider discoverData = Provider.of<DiscoverProvider>(context);
    if (discoverData.isFetcheddiscoverList == false) {
      discoverData.getDiscoverProvider();
    }

    setState(() {
      homeData = discoverData.discoverList;
    });
    for (var v in homeData) {
      if (v['Key'] == 'general_episode') {
        setState(() {
          recentlyPlayed = v['data'];
          for (var v in recentlyPlayed) {
            v['isLoading'] = false;
          }
        });
      }
    }
    return Scaffold(
      appBar: AppBar(),
     body:  ListView(
       children: [
         for (var a in recentlyPlayed)
           InkWell(
             onTap: () {
               print(a
                   .toString()
                   .contains('.mp4'));
               if (a.toString().contains('.mp4') == true ||
                   a.toString().contains(
                       '.m4v') ==
                       true ||
                   a.toString().contains(
                       '.flv') ==
                       true ||
                   a.toString().contains(
                       '.f4v') ==
                       true ||
                   a.toString().contains(
                       '.ogv') ==
                       true ||
                   a.toString().contains(
                       '.ogx') ==
                       true ||
                   a.toString().contains(
                       '.wmv') ==
                       true ||
                   a.toString().contains(
                       '.webm') ==
                       true) {
                 currentlyPlaying.stop();
                 Navigator.push(context,
                     CupertinoPageRoute(
                         builder:
                             (context) {
                           return PodcastVideoPlayer(
                               episodeObject: a);
                         }));
               } else {
                 if (a
                     .toString()
                     .contains(
                     '.pdf') ==
                     true) {
                   // Navigator.push(
                   //     context,
                   //     CupertinoPageRoute(
                   // der:
                   //             (context) {
                   //   return PDFviewer(
                   //       episodeObject:
                   //           v);
                   // }));
                 } else {
                   currentlyPlaying
                       .stop();
                   currentlyPlaying
                       .episodeObject = a;
                   print(currentlyPlaying
                       .episodeObject
                       .toString());
                   currentlyPlaying
                       .play();
                   Navigator.push(
                       context,
                       CupertinoPageRoute(
                           builder:
                               (context) {
                             return Player();
                           }));
                 }
               }
             },
             child: Container(
               width:
               MediaQuery.of(context)
                   .size
                   .width *
                   0.85,
               decoration: BoxDecoration(
                   borderRadius:
                   BorderRadius
                       .circular(
                       10)),
               child: Padding(
                 padding:
                 const EdgeInsets
                     .all(15),
                 child: Row(
                   crossAxisAlignment:
                   CrossAxisAlignment
                       .start,
                   children: [
                     Container(
                       width: MediaQuery.of(
                           context)
                           .size
                           .width /
                           4.5,
                       height: MediaQuery.of(
                           context)
                           .size
                           .width /
                           4.5,
                       child: Stack(
                         children: [
                           CachedNetworkImage(
                             imageBuilder:
                                 (context,
                                 imageProvider) {
                               return Container(
                                 height: MediaQuery.of(context).size.width /
                                     4.5,
                                 width: MediaQuery.of(context).size.width /
                                     4.5,
                                 decoration:
                                 BoxDecoration(
                                   borderRadius:
                                   BorderRadius.circular(8),
                                   image: DecorationImage(
                                       image: imageProvider,
                                       fit: BoxFit.cover),
                                 ),
                               );
                             },
                             memCacheHeight: (MediaQuery.of(context)
                                 .size
                                 .height)
                                 .floor(),
                             imageUrl: a['image'] !=
                                 null
                                 ? a['image']
                                 : 'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png',
                             placeholder:
                                 (context,
                                 imageProvider) {
                               return Container(
                                 decoration:
                                 BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/Thumbnail.png'), fit: BoxFit.cover)),
                                 height: MediaQuery.of(context).size.width *
                                     0.38,
                                 width: MediaQuery.of(context).size.width *
                                     0.38,
                               );
                             },
                           ),
                           Column(
                             mainAxisAlignment:
                             MainAxisAlignment
                                 .end,
                             children: [
                               FutureBuilder(
                                   future: dursaver.percentageDone(a[
                                   'id']),
                                   builder:
                                       (context, snapshot) {
                                     if (snapshot.data.toString() ==
                                         'null') {
                                       return Container();
                                     } else {
                                       // return Text(double.parse(snapshot.data.toString()).toStringAsFixed(2).toString());
                                       return Stack(
                                         children: [
                                           Container(
                                             decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
                                             width: MediaQuery.of(context).size.width / 4.5 * double.parse(double.parse(snapshot.data.toString()).toStringAsFixed(2)),
                                             height: 5,
                                           ),
                                           Container(
                                             width: MediaQuery.of(context).size.width / 4.5,
                                             height: 2,
                                           )
                                         ],
                                       );
                                     }
                                   }),
                             ],
                           ),
                         ],
                       ),
                     ),
                     Padding(
                       padding: const EdgeInsets
                           .symmetric(
                           horizontal:
                           15),
                       child: SizedBox(
                         width: MediaQuery.of(
                             context)
                             .size
                             .width /
                             2,
                         height: MediaQuery.of(
                             context)
                             .size
                             .width /
                             4.5,
                         child: Column(
                             mainAxisAlignment:
                             MainAxisAlignment
                                 .spaceBetween,
                             crossAxisAlignment:
                             CrossAxisAlignment
                                 .start,
                             children: [
                               Column(
                                 crossAxisAlignment:
                                 CrossAxisAlignment
                                     .start,
                                 children: [
                                   Padding(
                                     padding:
                                     const EdgeInsets.only(bottom: 10),
                                     child:
                                     GestureDetector(
                                       onTap:
                                           () {
                                         // Navigator.push(context, CupertinoPageRoute(widget: EpisodeView(episodeId: a['id'])));
                                         Navigator.push(context, CupertinoPageRoute(builder: (context) {
                                           return EpisodeView(
                                             episodeId: a['id'],
                                           );
                                         }));
                                       },
                                       child:
                                       GestureDetector(
                                         onTap: () {
                                           Navigator.push(context, CupertinoPageRoute(builder: (context) {
                                             return PodcastView(a['podcast_id']);
                                           }));
                                         },
                                         child: Padding(
                                           padding:   const EdgeInsets.only(top: 12),
                                           child: Text(
                                             a['name'].toString(),
                                             overflow: TextOverflow.clip,
                                             maxLines: 2,
                                             textScaleFactor: 1.0,
                                             style: TextStyle(fontWeight: FontWeight.w700, fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ),
                                   Text(
                                     a['podcast_name']
                                         .toString(),
                                     textScaleFactor:
                                     1.0,
                                     maxLines:
                                     1,
                                     overflow:
                                     TextOverflow.ellipsis,
                                     style: TextStyle(
                                         color: Color(0xff777777),
                                         fontSize: SizeConfig.safeBlockHorizontal * 2.8),
                                   ),
                                   // a['permlink'] ==
                                   //     null
                                   //     ? SizedBox()
                                   //     : Row(
                                   //   children: [
                                   //     InkWell(
                                   //       onTap: () async {
                                   //         if (pref.getString('HiveUserName') != null) {
                                   //           // setState(() {
                                   //           //   v['isLoading'] = true;
                                   //           // });
                                   //           double _value = 50.0;
                                   //           showDialog(
                                   //               context: context,
                                   //               builder: (context) {
                                   //                 return Dialog(backgroundColor: Colors.transparent, child: UpvoteEpisode(permlink: a['permlink'], episode_id: a['id']));
                                   //               }).then((value) async {
                                   //             print(value);
                                   //           });
                                   //           setState(() {
                                   //             a['ifVoted'] = !a['ifVoted'];
                                   //           });
                                   //           setState(() {
                                   //             a['isLoading'] = false;
                                   //           });
                                   //         } else {
                                   //           showBarModalBottomSheet(
                                   //               context: context,
                                   //               builder: (context) {
                                   //                 return HiveDetails();
                                   //               });
                                   //         }
                                   //       },
                                   //       child: Container(
                                   //         decoration: a['ifVoted'] == true ? BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Color(0xff5bc3ef), Color(0xff5d5da8)])) : BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xff222222))),
                                   //         child: Padding(
                                   //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                   //           child: Row(
                                   //             children: [
                                   //               a['isLoading'] == true
                                   //                   ? SpinKitCircle(
                                   //                 color: Colors.white,
                                   //                 size: 10,
                                   //               )
                                   //                   : Icon(
                                   //                 FontAwesomeIcons.chevronCircleUp,
                                   //                 size: 15,
                                   //               ),
                                   //               SizedBox(
                                   //                 width: 5,
                                   //               ),
                                   //               Text(
                                   //                 "${a['payout_value'].toString().split(' ')[0]}",
                                   //                 textScaleFactor: 1.0,
                                   //               ),
                                   //             ],
                                   //           ),
                                   //         ),
                                   //       ),
                                   //     ),
                                   //     SizedBox(
                                   //       width: 10,
                                   //     ),
                                   //     InkWell(
                                   //       onTap: () {
                                   //         if (pref.getString('HiveUserName') != null) {
                                   //           Navigator.push(
                                   //               context,
                                   //               CupertinoPageRoute(
                                   //                   builder: (context) => Comments(
                                   //                     episodeObject: a,
                                   //                   )));
                                   //         } else {
                                   //           showBarModalBottomSheet(
                                   //               context: context,
                                   //               builder: (context) {
                                   //                 return HiveDetails();
                                   //               });
                                   //         }
                                   //       },
                                   //       child: Container(
                                   //         decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xff222222))),
                                   //         child: Padding(
                                   //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                   //           child: Row(
                                   //             mainAxisSize: MainAxisSize.min,
                                   //             children: [
                                   //               Icon(
                                   //                 Icons.mode_comment_outlined,
                                   //                 size: 15,
                                   //               ),
                                   //               SizedBox(
                                   //                 width: 5,
                                   //               ),
                                   //               Text(
                                   //                 '${a['comments_count'].toString()}',
                                   //                 textScaleFactor: 1.0,
                                   //               )
                                   //             ],
                                   //           ),
                                   //         ),
                                   //       ),
                                   //     ),
                                   //   ],
                                   // )
                                 ],
                               ),
                             ]
                         ),
                       ),
                     )
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
