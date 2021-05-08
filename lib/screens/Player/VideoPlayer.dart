import 'package:auditory/utilities/SizeConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';

class PodcastVideoPlayer extends StatefulWidget {
  var episodeObject;

  PodcastVideoPlayer({this.episodeObject});

  @override
  _PodcastVideoPlayerState createState() => _PodcastVideoPlayerState();
}

class _PodcastVideoPlayerState extends State<PodcastVideoPlayer> {
  VideoPlayerController _controller;

  @override
  void initState() {
    // TODO: implement initState
    print(widget.episodeObject['url'].toString());
    super.initState();
    _controller = VideoPlayerController.network(widget.episodeObject['url'])
      ..initialize().then((value) {
        setState(() {});
      });
    _controller.play();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.pause();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
            child: _controller.value.initialized
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        },
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Text(
                          widget.episodeObject['name'],
                          textScaleFactor: 0.75,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        child: Text(
                          widget.episodeObject['podcast_name'],
                          textScaleFactor: 0.75,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: SizeConfig.safeBlockHorizontal * 3.2),
                        ),
                      ),
                      widget.episodeObject['description'] == null
                          ? SizedBox(
                              height: 0,
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 5),
                              child: Text(
                                widget.episodeObject['description'],
                                textScaleFactor: 0.75,
                              ),
                            )
                    ],
                  )
                : Container(
                    child: SpinKitPulse(
                      color: Colors.blue,
                    ),
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/Thumbnail.png'))),
                  )),
      ),
      floatingActionButton: FloatingActionButton(
        child: _controller.value.isPlaying
            ? Icon(
                Icons.pause,
                color: Colors.white,
              )
            : Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
      ),
    );
  }
}
