/// 手势子系统的一个binding
///
/// ## 指针事件的生命周期和手势竞技场
///
/// ### [PointerDownEvent]
///
/// 当[GestureBinding]收到[PointerDownEvent]（来自[dart:ui.PlatformDispatcher.onPointerDataPacket]，
/// 由[PointerEventConverter]解释）时，会执行[hitTest]以确定哪些[HitTestTarget]节点受到影响。
/// （其他绑定被期望实现[hitTest]以延迟到[HitTestable]对象。例如，渲染层会遵从[RenderView]和渲染对象层次结构的其他部分）。
///
/// 然后，会将事件（event）传递给受影响的节点来处理（[dispatchEvent]为每个受影响的节点调用
/// [HitTestTarget.handleEvent]）。如果有相关的[GestureRecognizer]，就用[GestureRecognizer.addPointer]
/// 向它们提供事件。这通常会导致识别器向[PointerRouter]注册，以接收有关指针的通知。
///
/// 一旦命中测试和分发逻辑完成，该事件（event）就会被传递给上述的[PointerRouter]，后者会将
/// 其传递给任何对该事件注册感兴趣的对象。
///
/// 最后，为给定的指针事件关闭[gestureArena]（[GestureArenaManager.close]），开始 一个选择手势来赢得该指针的 过程。
///
/// ### 其他事件（Other events）
///
/// 一个[PointerEvent.down]类型的指针可能会发送进一步的事件，例如[PointerMoveEvent]
/// 、[PointerUpEvent]或[PointerCancelEvent]。这些事件被发送到与接收[PointerDownEvent]
/// 时相同的[HitTestTarget]节点（即使它们后来被disposed了；这些对象有责任意识到这种可能性）。
///
/// 然后，这些事件被路由到[PointerRouter]表中任何对该指针仍在注册的参赛者。
///
/// 当收到[PointerUpEvent]事件时，[GestureArenaManager.sweep]方法被调用，以强制手势竞技
/// 场逻辑在必要时终止。
mixin GestureBinding on BindingBase
    implements HitTestable, HitTestDispatcher, HitTestTarget {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    window.onPointerDataPacket = _handlePointerDataPacket;
  }

  @override
  void unlocked() {
    super.unlocked();
    _flushPointerEventQueue();
  }

  /// The singleton instance of this object.
  static GestureBinding? get instance => _instance;
  static GestureBinding? _instance;

  final Queue<PointerEvent> _pendingPointerEvents = Queue<PointerEvent>();

  void _handlePointerDataPacket(ui.PointerDataPacket packet) {
    // We convert pointer data to logical pixels so that e.g. the touch slop can be
    // defined in a device-independent manner.
    //1. 将传递进来的事件转为使用逻辑像素的事件，并将他们放到_pendingPointerEvents队列中
    _pendingPointerEvents.addAll(
        PointerEventConverter.expand(packet.data, window.devicePixelRatio));
    // 2.开始循环处理队列中的事件
    if (!locked) _flushPointerEventQueue();
  }

  /// Dispatch a [PointerCancelEvent] for the given pointer soon.
  ///
  /// The pointer event will be dispatched before the next pointer event and
  /// before the end of the microtask but not within this function call.
  void cancelPointer(int pointer) {
    if (_pendingPointerEvents.isEmpty && !locked)
      scheduleMicrotask(_flushPointerEventQueue);
    _pendingPointerEvents.addFirst(PointerCancelEvent(pointer: pointer));
  }

  void _flushPointerEventQueue() {
    //while循环处理队列中的PointerEvent事件
    while (_pendingPointerEvents.isNotEmpty)
      handlePointerEvent(_pendingPointerEvents.removeFirst());
  }

  /// A router that routes all pointer events received from the engine.
  final PointerRouter pointerRouter = PointerRouter();

  /// The gesture arenas used for disambiguating the meaning of sequences of
  /// pointer events.
  final GestureArenaManager gestureArena = GestureArenaManager();

  /// The resolver used for determining which widget handles a
  /// [PointerSignalEvent].
  final PointerSignalResolver pointerSignalResolver = PointerSignalResolver();

  /// State for all pointers which are currently down.
  ///
  /// The state of hovering pointers is not tracked because that would require
  /// hit-testing on every frame.
  final Map<int, HitTestResult> _hitTests = <int, HitTestResult>{};

  /// 将事件分发给 在事件坐标上 通过命中测试（hit test）找到的 目标。
  ///
  /// 该方法会基于以下事件的类型，将事件发送到[dispatchEvent]方法：
  /// * [PointerDownEvent]和[PointerSignalEvent]事件会被分发给新的[hitTest]的结果。
  /// * [PointerUpEvent] 和 [PointerMoveEvent] 事件会被分发给前面[PointerDownEvent]事件的命中测试（hit test）的结果。
  /// * [PointerHoverEvent]s, [PointerAddedEvent]s, and [PointerRemovedEvent]s 不需要命中结果进行分发。
  void handlePointerEvent(PointerEvent event) {
    if (resamplingEnabled) {
      _resampler.addOrDispatch(event);
      _resampler.sample(samplingOffset, _samplingInterval);
      return;
    }

    // Stop resampler if resampling is not enabled. This is a no-op if
    // resampling was never enabled.
    _resampler.stop();
    _handlePointerEventImmediately(event);
  }

  void _handlePointerEventImmediately(PointerEvent event) {
    HitTestResult? hitTestResult;
    if (event is PointerDownEvent ||
        event is PointerSignalEvent ||
        event is PointerHoverEvent) {
      assert(!_hitTests.containsKey(event.pointer));
      // 新建一个HitTestResult
      hitTestResult = HitTestResult();
      // 开始命中测试，会在hitTestResult中建立起来对事件down感兴趣的路劲
      hitTest(hitTestResult, event.position);

      // 对于down事件，将命中测试的结果放入_hitTests中
      if (event is PointerDownEvent) {
        _hitTests[event.pointer] = hitTestResult;
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      // 对于up、cancel事件，将event从_hitTests中移除
      hitTestResult = _hitTests.remove(event.pointer);
    } else if (event.down) {
      // Because events that occur with the pointer down (like
      // [PointerMoveEvent]s) should be dispatched to the same place that their
      // initial PointerDownEvent was, we want to re-use the path we found when
      // the pointer went down, rather than do hit detection each time we get
      // such an event.
      hitTestResult = _hitTests[event.pointer];
    }
    if (hitTestResult != null ||
        event is PointerAddedEvent ||
        event is PointerRemovedEvent) {
      // 分发事件
      dispatchEvent(event, hitTestResult);
    }
  }

  /// Determine which [HitTestTarget] objects are located at a given position.
  /// 决定哪些[HitTestTarget]对象落在给定的position坐标内
  @override // from HitTestable
  void hitTest(HitTestResult result, Offset position) {
    // 将GestureBinding添加
    result.add(HitTestEntry(this));
  }

  /// Dispatch an event to [pointerRouter] and the path of a hit test result.
  ///
  /// The `event` is routed to [pointerRouter]. If the `hitTestResult` is not
  /// null, the event is also sent to every [HitTestTarget] in the entries of the
  /// given [HitTestResult]. Any exceptions from the handlers are caught.
  ///
  /// The `hitTestResult` argument may only be null for [PointerAddedEvent]s or
  /// [PointerRemovedEvent]s.
  @override // from HitTestDispatcher
  void dispatchEvent(PointerEvent event, HitTestResult? hitTestResult) {
    // No hit test information implies that this is a [PointerHoverEvent],
    // [PointerAddedEvent], or [PointerRemovedEvent]. These events are specially
    // routed here; other events will be routed through the `handleEvent` below.
    if (hitTestResult == null) {
      try {
        pointerRouter.route(event);
      } catch (exception, stack) {}
      return;
    }
    // 一般会走这里，调用感兴趣路劲上的对象的handleEvent方法来处理事件
    for (final HitTestEntry entry in hitTestResult.path) {
      try {
        entry.target.handleEvent(event.transformed(entry.transform), entry);
      } catch (exception, stack) {}
    }
  }

  @override // from HitTestTarget
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    pointerRouter.route(event);
    if (event is PointerDownEvent) {
      gestureArena.close(event.pointer);
    } else if (event is PointerUpEvent) {
      gestureArena.sweep(event.pointer);
    } else if (event is PointerSignalEvent) {
      pointerSignalResolver.resolve(event);
    }
  }

  /// Reset states of [GestureBinding].
  ///
  /// This clears the hit test records.
  ///
  /// This is typically called between tests.
  @protected
  void resetGestureBinding() {
    _hitTests.clear();
  }

  void _handleSampleTimeChanged() {
    if (!locked) {
      if (resamplingEnabled) {
        _resampler.sample(samplingOffset, _samplingInterval);
      } else {
        _resampler.stop();
      }
    }
  }

  // Resampler used to filter incoming pointer events when resampling
  // is enabled.
  late final _Resampler _resampler = _Resampler(
    _handlePointerEventImmediately,
    _handleSampleTimeChanged,
  );

  /// Enable pointer event resampling for touch devices by setting
  /// this to true.
  ///
  /// Resampling results in smoother touch event processing at the
  /// cost of some added latency. Devices with low frequency sensors
  /// or when the frequency is not a multiple of the display frequency
  /// (e.g., 120Hz input and 90Hz display) benefit from this.
  ///
  /// This is typically set during application initialization but
  /// can be adjusted dynamically in case the application only
  /// wants resampling for some period of time.
  bool resamplingEnabled = false;

  /// Offset relative to current frame time that should be used for
  /// resampling. The [samplingOffset] is expected to be negative.
  /// Non-negative [samplingOffset] is allowed but will effectively
  /// disable resampling.
  Duration samplingOffset = _defaultSamplingOffset;
}
