// import 'package:auditory/Services/HiveOperations.dart';
// import 'package:auditory/utilities/SizeConfig.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:marquee/marquee.dart';
// import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
// import 'package:provider/provider.dart';
// import 'package:assets_audio_player/assets_audio_player.dart';
//
// import '../PlayerState.dart';
// import 'Player/Player.dart';
//
// class BottomPlayer1 extends StatelessWidget {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     var episodeObject = Provider.of<PlayerChange>(context);
//
//     return episodeObject.episodeName != null
//         ? GestureDetector(
//             onTap: () {
//               // showBottomSheet( {
//               //   return Container(
//               //     decoration: BoxDecoration(
//               //         border: Border(top: BorderSide(color: Colors.black)),
//               //         color: Colors.grey),
//               //     child: Padding(
//               //       padding: const EdgeInsets.all(32.0),
//               //       child: Text(
//               //         'This is a persistent bottom sheet. Drag downwards to dismiss it.',
//               //         textAlign: TextAlign.center,
//               //         style: TextStyle(
//               //           fontSize: 24.0,
//               //         ),
//               //       ),
//               //     ),
//               //   );
//               // });
//               showMaterialModalBottomSheet(
//                   context: context,
//                   builder: (context, ScrollController controller) {
//                     return Player();
//                   });
//               // showBarModalBottomSheet(
//               //     backgroundColor: Colors.transparent,
//               //     context: context,
//               //     builder: (context, _controller) {
//               //       return Player();
//               //     });
//               // showBottomSheet(
//               //     context: context,
//               //     builder: (context) {
//               //       return BottomSheet(
//               //           onClosing: () {
//               //             print('Closed');
//               //           },
//               //           enableDrag: false,
//               //           builder: (context) {
//               //             return Player();
//               //           });
//               //     });
//
//               // Navigator.pushNamed(context, Player.id);
//               // showBottomSheet(
//               //     context: context,
//               //     builder: (context) {
//               //       return Player();
//               //     });
//             },
//             child: Container(
//               height: SizeConfig.safeBlockVertical * 6,
//               width: double.infinity,
//               decoration: BoxDecoration(color: kSecondaryColor),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       episodeObject.audioPlayer.builderRealtimePlayingInfos(
//                           builder: (context, infos) {
//                         if (infos == null) {
//                           return SizedBox(
//                             height: 0,
//                             width: 0,
//                           );
//                         } else {
//                           if (infos.isBuffering == true) {
//                             return SpinKitCircle(
//                               size: 15,
//                               color: Colors.white,
//                             );
//                           } else {
//                             if (infos.isPlaying == true) {
//                               return IconButton(
//                                 icon: Icon(
//                                   Icons.pause,
//                                   color: Colors.white,
//                                 ),
//                                 onPressed: () {
//                                   episodeObject.pause();
//                                 },
//                               );
//                             } else {
//                               return IconButton(
//                                 icon: Icon(
//                                   Icons.play_arrow,
//                                   color: Colors.white,
//                                 ),
//                                 onPressed: () {
//                                   episodeObject.resume();
//                                 },
//                               );
//                             }
//                           }
//                         }
//                       }),
//                       // InkWell(
//                       //   onTap: () {
//                       //     upvoteEpisode(
//                       //         episode_id: episodeObject.id,
//                       //         permlink: episodeObject.permlink);
//                       //   },
//                       //   child: Padding(
//                       //     padding: const EdgeInsets.all(8.0),
//                       //     child: Icon(
//                       //       FontAwesomeIcons.chevronCircleUp,
//                       //       color: Colors.white,
//                       //     ),
//                       //   ),
//                       // ),
//                       SizedBox(
//                         width: 10,
//                       ),
//                       Container(
//                         height: 40,
//                         width: MediaQuery.of(context).size.width * 0.8,
//                         child: Marquee(
//                           pauseAfterRound: Duration(seconds: 2),
//                           text:
//                               '${episodeObject.episodeName}  -  ${episodeObject.podcastName}',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontSize: SizeConfig.safeBlockHorizontal * 3.2),
//                           blankSpace: 100,
// //                  scrollAxis: Axis.horizontal,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           )
//         : SizedBox(
//             height: 0,
//           );
//   }
// }
