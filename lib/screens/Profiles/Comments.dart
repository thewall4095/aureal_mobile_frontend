import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:linkable/linkable.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Dio dio = Dio();

  CancelToken cancel = CancelToken();

  var commentsData;

  SharedPreferences prefs;

  Future getComments() async {
    prefs = await SharedPreferences.getInstance();
    String url = "https://rpc.ecency.com";
    print(url);
    var map = Map<String, dynamic>();
    map = {
      "jsonrpc": "2.0",
      "method": "bridge.get_discussion",
      "params": {
        'author': widget.episodeObject['author_hiveusername'],
        'permlink': widget.episodeObject['permlink'],
        'observer': ""
      },
      "id": 0
    };

    

    print(map);

    try{
      await dio.post(url, data: map, cancelToken: cancel).then((value) {
        Map<String, dynamic> result;
        result = value.data['result'];
        setState(() {
          commentKeys = result.keys.toList();
          commentsData = value.data['result'];
        });



        print(commentKeys);
        return value.data['result'];
      });
    }catch(e){
      print(e);
    }
  }

  var commentKeys = [];


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

  Future commentsFuture;

  void commentsgetter() async {

      commentsFuture = getComments();


  }

  @override
  void initState() {
    // TODO: implement initState
    commentsgetter();

    super.initState();
    _commentsController = TextEditingController();

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          "${widget.episodeObject['podcast_name']}",
          textScaleFactor: 1.0,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
//       body: FutureBuilder(future: commentsFuture, builder: (context, snapshot){
//         if(snapshot.hasData){
//           return ListView.builder(shrinkWrap: true,itemBuilder: (context, int index){
//             return Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Container(
//                 width: double.infinity,
//                 height: 100,
//                 color: Colors.blue,
//                 child: Text("${commentKeys.toString()}", style: TextStyle(color: Colors.white),),
//               ),
//             );
//           }, itemCount: commentKeys.length,);
//         }else{
//           return Container(
// color: Colors.white,
//           );
//         }
//       },),
    body: Stack(
      children: [
        ListView.builder(itemBuilder: (context, int index){
          if(index ==  0){
            return SizedBox();
          }else{
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CommentCard(data: commentsData['${commentKeys[index].toString()}']),
            );
          }

        }, itemCount: commentKeys.length,),
        Align(alignment: Alignment.bottomCenter,child: Container(color: kSecondaryColor,child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(enableIMEPersonalizedLearning: true,
            controller: _commentsController, decoration: InputDecoration(suffix: IconButton(icon: Icon(Icons.send,size: 20,),) ,suffixIconConstraints: BoxConstraints(maxWidth: 20, maxHeight: 20),prefixIconConstraints: BoxConstraints(maxHeight: 30, maxWidth: 30),prefixIcon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(height: 20, width:20,child: CircleAvatar(radius: 5,backgroundImage: Image.network('https://images.hive.blog/u/${prefs.getString('HiveUserName')}/avatar').image,)),
            ),contentPadding: EdgeInsets.only(bottom: 14),border: InputBorder.none,hintText: "commenting as @${prefs.getString('HiveUserName').toString()}"),),
        ),
        )),
      ],

    ),

    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     final mediaQueryData = MediaQuery.of(context);
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context, 'done');
//           },
//           icon: Icon(
//             Icons.navigate_before,
//           ),
//
//         ),
//         title: Text(
//           "${widget.episodeObject['podcast_name']}",
//           textScaleFactor: 1.0,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//               fontSize: SizeConfig.safeBlockHorizontal * 3,
//               fontWeight: FontWeight.w800,
//           ),
//         ),
//       ),
//       body:
//           Container(
//             height: MediaQuery.of(context).size.height,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: [
//                 new BoxShadow(
//                   color: Colors.black
//                       .withOpacity(01),
//                   blurRadius: 5.0,
//                 ),
//               ],
//               color:
//               themeProvider.isLightTheme ==
//                   true
//                   ? Colors.white
//                   : Color(0xff1a1a1a),
//
//             ),
//             child: Stack(
//               children: <Widget>[
//                 ListView.builder(
//                   itemBuilder: (BuildContext context, int index) {
//                     if (index == comments.length) {
//                       return SizedBox(
//                         height: 400,
//                       );
//                     } else {
//                       return Padding(
//                         padding: const EdgeInsets.all(15.0),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: <Widget>[
//                             Container(
//                               height: 40,
//                               width: 40,
//                               decoration: BoxDecoration(
//                                 image: DecorationImage(
//                                     image: comments[index]
//                                                 ['user_image'] ==
//                                             null
//                                         ? AssetImage(
//                                             'assets/images/person.png')
//                                         : NetworkImage(comments[index]
//                                             ['user_image']),
//                                     fit: BoxFit.cover),
//                                 shape: BoxShape.circle,
//                                 // color: Colors.white,
//                               ),
//                             ),
//                             Expanded(
//                               child: Padding(
//                                 padding: const EdgeInsets.only(left: 10),
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                       boxShadow: [
//                                         new BoxShadow(
//                                           color: Colors.black
//                                               .withOpacity(01),
//                                           blurRadius: 5.0,
//                                         ),
//                                       ],
//                                     color: themeProvider.isLightTheme == true
//                                         ? Colors.white
//                                         : kPrimaryColor,
//                                     borderRadius:BorderRadius.only(
//                                         topRight: Radius.circular(15.0),
//                                         bottomRight: Radius.circular(15.0),
//                                           bottomLeft: Radius.circular(15))),
//                                   child: Row(
//
//                                     children: <Widget>[
//                                       SizedBox(
//                                         width: 15,
//                                       ),
//                                       Expanded(
//                                         child: Padding(
//                                           padding: const EdgeInsets.all(10.0),
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: <Widget>[
//                                               Text(
//                                                 '${comments[index]['author']}',
//                                                 textScaleFactor: mediaQueryData
//                                                     .textScaleFactor
//                                                     .clamp(0.5, 1)
//                                                     .toDouble(),
//                                                 style: TextStyle(
//                                                     // color: Color(0xffe8e8e8),
//                                                     fontWeight:
//                                                         FontWeight.w600),
//                                               ),
//                                               SizedBox(height: 5,),
//                                               Text(
//                                                 '${comments[index]['text']}',
//                                                 textScaleFactor: mediaQueryData
//                                                     .textScaleFactor
//                                                     .clamp(0.5, 1)
//                                                     .toDouble(),
//                                                 style: TextStyle(
//
//                                                     fontWeight:
//                                                         FontWeight.normal),
//                                               ),
//                                               SizedBox(
//                                                 height: 10,
//                                               ),
//                                               Row(
//                                                 mainAxisAlignment: MainAxisAlignment.start,
//                                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                                 children: <Widget>[
//
//                                                   GestureDetector(
//                                                     onTap: () {
//                                                       setState(() {
//                                                         texting =
//                                                             CommentState.reply;
//                                                         replyingTo =
//                                                             comments[index]
//                                                                 ['author'];
//                                                         commentId =
//                                                             comments[index]
//                                                                 ['id'];
//                                                       });
//                                                     },
//                                                     child: Container(
//                                                       decoration: BoxDecoration(
//                                                           color: Colors.blue,
//                                                    borderRadius: BorderRadius.circular(20)
//                                                       ),
//                                                       height: MediaQuery.of(context).size.height/30,
//                                                       width: MediaQuery.of(context).size.width/6,
//                                                       child: Center(
//                                                         child: Text(
//                                                           "Reply",
//                                                           textScaleFactor:
//                                                               mediaQueryData
//                                                                   .textScaleFactor
//                                                                   .clamp(0.5, 1)
//                                                                   .toDouble(),
//                                                           style: TextStyle(
//                                                               // color: Colors.grey,
//                                                               fontSize: SizeConfig
//                                                                       .safeBlockHorizontal *
//                                                                   3),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   SizedBox(
//                                                     width: 20,
//                                                   ),
//                                                   Container(
//                                                     decoration: BoxDecoration(
//                                                       borderRadius: BorderRadius.circular(15),
//                                                       color: Colors.blue,
//                                                     ),
//                                                     height: MediaQuery.of(context).size.height/30,
//                                                     width: MediaQuery.of(context).size.width/3.9,
//                                                     child: Row(
//                                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                                       children: [
//                                                         Padding(
//                                                           padding: const EdgeInsets.all(8.0),
//                                                           child: Text("Upvote"),
//                                                         ),
//                                                         IconButton(
//                                                           onPressed: () {
//                                                             upVoteComment(
//                                                                 comments[index]['id'].toString());
//                                                           },
//                                                           icon: Icon(
//                                                             FontAwesomeIcons.chevronCircleUp,
//                                                             size: 15,
//                                                             // color: Colors.white,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   )
//                                                 ],
//                                               ),
//                                               comments[index]['comments'] ==
//                                                       null
//                                                   ? SizedBox(
//                                                       height: 0,
//                                                     )
//                                                   : ExpansionTile(
//                                                       backgroundColor:
//                                                           Colors.transparent,
//                                                       trailing: SizedBox(
//                                                         width: 0,
//                                                       ),
//                                                       title: Align(
//                                                         alignment: Alignment
//                                                             .centerLeft,
//                                                         child: Text(
//                                                           "View replies",
//                                                           textScaleFactor:
//                                                               mediaQueryData
//                                                                   .textScaleFactor
//                                                                   .clamp(0.5, 1)
//                                                                   .toDouble(),
//                                                           style: TextStyle(
//                                                             fontSize: SizeConfig
//                                                                     .safeBlockHorizontal *
//                                                                 3,
//                                                             // color: Colors.grey,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       children: <Widget>[
//                                                         for (var v
//                                                             in comments[index]
//                                                                 ['comments'])
//                                                           Align(
//                                                             alignment: Alignment
//                                                                 .centerLeft,
//                                                             child: Padding(
//                                                               padding:
//                                                                   const EdgeInsets
//                                                                           .only(
//                                                                       bottom:
//                                                                           10),
//                                                               child: Container(
//                                                                 child: Row(
//                                                                   children: <
//                                                                       Widget>[
//                                                                     CircleAvatar(
//                                                                       radius:
//                                                                           20,
//                                                                       backgroundImage: v['user_image'] ==
//                                                                               null
//                                                                           ? NetworkImage(
//                                                                               placeholderUrl)
//                                                                           : NetworkImage(
//                                                                               v['user_image']),
//                                                                     ),
//                                                                     SizedBox(
//                                                                         width:
//                                                                             10),
//                                                                     Expanded(
//                                                                       child:
//                                                                           Row(
//                                                                         mainAxisAlignment:
//                                                                             MainAxisAlignment.spaceBetween,
//                                                                         children: [
//                                                                           Column(
//                                                                             crossAxisAlignment:
//                                                                                 CrossAxisAlignment.start,
//                                                                             children: <Widget>[
//                                                                               Text(
//                                                                                 '${v['author']}',
//                                                                                 textScaleFactor: 1.0,
//                                                                                 style: TextStyle(fontWeight: FontWeight.w600),
//                                                                               ),
//
//                                                                               Text(
//                                                                                 '${v['text']}',
//                                                                                 textScaleFactor: 1.0,
//                                                                                 style: TextStyle(
//                                                                                     // color: Colors
//                                                                                     //     .white,
//                                                                                     fontWeight: FontWeight.normal),
//                                                                               ),
//
//                                                                               Row(
//                                                                                 children: <Widget>[
//                                                                                   SizedBox(
//                                                                                     width: 10,
//                                                                                   ),
//                                                                                   GestureDetector(
//                                                                                     onTap: () {
//                                                                                       setState(() {
//                                                                                         texting = CommentState.reply;
//                                                                                         replyingTo = v['author'];
//                                                                                         commentId = comments[index]['id'];
//                                                                                         commentPermlink = comments[index]['permlink'];
//                                                                                       });
//                                                                                       showModalBottomSheet(
//                                                                                           context: context,
//                                                                                           builder: (context) {
//                                                                                             return SingleChildScrollView(
//                                                                                               child: Container(
//                                                                                                 padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//                                                                                                 child: Column(
//                                                                                                   children: <Widget>[
//                                                                                                     Container(
//                                                                                                       color: kSecondaryColor,
//                                                                                                       child: Padding(
//                                                                                                         padding: const EdgeInsets.symmetric(horizontal: 10),
//                                                                                                         child: Row(
//                                                                                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                                                                           children: <Widget>[
//                                                                                                             Text(
//                                                                                                               "Replying to $replyingTo",
//                                                                                                               textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
//                                                                                                               style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.2),
//                                                                                                             ),
//                                                                                                             IconButton(
//                                                                                                               onPressed: () {
//                                                                                                                 setState(() {
//                                                                                                                   texting = CommentState.comment;
//                                                                                                                 });
//                                                                                                               },
//                                                                                                               icon: Icon(
//                                                                                                                 Icons.clear,
//                                                                                                                 // color: Colors.grey,
//                                                                                                                 size: 15,
//                                                                                                               ),
//                                                                                                             )
//                                                                                                           ],
//                                                                                                         ),
//                                                                                                       ),
//                                                                                                     ),
//                                                                                                     Container(
//                                                                                                       color: kSecondaryColor,
//                                                                                                       child: Padding(
//                                                                                                         padding: const EdgeInsets.symmetric(horizontal: 10),
//                                                                                                         child: Row(
//                                                                                                           children: <Widget>[
//                                                                                                             CircleAvatar(
//                                                                                                               radius: 15,
//                                                                                                               backgroundImage: displayPicture == null ? AssetImage('assets/images/Thumbnail.png') : NetworkImage(displayPicture),
//                                                                                                             ),
//                                                                                                             SizedBox(
//                                                                                                               width: 10,
//                                                                                                             ),
//                                                                                                             Expanded(
//                                                                                                                 child: TextField(
//                                                                                                               controller: _commentsController,
//                                                                                                               enabled: true,
//                                                                                                               minLines: 1,
//                                                                                                               maxLines: 10,
//                                                                                                               decoration: InputDecoration(border: InputBorder.none, hintText: 'Reply as @$user', hintStyle: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.2)),
//                                                                                                               onChanged: (value) {
//                                                                                                                 setState(() {
//                                                                                                                   reply = value;
//                                                                                                                 });
//                                                                                                               },
//                                                                                                             )),
//                                                                                                             FlatButton(
//                                                                                                               onPressed: () async {
//                                                                                                                 if (reply != null) {
//                                                                                                                   print(commentId);
//                                                                                                                   await postReply();
//                                                                                                                 }
//                                                                                                               },
//                                                                                                               child: Text(
//                                                                                                                 "Reply",
//                                                                                                                 textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
//                                                                                                                 style: TextStyle(color: kActiveColor, fontSize: SizeConfig.safeBlockHorizontal * 3.2),
//                                                                                                               ),
//                                                                                                             )
//                                                                                                           ],
//                                                                                                         ),
//                                                                                                       ),
//                                                                                                     ),
//                                                                                                   ],
//                                                                                                 ),
//                                                                                               ),
//                                                                                             );
//                                                                                           });
//                                                                                     },
//                                                                                     child: Text(
//                                                                                       'Reply',
//                                                                                       textScaleFactor: 1.0,
//                                                                                       style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
//                                                                                     ),
//                                                                                   )
//                                                                                 ],
//                                                                               )
//                                                                             ],
//                                                                           ),
//                                                                           IconButton(
//                                                                             onPressed:
//                                                                                 () {
//                                                                               upVoteComment(v['id'].toString());
//                                                                             },
//                                                                             icon:
//                                                                                 Icon(
//                                                                               FontAwesomeIcons.chevronCircleUp,
//                                                                               // color: Colors
//                                                                               //     .white,
//                                                                             ),
//                                                                           )
//                                                                         ],
//                                                                       ),
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           )
//                                                       ],
//                                                     )
//                                             ],
//                                           ),
//                                         ),
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(
//                               width: 10,
//                             ),
//                             // Icon(
//                             //   FontAwesomeIcons.heart,
//                             //   color: Colors.white,
//                             //   size: 13,
//                             // )
//                           ],
//                         ),
//                       );
//                     }
//                   },
//                   itemCount: comments.length + 1,
//                 ),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: <Widget>[
//                     Stack(
//                       children: [
//                         Container(
//                           child: isSending == false
//                               ? SizedBox(
//                                   width: 0,
//                                 )
//                               : LinearProgressIndicator(
//                                   minHeight: 50,
//                                   backgroundColor: Colors.blue,
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                       Color(0xff6249EF)),
//                                 ),
//                         ),
//                         texting == CommentState.reply
//                             ? Builder(
//                                 builder: (context) {
//                                   return SingleChildScrollView(
//                                     child: Center(
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                             boxShadow: [
//                                               new BoxShadow(
//                                                 color: Colors.black54.withOpacity(0.2),
//                                                 blurRadius:5.0,
//                                               ),
//                                             ],
//                                             color: isSending == false
//                                                 ?  kPrimaryColor
//                                                 : Colors.transparent,
//                                             borderRadius: BorderRadius.circular(10)),
//                                         width: MediaQuery.of(context).size.width / 1.3,
//                                         padding: EdgeInsets.only(
//                                             bottom: MediaQuery.of(context)
//                                                 .viewInsets
//                                                 .bottom),
//                                         child: Column(
//                                           children: <Widget>[
//                                             Padding(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                       horizontal: 10),
//                                               child: Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 children: <Widget>[
//                                                   Text(
//                                                     "Replying to $replyingTo",
//                                                     textScaleFactor:
//                                                         mediaQueryData
//                                                             .textScaleFactor
//                                                             .clamp(0.5, 1)
//                                                             .toDouble(),
//                                                     style: TextStyle(
//                                                         color: Colors.grey,
//                                                         fontSize: SizeConfig
//                                                                 .safeBlockHorizontal *
//                                                             3.2),
//                                                   ),
//                                                   IconButton(
//                                                     onPressed: () {
//                                                       setState(() {
//                                                         texting = CommentState
//                                                             .comment;
//                                                       });
//                                                     },
//                                                     icon: Icon(
//                                                       Icons.clear,
//                                                       color: Colors.grey,
//                                                       size: 15,
//                                                     ),
//                                                   )
//                                                 ],
//                                               ),
//                                             ),
//
//                                             Container(
//                                               decoration: BoxDecoration(
//                                                   boxShadow: [
//                                                     new BoxShadow(
//                                                       color: Colors.black54.withOpacity(0.2),
//                                                       blurRadius:5.0,
//                                                     ),
//                                                   ],
//                                                   color: isSending == false
//                                                       ?kPrimaryColor
//                                                       : Colors.transparent,
//                                                   borderRadius: BorderRadius.circular(10)),
//                                               padding: EdgeInsets.only(
//                                                   bottom: MediaQuery.of(context)
//                                                       .viewInsets
//                                                       .bottom)
//                                               ,
//                                               width: MediaQuery.of(context).size.width / 1.3,
//                                               child: Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 10),
//                                                 child: Row(
//                                                   children: <Widget>[
//                                                     CircleAvatar(
//                                                       radius: 15,
//                                                       backgroundImage:
//                                                           displayPicture == null
//                                                               ? AssetImage(
//                                                                   'assets/images/Thumbnail.png')
//                                                               : NetworkImage(
//                                                                   displayPicture),
//                                                     ),
//                                                     SizedBox(
//                                                       width: 10,
//                                                     ),
//                                                     Expanded(
//                                                         child: TextField(
//                                                       scrollPadding:
//                                                           EdgeInsets.only(
//                                                               bottom: MediaQuery
//                                                                       .of(context)
//                                                                   .viewInsets
//                                                                   .bottom),
//                                                       controller:
//                                                           _commentsController,
//                                                       enabled: true,
//
//                                                           autofocus: true,
//                                                           maxLines: null,
//
//                                                       style: TextStyle(
//                                                           color: Colors.white),
//                                                       decoration: InputDecoration(
//                                                           border:
//                                                               InputBorder.none,
//                                                           hintText:
//                                                               'Reply as @$user',
//                                                           hintStyle: TextStyle(
//                                                               color:
//                                                                   Colors.grey,
//                                                               fontSize: SizeConfig
//                                                                       .safeBlockHorizontal *
//                                                                   3.2)),
//                                                       onChanged: (value) {
//                                                         setState(() {
//                                                           reply = value;
//                                                         });
//                                                       },
//                                                     )),
//                                                     FlatButton(
//                                                       onPressed: () async {
//                                                         if (reply != null) {
//                                                           print(commentId);
//                                                           await postReply();
//                                                         }
//                                                       },
//                                                       child: Text(
//                                                         "Reply",
//                                                         textScaleFactor:
//                                                             mediaQueryData
//                                                                 .textScaleFactor
//                                                                 .clamp(0.5, 1)
//                                                                 .toDouble(),
//                                                         style: TextStyle(
//                                                             color: kActiveColor,
//                                                             fontSize: SizeConfig
//                                                                     .safeBlockHorizontal *
//                                                                 3.2),
//                                                       ),
//                                                     )
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               )
//                             : Padding(
//                               padding: const EdgeInsets.only(left: 40,bottom: 20),
//                               child: Builder(
//                                   builder: (context) {
//                                     return SingleChildScrollView(
//                                       child: Container(
//
//                                         decoration: BoxDecoration(
//                                         boxShadow: [
//                                         new BoxShadow(
//                                         color: Colors.black
//                                         .withOpacity(01),
//                                     blurRadius: 5.0,
//                                     ),
//                                     ],
//                                     color: themeProvider.isLightTheme == true
//                                     ? Colors.white
//                                         : kPrimaryColor,
//                                             borderRadius: BorderRadius.circular(10)),
//                                         padding: EdgeInsets.only(
//                                             bottom: MediaQuery.of(context)
//                                                 .viewInsets
//                                                 .bottom)
//                                         ,
//                                         width: MediaQuery.of(context).size.width / 1.3,
//                                         child: Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 10),
//                                           child: Row(
//                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                             children: <Widget>[
//                                              Icon( Icons.chat_bubble_outline),
//                                               SizedBox(
//                                                 width: 10,
//                                               ),
//                                               Expanded(
//                                                   child: TextField(
//                                                 scrollPadding: EdgeInsets.only(
//                                                     bottom:
//                                                         MediaQuery.of(context)
//                                                             .viewInsets
//                                                             .bottom),
//                                                 controller: _commentsController,
//                                                 enabled: true,
//                                                 minLines: 1,
//                                                 maxLines: 10,
//
//                                                 style: TextStyle(
//                                                    ),
//                                                 decoration: InputDecoration(
//                                                     border: InputBorder.none,
//                                                     hintText:
//                                                         ' Comment as @$user',
//                                                     hintStyle: TextStyle(
//                                                         color: Colors.grey,
//                                                         fontSize: SizeConfig
//                                                                 .safeBlockHorizontal *
//                                                             3.4)),
//                                                 onChanged: (value) {
//                                                   setState(() {
//                                                     comment = value;
//                                                   });
//                                                 },
//                                               )),
//                                               FlatButton(
//                                                 onPressed: () async {
//                                                   if (comment != null) {
//                                                     await postComment();
//                                                   }
//                                                 },
//                                                 child: Padding(
//                                                   padding: const EdgeInsets.only(left: 20),
//                                                   child: Icon(
//                                                      Icons.send
//                                               ),
//                                                 ))
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                             ),
//                       ],
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//
//
//       // body: Stack(
//       //   children: <Widget>[
//       //     ListView.builder(
//       //       itemBuilder: (BuildContext context, int index) {
//       //         if (index == comments.length) {
//       //           return SizedBox(
//       //             height: 400,
//       //           );
//       //         } else {
//       //           return Padding(
//       //             padding: const EdgeInsets.all(8.0),
//       //             child: Container(
//       //               decoration: BoxDecoration(
//       //                 boxShadow: [
//       //                   new BoxShadow(
//       //                     color: Colors.black54.withOpacity(0.2),
//       //                     blurRadius: 10.0,
//       //                   ),
//       //                 ],
//       //                 color: themeProvider.isLightTheme == true
//       //                     ? Colors.white
//       //                     : Color(0xff1a1a1a),
//       //                 borderRadius: BorderRadius.circular(8),
//       //               ),
//       //               child: Padding(
//       //                 padding: const EdgeInsets.all(8.0),
//       //                 child: Row(
//       //                   crossAxisAlignment: CrossAxisAlignment.start,
//       //                   children: <Widget>[
//       //                     Container(
//       //                       height: 40,
//       //                       width: 40,
//       //                       decoration: BoxDecoration(
//       //                         image: DecorationImage(
//       //                             image: comments[index]['user_image'] == null
//       //                                 ? AssetImage('assets/images/person.png')
//       //                                 : NetworkImage(
//       //                                     comments[index]['user_image']),
//       //                             fit: BoxFit.cover),
//       //                         shape: BoxShape.circle,
//       //                         // color: Colors.white,
//       //                       ),
//       //                     ),
//       //                     Expanded(
//       //                       child: Row(
//       //                         children: <Widget>[
//       //                           SizedBox(
//       //                             width: 10,
//       //                           ),
//       //                           Expanded(
//       //                             child: Column(
//       //                               crossAxisAlignment:
//       //                                   CrossAxisAlignment.start,
//       //                               children: <Widget>[
//       //                                 // Wrap(
//       //                                 //   direction: Axis.horizontal,
//       //                                 //   children: <Widget>[
//       //                                 Text(
//       //                                   '${comments[index]['author']}',
//       //                                   textScaleFactor: mediaQueryData
//       //                                       .textScaleFactor
//       //                                       .clamp(0.5, 1)
//       //                                       .toDouble(),
//       //                                   style: TextStyle(
//       //                                       // color: Color(0xffe8e8e8),
//       //                                       fontWeight: FontWeight.w600),
//       //                                 ),
//       //                                 Text(
//       //                                   '${comments[index]['text']}',
//       //                                   textScaleFactor: mediaQueryData
//       //                                       .textScaleFactor
//       //                                       .clamp(0.5, 1)
//       //                                       .toDouble(),
//       //                                   style: TextStyle(
//       //                                       // color: Colors.white,
//       //                                       fontWeight: FontWeight.normal),
//       //                                 ),
//       //                                 //   ],
//       //                                 // ),
//       //                                 SizedBox(
//       //                                   height: 4,
//       //                                 ),
//       //                                 Row(
//       //                                   children: <Widget>[
//       //                                     Text(
//       //                                       timeago.format(DateTime.parse(
//       //                                           comments[index]['createdAt'])),
//       //                                       textScaleFactor: mediaQueryData
//       //                                           .textScaleFactor
//       //                                           .clamp(0.5, 1)
//       //                                           .toDouble(),
//       //                                       style: TextStyle(
//       //                                           // color: Colors.grey,
//       //                                           fontSize: SizeConfig
//       //                                                   .safeBlockHorizontal *
//       //                                               3.2),
//       //                                     ),
//       //                                     SizedBox(
//       //                                       width: 20,
//       //                                     ),
//       //                                     GestureDetector(
//       //                                       onTap: () {
//       //                                         setState(() {
//       //                                           texting = CommentState.reply;
//       //                                           replyingTo =
//       //                                               comments[index]['author'];
//       //                                           commentId =
//       //                                               comments[index]['id'];
//       //                                         });
//       //                                       },
//       //                                       child: Text(
//       //                                         "Reply",
//       //                                         textScaleFactor: mediaQueryData
//       //                                             .textScaleFactor
//       //                                             .clamp(0.5, 1)
//       //                                             .toDouble(),
//       //                                         style: TextStyle(
//       //                                             // color: Colors.grey,
//       //                                             fontSize: SizeConfig
//       //                                                     .safeBlockHorizontal *
//       //                                                 3),
//       //                                       ),
//       //                                     )
//       //                                   ],
//       //                                 ),
//       //                                 comments[index]['comments'] == null
//       //                                     ? SizedBox(
//       //                                         height: 0,
//       //                                       )
//       //                                     : ExpansionTile(
//       //                                         backgroundColor:
//       //                                             Colors.transparent,
//       //                                         trailing: SizedBox(
//       //                                           width: 0,
//       //                                         ),
//       //                                         title: Align(
//       //                                           alignment: Alignment.centerLeft,
//       //                                           child: Text(
//       //                                             "View replies",
//       //                                             textScaleFactor:
//       //                                                 mediaQueryData
//       //                                                     .textScaleFactor
//       //                                                     .clamp(0.5, 1)
//       //                                                     .toDouble(),
//       //                                             style: TextStyle(
//       //                                               fontSize: SizeConfig
//       //                                                       .safeBlockHorizontal *
//       //                                                   3,
//       //                                               // color: Colors.grey,
//       //                                             ),
//       //                                           ),
//       //                                         ),
//       //                                         children: <Widget>[
//       //                                           for (var v in comments[index]
//       //                                               ['comments'])
//       //                                             Align(
//       //                                               alignment:
//       //                                                   Alignment.centerLeft,
//       //                                               child: Padding(
//       //                                                 padding:
//       //                                                     const EdgeInsets.only(
//       //                                                         bottom: 10),
//       //                                                 child: Container(
//       //                                                   child: Row(
//       //                                                     children: <Widget>[
//       //                                                       CircleAvatar(
//       //                                                         radius: 20,
//       //                                                         backgroundImage: v[
//       //                                                                     'user_image'] ==
//       //                                                                 null
//       //                                                             ? NetworkImage(
//       //                                                                 placeholderUrl)
//       //                                                             : NetworkImage(
//       //                                                                 v['user_image']),
//       //                                                       ),
//       //                                                       SizedBox(width: 10),
//       //                                                       Expanded(
//       //                                                         child: Row(
//       //                                                           mainAxisAlignment:
//       //                                                               MainAxisAlignment
//       //                                                                   .spaceBetween,
//       //                                                           children: [
//       //                                                             Column(
//       //                                                               crossAxisAlignment:
//       //                                                                   CrossAxisAlignment
//       //                                                                       .start,
//       //                                                               children: <
//       //                                                                   Widget>[
//       //                                                                 Text(
//       //                                                                   '${v['author']}',
//       //                                                                   textScaleFactor:
//       //                                                                       1.0,
//       //                                                                   style: TextStyle(
//       //                                                                       fontWeight:
//       //                                                                           FontWeight.w600),
//       //                                                                 ),
//       //
//       //                                                                 Text(
//       //                                                                   '${v['text']}',
//       //                                                                   textScaleFactor:
//       //                                                                       1.0,
//       //                                                                   style: TextStyle(
//       //                                                                       // color: Colors
//       //                                                                       //     .white,
//       //                                                                       fontWeight: FontWeight.normal),
//       //                                                                 ),
//       //                                                                 //   ],
//       //                                                                 // ),
//       //                                                                 // Text(
//       //                                                                 //   '${v['author']}  ${v['text']}',
//       //                                                                 //   style: TextStyle(
//       //                                                                 //       color: Colors
//       //                                                                 //           .white,
//       //                                                                 //       fontSize:
//       //                                                                 //           SizeConfig.safeBlockHorizontal *
//       //                                                                 //               3.2),
//       //                                                                 // ),
//       //                                                                 Row(
//       //                                                                   children: <
//       //                                                                       Widget>[
//       //                                                                     Text(
//       //                                                                       timeago.format(DateTime.parse(v['createdAt'])),
//       //                                                                       textScaleFactor:
//       //                                                                           1.0,
//       //                                                                       style: TextStyle(
//       //                                                                           // color: Colors.grey,
//       //                                                                           fontSize: SizeConfig.safeBlockHorizontal * 3),
//       //                                                                     ),
//       //                                                                     SizedBox(
//       //                                                                       width:
//       //                                                                           10,
//       //                                                                     ),
//       //                                                                     GestureDetector(
//       //                                                                       onTap:
//       //                                                                           () {
//       //                                                                         setState(() {
//       //                                                                           texting = CommentState.reply;
//       //                                                                           replyingTo = v['author'];
//       //                                                                           commentId = comments[index]['id'];
//       //                                                                           commentPermlink = comments[index]['permlink'];
//       //                                                                         });
//       //                                                                         showModalBottomSheet(
//       //                                                                             context: context,
//       //                                                                             builder: (context) {
//       //                                                                               return SingleChildScrollView(
//       //                                                                                 child: Container(
//       //                                                                                   padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//       //                                                                                   child: Column(
//       //                                                                                     children: <Widget>[
//       //                                                                                       Container(
//       //                                                                                         color: kSecondaryColor,
//       //                                                                                         child: Padding(
//       //                                                                                           padding: const EdgeInsets.symmetric(horizontal: 10),
//       //                                                                                           child: Row(
//       //                                                                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       //                                                                                             children: <Widget>[
//       //                                                                                               Text(
//       //                                                                                                 "Replying to $replyingTo",
//       //                                                                                                 textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
//       //                                                                                                 style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.2),
//       //                                                                                               ),
//       //                                                                                               IconButton(
//       //                                                                                                 onPressed: () {
//       //                                                                                                   setState(() {
//       //                                                                                                     texting = CommentState.comment;
//       //                                                                                                   });
//       //                                                                                                 },
//       //                                                                                                 icon: Icon(
//       //                                                                                                   Icons.clear,
//       //                                                                                                   // color: Colors.grey,
//       //                                                                                                   size: 15,
//       //                                                                                                 ),
//       //                                                                                               )
//       //                                                                                             ],
//       //                                                                                           ),
//       //                                                                                         ),
//       //                                                                                       ),
//       //                                                                                       Container(
//       //                                                                                         color: kSecondaryColor,
//       //                                                                                         child: Padding(
//       //                                                                                           padding: const EdgeInsets.symmetric(horizontal: 10),
//       //                                                                                           child: Row(
//       //                                                                                             children: <Widget>[
//       //                                                                                               CircleAvatar(
//       //                                                                                                 radius: 15,
//       //                                                                                                 backgroundImage: displayPicture == null ? AssetImage('assets/images/Thumbnail.png') : NetworkImage(displayPicture),
//       //                                                                                               ),
//       //                                                                                               SizedBox(
//       //                                                                                                 width: 10,
//       //                                                                                               ),
//       //                                                                                               Expanded(
//       //                                                                                                   child: TextField(
//       //                                                                                                 controller: _commentsController,
//       //                                                                                                 enabled: true,
//       //                                                                                                 minLines: 1,
//       //                                                                                                 maxLines: 10,
//       //                                                                                                 decoration: InputDecoration(border: InputBorder.none, hintText: 'Reply as @$user', hintStyle: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.2)),
//       //                                                                                                 onChanged: (value) {
//       //                                                                                                   setState(() {
//       //                                                                                                     reply = value;
//       //                                                                                                   });
//       //                                                                                                 },
//       //                                                                                               )),
//       //                                                                                               FlatButton(
//       //                                                                                                 onPressed: () async {
//       //                                                                                                   if (reply != null) {
//       //                                                                                                     print(commentId);
//       //                                                                                                     await postReply();
//       //                                                                                                   }
//       //                                                                                                 },
//       //                                                                                                 child: Text(
//       //                                                                                                   "Reply",
//       //                                                                                                   textScaleFactor: mediaQueryData.textScaleFactor.clamp(0.5, 1).toDouble(),
//       //                                                                                                   style: TextStyle(color: kActiveColor, fontSize: SizeConfig.safeBlockHorizontal * 3.2),
//       //                                                                                                 ),
//       //                                                                                               )
//       //                                                                                             ],
//       //                                                                                           ),
//       //                                                                                         ),
//       //                                                                                       ),
//       //                                                                                     ],
//       //                                                                                   ),
//       //                                                                                 ),
//       //                                                                               );
//       //                                                                             });
//       //                                                                       },
//       //                                                                       child:
//       //                                                                           Text(
//       //                                                                         'Reply',
//       //                                                                         textScaleFactor: 1.0,
//       //                                                                         style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
//       //                                                                       ),
//       //                                                                     )
//       //                                                                   ],
//       //                                                                 )
//       //                                                               ],
//       //                                                             ),
//       //                                                             IconButton(
//       //                                                               onPressed:
//       //                                                                   () {
//       //                                                                 upVoteComment(
//       //                                                                     v['id']
//       //                                                                         .toString());
//       //                                                               },
//       //                                                               icon: Icon(
//       //                                                                 FontAwesomeIcons
//       //                                                                     .chevronCircleUp,
//       //                                                                 // color: Colors
//       //                                                                 //     .white,
//       //                                                               ),
//       //                                                             )
//       //                                                           ],
//       //                                                         ),
//       //                                                       ),
//       //                                                     ],
//       //                                                   ),
//       //                                                 ),
//       //                                               ),
//       //                                             )
//       //                                         ],
//       //                                       )
//       //                               ],
//       //                             ),
//       //                           )
//       //                         ],
//       //                       ),
//       //                     ),
//       //                     SizedBox(
//       //                       width: 10,
//       //                     ),
//       //                     IconButton(
//       //                       onPressed: () {
//       //                         upVoteComment(comments[index]['id'].toString());
//       //                       },
//       //                       icon: Icon(
//       //                         FontAwesomeIcons.chevronCircleUp,
//       //                         // color: Colors.white,
//       //                       ),
//       //                     ),
//       //                     // Icon(
//       //                     //   FontAwesomeIcons.heart,
//       //                     //   color: Colors.white,
//       //                     //   size: 13,
//       //                     // )
//       //                   ],
//       //                 ),
//       //               ),
//       //             ),
//       //           );
//       //         }
//       //       },
//       //       itemCount: comments.length + 1,
//       //     ),
//       //     Column(
//       //       mainAxisAlignment: MainAxisAlignment.end,
//       //       children: <Widget>[
//       //         Stack(
//       //           children: [
//       //             Container(
//       //               child: isSending == false
//       //                   ? SizedBox(
//       //                       width: 0,
//       //                     )
//       //                   : LinearProgressIndicator(
//       //                       minHeight: 50,
//       //                       backgroundColor: Colors.blue,
//       //                       valueColor: AlwaysStoppedAnimation<Color>(
//       //                           Color(0xff6249EF)),
//       //                     ),
//       //             ),
//       //             texting == CommentState.reply
//       //                 ? Builder(
//       //                     builder: (context) {
//       //                       return SingleChildScrollView(
//       //                         child: Container(
//       //                           padding: EdgeInsets.only(
//       //                               bottom: MediaQuery.of(context)
//       //                                   .viewInsets
//       //                                   .bottom),
//       //                           child: Column(
//       //                             children: <Widget>[
//       //                               Container(
//       //                                 color: isSending == false
//       //                                     ? kSecondaryColor
//       //                                     : Colors.transparent,
//       //                                 child: Padding(
//       //                                   padding: const EdgeInsets.symmetric(
//       //                                       horizontal: 10),
//       //                                   child: Row(
//       //                                     mainAxisAlignment:
//       //                                         MainAxisAlignment.spaceBetween,
//       //                                     children: <Widget>[
//       //                                       Text(
//       //                                         "Replying to $replyingTo",
//       //                                         textScaleFactor: mediaQueryData
//       //                                             .textScaleFactor
//       //                                             .clamp(0.5, 1)
//       //                                             .toDouble(),
//       //                                         style: TextStyle(
//       //                                             color: Colors.grey,
//       //                                             fontSize: SizeConfig
//       //                                                     .safeBlockHorizontal *
//       //                                                 3.2),
//       //                                       ),
//       //                                       IconButton(
//       //                                         onPressed: () {
//       //                                           setState(() {
//       //                                             texting =
//       //                                                 CommentState.comment;
//       //                                           });
//       //                                         },
//       //                                         icon: Icon(
//       //                                           Icons.clear,
//       //                                           color: Colors.grey,
//       //                                           size: 15,
//       //                                         ),
//       //                                       )
//       //                                     ],
//       //                                   ),
//       //                                 ),
//       //                               ),
//       //                               Container(
//       //                                 color: kSecondaryColor,
//       //                                 child: Padding(
//       //                                   padding: const EdgeInsets.symmetric(
//       //                                       horizontal: 10),
//       //                                   child: Row(
//       //                                     children: <Widget>[
//       //                                       CircleAvatar(
//       //                                         radius: 15,
//       //                                         backgroundImage: displayPicture ==
//       //                                                 null
//       //                                             ? AssetImage(
//       //                                                 'assets/images/Thumbnail.png')
//       //                                             : NetworkImage(
//       //                                                 displayPicture),
//       //                                       ),
//       //                                       SizedBox(
//       //                                         width: 10,
//       //                                       ),
//       //                                       Expanded(
//       //                                           child: TextField(
//       //                                         scrollPadding: EdgeInsets.only(
//       //                                             bottom: MediaQuery.of(context)
//       //                                                 .viewInsets
//       //                                                 .bottom),
//       //                                         controller: _commentsController,
//       //                                         enabled: true,
//       //                                         minLines: 1,
//       //                                         maxLines: 10,
//       //                                         style: TextStyle(
//       //                                             color: Colors.white),
//       //                                         decoration: InputDecoration(
//       //                                             border: InputBorder.none,
//       //                                             hintText: 'Reply as @$user',
//       //                                             hintStyle: TextStyle(
//       //                                                 color: Colors.grey,
//       //                                                 fontSize: SizeConfig
//       //                                                         .safeBlockHorizontal *
//       //                                                     3.2)),
//       //                                         onChanged: (value) {
//       //                                           setState(() {
//       //                                             reply = value;
//       //                                           });
//       //                                         },
//       //                                       )),
//       //                                       FlatButton(
//       //                                         onPressed: () async {
//       //                                           if (reply != null) {
//       //                                             print(commentId);
//       //                                             await postReply();
//       //                                           }
//       //                                         },
//       //                                         child: Text(
//       //                                           "Reply",
//       //                                           textScaleFactor: mediaQueryData
//       //                                               .textScaleFactor
//       //                                               .clamp(0.5, 1)
//       //                                               .toDouble(),
//       //                                           style: TextStyle(
//       //                                               color: kActiveColor,
//       //                                               fontSize: SizeConfig
//       //                                                       .safeBlockHorizontal *
//       //                                                   3.2),
//       //                                         ),
//       //                                       )
//       //                                     ],
//       //                                   ),
//       //                                 ),
//       //                               ),
//       //                             ],
//       //                           ),
//       //                         ),
//       //                       );
//       //                     },
//       //                   )
//       //                 : Builder(
//       //                     builder: (context) {
//       //                       return SingleChildScrollView(
//       //                         child: Container(
//       //                           padding: EdgeInsets.only(
//       //                               bottom: MediaQuery.of(context)
//       //                                   .viewInsets
//       //                                   .bottom),
//       //                           color: isSending == false
//       //                               ? kSecondaryColor
//       //                               : Colors.transparent,
//       //                           child: Padding(
//       //                             padding: const EdgeInsets.symmetric(
//       //                                 horizontal: 10),
//       //                             child: Row(
//       //                               children: <Widget>[
//       //                                 CircleAvatar(
//       //                                   radius: 15,
//       //                                   backgroundImage: displayPicture == null
//       //                                       ? AssetImage(
//       //                                           'assets/images/Thumbnail.png')
//       //                                       : NetworkImage(displayPicture),
//       //                                 ),
//       //                                 SizedBox(
//       //                                   width: 10,
//       //                                 ),
//       //                                 Expanded(
//       //                                     child: TextField(
//       //                                   scrollPadding: EdgeInsets.only(
//       //                                       bottom: MediaQuery.of(context)
//       //                                           .viewInsets
//       //                                           .bottom),
//       //                                   controller: _commentsController,
//       //                                   enabled: true,
//       //                                   minLines: 1,
//       //                                   maxLines: 10,
//       //                                   style: TextStyle(color: Colors.white),
//       //                                   decoration: InputDecoration(
//       //                                       border: InputBorder.none,
//       //                                       hintText: 'Comment as @$user',
//       //                                       hintStyle: TextStyle(
//       //                                           color: Colors.grey,
//       //                                           fontSize: SizeConfig
//       //                                                   .safeBlockHorizontal *
//       //                                               3.4)),
//       //                                   onChanged: (value) {
//       //                                     setState(() {
//       //                                       comment = value;
//       //                                     });
//       //                                   },
//       //                                 )),
//       //                                 FlatButton(
//       //                                   onPressed: () async {
//       //                                     if (comment != null) {
//       //                                       await postComment();
//       //                                     }
//       //                                   },
//       //                                   child: Text(
//       //                                     "Post",
//       //                                     textScaleFactor: mediaQueryData
//       //                                         .textScaleFactor
//       //                                         .clamp(0.5, 1)
//       //                                         .toDouble(),
//       //                                     style: TextStyle(
//       //                                         color: kActiveColor,
//       //                                         fontSize: SizeConfig
//       //                                                 .safeBlockHorizontal *
//       //                                             3.4),
//       //                                   ),
//       //                                 )
//       //                               ],
//       //                             ),
//       //                           ),
//       //                         ),
//       //                       );
//       //                     },
//       //                   ),
//       //           ],
//       //         ),
//       //       ],
//       //     )
//       //   ],
//       // ),
//     );
//   }
// }

class CommentCard extends StatefulWidget {

  var data;

  CommentCard({@required this.data}) ;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  @override
  Widget build(BuildContext context) {
    return ListTile(

      horizontalTitleGap: 10,
      leading: SizedBox(height: 40, width: 40, child: CircleAvatar(backgroundColor: kSecondaryColor,backgroundImage: Image.network('https://images.hive.blog/u/${widget.data['author']}/avatar').image,)),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(decoration: BoxDecoration(
            color: kSecondaryColor,
            borderRadius: BorderRadius.circular(8)
          ),child: Html(data: widget.data['body'])),
          SizedBox(height: 8,),
          Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kSecondaryColor)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FontAwesomeIcons.chevronCircleUp, size: 15,),
                          SizedBox(width: 5,),
                          Text("\$${widget.data['payout']}")
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kSecondaryColor)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mode_comment, size: 15,),
                          SizedBox(width: 5,),
                          Text("${widget.data['replies'].length}")
                        ],
                      ),
                    ),
                  ),
                ),
                Text("View Replies", style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),)  //level 1 replies make a seperate interface for them

              ],
          )
        ],
      ),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text("${widget.data['author']}"),
      ),
    );
  }
}

