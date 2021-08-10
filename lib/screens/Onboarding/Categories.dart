import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingCategories extends StatefulWidget {
  static const String id = 'Category Selection';

  @override
  _OnboardingCategoriesState createState() => _OnboardingCategoriesState();
}

class _OnboardingCategoriesState extends State<OnboardingCategories> {
  var categories = [];
  var selectedCategories = [];

  postreq.Interceptor intercept = postreq.Interceptor();

  void getCategories() async {
    String url = 'https://api.aureal.one/public/getCategory';

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body)['allCategory'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void sendCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/addUserCategory';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    String key = '';

    for (var v in selectedCategories) {
      key += v.toString() + '_';
    }

    map['category_ids'] = key;

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response);
  }

  @override
  void initState() {
    // TODO: implement initState
    getCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Select Categories",
            textScaleFactor: 0.75,
            style: TextStyle(
                //   color: Colors.white,
                fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () async {
                if (selectedCategories.length == 0) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      HiveDetails.id, (Route<dynamic> route) => false);
                } else {
                  await sendCategories();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      HiveDetails.id, (Route<dynamic> route) => false);
                }
              },
              child: selectedCategories.length == 0
                  ? Text(
                      'Skip',
                      textScaleFactor: 1,
                      style: TextStyle(
                          // color: Colors.white,
                          fontSize: SizeConfig.safeBlockHorizontal * 4),
                    )
                  : Text(
                      'Save',
                      textScaleFactor: 1,
                      style: TextStyle(
                          //   color: Colors.white,
                          fontSize: SizeConfig.safeBlockHorizontal * 4),
                    ),
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Center(
                child: ListView(
                  children: <Widget>[
                    Wrap(
                      runSpacing: 15.0,
                      spacing: 15.0,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        for (var v in categories)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selectedCategories.contains(v['id'])) {
                                    selectedCategories.remove(v['id']);
                                  } else {
                                    selectedCategories.add(v['id']);
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(30),
                                    color: selectedCategories.contains(v['id'])
                                        ? Colors.blue
                                        : Colors.white),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 15),
                                  child: Text(
                                    v['name'],
                                    textScaleFactor: 0.75,
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3,
                                        color:
                                            selectedCategories.contains(v['id'])
                                                ? Colors.white
                                                : Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
class UserCategories extends StatefulWidget {


  @override
  _UserCategoriesState createState() => _UserCategoriesState();
}

class _UserCategoriesState extends State<UserCategories> {
  var userselectedCategories = [];
  var availableCategories = [];
  postreq.Interceptor intercept = postreq.Interceptor();
  void userCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/getCategory?user_id=${prefs
        .getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          userselectedCategories = jsonDecode(response.body)['Categories_you_like'];
        });
      }
    } catch (e) {
      print(e);
    }
  }
  void showCategories() async {
    String url = 'https://api.aureal.one/public/getCategory';

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          availableCategories = jsonDecode(response.body)['allCategory'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void selectCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/private/addUserCategory';
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    String key = '';

    for (var v in userselectedCategories) {
      key += v.toString() + '_';
    }

    map['Categories_you_like'] = key;

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response);
  }

  @override
  void initState() {
    // TODO: implement initState
   userCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
          ],
        ),
           body:Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: ListView(
                    children: <Widget>[
                      Wrap(
                        runSpacing: 15.0,
                        spacing: 15.0,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          for (var v in userselectedCategories)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(30),
                                color:Colors.white),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 15),
                                  child: Text(
                                    v['name'],
                                    textScaleFactor: 0.75,
                                    style: TextStyle(
                                        fontSize:
                                        SizeConfig.safeBlockHorizontal * 3,
                                        color:Colors.black)
                                  ),
                                ),
                              ),
                            )
                        ],
                      ),
                      // FlatButton(
                      //   onPressed: () async {
                      //     if (userselectedCategories.length == 0) {
                      //       Navigator.of(context).pushNamedAndRemoveUntil(
                      //           HiveDetails.id, (Route<dynamic> route) => false);
                      //     } else {
                      //       await selectCategories();
                      //       Navigator.of(context).pushNamedAndRemoveUntil(
                      //           HiveDetails.id, (Route<dynamic> route) => false);
                      //     }
                      //   },
                      //   child: userselectedCategories.length == 0
                      //       ? Text(
                      //     'Skip',
                      //     textScaleFactor: 1,
                      //     style: TextStyle(
                      //       // color: Colors.white,
                      //         fontSize: SizeConfig.safeBlockHorizontal * 4),
                      //   )
                      //       : Text(
                      //     'Save',
                      //     textScaleFactor: 1,
                      //     style: TextStyle(
                      //       //   color: Colors.white,
                      //         fontSize: SizeConfig.safeBlockHorizontal * 4),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        );

  }
}
