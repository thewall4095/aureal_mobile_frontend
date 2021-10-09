import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_media_notification/flutter_media_notification.dart';
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

  List _playList;

  bool _ifVoted;

  bool _isPlayListPlaying;

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

  bool get ifVoted => _ifVoted;

  bool get isPlaylistPlaying => _isPlayListPlaying;

  set isPlaylistPlaying(bool newValue) {
    _isPlayListPlaying = newValue;

    notifyListeners();
  }

  set ifVoted(bool newValue) {
    _ifVoted = newValue;
    notifyListeners();
  }

//  set musicPlaylist(var newValue) {
//    _musicPlaylist = newValue;
//    notifyListeners();
//    print(_musicPlaylist);
//    print(_musicPlaylist.runtimeType);
//  }

  List<dynamic> get playList => _playList;

  set playList(var newValue) {
    _playList = newValue;

    notifyListeners();
    print(_playList);
  }

  set episodeObject(var newValue) {
    _episodeObject = newValue;
    episodeName = _episodeObject['name'];
    podcastName = _episodeObject['podcast_name'];
    author = _episodeObject['author'];
//    duration = Duration(seconds: _episodeObject['duration'].toInt());
    id = _episodeObject['id'];
    permlink = _episodeObject['permlink'];
    _ifVoted = _episodeObject['ifVoted'];
    print("ifVoted is $ifVoted");

    notifyListeners();
  }

  void view() async {
    // if (dursaver.getEpisode(episodeObject['id']) == false) {
    //   print(
    //       '${dursaver.getEpisodeDuration(episodeObject['id'])} /////////////////////////////////////////////////////////////////////');
    // }
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

  NotificationAction customNextAction(AssetsAudioPlayer audioplayer) {
    if (currentIndex != playList.length - 1) {
      print(
          "${_playList.indexOf(episodeObject)} /////////////////////////////////////////////////////////////");
      episodeObject = _playList[_playList.indexOf(episodeObject) + 1];
      stop();
      play();
    }
  }

  NotificationAction customPreviousAction(AssetsAudioPlayer audioplayer) {
    if (currentIndex != 0) {
      episodeObject = _playList[_playList.indexOf(episodeObject) - 1];
      stop();
      play();
    }
  }

  void play() async {
    Duration dur = await dursaver.getEpisodeDuration(episodeObject['id']);
    print(dur);
    print(dur.runtimeType);
    state = PlayerState.playing;

    // currentIndex = _playList.indexOf(_episodeObject);
    // print(
    //     '$currentIndex ////////////////////////////////////////////////////////////////////');

    audioPlayer.open(
      Audio.network(_episodeObject['url'],
          metas: Metas(
            title: _episodeObject['name'],
            album: _episodeObject['podcast_name'],
            artist: _episodeObject['author'],
            image: MetasImage.network(_episodeObject['image']),
          )),
      seek: dur,
      showNotification: true,
      notificationSettings: NotificationSettings(
          customNextAction: customNextAction,
          customPrevAction: customPreviousAction,
          nextEnabled: true,
          prevEnabled: true,
          seekBarEnabled: true),
    );
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

    // if (dursaver.getEpisode(episodeObject['id']) == true) {
    //   print('The episode exists');
    //   print(jsonDecode(dursaver.getEpisode(episodeObject['id']).toString())[
    //       'currentPosition']);
    //
    // } else {
    //   audioPlayer.open(
    //     Audio.network(_episodeObject['url'],
    //         metas: Metas(
    //           title: _episodeObject['name'],
    //           album: _episodeObject['podcast_name'],
    //           artist: _episodeObject['author'],
    //           image: MetasImage.network(_episodeObject['image']),
    //         )),
    //     showNotification: true,
    //     notificationSettings: NotificationSettings(
    //         nextEnabled: false, prevEnabled: false, seekBarEnabled: true),
    //   );
    // }

    view();
  }

  void stop() {
    state = PlayerState.stopped;
    audioPlayer.stop();
    // print(
    //     '${audioPlayer.currentPosition.value} ///////////////////////////////////////////////////////////////////');
    _currentPosition = audioPlayer.currentPosition.value;
    if (audioPlayer.isPlaying == true) {
      var a = dursaver.getAllEpisodes();
      print(a.toString());

      dursaver.addToDatabase(
          episodeObject['id'],
          audioPlayer.currentPosition.value,
          audioPlayer.realtimePlayingInfos.value.duration);
    }
  }

  void pause() {
    // MediaNotification.showNotification(
    //     title: _episodeObject['name'],
    //     author: _episodeObject['podcast_name'],
    //     isPlaying: false);
    state = PlayerState.paused;
    audioPlayer.pause();
    _currentPosition = audioPlayer.currentPosition.value;
    dursaver.addToDatabase(
        _episodeObject['id'],
        audioPlayer.currentPosition.value,
        audioPlayer.realtimePlayingInfos.value.duration);
  }

  void resume() {
    state = PlayerState.playing;
    audioPlayer.play();
  }

  void seek(double position) {}
}
