import 'dart:convert';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  void getAurealRewardsTransactions() async {
    print('/////////////////////rewards api being called');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/getPoints?user_id=${prefs.getString('userId')}&page=$page&pageSize=$pageSize';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);

        setState(() {
          if (page == 0) {
            rewardsTransactions = jsonDecode(response.body)['points'];
          } else {
            rewardsTransactions =
                rewardsTransactions + jsonDecode(response.body)['points'];
          }

          page = page + 1;
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  var rewardsTransactions = [];

  void getHiveRewardData() async {
    // setState(() {
    //   isScreenLoading = true;
    // });
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
    // setState(() {
    //   isScreenLoading = false;
    // });
  }

  double x = 1892.98479;

  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(length: 4, vsync: this);
    getAurealRewardsTransactions();
    getHiveRewardData();
    getHiveTransactions();

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
    final mediaQueryData = MediaQuery.of(context);
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
            return [
              SliverAppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                expandedHeight: MediaQuery.of(context).size.height / 4,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: kSecondaryColor,
                          border: Border.all(color: Color(0xff171b27))
                          // color: Color(0xff171b27),
                          ),
                      child: SafeArea(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            Container(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '164.029 Points',
                                          style: TextStyle(
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  5),
                                        ),
                                        IconButton(
                                            icon: Icon(
                                                Icons.arrow_drop_down_circle),
                                            onPressed: () {})
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    child: Container(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('123.909'),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Icon(Icons.add_circle),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      child: TabBar(controller: _tabController, tabs: [
                        Tab(
                          child: Container(
                            width: MediaQuery.of(context).size.width / 4,
                            height: 10,
                            color: Colors.transparent,
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: MediaQuery.of(context).size.width / 4,
                            height: 10,
                            color: Colors.transparent,
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: MediaQuery.of(context).size.width / 4,
                            height: 10,
                            color: Colors.transparent,
                          ),
                        ),
                        Tab(
                          child: Container(
                            width: MediaQuery.of(context).size.width / 4,
                            height: 10,
                            color: Colors.transparent,
                          ),
                        ),
                      ]),
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
                    controller: _scrollRewardsController,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, int index) {
                      // return Text('${rewardsTransactions[index]}');
                      return Container(
                        child: ListTile(
                          minVerticalPadding: 10,
                          leading: iconGenerator(
                              rewardsTransactions[index]['action_type']),
                          title: Text(
                              'Points for ${rewardsTransactions[index]['action_type']}'),
                          subtitle: Text(
                              '${timeago.format(DateTime.parse(rewardsTransactions[index]['updatedAt']))}'),
                          trailing: Text(
                              '${double.parse(rewardsTransactions[index]['points'].toString())} points'),
                        ),
                      );
                    },
                    itemCount: rewardsTransactions.length,
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
                            color: kSecondaryColor,
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
                                        "${transferHive[index][1]['op'][1]['amount']}"),
                                  ],
                                ),
                                collapsed: Text(
                                  '${timeago.format(DateTime.parse(transferHive[index][1]['timestamp']))}',
                                  style: TextStyle(color: Color(0xff3a3a3a)),
                                ),
                                expanded: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${timeago.format(DateTime.parse(transferHive[index][1]['timestamp']))}',
                                      style:
                                          TextStyle(color: Color(0xff3a3a3a)),
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
                            color: kSecondaryColor,
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
                                  style: TextStyle(color: Color(0xff3a3a3a)),
                                ),
                                expanded: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Text(
                                        '${timeago.format(DateTime.parse(transferHBD[index][1]['timestamp']))}',
                                        style:
                                            TextStyle(color: Color(0xff3a3a3a)),
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

Widget iconGenerator(var action_type) {
  switch (action_type) {
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
