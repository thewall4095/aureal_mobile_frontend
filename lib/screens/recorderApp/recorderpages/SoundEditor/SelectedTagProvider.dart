import 'package:flutter/material.dart';

class SelectedTagProvider extends ChangeNotifier{
  List _selectedTag = [];
  List get selectedTag => _selectedTag;

  set selectedTag(var newValue) {
    _selectedTag = newValue;

    notifyListeners();
  }

  void clearSelectedCommunities() {
    selectedTag = [];
  }
}