
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

class SliverMultiBoxAdaptorElementWithCache extends SliverMultiBoxAdaptorElement implements WRenderSliverBoxChildManager{

  final List<Element> _elementCache = <Element>[];
  int _next = 0;
  bool _shouldPlaceHolder = false;
  List<int> _placeHolders = [];//记录目前使用简单配置创建的index

  SliverMultiBoxAdaptorElementWithCache(SliverMultiBoxAdaptorWidget widget) : super(widget);

  @override
  void mount(Element? parent, newSlot) {
    super.mount(parent, newSlot);

  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, newSlot) {
    // return super.updateChild(child, newWidget, newSlot);
    // 如果newWidget未null，表示需要移除对应的element
    // 将移除的element放入到cache

    if (child != null && newWidget == null) {//删除element
      print('需要删除element');
      // 将renderobject从child list移除
      child.detachRenderObject();
      child.deactivate();
      // 放入到cache中
      _elementCache.add(child);
      print('删除element，当前缓存个数:${_elementCache.length}');
      return null;
    } else if (child == null && newWidget != null) {//需要创建element

      // 如果现在时间比较紧张，则使用简单的widget去创建element

      //尝试从cache中获取，参考_retakeInactiveElement的逻辑来编写

      // 遍历cache，获取能使用newWidget更新的element
      print('需要创建一个element');

      Element? cachedElement;
      for(int i = 0; i < _elementCache.length; i++) {
        //如果最后一个都还未找到，直接使用
        if (i == _elementCache.length - 1) {
          cachedElement = _elementCache.removeAt(_elementCache.length - 1);

        } else if (Widget.canUpdate(_elementCache[i].widget, newWidget)) {//尽量寻找可以更新的
          cachedElement = _elementCache.removeAt(i);
          break;
        }
      }

      //未找到，则直接使用原来的方法创建一个
      if (cachedElement == null) {
        //确定使用原来的还是替换了，使用简单的widget
        // if (_hasSufficientTime()) {
        //   // 还是使用原来的配置
        //   print('使用原来的配置');
        // } else {
        //   print('使用简单的配置');
        //   // 使用简单的配置widget
        //   WSliverChildBuilderDelegate delegate = widget.delegate as WSliverChildBuilderDelegate;
        //   newWidget = delegate.buildPlaceHolder(this, newSlot);
        //   //因为使用站位的配置，所以这里标记还需要刷新
        //   // markNeedsBuild();
        //   SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
        //     markNeedsBuild();
        //   });
        // }

        if (!_shouldPlaceHolder) {
          _shouldPlaceHolder = true;
          print('使用原来的配置');
        } else {
          print('使用简单的配置');
          WSliverChildBuilderDelegate delegate = widget.delegate as WSliverChildBuilderDelegate;
          newWidget = delegate.buildPlaceHolder(this, newSlot);
          if (!_placeHolders.contains(newSlot)) {
            _placeHolders.add(newSlot);
          }
          SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
            markNeedsBuild();
            _shouldPlaceHolder = false;
            print('一帧结束');
          });
        }

        return super.updateChild(child, newWidget, newSlot);

      } else {//找到缓存的element
        print('使用找到的缓存，当前缓存个数：${_elementCache.length}');
        cachedElement.attachRenderObject(newSlot);
        cachedElement.activate();
        Element? newElement = super.updateChild(cachedElement, newWidget, newSlot);
        print('从缓存获取到的element：${cachedElement.hashCode}, updateChild更新后返回的element：${newElement?.hashCode}');
        return newElement;
      }
    } else {
      print('更新element');
      Element? updatedElement;
      if (!_placeHolders.contains(newSlot)) {
        //使用原来的配置更新
        print('使用原来配置更新element');
      } else {
        if (!_shouldPlaceHolder) {
          _placeHolders.remove(newSlot);
          _shouldPlaceHolder = true;
          //使用原来的配置更新
          print('使用原来配置更新element');
        } else {
          //还是使用简单的配置更新
          print('使用简单配置更新element');
          WSliverChildBuilderDelegate delegate = widget.delegate as WSliverChildBuilderDelegate;
          newWidget = delegate.buildPlaceHolder(this, newSlot);
          if (!_placeHolders.contains(newSlot)) {
            _placeHolders.add(newSlot);
          }

          SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
            _shouldPlaceHolder = false;
            markNeedsBuild();
            print('一帧结束');
          });
        }
      }
      updatedElement = super.updateChild(child, newWidget, newSlot);

      return updatedElement;
    }

  }

  @override
  void insertAndLayoutChildCost(int index, Duration cost) {
    print('insertAndLayoutChildCost消耗的时间：${cost.inMilliseconds} child的索引：$index');
    //将消耗的时间
    _totalCost += cost.inMilliseconds;
  }

  /// 是否还有充足的时间
  bool _hasSufficientTime() {
    // print('是否还有足够的时间：${_totalCost < 16}  当前总的花费时间:$_totalCost');
    // return _totalCost < 16;
    return _shouldPlaceHolder;
  }

  int _totalCost = 0;
  @override
  void startLayout() {
    _totalCost = 0;
  }
}


//=============================================================WSliverList=======================================================================

class WSliverList extends SliverList {
  const WSliverList({
    Key? key,
    required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  SliverMultiBoxAdaptorElement createElement() {
    return SliverMultiBoxAdaptorElementWithCache(this);
  }

  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return WRenderSliverList(childManager: element);
  }
}

//=============================================================WRenderSliverList=======================================================================
//主要实现布局和绘制的RenderObject
class WRenderSliverList extends RenderSliverList {
  late WRenderSliverBoxChildManager _childManager;

  WRenderSliverList({
    required RenderSliverBoxChildManager childManager,
  }) : super(childManager: childManager) {
    _childManager = childManager as WRenderSliverBoxChildManager;
  }


  @override
  bool addInitialChild({int index = 0, double layoutOffset = 0.0}) {

    DateTime pre = DateTime.now();
    bool? res = super.addInitialChild(index: index, layoutOffset: layoutOffset);
    DateTime now = DateTime.now();
    //计算插入和布局一个child所消耗的时间
    Duration diff = now.difference(pre);
    _childManager.insertAndLayoutChildCost(0, diff);
    return res;
  }


  @override
  RenderBox? insertAndLayoutChild(BoxConstraints childConstraints, {required RenderBox? after, bool parentUsesSize = false}) {
    DateTime pre = DateTime.now();
    RenderBox? child = super.insertAndLayoutChild(childConstraints, after: after, parentUsesSize: parentUsesSize );
    DateTime now = DateTime.now();
    //计算插入和布局一个child所消耗的时间
    Duration diff = now.difference(pre);
    if (child != null) {
      _childManager.insertAndLayoutChildCost(indexOf(child), diff);
    }
    return child;
  }

  @override
  RenderBox? insertAndLayoutLeadingChild(BoxConstraints childConstraints, {bool parentUsesSize = false}) {
    DateTime pre = DateTime.now();
    RenderBox? child = super.insertAndLayoutLeadingChild(childConstraints, parentUsesSize: parentUsesSize);
    DateTime now = DateTime.now();
    //计算插入和布局一个child所消耗的时间
    Duration diff = now.difference(pre);
    if (child != null) {
      _childManager.insertAndLayoutChildCost(indexOf(child), diff);
    }
    return child;
  }

  @override
  void performLayout() {
    _childManager.startLayout();
    super.performLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
  }
}

//=============================================================WRenderSliverBoxChildManager=======================================================================
// 增强的能力
abstract class WRenderSliverBoxChildManager extends RenderSliverBoxChildManager {

  /// 增加和布局一个child所消耗的时间
  void insertAndLayoutChildCost(int index,Duration cost);
  /// 布局开始的回调
  void startLayout();

}


//=====================================================================WListView===============================================================
class WListView extends BoxScrollView {
  /// Creates a scrollable, linear array of widgets from an explicit [List].
  ///
  /// This constructor is appropriate for list views with a small number of
  /// children because constructing the [List] requires doing work for every
  /// child that could possibly be displayed in the list view instead of just
  /// those children that are actually visible.
  ///
  /// Like other widgets in the framework, this widget expects that
  /// the [children] list will not be mutated after it has been passed in here.
  /// See the documentation at [SliverChildListDelegate.children] for more details.
  ///
  /// It is usually more efficient to create children on demand using
  /// [ListView.builder] because it will create the widget children lazily as necessary.
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. The
  /// `addSemanticIndexes` argument corresponds to the
  /// [SliverChildListDelegate.addSemanticIndexes] property. None
  /// may be null.
  WListView({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    this.itemExtent,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) : childrenDelegate = SliverChildListDelegate(
    children,
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: addRepaintBoundaries,
    addSemanticIndexes: addSemanticIndexes,
  ),
        super(
        key: key,
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        cacheExtent: cacheExtent,
        semanticChildCount: semanticChildCount ?? children.length,
        dragStartBehavior: dragStartBehavior,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
      );

  /// Creates a scrollable, linear array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for list views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [ListView] to
  /// estimate the maximum scroll extent.
  ///
  /// The `itemBuilder` callback will be called only with indices greater than
  /// or equal to zero and less than `itemCount`.
  ///
  /// The `itemBuilder` should always return a non-null widget, and actually
  /// create the widget instances when called. Avoid using a builder that
  /// returns a previously-constructed widget; if the list view's children are
  /// created in advance, or all at once when the [ListView] itself is created,
  /// it is more efficient to use the [ListView] constructor. Even more
  /// efficient, however, is to create the instances on demand using this
  /// constructor's `itemBuilder` callback.
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
  /// `addSemanticIndexes` argument corresponds to the
  /// [SliverChildBuilderDelegate.addSemanticIndexes] property. None may be
  /// null.
  ///
  /// [ListView.builder] by default does not support child reordering. If
  /// you are planning to change child order at a later time, consider using
  /// [ListView] or [ListView.custom].
  WListView.builder({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    this.itemExtent,
    required IndexedWidgetBuilder itemBuilder,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) : assert(itemCount == null || itemCount >= 0),
        assert(semanticChildCount == null || semanticChildCount <= itemCount!),
        childrenDelegate = WSliverChildBuilderDelegate(
          null,
          itemBuilder,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        ),
        super(
        key: key,
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        cacheExtent: cacheExtent,
        semanticChildCount: semanticChildCount ?? itemCount,
        dragStartBehavior: dragStartBehavior,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
      );

  /// Creates a fixed-length scrollable linear array of list "items" separated
  /// by list item "separators".
  ///
  /// This constructor is appropriate for list views with a large number of
  /// item and separator children because the builders are only called for
  /// the children that are actually visible.
  ///
  /// The `itemBuilder` callback will be called with indices greater than
  /// or equal to zero and less than `itemCount`.
  ///
  /// Separators only appear between list items: separator 0 appears after item
  /// 0 and the last separator appears before the last item.
  ///
  /// The `separatorBuilder` callback will be called with indices greater than
  /// or equal to zero and less than `itemCount - 1`.
  ///
  /// The `itemBuilder` and `separatorBuilder` callbacks should always return a
  /// non-null widget, and actually create widget instances when called. Avoid
  /// using a builder that returns a previously-constructed widget; if the list
  /// view's children are created in advance, or all at once when the [ListView]
  /// itself is created, it is more efficient to use the [ListView] constructor.
  ///
  /// {@tool snippet}
  ///
  /// This example shows how to create [ListView] whose [ListTile] list items
  /// are separated by [Divider]s.
  ///
  /// ```dart
  /// ListView.separated(
  ///   itemCount: 25,
  ///   separatorBuilder: (BuildContext context, int index) => Divider(),
  ///   itemBuilder: (BuildContext context, int index) {
  ///     return ListTile(
  ///       title: Text('item $index'),
  ///     );
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
  /// `addSemanticIndexes` argument corresponds to the
  /// [SliverChildBuilderDelegate.addSemanticIndexes] property. None may be
  /// null.
  WListView.separated({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) : assert(itemBuilder != null),
        assert(separatorBuilder != null),
        assert(itemCount != null && itemCount >= 0),
        itemExtent = null,
        childrenDelegate = SliverChildBuilderDelegate(
              (BuildContext context, int index) {
            final int itemIndex = index ~/ 2;
            final Widget widget;
            if (index.isEven) {
              widget = itemBuilder(context, itemIndex);
            } else {
              widget = separatorBuilder(context, itemIndex);
              assert(() {
                if (widget == null) { // ignore: dead_code
                  throw FlutterError('separatorBuilder cannot return null.');
                }
                return true;
              }());
            }
            return widget;
          },
          childCount: _computeActualChildCount(itemCount),
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          semanticIndexCallback: (Widget _, int index) {
            return index.isEven ? index ~/ 2 : null;
          },
        ),
        super(
        key: key,
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        cacheExtent: cacheExtent,
        semanticChildCount: itemCount,
        dragStartBehavior: dragStartBehavior,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
      );

  /// Creates a scrollable, linear array of widgets with a custom child model.
  ///
  /// For example, a custom child model can control the algorithm used to
  /// estimate the size of children that are not actually visible.
  ///
  /// {@tool snippet}
  ///
  /// This [ListView] uses a custom [SliverChildBuilderDelegate] to support child
  /// reordering.
  ///
  /// ```dart
  /// class MyListView extends StatefulWidget {
  ///   @override
  ///   _MyListViewState createState() => _MyListViewState();
  /// }
  ///
  /// class _MyListViewState extends State<MyListView> {
  ///   List<String> items = <String>['1', '2', '3', '4', '5'];
  ///
  ///   void _reverse() {
  ///     setState(() {
  ///       items = items.reversed.toList();
  ///     });
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Scaffold(
  ///       body: SafeArea(
  ///         child: ListView.custom(
  ///           childrenDelegate: SliverChildBuilderDelegate(
  ///             (BuildContext context, int index) {
  ///               return KeepAlive(
  ///                 data: items[index],
  ///                 key: ValueKey<String>(items[index]),
  ///               );
  ///             },
  ///             childCount: items.length,
  ///             findChildIndexCallback: (Key key) {
  ///               final ValueKey valueKey = key as ValueKey;
  ///               final String data = valueKey.value;
  ///               return items.indexOf(data);
  ///             }
  ///           ),
  ///         ),
  ///       ),
  ///       bottomNavigationBar: BottomAppBar(
  ///         child: Row(
  ///           mainAxisAlignment: MainAxisAlignment.center,
  ///           children: <Widget>[
  ///             TextButton(
  ///               onPressed: () => _reverse(),
  ///               child: Text('Reverse items'),
  ///             ),
  ///           ],
  ///         ),
  ///       ),
  ///     );
  ///   }
  /// }
  ///
  /// class KeepAlive extends StatefulWidget {
  ///   const KeepAlive({
  ///     required Key key,
  ///     required this.data,
  ///   }) : super(key: key);
  ///
  ///   final String data;
  ///
  ///   @override
  ///   _KeepAliveState createState() => _KeepAliveState();
  /// }
  ///
  /// class _KeepAliveState extends State<KeepAlive> with AutomaticKeepAliveClientMixin{
  ///   @override
  ///   bool get wantKeepAlive => true;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     super.build(context);
  ///     return Text(widget.data);
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  const WListView.custom({
    Key? key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    this.itemExtent,
    required this.childrenDelegate,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) : assert(childrenDelegate != null),
        super(
        key: key,
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        cacheExtent: cacheExtent,
        semanticChildCount: semanticChildCount,
        dragStartBehavior: dragStartBehavior,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
      );

  /// If non-null, forces the children to have the given extent in the scroll
  /// direction.
  ///
  /// Specifying an [itemExtent] is more efficient than letting the children
  /// determine their own extent because the scrolling machinery can make use of
  /// the foreknowledge of the children's extent to save work, for example when
  /// the scroll position changes drastically.
  final double? itemExtent;

  /// A delegate that provides the children for the [ListView].
  ///
  /// The [ListView.custom] constructor lets you specify this delegate
  /// explicitly. The [ListView] and [ListView.builder] constructors create a
  /// [childrenDelegate] that wraps the given [List] and [IndexedWidgetBuilder],
  /// respectively.
  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    if (itemExtent != null) {
      return SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: itemExtent!,
      );
    }
    return WSliverList(delegate: childrenDelegate);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('itemExtent', itemExtent, defaultValue: null));
  }

  // Helper method to compute the actual child count for the separated constructor.
  static int _computeActualChildCount(int itemCount) {
    return math.max(0, itemCount * 2 - 1);
  }
}

//=====================================================================WSliverChildDelegate===============================================================
typedef PlaceHolderBuilder = Widget? Function(BuildContext context, int index);
int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

/// 创建child的代理，增强能力，增加placeholder child的创建
abstract class WSliverChildDelegate extends SliverChildDelegate {

  Widget? buildPlaceHolder(BuildContext context, int index);
}


class WSliverChildBuilderDelegate extends SliverChildBuilderDelegate implements WSliverChildDelegate{
  //不传PlaceHolderBuilder就表示不需要分帧功能
  PlaceHolderBuilder? placeHolderBuilder;

  WSliverChildBuilderDelegate(this.placeHolderBuilder, builder, {
    ChildIndexGetter? findChildIndexCallback,
    int? childCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    SemanticIndexCallback semanticIndexCallback = _kDefaultSemanticIndexCallback,
    int semanticIndexOffset = 0
  })
      : super(builder,
      findChildIndexCallback: findChildIndexCallback,
    childCount: childCount,
    addAutomaticKeepAlives: addAutomaticKeepAlives,
    addRepaintBoundaries: addRepaintBoundaries,
    addSemanticIndexes: addSemanticIndexes,
    semanticIndexCallback: semanticIndexCallback,
    semanticIndexOffset: semanticIndexOffset
  );

  @override
  Widget? buildPlaceHolder(BuildContext context, int index) {
    Widget? widget = placeHolderBuilder?.call(context, index);
    if (widget == null) return SizedBox(
      height: 100,
    );
    return widget;
  }

}
