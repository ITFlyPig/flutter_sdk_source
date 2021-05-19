import 'package:flutter/material.dart';

///
/// 测试触摸事件
///
class EventTest extends StatefulWidget {
  @override
  _EventTestState createState() => _EventTestState();
}

class _EventTestState extends State<EventTest> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: GestureDetector(
      onVerticalDragCancel: () {
        print('onVerticalDragCancel');
      },
      onVerticalDragDown: (e) {
        print('onVerticalDragDown');
      },
      onVerticalDragEnd: (e) {
        print('onVerticalDragEnd');
      },
      onVerticalDragStart: (e) {
        print('onVerticalDragStart');
      },
      onVerticalDragUpdate: (e) {
        print('onVerticalDragUpdate');
      },
      child: Container(
        width: 100,
        height: 100,
        color: Colors.amber,
        child: GestureDetector(
          onTap: () {
            print('GestureDetector#onTap');
          },
          child: Container(
            width: 50,
            height: 50,
            color: Colors.lightBlue,
          ),
        ),
      ),
    ));
  }
}
