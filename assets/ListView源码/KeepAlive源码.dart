/// 将一个孩子标记为需要活着，即使它在一个懒加载的列表中，否则将删除它。
///
/// 这个部件用于[SliverWithKeepAliveWidget]，如[SliverGrid]或[SliverList]。
///
/// 这个小部件很少直接使用。与[SliverList]和[SliverGrid]以及滚动视图对应的[ListView]和
/// [GridView]一起使用的[SliverChildBuilderDelegate]和[SliverChildListDelegate]代表有
/// 一个 "addAutomaticKeepAlives "功能。默认情况下是启用的，它使[AutomaticKeepAlive]部
/// 件被插入到每个子部件周围，使[KeepAlive]部件根据[KeepAliveNotification]自动添加和配置。
///
/// 因此，为了保持一个小部件的活着，使用这些通知比直接处理[KeepAlive]小部件更常见。
///
/// 在实践中，处理这些通知的最简单方法是将[AutomaticKeepAliveClientMixin]混合到一个[State]中。
/// 详情请看该混合类的文档。
///
class KeepAlive extends ParentDataWidget<KeepAliveParentDataMixin> {
  /// Marks a child as needing to remain alive.
  ///
  /// The [child] and [keepAlive] arguments must not be null.
  const KeepAlive({
    Key? key,
    required this.keepAlive,
    required Widget child,
  }) : assert(child != null),
        assert(keepAlive != null),
        super(key: key, child: child);

  /// Whether to keep the child alive.
  ///
  /// If this is false, it is as if this widget was omitted.
  final bool keepAlive;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is KeepAliveParentDataMixin);
    final KeepAliveParentDataMixin parentData = renderObject.parentData! as KeepAliveParentDataMixin;
    if (parentData.keepAlive != keepAlive) {
      parentData.keepAlive = keepAlive;
      final AbstractNode? targetParent = renderObject.parent;
      if (targetParent is RenderObject && !keepAlive)
        targetParent.markNeedsLayout(); // No need to redo layout if it became true.
    }
  }

  // We only return true if [keepAlive] is true, because turning _off_ keep
  // alive requires a layout to do the garbage collection (but turning it on
  // requires nothing, since by definition the widget is already alive and won't
  // go away _unless_ we do a layout).
  @override
  bool debugCanApplyOutOfTurn() => keepAlive;

  @override
  Type get debugTypicalAncestorWidgetClass => SliverWithKeepAliveWidget;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('keepAlive', keepAlive));
  }
}
