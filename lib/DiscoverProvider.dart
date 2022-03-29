import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiscoverProvider extends ChangeNotifier {
  //Loaders ////////////////////////////////////////////////////

  bool _featuredLoading = false;
  get featuredLoading => _featuredLoading;

  set featuredLoading(bool newValue) {
    _featuredLoading = newValue;

    notifyListeners();
  }

  bool _recentlyPlayedLoading = false;
  get recentlyPlayedLoading => _recentlyPlayedLoading;

  set recentlyPlayedLoading(bool newValue) {
    _recentlyPlayedLoading = newValue;

    notifyListeners();
  }

  bool _newestLoading = false;
  get newestLoading => _newestLoading;

  set newestLoading(bool newValue) {
    _newestLoading = newValue;

    notifyListeners();
  }

  bool _popularLoading = false;
  get popularLoading => _popularLoading;

  set popularLoading(bool newValue) {
    _popularLoading = newValue;

    notifyListeners();
  }

  bool _recommendedLoading = false;
  get recommendedLoading => _recommendedLoading;

  set recommendedLoading(bool newValue) {
    _recommendedLoading = newValue;

    notifyListeners();
  }

  //response List //////////////////////////////////////////////

  var _featuredPodcast;
  get featuredPodcast => _featuredPodcast;

  var _recentlyPlayed;
  get recentlyPlayed => _recentlyPlayed;

  var _popular;
  get popular => _popular;

  var _newPodcast;
  get newPodcast => _newPodcast;

  var _recommended;
  get recommended => _recommended;

  set featuredPodcast(var newValue) {
    _featuredPodcast = newValue;
    notifyListeners();
  }

  set recentlyPlayed(var newValue) {
    _recentlyPlayed = newValue;
    notifyListeners();
  }

  set popular(var newValue) {
    _popular = newValue;
    notifyListeners();
  }

  set newPodcast(var newValue) {
    _newPodcast = newValue;
    notifyListeners();
  }

  set recommended(var newValue) {
    _recommended = newValue;
    notifyListeners();
  }

  var discoverList = [
    {
      'topic': "Featured Podcasts",
      'Key': 'featured',
      'data': [],
      'isLoaded': false
    },
    {
      'topic': 'Recently Played',
      'Key': 'general_episode',
      'data': [],
      'isLoaded': false
    },
    {
      'topic': 'Popular and Trending',
      'Key': 'general_podcast',
      'data': [],
      'isLoaded': false
    },
    {
      'topic': 'Newly Released',
      'Key': 'general_podcast',
      'data': [],
      'isLoaded': false
    },
    {
      'topic': 'Recommended for you',
      'Key': 'general_podcast',
      'data': [],
      'isLoaded': false
    }
  ];

  bool _isFetcheddiscoverList = false;
  // get discoverList => _discoverList;

  get isFetcheddiscoverList => _isFetcheddiscoverList;

  /*set discoverList(var newValue) {
    _discoverList = newValue;

    notifyListeners();
  }*/

  void getDiscoverProvider() async {
    await getPreferences();
    _isFetcheddiscoverList = false;
    getFeatured();
    getRecentlyPlayed();
    getNewPodcast();
    podcastInTrend();
    recommendedPodcast();
    _isFetcheddiscoverList = true;
  }

  SharedPreferences prefs;

  void getPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }
  Dio dio = Dio();
  CancelToken cancelToken = CancelToken();

  void getFeatured() async {
    String url =
        'https://api.aureal.one/public/featured?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        featuredPodcast = jsonDecode(response.body)['featured'];
        discoverList[0]['data'] = featuredPodcast;
        featuredLoading = true;
        discoverList[0]['isLoaded'] = featuredLoading;
        print(featuredPodcast);
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getRecentlyPlayed() async {
    String url =
        'https://api.aureal.one/public/recently?user_id=${prefs.getString('userId')}';
    try {
      var response = await dio.get(url, cancelToken: cancelToken);
      if (response.statusCode == 200) {
        recentlyPlayed = jsonDecode(response.data)['recently'];
        discoverList[1]['data'] = _recentlyPlayed;
        recentlyPlayedLoading = true;
        discoverList[0]['isLoaded'] = recentlyPlayedLoading;
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void podcastInTrend() async {
    String url =
        'https://api.aureal.one/public/inTrend?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        popular = jsonDecode(response.body)['trending'];
        discoverList[2]['data'] = _popular;
        popularLoading = true;
        discoverList[2]['isLoaded'] = popularLoading;
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void getNewPodcast() async {
    String url =
        'https://api.aureal.one/public/newest?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        newPodcast = jsonDecode(response.body)['newest'];
        discoverList[3]['data'] = _newPodcast;
        newestLoading = true;
        discoverList[3]['isLoaded'] = newestLoading;
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void recommendedPodcast() async {
    String url =
        'https://api.aureal.one/public/recommend?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        recommended = jsonDecode(response.body)['for_you'];
        discoverList[4]['data'] = _recommended;
        recommendedLoading = true;
        discoverList[4]['isLoaded'] = recommendedLoading;
      } else {
        print(response.statusCode);
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
