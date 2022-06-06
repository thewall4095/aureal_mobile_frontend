import 'dart:convert';

import 'package:auditory/Services/HiveOperations.dart';
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


class CommentCard extends StatefulWidget {

  var data;

  CommentCard({@required this.data}) ;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {

  SharedPreferences prefs;

  postreq.Interceptor intercept = postreq.Interceptor();


  // Future upvoteComment(int weight) async {
  //   prefs = await SharedPreferences.getInstance();
  //   String url = "https://api.aureal.one/public/voteComment";
  //
  //   var map = Map<String, dynamic>();
  //   map['author_hive_username'] = widget.data['author'];
  //   map['hive_username'] = prefs.getString('HiveUserName');
  //   map['permlink'] = widget.data['permlink'];
  //   map['weight'] = weight;
  //
  //   FormData formData = FormData.fromMap(map);
  //
  //   try{
  //     await intercept.postRequest(formData, url).then((value) {
  //       print(value);
  //     });
  //   }catch(e){
  //     print(e);
  //   }
  //
  // }

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

