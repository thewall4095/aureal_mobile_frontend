import 'package:flutter/material.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:auditory/screens/buttonPages/Profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Messages extends StatefulWidget {
  static const String id = "Messages";

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  String displayPicture;

  void getLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      displayPicture = prefs.getString('displayPicture');
    });
  }

  @override
  void initState() {
    getLocalData();
    // TODO: implement initState
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    //  backgroundColor: kPrimaryColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: displayPicture != null
                    ? CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(displayPicture),
                      )
                    : CircleAvatar(
                        radius: 14,
                        backgroundColor: kActiveColor,
                      ),
                onPressed: () {
                  Navigator.pushNamed(context, Profile.id);
                },
              ),
              expandedHeight: 170,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 0, 64),
                  height: 100,
                  alignment: Alignment.bottomLeft,
                  child: Text('Social',
                      textScaleFactor: 0.75,
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(70),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.white,
                    tabs: <Widget>[
                      Tab(
                        text: "Friends",
                      ),
                      Tab(
                        text: "Whispers",
                      )
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Positioned(
                  width: MediaQuery.of(context).size.width / 2.5,
                  left: 16,
                  bottom: 16,
                  child: RaisedButton(
                    onPressed: () {},
                    elevation: 5,
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.sort,
                          color: Colors.black54,
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Text(
                          "Sort & Filter",
                          textScaleFactor: 0.75,
                          style: TextStyle(color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            Center(
                child: Text(
              "Whispers",
              textScaleFactor: 0.75,
            )),
          ],
        ),
      ),
    );
  }
}
