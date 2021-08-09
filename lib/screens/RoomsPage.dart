import 'dart:convert';

import 'package:auditory/Services/LaunchUrl.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Home.dart';

class RoomsPage extends StatefulWidget {
  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  void getUserRooms() async {
    print("Rooms getting called");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getUserRooms?userid=${prefs.getString('userId')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          rooms = jsonDecode(response.body)['data'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  var rooms;

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    getUserRooms();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    Launcher launcher = Launcher();

    Future<void> _pullRefresh() async {
      print('proceedd');
    }

    Future<bool> _onBackPressed() async {
      Navigator.pushNamedAndRemoveUntil(
          context, Home.id, ModalRoute.withName("/"));
      return false; // return true if the route to be popped
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return WillPopScope(
            onWillPop: _onBackPressed,
            child: Scaffold(
              body: Container(
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 3 / 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20),
                    itemCount: rooms.length,
                    itemBuilder: (context, int index) {
                      return Container(
                        color: Colors.blue,
                      );
                    }),
              ),
            ),
          );
        },
      ),
    );
  }
}
