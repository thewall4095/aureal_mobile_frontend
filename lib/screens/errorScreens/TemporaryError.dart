import 'package:auditory/screens/buttonPages/Downloads.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';

class TemporaryError extends StatelessWidget {
  static const String id = "TemporaryError";

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        width: double.infinity,
//        decoration: BoxDecoration(
//          image: DecorationImage(
//              image: AssetImage('assets/images/internetIssue.png'),
//              fit: BoxFit.contain),
//        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height / 2,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/images/internetIssue.png'),
                      fit: BoxFit.contain)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                child: Center(
                  child: Text(
                    "Oh! Snap, There seems to be some trouble. Meanwhile please check your internet connection.",
                    textScaleFactor: 1,
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, DownloadPage.id);
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: kSecondaryColor),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Text(
                    "Listen to Downloads",
                    style: TextStyle(
                        color: Color(0xffe8e8e8),
                        fontSize: SizeConfig.safeBlockHorizontal * 4),
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
