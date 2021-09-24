import 'package:auditory/screens/LoginSignup/TroubleLogginIn/ChangePassword.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../Login.dart';

class EnterOTP extends StatefulWidget {
  String username;
  String userId;
  EnterOTP({@required this.userId, @required this.username});

  @override
  _EnterOTPState createState() => _EnterOTPState();
}

class _EnterOTPState extends State<EnterOTP> {
  final GlobalKey<ScaffoldState> _OTPverificationKey =
      new GlobalKey<ScaffoldState>();

  void showInSnackBar(String value) {
    _OTPverificationKey.currentState.showSnackBar(new SnackBar(
        content: new Text(
      value,
      textScaleFactor: 0.75,
    )));
  }

  Dio dio = Dio();

  Widget _buildUserNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
          child: TextField(
            onChanged: (value) {
              setState(() {
                enteredOTP = value;
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
              hintText: "123456",
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }

  void verifyOTP() async {
    String url = 'https://api.aureal.one/public/verifyOTP';
    var map = Map<String, dynamic>();

    map['user_id'] = widget.userId;
    map['otp'] = enteredOTP;

    print(map.toString());

    FormData formData = FormData.fromMap(map);

    var response = await dio.post(url, data: formData);
    print(response.data);
    if (response.data['msg'] != null) {
      showInSnackBar('${response.data['msg']}');
    } else {
      print('Verification success');
      Navigator.push(context, CupertinoPageRoute(builder: (context) {
        return ChangePassword(
          userId: widget.userId,
        );
      }));
    }
  }

  String enteredOTP;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _OTPverificationKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Enter OTP",
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
            Row(
              children: [
                Text(
                  'Username,\n ${widget.username}',
                  textScaleFactor: 0.75,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 5),
                ),
              ],
            ),
            SizedBox(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 20,
                    //  width: double.infinity,
                    //   decoration: BoxDecoration(
                    // borderRadius: BorderRadius.circular(50),
                    //   gradient: LinearGradient(
                    // colors: [Color(0xff6048F6), Color(0xff51C9F9)]),

//),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, Login.id);
                      },
                      child: Text(
                        "LOGIN",
                        textScaleFactor: 0.75,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                      ),
                    ),
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
                    "Please enter the OTP you received to change your password",
                    textScaleFactor: 0.75,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.safeBlockHorizontal * 3),
                  ),
                ],
              ),
            ),
            _buildUserNameTF(),
            SizedBox(
              height: 30,
            ),
            InkWell(
              onTap: () async {
                print('forward button pressed for password change');
                if (enteredOTP.length == 6) {
                  verifyOTP();
                }
              },
              borderRadius: BorderRadius.circular(30),
              splashColor: Color(0xff51C9F9),
              child: Container(
                height: 50,
                width: 50,
                decoration: enteredOTP.toString().length != 6
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
