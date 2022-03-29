import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/screens/buttonPages/Profile.dart';
import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailVerificationDialog extends StatefulWidget {
  static const String id = 'EmailVerification';
  var username;

  ThemeProvider themeProvider;
  EmailVerificationDialog({@required this.username});

  @override
  _EmailVerificationDialogState createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  postreq.Interceptor intercept = postreq.Interceptor();
  final GlobalKey<ScaffoldState> _RSSImportKey = new GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  Dio dio = Dio();

  bool isLoading = false;

  String podcastName;
  String podcastImage;
  String authorName;

  String kRSSMail = '';
String error ;
  void sendOTP() async {
    setState(() {
      isLoading = true;
    });

    String url = "https://api.aureal.one/private/sendOTPMailVerify";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['url'] = _RSSController.text;

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.runtimeType);
    print(jsonDecode(response.toString()));
    setState(() {
      kRSSMail = jsonDecode(response.toString())['email'];
    });
    if (jsonDecode(response.toString())['msg'] != null) {
      showInSnackBar('${jsonDecode(response.toString())['msg']}');
    } else {
      setState(() {
        _selectedIndex = 2;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void showInSnackBar(String value) {
    _RSSImportKey.currentState.showSnackBar(new SnackBar(
        backgroundColor: Colors.blue,
        content: new Text(
          value,
          style: TextStyle(color: Colors.white),
        )));
  }

  void verifyOTP() async {
    setState(() {
      isLoading = true;
    });
    String url = 'https://api.aureal.one/private/verifyOtpAndCreateFromRss';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();

    map['user_id'] = prefs.getString('userId');
    map['otp'] = _OTPController.text;
    map['url'] = _RSSController.text;

    print(map.toString());

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.data);

    if (response.data['msg'] != null) {
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        podcastName = response.data['podcast']['name'];
        podcastImage = response.data['podcast']['image'];
      });
      setState(() {
        isPodcastFetched = true;
      });
    }
  }

  String newRSSFeed;

  Widget _createPage(BuildContext context, int index) {
    switch (index) {
      case 1:
        return _RSSTextField();
        break;

      case 2:
        return _VerifyOTP();
        break;

      case 0:
        return _importPodcastIntro();
    }
  }
  TextEditingController _RSSController = TextEditingController();
  TextEditingController _OTPController = TextEditingController();

  Widget _RSSTextField() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Expanded(
      child: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
              // crossAxisAlignment: CrossAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(colors: [
                            Color(0xff52BFF9),
                            Color(0xff6048F6)
                          ]).createShader(bounds);
                        },
                        child: Row(
                          children: [
                            Text(
                              "Enter your RSS feed  ",
                              style: TextStyle(
                                  //color: Colors.white,
                                  fontSize: SizeConfig.safeBlockHorizontal * 5),
                            ),
                            Icon(
                              Icons.add_link,
                              //  color: Colors.white,
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "You get this link from your hosting provider",
                        //  style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      color: themeProvider.isLightTheme == true
                          ? kSecondaryColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30)),
                  child: TextFormField(
                    keyboardType: TextInputType.url,
                    style: TextStyle(
                        color: themeProvider.isLightTheme != true
                            ? Colors.black
                            : Colors.white),
                    decoration: InputDecoration(
                        hintText: 'Enter your RSS feed link here',
                        hintStyle: TextStyle(
                          color: themeProvider.isLightTheme != true
                              ? kSecondaryColor
                              : Colors.white.withOpacity(0.5),
                        ),

                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15)),
                    controller: _RSSController,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: InkWell(
                    onTap: () async {
                      if (_RSSController.text != null ||
                          _RSSController.text != '') {
                      await sendOTP();}
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: _RSSController.text == ''
                              ? LinearGradient(
                                  colors: [kSecondaryColor, kSecondaryColor])
                              : LinearGradient(colors: [
                                  Color(0xff52BFF9),
                                  Color(0xff6048F6)
                                ])),
                      width: MediaQuery.of(context).size.width / 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Continue",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 4.5),
                            ),
                            Icon(
                              FontAwesomeIcons.arrowCircleRight,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ]),
        ),
      ),
    );
  }

  Widget _VerifyOTP() {
    return Expanded(
      child: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                          colors: [Color(0xff52BFF9), Color(0xff6048F6)])
                      .createShader(rect);
                },
                child: Text(
                  "Please enter the One Time Password received on: $kRSSMail",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 4),
                ),
              ),
              SizedBox(
                height: SizeConfig.safeBlockVertical * 2,
              ),
              // OTPTextField(
              //   length: 6,
              //   width: MediaQuery.of(context).size.width,
              //   textFieldAlignment: MainAxisAlignment.spaceAround,
              //   fieldWidth: 30,
              //   fieldStyle: FieldStyle.underline,
              //   style: TextStyle(
              //     fontSize: 17,
              //     color: themeProvider.isLightTheme != true
              //         ? kSecondaryColor
              //         : Colors.white,
              //   ),
              //   onCompleted: (pin) {
              //     _OTPController.text = pin;
              //     _OTPController.text;
              //   },
              // ),
              PinCodeTextField(
                appContext: context,
                pastedTextStyle: TextStyle(
                  // color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                ),
                length: 6,
                obscureText: false,
                // obscuringCharacter: '*',
                // obscuringWidget: FlutterLogo(
                //   size: 24,
                // ),
                blinkWhenObscuring: true,
                // animationType: AnimationType.fade,
                validator: (v) {
                  // if (v!.length < 3) {
                  //   return "I'm from validator";
                  // } else {
                  //   return null;
                  // }
                },
                pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    borderRadius: BorderRadius.circular(5),
                    fieldHeight: 50,
                    fieldWidth: 40,
                    activeColor: Colors.blue,
                    inactiveColor: kSecondaryColor,
                    activeFillColor: Colors.transparent,
                    inactiveFillColor: Colors.transparent),
                cursorColor: Colors.black,
                animationDuration: Duration(milliseconds: 300),
                enableActiveFill: false,
                // errorAnimationController: errorController,
                controller: _OTPController,
                keyboardType: TextInputType.number,

                onCompleted: (pin) {
                  print(pin);
                  _OTPController.text = pin;
                  _OTPController.text;
                },
                // onTap: () {
                //   print("Pressed");
                // },
                onChanged: (value) {
                  // print(value);
                },
                beforeTextPaste: (text) {
                  print("Allowing to paste $text");
                  //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                  //but you can show anything you want here, like your pop up saying wrong paste format or etc
                  return true;
                },
              ),
              SizedBox(
                height: SizeConfig.safeBlockVertical * 2,
              ),
              InkWell(
                onTap: () async {
                  if (!_OTPController.text.isEmpty &&
                      _OTPController.text.length == 6) {
                    await verifyOTP();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Color(0xff52BFF9), Color(0xff6048F6)])),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Icon(
                      FontAwesomeIcons.arrowCircleRight,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _importPodcastIntro() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                        colors: [Color(0xff52BFF9), Color(0xff6048F6)])
                    .createShader(bounds);
              },
              child: Row(
                children: [
                  Text(
                    "Lets get you connected",
                    textScaleFactor: 0.75,
                    style: TextStyle(
                        //    color: Colors.white,
                        fontSize: SizeConfig.safeBlockHorizontal * 5),
                  ),
                  SizedBox(
                    width: SizeConfig.safeBlockHorizontal * 10,
                  ),
                  Icon(
                    FontAwesomeIcons.rss,
                    //     color: Colors.white,
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                "Connect your podcast with Aureal in 3 easy steps.",
                textScaleFactor: 0.75,
                style: TextStyle(
                  fontSize: SizeConfig.safeBlockHorizontal * 7.5,
                  //  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 2,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                          colors: [Color(0xff52BFF9), Color(0xff6048F6)])),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Get Started",
                          textScaleFactor: 0.75,
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        ),
                        Icon(
                          FontAwesomeIcons.arrowCircleRight,
                          color: Colors.white,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void fetchPodcast() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = "https://api.aureal.one/";
  }

  bool isPodcastFetched = false;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: ModalProgressHUD(
          inAsyncCall: isLoading,
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Stack(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/rss_page.png'),
                          ),
                        ),
                      ),
                      // Container(
                      //   width: MediaQuery.of(context).size.width * 0.8,
                      //   height: MediaQuery.of(context).size.width * 0.8,
                      //   decoration: BoxDecoration(
                      //       color: kPrimaryColor.withOpacity(0.55)),
                      // ),
                    ],
                  ),
                ),
                Container(
                  child: isPodcastFetched == true
                      ? Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: 50,
                              ),
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(),
                                        image: DecorationImage(
                                            image: NetworkImage(podcastImage),
                                            fit: BoxFit.contain),
                                        //    color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    height:
                                        MediaQuery.of(context).size.width / 1.5,
                                    width:
                                        MediaQuery.of(context).size.width / 1.5,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Text(
                                      "$podcastName",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          //  color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  8),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 25, horizontal: 15),
                                    child: Text(
                                      "Your podcast is now connected with Aureal, Visit your profile section to enable monetisation for every episode*",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          //color: Colors.white,
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  4),
                                    ),
                                  ),
                                ],
                              ),
                              // Row(children: <Widget>[
                              //   CircleAvatar(
                              //     radius: 20,
                              //
                              //   ),

                              Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 20,
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 20,
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, Profile.id);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(colors: [
                                          Color(0xff52BFF9),
                                          Color(0xff6048F6)
                                        ])),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Continue to Profile",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: SizeConfig
                                                        .safeBlockHorizontal *
                                                    4.5),
                                          ),
                                          Icon(
                                            FontAwesomeIcons.arrowCircleRight,
                                            // color: Colors.white,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Flexible(
                              child: Container(
                                width: double.infinity,
                              ),
                            ),
                            _createPage(context, _selectedIndex),
                            // _RSSTextField(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ));
  }
}
