import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auditory/utilities/DurationDatabase.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
// import 'package:flutter_media_notification/flutter_media_notification.dart';
// import 'package:music_player/music_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/Datasource.dart';

enum PlayerState {
  playing,
  paused,
  stopped,
}

class PlayerChange extends ChangeNotifier {
  PlayerState state = PlayerState.playing;

  RecentlyPlayedProvider dursaver = RecentlyPlayedProvider.getInstance();

  double position;

  bool _isVideo;

  bool get isVideo => _isVideo;

  set isVideo(bool newValue) {
    _isVideo = newValue;
    notifyListeners();
  }

  var _episodeObject;
  var _currentPosition;

  List<Audio> _playList;

  bool _ifVoted;

  bool _isPlayListPlaying;

  String episodeName;
  String podcastName;
  String author;
  Duration duration;
  int id;
  String permlink = '';

  int currentIndex = 0;

  //VideoPlayer Controls

  // BetterPlayerController betterPlayerController =
  //     BetterPlayerController(BetterPlayerConfiguration(
  //   aspectRatio: 16 / 9,
  //   fit: BoxFit.contain,
  //   autoPlay: true,
  //   looping: false,
  //   allowedScreenSleep: false,
  //   autoDispose: false,
  //   deviceOrientationsAfterFullScreen: [
  //     DeviceOrientation.portraitDown,
  //     DeviceOrientation.portraitUp
  //   ],
  // ));
  // BetterPlayerDataSource betterPlayerDataSource;
  // BetterPlayerConfiguration betterPlayerConfiguration;

  // Future setVideoPlayerConfiguration() async {
  //   betterPlayerConfiguration = BetterPlayerConfiguration(
  //     aspectRatio: 16 / 9,
  //     fit: BoxFit.contain,
  //     autoPlay: true,
  //     looping: false,
  //     allowedScreenSleep: false,
  //     autoDispose: false,
  //     deviceOrientationsAfterFullScreen: [
  //       DeviceOrientation.portraitDown,
  //       DeviceOrientation.portraitUp
  //     ],
  //   );
  // }

  // Future setVideoPlayerDataSource() {
  //   betterPlayerDataSource = BetterPlayerDataSource(
  //     BetterPlayerDataSourceType.network,
  //     _episodeObject['url'],
  //     notificationConfiguration: BetterPlayerNotificationConfiguration(
  //       showNotification: true,
  //       title: "${_episodeObject['name']}",
  //       author: "${_episodeObject['author']}",
  //       imageUrl: _episodeObject['image'],
  //     ),
  //   );
  //   betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
  //   betterPlayerController.setupDataSource(betterPlayerDataSource);
  // }

  // MusicPlayer musicPlayer = MusicPlayer();
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  AssetsAudioPlayer snippetPlayer = AssetsAudioPlayer();

  MiniplayerController miniplayerController = MiniplayerController();
  Dio dio = Dio();

  Video _videoSource;

  Video get videoSource => _videoSource;

  set videoSource(Video newValue) {
    _videoSource = newValue;
    notifyListeners();
  }

  get episodeObject => _episodeObject;

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

  List<Audio> get playList => _playList;

  set playList(var newValue) {
    _playList = newValue;

    // notifyListeners();
    print(_playList);
  }

  set episodeObject(var newValue) {
    _episodeObject = newValue;
    notifyListeners();
  }

  void episodeViewed(var episodeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://api.aureal.one/public/views';

    var map = Map<String, dynamic>();
    map['user_id'] = prefs.getString('userId');
    map['episode_id'] = episodeId;

    FormData formData = FormData.fromMap(map);

    try {
      var response = await dio.post(url, data: formData);
      print(response.toString());
    } catch (e) {
      print(e);
    }
  }

  NotificationAction customNextAction(AssetsAudioPlayer audioplayer) {
    // if (playList.length > 1) {
    //   if (currentIndex != playList.length - 1) {
    //     print(
    //         "${_playList.indexOf(episodeObject)} /////////////////////////////////////////////////////////////");
    //     if (_playList.contains(episodeObject) == true) {
    //       episodeObject = _playList[_playList.indexOf(episodeObject) + 1];
    //       stop();
    //       play();
    //     }
    //   }
    // }
  }

  NotificationAction customPreviousAction(AssetsAudioPlayer audioplayer) {
    // if (playList.length > 1) {
    //   if (currentIndex != 0) {
    //     if (_playList.contains(episodeObject) == true) {
    //       episodeObject = _playList[_playList.indexOf(episodeObject) + 1];
    //       stop();
    //       play();
    //     }
    //   }
    // }
  }

  void play() async {
    Duration dur = await dursaver.getEpisodeDuration(episodeObject['id']);
    print(dur);
    print(dur.runtimeType);
    state = PlayerState.playing;

    audioPlayer.open(
      Audio.network(_episodeObject['url'],
          metas: Metas(
            title: _episodeObject['name'],
            album: _episodeObject['podcast_name'],
            artist: _episodeObject['author'],
            image: _episodeObject['image'] == null
                ? MetasImage.network(_episodeObject['podcast_image'])
                : MetasImage.network(_episodeObject['image']),
          )),
      seek: dur,
      showNotification: true,
      notificationSettings: NotificationSettings(
          // customNextAction: customNextAction,
          // customPrevAction: customPreviousAction,
          nextEnabled: true,
          prevEnabled: true,
          seekBarEnabled: true),
    );
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
