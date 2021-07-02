import 'package:auditory/screens/buttonPages/settings/Theme-.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:expandable/expandable.dart';
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
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                decoration: BoxDecoration(
                    color: Color(0xff222222),
                    borderRadius: BorderRadius.circular(10)),
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
                                color: Color(0xff777777),
                                borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Text(
                                "https://aureal.one/referral?referral_id=87293",
                                textScaleFactor: 1.0,
                                style: TextStyle(
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 2.5),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                  onPressed: () {}, icon: Icon(Icons.copy)),
                              IconButton(
                                  onPressed: () {}, icon: Icon(Icons.share))
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(color: Colors.blue))),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text('1231'), Text('Links Shared')],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(color: Colors.blue))),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text('1231'), Text('Links Shared')],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(color: Colors.blue))),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text('1231'), Text('Links Shared')],
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text("Your estimated rewards"),
                    ],
                  ),
                ),
              ),
            ),
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
                decoration: BoxDecoration(color: Color(0xff222222)),
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
                decoration: BoxDecoration(color: Color(0xff222222)),
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
                decoration: BoxDecoration(color: Color(0xff222222)),
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
                decoration: BoxDecoration(color: Color(0xff222222)),
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
                decoration: BoxDecoration(color: Color(0xff222222)),
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
        ),
      ),
    );
  }
}
