///
/// 一个可以滚动的组件
///
/// [Scrollable]实现了可滚动widget的交互模型，包括手势识别，但对如何构造实际显示子节点的视
/// 窗（viewport）没有实现。
///
/// 很少直接构造一个[Scrollable]。相反，可以考虑[ListView]或[GridView]，它们结合了滚动、
/// 视窗和布局模型。要结合布局模型（或使用自定义布局模型），可以考虑使用[CustomScrollView]。
///
/// 静态的[Scrollable.of]和[Scrollable.ensureVisible]函数通常用于与[ListView]或
/// [GridView]中的[Scrollable]widget交互。
///
/// 使用[Scrollable]可进一步自定义滚动行为：
/// 1. 你可以提供一个[viewportBuilder]来自定义child模型。例如，[SingleChildScrollView]
///    使用的是显示单个box的视窗（viewport），而[CustomScrollView]使用的是[Viewport]或[ShrinkWrappingViewport]，
///    这两个视窗都显示一个sliver列表。
/// 2. 你可以提供一个自定义的[ScrollController]，创建一个自定义的[ScrollPosition]子类。例如，[PageView]使用了一个
///    [PageController]，它创建了一个面向页面的滚动位置子类，当[Scrollable]调整大小时，该子类保持同一页面可见。
///
/// 也可参考：
/// * [ListView]：这是一个常用的[ScrollView]，可以显示一个滚动的、线性的子部件列表。
/// * [PageView]：它是一个滚动的子部件列表，每个子部件的大小与视口相同
/// * [GridView]：它是一个[ScrollView]，显示一个滚动的、二维的子部件阵列。
/// * [CustomScrollView]：它是一个[ScrollView]，可以使用slivers创建自定义滚动效果。
/// * [SingleChildScrollView]：这是一个可滚动的小部件，它只有一个child。
/// * [ScrollNotification]和[NotificationListener]，可用于观察滚动位置，而无需使用[ScrollController]。
///
///
///
class Scrollable extends StatefulWidget {
  /// Creates a widget that scrolls.
  ///
  /// The [axisDirection] and [viewportBuilder] arguments must not be null.
  const Scrollable({
    Key? key,
    this.axisDirection = AxisDirection.down,
    this.controller,
    this.physics,
    required this.viewportBuilder,
    this.incrementCalculator,
    this.excludeFromSemantics = false,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
  }) : assert(axisDirection != null),
        assert(dragStartBehavior != null),
        assert(viewportBuilder != null),
        assert(excludeFromSemantics != null),
        assert(semanticChildCount == null || semanticChildCount >= 0),
        super (key: key);

  /// The direction in which this widget scrolls.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], increasing
  /// the scroll position will cause content below the bottom of the viewport to
  /// become visible through the viewport. Similarly, if [axisDirection] is
  /// [AxisDirection.right], increasing the scroll position will cause content
  /// beyond the right edge of the viewport to become visible through the
  /// viewport.
  ///
  /// Defaults to [AxisDirection.down].
  final AxisDirection axisDirection;

  /// 可用于控制该小组件滚动位置的对象。
  ///
  /// [ScrollController]有几个用途。它可以用来控制初始滚动位置（参见[ScrollController.initialScrollOffset]）。
  /// 它可以用来控制滚动视图是否应该自动保存并恢复其在[PageStorage]中的滚动位置
  /// （参见[ScrollController.keepScrollOffset]）。它可以用来读取当前的滚动位置（见[ScrollController.offset]），
  /// 或者改变它（见[ScrollController.animateTo]）。
  ///
  /// See also:
  ///
  ///  * [ensureVisible]，为了显示给定的[BuildContext]，动画调整滚动位置。
  final ScrollController? controller;

  /// 小组件应该如何响应用户的输入。
  ///
  /// 例如，决定用户停止拖动滚动视图后，小组件如何继续动画。
  ///
  /// 默认通过[ScrollConfiguration]提供的物理模型来匹配平台特性。
  ///
  /// 物理模型可以动态改变，但新的物理模型只有在所提供对象的_class_ 改变时才会生效。仅仅用
  /// 不同的配置构造一个新的实例是不足以导致物理模型被重新应用的。（这是因为最终使用的对象是
  /// 动态生成的，这可能会比较昂贵，而且每一帧都要推测性地创建这个对象来查看是否应该更新物理
  /// 模型，效率很低）。
  ///
  ///
  /// See also:
  ///
  ///  * [AlwaysScrollableScrollPhysics]，它可以用来指示应该对可滚动的内容的滚动请求
  ///    （以及可能的过度滚动）做出何种反应，即使可滚动的内容不需要滚动也能适应。
  final ScrollPhysics? physics;

  /// 建立显示可滚动内容的视窗（viewport）。
  ///
  /// 一个典型的视窗（viewport）使用给定的[ViewportOffset]来确定其内容的哪一部分实际上是
  /// 通过视窗可见的。
  ///
  /// See also:
  ///
  ///  * [Viewport], 它是一个显示slivers列表的视窗。
  ///  * [ShrinkWrappingViewport], 它是一个显示slivers列表的视窗，并根据slivers的大小
  ///    来调整自己的大小。
  final ViewportBuilder viewportBuilder;

  /// An optional function that will be called to calculate the distance to
  /// scroll when the scrollable is asked to scroll via the keyboard using a
  /// [ScrollAction].
  ///
  /// If not supplied, the [Scrollable] will scroll a default amount when a
  /// keyboard navigation key is pressed (e.g. pageUp/pageDown, control-upArrow,
  /// etc.), or otherwise invoked by a [ScrollAction].
  ///
  /// If [incrementCalculator] is null, the default for
  /// [ScrollIncrementType.page] is 80% of the size of the scroll window, and
  /// for [ScrollIncrementType.line], 50 logical pixels.
  final ScrollIncrementCalculator? incrementCalculator;

  /// Whether the scroll actions introduced by this [Scrollable] are exposed
  /// in the semantics tree.
  ///
  /// Text fields with an overflow are usually scrollable to make sure that the
  /// user can get to the beginning/end of the entered text. However, these
  /// scrolling actions are generally not exposed to the semantics layer.
  ///
  /// See also:
  ///
  ///  * [GestureDetector.excludeFromSemantics], which is used to accomplish the
  ///    exclusion.
  final bool excludeFromSemantics;

  /// The number of children that will contribute semantic information.
  ///
  /// The value will be null if the number of children is unknown or unbounded.
  ///
  /// Some subtypes of [ScrollView] can infer this value automatically. For
  /// example [ListView] will use the number of widgets in the child list,
  /// while the [new ListView.separated] constructor will use half that amount.
  ///
  /// For [CustomScrollView] and other types which do not receive a builder
  /// or list of widgets, the child count must be explicitly provided.
  ///
  /// See also:
  ///
  ///  * [CustomScrollView], for an explanation of scroll semantics.
  ///  * [SemanticsConfiguration.scrollChildCount], the corresponding semantics property.
  final int? semanticChildCount;

  // TODO(jslavitz): Set the DragStartBehavior default to be start across all widgets.
  /// {@template flutter.widgets.scrollable.dragStartBehavior}
  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], scrolling drag behavior will
  /// begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for
  ///    the different behaviors.
  ///
  /// {@endtemplate}
  final DragStartBehavior dragStartBehavior;

  /// {@template flutter.widgets.scrollable.restorationId}
  /// Restoration ID to save and restore the scroll offset of the scrollable.
  ///
  /// If a restoration id is provided, the scrollable will persist its current
  /// scroll offset and restore it during state restoration.
  ///
  /// The scroll offset is persisted in a [RestorationBucket] claimed from
  /// the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  /// {@endtemplate}
  final String? restorationId;

  /// The axis along which the scroll view scrolls.
  ///
  /// Determined by the [axisDirection].
  Axis get axis => axisDirectionToAxis(axisDirection);

  @override
  ScrollableState createState() => ScrollableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(DiagnosticsProperty<ScrollPhysics>('physics', physics));
    properties.add(StringProperty('restorationId', restorationId));
  }

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ScrollableState scrollable = Scrollable.of(context);
  /// ```
  ///
  /// Calling this method will create a dependency on the closest [Scrollable]
  /// in the [context], if there is one.
  static ScrollableState? of(BuildContext context) {
    final _ScrollableScope? widget = context.dependOnInheritedWidgetOfExactType<_ScrollableScope>();
    return widget?.scrollable;
  }

  /// Provides a heuristic to determine if expensive frame-bound tasks should be
  /// deferred for the [context] at a specific point in time.
  ///
  /// Calling this method does _not_ create a dependency on any other widget.
  /// This also means that the value returned is only good for the point in time
  /// when it is called, and callers will not get updated if the value changes.
  ///
  /// The heuristic used is determined by the [physics] of this [Scrollable]
  /// via [ScrollPhysics.recommendDeferredLoading]. That method is called with
  /// the current [ScrollPosition.activity]'s [ScrollActivity.velocity].
  ///
  /// If there is no [Scrollable] in the widget tree above the [context], this
  /// method returns false.
  static bool recommendDeferredLoadingForContext(BuildContext context) {
    final _ScrollableScope? widget = context.getElementForInheritedWidgetOfExactType<_ScrollableScope>()?.widget as _ScrollableScope?;
    if (widget == null) {
      return false;
    }
    return widget.position.recommendDeferredLoading(context);
  }

  /// Scrolls the scrollables that enclose the given context so as to make the
  /// given context visible.
  static Future<void> ensureVisible(
      BuildContext context, {
        double alignment = 0.0,
        Duration duration = Duration.zero,
        Curve curve = Curves.ease,
        ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
      }) {
    final List<Future<void>> futures = <Future<void>>[];

    // The `targetRenderObject` is used to record the first target renderObject.
    // If there are multiple scrollable widgets nested, we should let
    // the `targetRenderObject` as visible as possible to improve the user experience.
    // Otherwise, let the outer renderObject as visible as possible maybe cause
    // the `targetRenderObject` invisible.
    // Also see https://github.com/flutter/flutter/issues/65100
    RenderObject? targetRenderObject;
    ScrollableState? scrollable = Scrollable.of(context);
    while (scrollable != null) {
      futures.add(scrollable.position.ensureVisible(
        context.findRenderObject()!,
        alignment: alignment,
        duration: duration,
        curve: curve,
        alignmentPolicy: alignmentPolicy,
        targetRenderObject: targetRenderObject,
      ));

      targetRenderObject = targetRenderObject ?? context.findRenderObject();
      context = scrollable.context;
      scrollable = Scrollable.of(context);
    }

    if (futures.isEmpty || duration == Duration.zero)
      return Future<void>.value();
    if (futures.length == 1)
      return futures.single;
    return Future.wait<void>(futures).then<void>((List<void> _) => null);
  }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// [Scrollable] widget的state
///
/// 要操作[Scrollable] 小组件的滚动位置，请使用从[position] 属性获得的对象。
///
/// 要通知[Scrollable]widget何时滚动，请使用[NotificationListener]来监听[ScrollNotification]通知。
///
/// 这个类不应该被继承。要使[Scrollable]的行为特殊化，请为其提供一个[ScrollPhysics]。
///
class ScrollableState extends State<Scrollable> with TickerProviderStateMixin, RestorationMixin
    implements ScrollContext {
  /// 这个[Scrollable] 小组件的视窗位置的管理器。
  ///
  /// 要控制为一个[Scrollable]创建什么样的[ScrollPosition]，为它提供自定义的[ScrollController]，
  /// 在它的[ScrollController.createScrollPosition]方法中创建相应的[ScrollPosition]。
  ScrollPosition get position => _position!;
  ScrollPosition? _position;

  final _RestorableScrollOffset _persistedScrollOffset = _RestorableScrollOffset();

  @override
  AxisDirection get axisDirection => widget.axisDirection;

  late ScrollBehavior _configuration;
  ScrollPhysics? _physics;

  // 只有从肯定会引发重新构建（rebuild）的地方调用这个方法。
  void _updatePosition() {
    _configuration = ScrollConfiguration.of(context);
    _physics = _configuration.getScrollPhysics(context);
    if (widget.physics != null)
      _physics = widget.physics!.applyTo(_physics);
    final ScrollController? controller = widget.controller;
    final ScrollPosition? oldPosition = _position;
    if (oldPosition != null) {
      controller?.detach(oldPosition);
      // It's important that we not dispose the old position until after the
      // viewport has had a chance to unregister its listeners from the old
      // position. So, schedule a microtask to do it.
      scheduleMicrotask(oldPosition.dispose);
    }

    _position = controller?.createScrollPosition(_physics!, this, oldPosition)
        ?? ScrollPositionWithSingleContext(physics: _physics!, context: this, oldPosition: oldPosition);
    assert(_position != null);
    controller?.attach(position);
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_persistedScrollOffset, 'offset');
    if (_persistedScrollOffset.value != null) {
      position.restoreOffset(_persistedScrollOffset.value!, initialRestore: initialRestore);
    }
  }

  @override
  void saveOffset(double offset) {
    _persistedScrollOffset.value = offset;
    // [saveOffset] is called after a scrolling ends and it is usually not
    // followed by a frame. Therefore, manually flush restoration data.
    ServicesBinding.instance!.restorationManager.flushData();
  }

  @override
  void didChangeDependencies() {
    _updatePosition();
    super.didChangeDependencies();
  }

  bool _shouldUpdatePosition(Scrollable oldWidget) {
    ScrollPhysics? newPhysics = widget.physics;
    ScrollPhysics? oldPhysics = oldWidget.physics;
    do {
      if (newPhysics?.runtimeType != oldPhysics?.runtimeType)
        return true;
      newPhysics = newPhysics?.parent;
      oldPhysics = oldPhysics?.parent;
    } while (newPhysics != null || oldPhysics != null);

    return widget.controller?.runtimeType != oldWidget.controller?.runtimeType;
  }

  @override
  void didUpdateWidget(Scrollable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(position);
      widget.controller?.attach(position);
    }

    if (_shouldUpdatePosition(oldWidget))
      _updatePosition();
  }

  @override
  void dispose() {
    widget.controller?.detach(position);
    position.dispose();
    _persistedScrollOffset.dispose();
    super.dispose();
  }


  // SEMANTICS

  final GlobalKey _scrollSemanticsKey = GlobalKey();

  @override
  @protected
  void setSemanticsActions(Set<SemanticsAction> actions) {
    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState!.replaceSemanticsActions(actions);
  }


  //手势识别、忽略鼠标
  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = GlobalKey<RawGestureDetectorState>();
  final GlobalKey _ignorePointerKey = GlobalKey();

  // This field is set during layout, and then reused until the next time it is set.
  Map<Type, GestureRecognizerFactory> _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
  bool _shouldIgnorePointer = false;

  bool? _lastCanDrag;
  Axis? _lastAxisDirection;

  @override
  @protected
  void setCanDrag(bool canDrag) {
    if (canDrag == _lastCanDrag && (!canDrag || widget.axis == _lastAxisDirection))
      return;
    if (!canDrag) {
      _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
      // Cancel the active hold/drag (if any) because the gesture recognizers
      // will soon be disposed by our RawGestureDetector, and we won't be
      // receiving pointer up events to cancel the hold/drag.
      //取消有效的保持（hold）/拖动（drag）(如果有的话)，因为手势识别器很快就会被我们的
      // RawGestureDetector处理掉，我们不会再收到指针向上事件来取消保持/拖动。
      _handleDragCancel();
    } else {
      switch (widget.axis) {
        case Axis.vertical:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer(),
                  (VerticalDragGestureRecognizer instance) {
                instance
                  ..onDown = _handleDragDown
                  ..onStart = _handleDragStart
                  ..onUpdate = _handleDragUpdate
                  ..onEnd = _handleDragEnd
                  ..onCancel = _handleDragCancel
                  ..minFlingDistance = _physics?.minFlingDistance
                  ..minFlingVelocity = _physics?.minFlingVelocity
                  ..maxFlingVelocity = _physics?.maxFlingVelocity
                  ..velocityTrackerBuilder = _configuration.velocityTrackerBuilder(context)
                  ..dragStartBehavior = widget.dragStartBehavior;
              },
            ),
          };
          break;
        case Axis.horizontal:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
                  (HorizontalDragGestureRecognizer instance) {
                instance
                  ..onDown = _handleDragDown
                  ..onStart = _handleDragStart
                  ..onUpdate = _handleDragUpdate
                  ..onEnd = _handleDragEnd
                  ..onCancel = _handleDragCancel
                  ..minFlingDistance = _physics?.minFlingDistance
                  ..minFlingVelocity = _physics?.minFlingVelocity
                  ..maxFlingVelocity = _physics?.maxFlingVelocity
                  ..velocityTrackerBuilder = _configuration.velocityTrackerBuilder(context)
                  ..dragStartBehavior = widget.dragStartBehavior;
              },
            ),
          };
          break;
      }
    }
    _lastCanDrag = canDrag;
    _lastAxisDirection = widget.axis;
    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState!.replaceGestureRecognizers(_gestureRecognizers);
  }

  @override
  TickerProvider get vsync => this;

  @override
  @protected
  void setIgnorePointer(bool value) {
    if (_shouldIgnorePointer == value)
      return;
    _shouldIgnorePointer = value;
    if (_ignorePointerKey.currentContext != null) {
      final RenderIgnorePointer renderBox = _ignorePointerKey.currentContext!.findRenderObject()! as RenderIgnorePointer;
      renderBox.ignoring = _shouldIgnorePointer;
    }
  }

  @override
  BuildContext? get notificationContext => _gestureDetectorKey.currentContext;

  @override
  BuildContext get storageContext => context;

  // TOUCH HANDLERS

  Drag? _drag;
  ScrollHoldController? _hold;

  //按下
  void _handleDragDown(DragDownDetails details) {
    _hold = position.hold(_disposeHold);
  }

  //开始
  void _handleDragStart(DragStartDetails details) {
    // It's possible for _hold to become null between _handleDragDown and
    // _handleDragStart, for example if some user code calls jumpTo or otherwise
    // triggers a new activity to begin.
    _drag = position.drag(details, _disposeDrag);
  }

  //更新
  void _handleDragUpdate(DragUpdateDetails details) {
    // _drag might be null if the drag activity ended and called _disposeDrag.
    _drag?.update(details);
  }

  //结束
  void _handleDragEnd(DragEndDetails details) {
    // _drag might be null if the drag activity ended and called _disposeDrag.
    _drag?.end(details);
  }

  //取消
  void _handleDragCancel() {
    // _hold might be null if the drag started.
    // _drag might be null if the drag activity ended and called _disposeDrag.
    _hold?.cancel();
    _drag?.cancel();
  }

  void _disposeHold() {
    _hold = null;
  }

  void _disposeDrag() {
    _drag = null;
  }

  // SCROLL WHEEL

  // Returns the offset that should result from applying [event] to the current
  // position, taking min/max scroll extent into account.
  double _targetScrollOffsetForPointerScroll(double delta) {
    return math.min(math.max(position.pixels + delta, position.minScrollExtent),
        position.maxScrollExtent);
  }

  // Returns the delta that should result from applying [event] with axis and
  // direction taken into account.
  double _pointerSignalEventDelta(PointerScrollEvent event) {
    double delta = widget.axis == Axis.horizontal
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;

    if (axisDirectionIsReversed(widget.axisDirection)) {
      delta *= -1;
    }
    return delta;
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _position != null) {
      if (_physics != null && !_physics!.shouldAcceptUserOffset(position)) {
        return;
      }
      final double delta = _pointerSignalEventDelta(event);
      final double targetScrollOffset = _targetScrollOffsetForPointerScroll(delta);
      // Only express interest in the event if it would actually result in a scroll.
      if (delta != 0.0 && targetScrollOffset != position.pixels) {
        GestureBinding.instance!.pointerSignalResolver.register(event, _handlePointerScroll);
      }
    }
  }

  void _handlePointerScroll(PointerEvent event) {
    assert(event is PointerScrollEvent);
    final double delta = _pointerSignalEventDelta(event as PointerScrollEvent);
    final double targetScrollOffset = _targetScrollOffsetForPointerScroll(delta);
    if (delta != 0.0 && targetScrollOffset != position.pixels) {
      position.pointerScroll(delta);
    }
  }

  // DESCRIPTION

  @override
  Widget build(BuildContext context) {
    // _ScrollableScope必须放在notificationContext返回的BuildContext之上，这样我们就
    // 可以通过以下操作来获得这个ScrollableState了：
    //
    //  ScrollNotification notification;
    //  Scrollable.of(notification.context)
    //
    // 由于notificationContext指向_gestureDetectorKey.context，所以_ScrollableScope
    // 必须放在使用它的widget上方：RawGestureDetector

    Widget result = _ScrollableScope( //一个InheritedWidget
      scrollable: this,
      position: position,
      // TODO(ianh): Having all these global keys is sad.
      child: Listener(
        onPointerSignal: _receivedPointerSignal,
        child: RawGestureDetector( //手势识别器
          key: _gestureDetectorKey,
          gestures: _gestureRecognizers,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: widget.excludeFromSemantics,
          child: Semantics(
            explicitChildNodes: !widget.excludeFromSemantics,
            child: IgnorePointer(//忽略手势
              key: _ignorePointerKey,
              ignoring: _shouldIgnorePointer,
              ignoringSemantics: false,
              child: widget.viewportBuilder(context, position),
            ),
          ),
        ),
      ),
    );

    if (!widget.excludeFromSemantics) {
      result = _ScrollSemantics(
        key: _scrollSemanticsKey,
        child: result,
        position: position,
        allowImplicitScrolling: _physics!.allowImplicitScrolling,
        semanticChildCount: widget.semanticChildCount,
      );
    }

    return _configuration.buildViewportChrome(context, result, widget.axisDirection);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScrollPosition>('position', position));
    properties.add(DiagnosticsProperty<ScrollPhysics>('effective physics', _physics));
  }

  @override
  String? get restorationId => widget.restorationId;
}

