import 'dart:convert';
import 'dart:math';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'settings/Theme-.dart';

class Wallet extends StatefulWidget {
  static const String id = "HiveWallet";

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin {
  TabController _tabController;

  ScrollController _scrollRewardsController;

  var rewardsData;
  int page = 0;
  int pageSize = 10;
  var hiveTransactions;

  List claimedRewards = [];
  List transferHive = [];
  List transferHBD = [];
  SharedPreferences prefs;
  String hiveUsername;

  void getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (this.mounted) {
      setState(() {
        hiveUsername = prefs.getString('HiveUserName');
      });
    }
  }

  void getHiveTransactions() async {
    await getLocalData();
    print(hiveUsername);
    print('this Started');

    String url =
        'https://api.aureal.one/public/getHiveWalletTransactions?hive_username=$hiveUsername';
    if (hiveUsername != null) {
      try {
        http.Response response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          if (this.mounted) {
            setState(() {
              hiveTransactions = jsonDecode(response.body)['notifications'];
              print(hiveTransactions.toString());
              for (var v in hiveTransactions) {
                if (v[1]['op'][0] == 'claim_reward_balance') {
                  claimedRewards.add(v);
                }
                if (v[1]['op'][0] == 'transfer') {
                  if (v[1]['op'][1]['amount'].toString().contains('HBD') ==
                      true) {
                    transferHBD.add(v);
                  } else {
                    transferHive.add(v);
                  }
                }
              }
              transferHive = transferHive.reversed.toList();
              transferHBD = transferHBD.reversed.toList();
            });
          }
        } else {
          print(response.statusCode);
        }
      } catch (e) {
        print(e);
      }
    } else {
      print('Hive username is null');
    }
  }

  var cumulativePoints = [];

  void getCumulativePoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getCumulativePoints?user_id=${prefs.getString('userId')}';
    print(cumulativePoints);
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);

        setState(() {
            cumulativePoints = jsonDecode(response.body)['points'];

        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  bool rewardsList = true;
  void getAurealRewardsTransactions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getPoints?user_id=${prefs.getString('userId')}&page=$page&pageSize=$pageSize';
    print('api called');
    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);

        setState(() {
          if (page == 0) {
            rewardsTransactions = jsonDecode(response.body)['points'];
             rewardsList = true;
            page = page +1;
          } else {
            rewardsTransactions =
                rewardsTransactions + jsonDecode(response.body)['points'];
             rewardsList = false;
            page = page +1;
          }
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  bool isScreenLoading = true;

  var rewardsTransactions = [];

  void getHiveRewardData() async {
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
        rewardsData = jsonDecode(response.body)['client'];
      });
    } catch (e) {
      print(e);
    }
    if (this.mounted) {
      setState(() {
        isScreenLoading = false;
      });
    }
  }

  double x = 1892.98479;

  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(length: 4, vsync: this);
    getAurealRewardsTransactions();
    getHiveRewardData();
    getHiveTransactions();
    getCumulativePoints();
    //  countPoints();

    _scrollRewardsController = ScrollController();
    _scrollRewardsController.addListener(() {
      if (_scrollRewardsController.position.pixels ==
          _scrollRewardsController.position.maxScrollExtent) {
        getAurealRewardsTransactions();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: isScreenLoading,
          child: isScreenLoading == true
              ? Container()
              : NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool isInnerBoxScrolled) {
                    return [
                      SliverAppBar(
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back_rounded),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        expandedHeight:
                            MediaQuery.of(context).size.height / 3.8,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kSecondaryColor),
                                color: themeProvider.isLightTheme == true
                                    ? Colors.white
                                    : kSecondaryColor,
                              ),
                              child: SafeArea(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    Container(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      " ${cumulativePoints[1]["total_points"]+cumulativePoints[2]["total_points"]+cumulativePoints[2]["total_points"]}.00",

                                                      // '${cumulativePoints[]['points']}',
                                                      style: TextStyle(
                                                          fontSize: SizeConfig
                                                                  .safeBlockHorizontal *
                                                              5),
                                                    ),
                                                    IconButton(
                                                        icon: Icon(Icons
                                                            .arrow_drop_down_circle),
                                                        onPressed: () {}),
                                                  ], 
                                                ),

                                                Padding(
                                                  padding: const EdgeInsets.only(right: 30),
                                                  child: Text(
                                                    "Points",
                                                    // '${cumulativePoints[]['points']}',
                                                    style: TextStyle(
                                                        fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                            4),
                                                  ),
                                                ),
                                                // InkWell(
                                                //   child: Container(
                                                //     child: Row(
                                                //       mainAxisSize:
                                                //           MainAxisSize.min,
                                                //       children: [
                                                //         Padding(
                                                //           padding:
                                                //               const EdgeInsets
                                                //                       .symmetric(
                                                //                   horizontal: 10),
                                                //           child: Icon(
                                                //               Icons.add_circle),
                                                //         )
                                                //       ],
                                                //     ),
                                                //   ),
                                                // ),

                                                //
                                                // Padding(
                                                //   padding:
                                                //   const EdgeInsets.symmetric(
                                                //       vertical: 10),
                                                //   child: Row(
                                                //     mainAxisSize:
                                                //     MainAxisSize.min,
                                                //     children: [
                                                //       IconButton(
                                                //           icon: iconGenerator(
                                                //               cumulativePoints[0]
                                                //               ['action_type']),
                                                //           onPressed: () {}),
                                                //       Text(
                                                //         " Comment",
                                                //         // '${cumulativePoints[]['points']}',
                                                //         style: TextStyle(
                                                //             fontSize: SizeConfig
                                                //                 .safeBlockHorizontal *
                                                //                 5),
                                                //       ),
                                                //       Text(
                                                //         " ${cumulativePoints[0]["total_points"]}",
                                                //
                                                //         // '${cumulativePoints[]['points']}',
                                                //         style: TextStyle(
                                                //             fontSize: SizeConfig
                                                //                 .safeBlockHorizontal *
                                                //                 5),
                                                //       )
                                                //     ],
                                                //   ),
                                                // ),

                                    // Padding(
                                    //   padding: const EdgeInsets.all(8.0),
                                    //   child: InkWell(
                                    //     child: Container(
                                    //       child: Row(
                                    //         mainAxisSize: MainAxisSize.min,
                                    //         children: [
                                    //           Text('123.909'),
                                    //           Padding(
                                    //             padding: const EdgeInsets
                                    //                 .symmetric(
                                    //                 horizontal: 10),
                                    //             child:
                                    //             Icon(Icons.add_circle),
                                    //           )
                                    //         ],
                                    //       ),
                                    //     ),
                                    //   ),
                                    // )

                                              ],
                                            ),
                                          ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ListTile(
                                              title: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('HIVE'),
                                                  IconButton(
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle_outlined),
                                                      onPressed: () {})
                                                ],
                                              ),
                                              trailing: Text(
                                                  "${rewardsData['account']['balance'].toString().split(' ')[0]}"),
                                            ),
                                            ListTile(
                                              title: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('HIVE Savings'),
                                                  IconButton(
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle_outlined),
                                                      onPressed: () {})
                                                ],
                                              ),
                                              trailing: Text(
                                                  '${rewardsData['account']['savings_balance']}'),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ListTile(
                                              title: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('HBD'),
                                                  IconButton(
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle_outlined),
                                                      onPressed: () {})
                                                ],
                                              ),
                                              trailing: Text(
                                                  "${rewardsData['account']['hbd_balance'].toString().split(' ')[0]}"),
                                            ),
                                            ListTile(
                                              title: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('HBD Savings'),
                                                  IconButton(
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle_outlined),
                                                      onPressed: () {})
                                                ],
                                              ),
                                              trailing: Text(
                                                  '${rewardsData['account']['savings_hbd_balance'].toString().split(' ')[0]}'),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ListTile(
                                              title: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('HP'),
                                                  IconButton(
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle_outlined),
                                                      onPressed: () {})
                                                ],
                                              ),
                                              trailing: Text(
                                                  "${((double.parse(rewardsData['account']['vesting_shares'].toString().split(' ')[0]) / x) - (double.parse(rewardsData['account']['delegated_vesting_shares'].toString().split(' ')[0]) / x)).toStringAsFixed(3)}"),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ];
                  },
                  body: Container(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Container(
                          child: ListView.builder(
                            itemCount: rewardsTransactions.length  ,
                            controller: _scrollRewardsController,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, int index) {

                              // print(
                              //     '${double.parse(rewardsTransactions[index]['points'].toString())} points');
                              // return Text('${rewardsTransactions[index]}');
                              return Container(
                                child: ListTile(
                                  minVerticalPadding: 10,
                                  leading: iconGenerator(
                                      rewardsTransactions[index]
                                          ['action_type']),
                                  title: Text(
                                      'Points for ${rewardsTransactions[index ]['action_type']}'),
                                  subtitle: Text(
                                      '${timeago.format(DateTime.parse(rewardsTransactions[index]['updatedAt']))}'),
                                  trailing: Text(
                                      '${double.parse(rewardsTransactions[index ]['points'].toString())} points'),
                                ),
                              );
                            },

                          ),
                        ),
                        Container(
                          child: ListView.builder(
                            itemBuilder: (context, int index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kSecondaryColor),
                                    // border: Border.all(
                                    //   color: kSecondaryColor,
                                    color: themeProvider.isLightTheme == true
                                        ? Colors.white
                                        : kSecondaryColor,
                                    // color: kSecondaryColor,
                                    //),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: ExpandablePanel(
                                        header: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("Transfer"),
                                            Text(
                                                "${transferHive[index + 1][1]['op'][1]['amount']}"),
                                          ],
                                        ),
                                        collapsed: Text(
                                          '${timeago.format(DateTime.parse(transferHive[index][1]['timestamp']))}',
                                          style: TextStyle(
                                              // color: Color(0xff3a3a3a)
                                              ),
                                        ),
                                        expanded: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${timeago.format(DateTime.parse(transferHive[index][1]['timestamp']))}',
                                              style: TextStyle(),
                                            ),
                                            Text(
                                                "From: ${transferHive[index][1]['op'][1]['from']}"),
                                            Text(
                                                "To: ${transferHive[index][1]['op'][1]['to']}"),
                                            Text(
                                                "Memo: ${transferHive[index][1]['op'][1]['memo']}"),
                                          ],
                                        )),
                                  ),
                                ),
                              );
                            },
                            itemCount: transferHive.length,
                          ),
                        ),
                        Container(
                          child: ListView.builder(
                            itemBuilder: (context, int index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kSecondaryColor),
                                    // border: Border.all(
                                    //   color: kSecondaryColor,
                                    color: themeProvider.isLightTheme == true
                                        ? Colors.white
                                        : kSecondaryColor,
                                    // color: kSecondaryColor,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: ExpandablePanel(
                                        header: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("Transfer"),
                                            Text(
                                                "${transferHBD[index][1]['op'][1]['amount']}"),
                                          ],
                                        ),
                                        collapsed: Text(
                                          '${timeago.format(DateTime.parse(transferHBD[index][1]['timestamp']))}',
                                          style: TextStyle(
                                              color: Color(0xff3a3a3a)),
                                        ),
                                        expanded: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 10),
                                              child: Text(
                                                '${timeago.format(DateTime.parse(transferHBD[index][1]['timestamp']))}',
                                                style: TextStyle(
                                                    color: Color(0xff3a3a3a)),
                                              ),
                                            ),
                                            Text(
                                                "From: ${transferHBD[index][1]['op'][1]['from']}"),
                                            Text(
                                                "To: ${transferHBD[index][1]['op'][1]['to']}"),
                                            Text(
                                                "Memo: ${transferHBD[index][1]['op'][1]['memo']}"),
                                          ],
                                        )),
                                  ),
                                ),
                              );
                            },
                            itemCount: transferHBD.length,
                          ),
                        ),
                        Container(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// String pointsFor(var action_type) {
//   if(action_type == 'vote'){
//     return 'Points for vote';
//   }
//   if(action_type == "heartbeat"){
//     return 'Points for heartbeat';
//   }
//   if(action_type == 'comment'){
//     return 'Points for comment';
//   }
//   if(action_type == 'vote'){
//     return 'Points for vote';
//   }
//   if(action_type == 'vote'){
//     return 'Points for vote';
//   }
//
// }

Widget iconGenerator(var actionType) {
  switch (actionType) {
    case 'vote':
      return Icon(FontAwesomeIcons.chevronCircleUp);
      break;

    case 'comment':
      return Icon(Icons.comment);
      break;

    case 'heartbeat':
      return Icon(FontAwesomeIcons.heart);
      break;

    default:
      return Icon(FontAwesomeIcons.star);
      break;
  }
}
