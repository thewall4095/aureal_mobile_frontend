import 'dart:async';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audioplayer/audioplayer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auditory/Services/Interceptor.dart' as postreq;
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class SoundEditor extends StatefulWidget {
  static const String id = "SoundEditor";

  String userId;
  int libraryId;
  double soundDuration;
  String audioUrl;
  int episodeId;
  int associationId;

  SoundEditor(
      {this.userId,
      this.libraryId,
      this.soundDuration,
      this.audioUrl,
      this.episodeId,
      this.associationId});

  @override
  _SoundEditorState createState() => _SoundEditorState();
}

class _SoundEditorState extends State<SoundEditor> {
  AudioPlayer player = AudioPlayer();

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  final FlutterFFmpeg _fFmpeg = FlutterFFmpeg();

  bool loading = true;

  Color kSoundColor;
  Color kInterludeColor;

  bool playing = false;

  Dio dio = Dio();

  String userId;
  int libraryId;
  double soundDuration;
  String audioUrl;
  int episodeId;
  int associationId;

  double startTime;
  double endTime;

  Duration _duration = Duration();
  Duration _position = Duration();

  RangeValues _values;

  AudioPlayer advancedPlayer = AudioPlayer();

  ///////////////////////////////////////////////////////////////////------------To Set the values to be used in API------------------------/////////////////////////////////

  void setValues() {
    setState(() {
      userId = widget.userId;
      libraryId = widget.libraryId;
      soundDuration = widget.soundDuration;
      audioUrl = widget.audioUrl;
      _values = RangeValues(0.00, soundDuration);
      startTime = 0.00;
      endTime = soundDuration;
      episodeId = widget.episodeId;
      associationId = widget.associationId;
    });
    print(audioUrl);
  }

  String imagePath = '';

  void createAudiogram() async {
    setState(() {
      loading = true;
    });

    String customPath = 'aurealAudiogram';
    io.Directory appDocDirectory;

    if (io.Platform.isIOS) {
//      appDocDirectory = await getApplicationDocumentsDirectory();
      appDocDirectory = await getTemporaryDirectory();
    } else {
//      appDocDirectory = await getExternalStorageDirectory();
      appDocDirectory = await getTemporaryDirectory();
    }

    customPath = appDocDirectory.path +
        customPath +
        DateTime.now().millisecondsSinceEpoch.toString();

    _fFmpeg
        .execute(
            '-i ${audioUrl} -filter_complex showwavespic=colors=3F67F6 -frames:v 1 ${customPath}.png')
        .then((value) {
      setState(() {
        imagePath = '${customPath}.png';
      });
    });

    setState(() {
      loading = false;
    });
  }

  //////////////////////////////////////////////////////////////////-----------------Play Function-----------------/////////////////////////////////////////////////////
  Future _play(String url) async {
    player.play(url, isLocal: false);
    setState(() {
      playing = true;
    });
  }

  Future _stop() async {
    player.stop();
    setState(() {
      playing = false;
    });
  }

  //////////////////////////////////////////////////////////////////--------------------Trim API -----------------------//////////////////////////////////////////////////////

  void trimSound(
      String userId, int libraryId, double startTime, double endTime) async {
    postreq.Interceptor intercept = postreq.Interceptor();

    String url = "https://api.aureal.one/private/trimLibrary";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var map = Map<String, dynamic>();
    map['user_id'] = userId;
    map['library_id'] = libraryId;
    map['start_time'] = startTime;
    map['end_time'] = endTime;
    map['episode_id'] = episodeId;
    map['association_id'] = associationId;

    FormData formData = FormData.fromMap(map);
    try {
      var response = await intercept.postRequest(formData, url);
      print(response);
      Navigator.pop(context, 'done');
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setValues();
    createAudiogram();
    _positionSubscription = player.onAudioPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });
    _audioPlayerStateSubscription = player.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        setState(() {
          _duration = player.duration;
        });
      } else if (s == AudioPlayerState.STOPPED) {
        setState(() {
          _position = _duration;
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ModalProgressHUD(
      inAsyncCall: loading,
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.clear,
              color: Colors.white,
            ),
          ),
          title: Text("Sound Editor",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.safeBlockHorizontal * 4)),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                playing == false ? Icons.play_circle_filled : Icons.stop,
                color: Colors.white,
              ),
              onPressed: () {
                if (playing == false) {
                  _play(audioUrl.toString());
                } else {
                  _stop();
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Image.file(io.File(imagePath)),
              ),
            ),
            Center(
              child: Container(
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    activeTrackColor: Colors.blueAccent,
                    trackHeight: 100,
                  ),
                  child: Slider(
                    value: _position?.inMilliseconds?.toDouble() ?? 0.0,
                    onChanged: (double value) {
                      return player.seek((value / 1000).roundToDouble());
                    },
                    min: 0.0,
                    max: _duration.inMilliseconds.toDouble(),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbColor: Colors.white,
                    trackHeight: 100,
                    activeTrackColor: Colors.blueAccent.withOpacity(0.2),
                    inactiveTrackColor: Colors.transparent,
                  ),
                  child: RangeSlider(
                    values: _values,
                    min: 0.00,
                    max: soundDuration,
                    divisions: 100,
                    labels: RangeLabels('${_values.start}', '${_values.end}'),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _values = values;
                        startTime = _values.start;
                        endTime = _values.end;
                        print(startTime);
                        print(endTime);
                      });
                    },
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    trimSound(userId, libraryId, startTime, endTime);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    color: Color(0xff3F67F6),
                    child: Center(
                      child: Text(
                        'Save',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: SizeConfig.blockSizeHorizontal * 4),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
