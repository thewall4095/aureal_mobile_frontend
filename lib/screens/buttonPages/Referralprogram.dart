import 'dart:convert';

import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:clipboard/clipboard.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

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
        child: ListView(
          children: [
            ReferralDashboard(),
            FAQ(),
          ],
        ),
      ),
    );
  }
}

class ReferralDashboard extends StatefulWidget {
  const ReferralDashboard({Key key}) : super(key: key);

  @override
  _ReferralDashboardState createState() => _ReferralDashboardState();
}

class _ReferralDashboardState extends State<ReferralDashboard> {
  String linksShared = 0.toString();
  String referralCode = '';

  void getReferralLink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getPersonalReferralLink?user_id=${prefs.getString('userId')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          prefs.setString(
              'ReferralCode', jsonDecode(response.body)['data']['code']);
          prefs.setString(
              'LinksShared', jsonDecode(response.body)['data']['refer_count']);
          linksShared = jsonDecode(response.body)['data']['refer_count'];
          referralCode = jsonDecode(response.body)['data']['code'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void share({var episodeId, String episodeName}) async {
    await FlutterShare.share(
        title: '',
        text:
            "Hey There, I'm listening to  from  on Aureal, here's the link for you https://aureal.one/episode/${episodeId.toString()}");
  }

  int count = 0;

  @override
  void initState() {
    // TODO: implement initState
    getReferralLink();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    setState(() {});
    try {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              new BoxShadow(
                color: Colors.black54.withOpacity(0.2),
                blurRadius: 10.0,
              ),
            ],
            color: themeProvider.isLightTheme == true
                ? Colors.white
                : Color(0xff1a1a1a),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your Referral Dashboard"),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: themeProvider.isLightTheme == true
                              ? Color(0xffE8E8E8)
                              : Color(0xff1a1a1a),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(0xff1a1a1a))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 10),
                        child: Text(
                          "https://aureal.one/referral?refCode=${referralCode == 'null' ? "" : referralCode}",
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 2.5),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              FlutterClipboard.copy(
                                      'https://aureal.one/referral?refCode=${referralCode == 'null' ? "" : referralCode}')
                                  .then((value) => Fluttertoast.showToast(
                                      msg: 'Referral Code Copied'));
                            },
                            icon: Icon(Icons.copy)),
                        IconButton(
                            onPressed: () async {
                              await FlutterShare.share(
                                  title: 'Monetise your podcast on Aureal',
                                  text:
                                      "Hey There, I'm Inviting you this Decentralised Podcast App called Aureal. You can start monetising your podcast using my link: https://aureal.one/referral?refCode=${referralCode == 'null' ? "" : referralCode}");
                            },
                            icon: Icon(Icons.share))
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.blue))),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${linksShared.toString()}',
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text('Links Shared')
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Calculate your rewards"),
                            SizedBox(
                              width: 10,
                            ),
                            GestureDetector(
                                onTap: () {
                                  Fluttertoast.showToast(
                                      msg:
                                          'These are estimated rewards based on the average payout per episode');
                                },
                                child: Icon(Icons.info_outline))
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(colors: [
                                Color(0xff5d5da8),
                                Color(0xff5bc3ef)
                              ]).createShader(bounds);
                            },
                            child: Text(
                              "\$${(4.2 * count * 2).ceilToDouble()}",
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Your estimated invites"),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(colors: [
                                Color(0xff5d5da8),
                                Color(0xff5bc3ef)
                              ]).createShader(bounds);
                            },
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      count = count + 1;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color:
                                            themeProvider.isLightTheme == true
                                                ? Color(0xffE8E8E8)
                                                : Color(0xff1a1a1a),
                                        shape: BoxShape.circle),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(Icons.add),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "$count",
                                    style: TextStyle(
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (count > 0) {
                                        count = count - 1;
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color:
                                            themeProvider.isLightTheme == true
                                                ? Color(0xffE8E8E8)
                                                : Color(0xff1a1a1a),
                                        shape: BoxShape.circle),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(Icons.remove),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print(e);
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Shimmer.fromColors(
          direction: ShimmerDirection.ttb,
          baseColor: kPrimaryColor,
          highlightColor: Color(0xff3a3a3a),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            height: MediaQuery.of(context).size.height / 3,
            width: double.infinity,
          ),
        ),
      );
    }
  }
}

class FAQ extends StatelessWidget {
  const FAQ({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            "Frequently Asked Questions",
            textScaleFactor: 1.0,
            style: TextStyle(
              fontSize: SizeConfig.safeBlockHorizontal * 5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                new BoxShadow(
                  color: Colors.black54.withOpacity(0.2),
                  blurRadius: 10.0,
                ),
              ],
              color: themeProvider.isLightTheme == true
                  ? Colors.white
                  : Color(0xff1a1a1a),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpandablePanel(
                  header: Text(
                    "What is Aureal referral program",
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        fontWeight: FontWeight.w700),
                  ),
                  expanded: Text(
                      'The Referral program allows you to earn rewards by inviting your fellow podcasters to this new paradigm of podcasting on Hive Blockchain. You earn this reward as your fellow podcasters starts monetising their episodes from day 1')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                new BoxShadow(
                  color: Colors.black54.withOpacity(0.2),
                  blurRadius: 10.0,
                ),
              ],
              color: themeProvider.isLightTheme == true
                  ? Colors.white
                  : Color(0xff1a1a1a),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpandablePanel(
                  header: Text(
                    "Where do I get my referral link",
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        fontWeight: FontWeight.w700),
                  ),
                  expanded: Text(
                      'You can find the referral link from your profile. You can use this link to invite your fellow podcasters and earn rewards through it.')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                new BoxShadow(
                  color: Colors.black54.withOpacity(0.2),
                  blurRadius: 10.0,
                ),
              ],
              color: themeProvider.isLightTheme == true
                  ? Colors.white
                  : Color(0xff1a1a1a),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpandablePanel(
                  header: Text(
                    "Whom can I invite?",
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        fontWeight: FontWeight.w700),
                  ),
                  expanded: Text(
                      'You can invite anyone who is an avid fan of podcasts or podcasting. When there are more listeners the rewards that your favourite podcaster earn are more,and when they do, you earn rewards too')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                new BoxShadow(
                  color: Colors.black54.withOpacity(0.2),
                  blurRadius: 10.0,
                ),
              ],
              color: themeProvider.isLightTheme == true
                  ? Colors.white
                  : Color(0xff1a1a1a),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpandablePanel(
                  header: Text(
                    "When do I earn rewards?",
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        fontWeight: FontWeight.w700),
                  ),
                  expanded: Text(
                      'Usually you can claim the rewards after 7 days of the episodes being published by your fellow podcaster. You are eligible to 10% of the total rewards earned by your fellow podcaster for their first 2 episodes, when the 7 day payout period ends, you can claim their rewards from your wallet')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                new BoxShadow(
                  color: Colors.black54.withOpacity(0.2),
                  blurRadius: 10.0,
                ),
              ],
              color: themeProvider.isLightTheme == true
                  ? Colors.white
                  : Color(0xff1a1a1a),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ExpandablePanel(
                  header: Text(
                    "How can I claim the rewards?",
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        fontWeight: FontWeight.w700),
                  ),
                  expanded: Text(
                      'You can claim these rewards by clicking on the wallet button on the top right corner. Once you click on Claim Rewards button, all the rewards you earn inluding the referral rewards are credited to your wallet. If you are a user of any other Dapp on Hive, you can user their Wallet option and claim all the pending rewards.')),
            ),
          ),
        ),
      ],
    );
  }
}
