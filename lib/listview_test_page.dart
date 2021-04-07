import 'package:flutter/material.dart';
import 'package:flutter_app/cache/WListView.dart';

class ListViewTestPage extends StatefulWidget {
  @override
  _ListViewTestPageState createState() => _ListViewTestPageState();
}

class _ListViewTestPageState extends State<ListViewTestPage> {
  List<int>? _list;

  @override
  void initState() {
    super.initState();
    _list = [];
    for (int i = 0; i < 20; i++) {
      _list?.add(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        body: Container(
          child: WListView.builder(
            itemBuilder: (_, index) {
              return Container(
                height: 200,
                child: Center(
                  child: Text('$index'),
                ),
              );
            },
            itemCount: _list?.length,
          ),
        ),
      ),
    );
  }
}
