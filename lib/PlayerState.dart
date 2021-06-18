import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
// import 'package:music_player/music_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlayerState {
  playing,
  paused,
  stopped,
}

class PlayerChange extends ChangeNotifier {
  PlayerState state = PlayerState.playing;

  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  double position;

  var _episodeObject;
  var _currentPosition;

  String episodeName;
  String podcastName;
  String author;
  Duration duration;
  int id;
  String permlink = '';

  int currentIndex = 0;

  // MusicPlayer musicPlayer = MusicPlayer();
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  Dio dio = Dio();

  Map<String, dynamic> get episodeObject => _episodeObject;

//  set musicPlaylist(var newValue) {
//    _musicPlaylist = newValue;
//    notifyListeners();
//    print(_musicPlaylist);
//    print(_musicPlaylist.runtimeType);
//  }

  set episodeObject(var newValue) {
    _episodeObject = newValue;
    episodeName = _episodeObject['name'];
    podcastName = _episodeObject['podcast_name'];
    author = _episodeObject['author'];
//    duration = Duration(seconds: _episodeObject['duration'].toInt());
    id = _episodeObject['id'];
    permlink = _episodeObject['permlink'];

    notifyListeners();
  }

  void view() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/views';

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = _episodeObject['id'];

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  void play() {
    state = PlayerState.playing;
//    audioPlayer.play(kUrl, isLocal: false);
//    setState(() {
//      playerState = PlayerState.playing;
//    });
//    musicPlayer.play(
//      MusicItem(
//        trackName: '${_episodeObject['name']}',
//        albumName: '${_episodeObject['podcast_name']}',
//        artistName: '${_episodeObject['author']}',
//        url: _episodeObject['url'],
//        coverUrl: _episodeObject['image'],
//        duration: duration,
//      ),
//    );

    audioPlayer.open(
      Audio.network(_episodeObject['url'],
          metas: Metas(
            title: _episodeObject['name'],
            album: _episodeObject['podcast_name'],
            artist: _episodeObject['author'],
            image: MetasImage.network(_episodeObject['image']),
          )),
      showNotification: true,
      notificationSettings: NotificationSettings(
          nextEnabled: false, prevEnabled: false, seekBarEnabled: true),
    );


    // dursaver.getEpisodeDuration(_episodeObject['id']);

    view();


  }

  void stop() {
    state = PlayerState.stopped;
    audioPlayer.stop();
    print(
        '${audioPlayer.currentPosition.valueWrapper.value} ///////////////////////////////////////////////////////////////////');
    _currentPosition = audioPlayer.currentPosition.valueWrapper.value;
    if (audioPlayer.isPlaying == true) {
      print(episodeObject);
      dursaver.addToDatabase(
          episodeObject['id'], audioPlayer.currentPosition.valueWrapper.value);
    }
  }

  void pause() {
    MediaNotification.showNotification(
        title: _episodeObject['name'],
        author: _episodeObject['podcast_name'],
        isPlaying: false);
    state = PlayerState.paused;
    audioPlayer.pause();
    _currentPosition = audioPlayer.currentPosition.valueWrapper.value;
    dursaver.addToDatabase(
        _episodeObject['id'], audioPlayer.currentPosition.valueWrapper.value);
  }

  void resume() {
    state = PlayerState.playing;
    audioPlayer.play();
  }

  void seek(double position) {}
}
