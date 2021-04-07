///
/// 当用户在屏幕上拖动手指时，滚动scroll view。
///
/// See also:
/// * [DragScrollActivity]，这是scroll view在拖动过程中执行的活动。
///
class ScrollDragController implements Drag {
  /// Creates an object that scrolls a scroll view as the user drags their
  /// finger across the screen.
  ///
  /// The [delegate] and `details` arguments must not be null.
  ScrollDragController({
    required ScrollActivityDelegate delegate,
    required DragStartDetails details,
    this.onDragCanceled,
    this.carriedVelocity,
    this.motionStartDistanceThreshold,
  }) :
        _delegate = delegate,
        _lastDetails = details,
        _retainMomentum = carriedVelocity != null && carriedVelocity != 0.0,
        _lastNonStationaryTimestamp = details.sourceTimeStamp,
        _offsetSinceLastStop = motionStartDistanceThreshold == null ? null : 0.0;

  /// The object that will actuate the scroll view as the user drags.
  ScrollActivityDelegate get delegate => _delegate;
  ScrollActivityDelegate _delegate;

  /// Called when [dispose] is called.
  final VoidCallback? onDragCanceled;

  /// Velocity that was present from a previous [ScrollActivity] when this drag
  /// began.
  final double? carriedVelocity;

  /// Amount of pixels in either direction the drag has to move by to start
  /// scroll movement again after each time scrolling came to a stop.
  final double? motionStartDistanceThreshold;

  Duration? _lastNonStationaryTimestamp;
  bool _retainMomentum;
  /// Null if already in motion or has no [motionStartDistanceThreshold].
  double? _offsetSinceLastStop;

  /// Maximum amount of time interval the drag can have consecutive stationary
  /// pointer update events before losing the momentum carried from a previous
  /// scroll activity.
  static const Duration momentumRetainStationaryDurationThreshold =
  Duration(milliseconds: 20);

  /// Maximum amount of time interval the drag can have consecutive stationary
  /// pointer update events before needing to break the
  /// [motionStartDistanceThreshold] to start motion again.
  static const Duration motionStoppedDurationThreshold =
  Duration(milliseconds: 50);

  /// The drag distance past which, a [motionStartDistanceThreshold] breaking
  /// drag is considered a deliberate fling.
  static const double _bigThresholdBreakDistance = 24.0;

  bool get _reversed => axisDirectionIsReversed(delegate.axisDirection);

  /// Updates the controller's link to the [ScrollActivityDelegate].
  ///
  /// This should only be called when a controller is being moved from a defunct
  /// (or about-to-be defunct) [ScrollActivityDelegate] object to a new one.
  void updateDelegate(ScrollActivityDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  /// Determines whether to lose the existing incoming velocity when starting
  /// the drag.
  void _maybeLoseMomentum(double offset, Duration? timestamp) {
    if (_retainMomentum &&
        offset == 0.0 &&
        (timestamp == null || // If drag event has no timestamp, we lose momentum.
            timestamp - _lastNonStationaryTimestamp! > momentumRetainStationaryDurationThreshold)) {
      // If pointer is stationary for too long, we lose momentum.
      _retainMomentum = false;
    }
  }

  /// If a motion start threshold exists, determine whether the threshold needs
  /// to be broken to scroll. Also possibly apply an offset adjustment when
  /// threshold is first broken.
  ///
  /// Returns `0.0` when stationary or within threshold. Returns `offset`
  /// transparently when already in motion.
  double _adjustForScrollStartThreshold(double offset, Duration? timestamp) {
    if (timestamp == null) {
      // If we can't track time, we can't apply thresholds.
      // May be null for proxied drags like via accessibility.
      return offset;
    }
    if (offset == 0.0) {
      if (motionStartDistanceThreshold != null &&
          _offsetSinceLastStop == null &&
          timestamp - _lastNonStationaryTimestamp! > motionStoppedDurationThreshold) {
        // Enforce a new threshold.
        _offsetSinceLastStop = 0.0;
      }
      // Not moving can't break threshold.
      return 0.0;
    } else {
      if (_offsetSinceLastStop == null) {
        // Already in motion or no threshold behavior configured such as for
        // Android. Allow transparent offset transmission.
        return offset;
      } else {
        _offsetSinceLastStop = _offsetSinceLastStop! + offset;
        if (_offsetSinceLastStop!.abs() > motionStartDistanceThreshold!) {
          // Threshold broken.
          _offsetSinceLastStop = null;
          if (offset.abs() > _bigThresholdBreakDistance) {
            // This is heuristically a very deliberate fling. Leave the motion
            // unaffected.
            return offset;
          } else {
            // This is a normal speed threshold break.
            return math.min(
              // Ease into the motion when the threshold is initially broken
              // to avoid a visible jump.
              motionStartDistanceThreshold! / 3.0,
              offset.abs(),
            ) * offset.sign;
          }
        } else {
          return 0.0;
        }
      }
    }
  }

  @override
  void update(DragUpdateDetails details) {
    _lastDetails = details;
    double offset = details.primaryDelta!;
    if (offset != 0.0) {
      _lastNonStationaryTimestamp = details.sourceTimeStamp;
    }
    // 默认情况下，iOS平台带有动量，并有启动阈值（在[BouncingScrollPhysics]中配置）。下面
    // 2个操作在Android上是没有操作的。
    _maybeLoseMomentum(offset, details.sourceTimeStamp);
    offset = _adjustForScrollStartThreshold(offset, details.sourceTimeStamp);
    if (offset == 0.0) {
      return;
    }
    if (_reversed) // e.g. an AxisDirection.up scrollable
      offset = -offset;

    delegate.applyUserOffset(offset);
  }

  @override
  void end(DragEndDetails details) {
    assert(details.primaryVelocity != null);
    // We negate the velocity here because if the touch is moving downwards,
    // the scroll has to move upwards. It's the same reason that update()
    // above negates the delta before applying it to the scroll offset.
    double velocity = -details.primaryVelocity!;
    if (_reversed) // e.g. an AxisDirection.up scrollable
      velocity = -velocity;
    _lastDetails = details;

    // Build momentum only if dragging in the same direction.
    if (_retainMomentum && velocity.sign == carriedVelocity!.sign)
      velocity += carriedVelocity!;
    delegate.goBallistic(velocity);
  }

  @override
  void cancel() {
    delegate.goBallistic(0.0);
  }

  /// Called by the delegate when it is no longer sending events to this object.
  @mustCallSuper
  void dispose() {
    _lastDetails = null;
    if (onDragCanceled != null)
      onDragCanceled!();
  }

  /// The most recently observed [DragStartDetails], [DragUpdateDetails], or
  /// [DragEndDetails] object.
  dynamic get lastDetails => _lastDetails;
  dynamic _lastDetails;

  @override
  String toString() => describeIdentity(this);
}
