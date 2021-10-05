import 'package:auditory/screens/History.dart';
import 'package:auditory/screens/Player/Player.dart';
import 'package:auditory/screens/buttonPages/Downloads.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: (){  Navigator.push(context,
                  CupertinoPageRoute(builder: (context) {
                    return History();
                  }));},
              title: Text("History"),
              trailing: Icon(Icons.arrow_forward_ios),
            //  subtitle:Text("Your PlayList"),
              leading: Icon(Icons.history),
              contentPadding:EdgeInsets.all(5),
              horizontalTitleGap:5,
            ),
          ListTile(
            onTap: (){},
            title: Text("PlayList"),
            trailing: Icon(Icons.arrow_forward_ios),
         //   subtitle:Text("Your PlayList"),
            leading: Icon(Icons.play_arrow),
            contentPadding:EdgeInsets.all(5),
            horizontalTitleGap:5,
          ),
            ListTile(
              onTap: (){
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (context) {
                        return DownloadPage();
                      }));
                },
              title: Text("Downloads"),
              trailing: Icon(Icons.arrow_forward_ios),
            //  subtitle:Text("Your PlayList"),
              leading: Icon(Icons.download_outlined),
              contentPadding:EdgeInsets.all(5),
              horizontalTitleGap:5,
            ),
            ListTile(
              onTap: (){ Navigator.push(context,
                  CupertinoPageRoute(builder: (context) {
                    return ClipScreen();
                  }));},
              title: Text("Clips"),
              trailing: Icon(Icons.arrow_forward_ios),
             // subtitle:Text("Your PlayList"),
              leading: Icon(Icons.text_snippet),
              contentPadding:EdgeInsets.all(5),
              horizontalTitleGap:5,
            ),

          ],
        ),
      ),
    );
  }
}
