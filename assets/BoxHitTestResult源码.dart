class BoxHitTestResult extends HitTestResult {
  /// Creates an empty hit test result for hit testing on [RenderBox].
  BoxHitTestResult() : super();

  /// Wraps `result` to create a [HitTestResult] that implements the
  /// [BoxHitTestResult] protocol for hit testing on [RenderBox]es.
  ///
  /// This method is used by [RenderObject]s that adapt between the
  /// [RenderBox]-world and the non-[RenderBox]-world to convert a (subtype of)
  /// [HitTestResult] to a [BoxHitTestResult] for hit testing on [RenderBox]es.
  ///
  /// The [HitTestEntry] instances added to the returned [BoxHitTestResult] are
  /// also added to the wrapped `result` (both share the same underlying data
  /// structure to store [HitTestEntry] instances).
  ///
  /// See also:
  ///
  ///  * [HitTestResult.wrap], which turns a [BoxHitTestResult] back into a
  ///    generic [HitTestResult].
  ///  * [SliverHitTestResult.wrap], which turns a [BoxHitTestResult] into a
  ///    [SliverHitTestResult] for hit testing on [RenderSliver] children.
  BoxHitTestResult.wrap(HitTestResult result) : super.wrap(result);

  /// Transforms `position` to the local coordinate system of a child for
  /// hit-testing the child.
  ///
  /// The actual hit testing of the child needs to be implemented in the
  /// provided `hitTest` callback, which is invoked with the transformed
  /// `position` as argument.
  ///
  /// The provided paint `transform` (which describes the transform from the
  /// child to the parent in 3D) is processed by
  /// [PointerEvent.removePerspectiveTransform] to remove the
  /// perspective component and inverted before it is used to transform
  /// `position` from the coordinate system of the parent to the system of the
  /// child.
  ///
  /// If `transform` is null it will be treated as the identity transform and
  /// `position` is provided to the `hitTest` callback as-is. If `transform`
  /// cannot be inverted, the `hitTest` callback is not invoked and false is
  /// returned. Otherwise, the return value of the `hitTest` callback is
  /// returned.
  ///
  /// The `position` argument may be null, which will be forwarded to the
  /// `hitTest` callback as-is. Using null as the position can be useful if
  /// the child speaks a different hit test protocol then the parent and the
  /// position is not required to do the actual hit testing in that protocol.
  ///
  /// The function returns the return value of the `hitTest` callback.
  ///
  /// {@tool snippet}
  /// This method is used in [RenderBox.hitTestChildren] when the child and
  /// parent don't share the same origin.
  ///
  /// ```dart
  /// abstract class RenderFoo extends RenderBox {
  ///
  ///   final Matrix4 _effectiveTransform = Matrix4.rotationZ(50);
  ///
  ///   @override
  ///   void applyPaintTransform(RenderBox child, Matrix4 transform) {
  ///     transform.multiply(_effectiveTransform);
  ///   }
  ///
  ///   @override
  ///   bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
  ///     return result.addWithPaintTransform(
  ///       transform: _effectiveTransform,
  ///       position: position,
  ///       hitTest: (BoxHitTestResult result, Offset position) {
  ///         return super.hitTestChildren(result, position: position);
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [addWithPaintOffset], which can be used for `transform`s that are just
  ///    simple matrix translations by an [Offset].
  ///  * [addWithRawTransform], which takes a transform matrix that is directly
  ///    used to transform the position without any pre-processing.
  bool addWithPaintTransform({
    required Matrix4? transform,
    required Offset position,
    required BoxHitTest hitTest,
  }) {
    assert(position != null);
    assert(hitTest != null);
    if (transform != null) {
      transform = Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return false;
      }
    }
    return addWithRawTransform(
      transform: transform,
      position: position,
      hitTest: hitTest,
    );
  }

  /// 方便的方法，用于子代命中测试
  ///
  /// 子代的实际命中测试需要在提供的`hitTest`回调中实现，该回调以转换后的`position`为参数调用。
  ///
  /// 如果父代在一个 "offset "处绘制子代（child），这个方法可以作为[addWithPaintTransform]
  /// 的一个便利方法。
  ///
  /// 如果`offset`的值为空，那么将视为[Offset.zero]
  ///
  /// 该方法返回`hitTest`回调的返回值
  ///
  /// See also:
  ///
  ///  * [addWithPaintTransform], which takes a generic paint transform matrix and
  ///    documents the intended usage of this API in more detail.
  bool addWithPaintOffset({
    required Offset? offset,
    required Offset position,
    required BoxHitTest hitTest,
  }) {
    final Offset transformedPosition = offset == null ? position : position - offset;
    if (offset != null) {
      pushOffset(-offset);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (offset != null) {
      popTransform();
    }
    return isHit;
  }

  /// Transforms `position` to the local coordinate system of a child for
  /// hit-testing the child.
  ///
  /// The actual hit testing of the child needs to be implemented in the
  /// provided `hitTest` callback, which is invoked with the transformed
  /// `position` as argument.
  ///
  /// Unlike [addWithPaintTransform], the provided `transform` matrix is used
  /// directly to transform `position` without any pre-processing.
  ///
  /// If `transform` is null it will be treated as the identity transform ad
  /// `position` is provided to the `hitTest` callback as-is.
  ///
  /// The function returns the return value of the `hitTest` callback.
  ///
  /// See also:
  ///
  ///  * [addWithPaintTransform], which accomplishes the same thing, but takes a
  ///    _paint_ transform matrix.
  bool addWithRawTransform({
    required Matrix4? transform,
    required Offset position,
    required BoxHitTest hitTest,
  }) {
    assert(position != null);
    assert(hitTest != null);
    assert(position != null);
    final Offset transformedPosition = transform == null ?
    position : MatrixUtils.transformPoint(transform, position);
    if (transform != null) {
      pushTransform(transform);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (transform != null) {
      popTransform();
    }
    return isHit;
  }

  /// Pass-through method for adding a hit test while manually managing
  /// the position transformation logic.
  ///
  /// The actual hit testing of the child needs to be implemented in the
  /// provided `hitTest` callback. The position needs to be handled by
  /// the caller.
  ///
  /// The function returns the return value of the `hitTest` callback.
  ///
  /// A `paintOffset`, `paintTransform`, or `rawTransform` should be
  /// passed to the method to update the hit test stack.
  ///
  ///  * `paintOffset` has the semantics of the `offset` passed to
  ///    [addWithPaintOffset].
  ///
  ///  * `paintTransform` has the semantics of the `transform` passed to
  ///    [addWithPaintTransform], except that it must be invertible; it
  ///    is the responsibility of the caller to ensure this.
  ///
  ///  * `rawTransform` has the semantics of the `transform` passed to
  ///    [addWithRawTransform].
  ///
  /// Exactly one of these must be non-null.
  ///
  /// See also:
  ///
  ///  * [addWithPaintTransform], which takes a generic paint transform matrix and
  ///    documents the intended usage of this API in more detail.
  bool addWithOutOfBandPosition({
    Offset? paintOffset,
    Matrix4? paintTransform,
    Matrix4? rawTransform,
    required BoxHitTestWithOutOfBandPosition hitTest,
  }) {
    assert(hitTest != null);
    assert((paintOffset == null && paintTransform == null && rawTransform != null) ||
        (paintOffset == null && paintTransform != null && rawTransform == null) ||
        (paintOffset != null && paintTransform == null && rawTransform == null),
    'Exactly one transform or offset argument must be provided.');
    if (paintOffset != null) {
      pushOffset(-paintOffset);
    } else if (rawTransform != null) {
      pushTransform(rawTransform);
    } else {
      assert(paintTransform != null);
      paintTransform = Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(paintTransform!));
      assert(paintTransform != null, 'paintTransform must be invertible.');
      pushTransform(paintTransform!);
    }
    final bool isHit = hitTest(this);
    popTransform();
    return isHit;
  }
}
