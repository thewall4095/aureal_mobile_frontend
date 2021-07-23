import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

enum CommentState {
  reply,
  comment,
}

class Comments extends StatefulWidget {
  var episodeObject;

  Comments({this.episodeObject});

  @override
  _CommentsState createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  String getDuration() {}

  TextEditingController _commentsController;

  postreq.Interceptor intercept = postreq.Interceptor();

  CommentState texting = CommentState.comment;

  String replyingTo;
  bool isSending = false;

  String comment;
  String reply;
  var soundBlob;
  var comments = [];
  var replies = [];
  String user;
  int commentId;
  var expanded = [];
  String displayPicture;
  String commentPermlink;

  void deleteComment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/deleteComment';
    var map = Map<String, dynamic>();
    map['id'] = prefs.getString('userId');
    map['comment_id'] = commentId;

    FormData formData = FormData.fromMap(map);
    var response = intercept.postRequest(formData, url);
    print(response);
    await getComments();
  }

  void getComments() async {
    String url =
        'https://api.aureal.one/public/getComments?episode_id=${widget.episodeObject['id']}';
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          user = prefs.getString('userName');
          comments = jsonDecode(response.body)['comments'];

          displayPicture = prefs.getString('displayPicture');
          for (var v in comments) {
            expanded.add("0");
          }
        });
        print(comments);
        print(user);
      }
    } catch (e) {
      print(e);
    }
  }

  void postComment() async {
    setState(() {
      isSending = true;
    });
    String url = 'https://api.aureal.one/private/comment';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = widget.episodeObject['id'];
    map['text'] = comment;
    if (widget.episodeObject['permlink'] != null) {
      map['hive_username'] = prefs.getString('HiveUserName');
    }

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response);
    await getComments();
    _commentsController.clear();
    setState(() {
      isSending = false;
    });
  }

  void postReply() async {
    setState(() {
      isSending = true;
    });
    String url = 'https://api.aureal.one/private/reply';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['text'] = reply;
    map['comment_id'] = commentId;
    // if (commentPermlink != null) {
    map['hive_username'] = prefs.getString('HiveUserName');
    // }
    print(map.toString());
    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.toString());
    await getComments();
    _commentsController.clear();
    setState(() {
      isSending = false;
    });
  }

  void upVoteComment(String commentId) async {
    postreq.Interceptor interceptor = postreq.Interceptor();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String url = 'https://api.aureal.one/public/voteComment';

    var map = Map<String, dynamic>();
    map['hive_username'] = prefs.getString('HiveUserName');
    map['comment_id'] = commentId;
    map['user_id'] = prefs.getString('userId');
    FormData formData = FormData.fromMap(map);

    try {
      var response = await interceptor.postRequest(formData, url);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _commentsController = TextEditingController();
    getComments();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, 'done');
          },
          icon: Icon(
            Icons.navigate_before,
          ),
        ),
        title: Text(
          "Comments",
          textScaleFactor:
              mediaQueryData.textScaleFactor.clamp(0, 1).toDouble(),
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              if (index == comments.length) {
                return SizedBox(
                  height: 400,
                );
              } else {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  child: Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: comments[index]['user_image'] == null
                                    ? AssetImage('assets/images/person.png')
                                    : NetworkImage(
                                        comments[index]['user_image']),
                                fit: BoxFit.cover),
                            shape: BoxShape.circle,
                            // color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      // Wrap(
                                      //   direction: Axis.horizontal,
                                      //   children: <Widget>[
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${comments[index]['author']}',
                                              textScaleFactor: mediaQueryData
                                                  .textScaleFactor
                                                  .clamp(0.5, 1)
                                                  .toDouble(),
                                              style: TextStyle(
                                                  // color: Color(0xffe8e8e8),
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              timeago.format(DateTime.parse(
                                                  comments[index]
                                                      ['createdAt'])),
                                              textScaleFactor: mediaQueryData
                                                  .textScaleFactor
                                                  .clamp(0.5, 1)
                                                  .toDouble(),
                                              style: TextStyle(
                                                  // color: Colors.grey,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      2,
                                                  color: Color(0xffe8e8e8)
                                                      .withOpacity(0.5)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${comments[index]['text']}',
                                        textScaleFactor: mediaQueryData
                                            .textScaleFactor
                                            .clamp(0.5, 1)
                                            .toDouble(),
                                        style: TextStyle(
                                            // color: Colors.white,
                                            fontWeight: FontWeight.normal),
                                      ),
                                      //   ],
                                      // ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      Row(
                                        children: <Widget>[
                                          SizedBox(
                                            width: 20,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                texting = CommentState.reply;
                                                replyingTo =
                                                    comments[index]['author'];
                                                commentId =
                                                    comments[index]['id'];
                                              });
                                            },
                                            child: Text(
                                              "Reply",
                                              textScaleFactor: mediaQueryData
                                                  .textScaleFactor
                                                  .clamp(0.5, 1)
                                                  .toDouble(),
                                              style: TextStyle(
                                                  // color: Colors.grey,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3),
                                            ),
                                          )
                                        ],
                                      ),
                                      // comments[index]['comments'] == null
                                      // ? SizedBox(
                                      //     height: 0,
                                      //   )
                                      // : ExpansionTile(
                                      //     backgroundColor: Colors.transparent,
                                      //     trailing: SizedBox(
                                      //       width: 0,
                                      //     ),
                                      //     title: Align(
                                      //       alignment: Alignment.centerLeft,
                                      //       child: Text(
                                      //         "View replies",
                                      //         textScaleFactor: mediaQueryData
                                      //             .textScaleFactor
                                      //             .clamp(0.5, 1)
                                      //             .toDouble(),
                                      //         style: TextStyle(
                                      //           fontSize: SizeConfig
                                      //                   .safeBlockHorizontal *
                                      //               3,
                                      //           // color: Colors.grey,
                                      //         ),
                                      //       ),
                                      //     ),
                                      //     children: <Widget>[
                                      //       for (var v in comments[index]
                                      //           ['comments'])
                                      //         Align(
                                      //           alignment:
                                      //               Alignment.centerLeft,
                                      //           child: Padding(
                                      //             padding:
                                      //                 const EdgeInsets.only(
                                      //                     bottom: 10),
                                      //             child: Container(
                                      //               child: Row(
                                      //                 children: <Widget>[
                                      //                   CircleAvatar(
                                      //                     radius: 20,
                                      //                     backgroundImage: v[
                                      //                                 'user_image'] ==
                                      //                             null
                                      //                         ? NetworkImage(
                                      //                             'https://aurealbucket.s3.us-east-2.amazonaws.com/Thumbnail.png')
                                      //                         : NetworkImage(v[
                                      //                             'user_image']),
                                      //                   ),
                                      //                   SizedBox(width: 10),
                                      //                   Expanded(
                                      //                     child: Row(
                                      //                       mainAxisAlignment:
                                      //                           MainAxisAlignment
                                      //                               .spaceBetween,
                                      //                       children: [
                                      //                         Column(
                                      //                           crossAxisAlignment:
                                      //                               CrossAxisAlignment
                                      //                                   .start,
                                      //                           children: <
                                      //                               Widget>[
                                      //                             Text(
                                      //                               '${v['author']}',
                                      //                               textScaleFactor:
                                      //                                   1.0,
                                      //                               style: TextStyle(
                                      //                                   fontWeight:
                                      //                                       FontWeight.w600),
                                      //                             ),
                                      //
                                      //                             Text(
                                      //                               '${v['text']}',
                                      //                               textScaleFactor:
                                      //                                   1.0,
                                      //                               style: TextStyle(
                                      //                                   // color: Colors
                                      //                                   //     .white,
                                      //                                   fontWeight: FontWeight.normal),
                                      //                             ),
                                      //                             //   ],
                                      //                             // ),
                                      //                             // Text(
                                      //                             //   '${v['author']}  ${v['text']}',
                                      //                             //   style: TextStyle(
                                      //                             //       color: Colors
                                      //                             //           .white,
                                      //                             //       fontSize:
                                      //                             //           SizeConfig.safeBlockHorizontal *
                                      //                             //               3.2),
                                      //                             // ),
                                      //                             Row(
                                      //                               children: <
                                      //                                   Widget>[
                                      //                                 Text(
                                      //                                   timeago
                                      //                                       .format(DateTime.parse(v['createdAt'])),
                                      //                                   textScaleFactor:
                                      //                                       1.0,
                                      //                                   style: TextStyle(
                                      //                                       // color: Colors.grey,
                                      //                                       fontSize: SizeConfig.safeBlockHorizontal * 3),
                                      //                                 ),
                                      //                                 SizedBox(
                                      //                                   width:
                                      //                                       10,
                                      //                                 ),
                                      //                                 GestureDetector(
                                      //                                   onTap:
                                      //                                       () {
                                      //                                     setState(() {
                                      //                                       texting = CommentState.reply;
                                      //                                       replyingTo = v['author'];
                                      //                                       commentId = comments[index]['id'];
                                      //                                       commentPermlink = comments[index]['permlink'];
                                      //                                     });
                                      //                                     showModalBottomSheet(
                                      //                                         context: context,
                                      //                                         builder: (context) {
                                      //                                           return SingleChildScrollView(
                                      //                                             child: Container(
                                      //                                               padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                      //                                               child: Column(
                                      //                                                 children: <Widget>[
                                      //                                                   Container(
                                      //                                                     color: kSecondaryColor,
                                      //                                                     child: Padding(
                                      //                                                       padding: const EdgeInsets.symmetric(horizontal: 10),
                                      //                                                       child: Row(
                                      //                                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      //                                                         children: <Widget>[
                                      //                                                           Text(
                                      //                                                             "Replying to $replyingTo",
                                      //                                                             textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                      //                                                             style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                      //                                                           ),
                                      //                                                           IconButton(
                                      //                                                             onPressed: () {
                                      //                                                               setState(() {
                                      //                                                                 texting = CommentState.comment;
                                      //                                                               });
                                      //                                                             },
                                      //                                                             icon: Icon(
                                      //                                                               Icons.clear,
                                      //                                                               // color: Colors.grey,
                                      //                                                               size: 15,
                                      //                                                             ),
                                      //                                                           )
                                      //                                                         ],
                                      //                                                       ),
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                   Container(
                                      //                                                     color: kSecondaryColor,
                                      //                                                     child: Padding(
                                      //                                                       padding: const EdgeInsets.symmetric(horizontal: 10),
                                      //                                                       child: Row(
                                      //                                                         children: <Widget>[
                                      //                                                           CircleAvatar(
                                      //                                                             radius: 15,
                                      //                                                             backgroundImage: displayPicture == null ? AssetImage('assets/images/Thumbnail.png') : NetworkImage(displayPicture),
                                      //                                                           ),
                                      //                                                           SizedBox(
                                      //                                                             width: 10,
                                      //                                                           ),
                                      //                                                           Expanded(
                                      //                                                               child: TextField(
                                      //                                                             controller: _commentsController,
                                      //                                                             enabled: true,
                                      //                                                             minLines: 1,
                                      //                                                             maxLines: 10,
                                      //                                                             decoration: InputDecoration(border: InputBorder.none, hintText: 'Reply as @$user', hintStyle: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.2)),
                                      //                                                             onChanged: (value) {
                                      //                                                               setState(() {
                                      //                                                                 reply = value;
                                      //                                                               });
                                      //                                                             },
                                      //                                                           )),
                                      //                                                           FlatButton(
                                      //                                                             onPressed: () async {
                                      //                                                               if (reply != null) {
                                      //                                                                 print(commentId);
                                      //                                                                 await postReply();
                                      //                                                               }
                                      //                                                             },
                                      //                                                             child: Text(
                                      //                                                               "Reply",
                                      //                                                               textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
                                      //                                                               style: TextStyle(color: kActiveColor, fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                                      //                                                             ),
                                      //                                                           )
                                      //                                                         ],
                                      //                                                       ),
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                 ],
                                      //                                               ),
                                      //                                             ),
                                      //                                           );
                                      //                                         });
                                      //                                   },
                                      //                                   child:
                                      //                                       Text(
                                      //                                     'Reply',
                                      //                                     textScaleFactor:
                                      //                                         1.0,
                                      //                                     style:
                                      //                                         TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
                                      //                                   ),
                                      //                                 )
                                      //                               ],
                                      //                             )
                                      //                           ],
                                      //                         ),
                                      //                         IconButton(
                                      //                           onPressed:
                                      //                               () {
                                      //                             upVoteComment(v[
                                      //                                     'id']
                                      //                                 .toString());
                                      //                           },
                                      //                           icon: Icon(
                                      //                             FontAwesomeIcons
                                      //                                 .chevronCircleUp,
                                      //                             // color: Colors
                                      //                             //     .white,
                                      //                           ),
                                      //                         )
                                      //                       ],
                                      //                     ),
                                      //                   ),
                                      //                 ],
                                      //               ),
                                      //             ),
                                      //           ),
                                      //         )
                                      //     ],
                                      //   )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),

                        // Icon(
                        //   FontAwesomeIcons.heart,
                        //   color: Colors.white,
                        //   size: 13,
                        // )
                      ],
                    ),
                  ),
                );
              }
            },
            itemCount: comments.length + 1,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Stack(
                children: [
                  Container(
                    child: isSending == false
                        ? SizedBox(
                            width: 0,
                          )
                        : LinearProgressIndicator(
                            minHeight: 50,
                            backgroundColor: Colors.blue,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff6249EF)),
                          ),
                  ),
                  texting == CommentState.reply
                      ? Builder(
                          builder: (context) {
                            return SingleChildScrollView(
                              child: Container(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      color: isSending == false
                                          ? kSecondaryColor
                                          : Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text(
                                              "Replying to $replyingTo",
                                              textScaleFactor: mediaQueryData
                                                  .textScaleFactor
                                                  .clamp(0.5, 1)
                                                  .toDouble(),
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: SizeConfig
                                                          .safeBlockHorizontal *
                                                      3.2),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  texting =
                                                      CommentState.comment;
                                                });
                                              },
                                              icon: Icon(
                                                Icons.clear,
                                                color: Colors.grey,
                                                size: 15,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      color: kSecondaryColor,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Row(
                                          children: <Widget>[
                                            CircleAvatar(
                                              radius: 15,
                                              backgroundImage: displayPicture ==
                                                      null
                                                  ? AssetImage(
                                                      'assets/images/Thumbnail.png')
                                                  : NetworkImage(
                                                      displayPicture),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                                child: TextField(
                                              scrollPadding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom),
                                              controller: _commentsController,
                                              enabled: true,
                                              minLines: 1,
                                              maxLines: 10,
                                              style: TextStyle(
                                                  color: Colors.white),
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: 'Reply as @$user',
                                                  hintStyle: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: SizeConfig
                                                              .safeBlockHorizontal *
                                                          3.2)),
                                              onChanged: (value) {
                                                setState(() {
                                                  reply = value;
                                                });
                                              },
                                            )),
                                            FlatButton(
                                              onPressed: () async {
                                                if (reply != null) {
                                                  print(commentId);
                                                  await postReply();
                                                }
                                              },
                                              child: Text(
                                                "Reply",
                                                textScaleFactor: mediaQueryData
                                                    .textScaleFactor
                                                    .clamp(0.5, 1)
                                                    .toDouble(),
                                                style: TextStyle(
                                                    color: kActiveColor,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3.2),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Builder(
                          builder: (context) {
                            return SingleChildScrollView(
                              child: Container(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                color: isSending == false
                                    ? kSecondaryColor
                                    : Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundImage: displayPicture == null
                                            ? AssetImage(
                                                'assets/images/Thumbnail.png')
                                            : NetworkImage(displayPicture),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                          child: TextField(
                                        scrollPadding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context)
                                                .viewInsets
                                                .bottom),
                                        controller: _commentsController,
                                        enabled: true,
                                        minLines: 1,
                                        maxLines: 10,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'Comment as @$user',
                                            hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    3.4)),
                                        onChanged: (value) {
                                          setState(() {
                                            comment = value;
                                          });
                                        },
                                      )),
                                      FlatButton(
                                        onPressed: () async {
                                          if (comment != null) {
                                            await postComment();
                                          }
                                        },
                                        child: Text(
                                          "Post",
                                          textScaleFactor: mediaQueryData
                                              .textScaleFactor
                                              .clamp(0.5, 1)
                                              .toDouble(),
                                          style: TextStyle(
                                              color: kActiveColor,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3.4),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
