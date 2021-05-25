import 'package:flutter/animation.dart';

/// 一个参数化的动画曲线，即单位间隔与单位间隔的映射。
//
// 曲线用于调整动画随时间变化的速度，让它们加快和减慢，而不是以恒定的速度移动。
///
/// A [Curve] must map t=0.0 to 0.0 and t=1.0 to 1.0.
///
/// See also:
///
///  * [Curves], 常用的动画曲线集合
///  * [CurveTween], 它可以将 [Curve] 运用到 [Animation].
///  * [Canvas.drawArc], which draws an arc, and has nothing to do with easing
///    curves.
///  * [Animatable], 更灵活的，将分数映射到任意值的接口
@immutable
abstract class Curve extends ParametricCurve<double> {
  /// Abstract const constructor to enable subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Curve();

  /// Returns the value of the curve at point `t`.
  ///
  /// This function must ensure the following:
  /// - The value of `t` must be between 0.0 and 1.0
  /// - Values of `t`=0.0 and `t`=1.0 must be mapped to 0.0 and 1.0,
  /// respectively.
  ///
  /// It is recommended that subclasses override [transformInternal] instead of
  /// this function, as the above cases are already handled in the default
  /// implementation of [transform], which delegates the remaining logic to
  /// [transformInternal].
  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) {
      return t;
    }
    return super.transform(t);
  }

  /// Returns a new curve that is the reversed inversion of this one.
  ///
  /// This is often useful with [CurvedAnimation.reverseCurve].
  ///
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4}
  /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_flipped.mp4}
  ///
  /// See also:
  ///
  ///  * [FlippedCurve], the class that is used to implement this getter.
  ///  * [ReverseAnimation], which reverses an [Animation] rather than a [Curve].
  ///  * [CurvedAnimation], which can take a separate curve and reverse curve.
  Curve get flipped => FlippedCurve(this);
}
