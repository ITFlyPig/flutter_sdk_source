/// 一个显示从[Scene]绘制的Flutter图层树的顶层平台窗口
/// A top-level platform window displaying a Flutter layer tree drawn from a
/// [Scene].
///
/// 应用程序的所有Flutter视图的当前列表可从`WidgetsBinding.instance.platformDispatcher.views`中获得。
/// 只有类型为[FlutterWindow]的视图才是顶层平台窗口。
///
/// 如果`WidgetsBinding`不可用，`dart:ui`中也有一个[PlatformDispatcher.instance]单例
/// 对象，但我们强烈建议避免静态引用它。请参阅[PlatformDispatcher.instance]的文档，了解为
/// 什么要避免使用它。
///
/// See also:
///
/// * [PlatformDispatcher]，它管理着当前的[FlutterView]（进而管理着[FlutterWindow]）实例列表。
class FlutterWindow extends FlutterView {
  FlutterWindow._(this._windowId, this.platformDispatcher);

  /// The opaque ID for this view.
  final Object _windowId;

  @override
  final PlatformDispatcher platformDispatcher;

  @override
  ViewConfiguration get viewConfiguration {
    assert(platformDispatcher._viewConfigurations.containsKey(_windowId));
    return platformDispatcher._viewConfigurations[_windowId]!;
  }
}
