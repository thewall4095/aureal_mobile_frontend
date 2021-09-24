import 'dart:convert';

import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/screens/LoginSignup/WelcomeScreen.dart';
import 'package:auditory/screens/Onboarding/Categories.dart';
import 'package:auditory/screens/buttonPages/settings/Prefrences.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'settings/security/Security.dart';

class Settings extends StatefulWidget {
  static const String id = "Settings";

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var loggedInUser;

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    if (!prefs.containsKey('userId')) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Welcome.id, (Route<dynamic> route) => false);
    }
  }

  SharedPreferences prefs;
  Dio dio = Dio();

  void setData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInUser = prefs.getString('userId');
  }

  String hiveUserName;
  void feedBack() async {
    String url = "'https://api.aureal.one/public/report";

    var map = Map<String, dynamic>();
    map['message'] = feedback;

    FormData formData = FormData.fromMap(map);

    var response = await dio.post(url, data: formData);

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: "We've received your feedback");
    }
  }

  void hiveUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/private/users?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          hiveUserName = prefs.getString('HiveUserName');
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // void explorePodcast() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String url =
  //       "https://api.aureal.one/public/explorePodcasts?type=new&page=${explorPage}&user_id=${prefs
  //       .getString('userId')}&category_ids=${widget.categoryObject['id']}";
  //   try {
  //     http.Response response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       print(response.body);
  //       setState(() {
  //         explorePodcasts = jsonDecode(response.body)['podcasts'];
  //       });
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }
  @override
  void initState() {
    // TODO: implement initState
//    getCurrentUser();
    setData();
    super.initState();
  }

  String feedback;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);
    Launcher launcher = Launcher();
    SizeConfig().init(context);
    return Scaffold(
        //  backgroundColor: kPrimaryColor,
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
            "Settings",
            textScaleFactor:
                mediaQueryData.textScaleFactor.clamp(0.5, 0.8).toDouble(),
            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
        ),
        body: SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        showBarModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Scaffold(
                                appBar: AppBar(
                                  title: Text(
                                    "Send Feedback",
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                    textScaleFactor: 1.0,
                                  ),
                                ),
                                body: Container(
                                  child: ListView(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 20),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: kSecondaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextField(
                                                  onChanged: (value) {
                                                    setState(() {
                                                      feedback = value;
                                                    });
                                                  },
                                                  maxLines: 25,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20, horizontal: 15),
                                            child: InkWell(
                                              onTap: () {
                                                if (feedback.isEmpty == true) {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          "Please enter a message");
                                                } else {
                                                  feedBack();
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: kSecondaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 15),
                                                      child: Text(
                                                        "Send",
                                                        style: TextStyle(
                                                            fontSize: SizeConfig
                                                                    .safeBlockHorizontal *
                                                                4),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                        // Navigator.pushNamed(context, Prefrences.id);
                      },
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "Send Feedback",
                                  textScaleFactor: mediaQueryData
                                      .textScaleFactor
                                      .clamp(0.5, 1.5)
                                      .toDouble(),
                                  style: TextStyle(
                                      //  color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3.5),
                                ),
                                Text(
                                  "Let us know if you see anything troubling",
                                  textScaleFactor: mediaQueryData
                                      .textScaleFactor
                                      .clamp(0.5, 0.8)
                                      .toDouble(),
                                  style: TextStyle(
                                      //       color: Colors.white70,
                                      fontWeight: FontWeight.w300,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3),
                                )
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 15)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => UserCategories()));
                      },
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "Categories",
                                  textScaleFactor: mediaQueryData
                                      .textScaleFactor
                                      .clamp(0.5, 1.5)
                                      .toDouble(),
                                  style: TextStyle(
                                      //  color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3.5),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Select Categories",
                                  textScaleFactor: mediaQueryData
                                      .textScaleFactor
                                      .clamp(0.5, 0.8)
                                      .toDouble(),
                                  style: TextStyle(
                                      //       color: Colors.white70,
                                      fontWeight: FontWeight.w300,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3),
                                )
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 15)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Container(
                      child: InkWell(
                        onTap: () {
                          launcher.launchInBrowser(
                              "https://play.google.com/store/apps/details?id=co.titandlt.auditory");
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "Version",
                                  textScaleFactor: mediaQueryData
                                      .textScaleFactor
                                      .clamp(0.5, 1.5)
                                      .toDouble(),
                                  style: TextStyle(
                                      //  color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 3.5),
                                ),
                                SizedBox(height: 5),
                              ],
                            ),
                            Text("1.0.49"),
                            //    Icon(Icons.arrow_forward_ios_rounded)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 2.1,
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                          bottom: 3, // space between underline and text
                        ),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                          color: Colors.white, // Text colour here
                          width: 1.0, // Underline width
                        ))),
                        child: Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Colors.white, // Text colour here
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text("and"),
                      SizedBox(
                        width: 5,
                      ),
                      Container(
                        padding: EdgeInsets.only(
                          bottom: 3, // space between underline and text
                        ),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                          color: Colors.white, // Text colour here
                          width: 1.0, // Underline width
                        ))),
                        child: Text(
                          "Terms of Use",
                          style: TextStyle(
                            color: Colors.white, // Text colour here
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Container(
                  //   padding: EdgeInsets.only(
                  //     bottom: 3, // space between underline and text
                  //   ),
                  //   decoration: BoxDecoration(
                  //       border: Border(bottom: BorderSide(
                  //         color: Colors.white,  // Text colour here
                  //         width: 1.0, // Underline width
                  //       ))
                  //   ),
                  //
                  //   child: Text(
                  //     "Privacy Policy and Terms of Use",
                  //     style: TextStyle(
                  //       color: Colors.white,  // Text colour here
                  //     ),
                  //   ),
                  // ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                      hiveUserName != null
                          ? "Logged in with Google"
                          : "Logged in with Hive",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          //     color: Color(0xffe8e8e8),
                          fontSize: SizeConfig.safeBlockHorizontal * 3)),
                  //   "Logged in with Hive",style: TextStyle(
                  //   fontSize: 12
                  // ),),
                  SizedBox(
                    height: 20,
                  ),

                  InkWell(
                    onTap: () {
                      logout();
                      prefs.clear();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10)),
                      height: MediaQuery.of(context).size.height / 18,
                      width: MediaQuery.of(context).size.width / 1.2,
                      child: Center(
                          child: Text(
                        "Log Out",
                        style: TextStyle(color: Colors.white),
                      )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
