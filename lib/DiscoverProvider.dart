import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiscoverProvider extends ChangeNotifier {
  // var _discoverList = [
  //   {
  //     'topic': "Featured Podcasts",
  //     'Key': 'featured',
  //     'data': [],
  //     'isLoaded': false
  //   },
  //   {
  //     'topic': 'Recently Played',
  //     'Key': 'general_episode',
  //     'data': [],
  //     'isLoaded': false
  //   },
  //   {
  //     'topic': 'Popular and Trending',
  //     'Key': 'general_podcast',
  //     'data': [],
  //     'isLoaded': false
  //   },
  //   {
  //     'topic': 'Newly Released',
  //     'Key': 'general_podcast',
  //     'data': [],
  //     'isLoaded': false
  //   },
  //   {
  //     'topic': 'Recommended for you',
  //     'Key': 'general_podcast',
  //     'data': [],
  //     'isLoaded': false
  //   }
  // ];

  var _discoverList = [];

  bool _isFetcheddiscoverList = false;
  get discoverList => _discoverList;

  get isFetcheddiscoverList => _isFetcheddiscoverList;

  set discoverList(var newValue) {
    _discoverList = newValue;

    notifyListeners();
  }

  void getDiscoverProvider() async {
    _isFetcheddiscoverList = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/discover?user_id=${prefs.getString('userId')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetcheddiscoverList = true;

      if (response.statusCode == 200) {
        discoverList = jsonDecode(response.body)['ans'];
      }
    } catch (e) {
      _isFetcheddiscoverList = true;
      print(e);
    }
    // getFeaturedPodcasts();
    // getRecentlyPlayed();
    // getNewest();
  }

  void getFeaturedPodcasts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/featured?user_id=${prefs.getString('userId')}";
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        _discoverList[0]['data'] = jsonDecode(response.body)['featured'];
        print(_discoverList[0]['data']);
        _discoverList[0]['isLoaded'] = true;
      }
    } catch (e) {
      print(e);
    }
  }

  void getRecentlyPlayed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/recently?user_id=${prefs.getString('userId')}";
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        _discoverList[1]['data'] = jsonDecode(response.body)['recently'];
        print(_discoverList[1]['data']);
        _discoverList[1]['isLoaded'] = true;
      }
    } catch (e) {
      print(e);
    }
  }

  void getNewest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://apip.aureal.one/public/newest?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        _discoverList[3]['data'] = jsonDecode(response.body)['featured'];
        print(_discoverList[3]['data']);
        _discoverList[3]['isLoaded'] = true;
      }
    } catch (e) {
      print(e);
    }
  }

  void getDiscoverProviderPaginated({int pageNumber}) async {
    print("Starting the API for discover content");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/public/discover?user_id=${prefs.getString('userId')}&page=$pageNumber";

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }
}
