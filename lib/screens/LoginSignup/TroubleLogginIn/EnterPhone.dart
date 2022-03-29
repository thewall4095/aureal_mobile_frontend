import 'package:auditory/screens/LoginSignup/TroubleLogginIn/EnterOTPpassword.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:dio/dio.dart';

class EnterPhoneNumber extends StatefulWidget {
  @override
  _EnterPhoneNumberState createState() => _EnterPhoneNumberState();
}

class _EnterPhoneNumberState extends State<EnterPhoneNumber> {
  final GlobalKey<ScaffoldState> _resendOTPKey = new GlobalKey<ScaffoldState>();

  Dio dio = Dio();

  String phoneNumber;

  void showInSnackBar(String value) {
    _resendOTPKey.currentState.showSnackBar(new SnackBar(
        content: new Text(
      value,
      textScaleFactor: 0.75,
    )));
  }

  void sendResetOTP() async {
    String url = 'https://api.aureal.one/public/sendResetOTP';
    var map = Map<String, dynamic>();
    map['mobile'] = phoneNumber;

    FormData formData = FormData.fromMap(map);

    var response = await dio.post(url, data: formData);
    if (response.statusCode == 200) {
      print(response.toString());
      print(response.data['data']['user_id']);
      print(response.data['data']['username']);
      Navigator.push(context, CupertinoPageRoute(builder: (context) {
        return EnterOTP(
          userId: response.data['data']['user_id'],
          username: response.data['data']['username'],
        );
      }));
    } else {
      showInSnackBar(response.data['msg']);
    }
  }

  Widget _buildPhoneTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              "Phone Number",
              textScaleFactor: 0.75,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
          child: IntlPhoneField(
            dropDownArrowColor: Colors.white,
            showDropdownIcon: true,
            countryCodeTextColor: Colors.white,
            style: TextStyle(
                color: Colors.white,
                fontSize: SizeConfig.blockSizeHorizontal * 3),
            decoration: InputDecoration(
              prefixStyle: TextStyle(color: Colors.white),
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderSide: BorderSide(),
              ),
            ),
            onChanged: (phone) {
              print(phone.completeNumber);
              setState(() {
                phoneNumber = phone.completeNumber;
              });
            },
          ),
        ),
//        Padding(
//          padding: const EdgeInsets.symmetric(vertical: 15),
//          child: GestureDetector(
//            onTap: () {
//              setState(() {
//                loginSelector = LoginOption.phone;
//                print("Phone is selected");
//              });
//            },
//            child: Row(
//              children: <Widget>[
//                Icon(
//                  Icons.phone,
//                  color: Colors.teal,
//                ),
//                Padding(
//                  padding: const EdgeInsets.symmetric(horizontal: 10),
//                  child: Text(
//                    "Use phone instead",
//                    style: TextStyle(color: Colors.teal, fontSize: 16),
//                  ),
//                )
//              ],
//            ),
//          ),
//        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _resendOTPKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Enter phone number",
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
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Enter your phone number to Change your password",
                    textScaleFactor: 0.75,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.safeBlockHorizontal * 3),
                  ),
                ],
              ),
            ),
            _buildPhoneTF(),
            SizedBox(
              height: 30,
            ),
            InkWell(
              onTap: () async {
                print('forward button pressed for password change');

                sendResetOTP();
              },
              borderRadius: BorderRadius.circular(30),
              splashColor: Color(0xff51C9F9),
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
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
