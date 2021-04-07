///
///Parent data，sliver类型的parent是使用 它的layout offsets来定位children
///
/// 这种数据结构是为快速布局而优化的。它最适合那些希望有许多子代的父母使用，这些子代的相对位
/// 置即使在滚动时也不会改变。
///
class SliverLogicalParentData extends ParentData {
  /// 子代相对于零滚动偏移量的位置。
  ///
  /// 从父sliver的滚动偏移量为零（即[SliverConstraints.scrollOffset]为零的那条线）到
  /// child最接近该偏移量的一侧的像素数。[layoutOffset]在无法确定时可以为空。该值将在布局后设置。
  ///
  /// 在一个典型的列表中，这不会随着parent的滚动而改变。
  ///
  /// 默认为null
  double? layoutOffset;

  @override
  String toString() => 'layoutOffset=${layoutOffset == null ? 'None': layoutOffset!.toStringAsFixed(1)}';
}
