///
/// 接收拖拽更新的接口。
///
/// 这个接口的使用方式多种多样。例如，[MultiDragGestureRecognizer]在识别手势时使用它来更
/// 新其客户端。同样，widgets库中的滚动基础设施使用它来通知[DragScrollActivity]，当用户
/// 拖动scrollable时。
///
abstract class Drag {
  /// The pointer has moved.
  void update(DragUpdateDetails details) {}

  /// The pointer is no longer in contact with the screen.
  ///
  /// The velocity at which the pointer was moving when it stopped contacting
  /// the screen is available in the `details`.
  void end(DragEndDetails details) {}

  /// The input from the pointer is no longer directed towards this receiver.
  ///
  /// For example, the user might have been interrupted by a system-modal dialog
  /// in the middle of the drag.
  void cancel() {}
}
