import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class V2ListView extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int? itemCount;

  const V2ListView({Key? key, required this.itemBuilder, this.itemCount})
      : super(key: key);

  @override
  _V2ListViewState createState() => _V2ListViewState();
}

class _V2ListViewState extends State<V2ListView> {
  List<Widget> _holders = [];
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
      //检查目前布局了的item，是否还有holder类型的
    });
    return ListView.builder(
      itemBuilder: (context, index) {
        Widget holder = _placeHolder(index);
        _holders.add(holder);
        return holder;
      },
      itemCount: widget.itemCount,
    );
  }

  // 占位widget
  Widget _placeHolder(int index) {
    return SizedBox(
      height: 200,
    );
  }

  Widget _realItem(int index) {
    return widget.itemBuilder(context, index);
  }
}

List<BuildContext> _holders = [];
bool _isScheduled = false;

void scheduleCheckHolderTask() {
  if (_isScheduled || _holders.length == 0) return;
  _isScheduled = true;
  print('scheduleCheckHolderTask 函数');
  // SchedulerBinding.instance!.addPostFrameCallback((time) {
  //   print('scheduleTask 里面的task开始运行，占位element数量：${_holders.length}');
  //   Element? element;
  //   for (int i = _holders.length - 1; i >= 0; i--) {
  //     element = _holders[i] as Element;
  //     break;
  //   }
  //
  //   element?.markNeedsBuild();
  //   _holders.remove(element);
  //   _isScheduled = false;
  // });

  SchedulerBinding.instance!.scheduleTask(() {
    print('scheduleTask 里面的task开始运行，占位element数量：${_holders.length}');
    Element? element;
    for (int i = _holders.length - 1; i >= 0; i--) {
      element = _holders[i] as Element;
      break;
    }

    element?.markNeedsBuild();
    _holders.remove(element);
    _isScheduled = false;
  }, Priority.animation);
}

class Holder extends StatefulWidget {
  final Widget child;

  const Holder({Key? key, required this.child}) : super(key: key);
  @override
  _HolderState createState() => _HolderState();
}

class _HolderState extends State<Holder> {
  @override
  void initState() {
    super.initState();
    _holders.add(context);
  }

  @override
  Widget build(BuildContext context) {
    scheduleCheckHolderTask();

    if (_holders.contains(context)) {
      print('build  构建placeholder');
      return _placeHolder();
    } else {
      print('build  构建正常的widget');
      return widget.child;
    }
  }

  // 占位widget
  Widget _placeHolder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.amber,
      margin: EdgeInsets.all(2),
    );
  }

  @override
  void deactivate() {
    super.deactivate();
    _holders.remove(context);
  }
}
