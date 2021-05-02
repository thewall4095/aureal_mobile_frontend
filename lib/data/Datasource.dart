import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/BrowsePageResponse.dart';
import 'models/HomePageResponse.dart';
import 'models/DiscoverPageResponse.dart';

class DataSource {
  static Future<HomePageResponse> fetchFollowingPageResponse(
      BuildContext context) async {
    String response = await DefaultAssetBundle.of(context)
        .loadString('assets/homeDummyData.json');

    if (response != null) {
      Future.delayed(Duration(seconds: 1),
          () => HomePageResponse.fromJson(json.decode(response)));
    } else {
      print("loading failed");
      throw Exception("failed to load");
    }
  }

  static Future<DiscoverPageResponse> fetchDiscoverPageResponse(
      BuildContext context) async {
    String response = await DefaultAssetBundle.of(context)
        .loadString("assets/discoverDummyData.json");

    if (response != null) {
      return Future.delayed(Duration(seconds: 1),
          () => DiscoverPageResponse.fromJson(json.decode(response)));
    } else {
      print("loading failed");
      throw Exception('Failed to load');
    }
  }

  Future<BrowsePageResponse> fetchBrowsePageResponse(
      BuildContext context) async {
    String response = await DefaultAssetBundle.of(context)
        .loadString("assets/browseDummyData.json");

    if (response != null) {
      return Future.delayed(Duration(seconds: 1),
          () => BrowsePageResponse.fromJson(json.decode(response)));
    } else {
      print("loading failed");
      throw Exception('Failed to load');
    }
  }
}
