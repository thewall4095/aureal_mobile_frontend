import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Categories.dart';

class SelectLanguage extends StatefulWidget {
  static const String id = "language selection";

  @override
  _SelectLanguageState createState() => _SelectLanguageState();
}

class _SelectLanguageState extends State<SelectLanguage> {
  postreq.Interceptor intercept = postreq.Interceptor();

  GlobalKey<FormState> _languageSelection =
      GlobalKey<FormState>(debugLabel: '_languageSelection');

  bool isLoading = false;

  var languages = [];
  var selectedLanguages = [];

  void getLanguages() async {
    String url = 'https://api.aureal.one/public/getLanguage';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          languages = jsonDecode(response.body)['lang'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void selectLanguage() async {
    String url = 'https://api.aureal.one/private/addUserLanguage';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = '';

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    for (var v in selectedLanguages) {
      key += v.toString() + '_';
    }
    print(key);
    map['lang_ids'] = key;

    FormData formData = FormData.fromMap(map);
    var response = await intercept.postRequest(formData, url);
    print(response.toString());
  }

  @override
  void initState() {
    // TODO: implement initState
    getLanguages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //   backgroundColor: kPrimaryColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            "Language Preference",
            textScaleFactor: 0.75,
            //   style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: ModalProgressHUD(
          inAsyncCall: isLoading,
          child: Stack(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          for (var v in languages)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: FlatButton(
                                onPressed: () {
                                  setState(() {
                                    if (selectedLanguages.contains(v['id'])) {
                                      selectedLanguages.remove(v['id']);
                                    } else {
                                      selectedLanguages.add(v['id']);
                                    }
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  width: double.infinity,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        v['name'],
                                        textScaleFactor: 0.75,
                                        style: TextStyle(
                                            //    color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18),
                                      ),
                                      selectedLanguages.contains(v['id'])
                                          ? Icon(
                                              Icons.radio_button_checked,
                                              color: kActiveColor,
                                            )
                                          : Icon(
                                              Icons.radio_button_checked,
                                              color: kPrimaryColor,
                                            )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                            height: 50,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          isLoading = true;
                        });
                        print("Next pressed");
                        if (selectedLanguages.length == 0) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              OnboardingCategories.id,
                              (Route<dynamic> route) => false);
                        } else {
                          await selectLanguage();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              OnboardingCategories.id,
                              (Route<dynamic> route) => false);
                        }
                        setState(() {
                          isLoading = false;
                        });
                      },
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            gradient: kGradient,
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(30)),
                        child: Center(
                            child: selectedLanguages.length == 0
                                ? Text(
                                    'Skip',
                                    textScaleFactor: 0.75,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                : Text(
                                    "Next",
                                    textScaleFactor: 0.75,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
