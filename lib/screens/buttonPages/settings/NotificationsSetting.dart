import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'MobileNotifications/MobileNotifications.dart';
import 'EmailNotifications/EmailNotifications.dart';

class Notifications extends StatefulWidget {
  static const String id = "Notifications";

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  bool _smartNotifications = true; //value to be changed with the API

  bool _onChanged(bool value) {
    setState(() {
      _smartNotifications = value;
    });
    print(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(

        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.navigate_before,

          ),
        ),
        title: Text(
          "Notifications",

        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "MANAGE HOW YOU RECEIVE  NOTIFICATIONS",

              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Enable smart notifications",

                      ),
                      Text(
                        "Receive notifications depending on where you're active",
                        style: TextStyle(

                            fontWeight: FontWeight.w300,
                            fontSize: 13),
                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                "Learn more about smart notifications",

              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, MobileNotifications.id);
                },
                child: Text(
                  "On Mobile",
                  style: TextStyle( fontSize: 17),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, EmailNotifications.id);
                },
                child: Text(
                  "On Email",
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                "Per Channel",
                style: TextStyle( fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
