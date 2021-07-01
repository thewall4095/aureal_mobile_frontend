import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReferralProgram extends StatefulWidget {
  @override
  _ReferralProgramState createState() => _ReferralProgramState();
}

class _ReferralProgramState extends State<ReferralProgram>
    with TickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    // TODO: implement initState
    _controller = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Referral",
          textScaleFactor: 1.0,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: Container(
        height: 300,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              border:  Border.all(color: kSecondaryColor),
                color: themeProvider.isLightTheme == true
                    ? Colors.white
                    : Color(0xff222222),
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Invite Link",
                    textScaleFactor: 1.0,
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(

                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            "https://aureal.one/referral",
                            style: TextStyle(
                                fontSize:
                                    SizeConfig.safeBlockHorizontal * 4),
                          ),
                        ),
                      ),
                      Row(
                        children: [

                          Container(
                            decoration: BoxDecoration(
                              border:  Border.all(color: kSecondaryColor),
                              shape: BoxShape.circle,
                              color: themeProvider.isLightTheme == true
                                  ? Colors.white
                                  : Color(0xff222222),),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(Icons.copy),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border:  Border.all(color: kSecondaryColor),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(Icons.share),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.width / 7,
                        width: 2,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              Color(0xff5d5da8),
                              Color(0xff5bc3ef)
                            ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "234",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 4.5,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text("Links Shared")
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Container(
                        height: MediaQuery.of(context).size.width / 7,
                        width: 2,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              Color(0xff5d5da8),
                              Color(0xff5bc3ef)
                            ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "234",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 4.5,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text("Creators Signed Up")
                          ],
                        ),
                      ),
                      SizedBox(
                        width:10,
                      ),
                      Container(
                        height: MediaQuery.of(context).size.width / 7,
                        width: 2,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              Color(0xff5d5da8),
                              Color(0xff5bc3ef)
                            ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "234",
                              textScaleFactor: 1.0,
                              style: TextStyle(
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 4.5,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(" Rewards")
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
