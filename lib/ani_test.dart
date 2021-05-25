import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class AniTest extends StatefulWidget {
  @override
  _AniTestState createState() => _AniTestState();
}

class _AniTestState extends State<AniTest> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _fractor = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 10),
        lowerBound: 0,
        upperBound: 1);
    Animation animation =
        CurvedAnimation(parent: _controller, curve: Curves.linear);
    animation.addListener(() {
      setState(() {
        _fractor = animation.value;
      });
      print('${animation.value}');
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        body: Container(
          height: double.infinity,
          width: double.infinity,
          child: Container(
            width: _fractor,
            height: _fractor,
            color: Colors.amber,
          ),
        ),
      ),
    );
  }
}
