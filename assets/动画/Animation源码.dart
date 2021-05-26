/// 一个具有`T`类型值得动画
///
/// 一个动画由一个值（类型为`T`）和一个状态组成。状态表示动画在概念上是从开始到结束，还是从
/// 结束回到开始，尽管动画的实际值可能不是单调变化的（例如，如果动画使用一个弹跳的曲线）。
//
// 动画也让其他对象监听它们的值或它们的状态的变化。这些回调在管道的 "动画 "阶段被调用，就在重
// 建小部件之前。
//
// 要创建一个可以向前和向后运行的新动画，可以考虑使用[AnimationController]。
///
/// See also:
///
///  * [Tween], [Tween]，可用于创建[Animation]子类，将 "Animation<double>"转换成其他种类的 "Animation"。
abstract class Animation<T> extends Listenable implements ValueListenable<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Animation();

  // keep these next five dartdocs in sync with the dartdocs in AnimationWithParentMixin<T>

  /// Calls the listener every time the value of the animation changes.
  ///
  /// Listeners can be removed with [removeListener].
  @override
  void addListener(VoidCallback listener);

  /// Stop calling the listener every time the value of the animation changes.
  ///
  /// If `listener` is not currently registered as a listener, this method does
  /// nothing.
  ///
  /// Listeners can be added with [addListener].
  @override
  void removeListener(VoidCallback listener);

  /// Calls listener every time the status of the animation changes.
  ///
  /// Listeners can be removed with [removeStatusListener].
  void addStatusListener(AnimationStatusListener listener);

  /// Stops calling the listener every time the status of the animation changes.
  ///
  /// If `listener` is not currently registered as a status listener, this
  /// method does nothing.
  ///
  /// Listeners can be added with [addStatusListener].
  void removeStatusListener(AnimationStatusListener listener);

  /// The current status of this animation.
  AnimationStatus get status;

  /// The current value of the animation.
  @override
  T get value;

  /// Whether this animation is stopped at the beginning.
  bool get isDismissed => status == AnimationStatus.dismissed;

  /// Whether this animation is stopped at the end.
  bool get isCompleted => status == AnimationStatus.completed;

  /// Chains a [Tween] (or [CurveTween]) to this [Animation].
  ///
  /// This method is only valid for `Animation<double>` instances (i.e. when `T`
  /// is `double`). This means, for instance, that it can be called on
  /// [AnimationController] objects, as well as [CurvedAnimation]s,
  /// [ProxyAnimation]s, [ReverseAnimation]s, [TrainHoppingAnimation]s, etc.
  ///
  /// It returns an [Animation] specialized to the same type, `U`, as the
  /// argument to the method (`child`), whose value is derived by applying the
  /// given [Tween] to the value of this [Animation].
  ///
  /// {@tool snippet}
  ///
  /// Given an [AnimationController] `_controller`, the following code creates
  /// an `Animation<Alignment>` that swings from top left to top right as the
  /// controller goes from 0.0 to 1.0:
  ///
  /// ```dart
  /// Animation<Alignment> _alignment1 = _controller.drive(
  ///   AlignmentTween(
  ///     begin: Alignment.topLeft,
  ///     end: Alignment.topRight,
  ///   ),
  /// );
  /// ```
  /// {@end-tool}
  /// {@tool snippet}
  ///
  /// The `_alignment.value` could then be used in a widget's build method, for
  /// instance, to position a child using an [Align] widget such that the
  /// position of the child shifts over time from the top left to the top right.
  ///
  /// It is common to ease this kind of curve, e.g. making the transition slower
  /// at the start and faster at the end. The following snippet shows one way to
  /// chain the alignment tween in the previous example to an easing curve (in
  /// this case, [Curves.easeIn]). In this example, the tween is created
  /// elsewhere as a variable that can be reused, since none of its arguments
  /// vary.
  ///
  /// ```dart
  /// final Animatable<Alignment> _tween = AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight)
  ///   .chain(CurveTween(curve: Curves.easeIn));
  /// // ...
  /// Animation<Alignment> _alignment2 = _controller.drive(_tween);
  /// ```
  /// {@end-tool}
  /// {@tool snippet}
  ///
  /// The following code is exactly equivalent, and is typically clearer when
  /// the tweens are created inline, as might be preferred when the tweens have
  /// values that depend on other variables:
  ///
  /// ```dart
  /// Animation<Alignment> _alignment3 = _controller
  ///   .drive(CurveTween(curve: Curves.easeIn))
  ///   .drive(AlignmentTween(
  ///     begin: Alignment.topLeft,
  ///     end: Alignment.topRight,
  ///   ));
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [Animatable.animate], which does the same thing.
  ///  * [AnimationController], which is usually used to drive animations.
  ///  * [CurvedAnimation], an alternative to [CurveTween] for applying easing
  ///    curves, which supports distinct curves in the forward direction and the
  ///    reverse direction.
  @optionalTypeArgs
  Animation<U> drive<U>(Animatable<U> child) {
    assert(this is Animation<double>);
    return child.animate(this as Animation<double>);
  }

  @override
  String toString() {
    return '${describeIdentity(this)}(${toStringDetails()})';
  }

  /// Provides a string describing the status of this object, but not including
  /// information about the object itself.
  ///
  /// This function is used by [Animation.toString] so that [Animation]
  /// subclasses can provide additional details while ensuring all [Animation]
  /// subclasses have a consistent [toString] style.
  ///
  /// The result of this function includes an icon describing the status of this
  /// [Animation] object:
  ///
  /// * "&#x25B6;": [AnimationStatus.forward] ([value] increasing)
  /// * "&#x25C0;": [AnimationStatus.reverse] ([value] decreasing)
  /// * "&#x23ED;": [AnimationStatus.completed] ([value] == 1.0)
  /// * "&#x23EE;": [AnimationStatus.dismissed] ([value] == 0.0)
  String toStringDetails() {
    assert(status != null);
    switch (status) {
      case AnimationStatus.forward:
        return '\u25B6'; // >
      case AnimationStatus.reverse:
        return '\u25C0'; // <
      case AnimationStatus.completed:
        return '\u23ED'; // >>|
      case AnimationStatus.dismissed:
        return '\u23EE'; // |<<
    }
  }
}
