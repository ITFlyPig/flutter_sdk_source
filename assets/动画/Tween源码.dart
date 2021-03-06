/// 在开始和结束之的线性插值器
///
///
/// [Tween] is useful if you want to interpolate across a range.
///
/// To use a [Tween] object with an animation, call the [Tween] object's
/// [animate] method and pass it the [Animation] object that you want to
/// modify.
///
/// You can chain [Tween] objects together using the [chain] method, so that a
/// single [Animation] object is configured by multiple [Tween] objects called
/// in succession. This is different than calling the [animate] method twice,
/// which results in two separate [Animation] objects, each configured with a
/// single [Tween].
///
/// {@tool snippet}
///
/// Suppose `_controller` is an [AnimationController], and we want to create an
/// [Animation<Offset>] that is controlled by that controller, and save it in
/// `_animation`. Here are two possible ways of expressing this:
///
/// ```dart
/// _animation = _controller.drive(
///   Tween<Offset>(
///     begin: const Offset(100.0, 50.0),
///     end: const Offset(200.0, 300.0),
///   ),
/// );
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// ```dart
/// _animation = Tween<Offset>(
///   begin: const Offset(100.0, 50.0),
///   end: const Offset(200.0, 300.0),
/// ).animate(_controller);
/// ```
/// {@end-tool}
///
/// In both cases, the `_animation` variable holds an object that, over the
/// lifetime of the `_controller`'s animation, returns a value
/// (`_animation.value`) that depicts a point along the line between the two
/// offsets above. If we used a [MaterialPointArcTween] instead of a
/// [Tween<Offset>] in the code above, the points would follow a pleasing curve
/// instead of a straight line, with no other changes necessary.
///
/// ## Performance optimizations
///
/// Tweens are mutable; specifically, their [begin] and [end] values can be
/// changed at runtime. An object created with [Animation.drive] using a [Tween]
/// will immediately honor changes to that underlying [Tween] (though the
/// listeners will only be triggered if the [Animation] is actively animating).
/// This can be used to change an animation on the fly without having to
/// recreate all the objects in the chain from the [AnimationController] to the
/// final [Tween].
///
/// If a [Tween]'s values are never changed, however, a further optimization can
/// be applied: the object can be stored in a `static final` variable, so that
/// the exact same instance is used whenever the [Tween] is needed. This is
/// preferable to creating an identical [Tween] afresh each time a [State.build]
/// method is called, for example.
///
/// ## Types with special considerations
///
/// Classes with [lerp] static methods typically have corresponding dedicated
/// [Tween] subclasses that call that method. For example, [ColorTween] uses
/// [Color.lerp] to implement the [ColorTween.lerp] method.
///
/// Types that define `+` and `-` operators to combine values (`T + T → T` and
/// `T - T → T`) and an `*` operator to scale by multiplying with a double (`T *
/// double → T`) can be directly used with `Tween<T>`.
///
/// This does not extend to any type with `+`, `-`, and `*` operators. In
/// particular, [int] does not satisfy this precise contract (`int * double`
/// actually returns [num], not [int]). There are therefore two specific classes
/// that can be used to interpolate integers:
///
///  * [IntTween], which is an approximation of a linear interpolation (using
///    [double.round]).
///  * [StepTween], which uses [double.floor] to ensure that the result is
///    never greater than it would be using if a `Tween<double>`.
///
/// The relevant operators on [Size] also don't fulfill this contract, so
/// [SizeTween] uses [Size.lerp].
///
/// In addition, some of the types that _do_ have suitable `+`, `-`, and `*`
/// operators still have dedicated [Tween] subclasses that perform the
/// interpolation in a more specialized manner. One such class is
/// [MaterialPointArcTween], which is mentioned above. The [AlignmentTween], and
/// [AlignmentGeometryTween], and [FractionalOffsetTween] are another group of
/// [Tween]s that use dedicated `lerp` methods instead of merely relying on the
/// operators (in particular, this allows them to handle null values in a more
/// useful manner).
///
/// ## Nullability
///
/// The [begin] and [end] fields are nullable; a [Tween] does not have to
/// have non-null values specified when it is created.
///
/// If `T` is nullable, then [lerp] and [transform] may return null.
/// This is typically seen in the case where [begin] is null and `t`
/// is 0.0, or [end] is null and `t` is 1.0, or both are null (at any
/// `t` value).
///
/// If `T` is not nullable, then [begin] and [end] must both be set to
/// non-null values before using [lerp] or [transform], otherwise they
/// will throw.
class Tween<T extends dynamic> extends Animatable<T> {
  /// Creates a tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  Tween({
    this.begin,
    this.end,
  });

  /// The value this variable has at the beginning of the animation.
  ///
  /// See the constructor for details about whether this property may be null
  /// (it varies from subclass to subclass).
  T? begin;

  /// The value this variable has at the end of the animation.
  ///
  /// See the constructor for details about whether this property may be null
  /// (it varies from subclass to subclass).
  T? end;

  /// Returns the value this variable has at the given animation clock value.
  ///
  /// The default implementation of this method uses the [+], [-], and [*]
  /// operators on `T`. The [begin] and [end] properties must therefore be
  /// non-null by the time this method is called.
  ///
  /// In general, however, it is possible for this to return null, especially
  /// when `t`=0.0 and [begin] is null, or `t`=1.0 and [end] is null.
  @protected
  T lerp(double t) {
    assert(begin != null);
    assert(end != null);
    return begin + (end - begin) * t as T;
  }

  /// Returns the interpolated value for the current value of the given animation.
  ///
  /// This method returns `begin` and `end` when the animation values are 0.0 or
  /// 1.0, respectively.
  ///
  /// This function is implemented by deferring to [lerp]. Subclasses that want
  /// to provide custom behavior should override [lerp], not [transform] (nor
  /// [evaluate]).
  ///
  /// See the constructor for details about whether the [begin] and [end]
  /// properties may be null when this is called. It varies from subclass to
  /// subclass.
  @override
  T transform(double t) {
    if (t == 0.0)
      return begin as T;
    if (t == 1.0)
      return end as T;
    return lerp(t);
  }

  @override
  String toString() => '${objectRuntimeType(this, 'Animatable')}($begin \u2192 $end)';
}
