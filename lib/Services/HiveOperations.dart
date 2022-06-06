import 'dart:convert';

import 'package:auditory/utilities/SizeConfig.dart';
import 'package:auditory/utilities/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:slider_controller/slider_controller.dart';

import 'Interceptor.dart' as postreq;

void upvoteEpisode({String permlink, int episode_id, double weight}) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = 'https://api.aureal.one/public/voteEpisode';

  if (prefs.getString('HiveUserName') != null) {
    if (permlink != null) {
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['permlink'] = permlink;
      map['weight'] = weight;
      map['hive_username'] = prefs.getString('HiveUserName');
      map['episode_id'] = episode_id;

      FormData formData = FormData.fromMap(map);

      try {
        var response = await interceptor.postRequest(formData, url);
        print(response.toString());
      } catch (e) {
        print(e);
      }
    }
  } else {}
}

void downVoteEpisode({String permlink, int episode_id}) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (prefs.getString('HiveUserName') != null) {
    if (permlink != null) {
      String url = 'https://api.aureal.one/public/voteEpisode';
      var map = Map<String, dynamic>();
      map['user_id'] = prefs.getString('userId');
      map['permlink'] = permlink;
      map['weight'] = -10000;
      map['hive_username'] = prefs.getString('HiveUserName');
      map['episode_id'] = episode_id;

      FormData formData = FormData.fromMap(map);

      try {
        var response = await interceptor.postRequest(formData, url);
        print(response.toString());
      } catch (e) {
        print(e);
      }
    }
  } else {}
}

// void upVoteComment({@required String commentId, double weight}) async {
//   postreq.Interceptor interceptor = postreq.Interceptor();
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//
//   String url = 'https://api.aureal.one/public/voteComment';
//
//   var map = Map<String, dynamic>();
//   map['weight'] = weight;
//   map['hive_username'] = prefs.getString('HiveUserName');
//   map['comment_id'] = commentId;
//   map['user_id'] = prefs.getString('userId');
//
//   FormData formData = FormData.fromMap(map);
//
//   try {
//     var response = await interceptor.postRequest(formData, url);
//     print(response.toString());
//   } catch (e) {
//     print(e);
//   }
// }

Future upvoteComment({var weight, String author, String permlink}) async {
  postreq.Interceptor intercept = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = "https://api.aureal.one/public/voteComment";

  var map = Map<String, dynamic>();
  map['author_hive_username'] = author;
  map['hive_username'] = prefs.getString('HiveUserName');
  map['permlink'] = permlink;
  map['weight'] = weight;

  print(map);

  FormData formData = FormData.fromMap(map);

  try{
    await intercept.postRequest(formData, url).then((value) {
      print(value);
    });
  }catch(e){
    print(e);
  }

}

void publishManually(var episodeId) async {
  postreq.Interceptor interceptor = postreq.Interceptor();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = 'https://api.aureal.one/private/manualHivePublish';

  var map = Map<String, dynamic>();
  map['episode_id'] = episodeId;

  FormData formData = FormData.fromMap(map);

  var response = await interceptor.postRequest(formData, url);

  print(response.toString());
}

void downVoteComment(String commentId) async {
  postreq.Interceptor interceptor = postreq.Interceptor();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String url = 'https://api.aureal.one/public/voteComment';

  var map = Map<String, dynamic>();
  map['weight'] = 10000;
  map['hive_username'] = prefs.getString('HiveUserName');
  map['comment_id'] = commentId;
  map['user_id'] = prefs.getString('userId');

  FormData formData = FormData.fromMap(map);

  try {
    var response = await interceptor.postRequest(formData, url);
    print(response.toString());
  } catch (e) {
    print(e);
  }
}

Future getHiveData() async {
  postreq.Interceptor intercept = postreq.Interceptor();
  String url = 'https://api.aureal.one/public/clientMe';

  try {
    var response = await intercept.getRequest(url);
    print(response.runtimeType);
    print(response);
    // return jsonDecode(response);
  } catch (e) {
    print(e);
  }
}

void claimRewards() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  postreq.Interceptor intercept = postreq.Interceptor();

  String url = 'https://api.aureal.one/private/claimRewards';
  var map = Map<String, dynamic>();
  map['hive_username'] = prefs.getString('HiveUserName');
  map['user_id'] = prefs.getString('userId');

  FormData formData = FormData.fromMap(map);

  try {
    var response = await intercept.postRequest(formData, url);
    print(response);
  } catch (e) {
    print(e);
  }
}

class UpvoteEpisode extends StatefulWidget {
  String permlink;
  int episode_id;

  UpvoteEpisode({@required this.permlink, @required this.episode_id});

  @override
  _UpvoteEpisodeState createState() => _UpvoteEpisodeState();
}

class _UpvoteEpisodeState extends State<UpvoteEpisode> {
  double _value = 51.0;

  SharedPreferences prefs;

  double factor = 0.0000001;

  void getFactor() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/voteEstimate?hiveusername=${prefs.getString('HiveUserName')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      setState(() {
        factor = jsonDecode(response.body)['hive_estimate_factor'];
      });
    } catch (e) {}
  }

  @override
  void initState() {
    // TODO: implement initState
    getFactor();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(


      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: ShaderMask(
                shaderCallback: (Rect bounds){
                  return LinearGradient(
                    colors: [Color(0xff52BFF9),
                      Color(0xff6048F6)]
                  ).createShader(bounds);
                },
                child: Text(
                  "Rate this episode",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: SizeConfig.safeBlockHorizontal * 4),
                ),
              ),
              trailing: Text(
                '\$ ${((factor * _value) / 100).toStringAsPrecision(3)}',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.only(top: 10),
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 20),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         Text(
            //           "Rate this episode",
            //           style: TextStyle(
            //               color: Colors.white,
            //               fontSize: SizeConfig.safeBlockHorizontal * 3),
            //         ),
            //         Text(
            //           '\$ ${((factor * _value) / 100).toStringAsPrecision(3)}',
            //           style: TextStyle(
            //             color: Colors.white,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 30,
                  trackShape: GradientRectSliderTrackShape(darkenInactive: true, gradient: LinearGradient(colors: [Color(0xff52BFF9),
                    Color(0xff6048F6)]))

                ),
                child: Slider(
                  max: 100.0,
                  min: 1.0,
                  value: _value,
                  // activeColor: Colors.transparent,
                  // thumbColor: Colors.transparent,


                  onChanged: (value) {
                    setState(() {
                      _value = value;
                      print(_value);
                    });
                  },
                  onChangeEnd: (value) async {
                    Vibrate.feedback(FeedbackType.impact);
                    print("this is the final value: $value");
                    await upvoteEpisode(
                        permlink: widget.permlink,
                        episode_id: widget.episode_id,
                        weight: value * 100);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            SizedBox(height: 20,),



          ],
        ),
      ),
    );
  }
}

class UpvoteComment extends StatefulWidget {
  var data;

  UpvoteComment({@required this.data});

  @override
  _UpvoteCommentState createState() => _UpvoteCommentState();
}

class _UpvoteCommentState extends State<UpvoteComment> {
  double _value = 51.0;

  SharedPreferences prefs;

  double factor = 0.0000001;

  void getFactor() async {
    prefs = await SharedPreferences.getInstance();
    String url =
        'https://api.aureal.one/public/voteEstimate?hiveusername=${prefs.getString('HiveUserName')}';

    try {
      http.Response response = await http.get(Uri.parse(url));
      print(response.body);
      setState(() {
        factor = jsonDecode(response.body)['hive_estimate_factor'];
      });
    } catch (e) {}
  }

  @override
  void initState() {
    // TODO: implement initState
    getFactor();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: kSecondaryColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Your vote value:",
                            style: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3),
                          ),
                          Text(
                              '\$ ${((factor * _value) / 100).toStringAsPrecision(3)}'),
                        ],
                      ),
                    ),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                        trackHeight: 30,
                        trackShape: GradientRectSliderTrackShape(darkenInactive: true, gradient: LinearGradient(colors: [Color(0xff52BFF9),
                          Color(0xff6048F6)]))

                    ),
                    child: Slider(
                      max: 100.0,
                      min: 1.0,
                      value: _value,
                      onChanged: (value) {
                        print(widget.data);
                        setState(() {
                          _value = value;
                          print(_value);
                        });
                      },
                      onChangeEnd: (value) async {
                        print("this is the final value: $value");
                        await upvoteComment(permlink: widget.data['permlink'], author: widget.data['author'], weight: value * 100);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

class GradientRectSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  /// Based on https://www.youtube.com/watch?v=Wl4F5V6BoJw
  /// Create a slider track that draws two rectangles with rounded outer edges.
  final LinearGradient gradient;
  final bool darkenInactive;
  const GradientRectSliderTrackShape({ this.gradient: const LinearGradient(colors: [Colors.lightBlue, Colors.blue]), this.darkenInactive: true});

  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        @required RenderBox parentBox,
        @required SliderThemeData sliderTheme,
        @required Animation<double> enableAnimation,
        @required TextDirection textDirection,
        @required Offset thumbCenter,
        bool isDiscrete = false,
        bool isEnabled = false,
        double additionalActiveTrackHeight = 2,
      }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);
    // If the slider [SliderThemeData.trackHeight] is less than or equal to 0,
    // then it makes no difference whether the track is painted or not,
    // therefore the painting  can be a no-op.
    if (sliderTheme.trackHeight <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Assign the track segment paints, which are leading: active and
    // trailing: inactive.
    final ColorTween activeTrackColorTween = ColorTween(begin: sliderTheme.disabledActiveTrackColor, end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = darkenInactive
        ? ColorTween(begin: sliderTheme.disabledInactiveTrackColor, end: sliderTheme.inactiveTrackColor)
        : activeTrackColorTween;
    final Paint activePaint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..color = activeTrackColorTween.evaluate(enableAnimation);
    final Paint inactivePaint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..color = inactiveTrackColorTween.evaluate(enableAnimation);
    Paint leftTrackPaint;
    Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }
    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius = Radius.circular(trackRect.height / 2 + 1);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        (textDirection == TextDirection.ltr) ? trackRect.top - (additionalActiveTrackHeight / 2): trackRect.top,
        thumbCenter.dx,
        (textDirection == TextDirection.ltr) ? trackRect.bottom + (additionalActiveTrackHeight / 2) : trackRect.bottom,
        topLeft: (textDirection == TextDirection.ltr) ? activeTrackRadius : trackRadius,
        bottomLeft: (textDirection == TextDirection.ltr) ? activeTrackRadius: trackRadius,
      ),
      leftTrackPaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        (textDirection == TextDirection.rtl) ? trackRect.top - (additionalActiveTrackHeight / 2) : trackRect.top,
        trackRect.right,
        (textDirection == TextDirection.rtl) ? trackRect.bottom + (additionalActiveTrackHeight / 2) : trackRect.bottom,
        topRight: (textDirection == TextDirection.rtl) ? activeTrackRadius : trackRadius,
        bottomRight: (textDirection == TextDirection.rtl) ? activeTrackRadius : trackRadius,
      ),
      rightTrackPaint,
    );
  }
}
