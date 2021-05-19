/// [PrimaryPointerGestureRecognizer]识别器可能的状态
///
///
/// 当识别器开始跟踪主指针事件时，识别器将从[Ready(就绪)]前进到[Possible(可能)]。
/// 当主指针事件在手势竞技场中被解决时(接受或拒绝)，识别器前进到[defunct]。
/// 一旦识别器停止跟踪任何剩余的指针事件，识别器将返回到[ready]。
enum GestureRecognizerState {
  /// The recognizer is ready to start recognizing a gesture.
  ready,

  /// The sequence of pointer events seen thus far is consistent with the
  /// gesture the recognizer is attempting to recognize but the gesture has not
  /// been accepted definitively.
  possible,

  /// Further pointer events cannot cause this recognizer to recognize the
  /// gesture until the recognizer returns to the [ready] state (typically when
  /// all the pointers the recognizer is tracking are removed from the screen).
  defunct,
}
