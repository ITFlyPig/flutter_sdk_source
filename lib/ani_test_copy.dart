import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class AniTest extends StatefulWidget {
  @override
  _AniTestState createState() => _AniTestState();
}

class _AniTestState extends State<AniTest> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<int> animation;

  @override
  void initState() {
    super.initState();
    // 创建动画周期为 1 秒的 AnimationController 对象

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    // 为动画添加非线性效果
    CurvedAnimation curvedAnimation =
        CurvedAnimation(parent: controller, curve: Curves.bounceInOut);
    // 修改动画值的类型和范围
    animation = Tween(begin: 100, end: 200).animate(curvedAnimation);
    // 添加监听
    animation.addListener(() {
      setState(() {});
    });
    // 开始动画
    controller.forward(); // 启动动画
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: animation.value as double,
      height: animation.value as double,
      color: Colors.amber,
    );
  }
}
