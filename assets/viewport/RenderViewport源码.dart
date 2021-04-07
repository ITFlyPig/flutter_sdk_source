///
/// 一个内部较大的渲染对象。
///
/// [RenderViewport]是滚动机制的视觉主力。它根据自己的尺寸和给定的[offset]显示其children。
/// 随着偏移量的变化，不同的children通过视口可见。
///
/// [RenderViewport]持有一个双向slivers列表，锚定在一个[center] 中心sliver上，该sliver
/// 被放置在零滚动偏移处。中心部件（center widget ）根据[anchor]属性显示在视窗中。
///
/// 在child列表中，比 [center] 更前面的sliver会从 [center] 开始按反向 [axisDirection]
/// 的顺序显示。例如，如果[axisDirection]是[AxisDirection.down]，则[center]之前的第一个
/// sliver被置于[center]之上。在child列表中比[center]后面的sliver按[axisDirection]的顺序放置。
/// 例如，在前面的场景中，[center]之后的第一个sliver被放置在[center]的下方。
///
/// [RenderViewport]不能直接包含[RenderBox]类型的child。取而代之的是使用[RenderSliverList]、
/// [RenderSliverFixedExtentList]、[RenderSliverGrid]或[RenderSliverToBoxAdapter]等。
///
/// See also:
/// * [RenderSliver]，它解释了更多关于Sliver协议的内容。
/// * [RenderBox]，它解释了更多关于Box协议的内容。
/// * RenderSliverToBoxAdapter]，它允许一个[RenderBox]对象放置在一个[RenderSliver]里面（与这个类相反）。
/// * [RenderShrinkWrappingViewport]，是[RenderViewport]的一个变种，沿主轴收缩包装其内容。
///
class RenderViewport extends RenderViewportBase<SliverPhysicalContainerParentData> {
  /// 为[RenderSliver]对象创建一个视窗。
  ///
  /// 如果没有指定[center]，则使用 "children "列表中的第一个child（如果有的话）。
  ///
  /// 必须指定[offset]。
  /// 如果为了测试的目的，可以考虑传递一个[new ViewportOffset.zero]或[new ViewportOffset.fixed]。
  ///
  RenderViewport({
    AxisDirection axisDirection = AxisDirection.down,
    required AxisDirection crossAxisDirection,
    required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver>? children,
    RenderSliver? center,
    double? cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    Clip clipBehavior = Clip.hardEdge,
  }) :
        _anchor = anchor,
        _center = center,
        super(
        axisDirection: axisDirection,
        crossAxisDirection: crossAxisDirection,
        offset: offset,
        cacheExtent: cacheExtent,
        cacheExtentStyle: cacheExtentStyle,
        clipBehavior: clipBehavior,
      ) {
    addAll(children);
    if (center == null && firstChild != null)
      _center = firstChild;
  }

  /// If a [RenderAbstractViewport] overrides
  /// [RenderObject.describeSemanticsConfiguration] to add the [SemanticsTag]
  /// [useTwoPaneSemantics] to its [SemanticsConfiguration], two semantics nodes
  /// will be used to represent the viewport with its associated scrolling
  /// actions in the semantics tree.
  ///
  /// Two semantics nodes (an inner and an outer node) are necessary to exclude
  /// certain child nodes (via the [excludeFromScrolling] tag) from the
  /// scrollable area for semantic purposes: The [SemanticsNode]s of children
  /// that should be excluded from scrolling will be attached to the outer node.
  /// The semantic scrolling actions and the [SemanticsNode]s of scrollable
  /// children will be attached to the inner node, which itself is a child of
  /// the outer node.
  ///
  /// See also:
  ///
  /// * [RenderViewportBase.describeSemanticsConfiguration], which adds this
  ///   tag to its [SemanticsConfiguration].
  static const SemanticsTag useTwoPaneSemantics = SemanticsTag('RenderViewport.twoPane');

  /// When a top-level [SemanticsNode] below a [RenderAbstractViewport] is
  /// tagged with [excludeFromScrolling] it will not be part of the scrolling
  /// area for semantic purposes.
  ///
  /// This behavior is only active if the [RenderAbstractViewport]
  /// tagged its [SemanticsConfiguration] with [useTwoPaneSemantics].
  /// Otherwise, the [excludeFromScrolling] tag is ignored.
  ///
  /// As an example, a [RenderSliver] that stays on the screen within a
  /// [Scrollable] even though the user has scrolled past it (e.g. a pinned app
  /// bar) can tag its [SemanticsNode] with [excludeFromScrolling] to indicate
  /// that it should no longer be considered for semantic actions related to
  /// scrolling.
  static const SemanticsTag excludeFromScrolling = SemanticsTag('RenderViewport.excludeFromScrolling');

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData)
      child.parentData = SliverPhysicalContainerParentData();
  }

  /// 零滚动偏移量的相对位置。
  ///
  /// 例如，如果[anchor]是0.5，而[axisDirection]是[AxisDirection.down]或[AxisDirection.up]，
  /// 那么零滚动偏移量在视窗的垂直中心。如果[anchor]是1.0，并且[axisDirection]是[AxisDirection.right]，
  /// 那么零滚动偏移量在视口的左边缘。
  ///
  double get anchor => _anchor;
  double _anchor;
  set anchor(double value) {
    assert(value != null);
    assert(value >= 0.0 && value <= 1.0);
    if (value == _anchor)
      return;
    _anchor = value;
    markNeedsLayout();
  }

  /// The first child in the [GrowthDirection.forward] growth direction.
  ///
  /// This child that will be at the position defined by [anchor] when the
  /// [ViewportOffset.pixels] of [offset] is `0`.
  ///
  /// Children after [center] will be placed in the [axisDirection] relative to
  /// the [center]. Children before [center] will be placed in the opposite of
  /// the [axisDirection] relative to the [center].
  ///
  /// The [center] must be a child of the viewport.
  RenderSliver? get center => _center;
  RenderSliver? _center;
  set center(RenderSliver? value) {
    if (value == _center)
      return;
    _center = value;
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  // 计算child的大小
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  static const int _maxLayoutCycles = 10;

  // Out-of-band data computed during layout.
  // 在布局期间计算的带外数据。
  late double _minScrollExtent;
  late double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  /// 开始布局
  @override
  void performLayout() {
    // 忽略applyViewportDimension的返回值，因为无论如何我们都在做布局。

    //设置viewport的尺寸，那就说明，在该performLayout方法之前，该viewport的尺寸已经测量好了
    // 属于RenderBox完全根据约束条件就能确定自己大小的类型
    //
    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
        break;
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
        break;
    }

    //没有中心sliver，直接不走后续布局流程
    if (center == null) {
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }

    //据不同的布局方向，分别获取主轴和副轴的尺寸
    final double mainAxisExtent;
    final double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        mainAxisExtent = size.height;
        crossAxisExtent = size.width;
        break;
      case Axis.horizontal:
        mainAxisExtent = size.width;
        crossAxisExtent = size.height;
        break;
    }

    //获取中心sliver的偏移量调整
    final double centerOffsetAdjustment = center!.centerOffsetAdjustment;

    //需要矫正的尺寸
    double correction;
    //记录总的尝试布局遍数
    int count = 0;
    do {
      //尝试布局，并返回需要矫正尺寸
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent, offset.pixels + centerOffsetAdjustment);

      if (correction != 0.0) {
        //如果有尺寸需要矫正，那么将矫正运用到偏移量，重新开始一轮布局
        offset.correctBy(correction);
      } else {
        //没有需要矫正的尺寸，则本次布局完成
        if (offset.applyContentDimensions(
          math.min(0.0, _minScrollExtent + mainAxisExtent * anchor),
          math.max(0.0, _maxScrollExtent - mainAxisExtent * (1.0 - anchor)),
        ))
          break;
      }
      //尝试布局次数
      count += 1;

    } while (count < _maxLayoutCycles);//一次布局，最多可以尝试布局10次
  }

  double _attemptLayout(double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);

    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _hasVisualOverflow = false;

    // centerOffset是指从RenderViewport的前缘到零滚动偏移量处位置的偏移量（正向sliver和反向sliver之间的线）。
    // centerOffset也就是第一个正向child的偏移量
    final double centerOffset = mainAxisExtent * anchor - correctedOffset;
    //反方向剩余的绘制尺寸
    final double reverseDirectionRemainingPaintExtent = centerOffset.clamp(0.0, mainAxisExtent);
    //正向剩余的绘制尺寸
    final double forwardDirectionRemainingPaintExtent = (mainAxisExtent - centerOffset).clamp(0.0, mainAxisExtent);

    //缓存区域样式
    switch (cacheExtentStyle) {
      case CacheExtentStyle.pixel:
        _calculatedCacheExtent = cacheExtent;
        break;
      case CacheExtentStyle.viewport:
        _calculatedCacheExtent = mainAxisExtent * _cacheExtent;
        break;
    }

    // 计算完整缓存区域尺寸
    final double fullCacheExtent = mainAxisExtent + 2 * _calculatedCacheExtent!;
    // 据centerOffset计算缓存区域的偏移量
    final double centerCacheOffset = centerOffset + _calculatedCacheExtent!;
    //反向剩余缓存尺寸
    final double reverseDirectionRemainingCacheExtent = centerCacheOffset.clamp(0.0, fullCacheExtent);
    //正向剩余缓存尺寸
    final double forwardDirectionRemainingCacheExtent = (fullCacheExtent - centerCacheOffset).clamp(0.0, fullCacheExtent);

    //center前面的child
    final RenderSliver? leadingNegativeChild = childBefore(center!);

    if (leadingNegativeChild != null) {
      // negative scroll offsets
      final double result = layoutChildSequence(
        child: leadingNegativeChild,
        scrollOffset: math.max(mainAxisExtent, centerOffset) - mainAxisExtent,
        overlap: 0.0,
        layoutOffset: forwardDirectionRemainingPaintExtent,
        remainingPaintExtent: reverseDirectionRemainingPaintExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent,
        growthDirection: GrowthDirection.reverse,
        advance: childBefore,
        remainingCacheExtent: reverseDirectionRemainingCacheExtent,
        cacheOrigin: (mainAxisExtent - centerOffset).clamp(-_calculatedCacheExtent!, 0.0),
      );
      if (result != 0.0)
        return -result;
    }

    //正的滚动偏移量
    // positive scroll offsets
    return layoutChildSequence(
      child: center, //center child
      scrollOffset: math.max(0.0, -centerOffset), //滚动偏移量
      overlap: leadingNegativeChild == null ? math.min(0.0, -centerOffset) : 0.0,
      //布局偏移计算方式
      layoutOffset: centerOffset >= mainAxisExtent ? centerOffset: reverseDirectionRemainingPaintExtent,
      //等价于：(layoutOffset: centerOffset >= mainAxisExtent ? centerOffset: centerOffset.clamp(0.0, mainAxisExtent),)
      remainingPaintExtent: forwardDirectionRemainingPaintExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: forwardDirectionRemainingCacheExtent,
      cacheOrigin: centerOffset.clamp(-_calculatedCacheExtent!, 0.0),
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
        break;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
        break;
    }
    if (childLayoutGeometry.hasVisualOverflow)
      _hasVisualOverflow = true;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection) {
    final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.paintOffset = computeAbsolutePaintOffset(child, layoutOffset, growthDirection);
  }

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
    return childParentData.paintOffset;
  }

  @override
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    assert(growthDirection != null);
    switch (growthDirection) {
      case GrowthDirection.forward:
        double scrollOffsetToChild = 0.0;
        RenderSliver? current = center;
        while (current != child) {
          scrollOffsetToChild += current!.geometry!.scrollExtent;
          current = childAfter(current);
        }
        return scrollOffsetToChild + scrollOffsetWithinChild;
      case GrowthDirection.reverse:
        double scrollOffsetToChild = 0.0;
        RenderSliver? current = childBefore(center!);
        while (current != child) {
          scrollOffsetToChild -= current!.geometry!.scrollExtent;
          current = childBefore(current);
        }
        return scrollOffsetToChild - scrollOffsetWithinChild;
    }
  }

  @override
  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    assert(growthDirection != null);
    switch (growthDirection) {
      case GrowthDirection.forward:
        double pinnedExtent = 0.0;
        RenderSliver? current = center;
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childAfter(current);
        }
        return pinnedExtent;
      case GrowthDirection.reverse:
        double pinnedExtent = 0.0;
        RenderSliver? current = childBefore(center!);
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childBefore(current);
        }
        return pinnedExtent;
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // Hit test logic relies on this always providing an invertible matrix.
    assert(child != null);
    final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  double computeChildMainAxisPosition(RenderSliver child, double parentMainAxisPosition) {
    assert(child != null);
    assert(child.constraints != null);
    final SliverPhysicalParentData childParentData = child.parentData! as SliverPhysicalParentData;
    switch (applyGrowthDirectionToAxisDirection(child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
        return parentMainAxisPosition - childParentData.paintOffset.dy;
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.paintOffset.dx;
      case AxisDirection.up:
        return child.geometry!.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dy);
      case AxisDirection.left:
        return child.geometry!.paintExtent - (parentMainAxisPosition - childParentData.paintOffset.dx);
    }
  }

  @override
  int get indexOfFirstChild {
    assert(center != null);
    assert(center!.parent == this);
    assert(firstChild != null);
    int count = 0;
    RenderSliver? child = center;
    while (child != firstChild) {
      count -= 1;
      child = childBefore(child!);
    }
    return count;
  }

  @override
  String labelForChild(int index) {
    if (index == 0)
      return 'center child';
    return 'child $index';
  }

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    if (firstChild == null)
      return;
    RenderSliver? child = firstChild;
    while (child != center) {
      yield child!;
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      yield child!;
      if (child == center)
        return;
      child = childBefore(child);
    }
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    if (firstChild == null)
      return;
    RenderSliver? child = center;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
    child = childBefore(center!);
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('anchor', anchor));
  }
}
