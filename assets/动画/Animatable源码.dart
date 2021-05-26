import 'package:flutter/material.dart';

///
/// 给定一个[Animation<double>]作为输入，可以产生`T'类型值的对象。
///
/// 通常，输入的动画值名义上是在0.0到1.0之间。然而，原则上，可以提供任何数值。
///
/// [Animatable]的主要子类是[Tween]。
abstract class Animatable<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Animatable();

  ///
  /// 返回对象在`t'点的值
  ///
  /// The value of `t` is nominally a fraction in the range 0.0 to 1.0, though
  /// in practice it may extend outside this range.
  ///
  /// See also:
  ///
  ///  * [evaluate], which is a shorthand for applying [transform] to the value
  ///    of an [Animation].
  ///  * [Curve.transform], a similar method for easing curves.
  T transform(double t);

  /// The current value of this object for the given [Animation].
  ///
  /// This function is implemented by deferring to [transform]. Subclasses that
  /// want to provide custom behavior should override [transform], not
  /// [evaluate].
  ///
  /// See also:
  ///
  ///  * [transform], which is similar but takes a `t` value directly instead of
  ///    an [Animation].
  ///  * [animate], which creates an [Animation] out of this object, continually
  ///    applying [evaluate].
  T evaluate(Animation<double> animation) => transform(animation.value);

  /// 返回一个新的[Animation]，这个[Animation]是由给定的动画驱动的，但是它的值由这个对象决定。
  //
  // 本质上，这将返回一个[Animation]，自动应用[evaluate]方法到父对象的值。
  ///
  /// See also:
  ///
  ///  * [AnimationController.drive], which does the same thing from the
  ///    opposite starting point.
  Animation<T> animate(Animation<double> parent) {
    return _AnimatedEvaluation<T>(parent, this);
  }

  /// Returns a new [Animatable] whose value is determined by first evaluating
  /// the given parent and then evaluating this object.
  ///
  /// This allows [Tween]s to be chained before obtaining an [Animation].
  Animatable<T> chain(Animatable<double> parent) {
    return _ChainedEvaluation<T>(parent, this);
  }
}


class _AnimatedEvaluation<T> extends Animation<T> with AnimationWithParentMixin<double> {
  _AnimatedEvaluation(this.parent, this._evaluatable);

  @override
  final Animation<double> parent;

  final Animatable<T> _evaluatable;

  @override
  T get value => _evaluatable.evaluate(parent);

  @override
  String toString() {
    return '$parent\u27A9$_evaluatable\u27A9$value';
  }

  @override
  String toStringDetails() {
    return '${super.toStringDetails()} $_evaluatable';
  }
}
