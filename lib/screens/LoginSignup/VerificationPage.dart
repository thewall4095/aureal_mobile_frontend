import 'dart:convert';

import 'package:auditory/screens/Onboarding/LanguageSelection.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Verification extends StatefulWidget {
  String phone;

  Verification({this.phone});

  @override
  _VerificationState createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  final GlobalKey<ScaffoldState> _verificationKeyLogin =
      new GlobalKey<ScaffoldState>();

  Dio dio = Dio();

  void sendOTP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['mobile'] = widget.phone;
    map['user_id'] = prefs.getString('userId');

    print(map.toString());
    FormData formData = FormData.fromMap(map);

    var response =
        await dio.post('https://api.aureal.one/public/sendOTP', data: formData);
    print(response.data);
  }

  void showInSnackBar(String value) {
    _verificationKeyLogin.currentState.showSnackBar(new SnackBar(
        content: new Text(
      value,
      textScaleFactor: 0.75,
    )));
  }

  void verifyOTP() async {
    String url = 'https://api.aureal.one/public/verifyOTP';
    var map = Map<String, dynamic>();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    map['user_id'] = prefs.getString('userId');
    map['otp'] = oTP;

    print(map.toString());

    FormData formData = FormData.fromMap(map);

    var response = await dio.post(url, data: formData);

    print(response.data);
    if (response.statusCode == 200) {
      if (response.data['user'] == null) {
        showInSnackBar("Your OTP doesn't match, Please enter a valid OTP");
      } else {
        prefs.setString('token', response.data['token']);
        Navigator.pushNamed(context, SelectLanguage.id);
      }
    }
    print(prefs.getString('token'));
  }

  Widget _buildUserNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(5)),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  oTP = value;
                });
              },
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(top: 15.0),
                prefixIcon: Icon(
                  FontAwesomeIcons.lock,
                  color: Colors.white,
                ),
                hintText: "123456",
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String oTP;

  @override
  Widget build(BuildContext context) {
    print(widget.phone);
    return Scaffold(
      key: _verificationKeyLogin,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Verification",
          textScaleFactor: 0.75,
          style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.blockSizeHorizontal * 4),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  "Please enter the OTP received on your phone",
                  textScaleFactor: 0.75,
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: SizeConfig.blockSizeHorizontal * 3.5),
                ),
              )
            ],
          ),
          SizedBox(
            height: 30,
          ),
          _buildUserNameTF(),

          SizedBox(
            height: 50,
          ),
          Text(
            "Didn't receive the code?",
            textScaleFactor: 0.75,
            style: TextStyle(
                color: Colors.grey,
                fontSize: SizeConfig.blockSizeHorizontal * 3.5),
          ),
          SizedBox(
            height: 10,
          ),
          GestureDetector(
            onTap: () {
              sendOTP();
            },
            child: Text(
              "RESEND",
              textScaleFactor: 0.75,
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: SizeConfig.blockSizeHorizontal * 3.5),
            ),
          ),
          SizedBox(
            height: 50,
          ),
          InkWell(
            onTap: () async {
              print('forward button pressed for password change');
              if (oTP.toString().length == 6) {
                verifyOTP();
              }
            },
            borderRadius: BorderRadius.circular(30),
            splashColor: Color(0xff51C9F9),
            child: Container(
              height: 50,
              width: 50,
              decoration: oTP.toString().length != 6
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
//          oTP.toString().length != 6
//              ? Container(
//                  height: 50,
//                  width: MediaQuery.of(context).size.width / 1.25,
//                  decoration: BoxDecoration(
//                      color: Colors.grey,
//                      borderRadius: BorderRadius.circular(8)),
//                  child: Center(
//                    child: Text(
//                      "VERIFY",
//                      style: TextStyle(
//                          color: Colors.white,
//                          fontSize: SizeConfig.blockSizeHorizontal * 3.5,
//                          fontWeight: FontWeight.w600),
//                    ),
//                  ),
//                )
//              : GestureDetector(
//                  onTap: () {
//                    verifyOTP();
//                  },
//                  child: Container(
//                    height: 50,
//                    width: MediaQuery.of(context).size.width / 1.25,
//                    decoration: BoxDecoration(
//                        color: Colors.blue,
//                        borderRadius: BorderRadius.circular(8)),
//                    child: Center(
//                      child: Text(
//                        "VERIFY",
//                        style: TextStyle(
//                            color: Colors.white,
//                            fontSize: SizeConfig.blockSizeHorizontal * 3.5,
//                            fontWeight: FontWeight.w600),
//                      ),
//                    ),
//                  ),
//                ),
        ],
      ),
    );
  }
}
