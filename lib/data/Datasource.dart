import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Video {
  final int id;
  final String author;
  final String title;
  final String thumbnailUrl;
  final String url;
  final String album;
  final int podcastid;
  final String author_id;
  final String permlink;

  const Video(
      {@required this.id,
      @required this.author,
      @required this.title,
      @required this.thumbnailUrl,
      @required this.url,
      @required this.album,
      @required this.podcastid,
      @required this.author_id,
      @required this.permlink});
}
