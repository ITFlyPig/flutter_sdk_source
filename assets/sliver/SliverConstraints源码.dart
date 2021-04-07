/// 不可变的[RenderSliver]的布局约束。
///
/// [SliverConstraints]从接受布局约束的sliver的角度描述了当前视窗的滚动状态。例如，
/// [scrollOffset]为零意味着sliver的前缘在视窗中是可见的，而不是视窗本身的滚动偏移量为零。
///
///
class SliverConstraints extends Constraints {
  /// Creates sliver constraints with the given information.
  ///
  /// All of the argument must not be null.
  const SliverConstraints({
    required this.axisDirection,
    required this.growthDirection,
    required this.userScrollDirection,
    required this.scrollOffset,
    required this.precedingScrollExtent,
    required this.overlap,
    required this.remainingPaintExtent,
    required this.crossAxisExtent,
    required this.crossAxisDirection,
    required this.viewportMainAxisExtent,
    required this.remainingCacheExtent,
    required this.cacheOrigin,
  }) : assert(axisDirection != null),
        assert(growthDirection != null),
        assert(userScrollDirection != null),
        assert(scrollOffset != null),
        assert(precedingScrollExtent != null),
        assert(overlap != null),
        assert(remainingPaintExtent != null),
        assert(crossAxisExtent != null),
        assert(crossAxisDirection != null),
        assert(viewportMainAxisExtent != null),
        assert(remainingCacheExtent != null),
        assert(cacheOrigin != null);

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  SliverConstraints copyWith({
    AxisDirection? axisDirection,
    GrowthDirection? growthDirection,
    ScrollDirection? userScrollDirection,
    double? scrollOffset,
    double? precedingScrollExtent,
    double? overlap,
    double? remainingPaintExtent,
    double? crossAxisExtent,
    AxisDirection? crossAxisDirection,
    double? viewportMainAxisExtent,
    double? remainingCacheExtent,
    double? cacheOrigin,
  }) {
    return SliverConstraints(
      axisDirection: axisDirection ?? this.axisDirection,
      growthDirection: growthDirection ?? this.growthDirection,
      userScrollDirection: userScrollDirection ?? this.userScrollDirection,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      precedingScrollExtent: precedingScrollExtent ?? this.precedingScrollExtent,
      overlap: overlap ?? this.overlap,
      remainingPaintExtent: remainingPaintExtent ?? this.remainingPaintExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      crossAxisDirection: crossAxisDirection ?? this.crossAxisDirection,
      viewportMainAxisExtent: viewportMainAxisExtent ?? this.viewportMainAxisExtent,
      remainingCacheExtent: remainingCacheExtent ?? this.remainingCacheExtent,
      cacheOrigin: cacheOrigin ?? this.cacheOrigin,
    );
  }

  /// The direction in which the [scrollOffset] and [remainingPaintExtent]
  /// increase.
  final AxisDirection axisDirection;

  /// The direction in which the contents of slivers are ordered, relative to
  /// the [axisDirection].
  ///
  /// For example, if the [axisDirection] is [AxisDirection.up], and the
  /// [growthDirection] is [GrowthDirection.forward], then an alphabetical list
  /// will have A at the bottom, then B, then C, and so forth, with Z at the
  /// top, with the bottom of the A at scroll offset zero, and the top of the Z
  /// at the highest scroll offset.
  ///
  /// If a viewport has an overall [AxisDirection] of [AxisDirection.down], then
  /// slivers above the absolute zero offset will have an axis of
  /// [AxisDirection.up] and a growth direction of [GrowthDirection.reverse],
  /// while slivers below the absolute zero offset will have the same axis
  /// direction as the viewport and a growth direction of
  /// [GrowthDirection.forward]. (The slivers with a reverse growth direction
  /// still see only positive scroll offsets; the scroll offsets are reversed as
  /// well, with zero at the absolute zero point, and positive numbers going
  /// away from there.)
  ///
  /// Normally, the absolute zero offset is determined by the viewport's
  /// [RenderViewport.center] and [RenderViewport.anchor] properties.
  final GrowthDirection growthDirection;

  /// The direction in which the user is attempting to scroll, relative to the
  /// [axisDirection] and [growthDirection].
  ///
  /// For example, if [growthDirection] is [GrowthDirection.reverse] and
  /// [axisDirection] is [AxisDirection.down], then a
  /// [ScrollDirection.forward] means that the user is scrolling up, in the
  /// positive [scrollOffset] direction.
  ///
  /// If the _user_ is not scrolling, this will return [ScrollDirection.idle]
  /// even if there is (for example) a [ScrollActivity] currently animating the
  /// position.
  ///
  /// This is used by some slivers to determine how to react to a change in
  /// scroll offset. For example, [RenderSliverFloatingPersistentHeader] will
  /// only expand a floating app bar when the [userScrollDirection] is in the
  /// positive scroll offset direction.
  final ScrollDirection userScrollDirection;

  ///
  /// 如果[growthDirection]为[growthDirection.forward]，那么在这个sliver的坐标系中，
  /// 对应于这个sliver在[AxisDirection]方向的最早可见部分的滚动偏移量（scroll offset），
  /// 如果[growthDirection]为[growthDirection.reverse]，则对应于相反的[AxisDirection]方向。
  ///
  /// 例如，如果[AxisDirection]是[AxisDirection.down]，[growthDirection]是
  /// [GrowthDirection.forward]，那么滚动偏移量是指sliver的顶部被滚动过视窗顶部的数量。
  ///
  /// 这个值通常用于来计算这个sliver是否应该突出到视窗中，通过[SliverGeometry.paintExtent]
  /// 和[SliverGeometry.layoutExtent]，同时还需要考虑到sliver的起始点比视窗的起始点高出多远。
  ///
  /// 对于顶部不超过视窗顶部的slivers，当[AxisDirection]为[AxisDirection.down]且[growthDirection]
  /// 为[growthDirection.forward]时，[scrollOffset]为`0`。[scrollOffset] 为`0`的slivers集合包括所
  /// 有低于viewport底部的slivers。
  ///
  /// [SliverConstraints.remainPaintExtent]通常用于实现同样的目标，即计算滚动出来的
  /// slivers是否应该从视窗底部 “突出(protrude)"。
  ///
  /// 这是对应于sliver内容的开始还是末尾，取决于[growthDirection]。
  ///
  final double scrollOffset;

  /// 这个[RenderSliver]之前的所有[RenderSliver]所消耗的滚动距离。
  ///
  /// # 边界情况
  ///
  /// [RenderSliver]经常在布局发生时才创建其内部内容，例如[SliverList]。在这种情况下，
  /// 当[RenderSliver]s超过视窗时，它们的子代会被懒惰地构建，对于懒惰构建的子代之后出现的所
  /// 有[RenderSliver]s，[RenderSliver]没有足够的信息来估计它的总尺寸，因而[precedingScrollExtent]
  /// 将是[double.infinity]。这是因为除非所有的内部子代都被创建并确定了大小，或者提供了子代
  /// 的数量和估计的尺寸，否则无法计算出[SliverGeometry.scrollExtent]的总尺寸。一旦有足
  /// 够的信息来估计给定的 [RenderSliver] 内所有子代的总体尺寸，无限的 [SliverGeometry.scrollExtent]
  /// 就会变成有限的。
  ///
  /// [RenderSliver]可能合法地infinite，这意味着它们可以永远滚动内容而不到达终点。对于出现
  /// 在无限[RenderSliver]之后的任何[RenderSliver]，[precedingScrollExtent]将是[double.infinity]。
  ///
  final double precedingScrollExtent;

  /// 从[scrollOffset]对应将要被绘制的地到 尚未被早前的sliver绘制的第一个像素的距离。
  ///
  /// 例如，如果前一个sliver的[SliverGeometry.paintExtent]为100.0像素，但
  /// [SliverGeometry.layoutExtent]只有50.0像素，那么这个sliver的[overlap]将是50.0。
  ///
  /// 这个属性通常会被忽略，除非当前sliver本身要被钉住或浮动，但是前一个sliver不必固定或者浮动。
  ///
  /// The number of pixels from where the pixels corresponding to the
  /// [scrollOffset] will be painted up to the first pixel that has not yet been
  /// painted on by an earlier sliver, in the [axisDirection].
  ///
  /// For example, if the previous sliver had a [SliverGeometry.paintExtent] of
  /// 100.0 pixels but a [SliverGeometry.layoutExtent] of only 50.0 pixels,
  /// then the [overlap] of this sliver will be 50.0.
  ///
  final double overlap;

  /// sliver应该考虑提供的内容的像素数。(提供的像素数超过这个数是低效的)。
  ///
  /// 实际提供的像素数应该在[RenderSliver.geometry]中指定为[SliverGeometry.paintExtent]。
  ///
  /// 这个值可能是无限的，例如，如果视窗是一个无约束的[RenderShrinkWrappingViewport]。
  ///
  /// 这个值可以是0.0，例如，如果sliver滚过向下垂直视窗的底部。
  final double remainingPaintExtent;

  /// 副轴的像素数。
  ///
  /// 对于垂直列表来说，这就是sliver的宽度。
  final double crossAxisExtent;

  /// The direction in which children should be placed in the cross axis.
  ///
  /// Typically used in vertical lists to describe whether the ambient
  /// [TextDirection] is [TextDirection.rtl] or [TextDirection.ltr].
  final AxisDirection crossAxisDirection;

  /// 视窗在主轴上可显示的像素数。
  ///
  /// 对于垂直列表，这是视窗的高度。
  ///
  final double viewportMainAxisExtent;

  /// 缓存区域相对于[scrollOffset]的起始位置。
  ///
  /// 落入位于视窗前缘和后缘的缓存区域的Slivers仍然应该渲染内容，因为当用户滚动时，它们即将变得可见。
  ///
  /// [cacheOrigin]描述了相对于[scrollOffset]而言，[remainCacheExtent]的起始位置。缓存
  /// 原点为0，意味着在当前的[scrollOffset]之前，sliver不需要提供任何内容。[cacheOrigin]为
  /// -250.0 意味着即使sliver的第一个可见部分位于提供的[scrollOffset]处，sliver也应该在
  /// [scrollOffset]之前从250.0开始渲染内容，以填充视口的缓存区域。
  ///
  /// [cacheOrigin]总是负数或零，并且永远不会超过-[scrollOffset]。换句话说，在sliver的
  /// [scrollOffset]为零之前，绝不会要求该sliver提供内容。
  ///
  /// See also:
  ///
  ///  * [RenderViewport.cacheExtent]以获取viewport的缓存区域的描述。
  final double cacheOrigin;


  /// 描述了从[cacheOrigin]开始，sliver应该提供多少内容。
  ///
  /// 并非所有位于[remainCacheExtent]中的内容都会可见，因为有些内容可能会落入视窗的缓存区域。
  ///
  /// 每个sliver应该从[cacheOrigin]开始铺设内容，并尽量在[remainCacheExtent]允许的情况
  /// 下提供更多的内容。
  ///
  /// [remainingCacheExtent]总是大于或等于[remainingPaintExtent]。属于[remainCacheExtent]，
  /// 但在[remainPaintExtent]之外的内容，目前在视窗中不可见。
  ///
  /// See also:
  ///
  ///  * [RenderViewport.cacheExtent]以获取viewport的缓存区域的描述。
  final double remainingCacheExtent;

  /// The axis along which the [scrollOffset] and [remainingPaintExtent] are measured.
  Axis get axis => axisDirectionToAxis(axisDirection);

  /// Return what the [growthDirection] would be if the [axisDirection] was
  /// either [AxisDirection.down] or [AxisDirection.right].
  ///
  /// This is the same as [growthDirection] unless the [axisDirection] is either
  /// [AxisDirection.up] or [AxisDirection.left], in which case it is the
  /// opposite growth direction.
  ///
  /// This can be useful in combination with [axis] to view the [axisDirection]
  /// and [growthDirection] in different terms.
  GrowthDirection get normalizedGrowthDirection {
    assert(axisDirection != null);
    switch (axisDirection) {
      case AxisDirection.down:
      case AxisDirection.right:
        return growthDirection;
      case AxisDirection.up:
      case AxisDirection.left:
        switch (growthDirection) {
          case GrowthDirection.forward:
            return GrowthDirection.reverse;
          case GrowthDirection.reverse:
            return GrowthDirection.forward;
        }
    }
  }

  @override
  bool get isTight => false;

  @override
  bool get isNormalized {
    return scrollOffset >= 0.0
        && crossAxisExtent >= 0.0
        && axisDirectionToAxis(axisDirection) != axisDirectionToAxis(crossAxisDirection)
        && viewportMainAxisExtent >= 0.0
        && remainingPaintExtent >= 0.0;
  }

  /// Returns [BoxConstraints] that reflects the sliver constraints.
  ///
  /// The `minExtent` and `maxExtent` are used as the constraints in the main
  /// axis. If non-null, the given `crossAxisExtent` is used as a tight
  /// constraint in the cross axis. Otherwise, the [crossAxisExtent] from this
  /// object is used as a constraint in the cross axis.
  ///
  /// Useful for slivers that have [RenderBox] children.
  BoxConstraints asBoxConstraints({
    double minExtent = 0.0,
    double maxExtent = double.infinity,
    double? crossAxisExtent,
  }) {
    crossAxisExtent ??= this.crossAxisExtent;
    switch (axis) {
      case Axis.horizontal:
        return BoxConstraints(
          minHeight: crossAxisExtent,
          maxHeight: crossAxisExtent,
          minWidth: minExtent,
          maxWidth: maxExtent,
        );
      case Axis.vertical:
        return BoxConstraints(
          minWidth: crossAxisExtent,
          maxWidth: crossAxisExtent,
          minHeight: minExtent,
          maxHeight: maxExtent,
        );
    }
  }

  @override
  bool debugAssertIsValid({
    bool isAppliedConstraint = false,
    InformationCollector? informationCollector,
  }) {
    assert(() {
      bool hasErrors = false;
      final StringBuffer errorMessage = StringBuffer('\n');
      void verify(bool check, String message) {
        if (check)
          return;
        hasErrors = true;
        errorMessage.writeln('  $message');
      }
      void verifyDouble(double property, String name, {bool mustBePositive = false, bool mustBeNegative = false}) {
        verify(property != null, 'The "$name" is null.');
        if (property.isNaN) {
          String additional = '.';
          if (mustBePositive) {
            additional = ', expected greater than or equal to zero.';
          } else if (mustBeNegative) {
            additional = ', expected less than or equal to zero.';
          }
          verify(false, 'The "$name" is NaN$additional');
        } else if (mustBePositive) {
          verify(property >= 0.0, 'The "$name" is negative.');
        } else if (mustBeNegative) {
          verify(property <= 0.0, 'The "$name" is positive.');
        }
      }
      verify(axis != null, 'The "axis" is null.');
      verify(growthDirection != null, 'The "growthDirection" is null.');
      verifyDouble(scrollOffset, 'scrollOffset');
      verifyDouble(overlap, 'overlap');
      verifyDouble(crossAxisExtent, 'crossAxisExtent');
      verifyDouble(scrollOffset, 'scrollOffset', mustBePositive: true);
      verify(crossAxisDirection != null, 'The "crossAxisDirection" is null.');
      verify(axisDirectionToAxis(axisDirection) != axisDirectionToAxis(crossAxisDirection), 'The "axisDirection" and the "crossAxisDirection" are along the same axis.');
      verifyDouble(viewportMainAxisExtent, 'viewportMainAxisExtent', mustBePositive: true);
      verifyDouble(remainingPaintExtent, 'remainingPaintExtent', mustBePositive: true);
      verifyDouble(remainingCacheExtent, 'remainingCacheExtent', mustBePositive: true);
      verifyDouble(cacheOrigin, 'cacheOrigin', mustBeNegative: true);
      verifyDouble(precedingScrollExtent, 'precedingScrollExtent', mustBePositive: true);
      verify(isNormalized, 'The constraints are not normalized.'); // should be redundant with earlier checks
      if (hasErrors) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType is not valid: $errorMessage'),
          if (informationCollector != null)
            ...informationCollector(),
          DiagnosticsProperty<SliverConstraints>('The offending constraints were', this, style: DiagnosticsTreeStyle.errorProperty),
        ]);
      }
      return true;
    }());
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other is! SliverConstraints)
      return false;
    assert(other is SliverConstraints && other.debugAssertIsValid());
    return other is SliverConstraints
        && other.axisDirection == axisDirection
        && other.growthDirection == growthDirection
        && other.scrollOffset == scrollOffset
        && other.overlap == overlap
        && other.remainingPaintExtent == remainingPaintExtent
        && other.crossAxisExtent == crossAxisExtent
        && other.crossAxisDirection == crossAxisDirection
        && other.viewportMainAxisExtent == viewportMainAxisExtent
        && other.remainingCacheExtent == remainingCacheExtent
        && other.cacheOrigin == cacheOrigin;
  }

  @override
  int get hashCode {
    return hashValues(
      axisDirection,
      growthDirection,
      scrollOffset,
      overlap,
      remainingPaintExtent,
      crossAxisExtent,
      crossAxisDirection,
      viewportMainAxisExtent,
      remainingCacheExtent,
      cacheOrigin,
    );
  }

  @override
  String toString() {
    final List<String> properties = <String>[
      '$axisDirection',
      '$growthDirection',
      '$userScrollDirection',
      'scrollOffset: ${scrollOffset.toStringAsFixed(1)}',
      'remainingPaintExtent: ${remainingPaintExtent.toStringAsFixed(1)}',
      if (overlap != 0.0) 'overlap: ${overlap.toStringAsFixed(1)}',
      'crossAxisExtent: ${crossAxisExtent.toStringAsFixed(1)}',
      'crossAxisDirection: $crossAxisDirection',
      'viewportMainAxisExtent: ${viewportMainAxisExtent.toStringAsFixed(1)}',
      'remainingCacheExtent: ${remainingCacheExtent.toStringAsFixed(1)}',
      'cacheOrigin: ${cacheOrigin.toStringAsFixed(1)}',
    ];
    return 'SliverConstraints(${properties.join(', ')})';
  }
}
