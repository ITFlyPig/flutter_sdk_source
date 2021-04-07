class RenderPositionedBox extends RenderAligningShiftedBox {
  /// Creates a render object that positions its child.
  RenderPositionedBox({
    RenderBox? child,
    double? widthFactor,
    double? heightFactor,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection? textDirection,
  }) :
        _widthFactor = widthFactor,
        _heightFactor = heightFactor,
        super(child: child, alignment: alignment, textDirection: textDirection);

  /// If non-null, sets its width to the child's width multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  double? get widthFactor => _widthFactor;
  double? _widthFactor;
  set widthFactor(double? value) {
    if (_widthFactor == value)
      return;
    _widthFactor = value;
    markNeedsLayout();
  }

  /// If non-null, sets its height to the child's height multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  double? get heightFactor => _heightFactor;
  double? _heightFactor;
  set heightFactor(double? value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value)
      return;
    _heightFactor = value;
    markNeedsLayout();
  }

  ///纯粹基于约束条件进行大小计算需要重写的方法
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    //是否是缩小到包裹
    final bool shrinkWrapWidth = _widthFactor != null || constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight = _heightFactor != null || constraints.maxHeight == double.infinity;

    if (child != null) {
      //获取child的仅仅根据约束就计算出来的尺寸
      final Size childSize = child!.getDryLayout(constraints.loosen());
      // 布局约束：缩小到child的大小或者是无限大
      return constraints.constrain(Size(
          shrinkWrapWidth ? childSize.width * (_widthFactor ?? 1.0) : double.infinity,
          shrinkWrapHeight ? childSize.height * (_heightFactor ?? 1.0) : double.infinity),
      );
    }
    //没有child的情况
    return constraints.constrain(Size(
      shrinkWrapWidth ? 0.0 : double.infinity,
      shrinkWrapHeight ? 0.0 : double.infinity,
    ));
  }

  /// 实现布局的逻辑
  @override
  void performLayout() {
    //获取布局约束
    final BoxConstraints constraints = this.constraints;
    //是否需要wrap_content效果
    final bool shrinkWrapWidth = _widthFactor != null || constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight = _heightFactor != null || constraints.maxHeight == double.infinity;

    if (child != null) {
      //布局child
      child!.layout(constraints.loosen(), parentUsesSize: true);
      // 使用child的尺寸(wrap_content)或者无限大(match_parent)
      size = constraints.constrain(Size(shrinkWrapWidth ? child!.size.width * (_widthFactor ?? 1.0) : double.infinity,
          shrinkWrapHeight ? child!.size.height * (_heightFactor ?? 1.0) : double.infinity));
      //具体child位置摆放，在parent实现
      alignChild();
    } else {
      //0(wrap_content)或者无限大(match_parent)
      size = constraints.constrain(Size(shrinkWrapWidth ? 0.0 : double.infinity,
          shrinkWrapHeight ? 0.0 : double.infinity));
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
  }

}
