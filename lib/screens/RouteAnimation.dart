// import 'dart:async';
//
// import 'package:flutter/material.dart';
//
import 'dart:async';

import 'package:flutter/cupertino.dart';

class KupertinoPageRoute extends PageRouteBuilder {
  final Widget widget;
  KupertinoPageRoute({this.widget})
      : super(pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return widget;
        }, transitionsBuilder: (BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child) {
          return new SlideTransition(
            textDirection: TextDirection.ltr,
            position: new Tween<Offset>(
              begin: const Offset(
                1.0,
                0.0,
              ),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        });
}

class Animator extends StatefulWidget {
  final Widget child;
  final Duration time;
  Animator(this.child, this.time);
  @override
  _AnimatorState createState() => _AnimatorState();
}

class _AnimatorState extends State<Animator>
    with SingleTickerProviderStateMixin {
  Timer timer;
  AnimationController animationController;
  Animation animation;
  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    animation =
        CurvedAnimation(parent: animationController, curve: Curves.easeIn);
    timer = Timer(widget.time, animationController.forward);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (BuildContext context, Widget child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(2, (1 - animation.value) * 10),
            child: child,
          ),
        );
      },
    );
  }
}

Timer timer;
Duration duration = Duration();
wait() {
  if (timer == null || !timer.isActive) {
    timer = Timer(Duration(microseconds: 10), () {
      duration = Duration();
    });
  }
  duration += Duration(milliseconds: 50);
  return duration;
}

class WidgetANimator extends StatelessWidget {
  final Widget child;
  WidgetANimator(this.child);
  @override
  Widget build(BuildContext context) {
    return Animator(child, wait());
  }
}
