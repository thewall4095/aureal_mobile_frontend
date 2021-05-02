import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';

class EmailNotifications extends StatefulWidget {
  static const String id = "EmailNotification";

  @override
  _EmailNotificationsState createState() => _EmailNotificationsState();
}

class _EmailNotificationsState extends State<EmailNotifications> {
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
          icon: Icon(
            Icons.navigate_before,

          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "On Email",

        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    "PUSH NOTIFICATIONS",

                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            "Live Streams",
                            style: TextStyle(

                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            color: Colors.green,
                            child: Text(
                              'Smart Notifications',

                            ),
                          )
                        ],
                      ),
                      Text(
                        "When a podcaster I follow goes live.",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Votes",
                        style: TextStyle(

                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "When someone votes on my episode",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Comments",
                        style: TextStyle(

                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "When somebody comments on my episode",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Subscription",
                        style: TextStyle(

                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "When someone subscribes my podcast.",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            "Followers",
                            style: TextStyle(

                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "When someone follows me or my podcasts.",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            "Messages",
                            style: TextStyle(

                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "When sends messages or whispers.",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "Send me push notifications",
                        style: TextStyle(

                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        "Post Notification",
                        style: TextStyle(

                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            "Distribution Notification",
                            style: TextStyle(

                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "When my episodes are cross distributed",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            "Developer News",
                            style: TextStyle(

                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "When a new feature is added to the Aureal",

                      )
                    ],
                  ),
                  Switch(

                    value: _smartNotifications,
                    onChanged: (bool value) {
                      _onChanged(value);
                    },
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
