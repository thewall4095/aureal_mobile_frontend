import 'package:flutter/material.dart';

class UserProfile {
  String userId;

  UserProfile({this.userId});

  void updateProfile() async {
    String url = 'https://api.aureal.one/private/updateUser';

    var map = Map<String, dynamic>();

    map['user_id'] = userId;
  }
}
