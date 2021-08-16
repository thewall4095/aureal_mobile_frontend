import 'package:flutter_share/flutter_share.dart';

import 'package:social_share/social_share.dart';
void share({var episodeObject}) async {
  // String sharableLink;

  await FlutterShare.share(
      title: '${episodeObject['podcast_name']}',
      text:
          "Hey There, I'm listening to ${episodeObject['name']} from ${episodeObject['podcast_name']} on Aureal, \n \nhere's the link for you https://aureal.one/episode/${episodeObject['id']}");
}
