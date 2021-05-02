import 'package:auditory/Accounts/HiveAccount.dart';
import 'package:auditory/screens/Onboarding/Categories.dart';
import 'package:auditory/screens/Onboarding/LanguageSelection.dart';
import 'package:auditory/screens/Profiles/CategoryView.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auditory/screens/buttonPages/settings/security/AccountSettings/Presence.dart';

class Prefrences extends StatefulWidget {
  static const String id = "AccountSettings";

  @override
  _PrefrencesState createState() => _PrefrencesState();
}


class _PrefrencesState extends State<Prefrences> {

  bool _smartNotifications = true; //value to be changed with the API

  bool _onChanged(bool value) {
    setState(() {
      _smartNotifications = value;
    });
    print(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(

      appBar: AppBar(

        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.navigate_before,
            //   color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Preferences",

        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(height: 10,)
                ],
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Language",
                          style: TextStyle(
                            // color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                          context, SelectLanguage.id);
                    },
                  ),
                ],
              ),
              SizedBox(height: 35),// SizedBox(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                          context, OnboardingCategories.id);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Categories",
                          style: TextStyle(
                            // color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30,),
              //    Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: <Widget>[
              //     Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: <Widget>[
              //         Text(
              //           "Background Audio",
              //           style: TextStyle(
              //             // color: Colors.white,
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold),
              //         ),
              //
              //       ],
              //     ),
              //     Switch(
              //
              //       value: _smartNotifications,
              //       onChanged: (bool value) {
              //         _onChanged(value);
              //       },
              //     ),
              //   ],
              // ),
              // SizedBox(
              //   height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Theme",
                        style: TextStyle(
                          // color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),

                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ZAnimatedToggle(
                      values: ['Light', 'Dark'],
                      onToggleCallback: (v) async {
                        await themeProvider.toggleThemeData();
                        setState(() {});
                        (themeProvider.isLightTheme);
                      },
                    ),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
