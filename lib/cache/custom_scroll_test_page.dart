import 'package:flutter/material.dart';

class CustomScrollTestPage extends StatefulWidget {
  @override
  _CustomScrollTestPageState createState() => _CustomScrollTestPageState();
}

class _CustomScrollTestPageState extends State<CustomScrollTestPage> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        child:  CustomScrollView(
           slivers: <Widget>[
             const SliverAppBar(
               pinned: true,
               expandedHeight: 250.0,
               flexibleSpace: FlexibleSpaceBar(
                 title: Text('Demo'),
               ),
             ),
             SliverGrid(
               gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                 maxCrossAxisExtent: 200.0,
                 mainAxisSpacing: 10.0,
                 crossAxisSpacing: 10.0,
                 childAspectRatio: 4.0,
               ),
               delegate: SliverChildBuilderDelegate(
                 (BuildContext context, int index) {
                   return Container(
                     alignment: Alignment.center,
                     color: Colors.teal[100 * (index % 9)],
                     child: Text('Grid Item $index'),
                   );
                 },
                 childCount: 20,
               ),
             ),
             const SliverAppBar(
               pinned: true,
               expandedHeight: 250.0,
               flexibleSpace: FlexibleSpaceBar(
                 title: Text('Demo'),
               ),
             ),
             SliverFixedExtentList(
               itemExtent: 50.0,
               delegate: SliverChildBuilderDelegate(
                 (BuildContext context, int index) {
                   return Container(
                     alignment: Alignment.center,
                     color: Colors.lightBlue[100 * (index % 9)],
                     child: Text('List Item $index'),
                   );
                 },
               ),
             ),
           ],
         ),
      ),
    );
  }
}
