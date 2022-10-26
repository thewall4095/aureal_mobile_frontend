import 'dart:convert';

import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:expandable/expandable.dart';
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

// class Comments extends StatefulWidget {
//   var episodeObject;
//   // Map<String, dynamic> commentData;
//
//   Comments({this.episodeObject});
//
//   @override
//   _CommentsState createState() => _CommentsState();
// }
//
// class _CommentsState extends State<Comments> {
//   String getDuration() {}
//
//   TextEditingController _commentsController;
//
//   postreq.Interceptor intercept = postreq.Interceptor();
//
//   CommentState texting = CommentState.comment;
//
//   String replyingTo;
//   bool isSending = false;
//
//   var commentKeys;
//
//   void getCommentKeys() async {
//     prefs = await SharedPreferences.getInstance();
//     // comment_keys = widget.commentData.keys.toList();
//     print(comment_keys);
//   }
//
//   String comment;
//   String reply;
//   var soundBlob;
//   var comments = [];
//   var replies = [];
//   String user;
//   int commentId;
//   var expanded = [];
//   String displayPicture;
//   String commentPermlink;
//
//   void deleteComment() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String url = 'https://api.aureal.one/public/deleteComment';
//     var map = Map<String, dynamic>();
//     map['id'] = prefs.getString('userId');
//     map['comment_id'] = commentId;
//
//     FormData formData = FormData.fromMap(map);
//     var response = intercept.postRequest(formData, url);
//     print(response);
//     await getComments();
//   }
//
//   Dio dio = Dio();
//
//   CancelToken cancel = CancelToken();
//
//   var commentsData;
//
//   SharedPreferences prefs;
//
//   Future getComments() async {
//     prefs = await SharedPreferences.getInstance();
//     String url = "https://rpc.ecency.com";
//     print(url);
//     var map = Map<String, dynamic>();
//     map = {
//       "jsonrpc": "2.0",
//       "method": "bridge.get_discussion",
//       "params": {
//         'author': widget.episodeObject['author_hiveusername'],
//         'permlink': widget.episodeObject['permlink'],
//         'observer': ""
//       },
//       "id": 0
//     };
//
//     print(map);
//
//     try{
//       await dio.post(url, data: map, cancelToken: cancel).then((value) {
//         Map<String, dynamic> result;
//         result = value.data['result'];
//
//           commentKeys = result.keys.toList();
//           commentsData = value.data['result'];
//
//
//         print(commentKeys);
//         return value.data['result'];
//       });
//     }catch(e){
//       print(e);
//     }
//   }
//
//   var comment_keys = [];
//
//
//   void postComment() async {
//     setState(() {
//       isSending = true;
//     });
//     String url = 'https://api.aureal.one/private/comment';
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var map = Map<String, dynamic>();
//     map['user_id'] = prefs.getString('userId');
//     map['episode_id'] = widget.episodeObject['id'];
//     map['text'] = comment;
//     if (widget.episodeObject['permlink'] != null) {
//       map['hive_username'] = prefs.getString('HiveUserName');
//     }
//
//     FormData formData = FormData.fromMap(map);
//
//     var response = await intercept.postRequest(formData, url);
//     print(response);
//     await getComments();
//     _commentsController.clear();
//     setState(() {
//       isSending = false;
//     });
//   }
//
//   void postReply() async {
//     setState(() {
//       isSending = true;
//     });
//     String url = 'https://api.aureal.one/private/reply';
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var map = Map<String, dynamic>();
//     map['user_id'] = prefs.getString('userId');
//     map['text'] = reply;
//     map['comment_id'] = commentId;
//     // if (commentPermlink != null) {
//     map['hive_username'] = prefs.getString('HiveUserName');
//     // }
//     print(map.toString());
//     FormData formData = FormData.fromMap(map);
//
//     var response = await intercept.postRequest(formData, url);
//     print(response.toString());
//     await getComments();
//     _commentsController.clear();
//     setState(() {
//       isSending = false;
//     });
//   }
//
//   void upVoteComment(String commentId) async {
//     postreq.Interceptor interceptor = postreq.Interceptor();
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     String url = 'https://api.aureal.one/public/voteComment';
//
//     var map = Map<String, dynamic>();
//     map['hive_username'] = prefs.getString('HiveUserName');
//     map['comment_id'] = commentId;
//     map['user_id'] = prefs.getString('userId');
//     FormData formData = FormData.fromMap(map);
//
//     try {
//       var response = await interceptor.postRequest(formData, url);
//       print(response.toString());
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   Future commentsFuture;
//
//   void commentsgetter() async {
//       commentsFuture = getComments();
//   }
//
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     // commentsgetter();
//     // getComments();
//
//     super.initState();
//     _commentsController = TextEditingController();
//     // getCommentKeys();
//
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     _commentsController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     var comstate = Provider.of<ComState>(context);
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context, 'done');
//           },
//           icon: Icon(
//             Icons.navigate_before,
//           ),
//         ),
//         title: Text(
//           "${widget.episodeObject['podcast_name']}",
//           textScaleFactor: 1.0,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
//         ),
//       ),
//
//     // body: Stack(
//     //   children: [
//     //     ListView.builder(itemBuilder: (context, int index){
//     //       if(index ==  0){
//     //         return SizedBox();
//     //       }else{
//     //         if(index == comment_keys.length){
//     //           return SizedBox(height: 200,);
//     //         }else{
//     //           return Padding(
//     //             padding: const EdgeInsets.symmetric(vertical: 8),
//     //             child: CommentCard(data: widget.commentData['${comment_keys[index].toString()}']),
//     //           );
//     //         }
//     //
//     //       }
//     //
//     //     }, itemCount: comment_keys.length + 1,),
//     //     comstate.commentState == CommentState.reply? Align(alignment: Alignment.bottomCenter,child: Container(color: kSecondaryColor,child: Padding(
//     //       padding: const EdgeInsets.symmetric(horizontal: 10),
//     //       child: TextField(enableIMEPersonalizedLearning: true,
//     //         controller: _commentsController, decoration: InputDecoration(suffix: IconButton(icon: Icon(Icons.send,size: 20,),) ,suffixIconConstraints: BoxConstraints(maxWidth: 20, maxHeight: 20),prefixIconConstraints: BoxConstraints(maxHeight: 30, maxWidth: 30),prefixIcon: Padding(
//     //           padding: const EdgeInsets.only(right: 10),
//     //           child: SizedBox(height: 20, width:20,child: CircleAvatar(radius: 5,backgroundImage: Image.network('https://images.hive.blog/u/${prefs.getString('HiveUserName')}/avatar').image,)),
//     //         ),contentPadding: EdgeInsets.only(bottom: 14),border: InputBorder.none,hintText: "replying as @${prefs.getString('HiveUserName').toString()}"),),
//     //     ),
//     //     )) : Align(alignment: Alignment.bottomCenter,child: Container(color: kSecondaryColor,child: Padding(
//     //       padding: const EdgeInsets.symmetric(horizontal: 10),
//     //       child: TextField(enableIMEPersonalizedLearning: true,
//     //         controller: _commentsController, decoration: InputDecoration(suffix: IconButton(icon: Icon(Icons.send,size: 20,),) ,suffixIconConstraints: BoxConstraints(maxWidth: 20, maxHeight: 20),prefixIconConstraints: BoxConstraints(maxHeight: 30, maxWidth: 30),prefixIcon: Padding(
//     //           padding: const EdgeInsets.only(right: 10),
//     //           child: SizedBox(height: 20, width:20,child: CircleAvatar(radius: 5,backgroundImage: Image.network('https://images.hive.blog/u/${prefs.getString('HiveUserName')}/avatar').image,)),
//     //         ),contentPadding: EdgeInsets.only(bottom: 14),border: InputBorder.none,hintText: "commenting as @${prefs.getString('HiveUserName').toString()}"),),
//     //     ),
//     //     )),
//     //   ],
//     //
//     // ),
//       body: FutureBuilder(
//         future: getComments(),
//         builder: (context, snapshot){
//           if(snapshot.hasData == true){
//             return ListView.builder(itemBuilder: (context , int index){
//               return Container(
//                 child: Text("${commentKeys[0]}"),
//               );
//             }, itemCount: commentKeys.length,);
//           }else{
//             return Container(
//               child: Center(child: CircularProgressIndicator(color: Colors.white,)),
//             );
//           }
//         },
//       )
//
//     );
//   }
// }

class Comments extends StatelessWidget {

  final episodeObject;

  Comments({@required this.episodeObject});

  Dio dio = Dio();
  SharedPreferences prefs;
  CancelToken cancel = CancelToken();

  List commentKeys;

  Future<Map<String, dynamic>> getComments() async {
    prefs = await SharedPreferences.getInstance();
    String url = "https://rpc.ecency.com";

    var map = Map<String, dynamic>();

    map = {
      "jsonrpc": "2.0",
      "method": "bridge.get_discussion",
      "params": {
        'author': episodeObject['author_hiveusername'],
        'permlink': episodeObject['permlink'],
        'observer': ""
      },
      "id": 0
    };

    try{
      var result = await dio.post(url, cancelToken: cancel, data: map);

      if(result.statusCode == 200){
        print(result.data);
        Map<String, dynamic> comments = result.data['result'];
        commentKeys = comments.keys.toList();
        return result.data['result'];
      }else{
        print(result.statusCode);
      }

    }catch(e){
      print(e);
    }

  }

  Future getComments1() async {
    prefs = await SharedPreferences.getInstance();
    String url = "https://rpc.ecency.com";
    print(url);
    var map = Map<String, dynamic>();
    map = {
      "jsonrpc": "2.0",
      "method": "bridge.get_discussion",
      "params": {
        'author': episodeObject['author_hiveusername'],
        'permlink': episodeObject['permlink'],
        'observer': ""
      },
      "id": 0
    };

    print(map);

    try{
      await dio.post(url, data: map, cancelToken: cancel).then((value) {
        Map<String, dynamic> result;
        result = value.data['result'];

          commentKeys = result.keys.toList();
          // commentsData = value.data['result'];


        print(commentKeys);
        print(value.data['result']);
        print(result);
        return result;
      });
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: FutureBuilder(
          future: getComments(),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.active){
              return Center(child: CircularProgressIndicator(color: Colors.white,));
            }else{
              print(snapshot.hasData);
              print(snapshot.data);
              if(snapshot.hasData){
                return ListView.builder(itemBuilder: (context, int index){
                  if(index == 0){
                    return Container();
                  }else{
                    return CommentCard(data: snapshot.data['${commentKeys[index]}']);
                  }

                }, itemCount: commentKeys.length == 0 ? 0 : commentKeys.length,shrinkWrap: true,);
              }else{
                return Center(child: Text("Oh! Snap"));
              }
            }
          },
        ),
      ),
    );
  }
}



class CommentCard extends StatefulWidget {

  var data;

  CommentCard({@required this.data}) ;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {

  CommentState commstate = CommentState.comment;

  SharedPreferences prefs;

  postreq.Interceptor intercept = postreq.Interceptor();

  List active_votes;
  bool ifVoted;

  void setActiveVotes()async{

    prefs = await SharedPreferences.getInstance();

    setState(() {
      active_votes = widget.data['active_votes'];
      if(widget.data['active_votes'].toString().contains("${prefs.getString('HiveUserName')}")){
        ifVoted = true;
      }
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    setActiveVotes();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    var commentState = Provider.of<ComState>(context);
    return ExpandablePanel(
      header: ListTile(

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
                  child: InkWell(
                    onTap: (){
                      print(widget.data);
                      print(widget.data.runtimeType);
                      showModalBottomSheet(context: context, builder: (context){
                        return UpvoteComment(data: widget.data,);
                      }).then((value) {
                        setState(() {
                          ifVoted = true;
                        });
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kSecondaryColor),
                        color: ifVoted == true ? Colors.blue : Colors.transparent,
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
                      child: InkWell(
                        onTap: (){
                          commentState.commentState = CommentState.reply;
                        },
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
      ),

    );
  }
}

class ComState extends ChangeNotifier{

 CommentState _commentState;
 CommentState get commentState => _commentState;

 set commentState(CommentState newValue) {
   _commentState = newValue;
   notifyListeners();
 }



}



