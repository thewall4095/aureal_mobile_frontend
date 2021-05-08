import 'dart:async';

import 'package:auditory/screens/LoginSignup/Login.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChangePassword extends StatefulWidget {
  String userId;

  ChangePassword({@required this.userId});

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final GlobalKey<ScaffoldState> _changePasswordKey =
      new GlobalKey<ScaffoldState>();

  Dio dio = Dio();

  void showInSnackBar(String value) {
    _changePasswordKey.currentState.showSnackBar(new SnackBar(
        content: new Text(
      value,
      textScaleFactor: 0.75,
    )));
  }

  String password1;
  String password2;

  void changePassword() async {
    String url = 'https://api.aureal.one/public/setPassword';

    var map = Map<String, dynamic>();
    map['user_id'] = widget.userId;
    map['new_password'] = password1;
    map['new_password2'] = password2;

    FormData formData = FormData.fromMap(map);
    if (password1 != password2) {
      showInSnackBar("The password doesn't match");
    } else {
      var response = await dio.post(url, data: formData);
      print(response.statusCode);
      if (response.data['msg'] == null) {
        showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Container(
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          'Your password has been changed',
                          textScaleFactor: 0.75,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                Login.id, (Route<dynamic> route) => false);
                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  Color(0xff6048F6),
                                  Color(0xff51C9F9)
                                ])),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            });
      }
    }
  }

  Widget _buildPassword1TF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
          child: TextField(
            obscureText: true,
            onChanged: (value) {
              print('password1: $value');
              setState(() {
                password1 = value;
              });
            },
            keyboardType: TextInputType.text,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(top: 15.0),
              prefixIcon: Icon(
                FontAwesomeIcons.lock,
                color: Colors.white,
              ),
              hintText: "Enter new password",
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassword2TF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
          child: TextField(
            obscureText: true,
            onChanged: (value) {
              print('password2: $value');
              setState(() {
                password2 = value;
              });
            },
            keyboardType: TextInputType.text,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(top: 15.0),
              prefixIcon: Icon(
                FontAwesomeIcons.lock,
                color: Colors.white,
              ),
              hintText: "Confirm new password",
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _changePasswordKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Set new password',
          textScaleFactor: 0.75,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3.5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Change your password",
                    textScaleFactor: 0.75,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.safeBlockHorizontal * 3),
                  ),
                ],
              ),
            ),
            _buildPassword1TF(),
            SizedBox(
              height: 30,
            ),
            _buildPassword2TF(),
            SizedBox(
              height: 30,
            ),
            InkWell(
              onTap: () async {
                if (password1.toString().length < 8 || password1 == null) {
                  showInSnackBar(
                      'The password cannot be less than 8 characters');
                } else {
                  changePassword();
                }

                print('forward button pressed for password change');
              },
              borderRadius: BorderRadius.circular(30),
              splashColor: Color(0xff51C9F9),
              child: Container(
                height: 50,
                width: 50,
                decoration: password1 == null || password1.length < 8
                    ? BoxDecoration(color: Colors.grey, shape: BoxShape.circle)
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [Color(0xff6048F6), Color(0xff51C9F9)]),
                      ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
