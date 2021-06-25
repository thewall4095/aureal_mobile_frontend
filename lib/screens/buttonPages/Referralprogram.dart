import 'package:auditory/utilities/SizeConfig.dart';
import 'package:flutter/material.dart';

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
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListTile(
                    title: Text(
                      "Refer & Earn",
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontSize: SizeConfig.safeBlockHorizontal * 4,
                          fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                        "Refer your favourite podcasters and earn extra rewards when they join Aureal"),
                  ),
                ),
              ),
            ),
            TabBar(
              tabs: [
                Tab(
                  text: 'Join',
                ),
                Tab(
                  text: 'Share',
                ),
                Tab(
                  text: 'Earn',
                )
              ],
              controller: _controller,
            ),
            Container(
              height: MediaQuery.of(context).size.height / 2,
              child: TabBarView(
                children: [
                  Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text("Join")],
                    ),
                  ),
                  Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text("Share")],
                    ),
                  ),
                  Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text("Earn")],
                    ),
                  ),
                ],
                controller: _controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
