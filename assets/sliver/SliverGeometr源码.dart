@immutable
class SliverGeometry with Diagnosticable {
  /// Creates an object that describes the amount of space occupied by a sliver.
  ///
  /// If the [layoutExtent] argument is null, [layoutExtent] defaults to the
  /// [paintExtent]. If the [hitTestExtent] argument is null, [hitTestExtent]
  /// defaults to the [paintExtent]. If [visible] is null, [visible] defaults to
  /// whether [paintExtent] is greater than zero.
  ///
  /// The other arguments must not be null.
  const SliverGeometry({
    this.scrollExtent = 0.0,
    this.paintExtent = 0.0,
    this.paintOrigin = 0.0,
    double? layoutExtent,
    this.maxPaintExtent = 0.0,
    this.maxScrollObstructionExtent = 0.0,
    double? hitTestExtent,
    bool? visible,
    this.hasVisualOverflow = false,
    this.scrollOffsetCorrection,
    double? cacheExtent,
  }) : assert(scrollExtent != null),
        assert(paintExtent != null),
        assert(paintOrigin != null),
        assert(maxPaintExtent != null),
        assert(hasVisualOverflow != null),
        assert(scrollOffsetCorrection != 0.0),
        layoutExtent = layoutExtent ?? paintExtent,
        hitTestExtent = hitTestExtent ?? paintExtent,
        cacheExtent = cacheExtent ?? layoutExtent ?? paintExtent,
        visible = visible ?? paintExtent > 0.0;

  /// A sliver that occupies no space at all.
  static const SliverGeometry zero = SliverGeometry();

  /// 该sliver内容的（估计）总可滚动尺寸
  ///
  /// 这是用户从这个sliver的开始到这个sliver的结束所需要的滚动量。
  ///
  /// 该值用于计算scrollable中所有sliver的[SliverConstraints.scrollOffset]，
  /// 因此无论sliver当前是否在视窗中，都应该提供该值。
  ///
  /// 在典型的滚动场景中，[scrollExtent]在整个滚动过程中对一个sliver来说是恒定的，
  /// 而[paintExtent]和[layoutExtent]将从离屏时的 "0 "发展到当sliver部分滚动到屏幕内外时
  /// 的 "0 "和[scrollExtent]之间，当sliver完全在屏幕上时，则等于[scrollExtent]。不过，
  /// 这些关系可以自定义，以实现更多的特殊效果。
  ///
  /// 如果[paintExtent]小于布局时提供的[SliverConstraints.remainPaintExtent]，这个值必须准确。
  final double scrollExtent;

  /// The visual location of the first visible part of this sliver relative to
  /// its layout position.
  ///
  /// For example, if the sliver wishes to paint visually before its layout
  /// position, the [paintOrigin] is negative. The coordinate system this sliver
  /// uses for painting is relative to this [paintOrigin]. In other words,
  /// when [RenderSliver.paint] is called, the (0, 0) position of the [Offset]
  /// given to it is at this [paintOrigin].
  ///
  /// The coordinate system used for the [paintOrigin] itself is relative
  /// to the start of this sliver's layout position rather than relative to
  /// its current position on the viewport. In other words, in a typical
  /// scrolling scenario, [paintOrigin] remains constant at 0.0 rather than
  /// tracking from 0.0 to [SliverConstraints.viewportMainAxisExtent] as the
  /// sliver scrolls past the viewport.
  ///
  /// This value does not affect the layout of subsequent slivers. The next
  /// sliver is still placed at [layoutExtent] after this sliver's layout
  /// position. This value does affect where the [paintExtent] extent is
  /// measured from when computing the [SliverConstraints.overlap] for the next
  /// sliver.
  ///
  /// Defaults to 0.0, which means slivers start painting at their layout
  /// position by default.
  final double paintOrigin;

  /// The amount of currently visible visual space that was taken by the sliver
  /// to render the subset of the sliver that covers all or part of the
  /// [SliverConstraints.remainingPaintExtent] in the current viewport.
  ///
  /// This value does not affect how the next sliver is positioned. In other
  /// words, if this value was 100 and [layoutExtent] was 0, typical slivers
  /// placed after it would end up drawing in the same 100 pixel space while
  /// painting.
  ///
  /// This must be between zero and [SliverConstraints.remainingPaintExtent].
  ///
  /// This value is typically 0 when outside of the viewport and grows or
  /// shrinks from 0 or to 0 as the sliver is being scrolled into and out of the
  /// viewport unless the sliver wants to achieve a special effect and paint
  /// even when scrolled away.
  ///
  /// This contributes to the calculation for the next sliver's
  /// [SliverConstraints.overlap].
  final double paintExtent;

  /// The distance from the first visible part of this sliver to the first
  /// visible part of the next sliver, assuming the next sliver's
  /// [SliverConstraints.scrollOffset] is zero.
  ///
  /// This must be between zero and [paintExtent]. It defaults to [paintExtent].
  ///
  /// This value is typically 0 when outside of the viewport and grows or
  /// shrinks from 0 or to 0 as the sliver is being scrolled into and out of the
  /// viewport unless the sliver wants to achieve a special effect and push
  /// down the layout start position of subsequent slivers before the sliver is
  /// even scrolled into the viewport.
  final double layoutExtent;

  /// The (estimated) total paint extent that this sliver would be able to
  /// provide if the [SliverConstraints.remainingPaintExtent] was infinite.
  ///
  /// This is used by viewports that implement shrink-wrapping.
  ///
  /// By definition, this cannot be less than [paintExtent].
  final double maxPaintExtent;

  /// The maximum extent by which this sliver can reduce the area in which
  /// content can scroll if the sliver were pinned at the edge.
  ///
  /// Slivers that never get pinned at the edge, should return zero.
  ///
  /// A pinned app bar is an example for a sliver that would use this setting:
  /// When the app bar is pinned to the top, the area in which content can
  /// actually scroll is reduced by the height of the app bar.
  final double maxScrollObstructionExtent;

  /// The distance from where this sliver started painting to the bottom of
  /// where it should accept hits.
  ///
  /// This must be between zero and [paintExtent]. It defaults to [paintExtent].
  final double hitTestExtent;

  /// Whether this sliver should be painted.
  ///
  /// By default, this is true if [paintExtent] is greater than zero, and
  /// false if [paintExtent] is zero.
  final bool visible;

  /// Whether this sliver has visual overflow.
  ///
  /// By default, this is false, which means the viewport does not need to clip
  /// its children. If any slivers have visual overflow, the viewport will apply
  /// a clip to its children.
  final bool hasVisualOverflow;

  /// If this is non-zero after [RenderSliver.performLayout] returns, the scroll
  /// offset will be adjusted by the parent and then the entire layout of the
  /// parent will be rerun.
  ///
  /// When the value is non-zero, the [RenderSliver] does not need to compute
  /// the rest of the values when constructing the [SliverGeometry] or call
  /// [RenderObject.layout] on its children since [RenderSliver.performLayout]
  /// will be called again on this sliver in the same frame after the
  /// [SliverConstraints.scrollOffset] correction has been applied, when the
  /// proper [SliverGeometry] and layout of its children can be computed.
  ///
  /// If the parent is also a [RenderSliver], it must propagate this value
  /// in its own [RenderSliver.geometry] property until a viewport which adjusts
  /// its offset based on this value.
  final double? scrollOffsetCorrection;

  /// How many pixels the sliver has consumed in the
  /// [SliverConstraints.remainingCacheExtent].
  ///
  /// This value should be equal to or larger than the [layoutExtent] because
  /// the sliver always consumes at least the [layoutExtent] from the
  /// [SliverConstraints.remainingCacheExtent] and possibly more if it falls
  /// into the cache area of the viewport.
  ///
  /// See also:
  ///
  ///  * [RenderViewport.cacheExtent] for a description of a viewport's cache area.
  final double cacheExtent;

  /// Asserts that this geometry is internally consistent.
  ///
  /// Does nothing if asserts are disabled. Always returns true.
  bool debugAssertIsValid({
    InformationCollector? informationCollector,
  }) {
    assert(() {
      void verify(bool check, String summary, {List<DiagnosticsNode>? details}) {
        if (check)
          return;
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('${objectRuntimeType(this, 'SliverGeometry')} is not valid: $summary'),
          ...?details,
          if (informationCollector != null)
            ...informationCollector(),
        ]);
      }

      verify(scrollExtent != null, 'The "scrollExtent" is null.');
      verify(scrollExtent >= 0.0, 'The "scrollExtent" is negative.');
      verify(paintExtent != null, 'The "paintExtent" is null.');
      verify(paintExtent >= 0.0, 'The "paintExtent" is negative.');
      verify(paintOrigin != null, 'The "paintOrigin" is null.');
      verify(layoutExtent != null, 'The "layoutExtent" is null.');
      verify(layoutExtent >= 0.0, 'The "layoutExtent" is negative.');
      verify(cacheExtent >= 0.0, 'The "cacheExtent" is negative.');
      if (layoutExtent > paintExtent) {
        verify(false,
          'The "layoutExtent" exceeds the "paintExtent".',
          details: _debugCompareFloats('paintExtent', paintExtent, 'layoutExtent', layoutExtent),
        );
      }
      verify(maxPaintExtent != null, 'The "maxPaintExtent" is null.');
      // If the paintExtent is slightly more than the maxPaintExtent, but the difference is still less
      // than precisionErrorTolerance, we will not throw the assert below.
      if (paintExtent - maxPaintExtent > precisionErrorTolerance) {
        verify(false,
          'The "maxPaintExtent" is less than the "paintExtent".',
          details:
          _debugCompareFloats('maxPaintExtent', maxPaintExtent, 'paintExtent', paintExtent)
            ..add(ErrorDescription("By definition, a sliver can't paint more than the maximum that it can paint!")),
        );
      }
      verify(hitTestExtent != null, 'The "hitTestExtent" is null.');
      verify(hitTestExtent >= 0.0, 'The "hitTestExtent" is negative.');
      verify(visible != null, 'The "visible" property is null.');
      verify(hasVisualOverflow != null, 'The "hasVisualOverflow" is null.');
      verify(scrollOffsetCorrection != 0.0, 'The "scrollOffsetCorrection" is zero.');
      return true;
    }());
    return true;
  }

  @override
  String toStringShort() => objectRuntimeType(this, 'SliverGeometry');

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('scrollExtent', scrollExtent));
    if (paintExtent > 0.0) {
      properties.add(DoubleProperty('paintExtent', paintExtent, unit : visible ? null : ' but not painting'));
    } else if (paintExtent == 0.0) {
      if (visible) {
        properties.add(DoubleProperty('paintExtent', paintExtent, unit: visible ? null : ' but visible'));
      }
      properties.add(FlagProperty('visible', value: visible, ifFalse: 'hidden'));
    } else {
      // Negative paintExtent!
      properties.add(DoubleProperty('paintExtent', paintExtent, tooltip: '!'));
    }
    properties.add(DoubleProperty('paintOrigin', paintOrigin, defaultValue: 0.0));
    properties.add(DoubleProperty('layoutExtent', layoutExtent, defaultValue: paintExtent));
    properties.add(DoubleProperty('maxPaintExtent', maxPaintExtent));
    properties.add(DoubleProperty('hitTestExtent', hitTestExtent, defaultValue: paintExtent));
    properties.add(DiagnosticsProperty<bool>('hasVisualOverflow', hasVisualOverflow, defaultValue: false));
    properties.add(DoubleProperty('scrollOffsetCorrection', scrollOffsetCorrection, defaultValue: null));
    properties.add(DoubleProperty('cacheExtent', cacheExtent, defaultValue: 0.0));
  }
}
