abstract class RenderShiftedBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  /// Initializes the [child] property for subclasses.
  RenderShiftedBox(RenderBox? child) {
    this.child = child;
  }

  ///
  /// 通过一系列的compute将当前box的最大/最小尺寸限制为child的相应尺寸
  ///
  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null)
      return child!.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null)
      return child!.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null)
      return child!.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null)
      return child!.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    double? result;
    if (child != null) {
      //如果有child，调用child的基线
      result = child!.getDistanceToActualBaseline(baseline);
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      if (result != null)
        result += childParentData.offset.dy;
    } else {
      //没有child，返回默认的基线计算
      result = super.computeDistanceToActualBaseline(baseline);
    }
    return result;
  }


  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      //绘制
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      context.paintChild(child!, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    if (child != null) {
      //将坐标转换后，委托给子代决定，是否命中
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      return result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformed) {
          return child!.hitTest(result, position: transformed!);
        },
      );
    }
    return false;
  }
}
