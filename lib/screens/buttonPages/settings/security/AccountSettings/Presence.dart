import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;

class Presence extends StatefulWidget {
  static const String id = "presence";

  @override
  _PresenceState createState() => _PresenceState();
}

class _PresenceState extends State<Presence> {
  postreq.Interceptor intercept = postreq.Interceptor();

  String presenceState = 'Online';
  void updatePresence() async {
    String url = 'https://api.aureal.one/private/updateUser';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['settings_Account_Presence'] = presenceState;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await intercept.postRequest(formData, url);
    } catch (e) {
      print("Unable to update presence");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.navigate_before,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Presence",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                setState(() {
                  presenceState = 'Online';
                });
                updatePresence();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Online',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    presenceState == 'Online'
                        ? Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue,
                          )
                        : Icon(
                            Icons.radio_button_checked,
                            color: kPrimaryColor,
                          ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  presenceState = "Busy";
                });
                updatePresence();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Busy",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    presenceState == 'Busy'
                        ? Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue,
                          )
                        : Icon(
                            Icons.radio_button_checked,
                            color: kPrimaryColor,
                          ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  presenceState = 'Invisible';
                });
                updatePresence();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Invisible",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    presenceState == 'Invisible'
                        ? Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue,
                          )
                        : Icon(
                            Icons.radio_button_checked,
                            color: kPrimaryColor,
                          )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
