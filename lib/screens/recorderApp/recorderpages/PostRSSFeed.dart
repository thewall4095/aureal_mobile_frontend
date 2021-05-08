import 'package:auditory/Services/EmailVerificationDialog.dart';
import 'package:auditory/screens/buttonPages/Profile.dart';
import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;

//https://api.aureal.one/private/getSubmittedRssFeeds?user_id=925eaf6a6cfec06c058f922c6e6a9c15

class PostRSSFeed extends StatefulWidget {
  static const String id = 'PostRSSFeed';
  @override
  _PostRSSFeedState createState() => _PostRSSFeedState();
}

class _PostRSSFeedState extends State<PostRSSFeed> {
  postreq.Interceptor intercept = postreq.Interceptor();
  TabController _tabController;
  bool isLoading;
  Dio dio = Dio();

  void sendOTP() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url =
        "https://api.aureal.one/private/getSubmittedRssFeeds?user_id=${prefs.getString('userId')}";
    var map = Map<String, dynamic>();

    FormData formData = FormData.fromMap(map);

    var response = await intercept.postRequest(formData, url);
    print(response.toString());

    setState(() {
      isLoading = false;
    });
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Center(
          child: Text(
            "Your Podcast's",
            style: TextStyle(
                color: Colors.white,
                fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
        ),
      ),
      body: Column(children: [
        Row(
          children: [
            Container(
              //  height: 40, width: 40,
              height: 100,
              //  alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 0, 64),
                child: Text("Podcast Details",
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 6,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.only(left: 80, bottom: 50),
                child: FlatButton(
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                              child: EmailVerificationDialog(
                            username: prefs.getString('username'),
                          ));
                        });
                  },
                  color: Colors.white,
                  child: Text("Post"),
                ),
              ),
            ),
          ],
        ),
        Container(
          child: Row(children: <Widget>[
            DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Text(
                    'Title',
                    style: TextStyle(
                        color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Duration',
                    style: TextStyle(
                        color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                        color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              rows: const <DataRow>[
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('Sarah')),
                    DataCell(Text('19')),
                    DataCell(Text('Student')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('Janine')),
                    DataCell(Text('43')),
                    DataCell(Text('Professor')),
                  ],
                ),
                DataRow(
                  cells: <DataCell>[
                    DataCell(Text('William')),
                    DataCell(Text('27')),
                    DataCell(Text('Associate Professor')),
                  ],
                ),
              ],
            )
          ]),
        ),
      ]),
    );
  }
}
