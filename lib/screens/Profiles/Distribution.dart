import 'dart:convert';

import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:http/http.dart' as http;

class Distribution extends StatefulWidget {
  var podcastObject;

  Distribution({@required this.podcastObject});

  @override
  _DistributionState createState() => _DistributionState();
}

class _DistributionState extends State<Distribution> {
  final GlobalKey<ScaffoldState> _scaffoldKeyDistribution =
      new GlobalKey<ScaffoldState>();

  void showInSnackBar(String value) {
    _scaffoldKeyDistribution.currentState.showSnackBar(new SnackBar(
        content: new Text(
      value,
      textScaleFactor: 0.75,
    )));
  }

  postreq.Interceptor intercept = postreq.Interceptor();

  void share() async {
    await FlutterShare.share(title: "Some Title");
  }

  String aurealLink = '';
  var platforms = [];

  void getDistributionSettings() async {
    print(widget.podcastObject.toString());
    String url =
        'https://api.aureal.one/public/distributionStatus?podcast_id=${widget.podcastObject['id']}';

    print(url);

    try {
      http.Response response = await http.get(Uri.parse(url));
      setState(() {
        aurealLink = jsonDecode(response.body)['allDistributions'][0]['link']
            .toString()
            .split("//")[1];
        platforms = jsonDecode(response.body)['allDistributions'];
      });
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getDistributionSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      key: _scaffoldKeyDistribution,
      appBar: AppBar(
        title: Text(
          "Distribution settings",
          textScaleFactor: 0.75,
          style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.blockSizeHorizontal * 4),
        ),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Container(
              color: kSecondaryColor,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Your Podcast Profile",
                      textScaleFactor: 0.75,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.safeBlockHorizontal * 3.4),
                    ),
                    Text(
                      "View",
                      textScaleFactor: 0.75,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.blockSizeHorizontal * 3.4),
                    )
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        print("Copying");
                        Clipboard.setData(ClipboardData(text: aurealLink));
                        showInSnackBar('Copied to Clipboard');
                      },
                      child: Row(
                        children: <Widget>[
                          Container(
                              height: SizeConfig.safeBlockVertical * 8,
                              width: SizeConfig.safeBlockHorizontal * 8,
                              child: Image.asset('assets/images/Favicon.png')),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            aurealLink,
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.safeBlockHorizontal * 3.4),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: share,
                      icon: Icon(
                        Icons.share,
                        size: 20,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Container(
              color: kSecondaryColor,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Available Listening platforms",
                      textScaleFactor: 0.75,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.safeBlockHorizontal * 3.4),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var v in platforms)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        child: v['platform_name'] == 'Aureal'
                            ? SizedBox(
                                height: 0,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    v['platform_name'],
                                    textScaleFactor: 0.75,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal *
                                                3.4),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Flexible(
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: kSecondaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(30)),
                                            width: double.maxFinite,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 15),
                                              child: Text(
                                                v['link'],
                                                textScaleFactor: 0.75,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: SizeConfig
                                                            .safeBlockHorizontal *
                                                        3.4),
                                              ),
                                            )),
                                      ),
                                      IconButton(
                                        onPressed: () {},
                                        icon: Icon(
                                          Icons.share,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                      )
                  ],
                ),
              ),
            ),
            Container(
              color: kSecondaryColor,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Pending listening platforms",
                      textScaleFactor: 0.75,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: SizeConfig.safeBlockHorizontal * 3.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
