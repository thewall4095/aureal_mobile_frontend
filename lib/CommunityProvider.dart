import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommunityProvider extends ChangeNotifier {
  bool _isFetcheduserCommunities = false;
  bool _isFetchedallCommunities = false;
  bool _isFetcheduserCreatedCommunities = false;
  bool _isFetchedcommunityEpisodes = false;
  bool _isFetchedhomeEpisodes = false;

  List _userCommunities = [];
  List _allCommunities = [];
  List _userCreatedCommunities = [];
  List _searchResults = [];
  List _communityEpisodes = [];
  List _homeEpisodes = [];

  List get userCreatedCommunities => _userCreatedCommunities;
  List get userCommunities => _userCommunities;
  List get allCommunities => _allCommunities;
  List get searchResults => _searchResults;
  List get communityEpisodes => _communityEpisodes;
  List get homeEpisodes => _homeEpisodes;

  bool get isFetcheduserCommunities => _isFetcheduserCommunities;
  bool get isFetchedallCommunities => _isFetchedallCommunities;
  bool get isFetcheduserCreatedCommunities => _isFetcheduserCreatedCommunities;
  bool get isFetchedcommunityEpisodes => isFetchedcommunityEpisodes;
  bool get isFetchedhomeEpisodes => _isFetchedhomeEpisodes;

  set homeEpisodes(var newValue) {
    _homeEpisodes = newValue;

    notifyListeners();
  }

  set userCreatedCommunities(var newValue) {
    _userCreatedCommunities = newValue;
    notifyListeners();
  }

  set userCommunities(var newValue) {
    _userCommunities = newValue;
    notifyListeners();
  }

  set allCommunities(var newValue) {
    _allCommunities = newValue;
    notifyListeners();
  }

  set searchResults(var newValue) {
    _searchResults = newValue;

    notifyListeners();
  }

  set communityEpisodes(var newValue) {
    _communityEpisodes = newValue;

    notifyListeners();
  }

  void getUserCreatedCommunities() async {
    print("********************getting user Created Communities");
    _isFetcheduserCreatedCommunities = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/getCommunity?user_id=${prefs.getString('userId')}&relation=creator";
    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetcheduserCreatedCommunities = true;
      if (response.statusCode == 200) {
        userCreatedCommunities = jsonDecode(response.body)['allCommunity'];
        print(userCreatedCommunities);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      _isFetcheduserCreatedCommunities = true;
      print(e);
    }
  }

  void getAllCommunitiesForUser() async {
    print("*******************getting communities for user");
    _isFetcheduserCommunities = false;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCommunity?user_id=${prefs.getString('userId')}&relation=follower';
    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetcheduserCommunities = true;
      if (response.statusCode == 200) {
        userCommunities = jsonDecode(response.body)['allCommunity'];
        print(userCommunities);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      _isFetcheduserCommunities = true;
      print(e);
    }
  }

  void getAllCommunity() async {
    print('******************getting all communities for user');
    String url = 'https://api.aureal.one/public/getCommunity';
    _isFetchedallCommunities = false;

    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetchedallCommunities = true;
      if (response.statusCode == 200) {
        print(response.body);
        allCommunities = jsonDecode(response.body)['allCommunity'];
        print(allCommunities);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      _isFetchedallCommunities = true;
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

  void getCommunityEpisodes({int communityId}) async {
    _isFetchedcommunityEpisodes = false;

    String url =
        'https://api.aureal.one/public/getCommunityEpisodes?community_id=$communityId';
    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetchedcommunityEpisodes = true;
      if (response.statusCode == 200) {
        print(response.body);
        communityEpisodes = jsonDecode(response.body)['EpisodeResult'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      _isFetchedcommunityEpisodes = true;
      print(e);
    }
  }

  void getCommunityEpisodesforUser() async {
    _isFetchedhomeEpisodes = false;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCommunityEpisodes?user_id=${prefs.getString('userId')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetchedhomeEpisodes = true;
      if (response.statusCode == 200) {
        print(response.body);
        homeEpisodes = jsonDecode(response.body)['allEpisodes'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      _isFetchedhomeEpisodes = true;
      print(e);
    }
  }

  void communitySearch(String query) async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/searchCommunity?word=$query';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        searchResults = jsonDecode(response.body)['allCommunity'];
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }
}
