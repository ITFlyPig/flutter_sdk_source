import 'package:flutter/gestures.dart';

abstract class PrimaryPointerGestureRecognizer
    extends OneSequenceGestureRecognizer {
  /// Initializes the [deadline] field during construction of subclasses.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.kind}
  PrimaryPointerGestureRecognizer({
    this.deadline,
    this.preAcceptSlopTolerance = kTouchSlop,
    this.postAcceptSlopTolerance = kTouchSlop,
    Object? debugOwner,
    PointerDeviceKind? kind,
  })  : assert(
          preAcceptSlopTolerance == null || preAcceptSlopTolerance >= 0,
          'The preAcceptSlopTolerance must be positive or null',
        ),
        assert(
          postAcceptSlopTolerance == null || postAcceptSlopTolerance >= 0,
          'The postAcceptSlopTolerance must be positive or null',
        ),
        super(debugOwner: debugOwner, kind: kind);

  /// If non-null, the recognizer will call [didExceedDeadline] after this
  /// amount of time has elapsed since starting to track the primary pointer.
  ///
  /// The [didExceedDeadline] will not be called if the primary pointer is
  /// accepted, rejected, or all pointers are up or canceled before [deadline].
  final Duration? deadline;

  /// The maximum distance in logical pixels the gesture is allowed to drift
  /// from the initial touch down position before the gesture is accepted.
  ///
  /// Drifting past the allowed slop amount causes the gesture to be rejected.
  ///
  /// Can be null to indicate that the gesture can drift for any distance.
  /// Defaults to 18 logical pixels.
  final double? preAcceptSlopTolerance;

  /// The maximum distance in logical pixels the gesture is allowed to drift
  /// after the gesture has been accepted.
  ///
  /// Drifting past the allowed slop amount causes the gesture to stop tracking
  /// and signaling subsequent callbacks.
  ///
  /// Can be null to indicate that the gesture can drift for any distance.
  /// Defaults to 18 logical pixels.
  final double? postAcceptSlopTolerance;

  /// The current state of the recognizer.
  ///
  /// See [GestureRecognizerState] for a description of the states.
  GestureRecognizerState state = GestureRecognizerState.ready;

  /// The ID of the primary pointer this recognizer is tracking.
  int? primaryPointer;

  /// The location at which the primary pointer contacted the screen.
  OffsetPair? initialPosition;

  // Whether this pointer is accepted by winning the arena or as defined by
  // a subclass calling acceptGesture.
  bool _gestureAccepted = false;
  Timer? _timer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    if (state == GestureRecognizerState.ready) {
      state = GestureRecognizerState.possible;
      primaryPointer = event.pointer;
      initialPosition =
          OffsetPair(local: event.localPosition, global: event.position);
      if (deadline != null)
        _timer = Timer(deadline!, () => didExceedDeadlineWithEvent(event));
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    // ???????????????????????????????????????event
    if (state == GestureRecognizerState.possible &&
        event.pointer == primaryPointer) {
      // ?????????????????????????????? ??? ???????????????down?????????????????????????????????????????????????????????
      final bool isPreAcceptSlopPastTolerance = !_gestureAccepted &&
          preAcceptSlopTolerance != null &&
          _getGlobalDistance(event) > preAcceptSlopTolerance!;
      // ??????????????????????????? ??? ???????????????down?????????????????????????????????????????????????????????
      final bool isPostAcceptSlopPastTolerance = _gestureAccepted &&
          postAcceptSlopTolerance != null &&
          _getGlobalDistance(event) > postAcceptSlopTolerance!;

      // ?????????move???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
      if (event is PointerMoveEvent &&
          (isPreAcceptSlopPastTolerance || isPostAcceptSlopPastTolerance)) {
        // ???????????????
        resolve(GestureDisposition.rejected);
        // ?????????????????????
        stopTrackingPointer(primaryPointer!);
      } else {
        // ??????down??????
        // or up??????
        // or ??????????????????move??????
        // ??????????????????
        handlePrimaryPointer(event);
      }
    }
    // ?????????up??????cancel????????????????????????
    stopTrackingIfPointerNoLongerDown(event);
  }

  /// Override to provide behavior for the primary pointer when the gesture is still possible.
  @protected
  void handlePrimaryPointer(PointerEvent event);

  /// Override to be notified when [deadline] is exceeded.
  ///
  /// You must override this method or [didExceedDeadlineWithEvent] if you
  /// supply a [deadline].
  @protected
  void didExceedDeadline() {
    assert(deadline == null);
  }

  /// Same as [didExceedDeadline] but receives the [event] that initiated the
  /// gesture.
  ///
  /// You must override this method or [didExceedDeadline] if you supply a
  /// [deadline].
  @protected
  void didExceedDeadlineWithEvent(PointerDownEvent event) {
    didExceedDeadline();
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer == primaryPointer) {
      _stopTimer();
      _gestureAccepted = true;
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == primaryPointer && state == GestureRecognizerState.possible) {
      _stopTimer();
      state = GestureRecognizerState.defunct;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    assert(state != GestureRecognizerState.ready);
    _stopTimer();
    state = GestureRecognizerState.ready;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  double _getGlobalDistance(PointerEvent event) {
    final Offset offset = event.position - initialPosition!.global;
    return offset.distance;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<GestureRecognizerState>('state', state));
  }
}
