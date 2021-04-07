///
/// 在视窗中实现滚动效果的render object的基类
///
/// 一个[RenderViewport]有一个slivers子代的列表。每一个sliver--实际上是视窗内容的一个片
/// --都会依次铺设，在这个过程中覆盖视窗。(每个sliver每次都会被铺设，包括那些因为被 "滚动 "
/// 或超出视窗末端而尺寸（extent）为零的sliver。)
///
/// Sliver参与了_sliver协议，在[layout]过程中，每个sliver都会收到一个[SliverConstraints]
/// 对象，并计算输出一个相应的[SliverGeometry]来描述它在视窗中的位置。这类似于[RenderBox]
/// 使用的盒子协议，它得到一个[BoxConstraints]作为输入并计算出一个[Size]。
///
/// Sliver 有一个前缘，也就是 [SliverConstraints.scrollOffset] 所描述的这个 Sliver
/// 的位置开始的地方。Sliver 有几个维度，其中最主要的维度是 [SliverGeometry.paintExtent]，
/// 它描述了 Sliver 沿着主轴的尺寸，从前缘开始，到达视口的末端或 Sliver 的末端的尺寸，以先到者为准。
///
/// Sliver可以根据约束条件（constraints）的变化，以非线性的方式改变尺寸，实现各种滚动效果。
/// 例如，[SliverAppBar]所基于的各种[RenderSliverPersistentHeader]子类，可以实现诸如在
/// 滚动偏移的情况下仍然可见，或者根据用户的滚动方向（[SliverConstraints.userScrollDirection]）
/// 以不同的偏移量重新出现等效果。
///
/// ## 如何写一个RenderSliver的子类
///
/// Sliver 可以有 子代sliver ，或者来自另一个坐标系的子代，典型的是 box 子代。(关于 box
/// 协议的详细信息，请参见 [RenderBox])。(关于盒子协议的详细信息，请参见 [RenderBox]。)
/// Slivers也可以有不同的child模型，通常会有一个child，或者一个child列表的模型。
///
/// ### slivers的例子
///
/// 一个很好的例子是[RenderSliverPadding]，它有一个单独的子对象，而这个子对象本身也是一个sliver。
/// 像这样 sliver-to-sliver 的渲染对象必须为它的子对象构造一个 [SliverConstraints] 约束对象，
/// 然后必须使用它子对象的 [SliverGeometry] 来形成它自己的 [geometry]。
///
/// 另一种常见的one-child sliver是有一个[RenderBox]child的sliver。一个例子是 [RenderSliverToBoxAdapter]，
/// 它布置了一个单独的box，并在box周围调整自己的大小。这样的一个sliver必须使用它的[SliverConstraints]为
/// 子代创建一个[BoxConstraints]，将子代布局出来（使用子代的[layout]方法），然后使用子代的[RenderBox.size]
/// 来生成sliver的[SliverGeometry]。
///
/// 不过最常见的一种是sliver有多个子代。最直接的例子是[RenderSliverList]，它将它
/// 的子代在主轴方向上一个接一个地排列。和 one-box-child的sliver情况一样，它用它的[constraints]
/// 为子代创建一个[BoxConstraints]，然后用它所有子代的汇总信息来生成它的[geometry]。然而，
/// 与one-child案例不同的是，它在实际布局（以及随后绘制）哪些子代时是很谨慎的。如果滚动偏移量是 1000 像素，
/// 而它之前确定前三个子代的高度都是 400 像素，那么它将跳过前两个子代，从第三个子代开始布局。
///
/// ### 布局
///
/// 当它们被布局好时，sliver 确定了它们的 [geometry]，包括它们的大小 ([SliverGeometry.paintExtent])
/// 和下一个 sliver 的位置 ([SliverGeometry.layoutExtent])，以及它们每个子代的位置，这些
/// 都是基于来自视窗的输入[constraints]  ，例如滚动偏移 ([SliverConstraints.scrollOffset])。
///
/// 例如，一个仅仅绘制了一个100像素高的box的sliver，当滚动偏移量为零时，会说它的[SliverGeometry.paintExtent]
/// 是100像素，但当滚动偏移量为75像素时，会说它的[SliverGeometry.paintExtent]是25像素，
/// 当滚动偏移量为100像素或更多时，会说它是零。(这是假设 [SliverConstraints.remainPaintExtent] 超
/// 过 100 像素。)
///
/// 提供给本系统作为输入的各种维度都在[constraints]中。在[SliverConstraints]类的文档中对
/// 它们进行了详细的描述。
///
/// [performLayout]函数必须接受这些[constraints]并创建一个[SliverGeometry]对象，然后将
/// 其分配给[geometry]属性。可以配置的geometry的不同维度在 [SliverGeometry] 类的文档中
/// 有详细描述。
///
/// ### 绘制
///
/// 除了实现布局，sliver 还必须实现绘制。这可以通过覆盖 [paint] 方法来实现。
///
/// 会以[Offset]为参数调用[painting]方法，该[Offset]表示从[Canvas]原点到sliver的左上角，
/// 不管轴的方向如何。
///
/// 子类也应该重写[applyPaintTransform]来提供描述每个子类相对于sliver的位置的[Matrix4]。
/// (除其他外，这被可访问性层用来确定子类的边界)。
///
/// ### 命中测试
///
/// 要实现命中测试，可以覆盖[hitTestSelf]和[hitTestChildren]方法，或者，对于更复杂的情况，直接覆盖[hitTest]方法。
///
/// 为了对指针事件做出实际反应，可以实现[handleEvent]方法。默认情况下，它什么都不做。
/// (通常手势是由box协议中的widgets处理的，而不是直接由slivers处理。)
///
/// ### 辅助性的方法
///
/// 有许多方法是一个sliver应该实现的，这将使其他方法更容易实现。下面列出的每个方法都有详细的文档。
/// 此外，[RenderSliverHelpers]类可以用来混如一些有用的方法。
///
///
/// #### childScrollOffset
///
/// 如果子类将children定位在滚动偏移量0以外的任何地方，它应该覆盖[childScrollOffset]。例如，
/// [RenderSliverList]和[RenderSliverGrid]覆盖了这个方法，但[RenderSliverToBoxAdapter]没有。
///
/// 这被[Scrollable.sureVisible]等使用。
///
/// #### childMainAxisPosition
///
/// 子类应该实现[childMainAxisPosition]来描述children的位置。
///
/// #### childCrossAxisPosition
///
/// 如果子类将横轴中的children定位在零以外的位置，那么它应该覆盖[childCrossAxisPosition]。
/// 例如[RenderSliverGrid]就覆盖了这个方法。
abstract class RenderSliver extends RenderObject {
  // layout input
  @override
  SliverConstraints get constraints => super.constraints as SliverConstraints;

  /// The amount of space this sliver occupies.
  ///
  /// This value is stale whenever this object is marked as needing layout.
  /// During [performLayout], do not read the [geometry] of a child unless you
  /// pass true for parentUsesSize when calling the child's [layout] function.
  ///
  /// The geometry of a sliver should be set only during the sliver's
  /// [performLayout] or [performResize] functions. If you wish to change the
  /// geometry of a sliver outside of those functions, call [markNeedsLayout]
  /// instead to schedule a layout of the sliver.
  SliverGeometry? get geometry => _geometry;
  SliverGeometry? _geometry;
  set geometry(SliverGeometry? value) {
    _geometry = value;
  }

  @override
  Rect get semanticBounds => paintBounds;

  @override
  Rect get paintBounds {
    switch (constraints.axis) {
      case Axis.horizontal:
        return Rect.fromLTWH(
          0.0, 0.0,
          geometry!.paintExtent,
          constraints.crossAxisExtent,
        );
      case Axis.vertical:
        return Rect.fromLTWH(
          0.0, 0.0,
          constraints.crossAxisExtent,
          geometry!.paintExtent,
        );
    }
  }

  @override
  void debugResetSize() { }


  @override
  void performResize() {
    assert(false);
  }

  /// For a center sliver, the distance before the absolute zero scroll offset
  /// that this sliver can cover.
  ///
  /// For example, if an [AxisDirection.down] viewport with an
  /// [RenderViewport.anchor] of 0.5 has a single sliver with a height of 100.0
  /// and its [centerOffsetAdjustment] returns 50.0, then the sliver will be
  /// centered in the viewport when the scroll offset is 0.0.
  ///
  /// The distance here is in the opposite direction of the
  /// [RenderViewport.axisDirection], so values will typically be positive.
  double get centerOffsetAdjustment => 0.0;

  /// Determines the set of render objects located at the given position.
  ///
  /// Returns true if the given point is contained in this render object or one
  /// of its descendants. Adds any render objects that contain the point to the
  /// given hit test result.
  ///
  /// The caller is responsible for providing the position in the local
  /// coordinate space of the callee. The callee is responsible for checking
  /// whether the given position is within its bounds.
  ///
  /// Hit testing requires layout to be up-to-date but does not require painting
  /// to be up-to-date. That means a render object can rely upon [performLayout]
  /// having been called in [hitTest] but cannot rely upon [paint] having been
  /// called. For example, a render object might be a child of a [RenderOpacity]
  /// object, which calls [hitTest] on its children when its opacity is zero
  /// even through it does not [paint] its children.
  ///
  /// ## Coordinates for RenderSliver objects
  ///
  /// The `mainAxisPosition` is the distance in the [AxisDirection] (after
  /// applying the [GrowthDirection]) from the edge of the sliver's painted
  /// area. This can be an unusual direction, for example in the
  /// [AxisDirection.up] case this is a distance from the _bottom_ of the
  /// sliver's painted area.
  ///
  /// The `crossAxisPosition` is the distance in the other axis. If the cross
  /// axis is horizontal (i.e. the [SliverConstraints.axisDirection] is either
  /// [AxisDirection.down] or [AxisDirection.up]), then the `crossAxisPosition`
  /// is a distance from the left edge of the sliver. If the cross axis is
  /// vertical (i.e. the [SliverConstraints.axisDirection] is either
  /// [AxisDirection.right] or [AxisDirection.left]), then the
  /// `crossAxisPosition` is a distance from the top edge of the sliver.
  ///
  /// ## Implementing hit testing for slivers
  ///
  /// The most straight-forward way to implement hit testing for a new sliver
  /// render object is to override its [hitTestSelf] and [hitTestChildren]
  /// methods.
  bool hitTest(SliverHitTestResult result, { required double mainAxisPosition, required double crossAxisPosition }) {
    if (mainAxisPosition >= 0.0 && mainAxisPosition < geometry!.hitTestExtent &&
        crossAxisPosition >= 0.0 && crossAxisPosition < constraints.crossAxisExtent) {
      if (hitTestChildren(result, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition) ||
          hitTestSelf(mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition)) {
        result.add(SliverHitTestEntry(
          this,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        ));
        return true;
      }
    }
    return false;
  }

  /// Override this method if this render object can be hit even if its
  /// children were not hit.
  ///
  /// Used by [hitTest]. If you override [hitTest] and do not call this
  /// function, then you don't need to implement this function.
  ///
  /// For a discussion of the semantics of the arguments, see [hitTest].
  @protected
  bool hitTestSelf({ required double mainAxisPosition, required double crossAxisPosition }) => false;

  /// Override this method to check whether any children are located at the
  /// given position.
  ///
  /// Typically children should be hit-tested in reverse paint order so that
  /// hit tests at locations where children overlap hit the child that is
  /// visually "on top" (i.e., paints later).
  ///
  /// Used by [hitTest]. If you override [hitTest] and do not call this
  /// function, then you don't need to implement this function.
  ///
  /// For a discussion of the semantics of the arguments, see [hitTest].
  @protected
  bool hitTestChildren(SliverHitTestResult result, { required double mainAxisPosition, required double crossAxisPosition }) => false;

  /// Computes the portion of the region from `from` to `to` that is visible,
  /// assuming that only the region from the [SliverConstraints.scrollOffset]
  /// that is [SliverConstraints.remainingPaintExtent] high is visible, and that
  /// the relationship between scroll offsets and paint offsets is linear.
  ///
  /// For example, if the constraints have a scroll offset of 100 and a
  /// remaining paint extent of 100, and the arguments to this method describe
  /// the region 50..150, then the returned value would be 50 (from scroll
  /// offset 100 to scroll offset 150).
  ///
  /// This method is not useful if there is not a 1:1 relationship between
  /// consumed scroll offset and consumed paint extent. For example, if the
  /// sliver always paints the same amount but consumes a scroll offset extent
  /// that is proportional to the [SliverConstraints.scrollOffset], then this
  /// function's results will not be consistent.
  // This could be a static method but isn't, because it would be less convenient
  // to call it from subclasses if it was.
  double calculatePaintOffset(SliverConstraints constraints, { required double from, required double to }) {
    assert(from <= to);
    final double a = constraints.scrollOffset;
    final double b = constraints.scrollOffset + constraints.remainingPaintExtent;
    // the clamp on the next line is to avoid floating point rounding errors
    return (to.clamp(a, b) - from.clamp(a, b)).clamp(0.0, constraints.remainingPaintExtent);
  }

  /// Computes the portion of the region from `from` to `to` that is within
  /// the cache extent of the viewport, assuming that only the region from the
  /// [SliverConstraints.cacheOrigin] that is
  /// [SliverConstraints.remainingCacheExtent] high is visible, and that
  /// the relationship between scroll offsets and paint offsets is linear.
  ///
  /// This method is not useful if there is not a 1:1 relationship between
  /// consumed scroll offset and consumed cache extent.
  double calculateCacheOffset(SliverConstraints constraints, { required double from, required double to }) {
    assert(from <= to);
    final double a = constraints.scrollOffset + constraints.cacheOrigin;
    final double b = constraints.scrollOffset + constraints.remainingCacheExtent;
    // the clamp on the next line is to avoid floating point rounding errors
    return (to.clamp(a, b) - from.clamp(a, b)).clamp(0.0, constraints.remainingCacheExtent);
  }

  /// Returns the distance from the leading _visible_ edge of the sliver to the
  /// side of the given child closest to that edge.
  ///
  /// For example, if the [constraints] describe this sliver as having an axis
  /// direction of [AxisDirection.down], then this is the distance from the top
  /// of the visible portion of the sliver to the top of the child. On the other
  /// hand, if the [constraints] describe this sliver as having an axis
  /// direction of [AxisDirection.up], then this is the distance from the bottom
  /// of the visible portion of the sliver to the bottom of the child. In both
  /// cases, this is the direction of increasing
  /// [SliverConstraints.scrollOffset] and
  /// [SliverLogicalParentData.layoutOffset].
  ///
  /// For children that are [RenderSliver]s, the leading edge of the _child_
  /// will be the leading _visible_ edge of the child, not the part of the child
  /// that would locally be a scroll offset 0.0. For children that are not
  /// [RenderSliver]s, for example a [RenderBox] child, it's the actual distance
  /// to the edge of the box, since those boxes do not know how to handle being
  /// scrolled.
  ///
  /// This method differs from [childScrollOffset] in that
  /// [childMainAxisPosition] gives the distance from the leading _visible_ edge
  /// of the sliver whereas [childScrollOffset] gives the distance from the
  /// sliver's zero scroll offset.
  ///
  /// Calling this for a child that is not visible is not valid.
  @protected
  double childMainAxisPosition(covariant RenderObject child) {
    assert(() {
      throw FlutterError('${objectRuntimeType(this, 'RenderSliver')} does not implement childPosition.');
    }());
    return 0.0;
  }

  /// Returns the distance along the cross axis from the zero of the cross axis
  /// in this sliver's [paint] coordinate space to the nearest side of the given
  /// child.
  ///
  /// For example, if the [constraints] describe this sliver as having an axis
  /// direction of [AxisDirection.down], then this is the distance from the left
  /// of the sliver to the left of the child. Similarly, if the [constraints]
  /// describe this sliver as having an axis direction of [AxisDirection.up],
  /// then this is value is the same. If the axis direction is
  /// [AxisDirection.left] or [AxisDirection.right], then it is the distance
  /// from the top of the sliver to the top of the child.
  ///
  /// Calling this for a child that is not visible is not valid.
  @protected
  double childCrossAxisPosition(covariant RenderObject child) => 0.0;

  /// Returns the scroll offset for the leading edge of the given child.
  ///
  /// The `child` must be a child of this sliver.
  ///
  /// This method differs from [childMainAxisPosition] in that
  /// [childMainAxisPosition] gives the distance from the leading _visible_ edge
  /// of the sliver whereas [childScrollOffset] gives the distance from sliver's
  /// zero scroll offset.
  double? childScrollOffset(covariant RenderObject child) {
    assert(child.parent == this);
    return 0.0;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(() {
      throw FlutterError('${objectRuntimeType(this, 'RenderSliver')} does not implement applyPaintTransform.');
    }());
  }

  /// This returns a [Size] with dimensions relative to the leading edge of the
  /// sliver, specifically the same offset that is given to the [paint] method.
  /// This means that the dimensions may be negative.
  ///
  /// This is only valid after [layout] has completed.
  ///
  /// See also:
  ///
  ///  * [getAbsoluteSize], which returns absolute size.
  @protected
  Size getAbsoluteSizeRelativeToOrigin() {
    assert(geometry != null);
    assert(!debugNeedsLayout);
    switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return Size(constraints.crossAxisExtent, -geometry!.paintExtent);
      case AxisDirection.right:
        return Size(geometry!.paintExtent, constraints.crossAxisExtent);
      case AxisDirection.down:
        return Size(constraints.crossAxisExtent, geometry!.paintExtent);
      case AxisDirection.left:
        return Size(-geometry!.paintExtent, constraints.crossAxisExtent);
    }
  }

  /// This returns the absolute [Size] of the sliver.
  ///
  /// The dimensions are always positive and calling this is only valid after
  /// [layout] has completed.
  ///
  /// See also:
  ///
  ///  * [getAbsoluteSizeRelativeToOrigin], which returns the size relative to
  ///    the leading edge of the sliver.
  @protected
  Size getAbsoluteSize() {
    assert(geometry != null);
    assert(!debugNeedsLayout);
    switch (constraints.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.down:
        return Size(constraints.crossAxisExtent, geometry!.paintExtent);
      case AxisDirection.right:
      case AxisDirection.left:
        return Size(geometry!.paintExtent, constraints.crossAxisExtent);
    }
  }

  void _debugDrawArrow(Canvas canvas, Paint paint, Offset p0, Offset p1, GrowthDirection direction) {
    assert(() {
      if (p0 == p1)
        return true;
      assert(p0.dx == p1.dx || p0.dy == p1.dy); // must be axis-aligned
      final double d = (p1 - p0).distance * 0.2;
      final Offset temp;
      double dx1, dx2, dy1, dy2;
      switch (direction) {
        case GrowthDirection.forward:
          dx1 = dx2 = dy1 = dy2 = d;
          break;
        case GrowthDirection.reverse:
          temp = p0;
          p0 = p1;
          p1 = temp;
          dx1 = dx2 = dy1 = dy2 = -d;
          break;
      }
      if (p0.dx == p1.dx) {
        dx2 = -dx2;
      } else {
        dy2 = -dy2;
      }
      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..moveTo(p1.dx - dx1, p1.dy - dy1)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p1.dx - dx2, p1.dy - dy2),
        paint,
      );
      return true;
    }());
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled) {
        final double strokeWidth = math.min(4.0, geometry!.paintExtent / 30.0);
        final Paint paint = Paint()
          ..color = const Color(0xFF33CC33)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, strokeWidth);
        final double arrowExtent = geometry!.paintExtent;
        final double padding = math.max(2.0, strokeWidth);
        final Canvas canvas = context.canvas;
        canvas.drawCircle(
          offset.translate(padding, padding),
          padding * 0.5,
          paint,
        );
        switch (constraints.axis) {
          case Axis.vertical:
            canvas.drawLine(
              offset,
              offset.translate(constraints.crossAxisExtent, 0.0),
              paint,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(constraints.crossAxisExtent * 1.0 / 4.0, padding),
              offset.translate(constraints.crossAxisExtent * 1.0 / 4.0, arrowExtent - padding),
              constraints.normalizedGrowthDirection,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(constraints.crossAxisExtent * 3.0 / 4.0, padding),
              offset.translate(constraints.crossAxisExtent * 3.0 / 4.0, arrowExtent - padding),
              constraints.normalizedGrowthDirection,
            );
            break;
          case Axis.horizontal:
            canvas.drawLine(
              offset,
              offset.translate(0.0, constraints.crossAxisExtent),
              paint,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(padding, constraints.crossAxisExtent * 1.0 / 4.0),
              offset.translate(arrowExtent - padding, constraints.crossAxisExtent * 1.0 / 4.0),
              constraints.normalizedGrowthDirection,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(padding, constraints.crossAxisExtent * 3.0 / 4.0),
              offset.translate(arrowExtent - padding, constraints.crossAxisExtent * 3.0 / 4.0),
              constraints.normalizedGrowthDirection,
            );
            break;
        }
      }
      return true;
    }());
  }

  // This override exists only to change the type of the second argument.
  @override
  void handleEvent(PointerEvent event, SliverHitTestEntry entry) { }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SliverGeometry>('geometry', geometry));
  }
}
