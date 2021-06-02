import 'package:flutter_share/flutter_share.dart';

void share({var episodeObject}) async {
  // String sharableLink;

  await FlutterShare.share(
      title: '${episodeObject['podcast_name']}',
      text:
          "Hey There, I'm listening to ${episodeObject['name']} from ${episodeObject['podcast_name']} on Aureal, here's the link for you https://aureal.one/podcast/${episodeObject['podcast_id']}?episode_id=${episodeObject['id']}");
}
