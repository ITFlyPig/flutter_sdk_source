///
/// Flutter场景[Scene]会在该view中绘制
///
/// 每个[FlutterView]都有自己的图层树，每当用[Scene]调用[render]时，[FlutterView]就会被
/// 渲染到[FlutterWindow]内部的一个区域。
///
/// ## Insets and Padding
///
/// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/widgets/window_padding.mp4}
///
/// In this illustration, the black areas represent system UI that the app
/// cannot draw over. The red area represents view padding that the view may not
/// be able to detect gestures in and may not want to draw in. The grey area
/// represents the system keyboard, which can cover over the bottom view padding
/// when visible.
///
/// The [viewInsets] are the physical pixels which the operating
/// system reserves for system UI, such as the keyboard, which would fully
/// obscure any content drawn in that area.
///
/// The [viewPadding] are the physical pixels on each side of the
/// display that may be partially obscured by system UI or by physical
/// intrusions into the display, such as an overscan region on a television or a
/// "notch" on a phone. Unlike the insets, these areas may have portions that
/// show the user view-painted pixels without being obscured, such as a
/// notch at the top of a phone that covers only a subset of the area. Insets,
/// on the other hand, either partially or fully obscure the window, such as an
/// opaque keyboard or a partially translucent status bar, which cover an area
/// without gaps.
///
/// The [padding] property is computed from both
/// [viewInsets] and [viewPadding]. It will allow a
/// view inset to consume view padding where appropriate, such as when a phone's
/// keyboard is covering the bottom view padding and so "absorbs" it.
///
/// Clients that want to position elements relative to the view padding
/// regardless of the view insets should use the [viewPadding]
/// property, e.g. if you wish to draw a widget at the center of the screen with
/// respect to the iPhone "safe area" regardless of whether the keyboard is
/// showing.
///
/// [padding] is useful for clients that want to know how much
/// padding should be accounted for without concern for the current inset(s)
/// state, e.g. determining whether a gesture should be considered for scrolling
/// purposes. This value varies based on the current state of the insets. For
/// example, a visible keyboard will consume all gestures in the bottom part of
/// the [viewPadding] anyway, so there is no need to account for
/// that in the [padding], which is always safe to use for such
/// calculations.
///
/// See also:
///
///  * [FlutterWindow], a special case of a [FlutterView] that is represented on
///    the platform as a separate window which can host other [FlutterView]s.
abstract class FlutterView {
  /// The platform dispatcher that this view is registered with, and gets its
  /// information from.
  PlatformDispatcher get platformDispatcher;

  /// The configuration of this view.
  ViewConfiguration get viewConfiguration;

  /// The number of device pixels for each logical pixel for the screen this
  /// view is displayed on.
  ///
  /// This number might not be a power of two. Indeed, it might not even be an
  /// integer. For example, the Nexus 6 has a device pixel ratio of 3.5.
  ///
  /// Device pixels are also referred to as physical pixels. Logical pixels are
  /// also referred to as device-independent or resolution-independent pixels.
  ///
  /// By definition, there are roughly 38 logical pixels per centimeter, or
  /// about 96 logical pixels per inch, of the physical display. The value
  /// returned by [devicePixelRatio] is ultimately obtained either from the
  /// hardware itself, the device drivers, or a hard-coded value stored in the
  /// operating system or firmware, and may be inaccurate, sometimes by a
  /// significant margin.
  ///
  /// The Flutter framework operates in logical pixels, so it is rarely
  /// necessary to directly deal with this property.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  double get devicePixelRatio => viewConfiguration.devicePixelRatio;

  /// The dimensions and location of the rectangle into which the scene rendered
  /// in this view will be drawn on the screen, in physical pixels.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// At startup, the size and location of the view may not be known before Dart
  /// code runs. If this value is observed early in the application lifecycle,
  /// it may report [Rect.zero].
  ///
  /// This value does not take into account any on-screen keyboards or other
  /// system UI. The [padding] and [viewInsets] properties provide a view into
  /// how much of each side of the view may be obscured by system UI.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Rect get physicalGeometry => viewConfiguration.geometry;

  /// The dimensions of the rectangle into which the scene rendered in this view
  /// will be drawn on the screen, in physical pixels.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// At startup, the size of the view may not be known before Dart code runs.
  /// If this value is observed early in the application lifecycle, it may
  /// report [Size.zero].
  ///
  /// This value does not take into account any on-screen keyboards or other
  /// system UI. The [padding] and [viewInsets] properties provide information
  /// about how much of each side of the view may be obscured by system UI.
  ///
  /// This value is the same as the `size` member of [physicalGeometry].
  ///
  /// See also:
  ///
  ///  * [physicalGeometry], which reports the location of the view as well as
  ///    its size.
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Size get physicalSize => viewConfiguration.geometry.size;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but over which the operating system will likely
  /// place system UI, such as the keyboard, that fully obscures any content.
  ///
  /// When this property changes, [onMetricsChanged] is called.
  ///
  /// The relationship between this [viewInsets],
  /// [viewPadding], and [padding] are described in
  /// more detail in the documentation for [FlutterView].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the view insets in material
  ///    design applications.
  WindowPadding get viewInsets => viewConfiguration.viewInsets;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but which may be partially obscured by system
  /// UI (such as the system notification area), or or physical intrusions in
  /// the display (e.g. overscan regions on television screens or phone sensor
  /// housings).
  ///
  /// Unlike [padding], this value does not change relative to
  /// [viewInsets]. For example, on an iPhone X, it will not
  /// change in response to the soft keyboard being visible or hidden, whereas
  /// [padding] will.
  ///
  /// When this property changes, [onMetricsChanged] is called.
  ///
  /// The relationship between this [viewInsets],
  /// [viewPadding], and [padding] are described in
  /// more detail in the documentation for [FlutterView].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the padding in material design
  ///    applications.
  WindowPadding get viewPadding => viewConfiguration.viewPadding;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but where the operating system will consume
  /// input gestures for the sake of system navigation.
  ///
  /// For example, an operating system might use the vertical edges of the
  /// screen, where swiping inwards from the edges takes users backward
  /// through the history of screens they previously visited.
  ///
  /// When this property changes, [onMetricsChanged] is called.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  WindowPadding get systemGestureInsets => viewConfiguration.systemGestureInsets;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the view can render, but which may be partially obscured by system
  /// UI (such as the system notification area), or or physical intrusions in
  /// the display (e.g. overscan regions on television screens or phone sensor
  /// housings).
  ///
  /// This value is calculated by taking `max(0.0, FlutterView.viewPadding -
  /// FlutterView.viewInsets)`. This will treat a system IME that increases the
  /// bottom inset as consuming that much of the bottom padding. For example, on
  /// an iPhone X, [EdgeInsets.bottom] of [FlutterView.padding] is the same as
  /// [EdgeInsets.bottom] of [FlutterView.viewPadding] when the soft keyboard is
  /// not drawn (to account for the bottom soft button area), but will be `0.0`
  /// when the soft keyboard is visible.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// The relationship between this [viewInsets], [viewPadding], and [padding]
  /// are described in more detail in the documentation for [FlutterView].
  ///
  /// See also:
  ///
  /// * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///   observe when this value changes.
  /// * [MediaQuery.of], a simpler mechanism for the same.
  /// * [Scaffold], which automatically applies the padding in material design
  ///   applications.
  WindowPadding get padding => viewConfiguration.padding;

  /// Updates the view's rendering on the GPU with the newly provided [Scene].
  ///
  /// This function must be called within the scope of the
  /// [PlatformDispatcher.onBeginFrame] or [PlatformDispatcher.onDrawFrame]
  /// callbacks being invoked.
  ///
  /// If this function is called a second time during a single
  /// [PlatformDispatcher.onBeginFrame]/[PlatformDispatcher.onDrawFrame]
  /// callback sequence or called outside the scope of those callbacks, the call
  /// will be ignored.
  ///
  /// To record graphical operations, first create a [PictureRecorder], then
  /// construct a [Canvas], passing that [PictureRecorder] to its constructor.
  /// After issuing all the graphical operations, call the
  /// [PictureRecorder.endRecording] function on the [PictureRecorder] to obtain
  /// the final [Picture] that represents the issued graphical operations.
  ///
  /// Next, create a [SceneBuilder], and add the [Picture] to it using
  /// [SceneBuilder.addPicture]. With the [SceneBuilder.build] method you can
  /// then obtain a [Scene] object, which you can display to the user via this
  /// [render] function.
  ///
  /// See also:
  ///
  /// * [SchedulerBinding], the Flutter framework class which manages the
  ///   scheduling of frames.
  /// * [RendererBinding], the Flutter framework class which manages layout and
  ///   painting.
  void render(Scene scene) => _render(scene, this);
  void _render(Scene scene, FlutterView view) native 'PlatformConfiguration_render';
}