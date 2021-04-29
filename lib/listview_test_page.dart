import 'dart:math';

import 'package:flutter/material.dart';

import 'cache/cache_sliver.dart';

class ListViewTestPage extends StatefulWidget {
  @override
  _ListViewTestPageState createState() => _ListViewTestPageState();
}

class _ListViewTestPageState extends State<ListViewTestPage> {
  List<int>? _list;
  List<String> _images = [
    'https://img0.baidu.com/it/u=1303767811,1952707109&fm=26&fmt=auto&gp=0.jpg',
    'https://img1.baidu.com/it/u=1909725915,1791135853&fm=26&fmt=auto&gp=0.jpg',
    'https://img2.baidu.com/it/u=4126017381,2536863291&fm=11&fmt=auto&gp=0.jpg',
    'https://img0.baidu.com/it/u=2688939523,4102709511&fm=11&fmt=auto&gp=0.jpg',
    'https://img1.baidu.com/it/u=1408105896,3860982095&fm=26&fmt=auto&gp=0.jpg',
    'https://img2.baidu.com/it/u=2830652229,440401769&fm=26&fmt=auto&gp=0.jpg'
  ];

  Random random = Random();

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
                color: Colors.black12,
                margin: EdgeInsets.only(top: 6),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(randomImage()),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(randomImage()),
                              )
                            ],
                          ),
                            flex: 1,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white30, width: 5),
                                      borderRadius: BorderRadius.all(Radius.circular(40))
                                  ),
                                  child: Text('btnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtn:$index'),
                                ),
                                Container(
                                  child: Text('btn:$index'),
                                ),
                                Container(
                                  child: Text('btn:$index'),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.lightBlue, width: 5),
                                      borderRadius: BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: Text('btnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtnbtn:$index', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.amber, width: 5),
                                      borderRadius: BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: Text('btn:$index'),
                                ),
                                TextField(
                                  decoration: InputDecoration(
                                      hintText: 'hint:$index'
                                  ),
                                )
                              ],

                            ),
                            flex: 1,
                          )
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 6),
                        width: double.infinity,
                        height: 1,
                        color: Colors.black87,
                      )

                    ],
                  )
              );
            },
            itemCount: _list?.length,
          ),
        ),
      ),
    );
  }

  String randomImage() {
    return _images[random.nextInt(6)];
  }
}
