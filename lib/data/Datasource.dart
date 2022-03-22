import 'package:flutter/cupertino.dart';

class Video {
  final int id;
  final String author;
  final String title;
  final String thumbnailUrl;
  final String url;
  final String album;

  const Video(
      {@required this.id,
      @required this.author,
      @required this.title,
      @required this.thumbnailUrl,
      @required this.url,
      @required this.album});
}
