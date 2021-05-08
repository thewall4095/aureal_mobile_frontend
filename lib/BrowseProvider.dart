import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BrowseProvider extends ChangeNotifier {
  List _browseEpisodesList = [];
  List _browsePodcastsList = [];

  bool _isFetchedBrowseEpisodesList = false;
  bool _isFetchedBrowsePodcastsList = false;

  get isFetchedBrowseEpisodesList => _isFetchedBrowseEpisodesList;
  get isFetchedBrowsePodcastsList => _isFetchedBrowsePodcastsList;

  get browseEpisodesList => _browseEpisodesList;
  get browsePodcastsList => _browsePodcastsList;

  set browseEpisodesList(var newValue) {
    _browseEpisodesList = newValue;

    notifyListeners();
  }

  set browsePodcastsList(var newValue) {
    _browsePodcastsList = newValue;

    notifyListeners();
  }

  void getBrowseEpisodesList() async {
    _isFetchedBrowseEpisodesList = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/browseEpisode?user_id=${prefs.getString('userId')}&sort=${prefs.getString('sort')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetchedBrowseEpisodesList = true;
      if (response.statusCode == 200) {
        print(response.body);
        browseEpisodesList = jsonDecode(response.body)['EpisodeResult'];
      }
    } catch (e) {
      _isFetchedBrowseEpisodesList = true;
      print(e);
    }
  }

  void getBrowsePodcastsList() async {
    _isFetchedBrowsePodcastsList = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/browsePodcast?user_id=${prefs.getString('userId')}&sort=${prefs.getString('sort')}';
    print(url);
    try {
      http.Response response = await http.get(Uri.parse(url));
      _isFetchedBrowsePodcastsList = true;
      if (response.statusCode == 200) {
        browsePodcastsList = jsonDecode(response.body)['PodcastResult'];
        print(response.body);
      }
    } catch (e) {
      _isFetchedBrowsePodcastsList = true;
      print(e);
    }
  }
}
