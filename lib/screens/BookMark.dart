//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
//
//
// class BookmarksPage extends StatefulWidget {
//   @override
//   _BookmarksPageState createState() => _BookmarksPageState();
// }
//
// class _BookmarksPageState extends State<BookmarksPage> {
//   @override
//   Widget build(BuildContext context) {
//     var bookmarkBloc = Provider.of<BookmarkBloc>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Bookmarks"),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             ListView.builder(
//               itemCount: bookmarkBloc.episodeList.length,
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(bookmarkBloc.episodeList[index].name ?? 'Eposide'),
//                   subtitle: Text(bookmarkBloc.episodeList[index].url ?? 'default'),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// class BookmarkBloc extends ChangeNotifier {
//   int _count = 2;
//   List<ItemModel> episodeList = [];
//
//   void addCount() {
//     _count++;
//     notifyListeners();
//   }
//
//   void addItems(ItemModel data) {
//    episodeList.add(data);
//     notifyListeners();
//   }
//
//   int get count {
//     return _count;
//   }
//
//   List<ItemModel> get episode {
//     return episodeList;
//   }
// }
//
// class ItemModel {
//   String name;
//   String url;
//
//   ItemModel({this.name, this.url});
// }
