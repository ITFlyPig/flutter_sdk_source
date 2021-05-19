import 'package:flutter/gestures.dart';

import 'GestureRecognizer源码.dart';

/// 一次只能识别一个手势的手势识别器的基类。例如，一个[TapGestureRecognizer]永远无法识别同
/// 时发生的两次轻拍（tap），即使多个指针被放置在同一个部件上。
//
//  这与例如[MultiTapGestureRecognizer]形成对比，后者独立地管理每个指针，并且可以认为多个
//  同时触摸的结果都是一个单独的轻敲（tap）。
abstract class OneSequenceGestureRecognizer extends GestureRecognizer {
  /// Initialize the object.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.kind}
  OneSequenceGestureRecognizer({
    Object? debugOwner,
    PointerDeviceKind? kind,
  }) : super(debugOwner: debugOwner, kind: kind);

  final Map<int, GestureArenaEntry> _entries = <int, GestureArenaEntry>{};
  final Set<int> _trackedPointers = HashSet<int>();

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    resolve(GestureDisposition.rejected);
  }

  /// Called when a pointer event is routed to this recognizer.
  /// 当指针事件被路由到这个识别器时被调用
  @protected
  void handleEvent(PointerEvent event);

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}

  /// Called when the number of pointers this recognizer is tracking changes from one to zero.
  ///
  /// The given pointer ID is the ID of the last pointer this recognizer was
  /// tracking.
  @protected
  void didStopTrackingLastPointer(int pointer);

  /// Resolves this recognizer's participation in each gesture arena with the
  /// given disposition.
  @protected
  @mustCallSuper
  void resolve(GestureDisposition disposition) {
    final List<GestureArenaEntry> localEntries =
        List<GestureArenaEntry>.from(_entries.values);
    _entries.clear();
    for (final GestureArenaEntry entry in localEntries)
      entry.resolve(disposition);
  }

  /// Resolves this recognizer's participation in the given gesture arena with
  /// the given disposition.
  @protected
  @mustCallSuper
  void resolvePointer(int pointer, GestureDisposition disposition) {
    final GestureArenaEntry? entry = _entries[pointer];
    if (entry != null) {
      _entries.remove(pointer);
      entry.resolve(disposition);
    }
  }

  @override
  void dispose() {
    resolve(GestureDisposition.rejected);
    for (final int pointer in _trackedPointers)
      GestureBinding.instance!.pointerRouter.removeRoute(pointer, handleEvent);
    _trackedPointers.clear();
    assert(_entries.isEmpty);
    super.dispose();
  }

  /// 此识别器所属的团队(如果有)。
  ///
  ///如果[Team]为空，此识别器将直接在[GestureArenaManager]中竞争，将指针事件序列识别为手势。
  ///如果[Team]非空，则此识别器将与同一团队中的其他识别器在竞技场上进行分组竞争。
  ///
  ///只有当team没有参加竞技场时，才能将识别器分配给该team。例如，通常在创建识别器后不久将识别器分配给团队（team）。

  GestureArenaTeam? get team => _team;
  GestureArenaTeam? _team;

  /// The [team] can only be set once.
  set team(GestureArenaTeam? value) {
    assert(value != null);
    assert(_entries.isEmpty);
    assert(_trackedPointers.isEmpty);
    assert(_team == null);
    _team = value;
  }

  GestureArenaEntry _addPointerToArena(int pointer) {
    if (_team != null) return _team!.add(pointer, this);
    return GestureBinding.instance!.gestureArena.add(pointer, this);
  }

  /// 使与给定指针ID相关的事件被路由到此识别器。
  ///
  /// 指针事件根据`transform`进行转换，然后传递给[handleEvent]。
  /// `transform`参数的值通常从[PointerDownEvent.Transform]获取，将事件从全局坐标空间转换到事件接收方的坐标空间
  /// 。如果不需要变换，则它可能为空。
  ///
  /// 使用[stopTrackingPointer]删除此功能添加的路由。
  ///
  @protected
  void startTrackingPointer(int pointer, [Matrix4? transform]) {
    // 添加到全局路由，跟踪后续的事件
    GestureBinding.instance!.pointerRouter
        .addRoute(pointer, handleEvent, transform);
    _trackedPointers.add(pointer);
    assert(!_entries.containsValue(pointer));
    // 添加到全局竞技场
    _entries[pointer] = _addPointerToArena(pointer);
  }

  ///停止将与给定指针ID相关的事件路由到此识别器。
  ///
  ///如果此函数将跟踪指针的数量减少到零，它将同步调用[didStopTrackingLastPointer]。
  ///
  ///首先使用[startTrackingPointer]添加路由。
  @protected
  void stopTrackingPointer(int pointer) {
    if (_trackedPointers.contains(pointer)) {
      // 从全局指针事件的路由表中删除
      GestureBinding.instance!.pointerRouter.removeRoute(pointer, handleEvent);
      _trackedPointers.remove(pointer);
      if (_trackedPointers.isEmpty) didStopTrackingLastPointer(pointer);
    }
  }

  /// 如果给定事件是[PointerUpEvent]或[PointerCancelEvent]事件，则停止跟踪与该事件关联的指针事件。
  @protected
  void stopTrackingIfPointerNoLongerDown(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent)
      stopTrackingPointer(event.pointer);
  }
}
