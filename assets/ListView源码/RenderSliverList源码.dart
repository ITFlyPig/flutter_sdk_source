/// 一个sliver，可以将多个box类型的children置于沿主轴的线性排列。
///
/// 每个子代都必须在副轴上有[SliverConstraints.crossAxisExtent]，但确定自己的主轴尺寸。
///
/// [RenderSliverList]通过 “死计算(dead reckoning) "来确定它的滚动偏移量，因为在sliver
/// 可见部分之外的children没有被物化，这意味着[RenderSliverList]不能使用它们的主轴尺寸。
/// 取而代之的是，新物化的子代被放置在现有子代的旁边。如果这种死盘算导致逻辑上的不一致（例如，
/// 试图将第零个子代放置在滚动偏移量不是零的地方），[RenderSliverList]会生成一个[SliverGeometry.scrollOffsetCorrection]来恢复一致性。
///
/// 如果子代在主轴上有一个固定的尺寸，可以考虑使用[RenderSliverFixedExtentList]而不是[RenderSliverList]，
/// 因为[RenderSliverFixedExtentList]不需要对其子代进行布局来获取它们在主轴上的尺寸，因此效率更高。
///
/// See also:
///
/// * [RenderSliverFixedExtentList]，对于主轴方向具有相同尺寸的child，效率更高。
/// * [RenderSliverGrid]，它将其子代置于任意位置。
///
class RenderSliverList extends RenderSliverMultiBoxAdaptor {
  /// 创建一个sliver，将多个box类型的子代沿主轴的线性摆放。
  ///
  /// The [childManager] argument must not be null.
  RenderSliverList({
    required RenderSliverBoxChildManager childManager,
  }) : super(childManager: childManager);

  @override
  void performLayout() {
    //获取布局约束
    final SliverConstraints constraints = this.constraints;

    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    // scrollOffset落在cache区域内，得到值一直为0
    // 在cache区域外，值为：constraints.scrollOffset - cacheExtent
    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    ////剩余的尺寸 = cacheExtent * 2 + viewport尺寸，因为cacheExtent是变化的，所以这个值也一直变化直到cacheOrigin达到了cache的最大值
    final double remainingExtent = constraints.remainingCacheExtent;
    //
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    final BoxConstraints childConstraints = constraints.asBoxConstraints();

    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    // 这个算法原则上是简单明了的：找到第一个与给定的scrollOffset重叠的子代，必要时在列表顶
    // 部创建更多的子代，然后向下走，更新和布局每个子代，必要时在最后添加更多子代，直到我们有
    // 足够的子代覆盖整个视窗。
    //
    // 有一个小问题比较复杂，那就是任何时候你更新或创建一个子代，都有可能将一些还没有布局的子
    // 代删除，使列表处于不一致的状态，需要重新创建缺少的节点。
    //
    // 为了保持这种混乱的状态易于处理，这个算法从当前的第一个子节点（如果有的话）开始，然后从
    // 那里向上和/或向下走，所以可能被删除的节点总是在已经布局好的节点的边缘。
    //
    // 确保我们至少有一个子代开始。
    // 一般第一次布局的时候，会在这里面添加第一个child，放在布局偏移量为0的地方
    if (firstChild == null) {
      // 使用addInitialChild创建和添加索引为0的child
      if (!addInitialChild()) {
        // There are no children.
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    // 到这里至少有一个child

    // 这些变量跟踪了我们布局了的children的范围。
    // 在这个范围内，children有连续的指数。在这个范围之外，有可能在没有通知的情况下将子代删除。
    RenderBox? leadingChildWithLayout, trailingChildWithLayout;

    RenderBox? earliestUsefulChild = firstChild;

    // firstChild的布局偏移为空(null)，可能是子代重新排序导致的结果。
    //
    // 我们依靠firstChild来获得准确的布局偏移。在布局偏移为空(null)的情况下，我们必须找到具
    // 有有效布局偏移的第一个子代。
    if (childScrollOffset(firstChild!) == null) {
      //记录firstChild后面，没有布局偏移的child数量
      int leadingChildrenWithoutLayoutOffset = 0;
      //从firstChild往后找，找到布局偏移的child才停止
      while (earliestUsefulChild != null && childScrollOffset(earliestUsefulChild) == null) {
        earliestUsefulChild = childAfter(earliestUsefulChild);
        leadingChildrenWithoutLayoutOffset += 1;
      }
      // 我们应该能够安全地销毁布局偏移为空的子代，因为它们很可能在视窗之外。
      collectGarbage(leadingChildrenWithoutLayoutOffset, 0);
      // 如果找不到有效的布局偏移，则从初始化的子代开始。
      // If can not find a valid layout offset, start from the initial child.
      if (firstChild == null) {
        if (!addInitialChild()) {
          // There are no children.
          geometry = SliverGeometry.zero;
          childManager.didFinishLayout();
          return;
        }
      }
    }

    // 找出位于scrollOffset或之前的最后一个子代。
    // Find the last child that is at or before the scrollOffset.
    // 下面的for循环的主要逻辑就是不断添加firstChild前面的child，并布局，知道完全填充了cache区域
    earliestUsefulChild = firstChild;
    for (double earliestScrollOffset = childScrollOffset(earliestUsefulChild!)!;
    earliestScrollOffset > scrollOffset; // 表示最前面的child的布局偏移罗在cache区域内，还需要在布局child去填充cache区域
    earliestScrollOffset = childScrollOffset(earliestUsefulChild)!) {
      // We have to add children before the earliestUsefulChild.
      // 我们必须在earliestUsefulChild之前添加子代。
      earliestUsefulChild = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);

      //firstChild前面没有child来填充cache区域剩余的空间了
      if (earliestUsefulChild == null) {
        final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
        //将第一个child的布局偏移设置为0，因为前面没有更多的child了
        childParentData.layoutOffset = 0.0;

        if (scrollOffset == 0.0) {//在cache区域内，这个变量一直为0
          // insertAndLayoutLeadingChild only lays out the children before
          // firstChild. In this case, nothing has been laid out. We have
          // to lay out firstChild manually.
          // insertAndLayoutLeadingChild只在firstChild之前布局子代。在这种情况下，没有
          // 任何东西被布局出来。我们必须手动布局firstChild。
          firstChild!.layout(childConstraints, parentUsesSize: true);
          earliestUsefulChild = firstChild;
          leadingChildWithLayout = earliestUsefulChild;
          trailingChildWithLayout ??= earliestUsefulChild;
          break;
        } else {
          // 在达到滚动偏移量之前，我们已经用完了所有的children。我们必须通知我们的父体，
          // 这个sliver不能完成它的合同，我们需要修正滚动偏移量。
          geometry = SliverGeometry(
            scrollOffsetCorrection: -scrollOffset,
          );
          return;
        }
      }

      //计算最开始的child的滚动偏移量，也就是最开始的child的布局偏移 - child自己的尺寸
      final double firstChildScrollOffset = earliestScrollOffset - paintExtentOf(firstChild!);
      // firstChildScrollOffset可能包含双精度错误
      if (firstChildScrollOffset < -precisionErrorTolerance) {
        // 我们假设第一个子代之前没有子代。如果没有的话，我们会在下一个布局中进行修正。
        geometry = SliverGeometry(
          scrollOffsetCorrection: -firstChildScrollOffset,
        );
        final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;
        return;
      }

      final SliverMultiBoxAdaptorParentData childParentData = earliestUsefulChild.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = firstChildScrollOffset;
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }

    assert(childScrollOffset(firstChild!)! > -precisionErrorTolerance);

    // 如果滚动偏移量为零，我们应该确保我们确实是在列表的开头，下面每循环一次就调整一个child
    // 因为精度的存在，下面的判断可以看做：if (scrollOffset == 0) 来理解
    if (scrollOffset < precisionErrorTolerance) {
      // 我们从firstChild开始迭代，万一leading child 的 paint extent 为0。
      while (indexOf(firstChild!) > 0) {//当第一个child的索引不是0的情况走下面while里面的逻辑
        //获取firstChild的布局偏移
        final double earliestScrollOffset = childScrollOffset(firstChild!)!;
        // 我们每次修正一个子代。如果在earliestUsefulChild之前有更多的子代，一旦滚动偏移量再次达到零，我们就会修正它。
        // 在firstChild前面插入和和布局一个child
        earliestUsefulChild = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
        assert(earliestUsefulChild != null);
        final double firstChildScrollOffset = earliestScrollOffset - paintExtentOf(firstChild!);
        final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;
        // 我们只需要纠正，如果leading child 真的有paint extent。
        if (firstChildScrollOffset < -precisionErrorTolerance) {
          geometry = SliverGeometry(
            scrollOffsetCorrection: -firstChildScrollOffset,
          );
          return;
        }
      }
    }

    // 此时，earliestUsefulChild是第一个子代，子代的滚动偏移（scrollOffset）处在scrollOffset处或之前，
    // leadingChildWithLayout和trailingChildWithLayout要么为空，要么覆盖我们一部剧的render box范围，
    // 第一个与earliestUsefulChild相同，最后一个在滚动偏移处或之后。

    assert(earliestUsefulChild == firstChild);
    assert(childScrollOffset(earliestUsefulChild!)! <= scrollOffset);

    // 确保我们至少布局了一个子代
    if (leadingChildWithLayout == null) {
      earliestUsefulChild!.layout(childConstraints, parentUsesSize: true);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    // 在这里，earliestUsefulChild仍然是第一个子代，它的scrollOffset（其实是它的布局偏移量）在我们实际的
    // scrollOffset上或之前，而且它已经被布局了，实际上是我们的leadingChildWithLayout。
    // 有可能在这个子代之外的一些子代也已经被布局了。

    bool inLayoutRange = true;
    RenderBox? child = earliestUsefulChild;
    //获取child索引
    int index = indexOf(child!);
    // child对应的滚动偏移结束位置
    double endScrollOffset = childScrollOffset(child)! + paintExtentOf(child);

    // 这个函数的作用就是在当前child后面添加并布局一个child，然后更新记录的布局偏移量
    bool advance() { // 如果我们前进了，则返回true；如果我们没有子代了，则返回false。
      // 这个函数在下面两个不同的地方使用，以避免代码重复。
      if (child == trailingChildWithLayout)
        inLayoutRange = false;
      child = childAfter(child!);
      if (child == null)
        inLayoutRange = false;
      index += 1;

      //不在布局范围内，则需要布局
      if (!inLayoutRange) {
        if (child == null || indexOf(child!) != index) {
          // 我们缺少一个子代。如果可能的话，请插入（并布局）
          child = insertAndLayoutChild(childConstraints,
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          if (child == null) {
            // 我们已经没有子代了
            return false;
          }
        } else {
          // 布局 child.
          child!.layout(childConstraints, parentUsesSize: true);
        }
        //将trailingChildWithLayout后移
        trailingChildWithLayout = child;
      }

      final SliverMultiBoxAdaptorParentData childParentData = child!.parentData! as SliverMultiBoxAdaptorParentData;
      //赋值布局偏移量
      childParentData.layoutOffset = endScrollOffset;
      //更新endScrollOffset
      endScrollOffset = childScrollOffset(child!)! + paintExtentOf(child!);
      return true;
    }


    // Find the first child that ends after the scroll offset.
    // 找到滚动偏移结束后的第一个子代，这里应该就是回收前面不需要的child的主要逻辑
    while (endScrollOffset < scrollOffset) {
      leadingGarbage += 1;

      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        //我们要确保保留最后一个子代，这样我们就能知道最后的滚动偏移量了
        collectGarbage(leadingGarbage - 1, 0);
        assert(firstChild == lastChild);
        final double extent = childScrollOffset(lastChild!)! + paintExtentOf(lastChild!);
        geometry = SliverGeometry(
          scrollExtent: extent,
          paintExtent: 0.0,
          maxPaintExtent: extent,
        );
        return;
      }
    }

    //第一次添加和布局后续child，主要是通过这来实现的
    // Now find the first child that ends after our end.
    // 现在找到我们结束后的第一个子代
    while (endScrollOffset < targetEndScrollOffset) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }

    // Finally count up all the remaining children and label them as garbage.
    // 最后把剩下的孩子全部清点出来，贴上垃圾标签。
    // 在targetEndScrollOffset之后的child，也就是在需要布局范围之外的child，清点出来，然后回收
    if (child != null) {
      child = childAfter(child!);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child!);
      }
    }

    // 这时一切应该都好办了，我们只需要清理垃圾，上报geometry

    collectGarbage(leadingGarbage, trailingGarbage);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    final double estimatedMaxScrollOffset;

    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild!),
        lastIndex: indexOf(lastChild!),
        leadingScrollOffset: childScrollOffset(firstChild!),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedMaxScrollOffset >= endScrollOffset - childScrollOffset(firstChild!)!);
    }
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: childScrollOffset(firstChild!)!,
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: childScrollOffset(firstChild!)!,
      to: endScrollOffset,
    );
    final double targetEndScrollOffsetForPaint = constraints.scrollOffset + constraints.remainingPaintExtent;

    //最终的sliver输出
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent, //sliver自己的尺寸
      cacheExtent: cacheExtent, // cache的尺寸
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: endScrollOffset > targetEndScrollOffsetForPaint || constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    // 我们可能在滚动到最后的时候开始了布局，这样就不会暴露出一个新的子代。
    if (estimatedMaxScrollOffset == endScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }
}
