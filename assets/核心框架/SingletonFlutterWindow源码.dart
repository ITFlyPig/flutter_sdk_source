/// 一个[FlutterWindow]，包括设置回调和检索驻留在[PlatformDispatcher]上的属性的访问。
//
//  它是只有一个主窗口的应用程序所使用的全局单例[window]。
//
//  除了[FlutterView]的属性外，这个类还提供了对平台特定属性的访问。要修改或检索这些属性，有
//  多个主窗口的应用程序应该优先使用`WidgetsBinding.instance.platformDispatcher`代替。
//
//  最好通过`WidgetsBinding.instance.window`或`WidgetsBinding.instance.platformDispatcher`
//  进行访问，而不是静态引用到[window]或[PlatformDispatcher.instance]。关于这一建议的更多细节，
//  请参见[PlatformDispatcher.instance]的文档。
class SingletonFlutterWindow extends FlutterWindow {
  SingletonFlutterWindow._(
      Object windowId, PlatformDispatcher platformDispatcher)
      : super._(windowId, platformDispatcher);

  /// A callback that is invoked whenever the [devicePixelRatio],
  /// [physicalSize], [padding], [viewInsets], [PlatformDispatcher.views], or
  /// [systemGestureInsets] values change.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// See [PlatformDispatcher.onMetricsChanged] for more information.
  VoidCallback? get onMetricsChanged => platformDispatcher.onMetricsChanged;
  set onMetricsChanged(VoidCallback? callback) {
    platformDispatcher.onMetricsChanged = callback;
  }

  /// The system-reported default locale of the device.
  ///
  /// {@template dart.ui.window.accessorForwardWarning}
  /// Accessing this value returns the value contained in the
  /// [PlatformDispatcher] singleton, so instead of getting it from here, you
  /// should consider getting it from `WidgetsBinding.instance.platformDispatcher` instead
  /// (or, when `WidgetsBinding` isn't available, from
  /// [PlatformDispatcher.instance]). The reason this value forwards to the
  /// [PlatformDispatcher] is to provide convenience for applications that only
  /// use a single main window.
  /// {@endtemplate}
  ///
  /// This establishes the language and formatting conventions that window
  /// should, if possible, use to render their user interface.
  ///
  /// This is the first locale selected by the user and is the user's primary
  /// locale (the locale the device UI is displayed in)
  ///
  /// This is equivalent to `locales.first` and will provide an empty non-null
  /// locale if the [locales] list has not been set or is empty.
  Locale get locale => platformDispatcher.locale;

  /// The full system-reported supported locales of the device.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This establishes the language and formatting conventions that window
  /// should, if possible, use to render their user interface.
  ///
  /// The list is ordered in order of priority, with lower-indexed locales being
  /// preferred over higher-indexed ones. The first element is the primary [locale].
  ///
  /// The [onLocaleChanged] callback is called whenever this value changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  List<Locale> get locales => platformDispatcher.locales;

  /// Performs the platform-native locale resolution.
  ///
  /// Each platform may return different results.
  ///
  /// If the platform fails to resolve a locale, then this will return null.
  ///
  /// This method returns synchronously and is a direct call to
  /// platform specific APIs without invoking method channels.
  Locale? computePlatformResolvedLocale(List<Locale> supportedLocales) {
    return platformDispatcher.computePlatformResolvedLocale(supportedLocales);
  }

  /// A callback that is invoked whenever [locale] changes value.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onLocaleChanged => platformDispatcher.onLocaleChanged;
  set onLocaleChanged(VoidCallback? callback) {
    platformDispatcher.onLocaleChanged = callback;
  }

  /// The lifecycle state immediately after dart isolate initialization.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This property will not be updated as the lifecycle changes.
  ///
  /// It is used to initialize [SchedulerBinding.lifecycleState] at startup
  /// with any buffered lifecycle state events.
  String get initialLifecycleState => platformDispatcher.initialLifecycleState;

  /// The system-reported text scale.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This establishes the text scaling factor to use when rendering text,
  /// according to the user's platform preferences.
  ///
  /// The [onTextScaleFactorChanged] callback is called whenever this value
  /// changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  double get textScaleFactor => platformDispatcher.textScaleFactor;

  /// The setting indicating whether time should always be shown in the 24-hour
  /// format.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This option is used by [showTimePicker].
  bool get alwaysUse24HourFormat => platformDispatcher.alwaysUse24HourFormat;

  /// A callback that is invoked whenever [textScaleFactor] changes value.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onTextScaleFactorChanged =>
      platformDispatcher.onTextScaleFactorChanged;
  set onTextScaleFactorChanged(VoidCallback? callback) {
    platformDispatcher.onTextScaleFactorChanged = callback;
  }

  /// The setting indicating the current brightness mode of the host platform.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// If the platform has no preference, [platformBrightness] defaults to
  /// [Brightness.light].
  Brightness get platformBrightness => platformDispatcher.platformBrightness;

  /// A callback that is invoked whenever [platformBrightness] changes value.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onPlatformBrightnessChanged =>
      platformDispatcher.onPlatformBrightnessChanged;
  set onPlatformBrightnessChanged(VoidCallback? callback) {
    platformDispatcher.onPlatformBrightnessChanged = callback;
  }

  /// A callback that is invoked to notify the window that it is an appropriate
  /// time to provide a scene using the [SceneBuilder] API and the [render]
  /// method.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// When possible, this is driven by the hardware VSync signal. This is only
  /// called if [scheduleFrame] has been called since the last time this
  /// callback was invoked.
  ///
  /// The [onDrawFrame] callback is invoked immediately after [onBeginFrame],
  /// after draining any microtasks (e.g. completions of any [Future]s) queued
  /// by the [onBeginFrame] handler.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  FrameCallback? get onBeginFrame => platformDispatcher.onBeginFrame;
  set onBeginFrame(FrameCallback? callback) {
    platformDispatcher.onBeginFrame = callback;
  }

  /// A callback that is invoked for each frame after [onBeginFrame] has
  /// completed and after the microtask queue has been drained.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This can be used to implement a second phase of frame rendering that
  /// happens after any deferred work queued by the [onBeginFrame] phase.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  VoidCallback? get onDrawFrame => platformDispatcher.onDrawFrame;
  set onDrawFrame(VoidCallback? callback) {
    platformDispatcher.onDrawFrame = callback;
  }

  /// A callback that is invoked to report the [FrameTiming] of recently
  /// rasterized frames.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// It's prefered to use [SchedulerBinding.addTimingsCallback] than to use
  /// [SingletonFlutterWindow.onReportTimings] directly because
  /// [SchedulerBinding.addTimingsCallback] allows multiple callbacks.
  ///
  /// This can be used to see if the window has missed frames (through
  /// [FrameTiming.buildDuration] and [FrameTiming.rasterDuration]), or high
  /// latencies (through [FrameTiming.totalSpan]).
  ///
  /// Unlike [Timeline], the timing information here is available in the release
  /// mode (additional to the profile and the debug mode). Hence this can be
  /// used to monitor the application's performance in the wild.
  ///
  /// {@macro dart.ui.TimingsCallback.list}
  ///
  /// If this is null, no additional work will be done. If this is not null,
  /// Flutter spends less than 0.1ms every 1 second to report the timings
  /// (measured on iPhone6S). The 0.1ms is about 0.6% of 16ms (frame budget for
  /// 60fps), or 0.01% CPU usage per second.
  TimingsCallback? get onReportTimings => platformDispatcher.onReportTimings;
  set onReportTimings(TimingsCallback? callback) {
    platformDispatcher.onReportTimings = callback;
  }

  /// A callback that is invoked when pointer data is available.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [GestureBinding], the Flutter framework class which manages pointer
  ///    events.
  PointerDataPacketCallback? get onPointerDataPacket =>
      platformDispatcher.onPointerDataPacket;
  set onPointerDataPacket(PointerDataPacketCallback? callback) {
    platformDispatcher.onPointerDataPacket = callback;
  }

  /// The route or path that the embedder requested when the application was
  /// launched.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This will be the string "`/`" if no particular route was requested.
  ///
  /// ## Android
  ///
  /// On Android, the initial route can be set on the [initialRoute](/javadoc/io/flutter/embedding/android/FlutterActivity.NewEngineIntentBuilder.html#initialRoute-java.lang.String-)
  /// method of the [FlutterActivity](/javadoc/io/flutter/embedding/android/FlutterActivity.html)'s
  /// intent builder.
  ///
  /// On a standalone engine, see https://flutter.dev/docs/development/add-to-app/android/add-flutter-screen#initial-route-with-a-cached-engine.
  ///
  /// ## iOS
  ///
  /// On iOS, the initial route can be set on the `initialRoute`
  /// parameter of the [FlutterViewController](/objcdoc/Classes/FlutterViewController.html)'s
  /// initializer.
  ///
  /// On a standalone engine, see https://flutter.dev/docs/development/add-to-app/ios/add-flutter-screen#route.
  ///
  /// See also:
  ///
  ///  * [Navigator], a widget that handles routing.
  ///  * [SystemChannels.navigation], which handles subsequent navigation
  ///    requests from the embedder.
  String get defaultRouteName => platformDispatcher.defaultRouteName;

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame] and
  /// [onDrawFrame] callbacks be invoked.
  ///
  /// {@template dart.ui.window.functionForwardWarning}
  /// Calling this function forwards the call to the same function on the
  /// [PlatformDispatcher] singleton, so instead of calling it here, you should
  /// consider calling it on `WidgetsBinding.instance.platformDispatcher` instead (or, when
  /// `WidgetsBinding` isn't available, on [PlatformDispatcher.instance]). The
  /// reason this function forwards to the [PlatformDispatcher] is to provide
  /// convenience for applications that only use a single main window.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  /// * [SchedulerBinding], the Flutter framework class which manages the
  ///   scheduling of frames.
  void scheduleFrame() => platformDispatcher.scheduleFrame();

  /// Whether the user has requested that [updateSemantics] be called when
  /// the semantic contents of window changes.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The [onSemanticsEnabledChanged] callback is called whenever this value
  /// changes.
  bool get semanticsEnabled => platformDispatcher.semanticsEnabled;

  /// A callback that is invoked when the value of [semanticsEnabled] changes.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get onSemanticsEnabledChanged =>
      platformDispatcher.onSemanticsEnabledChanged;
  set onSemanticsEnabledChanged(VoidCallback? callback) {
    platformDispatcher.onSemanticsEnabledChanged = callback;
  }

  /// A callback that is invoked whenever the user requests an action to be
  /// performed.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// This callback is used when the user expresses the action they wish to
  /// perform based on the semantics supplied by [updateSemantics].
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  SemanticsActionCallback? get onSemanticsAction =>
      platformDispatcher.onSemanticsAction;
  set onSemanticsAction(SemanticsActionCallback? callback) {
    platformDispatcher.onSemanticsAction = callback;
  }

  /// Additional accessibility features that may be enabled by the platform.
  AccessibilityFeatures get accessibilityFeatures =>
      platformDispatcher.accessibilityFeatures;

  /// A callback that is invoked when the value of [accessibilityFeatures] changes.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get onAccessibilityFeaturesChanged =>
      platformDispatcher.onAccessibilityFeaturesChanged;
  set onAccessibilityFeaturesChanged(VoidCallback? callback) {
    platformDispatcher.onAccessibilityFeaturesChanged = callback;
  }

  /// Change the retained semantics data about this window.
  ///
  /// {@macro dart.ui.window.functionForwardWarning}
  ///
  /// If [semanticsEnabled] is true, the user has requested that this function
  /// be called whenever the semantic content of this window changes.
  ///
  /// In either case, this function disposes the given update, which means the
  /// semantics update cannot be used further.
  void updateSemantics(SemanticsUpdate update) =>
      platformDispatcher.updateSemantics(update);

  /// Sends a message to a platform-specific plugin.
  ///
  /// {@macro dart.ui.window.functionForwardWarning}
  ///
  /// The `name` parameter determines which plugin receives the message. The
  /// `data` parameter contains the message payload and is typically UTF-8
  /// encoded JSON but can be arbitrary data. If the plugin replies to the
  /// message, `callback` will be called with the response.
  ///
  /// The framework invokes [callback] in the same zone in which this method
  /// was called.
  void sendPlatformMessage(
      String name, ByteData? data, PlatformMessageResponseCallback? callback) {
    platformDispatcher.sendPlatformMessage(name, data, callback);
  }

  /// Called whenever this window receives a message from a platform-specific
  /// plugin.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// The `name` parameter determines which plugin sent the message. The `data`
  /// parameter is the payload and is typically UTF-8 encoded JSON but can be
  /// arbitrary data.
  ///
  /// Message handlers must call the function given in the `callback` parameter.
  /// If the handler does not need to respond, the handler should pass null to
  /// the callback.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  // TODO(ianh): deprecate once framework uses [ChannelBuffers.setListener].
  PlatformMessageCallback? get onPlatformMessage =>
      platformDispatcher.onPlatformMessage;
  set onPlatformMessage(PlatformMessageCallback? callback) {
    platformDispatcher.onPlatformMessage = callback;
  }

  /// Set the debug name associated with this platform dispatcher's root
  /// isolate.
  ///
  /// {@macro dart.ui.window.accessorForwardWarning}
  ///
  /// Normally debug names are automatically generated from the Dart port, entry
  /// point, and source file. For example: `main.dart$main-1234`.
  ///
  /// This can be combined with flutter tools `--isolate-filter` flag to debug
  /// specific root isolates. For example: `flutter attach --isolate-filter=[name]`.
  /// Note that this does not rename any child isolates of the root.
  void setIsolateDebugName(String name) =>
      PlatformDispatcher.instance.setIsolateDebugName(name);
}
