import 'dart:async';

import 'package:auditory/Accounts/HiveAccount.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_twitter/flutter_twitter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import 'Auth.dart';

class Welcome extends StatefulWidget {
  static const String id = 'welcomeScreen';

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  StreamSubscription<User> loginStateSubscription;
  // static final TwitterLogin twitterLogin = new TwitterLogin(
  //   consumerKey: '255420786-7klL26DLH6hAXYIW3nmnGv2frktiGMNvBWxD23N3',
  //   consumerSecret: 'HQDbaVxqXzj2RMhPHOWpktzVtwiYSD5a2M1FESpEWhRXk',
  // );
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  String _message = 'Logged out.';
  bool _rememberMe = false;
  bool showSpinner = false;
  final _auth = FirebaseAuth.instance;
  String email;
  String password;

  @override
  void initState() {
    var authBloc = Provider.of<AuthBloc>(context, listen: false);
    // loginStateSubscription = authBloc.currentUser.listen((fbUser) {
    //   if (fbUser != null) {
    //     Navigator.of(context).pushReplacement(
    //       MaterialPageRoute(
    //         builder: (context) => Home(),
    //       ),
    //     );
    //   }
    // });
    super.initState();
  }

  @override
  void dispose() {
    // loginStateSubscription.cancel();
    super.dispose();
  }

  void _login() async {
    // final TwitterLoginResult result = await twitterLogin.authorize();
    // String newMessage;
    //
    // switch (result.status) {
    //   case TwitterLoginStatus.loggedIn:
    //     newMessage = 'Logged in! username: ${result.session.username}';
    //     break;
    //   case TwitterLoginStatus.cancelledByUser:
    //     newMessage = 'Login cancelled by user.';
    //     break;
    //   case TwitterLoginStatus.error:
    //     newMessage = 'Login error: ${result.errorMessage}';
    //     break;
    // }

    // setState(() {
    //   _message = newMessage;
    // });
  }

  void _logout() async {
    // await twitterLogin.logOut();

    setState(() {
      _message = 'Logged out.';
    });
  }

  bool isLoggedIn = false;

  var profileData;

  // var facebookLogin = FacebookLogin();

  void onLoginStatusChanged(bool isLoggedIn, {profileData}) {
    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.profileData = profileData;
    });
  }

  // void initiateFacebookLogin() async {
  //   // var facebookLoginResult =
  //   //     await facebookLogin.logInWithReadPermissions(['email']);
  //
  //   var facebookLoginResult = await facebookLogin.logIn(['email']);
  //
  //   print('//////////////////fucking it here');
  //   print(facebookLoginResult.status);
  //   print(facebookLoginResult.errorMessage);
  //
  //   switch (facebookLoginResult.status) {
  //     case FacebookLoginStatus.error:
  //       onLoginStatusChanged(false);
  //       break;
  //     case FacebookLoginStatus.cancelledByUser:
  //       onLoginStatusChanged(false);
  //       break;
  //     case FacebookLoginStatus.loggedIn:
  //       print(
  //           '///////////////////////////////////////////////////////////////////////');
  //       var graphResponse = await http.get(Uri.parse(
  //           'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult.accessToken.token}'));
  //       print(graphResponse.body);
  //
  //       var profile = json.decode(graphResponse.body);
  //       print(profile.toString());
  //
  //       onLoginStatusChanged(true, profileData: profile);
  //       break;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);
    SizeConfig().init(context);
    return Scaffold(
        backgroundColor: kPrimaryColor,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            Container(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/cut_piece.png',
                    cacheHeight: MediaQuery.of(context).size.height.floor(),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Image.asset('assets/images/aureaText.png')),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
            ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Center(
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 50),
            //       child: InkWell(
            //         onTap: () {
            //           Navigator.pushNamed(context, Login.id);
            //         },
            //         child: Container(
            //           width: double.infinity,
            //           decoration: BoxDecoration(
            //               borderRadius: BorderRadius.circular(30),
            //               border:
            //                   Border.all(color: kSecondaryColor, width: 2.5)),
            //           child: Padding(
            //             padding: const EdgeInsets.symmetric(
            //                 horizontal: 20, vertical: 10),
            //             child: Center(
            //               child: Text(
            //                 'Login',
            //                 style: TextStyle(
            //                     color: Color(0xffe8e8e8),
            //                     fontSize: SizeConfig.safeBlockHorizontal * 5.5),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Center(
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 50),
            //       child: InkWell(
            //         onTap: () {
            //           Navigator.pushNamed(context, SignUp.id);
            //         },
            //         child: Container(
            //           width: double.infinity,
            //           decoration: BoxDecoration(
            //               borderRadius: BorderRadius.circular(30),
            //               gradient: LinearGradient(
            //                   colors: [Color(0xff5bc3ef), Color(0xff5d5da8)])),
            //           child: Padding(
            //             padding: const EdgeInsets.symmetric(
            //                 horizontal: 20, vertical: 10),
            //             child: Center(
            //               child: Text(
            //                 'Sign Up',
            //                 style: TextStyle(
            //                     color: Color(0xffe8e8e8),
            //                     fontSize: SizeConfig.safeBlockHorizontal * 5.5),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(
              height: 80,
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Container(
            //       decoration:
            //           BoxDecoration(border: Border.all(color: kSecondaryColor)),
            //       height: 0,
            //       width: MediaQuery.of(context).size.width / 3.1,
            //     ),
            //     Padding(
            //       padding: const EdgeInsets.all(8.0),
            //       child: Text(
            //         'or',
            //         style: TextStyle(
            //             color: Color(0xffe8e8e8),
            //             fontSize: SizeConfig.safeBlockHorizontal * 5),
            //       ),
            //     ),
            //     Container(
            //       decoration:
            //           BoxDecoration(border: Border.all(color: kSecondaryColor)),
            //       height: 0,
            //       width: MediaQuery.of(context).size.width / 3.1,
            //     )
            //   ],
            // ),
            // SizedBox(
            //   height: 40,
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     GestureDetector(
            //         child: CircleAvatar(
            //           child: Icon(
            //             FontAwesomeIcons.google,
            //             color: Color(0xffe8e8e8),
            //           ),
            //           radius: 25,
            //           backgroundColor: kSecondaryColor,
            //         ),
            //         onTap: () {
            //           authBloc.loginGoogle(context);
            //         }),
            //     // InkWell(
            //     //   onTap: () async {
            //     //     initiateFacebookLogin();
            //     //   },
            //     //   child: CircleAvatar(
            //     //     radius: 25,
            //     //     backgroundColor: kSecondaryColor,
            //     //     child: Icon(
            //     //       FontAwesomeIcons.facebookF,
            //     //       color: Color(0xffe8e8e8),
            //     //     ),
            //     //   ),
            //     // ),
            //     // InkWell(
            //     //   onTap: () {
            //     //     _login();
            //     //   },
            //     //   child: CircleAvatar(
            //     //     radius: 25,
            //     //     backgroundColor: kSecondaryColor,
            //     //     child: Icon(
            //     //       FontAwesomeIcons.twitter,
            //     //       color: Color(0xffe8e8e8),
            //     //     ),
            //     //   ),
            //     // )
            //   ],
            // ),
            InkWell(
              onTap: () {
                authBloc.loginGoogle(context);
                // print("Hive Signer Activated");
                // showBarModalBottomSheet(
                //     context: context,
                //     builder: (context, ScrollController controller) {
                //       return HiveAccount();
                //     });
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 1.3,
                decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(30)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.google,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      Center(
                        child: Text(
                          "Sign in with Google",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: Color(0xffe8e8e8),
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            InkWell(
              onTap: () {
                print("Hive Signer Activated");
                showBarModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return HiveAccount();
                    });
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 1.3,
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(30)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.hive,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      Center(
                        child: Text(
                          "Sign in using HiveSigner",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              color: Color(0xffe8e8e8),
                              fontSize: SizeConfig.safeBlockHorizontal * 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
