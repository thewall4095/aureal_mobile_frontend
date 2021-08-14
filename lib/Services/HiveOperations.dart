import 'dart:convert';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Interceptor.dart' as postreq;

void upvoteEpisode({String permlink, int episode_id, double weight}) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = 'https://api.aureal.one/public/voteEpisode';

  if (prefs.getString('HiveUserName') != null) {
    if (permlink != null) {
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['permlink'] = permlink;
      map['weight'] = weight;
      map['hive_username'] = prefs.getString('HiveUserName');
      map['episode_id'] = episode_id;

      FormData formData = FormData.fromMap(map);

      try {
        var response = await interceptor.postRequest(formData, url);
        print(response.toString());
      } catch (e) {
        print(e);
      }
    }
  } else {}
}

void downVoteEpisode({String permlink, int episode_id}) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (prefs.getString('HiveUserName') != null) {
    if (permlink != null) {
      String url = 'https://api.aureal.one/public/voteEpisode';
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['permlink'] = permlink;
      map['weight'] = -10000;
      map['hive_username'] = prefs.getString('HiveUserName');
      map['episode_id'] = episode_id;

      FormData formData = FormData.fromMap(map);

      try {
        var response = await interceptor.postRequest(formData, url);
        print(response.toString());
      } catch (e) {
        print(e);
      }
    }
  } else {}
}

void upVoteComment({@required String commentId, double weight}) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String url = 'https://api.aureal.one/public/voteComment';

  var map = Map<String, dynamic>();
  map['weight'] = weight;
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

void publishManually(var episodeId) async {
  postreq.Interceptor interceptor = postreq.Interceptor();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = 'https://api.aureal.one/private/manualHivePublish';

  var map = Map<String, dynamic>();
  map['episode_id'] = episodeId;

  FormData formData = FormData.fromMap(map);

  var response = await interceptor.postRequest(formData, url);

  print(response.toString());
}

void downVoteComment(String commentId) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String url = 'https://api.aureal.one/public/voteComment';

  var map = Map<String, dynamic>();
  map['weight'] = 10000;
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

Future getHiveData() async {
  postreq.Interceptor intercept = postreq.Interceptor();
  String url = 'https://api.aureal.one/public/clientMe';

  try {
    var response = await intercept.getRequest(url);
    print(response.runtimeType);
    print(response);
    // return jsonDecode(response);
  } catch (e) {
    print(e);
  }
}

void claimRewards() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  postreq.Interceptor intercept = postreq.Interceptor();

  String url = 'https://api.aureal.one/private/claimRewards';
  var map = Map<String, dynamic>();
  map['hive_username'] = prefs.getString('HiveUserName');
  map['user_id'] = prefs.getString('userId');

  FormData formData = FormData.fromMap(map);

  try {
    var response = await intercept.postRequest(formData, url);
    print(response);
  } catch (e) {
    print(e);
  }
}

class UpvoteEpisode extends StatefulWidget {
  String permlink;
  int episode_id;

  UpvoteEpisode({@required this.permlink, @required this.episode_id});

  @override
  _UpvoteEpisodeState createState() => _UpvoteEpisodeState();
}

class _UpvoteEpisodeState extends State<UpvoteEpisode> {
  double _value = 51.0;

  SharedPreferences prefs;

  double factor = 0.0000001;

  void getFactor() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/voteEstimate?hiveusername=${prefs.getString('HiveUserName')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      setState(() {
        factor = jsonDecode(response.body)['hive_estimate_factor'];
      });
    } catch (e) {}
  }

  @override
  void initState() {
    // TODO: implement initState
    getFactor();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Color(0xff222222),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your vote value:",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.safeBlockHorizontal * 3),
                    ),
                    Text(
                      '\$ ${((factor * _value) / 100).toStringAsPrecision(3)}',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Slider(
              max: 100.0,
              min: 1.0,
              value: _value,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _value = value;
                  print(_value);
                });
              },
              onChangeEnd: (value) async {
                print("this is the final value: $value");
                await upvoteEpisode(
                    permlink: widget.permlink,
                    episode_id: widget.episode_id,
                    weight: value * 100);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UpvoteComment extends StatefulWidget {
  var comment_id;

  UpvoteComment({@required comment_id});

  @override
  _UpvoteCommentState createState() => _UpvoteCommentState();
}

class _UpvoteCommentState extends State<UpvoteComment> {
  double _value = 51.0;

  SharedPreferences prefs;

  double factor = 0.0000001;

  void getFactor() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/voteEstimate?hiveusername=${prefs.getString('HiveUserName')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      setState(() {
        factor = jsonDecode(response.body)['hive_estimate_factor'];
      });
    } catch (e) {}
  }

  @override
  void initState() {
    // TODO: implement initState
    getFactor();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return factor == null
        ? SizedBox()
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: kSecondaryColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Your vote value:",
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3),
                          ),
                          Text(
                              '\$ ${((factor * _value) / 100).toStringAsPrecision(3)}'),
                        ],
                      ),
                    ),
                  ),
                  Slider(
                    max: 100.0,
                    min: 1.0,
                    value: _value,
                    onChanged: (value) {
                      setState(() {
                        _value = value;
                        print(_value);
                      });
                    },
                    onChangeEnd: (value) async {
                      print("this is the final value: $value");
                      await upVoteComment(
                          commentId: widget.comment_id, weight: _value*100);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
  }
}
