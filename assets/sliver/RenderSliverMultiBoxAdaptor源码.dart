/// 具有多个box类型子代的sliver
///
/// [RenderSliverMultiBoxAdaptor]是一个有多个box children的slivers的基类，这些children由
/// [RenderSliverBoxChildManager] 管理，它允许子类在布局过程中懒惰地创建children。通常
/// 情况下，子类只创建那些实际需要的children来填充[SliverConstraints.remainPaintExtent]。
///
/// 从该渲染对象中添加和删除children的合同比普通渲染对象更严格：
/// * Children可以被移除，但在布局过程中，如果Children已经在该布局过程中被布局过，则可移除。
/// * 除非在调用[childManager]的过程中，并且只有在没有对应于该索引的子代（或者对应于该索引的子代先被删除）
///   的情况下，才可以添加子代。
///
/// See also:
/// * RenderSliverToBoxAdapter]，它有一个单一的box child。
/// * [RenderSliverList]，它将其子代放置在一个线性数组中。
/// * [RenderSliverFixedExtentList]，它把它的子代放在一个线性数组中，这些子代主轴上有一个固定的尺寸。
/// * RenderSliverGrid]，它将其子代放在任意位置。
abstract class RenderSliverMultiBoxAdaptor extends RenderSliver
    with
        ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
        RenderSliverHelpers,
        RenderSliverWithKeepAliveMixin {
  /// Creates a sliver with multiple box children.
  ///
  /// The [childManager] argument must not be null.
  RenderSliverMultiBoxAdaptor({
    required RenderSliverBoxChildManager childManager,
  })   : assert(childManager != null),
        _childManager = childManager {}

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMultiBoxAdaptorParentData)
      child.parentData = SliverMultiBoxAdaptorParentData();
  }

  /// The delegate that manages the children of this object.
  ///
  /// Rather than having a concrete list of children, a
  /// [RenderSliverMultiBoxAdaptor] uses a [RenderSliverBoxChildManager] to
  /// create children during layout in order to fill the
  /// [SliverConstraints.remainingPaintExtent].
  @protected
  RenderSliverBoxChildManager get childManager => _childManager;
  final RenderSliverBoxChildManager _childManager;

  /// The nodes being kept alive despite not being visible.
  final Map<int, RenderBox> _keepAliveBucket = <int, RenderBox>{};

  late List<RenderBox> _debugDanglingKeepAlives;

  /// Indicates whether integrity check is enabled.
  ///
  /// Setting this property to true will immediately perform an integrity check.
  ///
  /// The integrity check consists of:
  ///
  /// 1. Verify that the children index in childList is in ascending order.
  /// 2. Verify that there is no dangling keepalive child as the result of [move].
  bool get debugChildIntegrityEnabled => _debugChildIntegrityEnabled;
  bool _debugChildIntegrityEnabled = true;
  set debugChildIntegrityEnabled(bool enabled) {
    assert(enabled != null);
    assert(() {
      _debugChildIntegrityEnabled = enabled;
      return _debugVerifyChildOrder() &&
          (!_debugChildIntegrityEnabled || _debugDanglingKeepAlives.isEmpty);
    }());
  }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    final SliverMultiBoxAdaptorParentData childParentData =
        child.parentData! as SliverMultiBoxAdaptorParentData;
    if (!childParentData._keptAlive)
      childManager.didAdoptChild(child as RenderBox);
  }

  bool _debugAssertChildListLocked() =>
      childManager.debugAssertChildListLocked();

  /// Verify that the child list index is in strictly increasing order.
  ///
  /// This has no effect in release builds.
  bool _debugVerifyChildOrder() {
    if (_debugChildIntegrityEnabled) {
      RenderBox? child = firstChild;
      int index;
      while (child != null) {
        index = indexOf(child);
        child = childAfter(child);
        assert(child == null || indexOf(child) > index);
      }
    }
    return true;
  }

  @override
  void insert(RenderBox child, {RenderBox? after}) {
    assert(!_keepAliveBucket.containsValue(child));
    super.insert(child, after: after);
    assert(firstChild != null);
    assert(_debugVerifyChildOrder());
  }

  @override
  void move(RenderBox child, {RenderBox? after}) {
    // There are two scenarios:
    //
    // 1. The child is not keptAlive.
    // The child is in the childList maintained by ContainerRenderObjectMixin.
    // We can call super.move and update parentData with the new slot.
    //
    // 2. The child is keptAlive.
    // In this case, the child is no longer in the childList but might be stored in
    // [_keepAliveBucket]. We need to update the location of the child in the bucket.
    final SliverMultiBoxAdaptorParentData childParentData =
        child.parentData! as SliverMultiBoxAdaptorParentData;
    if (!childParentData.keptAlive) {
      super.move(child, after: after);
      childManager.didAdoptChild(child); // updates the slot in the parentData
      // Its slot may change even if super.move does not change the position.
      // In this case, we still want to mark as needs layout.
      markNeedsLayout();
    } else {
      // If the child in the bucket is not current child, that means someone has
      // already moved and replaced current child, and we cannot remove this child.
      if (_keepAliveBucket[childParentData.index] == child) {
        _keepAliveBucket.remove(childParentData.index);
      }
      assert(() {
        _debugDanglingKeepAlives.remove(child);
        return true;
      }());
      // Update the slot and reinsert back to _keepAliveBucket in the new slot.
      childManager.didAdoptChild(child);
      // If there is an existing child in the new slot, that mean that child will
      // be moved to other index. In other cases, the existing child should have been
      // removed by updateChild. Thus, it is ok to overwrite it.
      assert(() {
        if (_keepAliveBucket.containsKey(childParentData.index))
          _debugDanglingKeepAlives
              .add(_keepAliveBucket[childParentData.index]!);
        return true;
      }());
      _keepAliveBucket[childParentData.index!] = child;
    }
  }

  @override
  void remove(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData =
        child.parentData! as SliverMultiBoxAdaptorParentData;
    if (!childParentData._keptAlive) {
      super.remove(child);
      return;
    }
    _keepAliveBucket.remove(childParentData.index);
    dropChild(child);
  }

  @override
  void removeAll() {
    super.removeAll();
    _keepAliveBucket.values.forEach(dropChild);
    _keepAliveBucket.clear();
  }

  // 创建或者从缓存获取child
  void _createOrObtainChild(int index, {required RenderBox? after}) {
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      //从缓存获取child
      if (_keepAliveBucket.containsKey(index)) {
        final RenderBox child = _keepAliveBucket.remove(index)!;
        final SliverMultiBoxAdaptorParentData childParentData =
            child.parentData! as SliverMultiBoxAdaptorParentData;
        dropChild(child);
        child.parentData = childParentData;
        insert(child, after: after);
        childParentData._keptAlive = false;
      } else {
        //创建child
        _childManager.createChild(index, after: after);
      }
    });
  }

  /// 销毁或者缓存child的关键
  void _destroyOrCacheChild(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData =
        child.parentData! as SliverMultiBoxAdaptorParentData;
    if (childParentData.keepAlive) {
      //缓存child
      remove(child);
      //放到map中缓存
      _keepAliveBucket[childParentData.index!] = child;
      child.parentData = childParentData;
      super.adoptChild(child);
      childParentData._keptAlive = true;
    } else {
      //销毁child
      _childManager.removeChild(child);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final RenderBox child in _keepAliveBucket.values) child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    for (final RenderBox child in _keepAliveBucket.values) child.detach();
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    _keepAliveBucket.values.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    _keepAliveBucket.values.forEach(visitor);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    // Do not visit children in [_keepAliveBucket].
  }

  /// Called during layout to create and add the child with the given index and
  /// scroll offset.
  ///
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child if necessary. The child may instead be obtained from a cache;
  /// see [SliverMultiBoxAdaptorParentData.keepAlive].
  ///
  /// Returns false if there was no cached child and `createChild` did not add
  /// any child, otherwise returns true.
  ///
  /// Does not layout the new child.
  ///
  /// When this is called, there are no visible children, so no children can be
  /// removed during the call to `createChild`. No child should be added during
  /// that call either, except for the one that is created and returned by
  /// `createChild`.
  @protected
  bool addInitialChild({int index = 0, double layoutOffset = 0.0}) {
    assert(_debugAssertChildListLocked());
    assert(firstChild == null);
    _createOrObtainChild(index, after: null);
    if (firstChild != null) {
      assert(firstChild == lastChild);
      assert(indexOf(firstChild!) == index);
      final SliverMultiBoxAdaptorParentData firstChildParentData =
          firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      firstChildParentData.layoutOffset = layoutOffset;
      return true;
    }
    childManager.setDidUnderflow(true);
    return false;
  }

  /// Called during layout to create, add, and layout the child before
  /// [firstChild].
  ///
  /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
  /// the child if necessary. The child may instead be obtained from a cache;
  /// see [SliverMultiBoxAdaptorParentData.keepAlive].
  ///
  /// Returns the new child or null if no child was obtained.
  ///
  /// The child that was previously the first child, as well as any subsequent
  /// children, may be removed by this call if they have not yet been laid out
  /// during this layout pass. No child should be added during that call except
  /// for the one that is created and returned by `createChild`.
  @protected
  RenderBox? insertAndLayoutLeadingChild(
    BoxConstraints childConstraints, {
    bool parentUsesSize = false,
  }) {
    final int index = indexOf(firstChild!) - 1;
    _createOrObtainChild(index, after: null);
    if (indexOf(firstChild!) == index) {
      firstChild!.layout(childConstraints, parentUsesSize: parentUsesSize);
      return firstChild;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  /// 在布局过程中调用，在给定child后面创建、添加和布局child。
  ///
  /// 调用 [RenderSliverBoxChildManager.createChild] 来实际创建并在必要时添加子代。
  /// 子代可以从缓存中获取；参见 [SliverMultiBoxAdaptorParentData.keepAlive]。
  ///
  /// 返回新的child。调用者有责任配置child的滚动偏移量。
  ///
  /// 在此过程中，"after "child之后的Children可以被删除。只新的child可以被添加。
  ///
  @protected
  RenderBox? insertAndLayoutChild(
    BoxConstraints childConstraints, {
    required RenderBox? after,
    bool parentUsesSize = false,
  }) {
    //计算出需要的child对应的index
    final int index = indexOf(after!) + 1;
    //创建或者从缓存获取child
    _createOrObtainChild(index, after: after);
    //获取'after'后面的child
    final RenderBox? child = childAfter(after);

    if (child != null && indexOf(child) == index) {
      //布局新插入的child
      child.layout(childConstraints, parentUsesSize: parentUsesSize);
      return child;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  /// 在布局后调用，在child列表的头部和尾部有可被垃圾收集的child数量。
  ///
  /// 属性[SliverMultiBoxAdaptorParentData.keepAlive]被设置为true的Children将会被
  /// 移到cache中，而不是被丢弃（dropped）
  ///
  /// 这个方法也会收集任何以前被保留下来但现在不再需要的孩子。因此，它应该在每次运行[performLayout]
  /// 时被调用，即使参数都是零。
  @protected
  void collectGarbage(int leadingGarbage, int trailingGarbage) {
    assert(_debugAssertChildListLocked());
    assert(childCount >= leadingGarbage + trailingGarbage);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      //删除或缓存头部child
      while (leadingGarbage > 0) {
        _destroyOrCacheChild(firstChild!);
        leadingGarbage -= 1;
      }
      //删除或缓存尾部child
      while (trailingGarbage > 0) {
        _destroyOrCacheChild(lastChild!);
        trailingGarbage -= 1;
      }
      // 要求child manager删除不再保持活力（alive）的children。这应该会导致_keepAliveBucket
      // 发生变化，所以我们必须提前准备好我们的列表）。
      _keepAliveBucket.values
          .where((RenderBox child) {
            final SliverMultiBoxAdaptorParentData childParentData =
                child.parentData! as SliverMultiBoxAdaptorParentData;
            return !childParentData.keepAlive;
          })
          .toList()
          .forEach(_childManager.removeChild);
      assert(_keepAliveBucket.values.where((RenderBox child) {
        final SliverMultiBoxAdaptorParentData childParentData =
            child.parentData! as SliverMultiBoxAdaptorParentData;
        return !childParentData.keepAlive;
      }).isEmpty);
    });
  }

  /// Returns the index of the given child, as given by the
  /// [SliverMultiBoxAdaptorParentData.index] field of the child's [parentData].
  int indexOf(RenderBox child) {
    assert(child != null);
    final SliverMultiBoxAdaptorParentData childParentData =
        child.parentData! as SliverMultiBoxAdaptorParentData;
    assert(childParentData.index != null);
    return childParentData.index!;
  }

  /// Returns the dimension of the given child in the main axis, as given by the
  /// child's [RenderBox.size] property. This is only valid after layout.
  @protected
  double paintExtentOf(RenderBox child) {
    assert(child != null);
    assert(child.hasSize);
    switch (constraints.axis) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {required double mainAxisPosition, required double crossAxisPosition}) {
    RenderBox? child = lastChild;
    final BoxHitTestResult boxResult = BoxHitTestResult.wrap(result);
    while (child != null) {
      if (hitTestBoxChild(boxResult, child,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition)) return true;
      child = childBefore(child);
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return childScrollOffset(child)! - constraints.scrollOffset;
  }

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child != null);
    assert(child.parent == this);
    final SliverMultiBoxAdaptorParentData childParentData =
        child.parentData! as SliverMultiBoxAdaptorParentData;
    return childParentData.layoutOffset;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_keepAliveBucket.containsKey(indexOf(child))) {
      // It is possible that widgets under kept alive children want to paint
      // themselves. For example, the Material widget tries to paint all
      // InkFeatures under its subtree as long as they are not disposed. In
      // such case, we give it a zero transform to prevent them from painting.
      transform.setZero();
    } else {
      applyPaintTransformForBoxChild(child, transform);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;
    // offset is to the top-left corner, regardless of our axis direction.
    // originOffset gives us the delta from the real origin to the origin in the axis direction.
    final Offset mainAxisUnit, crossAxisUnit, originOffset;
    final bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        mainAxisUnit = const Offset(0.0, -1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset + Offset(0.0, geometry!.paintExtent);
        addExtent = true;
        break;
      case AxisDirection.right:
        mainAxisUnit = const Offset(1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.down:
        mainAxisUnit = const Offset(0.0, 1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.left:
        mainAxisUnit = const Offset(-1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset + Offset(geometry!.paintExtent, 0.0);
        addExtent = true;
        break;
    }
    assert(mainAxisUnit != null);
    assert(addExtent != null);
    RenderBox? child = firstChild;
    while (child != null) {
      final double mainAxisDelta = childMainAxisPosition(child);
      final double crossAxisDelta = childCrossAxisPosition(child);
      Offset childOffset = Offset(
        originOffset.dx +
            mainAxisUnit.dx * mainAxisDelta +
            crossAxisUnit.dx * crossAxisDelta,
        originOffset.dy +
            mainAxisUnit.dy * mainAxisDelta +
            crossAxisUnit.dy * crossAxisDelta,
      );
      if (addExtent) childOffset += mainAxisUnit * paintExtentOf(child);

      // If the child's visible interval (mainAxisDelta, mainAxisDelta + paintExtentOf(child))
      // does not intersect the paint extent interval (0, constraints.remainingPaintExtent), it's hidden.
      if (mainAxisDelta < constraints.remainingPaintExtent &&
          mainAxisDelta + paintExtentOf(child) > 0)
        context.paintChild(child, childOffset);

      child = childAfter(child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message(firstChild != null
        ? 'currently live children: ${indexOf(firstChild!)} to ${indexOf(lastChild!)}'
        : 'no children current live'));
  }

  /// Asserts that the reified child list is not empty and has a contiguous
  /// sequence of indices.
  ///
  /// Always returns true.
  bool debugAssertChildListIsNonEmptyAndContiguous() {
    assert(() {
      assert(firstChild != null);
      int index = indexOf(firstChild!);
      RenderBox? child = childAfter(firstChild!);
      while (child != null) {
        index += 1;
        assert(indexOf(child) == index);
        child = childAfter(child);
      }
      return true;
    }());
    return true;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild != null) {
      RenderBox? child = firstChild;
      while (true) {
        final SliverMultiBoxAdaptorParentData childParentData =
            child!.parentData! as SliverMultiBoxAdaptorParentData;
        children.add(child.toDiagnosticsNode(
            name: 'child with index ${childParentData.index}'));
        if (child == lastChild) break;
        child = childParentData.nextSibling;
      }
    }
    if (_keepAliveBucket.isNotEmpty) {
      final List<int> indices = _keepAliveBucket.keys.toList()..sort();
      for (final int index in indices) {
        children.add(_keepAliveBucket[index]!.toDiagnosticsNode(
          name: 'child with index $index (kept alive but not laid out)',
          style: DiagnosticsTreeStyle.offstage,
        ));
      }
    }
    return children;
  }
}
