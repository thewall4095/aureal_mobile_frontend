import 'package:auditory/DatabaseFunctions/Database.dart';
import 'package:auditory/screens/Onboarding/LanguageSelection.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Login.dart';
import 'package:auditory/screens/Home.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'VerificationPage.dart';

enum LoginOption {
  phone,
  email,
}

enum ActiveState {
  email,
  phone,
  username,
  password,
}

class SignUp extends StatefulWidget {
  static const String id = "Signup";

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String termsUrl = 'https://aureal.one/terms-of-use/';
  String privacyUrl = 'https://aureal.one/privacy-policy';

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        value,
        textScaleFactor: 0.75,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }

  Dio dio = Dio();
  var user;

  final format = DateFormat("yyyy-MM-dd");

  String _loggedInMessage;

  LoginOption loginSelector = LoginOption.email;
  ActiveState activeTF;

  bool showSpinner = false;
  String username;
  String email;
  String password;
  String phoneNumber;
  DateTime dateOfBirth;
  String fullname;
  String registrationToken;
  bool alreadyExists;

  void sendOTP() async {
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

  void register() async {
    setState(() {
      showSpinner = true;
    });
    var map = Map<String, dynamic>();
    map['mobile'] = phoneNumber;
    map['password'] = password;
    map['password2'] = password;
    map['username'] = username;
    print(dateOfBirth.toString().split(' ')[0]);
    map['date_of_birth'] = dateOfBirth.toString().split(' ')[0];
    map['fullname'] = fullname;
    map['registration_token'] = registrationToken;
    FormData formData = FormData.fromMap(map);

    print(map.toString());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var response = await dio.post("https://api.aureal.one/public/register",
        data: formData);

    var data = Map<String, dynamic>();
    setState(() {
      data = response.data;
    });

    print(response.toString());

    if (response.statusCode == 200) {
      if (data.containsKey('msg')) {
        if (data['msg'] == "User with this username already exists.") {
          showInSnackBar("User with this username already exists.");
        }
        if (data['msg'] == "User with this phone number already exists.") {
          showInSnackBar('User with this email already exists.');
          Timer(Duration(seconds: 3), () {
            Navigator.pushNamed(context, Login.id);
          });
        }
      } else {
        prefs.setString('token', response.data['token']);
        prefs.setString('userId', response.data['user']['id']);
        prefs.setString('userName', response.data['user']['username']);
        await sendOTP();
        Navigator.push(context, CupertinoPageRoute(builder: (context) {
          return Verification();
        }));
      }
    } else {
      print(response.statusCode.toString());
    }

    print(prefs.getString('token'));
    print(prefs.getString('userId'));
    print(prefs.getString('userName'));

//    setState(() {
//      user = response.data;
//    });
//    print(user);

    setState(() {
      showSpinner = false;
    });
  }

  Widget _buildUserNameTF() {
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
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
          // child: TextField(
          //   onChanged: (value) async {
          //     if (value.contains(' ') == true) {
          //       showInSnackBar('The username cannot have space');
          //     }
          //     username = value;
          //   },
          //   keyboardType: TextInputType.text,
          //   style: TextStyle(color: Colors.white),
          //   decoration: InputDecoration(
          //     contentPadding: EdgeInsets.only(top: 15.0),
          //     prefixIcon: Icon(
          //       FontAwesomeIcons.userCircle,
          //       color: Colors.white,
          //     ),
          //     hintText: "Username",
          //     hintStyle: TextStyle(color: Colors.white24),
          //   ),
          // ),
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

  Widget _buildFullNameTF() {
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
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
          // child: TextField(
          //   onChanged: (value) async {
          //     fullname = value;
          //   },
          //   keyboardType: TextInputType.text,
          //   style: TextStyle(color: Colors.white),
          //   decoration: InputDecoration(
          //       contentPadding: EdgeInsets.only(top: 15.0),
          //       prefixIcon: Icon(
          //         Icons.account_circle,
          //         color: Colors.white,
          //       ),
          //       hintText: "John Snow",
          //       hintStyle: TextStyle(color: Colors.white24)),
          // ),
          child: TextFormField(
            onChanged: (value) async {
              fullname = value;
            },
            style: TextStyle(color: Color(0xffe8e8e8)),
            decoration: InputDecoration(
              disabledBorder: OutlineInputBorder(),
              labelText: 'Full Name',
              labelStyle: TextStyle(color: Color(0xffe8e8e8)),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              "Date of Birth",
              textScaleFactor: 0.75,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
//          child: TextField(
//            onChanged: (value) {
////                dateOfBirth = value;
//            },
//            keyboardType: TextInputType.datetime,
//            style: TextStyle(color: Colors.white),
//            decoration: InputDecoration(
//                contentPadding: EdgeInsets.only(top: 14.0),
//                prefixIcon: Icon(
//                  Icons.date_range,
//                  color: Colors.white,`
//                ),
//                hintText: "dd/mm/yyyy",
//                hintStyle: TextStyle(color: Colors.white24)),
//          ),
          child: DateTimeField(
            style: TextStyle(color: Colors.white),
            format: format,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.only(top: 15.0),
                prefixIcon: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                )),
            onShowPicker: (context, currentValue) {
              return showDatePicker(
                  context: context,
                  firstDate: DateTime(1960),
                  initialDate:
                      currentValue ?? DateTime.utc(DateTime.now().year - 13),
                  lastDate: DateTime(DateTime.now().year - 12));
            },
            onChanged: (value) {
              setState(() {
                dateOfBirth = value;
                print(dateOfBirth);
              });
            },
          ),
        ),
      ],
    );
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
              color: Colors.white10, borderRadius: BorderRadius.circular(5)),
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
          //       hintText: "Password",
          //       hintStyle: TextStyle(color: Colors.white24)),
          // ),
          child: TextFormField(
            obscureText: true,
            onChanged: (value) async {
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
    return Container(
      alignment: Alignment.centerRight,
      child: FlatButton(
        onPressed: () {},
        child: Text(
          "Forgot Password?",
          textScaleFactor: 0.75,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
//
      padding: EdgeInsets.symmetric(vertical: 10.0),
      width: double.infinity,
      child: RaisedButton(
        color: kSecondaryColor,
        elevation: 5.0,
        onPressed: () async {
          print("Sign Up Button Pressed");
          if (username.contains(' ') == true) {
            showInSnackBar('Remove the username');
          } else {
            register();
          }
        },
        padding: EdgeInsets.all(10.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "SIGN UP",
            textScaleFactor: 0.75,
            style: TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: Color(0xffe8e8e8)),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpwithText() {
    return Column(
      children: <Widget>[
        Text(
          "-OR-",
          textScaleFactor: 0.75,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        ),
        SizedBox(height: 20),
        Text(
          "Login with",
          textScaleFactor: 0.75,
          style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.safeBlockHorizontal * 3.5),
        )
      ],
    );
  }

  Widget _buildSocialBtn(Function onTap, AssetImage logo) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        height: 50.0,
        width: 50.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black54, offset: Offset(0, 2), blurRadius: 6.0)
          ],
        ),
        child: Image(
          image: logo,
        ),
      ),
    );
  }

  Widget _buildLoginBtn() {
    return GestureDetector(
      onTap: () {
        print("Login pressed");
        Navigator.pushNamed(context, Login.id);
      },
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: "Already have an account? ",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.blockSizeHorizontal * 3.5,
                  fontWeight: FontWeight.w400)),
          TextSpan(
              text: "Login",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.blockSizeHorizontal * 3.5,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _messaging.getToken().then((token) {
      setState(() {
        registrationToken = token;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _scaffoldKey,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Sign Up",
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.blockSizeHorizontal * 4,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 60,
                      ),
//                    _buildNameTF(),
                      SizedBox(
                        height: 15.0,
                      ),
//
                      _buildPhoneTF(),
                      SizedBox(height: 20),
                      _buildUserNameTF(),
                      SizedBox(
                        height: 20,
                      ),
                      _buildFullNameTF(),
                      SizedBox(
                        height: 20,
                      ),
                      _buildPasswordTF(),

                      SizedBox(height: 20),
                      _buildDateOfBirth(),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "By clicking Sign Up, you are indicating that you have read and acknowledge",
                        textScaleFactor: 0.75,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.safeBlockHorizontal * 3),
                      ),
                      GestureDetector(
                        onTap: () {
                          _launchInBrowser(privacyUrl);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Terms of Service',
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                color: kActiveColor,
                                fontSize: SizeConfig.safeBlockHorizontal * 3),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _launchInBrowser(termsUrl);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Privacy Notice',
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                color: kActiveColor,
                                fontSize: SizeConfig.safeBlockHorizontal * 3),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      _buildSignUpButton(),
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
