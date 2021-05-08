import 'dart:convert';
import 'package:auditory/Services/EmailVerificationDialog.dart';
import 'package:auditory/screens/Home.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recorderpages/Editor.dart';
import 'recorderpages/Sounds.dart';
import 'recorderpages/Library.dart';
import 'recorderpages/Music.dart';
import 'recorderpages/Interludes.dart';
// import 'package:auditory/screens/recorderApp/recorder/Recorder.dart';
import 'package:http/http.dart' as http;

class RecorderDashboard extends StatefulWidget {
  static const String id = 'RecorderDashboard';

  @override
  _RecorderDashboardState createState() => _RecorderDashboardState();
}

class _RecorderDashboardState extends State<RecorderDashboard> {
  // final _auth = FirebaseAuth.instance;
  // FirebaseUser loggedInUser;

  bool isLoading;
  var episodeList = [];
  var library = [];

  int _selectedIndex = 0;

  Widget _createPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        return Record();
        break;

      case 1:
        return Library();
        break;

      case 2:
        return Interludes();
        break;

      case 3:
        return Sounds();
        break;

      case 4:
        return Music();
        break;

      // case 5:
      //   return Recorder();
      //   break;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //    getEpisodesList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: _createPage(context, _selectedIndex),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        color: Color(0x11171B27),
//        shape: CircularNotchedRectangle(),
        child: Container(
          height: 55,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                MaterialButton(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.graphic_eq,
                        color:
                            _selectedIndex == 0 ? kActiveColor : Colors.white,
                      ),
                      Text(
                        "Editor",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3,
                            color: _selectedIndex == 0
                                ? kActiveColor
                                : Colors.white),
                      )
                    ],
                  ),
                  minWidth: 40,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                MaterialButton(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.folder,
                        color:
                            _selectedIndex == 1 ? kActiveColor : Colors.white,
                      ),
                      Text(
                        "Library",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3,
                            color: _selectedIndex == 1
                                ? kActiveColor
                                : Colors.white),
                      )
                    ],
                  ),
                  minWidth: 40,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                MaterialButton(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.arrow_forward,
                        color:
                            _selectedIndex == 2 ? kActiveColor : Colors.white,
                      ),
                      Text(
                        "Interludes",
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3,
                            color: _selectedIndex == 2
                                ? kActiveColor
                                : Colors.white),
                      )
                    ],
                  ),
                  minWidth: 40,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FloatingActionButton(
                      heroTag: 'record',
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        // episodeObject.stop();
                        // if (prefs.getString('userEmail') != null) {
                        //   Navigator.pushNamed(context, RecorderDashboard.id);
                        //  } else {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                child: EmailVerificationDialog(
                                  username: prefs.getString('username'),
                                ),
                              );
                            });
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//_createPage(context, _selectedIndex),
