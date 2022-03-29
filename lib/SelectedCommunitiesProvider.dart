import 'package:flutter/material.dart';

class SelectedCommunityProvider extends ChangeNotifier {
  List _selectedCommunities = [];

  List get selectedCommunities => _selectedCommunities;

  set selectedCommunities(var newValue) {
    _selectedCommunities = newValue;

    notifyListeners();
  }

  void clearSelectedCommunities() {
    selectedCommunities = [];
  }
}
