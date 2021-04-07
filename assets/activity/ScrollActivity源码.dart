///
/// 拖拽、甩动等滚动活动的基础类。
///
/// See also:
/// * [ScrollPosition]，它使用[ScrollActivity]对象来管理[Scrollable]的[ScrollPosition]。
///
abstract class ScrollActivity {
  /// Initializes [delegate] for subclasses.
  ScrollActivity(this._delegate);

  /// 该Activity将用于驱动scroll view的委托。
  ScrollActivityDelegate get delegate => _delegate;
  ScrollActivityDelegate _delegate;

  /// Updates the activity's link to the [ScrollActivityDelegate].
  ///
  /// This should only be called when an activity is being moved from a defunct
  /// (or about-to-be defunct) [ScrollActivityDelegate] object to a new one.
  void updateDelegate(ScrollActivityDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  /// Called by the [ScrollActivityDelegate] when it has changed type (for
  /// example, when changing from an Android-style scroll position to an
  /// iOS-style scroll position). If this activity can differ between the two
  /// modes, then it should tell the position to restart that activity
  /// appropriately.
  ///
  /// For example, [BallisticScrollActivity]'s implementation calls
  /// [ScrollActivityDelegate.goBallistic].
  void resetActivity() { }

  /// Dispatch a [ScrollStartNotification] with the given metrics.
  void dispatchScrollStartNotification(ScrollMetrics metrics, BuildContext? context) {
    ScrollStartNotification(metrics: metrics, context: context).dispatch(context);
  }

  /// Dispatch a [ScrollUpdateNotification] with the given metrics and scroll delta.
  void dispatchScrollUpdateNotification(ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    ScrollUpdateNotification(metrics: metrics, context: context, scrollDelta: scrollDelta).dispatch(context);
  }

  /// Dispatch an [OverscrollNotification] with the given metrics and overscroll.
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll).dispatch(context);
  }

  /// Dispatch a [ScrollEndNotification] with the given metrics and overscroll.
  void dispatchScrollEndNotification(ScrollMetrics metrics, BuildContext context) {
    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
  }

  /// Called when the scroll view that is performing this activity changes its metrics.
  void applyNewDimensions() { }

  /// Whether the scroll view should ignore pointer events while performing this
  /// activity.
  ///
  /// See also:
  ///
  ///  * [isScrolling], which describes whether the activity is considered
  ///    to represent user interaction or not.
  bool get shouldIgnorePointer;

  /// Whether performing this activity constitutes scrolling.
  ///
  /// Used, for example, to determine whether the user scroll
  /// direction (see [ScrollPosition.userScrollDirection]) is
  /// [ScrollDirection.idle].
  ///
  /// See also:
  ///
  ///  * [shouldIgnorePointer], which controls whether pointer events
  ///    are allowed while the activity is live.
  ///  * [UserScrollNotification], which exposes this status.
  bool get isScrolling;

  /// If applicable, the velocity at which the scroll offset is currently
  /// independently changing (i.e. without external stimuli such as a dragging
  /// gestures) in logical pixels per second for this activity.
  double get velocity;

  /// Called when the scroll view stops performing this activity.
  @mustCallSuper
  void dispose() { }

  @override
  String toString() => describeIdentity(this);
}
