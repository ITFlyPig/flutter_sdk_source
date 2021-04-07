/// 当用户在屏幕上拖动手指时，scroll view执行的活动（activity）。
///
/// See also:
/// * [ScrollDragController]，它监听[Drag]并实际滚scroll view。
///
///
class DragScrollActivity extends ScrollActivity {
  /// Creates an activity for when the user drags their finger across the
  /// screen.
  DragScrollActivity(
      ScrollActivityDelegate delegate,
      ScrollDragController controller,
      ) : _controller = controller,
        super(delegate);

  ScrollDragController? _controller;

  @override
  void dispatchScrollStartNotification(ScrollMetrics metrics, BuildContext? context) {
    final dynamic lastDetails = _controller!.lastDetails;
    ScrollStartNotification(metrics: metrics, context: context, dragDetails: lastDetails as DragStartDetails).dispatch(context);
  }

  @override
  void dispatchScrollUpdateNotification(ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    final dynamic lastDetails = _controller!.lastDetails;
    ScrollUpdateNotification(metrics: metrics, context: context, scrollDelta: scrollDelta, dragDetails: lastDetails as DragUpdateDetails).dispatch(context);
  }

  @override
  void dispatchOverscrollNotification(ScrollMetrics metrics, BuildContext context, double overscroll) {
    final dynamic lastDetails = _controller!.lastDetails;
    OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll, dragDetails: lastDetails as DragUpdateDetails).dispatch(context);
  }

  @override
  void dispatchScrollEndNotification(ScrollMetrics metrics, BuildContext context) {
    // We might not have DragEndDetails yet if we're being called from beginActivity.
    final dynamic lastDetails = _controller!.lastDetails;
    ScrollEndNotification(
      metrics: metrics,
      context: context,
      dragDetails: lastDetails is DragEndDetails ? lastDetails : null,
    ).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  // DragScrollActivity is not independently changing velocity yet
  // until the drag is ended.
  @override
  double get velocity => 0.0;

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($_controller)';
  }
}
