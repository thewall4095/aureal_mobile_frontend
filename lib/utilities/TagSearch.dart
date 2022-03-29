import 'dart:convert';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TagSearch extends StatefulWidget {
  static const String id = "TagSearch";

  @override
  _TagSearchState createState() => _TagSearchState();
}

class _TagSearchState extends State<TagSearch> {
  TextEditingController _controller;

  var tags = [];
  String word;

  void getTags() async {
    print('getting the tags');
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/getTag?word=$word';

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          tags = jsonDecode(response.body)['allTags'];
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _controller = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Search Tags",
            textScaleFactor: 0.75,
            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (var v in tags)
                    ListTile(
                      onTap: () {},
                      title: Container(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${v['name']}',
                            textScaleFactor: 0.75,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: SizeConfig.safeBlockHorizontal * 4),
                          ),
                        ),
                      ),
                      trailing: Icon(
                        Icons.radio_button_checked,
                        color: kActiveColor,
                      ),
                    )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                height: SizeConfig.safeBlockVertical * 5,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Container(
                          decoration: BoxDecoration(
                              color: kSecondaryColor,
                              borderRadius: BorderRadius.circular(30)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            child: TextField(
                              controller: _controller,
                              onTap: () {
                                setState(() {});
                              },
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      SizeConfig.safeBlockHorizontal * 3.2),
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Search upto 5 tag -->",
                                  hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: SizeConfig.safeBlockHorizontal *
                                          3.2)),
                              onChanged: (value) {
                                setState(() {
                                  word = value;
                                  print(word);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    CircleAvatar(
                      child: IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _controller.clear();
                          getTags();
                        },
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ));
  }
}
