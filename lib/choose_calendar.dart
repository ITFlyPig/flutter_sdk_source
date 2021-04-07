import 'package:flutter/material.dart';

///
/// 选择时间期间的日历控件
///
class ChooseCalendar extends StatefulWidget {
  final DateTime start;
  final DateTime end;

  const ChooseCalendar({Key key, @required this.start, @required this.end})
      : super(key: key);

  @override
  _ChooseCalendarState createState() => _ChooseCalendarState();
}

class _ChooseCalendarState extends State<ChooseCalendar> {
  Map<int, DateTime> _dateMap;
  DateTime _selStart;
  DateTime _selEnd;
  List<String> weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  @override
  void initState() {
    super.initState();
    _dateMap = Map();
    int index = 0;
    DateTime temp = DateTime.fromMillisecondsSinceEpoch(
        widget.start.millisecondsSinceEpoch);
    while (temp.year <= widget.end.year && temp.month <= widget.end.month) {
      _dateMap[index] = temp;
      if (temp.month + 1 <= 12) {
        temp = DateTime(temp.year, temp.month + 1);
      } else {
        temp = DateTime(temp.year + 1, 1);
      }
      index++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: Colors.amberAccent),
      child: Column(
        children: [
          _buildWeekday(),
          Expanded(
              child: ListView.builder(
            itemBuilder: (context, index) {
              return _buildMonth(index);
            },
            itemCount: _dateMap.length,
          ))
        ],
      ),
    );
  }

  Widget _buildWeekday() {
    return Container(
      width: double.infinity,
      child: Row(
        children: weekdays.map((week) {
          return Expanded(
              child: Center(
            child: Text('$week'),
          ));
        }).toList(),
      ),
    );
  }

  /// 月份对应的UI
  Widget _buildMonth(int index) {
    List<Widget> days = [];
    DateTime dateTime = _dateMap[index];
    //当前月份对应的天数
    int dayCount = DateTime(dateTime.year, dateTime.month + 1, 0).day;
    //计算最开始和最后一天分别是周几
    int firstWeekday = DateTime(dateTime.year, dateTime.month, 1).weekday;
    int lastWeekday = DateTime(dateTime.year, dateTime.month, dayCount).weekday;
    //填充开始空白的day
    if (firstWeekday < 7) {
      for (int i = 0; i < firstWeekday; i++) {
        days.add(Container(
          color: Colors.white,
        ));
      }
    }
    //构建day
    for (int i = 1; i <= dayCount; i++) {
      DateTime cur = DateTime(dateTime.year, dateTime.month, i);
      days.add(GestureDetector(
        onTap: () {
          print('点击');
          if (_selStart != null && _selEnd != null) {
            setState(() {
              _selEnd = null;
              _selStart = cur;
            });
          } else if (_selStart != null) {
            //如果有开始时间则判断选择的结束时间是否合理
            if (cur.millisecondsSinceEpoch - _selStart.millisecondsSinceEpoch >=
                24 * 60 * 60 * 1000) {
              setState(() {
                _selEnd = cur;
              });
            } else {
              setState(() {
                _selEnd = null;
                _selStart = null;
              });
            }
          } else {
            //如果没有开始时间，则当前选择的时间为开始时间
            setState(() {
              _selStart = cur;
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(color: _itemBg(cur)),
          child: Center(
            child: Text('$i'),
          ),
        ),
      ));
    }
    //填充剩余的空白day
    if (lastWeekday != 6) {
      int count = lastWeekday == 7 ? 6 : (6 - lastWeekday);
      for (int i = 0; i < count; i++) {
        days.add(Container(
          color: Colors.white,
        ));
      }
    }
    return GridView.count(
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: days,
      shrinkWrap: true,
    );
  }

  Color _itemBg(DateTime itemDateTime) {
    Color bgColor = Colors.white;
    print(
        'item的时间：$itemDateTime 选中的开始时间：${_selStart ?? 'null'}  选中的结束时间:${_selEnd ?? 'null'}');
    if (_selStart != null && _selEnd != null) {
      if (itemDateTime.millisecondsSinceEpoch >=
              _selStart.millisecondsSinceEpoch &&
          itemDateTime.millisecondsSinceEpoch <=
              _selEnd.millisecondsSinceEpoch) {
        //选中的时间
        bgColor = Colors.lightBlue;
      }
    } else if (_selStart != null && _selEnd == null) {
      //选中一个的情况
      if (itemDateTime.year == _selStart.year &&
          itemDateTime.month == _selStart.month &&
          itemDateTime.day == _selStart.day) {
        bgColor = Colors.lightBlue;
      }
    }
    return bgColor;
  }
}
