import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PublicProfile extends StatefulWidget {
  @override
  _PublicProfileState createState() => _PublicProfileState();
}

class _PublicProfileState extends State<PublicProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool isInnerBoxScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.ios_share),
                  onPressed: () {
                    print("profile pressed");
                  },
                )
              ],
              expandedHeight: MediaQuery.of(context).size.height / 2.3,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      color: Colors.blue,
                    )
                  ],
                ),
              ),
            )
          ];
        },
        body: Container(),
      ),
    );
  }
}
