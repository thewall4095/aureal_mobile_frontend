import 'dart:io';

import 'package:flutter_share/flutter_share.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

import 'package:social_share/social_share.dart';
void share({var episodeObject}) async {
  // String sharableLink;

  await FlutterShare.share(
      title: '${episodeObject['podcast_name']}',
      text:
          "Hey There, I'm listening to ${episodeObject['name']} from ${episodeObject['podcast_name']} on Aureal, \n \nhere's the link for you https://aureal.one/episode/${episodeObject['id']}");
}
void shareImage() async {
  String url="https://media.istockphoto.com/photos/underwater-view-with-tuna-school-fish-in-ocean-sea-life-in-water-picture-id1189904571?s=612x612";
  final response = await get(Uri.parse(url));
  final bytes = response.bodyBytes;
  final Directory temp = await getTemporaryDirectory();
  final File imageFile = File('${temp.path}/tempImage');
  imageFile.writeAsBytesSync(response.bodyBytes);
  Share.shareFiles(['${temp.path}/tempImage'], text: 'text to share',);
}