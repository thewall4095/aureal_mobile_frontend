import 'dart:convert';

import 'package:auditory/utilities/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TagSelector extends StatefulWidget {
  static const String id = 'TagSelection';
  var tags;

  TagSelector({@required tags});

  @override
  _TagSelectorState createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Add Tags",
          textScaleFactor: 0.75,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              setState(() {});
            },
            child: Center(
              child: Text(
                "Clear",
                textScaleFactor: 0.75,
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: ListView(
          children: <Widget>[
            for (var v in widget.tags)
              Text(
                v['name'],
                textScaleFactor: 0.75,
                style: TextStyle(color: Colors.white),
              )
          ],
        ),
      ),
    );
  }
}
