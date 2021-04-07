///
/// [ScrollActivity]的后端
///
/// 由[ScrollActivity]的子类使用，用于操作它们正在执行的滚动视图。
///
/// See also:
/// * [ScrollActivity]，它使用这个类作为它的委托
/// * [ScrollPositionWithSingleContext]，这个接口的主要实现。
///
///
abstract class ScrollActivityDelegate {
  /// 滚动的方向
  AxisDirection get axisDirection;

  /// 更新滚动位置为pixels
  double setPixels(double pixels);

  /// 按传入数值更新滚动位置
  ///
  /// 适用于用户直接操作滚动位置时，例如通过拖动scroll view。通常应用
  /// [ScrollPhysics.applyPhysicsToUserOffset]和其他适合用户驱动的滚动的变换。
  void applyUserOffset(double delta);

  /// 终止当前活动，并开始一个空闲的活动。
  void goIdle();

  /// 终止当前活动，并以给定速度开始弹道活动（ballistic activity ）。
  void goBallistic(double velocity);
}
