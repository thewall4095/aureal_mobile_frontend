// import 'package:auditory/utilities/SizeConfig.dart';
// import 'package:flutter/material.dart';
// import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
//
// class PDFviewer extends StatefulWidget {
//   var episodeObject;
//
//   PDFviewer({ this.episodeObject});
//
//   @override
//   _PDFviewerState createState() => _PDFviewerState();
// }
//
// class _PDFviewerState extends State<PDFviewer> {
//   PDFDocument document;
//   bool _isLoading = true;
//
//   PageController _controller;
//
//   void loadDocument() async {
//     document = await PDFDocument.fromURL(widget.episodeObject['url']);
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     _controller = PageController();
//     loadDocument();
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text(
//           widget.episodeObject['name'],
//           textScaleFactor: 0.75,
//           style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
//         ),
//       ),
//       body: _isLoading
//           ? Center(
//               child: CircularProgressIndicator(),
//             )
//           : PDFViewer(
//               scrollDirection: Axis.vertical,
//               indicatorBackground: Colors.blue,
//               document: document,
//               zoomSteps: 1,
//             ),
//     );
//   }
// }
