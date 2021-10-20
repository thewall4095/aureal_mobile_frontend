import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/Onboarding/HiveDetails.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icons.dart';
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

  List _icons = [
    LineIcons.palette,
    LineIcons.briefcase,
    LineIcons.laughFaceWithBeamingEyes,
    LineIcons.fruitApple,
    LineIcons.cloudWithAChanceOfMeatball,
    LineIcons.businessTime,
    LineIcons.hourglass,
    LineIcons.swimmingPool,
    LineIcons.baby,
    LineIcons.beer,
    LineIcons.music,
    LineIcons.newspaper,
    LineIcons.twitter,
    LineIcons.atom,
    LineIcons.globe,
    LineIcons.footballBall,
    LineIcons.alternateGithub,
    LineIcons.dungeon,
    LineIcons.television
  ];

  @override
  void initState() {
    // TODO: implement initState
    getCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return SafeArea(
      child: Scaffold(
          body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            color: Color(0xff161616),
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "Select Topics:",
                  textScaleFactor: 1.0,
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 7,
                      fontWeight: FontWeight.w600),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Please select 3 or more topics to personalise your Aureal feed",
                  textScaleFactor: 1.0,
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 3.6,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          Expanded(
            child: categories.length == 0
                ? Container()
                : ListView.builder(
                    itemCount: _icons.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              if (selectedCategories
                                  .contains(categories[index]['id'])) {
                                selectedCategories
                                    .remove(categories[index]['id']);
                              } else {
                                selectedCategories.add(categories[index]['id']);
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          selectedTileColor: Color(0xff222222),
                          selected: selectedCategories
                              .toSet()
                              .toList()
                              .contains(categories[index]['id']),
                          leading: Icon(_icons[index]),
                          title: Text("${categories[index]['name']}"),
                        ),
                      );
                    }),
          ),
          Container(
            color: Color(0xff161616),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: () async {
                      if (selectedCategories.length == 0) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            HiveDetails.id, (Route<dynamic> route) => false);
                      } else {
                        await sendCategories(); //TODO: Some fuckup here!
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            HiveDetails.id, (Route<dynamic> route) => false);
                      }
                    },
                    child: Container(
                      decoration: selectedCategories.isEmpty
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Color(0xff222222))
                          : BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: kGradient),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Text("CONTINUE"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Select at least 3 topics"),
                )
              ],
            ),
          )
        ],
      )),
    );
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
    String url =
        'https://api.aureal.one/public/getCategory?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      // print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          userselectedCategories =
              jsonDecode(response.body)['Categories_you_like'];
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
      // print(response.body);
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

    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    userCategories();
    showCategories();
    super.initState();
  }

  List _icons = [
    LineIcons.palette,
    LineIcons.briefcase,
    LineIcons.laughFaceWithBeamingEyes,
    LineIcons.fruitApple,
    LineIcons.cloudWithAChanceOfMeatball,
    LineIcons.businessTime,
    LineIcons.hourglass,
    LineIcons.swimmingPool,
    LineIcons.baby,
    LineIcons.beer,
    LineIcons.music,
    LineIcons.newspaper,
    LineIcons.twitter,
    LineIcons.atom,
    LineIcons.globe,
    LineIcons.footballBall,
    LineIcons.alternateGithub,
    LineIcons.dungeon,
    LineIcons.television
  ];

  @override
  Widget build(BuildContext context) {
    print(userselectedCategories);
    print(availableCategories);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        //     backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.navigate_before,
          ),
          onPressed: () {
            print("Pop button pressed");
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Categories",
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Color(0xff161616),
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "Select Topics:",
                  textScaleFactor: 1.0,
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 7,
                      fontWeight: FontWeight.w600),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Please select 3 or more topics to personalise your Aureal feed",
                  textScaleFactor: 1.0,
                  style: TextStyle(
                      fontSize: SizeConfig.safeBlockHorizontal * 3.6,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          Expanded(
            child: availableCategories.length == 0
                ? Container()
                : ListView.builder(
                    itemCount: _icons.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              if (userselectedCategories
                                  .contains(availableCategories[index]['id'])) {
                                userselectedCategories
                                    .remove(availableCategories[index]['id']);
                              } else {
                                userselectedCategories
                                    .add(availableCategories[index]['id']);
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          selectedTileColor: Color(0xff222222),
                          selected: userselectedCategories
                              .toSet()
                              .toList()
                              .contains(availableCategories[index]['id']),
                          leading: Icon(_icons[index]),
                          title: Text("${availableCategories[index]['name']}"),
                        ),
                      );
                    }),
          ),
          Container(
            color: Color(0xff161616),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: () async {
                      selectCategories();
                    },
                    child: Container(
                      decoration: userselectedCategories.isEmpty
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Color(0xff222222))
                          : BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: kGradient),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Text("CONTINUE"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Select at least 3 topics"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Wrap(
//   runSpacing: 15.0,
//   spacing: 15.0,
//   alignment: WrapAlignment.center,
//   children: <Widget>[
//     for (var v in categories)
//       Padding(
//         padding: const EdgeInsets.symmetric(
//             horizontal: 5, vertical: 5),
//         child: GestureDetector(
//           onTap: () {
//             setState(() {
//               if (selectedCategories.contains(v['id'])) {
//                 selectedCategories.remove(v['id']);
//               } else {
//                 selectedCategories.add(v['id']);
//               }
//             });
//           },
//           child: Container(
//             decoration: BoxDecoration(
//                 border: Border.all(),
//                 borderRadius: BorderRadius.circular(30),
//                 color: selectedCategories.contains(v['id'])
//                     ? Colors.blue
//                     : Colors.white),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(
//                   vertical: 8, horizontal: 15),
//               child: Text(
//                 v['name'],
//                 textScaleFactor: 0.75,
//                 style: TextStyle(
//                     fontSize:
//                         SizeConfig.safeBlockHorizontal * 3,
//                     color:
//                         selectedCategories.contains(v['id'])
//                             ? Colors.white
//                             : Colors.black),
//               ),
//             ),
//           ),
//         ),
//       )
//   ],
// )
