import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'binding.dart';
// TODO(jacobr): make Ticker use Diagnosticable to simplify reporting errors
// related to a ticker.

/// 每一个动画帧都会调用它的回调一次
///
/// 创建后，一个ticker最初是禁用了，调用[start]来是它允许使用。
///
/// 可以通过将[muted]设置为ture来将[Ticker]设置为静默的。在静默期间，时间仍然在流逝，
/// [start] 和 [stop] 仍然可以调用，但是回调不会被调用而已。
///
/// 按照惯例，[start] 和 [stop]方法被ticker的消费者使用，[muted]属性被ticker的创建者[TickerProvider]控制。
///
/// [SchedulerBinding]驱动Ticker。可以查看[SchedulerBinding.scheduleFrameCallback]。
///
class Ticker {
  /// Creates a ticker that will call the provided callback once per frame while
  /// running.
  ///
  /// An optional label can be provided for debugging purposes. That label
  /// will appear in the [toString] output in debug builds.
  Ticker(this._onTick, {this.debugLabel}) {
    assert(() {
      _debugCreationStack = StackTrace.current;
      return true;
    }());
  }

  TickerFuture? _future;

  /// Whether this ticker has been silenced.
  ///
  /// While silenced, a ticker's clock can still run, but the callback will not
  /// be called.
  bool get muted => _muted;
  bool _muted = false;

  /// When set to true, silences the ticker, so that it is no longer ticking. If
  /// a tick is already scheduled, it will unschedule it. This will not
  /// unschedule the next frame, though.
  ///
  /// When set to false, unsilences the ticker, potentially scheduling a frame
  /// to handle the next tick.
  ///
  /// By convention, the [muted] property is controlled by the object that
  /// created the [Ticker] (typically a [TickerProvider]), not the object that
  /// listens to the ticker's ticks.
  set muted(bool value) {
    if (value == muted) return;
    _muted = value;
    if (value) {
      unscheduleTick();
    } else if (shouldScheduleTick) {
      scheduleTick();
    }
  }

  /// Whether this [Ticker] has scheduled a call to call its callback
  /// on the next frame.
  ///
  /// A ticker that is [muted] can be active (see [isActive]) yet not be
  /// ticking. In that case, the ticker will not call its callback, and
  /// [isTicking] will be false, but time will still be progressing.
  ///
  /// This will return false if the [SchedulerBinding.lifecycleState] is one
  /// that indicates the application is not currently visible (e.g. if the
  /// device's screen is turned off).
  bool get isTicking {
    if (_future == null) return false;
    if (muted) return false;
    if (SchedulerBinding.instance!.framesEnabled) return true;
    if (SchedulerBinding.instance!.schedulerPhase != SchedulerPhase.idle)
      return true; // for example, we might be in a warm-up frame or forced frame
    return false;
  }

  /// Whether time is elapsing for this [Ticker]. Becomes true when [start] is
  /// called and false when [stop] is called.
  ///
  /// A ticker can be active yet not be actually ticking (i.e. not be calling
  /// the callback). To determine if a ticker is actually ticking, use
  /// [isTicking].
  bool get isActive => _future != null;

  Duration? _startTime;

  /// Starts the clock for this [Ticker]. If the ticker is not [muted], then this
  /// also starts calling the ticker's callback once per animation frame.
  ///
  /// The returned future resolves once the ticker [stop]s ticking. If the
  /// ticker is disposed, the future does not resolve. A derivative future is
  /// available from the returned [TickerFuture] object that resolves with an
  /// error in that case, via [TickerFuture.orCancel].
  ///
  /// Calling this sets [isActive] to true.
  ///
  /// This method cannot be called while the ticker is active. To restart the
  /// ticker, first [stop] it.
  ///
  /// By convention, this method is used by the object that receives the ticks
  /// (as opposed to the [TickerProvider] which created the ticker).
  TickerFuture start() {
    _future = TickerFuture._();
    if (shouldScheduleTick) {
      scheduleTick();
    }
    if (SchedulerBinding.instance!.schedulerPhase.index >
            SchedulerPhase.idle.index &&
        SchedulerBinding.instance!.schedulerPhase.index <
            SchedulerPhase.postFrameCallbacks.index)
      _startTime = SchedulerBinding.instance!.currentFrameTimeStamp;
    return _future!;
  }

  /// Adds a debug representation of a [Ticker] optimized for including in error
  /// messages.
  DiagnosticsNode describeForError(String name) {
    // TODO(jacobr): make this more structured.
    return DiagnosticsProperty<Ticker>(name, this,
        description: toString(debugIncludeStack: true));
  }

  /// Stops calling this [Ticker]'s callback.
  ///
  /// If called with the `canceled` argument set to false (the default), causes
  /// the future returned by [start] to resolve. If called with the `canceled`
  /// argument set to true, the future does not resolve, and the future obtained
  /// from [TickerFuture.orCancel], if any, resolves with a [TickerCanceled]
  /// error.
  ///
  /// Calling this sets [isActive] to false.
  ///
  /// This method does nothing if called when the ticker is inactive.
  ///
  /// By convention, this method is used by the object that receives the ticks
  /// (as opposed to the [TickerProvider] which created the ticker).
  void stop({bool canceled = false}) {
    if (!isActive) return;

    // We take the _future into a local variable so that isTicking is false
    // when we actually complete the future (isTicking uses _future to
    // determine its state).
    final TickerFuture localFuture = _future!;
    _future = null;
    _startTime = null;
    assert(!isActive);

    unscheduleTick();
    if (canceled) {
      localFuture._cancel(this);
    } else {
      localFuture._complete();
    }
  }

  final TickerCallback _onTick;

  int? _animationId;

  /// Whether this [Ticker] has already scheduled a frame callback.
  @protected
  bool get scheduled => _animationId != null;

  /// Whether a tick should be scheduled.
  ///
  /// If this is true, then calling [scheduleTick] should succeed.
  ///
  /// Reasons why a tick should not be scheduled include:
  ///
  /// * A tick has already been scheduled for the coming frame.
  /// * The ticker is not active ([start] has not been called).
  /// * The ticker is not ticking, e.g. because it is [muted] (see [isTicking]).
  @protected
  bool get shouldScheduleTick => !muted && isActive && !scheduled;

  void _tick(Duration timeStamp) {
    _animationId = null;

    _startTime ??= timeStamp;
    // 调用回调
    _onTick(timeStamp - _startTime!);

    // The onTick callback may have scheduled another tick already, for
    // example by calling stop then start again.
    if (shouldScheduleTick) scheduleTick(rescheduling: true);
  }

  /// 规划一个下一帧的tick
  ///
  /// Schedules a tick for the next frame.
  ///
  /// This should only be called if [shouldScheduleTick] is true.
  @protected
  void scheduleTick({bool rescheduling = false}) {
    _animationId = SchedulerBinding.instance!
        .scheduleFrameCallback(_tick, rescheduling: rescheduling);
  }

  /// Cancels the frame callback that was requested by [scheduleTick], if any.
  ///
  /// Calling this method when no tick is [scheduled] is harmless.
  ///
  /// This method should not be called when [shouldScheduleTick] would return
  /// true if no tick was scheduled.
  @protected
  void unscheduleTick() {
    if (scheduled) {
      SchedulerBinding.instance!.cancelFrameCallbackWithId(_animationId!);
      _animationId = null;
    }
    assert(!shouldScheduleTick);
  }

  /// Makes this [Ticker] take the state of another ticker, and disposes the
  /// other ticker.
  ///
  /// This is useful if an object with a [Ticker] is given a new
  /// [TickerProvider] but needs to maintain continuity. In particular, this
  /// maintains the identity of the [TickerFuture] returned by the [start]
  /// function of the original [Ticker] if the original ticker is active.
  ///
  /// This ticker must not be active when this method is called.
  void absorbTicker(Ticker originalTicker) {
    assert(!isActive);
    assert(_future == null);
    assert(_startTime == null);
    assert(_animationId == null);
    assert(
        (originalTicker._future == null) == (originalTicker._startTime == null),
        'Cannot absorb Ticker after it has been disposed.');
    if (originalTicker._future != null) {
      _future = originalTicker._future;
      _startTime = originalTicker._startTime;
      if (shouldScheduleTick) scheduleTick();
      originalTicker._future =
          null; // so that it doesn't get disposed when we dispose of originalTicker
      originalTicker.unscheduleTick();
    }
    originalTicker.dispose();
  }

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  ///
  /// It is legal to call this method while [isActive] is true, in which case:
  ///
  ///  * The frame callback that was requested by [scheduleTick], if any, is
  ///    canceled.
  ///  * The future that was returned by [start] does not resolve.
  ///  * The future obtained from [TickerFuture.orCancel], if any, resolves
  ///    with a [TickerCanceled] error.
  @mustCallSuper
  void dispose() {
    if (_future != null) {
      final TickerFuture localFuture = _future!;
      _future = null;
      assert(!isActive);
      unscheduleTick();
      localFuture._cancel(this);
    }
    assert(() {
      // We intentionally don't null out _startTime. This means that if start()
      // was ever called, the object is now in a bogus state. This weakly helps
      // catch cases of use-after-dispose.
      _startTime = Duration.zero;
      return true;
    }());
  }

  /// An optional label can be provided for debugging purposes.
  ///
  /// This label will appear in the [toString] output in debug builds.
  final String? debugLabel;
  late StackTrace _debugCreationStack;

  @override
  String toString({bool debugIncludeStack = false}) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('${objectRuntimeType(this, 'Ticker')}(');
    assert(() {
      buffer.write(debugLabel ?? '');
      return true;
    }());
    buffer.write(')');
    assert(() {
      if (debugIncludeStack) {
        buffer.writeln();
        buffer.writeln(
            'The stack trace when the $runtimeType was actually created was:');
        FlutterError.defaultStackFilter(
                _debugCreationStack.toString().trimRight().split('\n'))
            .forEach(buffer.writeln);
      }
      return true;
    }());
    return buffer.toString();
  }
}
