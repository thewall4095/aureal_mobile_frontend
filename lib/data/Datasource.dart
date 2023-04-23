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
  final String createdAt;
  final String episodeImage;

  const Video(
      { this.id,
       this.author,
       this.title,
       this.thumbnailUrl,
       this.episodeImage,
       this.url,
       this.album,
       this.podcastid,
       this.author_id,
       this.permlink,
       this.createdAt});
}
