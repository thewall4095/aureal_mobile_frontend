import 'dart:convert';

import 'package:auditory/Services/HiveOperations.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Rewards extends StatefulWidget {
  static const String id = 'Rewards Screen';

  @override
  _RewardsState createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> {
  @override
  void initState() {
    // TODO: implement initState
    getHiveRewardData();
    super.initState();
  }

  var rewardsdata;
  bool isScreenLoading = false;

  void getHiveRewardData() async {
    setState(() {
      isScreenLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/clientMe';
    print('ceck');
    print(prefs.getString('token'));
    print(prefs.getString('access_token'));
    try {
      http.Response response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${prefs.getString('token')}',
        'access-token': '${prefs.getString('access_token')}'
      });
      print(response.body);
      setState(() {
        rewardsdata = jsonDecode(response.body)['client'];
      });
    } catch (e) {
      print(e);
    }
    setState(() {
      isScreenLoading = false;
    });
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Rewards',
          textScaleFactor: 0.75,
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: isScreenLoading,
        child: rewardsdata == null
            ? Expanded(
                child: Container(),
              )
            : Container(
                child: Stack(
                  children: [
                    ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                  color: Color(0xff3a3a3a),
                                ))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.08,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'HIVE',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  5.5,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          '${rewardsdata['account']['reward_hive_balance'].toString()}',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4),
                                        )
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Text(
                                        'HIVE are tokens that maybe transferrable \nanytime. HIVE can be converted to Hive Power \nin a process called powering up',
                                        textScaleFactor: 0.75,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                  color: Color(0xff3a3a3a),
                                ))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.05,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'HBD',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  5.5,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          '${rewardsdata['account']['reward_hbd_balance']}',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4),
                                        )
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Text(
                                        'Tokens worth about \$1 of HIVE',
                                        textScaleFactor: 0.75,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                  color: Color(0xff3a3a3a),
                                ))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.05,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Hive Power',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  5.5,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          '${rewardsdata['account']['reward_vesting_hive'].toString().split(' ')[0]} HP',
                                          textScaleFactor: 0.75,
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  4),
                                        )
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Text(
                                        'Hive Power are influence tokens that earn \nmore power for holding long term and voting \non posts. The more Hive Power one holds the \nmore one can influence other\'s rewards and \nearn rewards for accurate voting',
                                        textScaleFactor: 0.75,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 50,
                              ),
                              InkWell(
                                onTap: () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  await claimRewards();
                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: kSecondaryColor,
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Text(
                                      'Claim Reward',
                                      textScaleFactor: 0.75,
                                      style: TextStyle(
                                          color: Color(0xffe8e8e8),
                                          fontSize:
                                              SizeConfig.safeBlockHorizontal *
                                                  4),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        isLoading == false
                            ? SizedBox(height: 0)
                            : LinearProgressIndicator(
                                minHeight: SizeConfig.safeBlockVertical * 5,
                                backgroundColor: kSecondaryColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xffe8e8e8)),
                              ),
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
