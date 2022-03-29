import 'package:auditory/utilities/constants.dart';
import 'package:flutter/material.dart';

class PopError extends StatefulWidget {
  static const String id = "PopError";

  @override
  _PopErrorState createState() => _PopErrorState();
}

class _PopErrorState extends State<PopError> {
  static const TextStyle linkStyle = const TextStyle(
    decoration: TextDecoration.underline,
  );

  void _openUrl(String url) async {
    // Close the about dialog.
    Navigator.pop(context);
  }

  Widget home(BuildContext context) {
    return Container(
        //  height: 20,
        //  width: 20,
        child: Padding(
      padding: const EdgeInsets.all(60.0),
      child: AlertDialog(
        backgroundColor: kSecondaryColor,
        title: Image.asset("assets/images/animatedtick.gif"),
        // title:  Text('Errors',
        // style: TextStyle(
        //     color: Colors.white
        // ),),
        content: Column(
          children: <Widget>[
            _buildAboutText(),
            _buildLogoAttribution(),
          ],
        ),
        actions: <Widget>[
          Center(
            child: new FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              textColor: Colors.blue,
              child: Text(
                'Okay',
                textScaleFactor: 0.75,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildAboutText() {
    return Container();
    // return  RichText(
    //   text:TextSpan(
    //     text: 'UpVote Not Done',
    //     style: TextStyle(color: Colors.white),
    //   ),
    // );
  }

  Widget _buildLogoAttribution() {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 100.0),
      color: Colors.transparent,
      child: new Column(
        children: <Widget>[
          home(context),
        ],
      ),
    );
  }
}
