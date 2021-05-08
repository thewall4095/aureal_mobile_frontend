import 'dart:async';
import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';

class CommunityService {
  Future<List> getAllCommunitiesForUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCommunity?user_id=${prefs.getString('userId')}&relation=creator';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['allCommunity'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List> getAllCommunity() async {
    String url = 'https://api.aureal.one/public/getCommunity';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['allCommunity'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void addCommunity({String communityName, String description}) async {
    postreq.Interceptor intercept = postreq.Interceptor();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/addCommunity';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['community_name'] = communityName;
    map['description'] = description;

    FormData formData = FormData.fromMap(map);
    try {
      print(map.toString());
      var response = await intercept.postRequest(formData, url);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  void subscribeCommunity({int communityId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    postreq.Interceptor intercept = postreq.Interceptor();
    String url = "https://api.aureal.one/public/subscribeCommunity";
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['community_id'] = communityId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      await getAllCommunity();
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  void unSubScribeCommunity({int communityId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    postreq.Interceptor intercept = postreq.Interceptor();
    String url = "https://api.aureal.one/public/unsubscribeCommunity";
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['community_id'] = communityId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> getCommunityEpisodes({int communityId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCommunityEpisodes?community_id=$communityId&user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
        // return jsonDecode(response.body);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List> getCommunityEpisodesforUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCommunityEpisodes?user_id=${prefs.getString('userId')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
    } catch (e) {
      print(e);
    }
  }
}
