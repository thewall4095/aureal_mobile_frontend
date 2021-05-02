import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Interceptor {
  Interceptor();

  String token;
  String hiveToken;

  void getToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    token = await pref.getString('token');
    hiveToken = await pref.getString('access_token');
    print(token);
    print(hiveToken);
  }

  Future<Map<String, dynamic>> getRequest(String url) async {
    await getToken();
    print(hiveToken);
    SharedPreferences pref = await SharedPreferences.getInstance();
    hiveToken = await pref.getString('access_token');

    http.Response response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
      'access-token': '$hiveToken'
    });
//    return jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (response.body.contains('msg') == true) {
        Fluttertoast.showToast(
            msg: jsonDecode(response.body)['msg'],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff3a3a3a),
            textColor: Color(0xffe8e8e8),
            fontSize: 12.0);
      }
      return jsonDecode(response.body);
    } else {
      Fluttertoast.showToast(
          msg: "Operation unauthorised.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff3a3a3a),
          textColor: Color(0xffe8e8e8),
          fontSize: 12.0);
      print(response.statusCode);
    }
  }

  Future postRequest(formData, url) async {
    await getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    hiveToken = await prefs.getString('access_token');
    print(hiveToken);
    Dio dio = Dio(BaseOptions(headers: {
      "Authorization": "Bearer $token",
    }));
    print('Hive token: $hiveToken');
    try {
      var response = await dio.post(
        url,
        data: formData,
      );

      print(response.statusCode);

      // if (response.statusCode == 401) {
      //   Fluttertoast.showToast(
      //       msg: "Operation unauthorised.",
      //       toastLength: Toast.LENGTH_LONG,
      //       gravity: ToastGravity.BOTTOM,
      //       timeInSecForIosWeb: 1,
      //       backgroundColor: Color(0xff3a3a3a),
      //       textColor: Color(0xffe8e8e8),
      //       fontSize: 12.0);
      // }
      //
      // print(response.data);
      // if (jsonDecode(response.data) == true) {
      //   Fluttertoast.showToast(
      //       msg: response.data.msg,
      //       toastLength: Toast.LENGTH_LONG,
      //       gravity: ToastGravity.BOTTOM,
      //       timeInSecForIosWeb: 1,
      //       backgroundColor: Color(0xff3a3a3a),
      //       textColor: Color(0xffe8e8e8),
      //       fontSize: 12.0);
      // }
      // if (response.data)
      return response;
    } catch (err) {
      print(err);
      // Fluttertoast.showToast(
      //     msg: "Something went wrong.",
      //     toastLength: Toast.LENGTH_LONG,
      //     gravity: ToastGravity.BOTTOM,
      //     timeInSecForIosWeb: 1,
      //     backgroundColor: Color(0xff3a3a3a),
      //     textColor: Color(0xffe8e8e8),
      //     fontSize: 12.0);
    }
  }
}
