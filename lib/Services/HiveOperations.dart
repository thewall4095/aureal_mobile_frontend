import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Interceptor.dart' as postreq;

void upvoteEpisode({String permlink, int episode_id}) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = 'https://api.aureal.one/public/voteEpisode';

  if (prefs.getString('HiveUserName') != null) {
    if (permlink != null) {
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['permlink'] = permlink;
      map['weight'] = 10000;
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

void upVoteComment(String commentId) async {
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
