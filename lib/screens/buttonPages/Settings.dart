import 'package:auditory/screens/buttonPages/settings/Prefrences.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/screens/errorScreens/PopError.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auditory/screens/buttonPages/settings/AccountSettings.dart';
import 'package:auditory/screens/buttonPages/settings/NotificationsSetting.dart';
import 'package:auditory/screens/LoginSignup/WelcomeScreen.dart';
import 'package:provider/provider.dart';
import 'settings/security/Security.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void setData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInUser = prefs.getString('userId');
  }



  @override
  void initState() {
    // TODO: implement initState
//    getCurrentUser();
    setData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);
    SizeConfig().init(context);
    return Scaffold(
      //  backgroundColor: kPrimaryColor,
        appBar: AppBar(
          elevation: 0,
          //     backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.navigate_before,),
            onPressed: () {
              print("Pop button pressed");
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Settings",
            textScaleFactor: mediaQueryData
                .textScaleFactor
                .clamp(0.5, 0.8)
                .toDouble(),
            style: TextStyle(

                fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: GestureDetector(
                              //     onTap: () {
                              //       print("Account Settings");
                              //       Navigator.pushNamed(
                              //           context, AccountSettings.id);
                              //     },
                              //     child: Container(
                              //       width: double.infinity,
                              //       child: Column(
                              //         crossAxisAlignment:
                              //             CrossAxisAlignment.start,
                              //         children: <Widget>[
                              //           Text(
                              //             "Accounts",
                              //             textScaleFactor: 0.75,
                              //             style: TextStyle(
                              //                // color: Colors.white,
                              //                 fontWeight: FontWeight.bold,
                              //                 fontSize: SizeConfig
                              //                         .safeBlockHorizontal *
                              //                     4),
                              //           ),
                              //           Text(
                              //             "Profile, Subscriptions, Presence",
                              //             textScaleFactor: 0.75,
                              //             style: TextStyle(
                              //              //
                              //               //  color: Colors.white70,
                              //                 fontWeight: FontWeight.w300,
                              //                 fontSize: SizeConfig
                              //                         .safeBlockHorizontal *
                              //                     3.4),
                              //           )
                              //         ],
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: GestureDetector( onTap: () {
                                  print("Account Settings");
                                  Navigator.pushNamed(
                                      context, Prefrences.id);
                                },
                                  child: Container(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          "Preferences",
                                          textScaleFactor: mediaQueryData
                                              .textScaleFactor
                                              .clamp(0.5, 1.5)
                                              .toDouble(),
                                          style: TextStyle(
                                            //  color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  4),
                                        ),
                                        Text(
                                          "Dark Mode, Background Audio, Language, Categories",
                                          textScaleFactor: mediaQueryData
                                              .textScaleFactor
                                              .clamp(0.5, 0.8)
                                              .toDouble(),
                                          style: TextStyle(
                                            //       color: Colors.white70,
                                              fontWeight: FontWeight.w300,
                                              fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  3.4),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: GestureDetector(
                              //     onTap: () {
                              //
                              //       Navigator.pushNamed(
                              //           context, Notifications.id);
                              //     },
                              //     child: Container(
                              //       child: Column(
                              //         crossAxisAlignment:
                              //             CrossAxisAlignment.start,
                              //         children: <Widget>[
                              //           Text(
                              //             "Notifications",
                              //             textScaleFactor: 0.75,
                              //             style: TextStyle(
                              //     //            color: Colors.white,
                              //                 fontWeight: FontWeight.bold,
                              //                 fontSize: SizeConfig
                              //                         .safeBlockHorizontal *
                              //                     4),
                              //           ),
                              //         ],
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: Container(
                              //     child: Column(
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       children: <Widget>[
                              //         Text(
                              //           "Dashboard",
                              //           textScaleFactor: 0.75,
                              //           style: TextStyle(
                              //       //        color: Colors.white,
                              //               fontWeight: FontWeight.bold,
                              //               fontSize:
                              //                   SizeConfig.safeBlockHorizontal *
                              //                       4),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: Container(
                              //     child: GestureDetector(
                              //       onTap: () {
                              //         Navigator.pushNamed(context, Security.id);
                              //       },
                              //       child: Column(
                              //         crossAxisAlignment:
                              //             CrossAxisAlignment.start,
                              //         children: <Widget>[
                              //           Text(
                              //             "Security + Privacy",
                              //             textScaleFactor: 0.75,
                              //             style: TextStyle(
                              //             //    color: Colors.white,
                              //                 fontWeight: FontWeight.bold,
                              //                 fontSize: SizeConfig
                              //                         .safeBlockHorizontal *
                              //                     4),
                              //           ),
                              //           Text(
                              //             "Contact, Password",
                              //             textScaleFactor: 0.75,
                              //             style: TextStyle(
                              //          //       color: Colors.white70,
                              //                 fontWeight: FontWeight.w300,
                              //                 fontSize: SizeConfig
                              //                         .safeBlockHorizontal *
                              //                     3.4),
                              //           )
                              //         ],
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: Container(
                              //     child: Column(
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       children: <Widget>[
                              //         Text(
                              //           "Recommendations",
                              //           textScaleFactor: 0.75,
                              //           style: TextStyle(
                              //        //       color: Colors.white,
                              //               fontWeight: FontWeight.bold,
                              //               fontSize:
                              //                   SizeConfig.safeBlockHorizontal *
                              //                       4),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: Container(
                              //     child: Column(
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       children: <Widget>[
                              //         Text(
                              //           "System",
                              //           textScaleFactor: 0.75,
                              //           style: TextStyle(
                              //    //           color: Colors.white,
                              //               fontWeight: FontWeight.bold,
                              //               fontSize:
                              //                   SizeConfig.safeBlockHorizontal *
                              //                       4),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: Container(
                              //     child: Column(
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       children: <Widget>[
                              //         Text(
                              //           "Community Guidelines",
                              //           textScaleFactor: 0.75,
                              //           style: TextStyle(
                              //           //    color: Colors.white,
                              //               fontWeight: FontWeight.bold,
                              //               fontSize:
                              //                   SizeConfig.safeBlockHorizontal *
                              //                       4),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.only(bottom: 30),
                              //   child: Container(
                              //     child: Column(
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       children: <Widget>[
                              //         Text(
                              //           "Terms of Service",
                              //           textScaleFactor: 0.75,
                              //           style: TextStyle(
                              //         //      color: Colors.white,
                              //               fontWeight: FontWeight.bold,
                              //               fontSize:
                              //                   SizeConfig.safeBlockHorizontal *
                              //                       4),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Padding(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              //   child: Center(
              //     child: Container(
              //       decoration: BoxDecoration(
              //           border: Border.all(
              //               color: Colors.blue, width: 2.0)),
              //       width: double.infinity,
              //       child: RaisedButton(
              //         color: Colors.transparent,
              //         elevation: 0,
              //         onPressed: () {
              //           logout();
              //         },
              //         child: Text(
              //           "Log out",
              //           textScaleFactor: 0.75,
              //           style: TextStyle(
              //            //   color: Colors.white,
              //               fontSize: SizeConfig.safeBlockHorizontal * 4),
              //         ),
              //       ),
              //     ),
              //   ),
              // )
            ],
          ),
        ));
  }
}
