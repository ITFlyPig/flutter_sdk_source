/// 一个内部较大的渲染对象的基类。
///
/// 这个渲染对象提供了在[RenderBox]内承载[RenderSliver]的共享代码。视窗建立了一个[axisDirection]，
/// 它为sliver的坐标系确定方向，该坐标系是基于滚动偏移而不是笛卡尔坐标。
///
/// 视窗还监听一个[offset]，它决定了输入到sliver布局协议的[SliverConstraints.scrollOffset]
///
/// 子类通常会重写[performLayout]并调用[layoutChildSequence]，也许会调用多次。
///
/// See also:
///
/// * [RenderSliver]，它解释了更多关于Sliver协议的内容。
/// * [RenderBox]，它解释了更多关于Box协议的内容。
/// * [RenderSliverToBoxAdapter]，它允许一个[RenderBox]对象放置在一个[RenderSliver]里面（与这个类相反）。
///
///
abstract class RenderViewportBase<ParentDataClass extends ContainerParentDataMixin<RenderSliver>>
    extends RenderBox with ContainerRenderObjectMixin<RenderSliver, ParentDataClass>
    implements RenderAbstractViewport {
  /// Initializes fields for subclasses.
  ///
  /// The [cacheExtent], if null, defaults to [RenderAbstractViewport.defaultCacheExtent].
  ///
  /// The [cacheExtent] must be specified if [cacheExtentStyle] is not [CacheExtentStyle.pixel].
  RenderViewportBase({
    AxisDirection axisDirection = AxisDirection.down,
    required AxisDirection crossAxisDirection,
    required ViewportOffset offset,
    double? cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    Clip clipBehavior = Clip.hardEdge,
  }) : assert(axisDirection != null),
        assert(crossAxisDirection != null),
        assert(offset != null),
        assert(axisDirectionToAxis(axisDirection) != axisDirectionToAxis(crossAxisDirection)),
        assert(cacheExtentStyle != null),
        assert(cacheExtent != null || cacheExtentStyle == CacheExtentStyle.pixel),
        assert(clipBehavior != null),
        _axisDirection = axisDirection,
        _crossAxisDirection = crossAxisDirection,
        _offset = offset,
        _cacheExtent = cacheExtent ?? RenderAbstractViewport.defaultCacheExtent,
        _cacheExtentStyle = cacheExtentStyle,
        _clipBehavior = clipBehavior;

  /// Report the semantics of this node, for example for accessibility purposes.
  ///
  /// [RenderViewportBase] adds [RenderViewport.useTwoPaneSemantics] to the
  /// provided [SemanticsConfiguration] to support children using
  /// [RenderViewport.excludeFromScrolling].
  ///
  /// This method should be overridden by subclasses that have interesting
  /// semantic information. Overriding subclasses should call
  /// `super.describeSemanticsConfiguration(config)` to ensure
  /// [RenderViewport.useTwoPaneSemantics] is still added to `config`.
  ///
  /// See also:
  ///
  /// * [RenderObject.describeSemanticsConfiguration], for important
  ///   details about not mutating a [SemanticsConfiguration] out of context.
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.addTagForChildren(RenderViewport.useTwoPaneSemantics);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    childrenInPaintOrder
        .where((RenderSliver sliver) => sliver.geometry!.visible || sliver.geometry!.cacheExtent > 0.0)
        .forEach(visitor);
  }

  /// The direction in which the [SliverConstraints.scrollOffset] increases.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
  /// offset of zero is at the top of the viewport and increases towards the
  /// bottom of the viewport.
  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _axisDirection)
      return;
    _axisDirection = value;
    markNeedsLayout();
  }

  /// The direction in which child should be laid out in the cross axis.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], this property
  /// is typically [AxisDirection.left] if the ambient [TextDirection] is
  /// [TextDirection.rtl] and [AxisDirection.right] if the ambient
  /// [TextDirection] is [TextDirection.ltr].
  AxisDirection get crossAxisDirection => _crossAxisDirection;
  AxisDirection _crossAxisDirection;
  set crossAxisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _crossAxisDirection)
      return;
    _crossAxisDirection = value;
    markNeedsLayout();
  }

  /// The axis along which the viewport scrolls.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], then the
  /// [axis] is [Axis.vertical] and the viewport scrolls vertically.
  Axis get axis => axisDirectionToAxis(axisDirection);

  /// 决定视窗内的哪部分内容应该是可见的。
  ///
  /// [ViewportOffset.pixel]值决定了视窗 显示其哪一部分内容的 滚动偏移量。当用户滚动视窗
  /// 时，这个值会改变，从而改变显示的内容。
  ///
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  ///设置offset
  set offset(ViewportOffset value) {
    if (value == _offset)
      return;
    if (attached)
      _offset.removeListener(markNeedsLayout);
    _offset = value;
    //监听视窗偏移量的改变
    if (attached)
      _offset.addListener(markNeedsLayout);
    // 即使新的偏移量与旧的偏移量具有相同的像素值，我们也需要布局，这样我们将应用我们的视窗和
    // 内容尺寸。
    markNeedsLayout();
  }

  // TODO(ianh): cacheExtent/cacheExtentStyle should be a single
  // object that specifies both the scalar value and the unit, not a
  // pair of independent setters. Changing that would allow a more
  // rational API and would let us make the getter non-nullable.

  /// {@template flutter.rendering.RenderViewportBase.cacheExtent}
  /// The viewport has an area before and after the visible area to cache items
  /// that are about to become visible when the user scrolls.
  ///
  /// Items that fall in this cache area are laid out even though they are not
  /// (yet) visible on screen. The [cacheExtent] describes how many pixels
  /// the cache area extends before the leading edge and after the trailing edge
  /// of the viewport.
  ///
  /// The total extent, which the viewport will try to cover with children, is
  /// [cacheExtent] before the leading edge + extent of the main axis +
  /// [cacheExtent] after the trailing edge.
  ///
  /// The cache area is also used to implement implicit accessibility scrolling
  /// on iOS: When the accessibility focus moves from an item in the visible
  /// viewport to an invisible item in the cache area, the framework will bring
  /// that item into view with an (implicit) scroll action.
  /// {@endtemplate}
  ///
  /// The getter can never return null, but the field is nullable
  /// because the setter can be set to null to reset the value to
  /// [RenderAbstractViewport.defaultCacheExtent] (in which case
  /// [cacheExtentStyle] must be [CacheExtentStyle.pixel]).
  ///
  /// See also:
  ///
  ///  * [cacheExtentStyle], which controls the units of the [cacheExtent].
  double? get cacheExtent => _cacheExtent;
  double _cacheExtent;
  set cacheExtent(double? value) {
    value ??= RenderAbstractViewport.defaultCacheExtent;
    assert(value != null);
    if (value == _cacheExtent)
      return;
    _cacheExtent = value;
    markNeedsLayout();
  }

  /// This value is set during layout based on the [CacheExtentStyle].
  ///
  /// When the style is [CacheExtentStyle.viewport], it is the main axis extent
  /// of the viewport multiplied by the requested cache extent, which is still
  /// expressed in pixels.
  double? _calculatedCacheExtent;

  /// {@template flutter.rendering.RenderViewportBase.cacheExtentStyle}
  /// Controls how the [cacheExtent] is interpreted.
  ///
  /// If set to [CacheExtentStyle.pixel], the [cacheExtent] will be
  /// treated as a logical pixels, and the default [cacheExtent] is
  /// [RenderAbstractViewport.defaultCacheExtent].
  ///
  /// If set to [CacheExtentStyle.viewport], the [cacheExtent] will be
  /// treated as a multiplier for the main axis extent of the
  /// viewport. In this case there is no default [cacheExtent]; it
  /// must be explicitly specified.
  /// {@endtemplate}
  ///
  /// Changing the [cacheExtentStyle] without also changing the [cacheExtent]
  /// is rarely the correct choice.
  CacheExtentStyle get cacheExtentStyle => _cacheExtentStyle;
  CacheExtentStyle _cacheExtentStyle;
  set cacheExtentStyle(CacheExtentStyle value) {
    assert(value != null);
    if (value == _cacheExtentStyle) {
      return;
    }
    _cacheExtentStyle = value;
    markNeedsLayout();
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  bool get isRepaintBoundary => true;

  /// 确定视窗部分children的大小和位置。
  ///
  /// 这个函数会是子类'performLayout'方法中的主要逻辑
  ///
  ///  布局从 "child "开始，根据 "advance "回调进行，一旦 "advance "返回null就停止。
  ///
  ///  * `scrollOffset`是传递给第一个子代的[SliverConstraints.scrollOffset]。滚动偏移
  ///     量（scroll offset）由[SliverGeometry.scrollExtent]调整后用于后续子代。
  ///  * `overlap`是要传递给第一个子代的[SliverConstraints.overlap]。后续子代的重叠由
  ///    [SliverGeometry.paintOrigin]和[SliverGeometry.paintExtent]调整。
  ///  * `layoutOffset`是放置第一个子代的布局偏移量。后续子代的布局偏移量由[SliverGeometry.layoutExtent]
  ///    更新。
  ///  * `remainingPaintExtent`是[SliverConstraints.remainingPaintExtent]传递给第一个子代。
  ///    后续子代的剩余绘制范围由[SliverGeometry.layoutExtent]更新。
  ///  * `mainAxisExtent`是传递给每个子节点的[SliverConstraints.viewportMainAxisExtent]。
  ///  * `crossAxisExtent` 是传递给每个子节点的 [SliverConstraints.crossAxisExtent]
  ///  * `growthDirection` 是传递给每个子节点的 [SliverConstraints.growthDirection]
  ///
  /// 返回遇到的第一个非零[SliverGeometry.scrollOffsetCorrection]，如果有的话。
  /// 否则返回0.0，一般的调用者会反复调用这个函数，直到返回0.0。
  @protected
  double layoutChildSequence({
    required RenderSliver? child,
    required double scrollOffset,
    required double overlap,
    required double layoutOffset,
    required double remainingPaintExtent,
    required double mainAxisExtent,
    required double crossAxisExtent,
    required GrowthDirection growthDirection,
    required RenderSliver? Function(RenderSliver child) advance,
    required double remainingCacheExtent,
    required double cacheOrigin,
  }) {
    assert(scrollOffset.isFinite);
    assert(scrollOffset >= 0.0);
    //获取对于本轮次布局，第一个child的布局偏移量
    final double initialLayoutOffset = layoutOffset;
    final ScrollDirection adjustedUserScrollDirection =
    applyGrowthDirectionToScrollDirection(offset.userScrollDirection, growthDirection);
    //计算最大绘制偏移量
    double maxPaintOffset = layoutOffset + overlap;

    double precedingScrollExtent = 0.0;

    while (child != null) {
      //确保滚动偏移量大于0
      final double sliverScrollOffset = scrollOffset <= 0.0 ? 0.0 : scrollOffset;
      //如果滚动偏移量太小，我们就调整paddedOrigin，因为对于该滚动偏移量，要求计算一个sliver的内容是没有意义的。
      // If the scrollOffset is too small we adjust the paddedOrigin because it
      // doesn't make sense to ask a sliver for content before its scroll
      // offset.
      final double correctedCacheOrigin = math.max(cacheOrigin, -sliverScrollOffset);
      final double cacheExtentCorrection = cacheOrigin - correctedCacheOrigin;

      assert(sliverScrollOffset >= correctedCacheOrigin.abs());
      assert(correctedCacheOrigin <= 0.0);
      assert(sliverScrollOffset >= 0.0);
      assert(cacheExtentCorrection <= 0.0);

      //开始child的测量和布局
      child.layout(SliverConstraints(
        axisDirection: axisDirection,
        growthDirection: growthDirection,
        userScrollDirection: adjustedUserScrollDirection,
        scrollOffset: sliverScrollOffset,
        precedingScrollExtent: precedingScrollExtent,
        overlap: maxPaintOffset - layoutOffset,
        remainingPaintExtent: math.max(0.0, remainingPaintExtent - layoutOffset + initialLayoutOffset),
        crossAxisExtent: crossAxisExtent,
        crossAxisDirection: crossAxisDirection,
        viewportMainAxisExtent: mainAxisExtent,
        remainingCacheExtent: math.max(0.0, remainingCacheExtent + cacheExtentCorrection),
        cacheOrigin: correctedCacheOrigin,
      ), parentUsesSize: true);

      final SliverGeometry childLayoutGeometry = child.geometry!;
      assert(childLayoutGeometry.debugAssertIsValid());

      // 如果有需要更正的地方，我们就得重新开始。
      if (childLayoutGeometry.scrollOffsetCorrection != null)
        return childLayoutGeometry.scrollOffsetCorrection!;

      // We use the child's paint origin in our coordinate system as the
      // layoutOffset we store in the child's parent data.
      // 在我们的坐标系中，使用子代的paint origin作为layoutOffset，该paint origin是我们存储在child的parent data里面的。
      //计算有效的布局偏移量 = 当前布局偏移量 + child的paintOrigin
      final double effectiveLayoutOffset = layoutOffset + childLayoutGeometry.paintOrigin;

      // `effectiveLayoutOffset` becomes meaningless once we moved past the trailing edge
      // because `childLayoutGeometry.layoutExtent` is zero. Using the still increasing
      // 'scrollOffset` to roughly position these invisible slivers in the right order.
      // 一旦我们移过了尾部边缘 ，`effectiveLayoutOffset`就变得毫无意义，因为`childLayoutGeometry.layoutExtent`为零。
      // 使用仍在增加的'scrollOffset'来大致将这些不可见的slivers按正确的顺序定位。
      // childLayoutGeometry.visible一般是据[paintExtent]的值是否大于0来判断
      if (childLayoutGeometry.visible || scrollOffset > 0) {
        //对于该child有效的布局偏移存储下来
        updateChildLayoutOffset(child, effectiveLayoutOffset, growthDirection);
      } else {
        //对于不可见的child，使用scrollOffset来按顺序大致定位
        updateChildLayoutOffset(child, -scrollOffset + initialLayoutOffset, growthDirection);
      }

      //更新最大的绘制偏移量
      maxPaintOffset = math.max(effectiveLayoutOffset + childLayoutGeometry.paintExtent, maxPaintOffset);
      //更新滚动偏移量
      scrollOffset -= childLayoutGeometry.scrollExtent;
      //更新前面消耗掉的滚动偏移量
      precedingScrollExtent += childLayoutGeometry.scrollExtent;
      //更新布局偏移量
      layoutOffset += childLayoutGeometry.layoutExtent;
      //更新缓存尺寸
      if (childLayoutGeometry.cacheExtent != 0.0) {
        remainingCacheExtent -= childLayoutGeometry.cacheExtent - cacheExtentCorrection;
        cacheOrigin = math.min(correctedCacheOrigin + childLayoutGeometry.cacheExtent, 0.0);
      }

      updateOutOfBandData(growthDirection, childLayoutGeometry);

      // move on to the next child
      //移动到下一个child
      child = advance(child);
    }

    // we made it without a correction, whee!
    // 没有需要纠正的了，good。
    return 0.0;
  }

  @override
  Rect describeApproximatePaintClip(RenderSliver child) {
    final Rect viewportClip = Offset.zero & size;
    // The child's viewportMainAxisExtent can be infinite when a
    // RenderShrinkWrappingViewport is given infinite constraints, such as when
    // it is the child of a Row or Column (depending on orientation).
    //
    // For example, a shrink wrapping render sliver may have infinite
    // constraints along the viewport's main axis but may also have bouncing
    // scroll physics, which will allow for some scrolling effect to occur.
    // We should just use the viewportClip - the start of the overlap is at
    // double.infinity and so it is effectively meaningless.
    if (child.constraints.overlap == 0 || !child.constraints.viewportMainAxisExtent.isFinite) {
      return viewportClip;
    }

    // Adjust the clip rect for this sliver by the overlap from the previous sliver.
    double left = viewportClip.left;
    double right = viewportClip.right;
    double top = viewportClip.top;
    double bottom = viewportClip.bottom;
    final double startOfOverlap = child.constraints.viewportMainAxisExtent - child.constraints.remainingPaintExtent;
    final double overlapCorrection = startOfOverlap + child.constraints.overlap;
    switch (applyGrowthDirectionToAxisDirection(axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
        top += overlapCorrection;
        break;
      case AxisDirection.up:
        bottom -= overlapCorrection;
        break;
      case AxisDirection.right:
        left += overlapCorrection;
        break;
      case AxisDirection.left:
        right -= overlapCorrection;
        break;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Rect describeSemanticsClip(RenderSliver? child) {
    assert(axis != null);

    if (_calculatedCacheExtent == null) {
      return semanticBounds;
    }

    switch (axis) {
      case Axis.vertical:
        return Rect.fromLTRB(
          semanticBounds.left,
          semanticBounds.top - _calculatedCacheExtent!,
          semanticBounds.right,
          semanticBounds.bottom + _calculatedCacheExtent!,
        );
      case Axis.horizontal:
        return Rect.fromLTRB(
          semanticBounds.left - _calculatedCacheExtent!,
          semanticBounds.top,
          semanticBounds.right + _calculatedCacheExtent!,
          semanticBounds.bottom,
        );
    }
  }

  /// 绘制
  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null)
      return;
    if (hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer = context.pushClipRect(needsCompositing, offset, Offset.zero & size, _paintContents,
          clipBehavior: clipBehavior, oldLayer: _clipRectLayer);
    } else {
      _clipRectLayer = null;
      _paintContents(context, offset);
    }
  }

  ClipRectLayer? _clipRectLayer;

  void _paintContents(PaintingContext context, Offset offset) {
    for (final RenderSliver child in childrenInPaintOrder) {
      if (child.geometry!.visible)
        context.paintChild(child, offset + paintOffsetOf(child));
    }
  }

  /// 命中测试
  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    double mainAxisPosition, crossAxisPosition;
    switch (axis) {
      case Axis.vertical:
        mainAxisPosition = position.dy;
        crossAxisPosition = position.dx;
        break;
      case Axis.horizontal:
        mainAxisPosition = position.dx;
        crossAxisPosition = position.dy;
        break;
    }
    final SliverHitTestResult sliverResult = SliverHitTestResult.wrap(result);
    for (final RenderSliver child in childrenInHitTestOrder) {
      if (!child.geometry!.visible) {
        continue;
      }
      final Matrix4 transform = Matrix4.identity();
      applyPaintTransform(child, transform); // 必须是可逆的
      //调用child开始测试
      final bool isHit = result.addWithOutOfBandPosition(
        paintTransform: transform,
        hitTest: (BoxHitTestResult result) {
          return child.hitTest(
            sliverResult,
            mainAxisPosition: computeChildMainAxisPosition(child, mainAxisPosition),
            crossAxisPosition: crossAxisPosition,
          );
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment, { Rect? rect }) {
    // Steps to convert `rect` (from a RenderBox coordinate system) to its
    // scroll offset within this viewport (not in the exact order):
    //
    // 1. Pick the outmost RenderBox (between which, and the viewport, there is
    // nothing but RenderSlivers) as an intermediate reference frame
    // (the `pivot`), convert `rect` to that coordinate space.
    //
    // 2. Convert `rect` from the `pivot` coordinate space to its sliver
    // parent's sliver coordinate system (i.e., to a scroll offset), based on
    // the axis direction and growth direction of the parent.
    //
    // 3. Convert the scroll offset to its sliver parent's coordinate space
    // using `childScrollOffset`, until we reach the viewport.
    //
    // 4. Make the final conversion from the outmost sliver to the viewport
    // using `scrollOffsetOf`.

    double leadingScrollOffset = 0.0;
    // Starting at `target` and walking towards the root:
    //  - `child` will be the last object before we reach this viewport, and
    //  - `pivot` will be the last RenderBox before we reach this viewport.
    RenderObject child = target;
    RenderBox? pivot;
    bool onlySlivers = target is RenderSliver; // ... between viewport and `target` (`target` included).
    while (child.parent != this) {
      final RenderObject parent = child.parent! as RenderObject;
      assert(parent != null, '$target must be a descendant of $this');
      if (child is RenderBox) {
        pivot = child;
      }
      if (parent is RenderSliver) {
        leadingScrollOffset += parent.childScrollOffset(child)!;
      } else {
        onlySlivers = false;
        leadingScrollOffset = 0.0;
      }
      child = parent;
    }

    // `rect` in the new intermediate coordinate system.
    final Rect rectLocal;
    // Our new reference frame render object's main axis extent.
    final double pivotExtent;
    final GrowthDirection growthDirection;

    // `leadingScrollOffset` is currently the scrollOffset of our new reference
    // frame (`pivot` or `target`), within `child`.
    if (pivot != null) {
      assert(pivot.parent != null);
      assert(pivot.parent != this);
      assert(pivot != this);
      assert(pivot.parent is RenderSliver);  // TODO(abarth): Support other kinds of render objects besides slivers.
      final RenderSliver pivotParent = pivot.parent! as RenderSliver;
      growthDirection = pivotParent.constraints.growthDirection;
      switch (axis) {
        case Axis.horizontal:
          pivotExtent = pivot.size.width;
          break;
        case Axis.vertical:
          pivotExtent = pivot.size.height;
          break;
      }
      rect ??= target.paintBounds;
      rectLocal = MatrixUtils.transformRect(target.getTransformTo(pivot), rect);
    } else if (onlySlivers) {
      // `pivot` does not exist. We'll have to make up one from `target`, the
      // innermost sliver.
      final RenderSliver targetSliver = target as RenderSliver;
      growthDirection = targetSliver.constraints.growthDirection;
      // TODO(LongCatIsLooong): make sure this works if `targetSliver` is a
      // persistent header, when #56413 relands.
      pivotExtent = targetSliver.geometry!.scrollExtent;
      if (rect == null) {
        switch (axis) {
          case Axis.horizontal:
            rect = Rect.fromLTWH(
              0, 0,
              targetSliver.geometry!.scrollExtent,
              targetSliver.constraints.crossAxisExtent,
            );
            break;
          case Axis.vertical:
            rect = Rect.fromLTWH(
              0, 0,
              targetSliver.constraints.crossAxisExtent,
              targetSliver.geometry!.scrollExtent,
            );
            break;
        }
      }
      rectLocal = rect;
    } else {
      assert(rect != null);
      return RevealedOffset(offset: offset.pixels, rect: rect!);
    }

    assert(pivotExtent != null);
    assert(rect != null);
    assert(rectLocal != null);
    assert(growthDirection != null);
    assert(child.parent == this);
    assert(child is RenderSliver);
    final RenderSliver sliver = child as RenderSliver;

    final double targetMainAxisExtent;
    // The scroll offset of `rect` within `child`.
    switch (applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
      case AxisDirection.up:
        leadingScrollOffset += pivotExtent - rectLocal.bottom;
        targetMainAxisExtent = rectLocal.height;
        break;
      case AxisDirection.right:
        leadingScrollOffset += rectLocal.left;
        targetMainAxisExtent = rectLocal.width;
        break;
      case AxisDirection.down:
        leadingScrollOffset += rectLocal.top;
        targetMainAxisExtent = rectLocal.height;
        break;
      case AxisDirection.left:
        leadingScrollOffset += pivotExtent - rectLocal.right;
        targetMainAxisExtent = rectLocal.width;
        break;
    }

    // So far leadingScrollOffset is the scroll offset of `rect` in the `child`
    // sliver's sliver coordinate system. The sign of this value indicates
    // whether the `rect` protrudes the leading edge of the `child` sliver. When
    // this value is non-negative and `child`'s `maxScrollObstructionExtent` is
    // greater than 0, we assume `rect` can't be obstructed by the leading edge
    // of the viewport (i.e. its pinned to the leading edge).
    final bool isPinned = sliver.geometry!.maxScrollObstructionExtent > 0 && leadingScrollOffset >= 0;

    // The scroll offset in the viewport to `rect`.
    leadingScrollOffset = scrollOffsetOf(sliver, leadingScrollOffset);

    // This step assumes the viewport's layout is up-to-date, i.e., if
    // offset.pixels is changed after the last performLayout, the new scroll
    // position will not be accounted for.
    final Matrix4 transform = target.getTransformTo(this);
    Rect targetRect = MatrixUtils.transformRect(transform, rect);
    final double extentOfPinnedSlivers = maxScrollObstructionExtentBefore(sliver);

    switch (sliver.constraints.growthDirection) {
      case GrowthDirection.forward:
        if (isPinned && alignment <= 0)
          return RevealedOffset(offset: double.infinity, rect: targetRect);
        leadingScrollOffset -= extentOfPinnedSlivers;
        break;
      case GrowthDirection.reverse:
        if (isPinned && alignment >= 1)
          return RevealedOffset(offset: double.negativeInfinity, rect: targetRect);
        // If child's growth direction is reverse, when viewport.offset is
        // `leadingScrollOffset`, it is positioned just outside of the leading
        // edge of the viewport.
        switch (axis) {
          case Axis.vertical:
            leadingScrollOffset -= targetRect.height;
            break;
          case Axis.horizontal:
            leadingScrollOffset -= targetRect.width;
            break;
        }
        break;
    }

    final double mainAxisExtent;
    switch (axis) {
      case Axis.horizontal:
        mainAxisExtent = size.width - extentOfPinnedSlivers;
        break;
      case Axis.vertical:
        mainAxisExtent = size.height - extentOfPinnedSlivers;
        break;
    }

    final double targetOffset = leadingScrollOffset - (mainAxisExtent - targetMainAxisExtent) * alignment;
    final double offsetDifference = offset.pixels - targetOffset;

    switch (axisDirection) {
      case AxisDirection.down:
        targetRect = targetRect.translate(0.0, offsetDifference);
        break;
      case AxisDirection.right:
        targetRect = targetRect.translate(offsetDifference, 0.0);
        break;
      case AxisDirection.up:
        targetRect = targetRect.translate(0.0, -offsetDifference);
        break;
      case AxisDirection.left:
        targetRect = targetRect.translate(-offsetDifference, 0.0);
        break;
    }

    return RevealedOffset(offset: targetOffset, rect: targetRect);
  }

  /// The offset at which the given `child` should be painted.
  ///
  /// The returned offset is from the top left corner of the inside of the
  /// viewport to the top left corner of the paint coordinate system of the
  /// `child`.
  ///
  /// See also:
  ///
  ///  * [paintOffsetOf], which uses the layout offset and growth direction
  ///    computed for the child during layout.
  @protected
  Offset computeAbsolutePaintOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection) {
    assert(hasSize); // this is only usable once we have a size
    assert(axisDirection != null);
    assert(growthDirection != null);
    assert(child != null);
    assert(child.geometry != null);
    switch (applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
      case AxisDirection.up:
        return Offset(0.0, size.height - (layoutOffset + child.geometry!.paintExtent));
      case AxisDirection.right:
        return Offset(layoutOffset, 0.0);
      case AxisDirection.down:
        return Offset(0.0, layoutOffset);
      case AxisDirection.left:
        return Offset(size.width - (layoutOffset + child.geometry!.paintExtent), 0.0);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(EnumProperty<AxisDirection>('crossAxisDirection', crossAxisDirection));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    RenderSliver? child = firstChild;
    if (child == null)
      return children;

    int count = indexOfFirstChild;
    while (true) {
      children.add(child!.toDiagnosticsNode(name: labelForChild(count)));
      if (child == lastChild)
        break;
      count += 1;
      child = childAfter(child);
    }
    return children;
  }

  // API TO BE IMPLEMENTED BY SUBCLASSES

  // setupParentData

  // performLayout (and optionally sizedByParent and performResize)

  /// Whether the contents of this viewport would paint outside the bounds of
  /// the viewport if [paint] did not clip.
  ///
  /// This property enables an optimization whereby [paint] can skip apply a
  /// clip of the contents of the viewport are known to paint entirely within
  /// the bounds of the viewport.
  @protected
  bool get hasVisualOverflow;

  /// 在[layoutChildSequence]中为每个child调用该方法
  ///
  /// 通常被子类用来更新任何带外数据（out-of-band ），如每个child的最大滚动范围。
  ///
  ///
  /// Called during [layoutChildSequence] for each child.
  ///
  /// Typically used by subclasses to update any out-of-band data, such as the
  /// max scroll extent, for each child.
  @protected
  void updateOutOfBandData(GrowthDirection growthDirection, SliverGeometry childLayoutGeometry);

  /// 在[layoutChildSequence]方法中调用，用以存储给定子代的布局偏移（layout offset）。
  ///
  /// 不同的子类对其children的布局偏移使用不同的表示方法（如逻辑或物理坐标）。这个函数让子
  /// 类在将child的布局偏移量存储到子类的parent data之前，对其进行转换。
  ///
  @protected
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset, GrowthDirection growthDirection);

  /// `child`应该在此偏移量处绘制
  ///
  /// 返回的偏移量是从视窗内部的左上角到 "child "的绘制坐标系的左上角。
  ///
  /// See also:
  ///
  ///  * [computeAbsolutePaintOffset]，它通过明确的布局偏移量（ layout offset）和增长
  ///    方向（growth direction）来计算绘制偏移量（paint offset），而不是使用布局期间为子代
  ///    计算的值。
  @protected
  Offset paintOffsetOf(RenderSliver child);

  /// Returns the scroll offset within the viewport for the given
  /// `scrollOffsetWithinChild` within the given `child`.
  ///
  /// The returned value is an estimate that assumes the slivers within the
  /// viewport do not change the layout extent in response to changes in their
  /// scroll offset.
  @protected
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild);

  /// Returns the total scroll obstruction extent of all slivers in the viewport
  /// before [child].
  ///
  /// This is the extent by which the actual area in which content can scroll
  /// is reduced. For example, an app bar that is pinned at the top will reduce
  /// the area in which content can actually scroll by the height of the app bar.
  @protected
  double maxScrollObstructionExtentBefore(RenderSliver child);

  /// Converts the `parentMainAxisPosition` into the child's coordinate system.
  ///
  /// The `parentMainAxisPosition` is a distance from the top edge (for vertical
  /// viewports) or left edge (for horizontal viewports) of the viewport bounds.
  /// This describes a line, perpendicular to the viewport's main axis, heretofore
  /// known as the target line.
  ///
  /// The child's coordinate system's origin in the main axis is at the leading
  /// edge of the given child, as given by the child's
  /// [SliverConstraints.axisDirection] and [SliverConstraints.growthDirection].
  ///
  /// This method returns the distance from the leading edge of the given child to
  /// the target line described above.
  ///
  /// (The `parentMainAxisPosition` is not from the leading edge of the
  /// viewport, it's always the top or left edge.)
  @protected
  double computeChildMainAxisPosition(RenderSliver child, double parentMainAxisPosition);

  /// The index of the first child of the viewport relative to the center child.
  ///
  /// For example, the center child has index zero and the first child in the
  /// reverse growth direction has index -1.
  @protected
  int get indexOfFirstChild;

  /// A short string to identify the child with the given index.
  ///
  /// Used by [debugDescribeChildren] to label the children.
  @protected
  String labelForChild(int index);

  /// Provides an iterable that walks the children of the viewport, in the order
  /// that they should be painted.
  ///
  /// This should be the reverse order of [childrenInHitTestOrder].
  @protected
  Iterable<RenderSliver> get childrenInPaintOrder;

  /// Provides an iterable that walks the children of the viewport, in the order
  /// that hit-testing should use.
  ///
  /// This should be the reverse order of [childrenInPaintOrder].
  @protected
  Iterable<RenderSliver> get childrenInHitTestOrder;

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!offset.allowImplicitScrolling) {
      return super.showOnScreen(
        descendant: descendant,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }

    final Rect? newRect = RenderViewportBase.showInViewport(
      descendant: descendant,
      viewport: this,
      offset: offset,
      rect: rect,
      duration: duration,
      curve: curve,
    );
    super.showOnScreen(
      rect: newRect,
      duration: duration,
      curve: curve,
    );
  }

  /// Make (a portion of) the given `descendant` of the given `viewport` fully
  /// visible in the `viewport` by manipulating the provided [ViewportOffset]
  /// `offset`.
  ///
  /// The optional `rect` parameter describes which area of the `descendant`
  /// should be shown in the viewport. If `rect` is null, the entire
  /// `descendant` will be revealed. The `rect` parameter is interpreted
  /// relative to the coordinate system of `descendant`.
  ///
  /// The returned [Rect] describes the new location of `descendant` or `rect`
  /// in the viewport after it has been revealed. See [RevealedOffset.rect]
  /// for a full definition of this [Rect].
  ///
  /// The parameters `viewport` and `offset` are required and cannot be null.
  /// If `descendant` is null, this is a no-op and `rect` is returned.
  ///
  /// If both `descendant` and `rect` are null, null is returned because there is
  /// nothing to be shown in the viewport.
  ///
  /// The `duration` parameter can be set to a non-zero value to animate the
  /// target object into the viewport with an animation defined by `curve`.
  ///
  /// See also:
  ///
  /// * [RenderObject.showOnScreen], overridden by [RenderViewportBase] and the
  ///   renderer for [SingleChildScrollView] to delegate to this method.
  static Rect? showInViewport({
    RenderObject? descendant,
    Rect? rect,
    required RenderAbstractViewport viewport,
    required ViewportOffset offset,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    assert(viewport != null);
    assert(offset != null);
    if (descendant == null) {
      return rect;
    }
    final RevealedOffset leadingEdgeOffset = viewport.getOffsetToReveal(descendant, 0.0, rect: rect);
    final RevealedOffset trailingEdgeOffset = viewport.getOffsetToReveal(descendant, 1.0, rect: rect);
    final double currentOffset = offset.pixels;

    //           scrollOffset
    //                       0 +---------+
    //                         |         |
    //                       _ |         |
    //    viewport position |  |         |
    // with `descendant` at |  |         | _
    //        trailing edge |_ | xxxxxxx |  | viewport position
    //                         |         |  | with `descendant` at
    //                         |         | _| leading edge
    //                         |         |
    //                     800 +---------+
    //
    // `trailingEdgeOffset`: Distance from scrollOffset 0 to the start of the
    //                       viewport on the left in image above.
    // `leadingEdgeOffset`: Distance from scrollOffset 0 to the start of the
    //                      viewport on the right in image above.
    //
    // The viewport position on the left is achieved by setting `offset.pixels`
    // to `trailingEdgeOffset`, the one on the right by setting it to
    // `leadingEdgeOffset`.

    final RevealedOffset targetOffset;
    if (leadingEdgeOffset.offset < trailingEdgeOffset.offset) {
      // `descendant` is too big to be visible on screen in its entirety. Let's
      // align it with the edge that requires the least amount of scrolling.
      final double leadingEdgeDiff = (offset.pixels - leadingEdgeOffset.offset).abs();
      final double trailingEdgeDiff = (offset.pixels - trailingEdgeOffset.offset).abs();
      targetOffset = leadingEdgeDiff < trailingEdgeDiff ? leadingEdgeOffset : trailingEdgeOffset;
    } else if (currentOffset > leadingEdgeOffset.offset) {
      // `descendant` currently starts above the leading edge and can be shown
      // fully on screen by scrolling down (which means: moving viewport up).
      targetOffset = leadingEdgeOffset;
    } else if (currentOffset < trailingEdgeOffset.offset) {
      // `descendant currently ends below the trailing edge and can be shown
      // fully on screen by scrolling up (which means: moving viewport down)
      targetOffset = trailingEdgeOffset;
    } else {
      // `descendant` is between leading and trailing edge and hence already
      //  fully shown on screen. No action necessary.
      final Matrix4 transform = descendant.getTransformTo(viewport.parent! as RenderObject);
      return MatrixUtils.transformRect(transform, rect ?? descendant.paintBounds);
    }

    assert(targetOffset != null);

    offset.moveTo(targetOffset.offset, duration: duration, curve: curve);
    return targetOffset.rect;
  }
}
