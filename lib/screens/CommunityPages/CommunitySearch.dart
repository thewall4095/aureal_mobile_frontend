import 'package:auditory/CommunityProvider.dart';
import 'package:auditory/screens/CommunityPages/CommunityProfileView.dart';
import 'package:auditory/screens/Profiles/CategoryView.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'CommunityView.dart';

class CommunitySearch extends StatefulWidget {
  static const String id = "CommunitySearch";

  @override
  _CommunitySearchState createState() => _CommunitySearchState();
}

class _CommunitySearchState extends State<CommunitySearch>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  TextEditingController _controller;

  String searchString;

  List results = [];

  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(length: 3, vsync: this);
    _controller = TextEditingController();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var communities = Provider.of<CommunityProvider>(context);
    SizeConfig().init(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: TextField(
                enabled: true,
                onEditingComplete: () {
                  communities.communitySearch(_controller.value.text);
                },
                controller: _controller,
                onChanged: (value) {
                  setState(() {
                    searchString = value;
                  });
                },
                style: TextStyle(
            //        color: Colors.white,
                    fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                decoration: InputDecoration(enabled: true),
              ),
           //   backgroundColor: kPrimaryColor,
              pinned: true,
              expandedHeight: MediaQuery.of(context).size.height / 10,

              // flexibleSpace: FlexibleSpaceBar(
              //   background: Container(
              //     child: Column(
              //       children: [],
              //     ),
              //   ),
              // ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: Container(
                  height: 50,
                  width: double.infinity,
                //  color: kPrimaryColor,
                  child: communities.searchResults.toList().length != 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(colors: [
                                    Color(0xffE73B57),
                                    Color(0xff6048F6)
                                  ]).createShader(bounds);
                                },
                                child: Text(
                                  "Results",
                                  textScaleFactor: 0.75,
                                  style: TextStyle(
                                //      color: Colors.white,
                                      fontSize:
                                          SizeConfig.safeBlockHorizontal * 4),
                                ),
                              ),
                              InkWell(
                                  onTap: () {
                                    setState(() {
                                      searchString = null;
                                      communities.searchResults = [];
                                      _controller.clear();
                                    });
                                  },
                                  child: Icon(
                                    Icons.close,
                                 //   color: Colors.white,
                                  ))
                            ],
                          ),
                        )
                      : TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabs: [
                            Tab(
                              text: 'Explore',
                            ),
                            Tab(
                              text: 'Followed',
                            ),
                            Tab(
                              text: 'Your communities',
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: communities.searchResults.toList().length != 0
                ? GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      for (var v in communities.searchResults)
                        InkWell(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return CommunityView(communityObject: v);
                            }));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kSecondaryColor)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: v['profileImageUrl'] == null
                                      ? AssetImage('assets/images/Favicon.png')
                                      : NetworkImage(v['profileImageUrl']),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text(
                                    v['name'],
                                    textScaleFactor: 0.75,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      Container(
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            for (var v in communities.allCommunities)
                              InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return CommunityProfileView(
                                        communityObject: v);
                                  }));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: kSecondaryColor)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            v['profileImageUrl'] == null
                                                ? AssetImage(
                                                    'assets/images/Favicon.png')
                                                : NetworkImage(
                                                    v['profileImageUrl']),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          v['name'],
                                          textScaleFactor: 0.75,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            for (var v in communities.userCommunities)
                              InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return CommunityView(communityObject: v);
                                  }));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: kSecondaryColor)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            v['profileImageUrl'] == null
                                                ? AssetImage(
                                                    'assets/images/Favicon.png')
                                                : NetworkImage(
                                                    v['profileImageUrl']),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          v['name'],
                                          textScaleFactor: 0.75,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            for (var v in communities.userCreatedCommunities)
                              InkWell(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return CommunityView(communityObject: v);
                                  }));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: kSecondaryColor)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            v['profileImageUrl'] == null
                                                ? AssetImage(
                                                    'assets/images/Favicon.png')
                                                : NetworkImage(
                                                    v['profileImageUrl']),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          v['name'],
                                          textScaleFactor: 0.75,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: SizeConfig
                                                      .safeBlockHorizontal *
                                                  3),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(
          Icons.close,
          color: Colors.white,
        ),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: Colors.white,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Column(
      children: [],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
