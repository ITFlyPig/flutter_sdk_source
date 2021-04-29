///
/// [RenderSliverMultiBoxAdaptor]用来管理其子代的委托（delegate）。
///
/// [RenderSliverMultiBoxAdaptor]对象懒惰地重新定义其子对象，以避免在视口中不可见的子对
/// 象上花费资源。这个委托可以创建和删除children，以及估计全部子列表所占用的总滚动偏移尺寸
/// （total scroll offset extent ）。
///
abstract class RenderSliverBoxChildManager {
  /// 在布局过程中，当需要一个新的child时，调用该函数。该child应该被插入到child列表的适当
  /// 位置，在 "after "子代之后（如果 "after "为空，则插入到列表的开头）。它的索引和滚动偏
  /// 移量将自动被适当设置。
  ///
  /// `index`参数给出了要显示的孩子的索引。负也是可以请求的。例如：如果用户从子代0滚动到子
  /// 代10，然后这些子代变得更小，然后用户再次向上滚动，这个方法最终会被要求生成一个索引为-1的子代。
  ///
  /// 如果没有与`index`对应的子代，则什么也不做。
  ///
  /// 索引0表示哪个子代取决于[RenderSliverMultiBoxAdaptor]的`constraints`中指定的[GrowthDirection]。
  /// 例如，如果子代是字母，那么如果[SliverConstraints.growthDirection]是[GrowthDirection.forward]，
  /// 那么索引0是A，索引25是Z。另一方面，如果[SliverConstraints.growthDirection]是[GrowthDirection.reverse]，
  /// 那么指数0是Z，指数25是A。
  ///
  /// 在调用[createChild]的过程中，如果[RenderSliverMultiBoxAdaptor]对象的其他子代没有
  /// 在这一帧中创建，并且在这一帧中还没有更新，那么从该对象中删除其他子代是有效的。在此渲染
  /// 对象中添加任何其他子对象是无效的。
  void createChild(int index, {required RenderBox? after});

  /// 将child从child列表移除
  ///
  /// 该方法会被[RenderSliverMultiBoxAdaptor.collectGarbage]调用，
  /// 同时垃圾收集又会被[RenderSliverMultiBoxAdaptor]的`performLayout`调用。
  ///
  /// 传入的child的index可以通过[RenderSliverMultiBoxAdaptor.indexOf]获取，该方法读取
  /// [RenderObject.parentData]的[SliverMultiBoxAdaptorParentData.index]字段。
  ///
  void removeChild(RenderBox child);

  /// Called to estimate the total scrollable extents of this object.
  ///
  /// Must return the total distance from the start of the child with the
  /// earliest possible index to the end of the child with the last possible
  /// index.
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  });

  /// Called to obtain a precise measure of the total number of children.
  ///
  /// Must return the number that is one greater than the greatest `index` for
  /// which `createChild` will actually create a child.
  ///
  /// This is used when [createChild] cannot add a child for a positive `index`,
  /// to determine the precise dimensions of the sliver. It must return an
  /// accurate and precise non-null value. It will not be called if
  /// [createChild] is always able to create a child (e.g. for an infinite
  /// list).
  int get childCount;

  /// Called during [RenderSliverMultiBoxAdaptor.adoptChild] or
  /// [RenderSliverMultiBoxAdaptor.move].
  ///
  /// Subclasses must ensure that the [SliverMultiBoxAdaptorParentData.index]
  /// field of the child's [RenderObject.parentData] accurately reflects the
  /// child's index in the child list after this function returns.
  void didAdoptChild(RenderBox child);

  /// Called during layout to indicate whether this object provided insufficient
  /// children for the [RenderSliverMultiBoxAdaptor] to fill the
  /// [SliverConstraints.remainingPaintExtent].
  ///
  /// Typically called unconditionally at the start of layout with false and
  /// then later called with true when the [RenderSliverMultiBoxAdaptor]
  /// fails to create a child required to fill the
  /// [SliverConstraints.remainingPaintExtent].
  ///
  /// Useful for subclasses to determine whether newly added children could
  /// affect the visible contents of the [RenderSliverMultiBoxAdaptor].
  void setDidUnderflow(bool value);

  /// Called at the beginning of layout to indicate that layout is about to
  /// occur.
  void didStartLayout() {}

  /// Called at the end of layout to indicate that layout is now complete.
  void didFinishLayout() {}

  /// In debug mode, asserts that this manager is not expecting any
  /// modifications to the [RenderSliverMultiBoxAdaptor]'s child list.
  ///
  /// This function always returns true.
  ///
  /// The manager is not required to track whether it is expecting modifications
  /// to the [RenderSliverMultiBoxAdaptor]'s child list and can simply return
  /// true without making any assertions.
  bool debugAssertChildListLocked() => true;
}
