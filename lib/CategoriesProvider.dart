import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CategoriesProvider extends ChangeNotifier {
  List _categoryList = [];

  bool _isFetchedCategories = false;

  get isFetchedCategories => _isFetchedCategories;

  set isFetchedCategories(bool newValue) {
    _isFetchedCategories = newValue;
    notifyListeners();
  }

  get categoryList => _categoryList;

  set categoryList(var newValue) {
    _categoryList = newValue;

    notifyListeners();
  }

  void getCategories() async {
    String url = 'https://api.aureal.one/public/getCategory';

    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        categoryList = jsonDecode(response.body)['allCategory'];
        isFetchedCategories = true;
        print(_categoryList.toString());
      }
    } catch (e) {
      print(e);
    }
  }
}
