///
/// 确定内容的哪一部分在scroll view中可见。
///
///  [pixels] 值决定了scroll view选择其内容的哪一部分的来展示。当用户滚动视窗时，这个值会
///  改变，从而改变显示的内容。
///
/// [ScrollPosition]将[physics] 应用于滚动，并存储[minScrollExtent]和[maxScrollExtent]。
///
/// 滚动是由当前的[activity]控制的，它由[beginActivity]设置。[ScrollPosition]本身并不
/// 启动任何活动，而是由具体的子类，如[ScrollPositionWithSingleContext]来启动活动。相反，
/// 具体的子类，如[ScrollPositionWithSingleContext]，通常会响应用户输入或来自[ScrollController]
/// 的指令来启动活动（activity）。
///
/// 这个对象是一个[Listenable] 类型的，当 [pixels]发生变化时，会通知其监听者。
///
/// ## ScrollPosition 子类
///
/// 随着时间的推移，一个[Scrollable]可能会有许多不同的[ScrollPosition]对象。例如，如果
/// [Scrollable.physics]改变了类型，[Scrollable]就会用新的physics创建一个新的[ScrollPosition]。
/// 为了将状态从旧实例转移到新实例，子类实现了[absorb]。更多细节请参见[absorb]。
///
/// 每当[userScrollDirection]改变值时，子类也需要调用[didUpdateScrollDirection]。
///
/// See also:
/// * [Scrollable]，它使用[ScrollPosition]来决定显示其内容的哪一部分。
/// * [ScrollController]，它可以与[ListView]、[GridView]和其他可滚动的widget一起使用，
///   来控制[ScrollPosition]。
/// * [ScrollPositionWithSingleContext]，它是[ScrollPosition]最常用的具体子类。
/// * [ScrollNotification]和[NotificationListener]，可用于观察滚动位置，而无需使用[ScrollController]。
///
abstract class ScrollPosition extends ViewportOffset with ScrollMetrics {
  /// Creates an object that determines which portion of the content is visible
  /// in a scroll view.
  ///
  /// The [physics], [context], and [keepScrollOffset] parameters must not be null.
  ScrollPosition({
    required this.physics,
    required this.context,
    this.keepScrollOffset = true,
    ScrollPosition? oldPosition,
    this.debugLabel,
  }){
    if (oldPosition != null)
      absorb(oldPosition);
    if (keepScrollOffset)
      restoreScrollOffset();
  }

  /// 确定scroll position应该如何响应用户的输入
  ///
  /// 例如，决定用户停止拖动scroll view后，小组件如何继续动画。
  ///
  final ScrollPhysics physics;

  /// 滚动发生的地方
  ///
  /// 通常由[ScrollableState]实现。
  ///
  final ScrollContext context;

  ///
  /// 用[PageStorage]保存当前的滚动偏移量，如果重新创建scroll position 的 scrollable，则恢复它。
  ///
  /// See also:
  ///
  ///  * [ScrollController.keepScrollOffset]和[PageController.keepPage]，
  ///    它们创建scroll position并初始化该属性。
  // TODO(goderbauer): Deprecate this when state restoration supports all features of PageStorage.
  final bool keepScrollOffset;

  /// A label that is used in the [toString] output.
  ///
  /// Intended to aid with identifying animation controller instances in debug
  /// output.
  final String? debugLabel;

  //最小滚动尺寸
  @override
  double get minScrollExtent => _minScrollExtent!;
  double? _minScrollExtent;

  //最大滚动尺寸
  @override
  double get maxScrollExtent => _maxScrollExtent!;
  double? _maxScrollExtent;

  @override
  bool get hasContentDimensions => _minScrollExtent != null && _maxScrollExtent != null;

  ///
  /// 单帧中[forcePixels]变化的附加速度。
  ///
  /// The additional velocity added for a [forcePixels] change in a single
  /// frame.
  ///
  /// This value is used by [recommendDeferredLoading] in addition to the
  /// [activity]'s [ScrollActivity.velocity] to ask the [physics] whether or
  /// not to defer loading. It accounts for the fact that a [forcePixels] call
  /// may involve a [ScrollActivity] with 0 velocity, but the scrollable is
  /// still instantaneously moving from its current position to a potentially
  /// very far position, and which is of interest to callers of
  /// [recommendDeferredLoading].
  ///
  /// For example, if a scrollable is currently at 5000 pixels, and we [jumpTo]
  /// 0 to get back to the top of the list, we would have an implied velocity of
  /// -5000 and an `activity.velocity` of 0. The jump may be going past a
  /// number of resource intensive widgets which should avoid doing work if the
  /// position jumps past them.
  double _impliedVelocity = 0;

  //当前像素
  @override
  double get pixels => _pixels!;
  double? _pixels;

  @override
  bool get hasPixels => _pixels != null;

  //视窗尺寸
  @override
  double get viewportDimension => _viewportDimension!;
  double? _viewportDimension;

  @override
  bool get hasViewportDimension => _viewportDimension != null;

  /// [viewportDimension]、[minScrollExtent]、[maxScrollExtent]、[outOfRange]和[atEdge]是否可用。
  ///
  /// 在第一次调用[applyNewDimensions]之前设置为true。
  bool get haveDimensions => _haveDimensions;
  bool _haveDimensions = false;

  /// Take any current applicable state from the given [ScrollPosition].
  ///
  /// This method is called by the constructor if it is given an `oldPosition`.
  /// The `other` argument might not have the same [runtimeType] as this object.
  ///
  /// This method can be destructive to the other [ScrollPosition]. The other
  /// object must be disposed immediately after this call (in the same call
  /// stack, before microtask resolution, by whomever called this object's
  /// constructor).
  ///
  /// If the old [ScrollPosition] object is a different [runtimeType] than this
  /// one, the [ScrollActivity.resetActivity] method is invoked on the newly
  /// adopted [ScrollActivity].
  ///
  /// ## Overriding
  ///
  /// Overrides of this method must call `super.absorb` after setting any
  /// metrics-related or activity-related state, since this method may restart
  /// the activity and scroll activities tend to use those metrics when being
  /// restarted.
  ///
  /// Overrides of this method might need to start an [IdleScrollActivity] if
  /// they are unable to absorb the activity from the other [ScrollPosition].
  ///
  /// Overrides of this method might also need to update the delegates of
  /// absorbed scroll activities if they use themselves as a
  /// [ScrollActivityDelegate].
  @protected
  @mustCallSuper
  void absorb(ScrollPosition other) {
    if (other.hasContentDimensions) {
      _minScrollExtent = other.minScrollExtent;
      _maxScrollExtent = other.maxScrollExtent;
    }
    if (other.hasPixels) {
      _pixels = other.pixels;
    }
    if (other.hasViewportDimension) {
      _viewportDimension = other.viewportDimension;
    }

    _activity = other.activity;
    other._activity = null;
    if (other.runtimeType != runtimeType)
      activity!.resetActivity();
    context.setIgnorePointer(activity!.shouldIgnorePointer);
    isScrollingNotifier.value = activity!.isScrolling;
  }

  /// 将滚动位置([pixels])更新为给定的像素值。
  ///
  /// 这应该只被当前的[ScrollActivity]调用，无论是在瞬时回调阶段还是响应用户输入。
  ///
  /// 如果有，返回overscroll的值。如果返回值为0.0，意味传入的’newPixels’和当前的[pixels]
  /// 值相等。如果返回值为正值，则[pixels]比 超过最大尺寸的量小，如果为负值，则比低于最小尺
  /// 寸的量大。
  ///
  /// Returns the overscroll, if any. If the return value is 0.0, that means
  /// that [pixels] now returns the given `value`. If the return value is
  /// positive, then [pixels] is less than the requested `value` by the given
  /// amount (overscroll past the max extent), and if it is negative, it is
  /// greater than the requested `value` by the given amount (underscroll past
  /// the min extent).
  ///
  /// overscroll的数值由[applyBoundaryConditions]计算
  ///
  /// 使用[didUpdateScrollPositionBy]报告所应用的变化量。如果有任何overscroll，则使用[didOverscrollBy]报告。
  ///
  double setPixels(double newPixels) {
    if (newPixels != pixels) {
      //返回由于边界条件而不能应用于[pixels]的量
      final double overscroll = applyBoundaryConditions(newPixels);
      //保存旧的值
      final double oldPixels = pixels;
      //计算应用在[pixels]的
      _pixels = newPixels - overscroll;
      //如果新旧值不相等，则通知
      if (_pixels != oldPixels) {
        notifyListeners();
        //报告位置的变化量（新的位置 - 旧的位置）
        didUpdateScrollPositionBy(pixels - oldPixels);
      }
      //如果存在overscroll
      if (overscroll != 0.0) {
        //报告overscroll的值
        didOverscrollBy(overscroll);
        return overscroll;
      }
    }
    return 0.0;
  }

  /// 在不通知客户的情况下，将[pixels] 的值改为新值。
  ///
  /// 这是在做布局时用来调整位置的。特别是，这通常作为对[applyViewportDimension]或
  /// [applyContentDimensions]的响应而被调用（在这两种情况下，如果调用了这个方法，那么这
  /// 些方法应该返回false来表示位置已经被调整）。
  ///
  /// 在其他情况下，调用这个功能容易出问题。它不会立即导致渲染的改变，因为它不会通知可能监听
  /// 此对象的部件或渲染对象：它们只会在下次读取值时才会改变，而下次读取值的时间可能是任意的。
  /// 一般来说，它只适用于在布局过程中对值进行修正的非常特殊的情况下（因为这样一来，该值就会
  /// 立即被读取），在一个[ScrollPosition]与一个单一视窗客户的特殊情况下。
  ///
  /// 要使位置跳转或动画化到一个新的值，请考虑[jumpTo]或[animateTo]，这将尊重改变滚动偏移的
  /// 正常惯例。
  ///
  /// 如果要强制[pixels] 为一个特定的值，而不遵守改变滚动偏移的常规，可以考虑使用[forcePixels]。
  /// (但请看这里的讨论，以了解为什么这仍然是个坏主意。)
  ///
  /// See also:
  /// * [correctBy]，它是[ViewportOffset]的一个方法，被视窗渲染对象用来修正布局过程中的
  ///   偏移，而不通知它的监听器。
  /// * [jumpTo]，非布局中的情况下对位置进行更改，并立即应用新的位置。
  /// * [animateTo]，类似于[jumpTo]，但动画方式达到目的偏移位置。
  ///
  void correctPixels(double value) {
    _pixels = value;
  }

  /// Apply a layout-time correction to the scroll offset.
  ///
  /// This method should change the [pixels] value by `correction`, but without
  /// calling [notifyListeners]. It is called during layout by the
  /// [RenderViewport], before [applyContentDimensions]. After this method is
  /// called, the layout will be recomputed and that may result in this method
  /// being called again, though this should be very rare.
  ///
  /// See also:
  ///
  ///  * [jumpTo], for also changing the scroll position when not in layout.
  ///    [jumpTo] applies the change immediately and notifies its listeners.
  ///  * [correctPixels], which is used by the [ScrollPosition] itself to
  ///    set the offset initially during construction or after
  ///    [applyViewportDimension] or [applyContentDimensions] is called.
  @override
  void correctBy(double correction) {
    _pixels = _pixels! + correction;
    _didChangeViewportDimensionOrReceiveCorrection = true;
  }

  /// Change the value of [pixels] to the new value, and notify any customers,
  /// but without honoring normal conventions for changing the scroll offset.
  ///
  /// This is used to implement [jumpTo]. It can also be used adjust the
  /// position when the dimensions of the viewport change. It should only be
  /// used when manually implementing the logic for honoring the relevant
  /// conventions of the class. For example, [ScrollPositionWithSingleContext]
  /// introduces [ScrollActivity] objects and uses [forcePixels] in conjunction
  /// with adjusting the activity, e.g. by calling
  /// [ScrollPositionWithSingleContext.goIdle], so that the activity does
  /// not immediately set the value back. (Consider, for instance, a case where
  /// one is using a [DrivenScrollActivity]. That object will ignore any calls
  /// to [forcePixels], which would result in the rendering stuttering: changing
  /// in response to [forcePixels], and then changing back to the next value
  /// derived from the animation.)
  ///
  /// To cause the position to jump or animate to a new value, consider [jumpTo]
  /// or [animateTo].
  ///
  /// This should not be called during layout (e.g. when setting the initial
  /// scroll offset). Consider [correctPixels] if you find you need to adjust
  /// the position during layout.
  @protected
  void forcePixels(double value) {
    assert(hasPixels);
    assert(value != null);
    _impliedVelocity = value - pixels;
    _pixels = value;
    notifyListeners();
    SchedulerBinding.instance!.addPostFrameCallback((Duration timeStamp) {
      _impliedVelocity = 0;
    });
  }

  /// Called whenever scrolling ends, to store the current scroll offset in a
  /// storage mechanism with a lifetime that matches the app's lifetime.
  ///
  /// The stored value will be used by [restoreScrollOffset] when the
  /// [ScrollPosition] is recreated, in the case of the [Scrollable] being
  /// disposed then recreated in the same session. This might happen, for
  /// instance, if a [ListView] is on one of the pages inside a [TabBarView],
  /// and that page is displayed, then hidden, then displayed again.
  ///
  /// The default implementation writes the [pixels] using the nearest
  /// [PageStorage] found from the [context]'s [ScrollContext.storageContext]
  /// property.
  // TODO(goderbauer): Deprecate this when state restoration supports all features of PageStorage.
  @protected
  void saveScrollOffset() {
    PageStorage.of(context.storageContext)?.writeState(context.storageContext, pixels);
  }

  /// Called whenever the [ScrollPosition] is created, to restore the scroll
  /// offset if possible.
  ///
  /// The value is stored by [saveScrollOffset] when the scroll position
  /// changes, so that it can be restored in the case of the [Scrollable] being
  /// disposed then recreated in the same session. This might happen, for
  /// instance, if a [ListView] is on one of the pages inside a [TabBarView],
  /// and that page is displayed, then hidden, then displayed again.
  ///
  /// The default implementation reads the value from the nearest [PageStorage]
  /// found from the [context]'s [ScrollContext.storageContext] property, and
  /// sets it using [correctPixels], if [pixels] is still null.
  ///
  /// This method is called from the constructor, so layout has not yet
  /// occurred, and the viewport dimensions aren't yet known when it is called.
  // TODO(goderbauer): Deprecate this when state restoration supports all features of PageStorage.
  @protected
  void restoreScrollOffset() {
    if (!hasPixels) {
      final double? value = PageStorage.of(context.storageContext)?.readState(context.storageContext) as double?;
      if (value != null)
        correctPixels(value);
    }
  }

  /// Called by [context] to restore the scroll offset to the provided value.
  ///
  /// The provided value has previously been provided to the [context] by
  /// calling [ScrollContext.saveOffset], e.g. from [saveOffset].
  ///
  /// This method may be called right after the scroll position is created
  /// before layout has occurred. In that case, `initialRestore` is set to true
  /// and the viewport dimensions will not be known yet. If the [context]
  /// doesn't have any information to restore the scroll offset this method is
  /// not called.
  ///
  /// The method may be called multiple times in the lifecycle of a
  /// [ScrollPosition] to restore it to different scroll offsets.
  void restoreOffset(double offset, {bool initialRestore = false}) {
    assert(initialRestore != null);
    assert(offset != null);
    if (initialRestore) {
      correctPixels(offset);
    } else {
      jumpTo(offset);
    }
  }

  /// Called whenever scrolling ends, to persist the current scroll offset for
  /// state restoration purposes.
  ///
  /// The default implementation stores the current value of [pixels] on the
  /// [context] by calling [ScrollContext.saveOffset]. At a later point in time
  /// or after the application restarts, the [context] may restore the scroll
  /// position to the persisted offset by calling [restoreOffset].
  @protected
  void saveOffset() {
    assert(hasPixels);
    context.saveOffset(pixels);
  }

  /// 通过应用边界条件返回overscroll
  ///
  /// 如果给定的值在边界内，返回0.0。否则，返回由于边界条件而不能应用于[pixels]的值的量。
  /// 如果[physics]允许越界滚动，本方法总是返回0.0。
  ///
  /// 默认是由[physics]对象的[ScrollPhysics.applyBoundaryConditions]来实现具体逻辑
  @protected
  double applyBoundaryConditions(double value) {
    final double result = physics.applyBoundaryConditions(this, value);
    return result;
  }

  bool _didChangeViewportDimensionOrReceiveCorrection = true;

  @override
  bool applyViewportDimension(double viewportDimension) {
    if (_viewportDimension != viewportDimension) {
      _viewportDimension = viewportDimension;
      _didChangeViewportDimensionOrReceiveCorrection = true;
      // If this is called, you can rely on applyContentDimensions being called
      // soon afterwards in the same layout phase. So we put all the logic that
      // relies on both values being computed into applyContentDimensions.
    }
    return true;
  }

  bool _pendingDimensions = false;
  ScrollMetrics? _lastMetrics;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    assert(minScrollExtent != null);
    assert(maxScrollExtent != null);
    assert(haveDimensions == (_lastMetrics != null));
    if (!nearEqual(_minScrollExtent, minScrollExtent, Tolerance.defaultTolerance.distance) ||
        !nearEqual(_maxScrollExtent, maxScrollExtent, Tolerance.defaultTolerance.distance) ||
        _didChangeViewportDimensionOrReceiveCorrection) {
      assert(minScrollExtent != null);
      assert(maxScrollExtent != null);
      assert(minScrollExtent <= maxScrollExtent);
      _minScrollExtent = minScrollExtent;
      _maxScrollExtent = maxScrollExtent;
      final ScrollMetrics? currentMetrics = haveDimensions ? copyWith() : null;
      _didChangeViewportDimensionOrReceiveCorrection = false;
      _pendingDimensions = true;
      if (haveDimensions && !correctForNewDimensions(_lastMetrics!, currentMetrics!)) {
        return false;
      }
      _haveDimensions = true;
    }
    assert(haveDimensions);
    if (_pendingDimensions) {
      applyNewDimensions();
      _pendingDimensions = false;
    }
    assert(!_didChangeViewportDimensionOrReceiveCorrection, 'Use correctForNewDimensions() (and return true) to change the scroll offset during applyContentDimensions().');
    _lastMetrics = copyWith();
    return true;
  }

  /// Verifies that the new content and viewport dimensions are acceptable.
  ///
  /// Called by [applyContentDimensions] to determine its return value.
  ///
  /// Should return true if the current scroll offset is correct given
  /// the new content and viewport dimensions.
  ///
  /// Otherwise, should call [correctPixels] to correct the scroll
  /// offset given the new dimensions, and then return false.
  ///
  /// This is only called when [haveDimensions] is true.
  ///
  /// The default implementation defers to [ScrollPhysics.adjustPositionForNewDimensions].
  @protected
  bool correctForNewDimensions(ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    final double newPixels = physics.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: activity!.isScrolling,
      velocity: activity!.velocity,
    );
    if (newPixels != pixels) {
      correctPixels(newPixels);
      return false;
    }
    return true;
  }

  /// Notifies the activity that the dimensions of the underlying viewport or
  /// contents have changed.
  ///
  /// Called after [applyViewportDimension] or [applyContentDimensions] have
  /// changed the [minScrollExtent], the [maxScrollExtent], or the
  /// [viewportDimension]. When this method is called, it should be called
  /// _after_ any corrections are applied to [pixels] using [correctPixels], not
  /// before.
  ///
  /// The default implementation informs the [activity] of the new dimensions by
  /// calling its [ScrollActivity.applyNewDimensions] method.
  ///
  /// See also:
  ///
  ///  * [applyViewportDimension], which is called when new
  ///    viewport dimensions are established.
  ///  * [applyContentDimensions], which is called after new
  ///    viewport dimensions are established, and also if new content dimensions
  ///    are established, and which calls [ScrollPosition.applyNewDimensions].
  @protected
  @mustCallSuper
  void applyNewDimensions() {
    assert(hasPixels);
    assert(_pendingDimensions);
    activity!.applyNewDimensions();
    _updateSemanticActions(); // will potentially request a semantics update.
  }

  Set<SemanticsAction>? _semanticActions;

  /// Called whenever the scroll position or the dimensions of the scroll view
  /// change to schedule an update of the available semantics actions. The
  /// actual update will be performed in the next frame. If non is pending
  /// a frame will be scheduled.
  ///
  /// For example: If the scroll view has been scrolled all the way to the top,
  /// the action to scroll further up needs to be removed as the scroll view
  /// cannot be scrolled in that direction anymore.
  ///
  /// This method is potentially called twice per frame (if scroll position and
  /// scroll view dimensions both change) and therefore shouldn't do anything
  /// expensive.
  void _updateSemanticActions() {
    final SemanticsAction forward;
    final SemanticsAction backward;
    switch (axisDirection) {
      case AxisDirection.up:
        forward = SemanticsAction.scrollDown;
        backward = SemanticsAction.scrollUp;
        break;
      case AxisDirection.right:
        forward = SemanticsAction.scrollLeft;
        backward = SemanticsAction.scrollRight;
        break;
      case AxisDirection.down:
        forward = SemanticsAction.scrollUp;
        backward = SemanticsAction.scrollDown;
        break;
      case AxisDirection.left:
        forward = SemanticsAction.scrollRight;
        backward = SemanticsAction.scrollLeft;
        break;
    }

    final Set<SemanticsAction> actions = <SemanticsAction>{};
    if (pixels > minScrollExtent)
      actions.add(backward);
    if (pixels < maxScrollExtent)
      actions.add(forward);

    if (setEquals<SemanticsAction>(actions, _semanticActions))
      return;

    _semanticActions = actions;
    context.setSemanticsActions(_semanticActions!);
  }

  /// Animates the position such that the given object is as visible as possible
  /// by just scrolling this position.
  ///
  /// The optional `targetRenderObject` parameter is used to determine which area
  /// of that object should be as visible as possible. If `targetRenderObject`
  /// is null, the entire [RenderObject] (as defined by its
  /// [RenderObject.paintBounds]) will be as visible as possible. If
  /// `targetRenderObject` is provided, it must be a descendant of the object.
  ///
  /// See also:
  ///
  ///  * [ScrollPositionAlignmentPolicy] for the way in which `alignment` is
  ///    applied, and the way the given `object` is aligned.
  Future<void> ensureVisible(
      RenderObject object, {
        double alignment = 0.0,
        Duration duration = Duration.zero,
        Curve curve = Curves.ease,
        ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
        RenderObject? targetRenderObject,
      }) {
    assert(alignmentPolicy != null);
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object)!;
    assert(viewport != null);

    Rect? targetRect;
    if (targetRenderObject != null && targetRenderObject != object) {
      targetRect = MatrixUtils.transformRect(
          targetRenderObject.getTransformTo(object),
          object.paintBounds.intersect(targetRenderObject.paintBounds)
      );
    }

    double target;
    switch (alignmentPolicy) {
      case ScrollPositionAlignmentPolicy.explicit:
        target = viewport.getOffsetToReveal(object, alignment, rect: targetRect).offset.clamp(minScrollExtent, maxScrollExtent);
        break;
      case ScrollPositionAlignmentPolicy.keepVisibleAtEnd:
        target = viewport.getOffsetToReveal(object, 1.0, rect: targetRect).offset.clamp(minScrollExtent, maxScrollExtent);
        if (target < pixels) {
          target = pixels;
        }
        break;
      case ScrollPositionAlignmentPolicy.keepVisibleAtStart:
        target = viewport.getOffsetToReveal(object, 0.0, rect: targetRect).offset.clamp(minScrollExtent, maxScrollExtent);
        if (target > pixels) {
          target = pixels;
        }
        break;
    }

    if (target == pixels)
      return Future<void>.value();

    if (duration == Duration.zero) {
      jumpTo(target);
      return Future<void>.value();
    }

    return animateTo(target, duration: duration, curve: curve);
  }

  /// This notifier's value is true if a scroll is underway and false if the scroll
  /// position is idle.
  ///
  /// Listeners added by stateful widgets should be removed in the widget's
  /// [State.dispose] method.
  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);

  /// Animates the position from its current value to the given value.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// The returned [Future] will complete when the animation ends, whether it
  /// completed successfully or whether it was interrupted prematurely.
  ///
  /// An animation will be interrupted whenever the user attempts to scroll
  /// manually, or whenever another activity is started, or whenever the
  /// animation reaches the edge of the viewport and attempts to overscroll. (If
  /// the [ScrollPosition] does not overscroll but instead allows scrolling
  /// beyond the extents, then going beyond the extents will not interrupt the
  /// animation.)
  ///
  /// The animation is indifferent to changes to the viewport or content
  /// dimensions.
  ///
  /// Once the animation has completed, the scroll position will attempt to
  /// begin a ballistic activity in case its value is not stable (for example,
  /// if it is scrolled beyond the extents and in that situation the scroll
  /// position would normally bounce back).
  ///
  /// The duration must not be zero. To jump to a particular value without an
  /// animation, use [jumpTo].
  ///
  /// The animation is typically handled by an [DrivenScrollActivity].
  @override
  Future<void> animateTo(
      double to, {
        required Duration duration,
        required Curve curve,
      });

  /// 将滚动位置从当前值跳转到给定值，没有动画，也不检查新值是否在范围内。
  ///
  /// 任何活动的动画都会被取消。如果用户当前正在滚动，则该动作被取消。
  ///
  /// 如果本方法改变了滚动位置，将发送开始/更新/结束 一系列滚动通知。此方法不会产生overscroll通知。
  ///
  @override
  void jumpTo(double value);

  /// Changes the scrolling position based on a pointer signal from current
  /// value to delta without animation and without checking if new value is in
  /// range, taking min/max scroll extent into account.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// This method dispatches the start/update/end sequence of scrolling
  /// notifications.
  ///
  /// This method is very similar to [jumpTo], but [pointerScroll] will
  /// update the [ScrollDirection].
  ///
  // TODO(YeungKC): Support trackpad scroll, https://github.com/flutter/flutter/issues/23604.
  void pointerScroll(double delta);

  /// Calls [jumpTo] if duration is null or [Duration.zero], otherwise
  /// [animateTo] is called.
  ///
  /// If [clamp] is true (the default) then [to] is adjusted to prevent over or
  /// underscroll.
  ///
  /// If [animateTo] is called then [curve] defaults to [Curves.ease].
  @override
  Future<void> moveTo(
      double to, {
        Duration? duration,
        Curve? curve,
        bool? clamp = true,
      }) {

    if (clamp!)
      to = to.clamp(minScrollExtent, maxScrollExtent);

    return super.moveTo(to, duration: duration, curve: curve);
  }

  @override
  bool get allowImplicitScrolling => physics.allowImplicitScrolling;

  /// Deprecated. Use [jumpTo] or a custom [ScrollPosition] instead.
  @Deprecated('This will lead to bugs.') // ignore: flutter_deprecation_syntax, https://github.com/flutter/flutter/issues/44609
  void jumpToWithoutSettling(double value);


  /// Stop the current activity and start a [HoldScrollActivity].
  ScrollHoldController hold(VoidCallback holdCancelCallback);

  ///
  /// Start a drag activity corresponding to the given [DragStartDetails].
  ///
  /// The `onDragCanceled` argument will be invoked if the drag is ended
  /// prematurely (e.g. from another activity taking over). See
  /// [ScrollDragController.onDragCanceled] for details.
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback);

  /// The currently operative [ScrollActivity].
  ///
  /// If the scroll position is not performing any more specific activity, the
  /// activity will be an [IdleScrollActivity]. To determine whether the scroll
  /// position is idle, check the [isScrollingNotifier].
  ///
  /// Call [beginActivity] to change the current activity.
  @protected
  @visibleForTesting
  ScrollActivity? get activity => _activity;
  ScrollActivity? _activity;

  /// 更改当前 [activity]，dispose旧活动，必要时发送滚动通知。
  ///
  /// 如果参数为空，这个方法就没有任何效果。这对于新的活动是从另一个方法获得的，而该方法可能
  /// 返回null的情况很方便，因为这意味着调用者不必显式地检查参数的null。
  ///
  void beginActivity(ScrollActivity? newActivity) {
    if (newActivity == null)
      return;
    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity!.shouldIgnorePointer;
      wasScrolling = _activity!.isScrolling;
      if (wasScrolling && !newActivity.isScrolling)
        didEndScroll(); // notifies and then saves the scroll offset
      _activity!.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;
    if (oldIgnorePointer != activity!.shouldIgnorePointer)
      context.setIgnorePointer(activity!.shouldIgnorePointer);
    isScrollingNotifier.value = activity!.isScrolling;
    if (!wasScrolling && _activity!.isScrolling)
      didStartScroll();
  }


  // 通知的分发

  // NOTIFICATION DISPATCH

  /// 由[beginActivity]调用，报告活动何时开始。
  /// 本质也是调用Notification将通知往上冒泡发送出去
  void didStartScroll() {
    activity!.dispatchScrollStartNotification(copyWith(), context.notificationContext);
  }

  /// Called by [setPixels] to report a change to the [pixels] position.
  void didUpdateScrollPositionBy(double delta) {
    activity!.dispatchScrollUpdateNotification(copyWith(), context.notificationContext!, delta);
  }

  /// Called by [beginActivity] to report when an activity has ended.
  ///
  /// This also saves the scroll offset using [saveScrollOffset].
  void didEndScroll() {
    activity!.dispatchScrollEndNotification(copyWith(), context.notificationContext!);
    saveOffset();
    if (keepScrollOffset)
      saveScrollOffset();
  }

  /// Called by [setPixels] to report overscroll when an attempt is made to
  /// change the [pixels] position. Overscroll is the amount of change that was
  /// not applied to the [pixels] value.
  void didOverscrollBy(double value) {
    assert(activity!.isScrolling);
    activity!.dispatchOverscrollNotification(copyWith(), context.notificationContext!, value);
  }

  /// Dispatches a notification that the [userScrollDirection] has changed.
  ///
  /// Subclasses should call this function when they change [userScrollDirection].
  void didUpdateScrollDirection(ScrollDirection direction) {
    UserScrollNotification(metrics: copyWith(), context: context.notificationContext!, direction: direction).dispatch(context.notificationContext);
  }

  /// Provides a heuristic to determine if expensive frame-bound tasks should be
  /// deferred.
  ///
  /// The actual work of this is delegated to the [physics] via
  /// [ScrollPhysics.recommendDeferredLoading] called with the current
  /// [activity]'s [ScrollActivity.velocity].
  ///
  /// Returning true from this method indicates that the [ScrollPhysics]
  /// evaluate the current scroll velocity to be great enough that expensive
  /// operations impacting the UI should be deferred.
  bool recommendDeferredLoading(BuildContext context) {
    return physics.recommendDeferredLoading(
      activity!.velocity + _impliedVelocity,
      copyWith(),
      context,
    );
  }

  @override
  void dispose() {
    activity?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    super.dispose();
  }

  @override
  void notifyListeners() {
    _updateSemanticActions(); // will potentially request a semantics update.
    super.notifyListeners();
  }


}
