import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class AniTest extends StatefulWidget {
  @override
  _AniTestState createState() => _AniTestState();
}

class _AniTestState extends State<AniTest> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    // 创建动画周期为 1 秒的 AnimationController 对象

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    // 将曲线应用到动画上
    CurvedAnimation curvedAnimation =
        CurvedAnimation(parent: controller, curve: Curves.decelerate);
    // 创建从 50 到 200 线性变化的 Animation 对象
    animation = Tween(begin: 50.0, end: 200.0).animate(curvedAnimation)
      ..addListener(() {
        setState(() {
          print('setState');
        }); // 刷新界面
      });
    // controller.addListener(() {
    //   setState(() {});
    // });
    controller.forward(); // 启动动画
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.reset();
        controller.forward();
      },
      child: Material(
        child: Scaffold(
          body: Center(
            child: Container(
              width: animation.value,
              height: animation.value,
              color: Colors.amber,
            ),
          ),
        ),
      ),
    );
  }
}
