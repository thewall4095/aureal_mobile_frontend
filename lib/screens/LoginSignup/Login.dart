import 'dart:async';
import 'dart:convert';
import 'package:auditory/screens/LoginSignup/VerificationPage.dart';
import 'package:auditory/screens/errorScreens/TemporaryError.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'SignUp.dart';
import 'package:auditory/screens/Home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'TroubleLogginIn/EnterPhone.dart';

class Login extends StatefulWidget {
  static const String id = "Login";

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<ScaffoldState> _scaffoldKeyLogin =
      new GlobalKey<ScaffoldState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  void showInSnackBar(String value) {
    _scaffoldKeyLogin.currentState.showSnackBar(new SnackBar(
        backgroundColor: Colors.red,
        content: new Text(
          value,
          textScaleFactor: 0.75,
          style: TextStyle(color: Colors.white),
        )));
  }

  Dio dio = Dio();

  String _loggedInMessage;

  bool showSpinner = false;
  bool _rememberMe = false;
  String phoneNumber;
  String username;
  String password;
  String registrationToken;

  Map<String, dynamic> _profile;
  bool _loading = false;

  var user;

  void sendOTP(String phoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['mobile'] = phoneNumber;
    map['user_id'] = prefs.getString('userId');

    print(map.toString());
    FormData formData = FormData.fromMap(map);

    var response =
        await dio.post('https://api.aureal.one/public/sendOTP', data: formData);
    print(response.data);
  }

  void login() async {
    var map = Map<String, dynamic>();
    map['username'] = username;
    map['password'] = password;

    print(registrationToken);

    map['registration_token'] = registrationToken;
    FormData formData = FormData.fromMap(map);

    try {
      var response =
          await dio.post("https://api.aureal.one/public/login", data: formData);
      print(response.data.toString());
      var userDetails = Map<String, dynamic>();
      setState(() {
        user = response.data;
        userDetails = response.data;
      });

      if (userDetails.containsKey('msg')) {
        if (userDetails['msg'] == 'Unauthorized') {
          showInSnackBar("The username or password is incorrect");
        }
        if (userDetails['msg'] == "Bad Request: User not found") {
          showInSnackBar("The user with this username doesn't exist");
        }
        if (userDetails['msg'] == "Verify your email") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('userId', userDetails['user']['id']);
          prefs.setString('userName', userDetails['user']['username']);
          await sendOTP(userDetails['user']['mobile']);
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Verification(
              phone: userDetails['user']['mobile'],
            );
          }));
        }
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        prefs.setString('token', user['token']);
        prefs.setString('userId', user['user']['id']);
        prefs.setString('userName', user['user']['username']);

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return Home();
        }));
      }
    } catch (e) {
      Navigator.pushNamed(context, TemporaryError.id);
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
      ],
    );
  }

  Widget _buildUserNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 10,
        ),
        // Container(
        //   height: 50,
        //   alignment: Alignment.centerLeft,
        //   decoration: BoxDecoration(
        //       color: Colors.white10, borderRadius: BorderRadius.circular(5)),
        //   child: TextField(
        //     onChanged: (value) async {
        //       if (value.contains(' ') == true) {
        //         showInSnackBar('The username cannot have space');
        //       }
        //       username = value;
        //     },
        //     keyboardType: TextInputType.text,
        //     style: TextStyle(color: Colors.white),
        //     decoration: InputDecoration(
        //       contentPadding: EdgeInsets.only(top: 15.0),
        //       prefixIcon: Icon(
        //         FontAwesomeIcons.userCircle,
        //         color: Colors.white,
        //       ),
        //       hintText: "Username",
        //       hintStyle: TextStyle(color: Colors.white24),
        //     ),
        //   ),
        // ),
        Container(
          decoration: BoxDecoration(
              color: kSecondaryColor, borderRadius: BorderRadius.circular(8)),
          child: TextFormField(
            onChanged: (value) async {
              if (value.contains(' ') == true) {
                showInSnackBar('The username cannot have space');
              }
              username = value.trim();
            },
            style: TextStyle(color: Color(0xffe8e8e8)),
            decoration: InputDecoration(
              disabledBorder: OutlineInputBorder(),
              labelText: 'Username',
              labelStyle: TextStyle(color: Color(0xffe8e8e8)),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 10,
        ),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: kSecondaryColor, borderRadius: BorderRadius.circular(5)),
          // child: TextField(
          //   onChanged: (value) {
          //     password = value;
          //   },
          //   obscureText: true,
          //   keyboardType: TextInputType.emailAddress,
          //   style: TextStyle(color: Colors.white),
          //   decoration: InputDecoration(
          //       contentPadding: EdgeInsets.only(top: 14.0),
          //       prefixIcon: Icon(
          //         Icons.lock,
          //         color: Colors.white,
          //       ),
          //       hintText: "Enter your password",
          //       hintStyle: TextStyle(color: Colors.white24)),
          // ),
          child: TextFormField(
            obscureText: true,
            onChanged: (value) {
              password = value;
            },
            style: TextStyle(color: Color(0xffe8e8e8)),
            decoration: InputDecoration(
              disabledBorder: OutlineInputBorder(),
              labelText: 'Password',
              labelStyle: TextStyle(color: Color(0xffe8e8e8)),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return EnterPhoneNumber();
          }));
        },
        child: Text(
          'Trouble Loggin in?',
          textScaleFactor: 0.75,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 15,
          ),
        ),
      ),
    );
//    return Container(
//      alignment: Alignment.centerLeft,
//      child: FlatButton(
//        onPressed: () {},
//        child: Text(
//          'Trouble loggin in?',
//          style: TextStyle(color: Colors.teal),
//        ),
//      ),
  }

  Widget _buildRememberMeCheckbox() {
    return Container(
        // child: Row(
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: <Widget>[
        //     Theme(
        //       data: ThemeData(unselectedWidgetColor: Colors.white),
        //       child: Checkbox(
        //         value: _rememberMe,
        //         checkColor: Colors.green,
        //         activeColor: Colors.white,
        //         onChanged: (value) {
        //           setState(() {
        //             _rememberMe = value;
        //           });
        //         },
        //       ),
        //     ),
        //     Text(
        //       "Remember Me",
        //       style: TextStyle(color: Colors.white, fontSize: 16),
        //     )
        //   ],
        // ),
        );
  }

  Widget _buildLoginButton() {
    return Container(
//                      decoration: BoxDecoration(
//                          gradient: LinearGradient(
//                              begin: Alignment.centerLeft,
//                              end: Alignment.centerRight,
//                              colors: [Color(0xFF41987E), kActiveColor])),
      padding: EdgeInsets.symmetric(vertical: 20.0),
      width: double.infinity,
      child: RaisedButton(
        elevation: 5.0,
        onPressed: () async {
          setState(() {
            showSpinner = true;
          });
//
          await login();
          showSpinner = false;

          print("Login Button Pressed");
        },
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Text(
          "LOGIN",
          textScaleFactor: 0.75,
          style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAlternateLoginButton() {
    return Container(
//                      decoration: BoxDecoration(
//                          gradient: LinearGradient(
//                              begin: Alignment.centerLeft,
//                              end: Alignment.centerRight,
//                              colors: [Color(0xFF41987E), kActiveColor])),
      padding: EdgeInsets.symmetric(vertical: 10.0),
      width: double.infinity,
      child: RaisedButton(
        color: Colors.white38,
        elevation: 5.0,
        onPressed: () async {},
        padding: EdgeInsets.all(10.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Text(
          "LOGIN",
          textScaleFactor: 0.75,
          style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Widget _buildSignInwithText() {
  //   return Column(
  //     children: <Widget>[
  //       Text(
  //         "-OR-",
  //         style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
  //       ),
  //       SizedBox(height: 20),
  //       Text(
  //         "Sign In with",
  //         style: TextStyle(color: Colors.white, fontSize: 16),
  //       )
  //     ],
  //   );
  // }

  // Widget _buildSocialBtn(Function onTap, AssetImage logo) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: EdgeInsets.all(15),
  //       height: 50.0,
  //       width: 50.0,
  //       decoration: BoxDecoration(
  //         shape: BoxShape.circle,
  //         color: Colors.white,
  //         boxShadow: [
  //           BoxShadow(
  //               color: Colors.black54, offset: Offset(0, 2), blurRadius: 6.0)
  //         ],
  //       ),
  //       child: Image(
  //         image: logo,
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildSignUpBtn() {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.pushNamed(context, SignUp.id);
  //       print("Signup pressed");
  //     },
  //     child: RichText(
  //       text: TextSpan(children: [
  //         TextSpan(
  //             text: "Don't have an account? ",
  //             style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 18.0,
  //                 fontWeight: FontWeight.w400)),
  //         TextSpan(
  //             text: "Sign Up",
  //             style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 18.0,
  //                 fontWeight: FontWeight.bold)),
  //       ]),
  //     ),
  //   );
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _messaging.getToken().then((token) {
      setState(() {
        registrationToken = token;
      });
    });

//    authService.profile.listen((state) => setState(() => _profile = state));
//
//    authService.loading.listen((state) => setState(() => _loading = state));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _scaffoldKeyLogin,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor,
              ),
            ),
            Container(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 50.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Sign In",
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 80.0,
                      ),
                      _buildUserNameTF(),
                      SizedBox(height: 30),
                      _buildPasswordTF(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          _buildForgotPasswordBtn(),
                        ],
                      ),
//                      _buildRememberMeCheckbox(),

                      _buildLoginButton(),
//                      _buildSignInwithText(),
//                      _buildSocialBtnRow(),
//                      _buildSignUpBtn(),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
