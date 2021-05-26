/// 一个将曲线应用于另一个动画的动画
///
///
/// 当你想对一个动画应用曲线[Curve]时，[CurvedAnimation]是很有用的，特别是当你想在动画前
/// 进和后退时使用不同的曲线。
//
//  根据给定的曲线，[CurvedAnimation]的输出可能比其输入有更大的范围。例如，像[Curves.elasticIn]
//  这样的弹性曲线会明显地过高或过低默认的0.0到1.0的范围。
//
//  如果你想把[Curve]应用于[Tween]，可以考虑使用[CurveTween]。
//
//  下面的代码片断显示了如何将曲线应用于由[AnimationController]`controller`产生的线性动画。
///
/// ```dart
/// final Animation<double> animation = CurvedAnimation(
///   parent: controller,
///   curve: Curves.ease,
/// );
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// 这第二个代码片段显示了如何在正向和反向方向上应用不同的曲线。这不能用[CurveTween]来完成
/// （因为[Tween]在应用时不知道动画的方向）。
///
/// ```dart
/// final Animation<double> animation = CurvedAnimation(
///   parent: controller,
///   curve: Curves.easeIn,
///   reverseCurve: Curves.easeOut,
/// );
/// ```
/// {@end-tool}
///
/// 默认情况下，[reverseCurve]与正向[curve]匹配。
///
/// See also:
///
///  * [CurveTween], for an alternative way of expressing the first sample
///    above.
///  * [AnimationController], for examples of creating and disposing of an
///    [AnimationController].
///  * [Curve.flipped] and [FlippedCurve], which provide the reverse of a
///    [Curve].
class CurvedAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  /// Creates a curved animation.
  ///
  /// The parent and curve arguments must not be null.
  CurvedAnimation({
    required this.parent,
    required this.curve,
    this.reverseCurve,
  })  : assert(parent != null),
        assert(curve != null) {
    _updateCurveDirection(parent.status);
    // 监听parent的改变
    parent.addStatusListener(_updateCurveDirection);
  }

  /// The animation to which this animation applies a curve.
  @override
  final Animation<double> parent;

  /// The curve to use in the forward direction.
  Curve curve;

  /// The curve to use in the reverse direction.
  ///
  /// If the parent animation changes direction without first reaching the
  /// [AnimationStatus.completed] or [AnimationStatus.dismissed] status, the
  /// [CurvedAnimation] stays on the same curve (albeit in the opposite
  /// direction) to avoid visual discontinuities.
  ///
  /// If you use a non-null [reverseCurve], you might want to hold this object
  /// in a [State] object rather than recreating it each time your widget builds
  /// in order to take advantage of the state in this object that avoids visual
  /// discontinuities.
  ///
  /// If this field is null, uses [curve] in both directions.
  Curve? reverseCurve;

  /// The direction used to select the current curve.
  ///
  /// The curve direction is only reset when we hit the beginning or the end of
  /// the timeline to avoid discontinuities in the value of any variables this
  /// animation is used to animate.
  AnimationStatus? _curveDirection;

  // 更新状态
  void _updateCurveDirection(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        _curveDirection = null;
        break;
      case AnimationStatus.forward:
        _curveDirection ??= AnimationStatus.forward;
        break;
      case AnimationStatus.reverse:
        _curveDirection ??= AnimationStatus.reverse;
        break;
    }
  }

  bool get _useForwardCurve {
    return reverseCurve == null ||
        (_curveDirection ?? parent.status) != AnimationStatus.reverse;
  }

  @override
  double get value {
    final Curve? activeCurve = _useForwardCurve ? curve : reverseCurve;

    final double t = parent.value;
    if (activeCurve == null) return t;
    if (t == 0.0 || t == 1.0) {
      assert(() {
        final double transformedValue = activeCurve.transform(t);
        final double roundedTransformedValue =
            transformedValue.round().toDouble();
        if (roundedTransformedValue != t) {
          throw FlutterError('Invalid curve endpoint at $t.\n'
              'Curves must map 0.0 to near zero and 1.0 to near one but '
              '${activeCurve.runtimeType} mapped $t to $transformedValue, which '
              'is near $roundedTransformedValue.');
        }
        return true;
      }());
      return t;
    }
    return activeCurve.transform(t);
  }

  @override
  String toString() {
    if (reverseCurve == null) return '$parent\u27A9$curve';
    if (_useForwardCurve)
      return '$parent\u27A9$curve\u2092\u2099/$reverseCurve';
    return '$parent\u27A9$curve/$reverseCurve\u2092\u2099';
  }
}
