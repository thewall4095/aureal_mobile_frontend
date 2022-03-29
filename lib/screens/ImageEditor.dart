import 'package:flutter/material.dart';

class ImageEditor extends StatefulWidget {
  @override
  _ImageEditorState createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Image",
          textScaleFactor: 0.75,
        ),
        centerTitle: true,
      ),
    );
  }
}
