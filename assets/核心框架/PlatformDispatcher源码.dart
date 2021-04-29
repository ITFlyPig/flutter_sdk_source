///
/// 平台事件调度器单例
//
// 对宿主操作系统提供了最基本的接口
//
// 这是平台消息和平台配置事件的中心入口点
//
// 它暴露了核心调度器API、输入事件回调、图形绘制API以及其他此类核心服务。
//
// 它管理着应用的[views]和附着到设备的屏幕[screens] 列表，以及各种平台属性的配置[configuration] 。
//
// 考虑避免通过[PlatformDispatcher.instance]来静态引用这个单例，而更倾向于使用binding来
// 解决依赖关系，比如`WidgetsBinding.instance.platformDispatcher`。关于为什么要这样做的
// 更多信息，请参见[PlatformDispatcher.instance]。
///
class PlatformDispatcher {
  /// Private constructor, since only dart:ui is supposed to create one of
  /// these. Use [instance] to access the singleton.
  PlatformDispatcher._() {
    _setNeedsReportTimings = _nativeSetNeedsReportTimings;
  }

  /// The [PlatformDispatcher] singleton.
  ///
  /// Consider avoiding static references to this singleton though
  /// [PlatformDispatcher.instance] and instead prefer using a binding for
  /// dependency resolution such as `WidgetsBinding.instance.platformDispatcher`.
  ///
  /// Static access of this object means that Flutter has few, if any options to
  /// fake or mock the given object in tests. Even in cases where Dart offers
  /// special language constructs to forcefully shadow such properties, those
  /// mechanisms would only be reasonable for tests and they would not be
  /// reasonable for a future of Flutter where we legitimately want to select an
  /// appropriate implementation at runtime.
  ///
  /// The only place that `WidgetsBinding.instance.platformDispatcher` is
  /// inappropriate is if access to these APIs is required before the binding is
  /// initialized by invoking `runApp()` or
  /// `WidgetsFlutterBinding.instance.ensureInitialized()`. In that case, it is
  /// necessary (though unfortunate) to use the [PlatformDispatcher.instance]
  /// object statically.
  static PlatformDispatcher get instance => _instance;
  static final PlatformDispatcher _instance = PlatformDispatcher._();

  /// The current platform configuration.
  ///
  /// If values in this configuration change, [onPlatformConfigurationChanged]
  /// will be called.
  PlatformConfiguration get configuration => _configuration;
  PlatformConfiguration _configuration = const PlatformConfiguration();

  /// Called when the platform configuration changes.
  ///
  /// The engine invokes this callback in the same zone in which the callback
  /// was set.
  VoidCallback? get onPlatformConfigurationChanged => _onPlatformConfigurationChanged;
  VoidCallback? _onPlatformConfigurationChanged;
  Zone _onPlatformConfigurationChangedZone = Zone.root;
  set onPlatformConfigurationChanged(VoidCallback? callback) {
    _onPlatformConfigurationChanged = callback;
    _onPlatformConfigurationChangedZone = Zone.current;
  }

  /// 当前view的列表，包括顶层平台窗口（window）
  ///
  /// If any of their configurations change, [onMetricsChanged] will be called.
  Iterable<FlutterView> get views => _views.values;
  Map<Object, FlutterView> _views = <Object, FlutterView>{};

  // A map of opaque platform view identifiers to view configurations.
  Map<Object, ViewConfiguration> _viewConfigurations = <Object, ViewConfiguration>{};

  /// A callback that is invoked whenever the [ViewConfiguration] of any of the
  /// [views] changes.
  ///
  /// For example when the device is rotated or when the application is resized
  /// (e.g. when showing applications side-by-side on Android),
  /// `onMetricsChanged` is called.
  ///
  /// The engine invokes this callback in the same zone in which the callback
  /// was set.
  ///
  /// The framework registers with this callback and updates the layout
  /// appropriately.
  ///
  /// See also:
  ///
  /// * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///   register for notifications when this is called.
  /// * [MediaQuery.of], a simpler mechanism for the same.
  VoidCallback? get onMetricsChanged => _onMetricsChanged;
  VoidCallback? _onMetricsChanged;
  Zone _onMetricsChangedZone = Zone.root;
  set onMetricsChanged(VoidCallback? callback) {
    _onMetricsChanged = callback;
    _onMetricsChangedZone = Zone.current;
  }

  // 引擎调用的防范，通过hooks.dart实现调用
  //
  //据传入的id，更新窗口的指标
  // Updates the metrics of the window with the given id.
  void _updateWindowMetrics(
      Object id,
      double devicePixelRatio,
      double width,
      double height,
      double viewPaddingTop,
      double viewPaddingRight,
      double viewPaddingBottom,
      double viewPaddingLeft,
      double viewInsetTop,
      double viewInsetRight,
      double viewInsetBottom,
      double viewInsetLeft,
      double systemGestureInsetTop,
      double systemGestureInsetRight,
      double systemGestureInsetBottom,
      double systemGestureInsetLeft,
      ) {
    final ViewConfiguration previousConfiguration =
        _viewConfigurations[id] ?? const ViewConfiguration();
    if (!_views.containsKey(id)) {
      _views[id] = FlutterWindow._(id, this);
    }
    _viewConfigurations[id] = previousConfiguration.copyWith(
      window: _views[id],
      devicePixelRatio: devicePixelRatio,
      geometry: Rect.fromLTWH(0.0, 0.0, width, height),
      viewPadding: WindowPadding._(
        top: viewPaddingTop,
        right: viewPaddingRight,
        bottom: viewPaddingBottom,
        left: viewPaddingLeft,
      ),
      viewInsets: WindowPadding._(
        top: viewInsetTop,
        right: viewInsetRight,
        bottom: viewInsetBottom,
        left: viewInsetLeft,
      ),
      padding: WindowPadding._(
        top: math.max(0.0, viewPaddingTop - viewInsetTop),
        right: math.max(0.0, viewPaddingRight - viewInsetRight),
        bottom: math.max(0.0, viewPaddingBottom - viewInsetBottom),
        left: math.max(0.0, viewPaddingLeft - viewInsetLeft),
      ),
      systemGestureInsets: WindowPadding._(
        top: math.max(0.0, systemGestureInsetTop),
        right: math.max(0.0, systemGestureInsetRight),
        bottom: math.max(0.0, systemGestureInsetBottom),
        left: math.max(0.0, systemGestureInsetLeft),
      ),
    );
    _invoke(onMetricsChanged, _onMetricsChangedZone);
  }

  /// 当任何一个view开始一帧时，这个callback会被回调
  ///
  /// 一个回调，用来告诉应用程序，当前是使用[SceneBuilder] API和[FlutterView.render]方法
  /// 来提供一个场景(scene)的合适时间。
  ///
  /// A callback invoked when any view begins a frame.
  ///
  /// A callback that is invoked to notify the application that it is an
  /// appropriate time to provide a scene using the [SceneBuilder] API and the
  /// [FlutterView.render] method.
  ///
  /// When possible, this is driven by the hardware VSync signal of the attached
  /// screen with the highest VSync rate. This is only called if
  /// [PlatformDispatcher.scheduleFrame] has been called since the last time
  /// this callback was invoked.
  FrameCallback? get onBeginFrame => _onBeginFrame;
  FrameCallback? _onBeginFrame;
  Zone _onBeginFrameZone = Zone.root;
  set onBeginFrame(FrameCallback? callback) {
    _onBeginFrame = callback;
    _onBeginFrameZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _beginFrame(int microseconds) {
    _invoke1<Duration>(
      onBeginFrame,
      _onBeginFrameZone,
      Duration(microseconds: microseconds),
    );
  }

  /// 在[onBeginFrame]完成后和微任务队列清空后，为每个帧调用的回调
  ///
  /// 这可以用来实现帧渲染的第二阶段，该阶段发生在[onBeginFrame]阶段排队的任何延迟工作之后。
  ///
  ///
  /// A callback that is invoked for each frame after [onBeginFrame] has
  /// completed and after the microtask queue has been drained.
  ///
  /// This can be used to implement a second phase of frame rendering that
  /// happens after any deferred work queued by the [onBeginFrame] phase.
  VoidCallback? get onDrawFrame => _onDrawFrame;
  VoidCallback? _onDrawFrame;
  Zone _onDrawFrameZone = Zone.root;
  set onDrawFrame(VoidCallback? callback) {
    _onDrawFrame = callback;
    _onDrawFrameZone = Zone.current;
  }

  // 引擎调用
  // Called from the engine, via hooks.dart
  void _drawFrame() {
    _invoke(onDrawFrame, _onDrawFrameZone);
  }

  /// 指针事件的回调
  ///
  /// A callback that is invoked when pointer data is available.
  ///
  /// The framework invokes this callback in the same zone in which the callback
  /// was set.
  ///
  /// See also:
  ///
  ///  * [GestureBinding], the Flutter framework class which manages pointer
  ///    events.
  PointerDataPacketCallback? get onPointerDataPacket => _onPointerDataPacket;
  PointerDataPacketCallback? _onPointerDataPacket;
  Zone _onPointerDataPacketZone = Zone.root;
  set onPointerDataPacket(PointerDataPacketCallback? callback) {
    _onPointerDataPacket = callback;
    _onPointerDataPacketZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _dispatchPointerDataPacket(ByteData packet) {
    if (onPointerDataPacket != null) {
      _invoke1<PointerDataPacket>(
        onPointerDataPacket,
        _onPointerDataPacketZone,
        _unpackPointerDataPacket(packet),
      );
    }
  }

  // If this value changes, update the encoding code in the following files:
  //
  //  * pointer_data.cc
  //  * pointer.dart
  //  * AndroidTouchProcessor.java
  static const int _kPointerDataFieldCount = 29;

  static PointerDataPacket _unpackPointerDataPacket(ByteData packet) {
    const int kStride = Int64List.bytesPerElement;
    const int kBytesPerPointerData = _kPointerDataFieldCount * kStride;
    final int length = packet.lengthInBytes ~/ kBytesPerPointerData;
    assert(length * kBytesPerPointerData == packet.lengthInBytes);
    final List<PointerData> data = <PointerData>[];
    for (int i = 0; i < length; ++i) {
      int offset = i * _kPointerDataFieldCount;
      data.add(PointerData(
        embedderId: packet.getInt64(kStride * offset++, _kFakeHostEndian),
        timeStamp: Duration(microseconds: packet.getInt64(kStride * offset++, _kFakeHostEndian)),
        change: PointerChange.values[packet.getInt64(kStride * offset++, _kFakeHostEndian)],
        kind: PointerDeviceKind.values[packet.getInt64(kStride * offset++, _kFakeHostEndian)],
        signalKind: PointerSignalKind.values[packet.getInt64(kStride * offset++, _kFakeHostEndian)],
        device: packet.getInt64(kStride * offset++, _kFakeHostEndian),
        pointerIdentifier: packet.getInt64(kStride * offset++, _kFakeHostEndian),
        physicalX: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        physicalY: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        physicalDeltaX: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        physicalDeltaY: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        buttons: packet.getInt64(kStride * offset++, _kFakeHostEndian),
        obscured: packet.getInt64(kStride * offset++, _kFakeHostEndian) != 0,
        synthesized: packet.getInt64(kStride * offset++, _kFakeHostEndian) != 0,
        pressure: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        pressureMin: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        pressureMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        distance: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        distanceMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        size: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        radiusMajor: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        radiusMinor: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        radiusMin: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        radiusMax: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        orientation: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        tilt: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        platformData: packet.getInt64(kStride * offset++, _kFakeHostEndian),
        scrollDeltaX: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
        scrollDeltaY: packet.getFloat64(kStride * offset++, _kFakeHostEndian),
      ));
      assert(offset == (i + 1) * _kPointerDataFieldCount);
    }
    return PointerDataPacket(data: data);
  }

  /// A callback that is invoked to report the [FrameTiming] of recently
  /// rasterized frames.
  ///
  /// It's preferred to use [SchedulerBinding.addTimingsCallback] than to use
  /// [onReportTimings] directly because [SchedulerBinding.addTimingsCallback]
  /// allows multiple callbacks.
  ///
  /// This can be used to see if the application has missed frames (through
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
  TimingsCallback? get onReportTimings => _onReportTimings;
  TimingsCallback? _onReportTimings;
  Zone _onReportTimingsZone = Zone.root;
  set onReportTimings(TimingsCallback? callback) {
    if ((callback == null) != (_onReportTimings == null)) {
      _setNeedsReportTimings(callback != null);
    }
    _onReportTimings = callback;
    _onReportTimingsZone = Zone.current;
  }

  late _SetNeedsReportTimingsFunc _setNeedsReportTimings;
  void _nativeSetNeedsReportTimings(bool value)
  native 'PlatformConfiguration_setNeedsReportTimings';

  // Called from the engine, via hooks.dart
  void _reportTimings(List<int> timings) {
    assert(timings.length % FramePhase.values.length == 0);
    final List<FrameTiming> frameTimings = <FrameTiming>[];
    for (int i = 0; i < timings.length; i += FramePhase.values.length) {
      frameTimings.add(FrameTiming._(timings.sublist(i, i + FramePhase.values.length)));
    }
    _invoke1(onReportTimings, _onReportTimingsZone, frameTimings);
  }

  /// Sends a message to a platform-specific plugin.
  ///
  /// The `name` parameter determines which plugin receives the message. The
  /// `data` parameter contains the message payload and is typically UTF-8
  /// encoded JSON but can be arbitrary data. If the plugin replies to the
  /// message, `callback` will be called with the response.
  ///
  /// The framework invokes [callback] in the same zone in which this method was
  /// called.
  void sendPlatformMessage(String name, ByteData? data, PlatformMessageResponseCallback? callback) {
    final String? error =
    _sendPlatformMessage(name, _zonedPlatformMessageResponseCallback(callback), data);
    if (error != null)
      throw Exception(error);
  }

  String? _sendPlatformMessage(String name, PlatformMessageResponseCallback? callback, ByteData? data)
  native 'PlatformConfiguration_sendPlatformMessage';

  /// Called whenever this platform dispatcher receives a message from a
  /// platform-specific plugin.
  ///
  /// The `name` parameter determines which plugin sent the message. The `data`
  /// parameter is the payload and is typically UTF-8 encoded JSON but can be
  /// arbitrary data.
  ///
  /// Message handlers must call the function given in the `callback` parameter.
  /// If the handler does not need to respond, the handler should pass null to
  /// the callback.
  ///
  /// The framework invokes this callback in the same zone in which the callback
  /// was set.
  // TODO(ianh): Deprecate onPlatformMessage once the framework is moved over
  // to using channel buffers exclusively.
  PlatformMessageCallback? get onPlatformMessage => _onPlatformMessage;
  PlatformMessageCallback? _onPlatformMessage;
  Zone _onPlatformMessageZone = Zone.root;
  set onPlatformMessage(PlatformMessageCallback? callback) {
    _onPlatformMessage = callback;
    _onPlatformMessageZone = Zone.current;
  }

  /// Called by [_dispatchPlatformMessage].
  void _respondToPlatformMessage(int responseId, ByteData? data)
  native 'PlatformConfiguration_respondToPlatformMessage';

  /// Wraps the given [callback] in another callback that ensures that the
  /// original callback is called in the zone it was registered in.
  static PlatformMessageResponseCallback? _zonedPlatformMessageResponseCallback(
      PlatformMessageResponseCallback? callback,
      ) {
    if (callback == null) {
      return null;
    }

    // Store the zone in which the callback is being registered.
    final Zone registrationZone = Zone.current;

    return (ByteData? data) {
      registrationZone.runUnaryGuarded(callback, data);
    };
  }

  /// Send a message to the framework using the [ChannelBuffers].
  ///
  /// This method constructs the appropriate callback to respond
  /// with the given `responseId`. It should only be called for messages
  /// from the platform.
  void _dispatchPlatformMessage(String name, ByteData? data, int responseId) {
    if (name == ChannelBuffers.kControlChannelName) {
      try {
        channelBuffers.handleMessage(data!);
      } finally {
        _respondToPlatformMessage(responseId, null);
      }
    } else if (onPlatformMessage != null) {
      _invoke3<String, ByteData?, PlatformMessageResponseCallback>(
        onPlatformMessage,
        _onPlatformMessageZone,
        name,
        data,
            (ByteData? responseData) {
          _respondToPlatformMessage(responseId, responseData);
        },
      );
    } else {
      channelBuffers.push(name, data, (ByteData? responseData) {
        _respondToPlatformMessage(responseId, responseData);
      });
    }
  }

  /// Set the debug name associated with this platform dispatcher's root
  /// isolate.
  ///
  /// Normally debug names are automatically generated from the Dart port, entry
  /// point, and source file. For example: `main.dart$main-1234`.
  ///
  /// This can be combined with flutter tools `--isolate-filter` flag to debug
  /// specific root isolates. For example: `flutter attach --isolate-filter=[name]`.
  /// Note that this does not rename any child isolates of the root.
  void setIsolateDebugName(String name) native 'PlatformConfiguration_setIsolateDebugName';

  /// The embedder can specify data that the isolate can request synchronously
  /// on launch. This accessor fetches that data.
  ///
  /// This data is persistent for the duration of the Flutter application and is
  /// available even after isolate restarts. Because of this lifecycle, the size
  /// of this data must be kept to a minimum.
  ///
  /// For asynchronous communication between the embedder and isolate, a
  /// platform channel may be used.
  ByteData? getPersistentIsolateData() native 'PlatformConfiguration_getPersistentIsolateData';

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame] and
  /// [onDrawFrame] callbacks be invoked.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  void scheduleFrame() native 'PlatformConfiguration_scheduleFrame';

  /// Additional accessibility features that may be enabled by the platform.
  AccessibilityFeatures get accessibilityFeatures => configuration.accessibilityFeatures;

  /// A callback that is invoked when the value of [accessibilityFeatures]
  /// changes.
  ///
  /// The framework invokes this callback in the same zone in which the callback
  /// was set.
  VoidCallback? get onAccessibilityFeaturesChanged => _onAccessibilityFeaturesChanged;
  VoidCallback? _onAccessibilityFeaturesChanged;
  Zone _onAccessibilityFeaturesChangedZone = Zone.root;
  set onAccessibilityFeaturesChanged(VoidCallback? callback) {
    _onAccessibilityFeaturesChanged = callback;
    _onAccessibilityFeaturesChangedZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _updateAccessibilityFeatures(int values) {
    final AccessibilityFeatures newFeatures = AccessibilityFeatures._(values);
    final PlatformConfiguration previousConfiguration = configuration;
    if (newFeatures == previousConfiguration.accessibilityFeatures) {
      return;
    }
    _configuration = previousConfiguration.copyWith(
      accessibilityFeatures: newFeatures,
    );
    _invoke(onPlatformConfigurationChanged, _onPlatformConfigurationChangedZone,);
    _invoke(onAccessibilityFeaturesChanged, _onAccessibilityFeaturesChangedZone,);
  }

  /// Change the retained semantics data about this platform dispatcher.
  ///
  /// If [semanticsEnabled] is true, the user has requested that this function
  /// be called whenever the semantic content of this platform dispatcher
  /// changes.
  ///
  /// In either case, this function disposes the given update, which means the
  /// semantics update cannot be used further.
  void updateSemantics(SemanticsUpdate update) native 'PlatformConfiguration_updateSemantics';

  /// The system-reported default locale of the device.
  ///
  /// This establishes the language and formatting conventions that application
  /// should, if possible, use to render their user interface.
  ///
  /// This is the first locale selected by the user and is the user's primary
  /// locale (the locale the device UI is displayed in)
  ///
  /// This is equivalent to `locales.first`, except that it will provide an
  /// undefined (using the language tag "und") non-null locale if the [locales]
  /// list has not been set or is empty.
  Locale get locale => locales.isEmpty ? const Locale.fromSubtags() : locales.first;

  /// The full system-reported supported locales of the device.
  ///
  /// This establishes the language and formatting conventions that application
  /// should, if possible, use to render their user interface.
  ///
  /// The list is ordered in order of priority, with lower-indexed locales being
  /// preferred over higher-indexed ones. The first element is the primary
  /// [locale].
  ///
  /// The [onLocaleChanged] callback is called whenever this value changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  List<Locale> get locales => configuration.locales;

  /// Performs the platform-native locale resolution.
  ///
  /// Each platform may return different results.
  ///
  /// If the platform fails to resolve a locale, then this will return null.
  ///
  /// This method returns synchronously and is a direct call to
  /// platform specific APIs without invoking method channels.
  Locale? computePlatformResolvedLocale(List<Locale> supportedLocales) {
    final List<String?> supportedLocalesData = <String?>[];
    for (Locale locale in supportedLocales) {
      supportedLocalesData.add(locale.languageCode);
      supportedLocalesData.add(locale.countryCode);
      supportedLocalesData.add(locale.scriptCode);
    }

    final List<String> result = _computePlatformResolvedLocale(supportedLocalesData);

    if (result.isNotEmpty) {
      return Locale.fromSubtags(
          languageCode: result[0],
          countryCode: result[1] == '' ? null : result[1],
          scriptCode: result[2] == '' ? null : result[2]);
    }
    return null;
  }
  List<String> _computePlatformResolvedLocale(List<String?> supportedLocalesData) native 'PlatformConfiguration_computePlatformResolvedLocale';

  /// A callback that is invoked whenever [locale] changes value.
  ///
  /// The framework invokes this callback in the same zone in which the callback
  /// was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onLocaleChanged => _onLocaleChanged;
  VoidCallback? _onLocaleChanged;
  Zone _onLocaleChangedZone = Zone.root; // ignore: unused_field
  set onLocaleChanged(VoidCallback? callback) {
    _onLocaleChanged = callback;
    _onLocaleChangedZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _updateLocales(List<String> locales) {
    const int stringsPerLocale = 4;
    final int numLocales = locales.length ~/ stringsPerLocale;
    final PlatformConfiguration previousConfiguration = configuration;
    final List<Locale> newLocales = <Locale>[];
    bool localesDiffer = numLocales != previousConfiguration.locales.length;
    for (int localeIndex = 0; localeIndex < numLocales; localeIndex++) {
      final String countryCode = locales[localeIndex * stringsPerLocale + 1];
      final String scriptCode = locales[localeIndex * stringsPerLocale + 2];

      newLocales.add(Locale.fromSubtags(
        languageCode: locales[localeIndex * stringsPerLocale],
        countryCode: countryCode.isEmpty ? null : countryCode,
        scriptCode: scriptCode.isEmpty ? null : scriptCode,
      ));
      if (!localesDiffer && newLocales[localeIndex] != previousConfiguration.locales[localeIndex]) {
        localesDiffer = true;
      }
    }
    if (!localesDiffer) {
      return;
    }
    _configuration = previousConfiguration.copyWith(locales: newLocales);
    _invoke(onPlatformConfigurationChanged, _onPlatformConfigurationChangedZone);
    _invoke(onLocaleChanged, _onLocaleChangedZone);
  }

  // Called from the engine, via hooks.dart
  String _localeClosure() => locale.toString();

  /// The lifecycle state immediately after dart isolate initialization.
  ///
  /// This property will not be updated as the lifecycle changes.
  ///
  /// It is used to initialize [SchedulerBinding.lifecycleState] at startup with
  /// any buffered lifecycle state events.
  String get initialLifecycleState {
    _initialLifecycleStateAccessed = true;
    return _initialLifecycleState;
  }

  late String _initialLifecycleState;

  /// Tracks if the initial state has been accessed. Once accessed, we will stop
  /// updating the [initialLifecycleState], as it is not the preferred way to
  /// access the state.
  bool _initialLifecycleStateAccessed = false;

  // Called from the engine, via hooks.dart
  void _updateLifecycleState(String state) {
    // We do not update the state if the state has already been used to initialize
    // the lifecycleState.
    if (!_initialLifecycleStateAccessed)
      _initialLifecycleState = state;
  }

  /// The setting indicating whether time should always be shown in the 24-hour
  /// format.
  ///
  /// This option is used by [showTimePicker].
  bool get alwaysUse24HourFormat => configuration.alwaysUse24HourFormat;

  /// The system-reported text scale.
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
  double get textScaleFactor => configuration.textScaleFactor;

  /// A callback that is invoked whenever [textScaleFactor] changes value.
  ///
  /// The framework invokes this callback in the same zone in which the callback
  /// was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onTextScaleFactorChanged => _onTextScaleFactorChanged;
  VoidCallback? _onTextScaleFactorChanged;
  Zone _onTextScaleFactorChangedZone = Zone.root;
  set onTextScaleFactorChanged(VoidCallback? callback) {
    _onTextScaleFactorChanged = callback;
    _onTextScaleFactorChangedZone = Zone.current;
  }

  /// The setting indicating the current brightness mode of the host platform.
  /// If the platform has no preference, [platformBrightness] defaults to
  /// [Brightness.light].
  Brightness get platformBrightness => configuration.platformBrightness;

  /// A callback that is invoked whenever [platformBrightness] changes value.
  ///
  /// The framework invokes this callback in the same zone in which the callback
  /// was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onPlatformBrightnessChanged => _onPlatformBrightnessChanged;
  VoidCallback? _onPlatformBrightnessChanged;
  Zone _onPlatformBrightnessChangedZone = Zone.root;
  set onPlatformBrightnessChanged(VoidCallback? callback) {
    _onPlatformBrightnessChanged = callback;
    _onPlatformBrightnessChangedZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _updateUserSettingsData(String jsonData) {
    final Map<String, dynamic> data = json.decode(jsonData) as Map<String, dynamic>;
    if (data.isEmpty) {
      return;
    }

    final double textScaleFactor = (data['textScaleFactor'] as num).toDouble();
    final bool alwaysUse24HourFormat = data['alwaysUse24HourFormat'] as bool;
    final Brightness platformBrightness =
    data['platformBrightness'] as String == 'dark' ? Brightness.dark : Brightness.light;
    final PlatformConfiguration previousConfiguration = configuration;
    final bool platformBrightnessChanged =
        previousConfiguration.platformBrightness != platformBrightness;
    final bool textScaleFactorChanged = previousConfiguration.textScaleFactor != textScaleFactor;
    final bool alwaysUse24HourFormatChanged =
        previousConfiguration.alwaysUse24HourFormat != alwaysUse24HourFormat;
    if (!platformBrightnessChanged && !textScaleFactorChanged && !alwaysUse24HourFormatChanged) {
      return;
    }
    _configuration = previousConfiguration.copyWith(
      textScaleFactor: textScaleFactor,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
      platformBrightness: platformBrightness,
    );
    _invoke(onPlatformConfigurationChanged, _onPlatformConfigurationChangedZone);
    if (textScaleFactorChanged) {
      _invoke(onTextScaleFactorChanged, _onTextScaleFactorChangedZone);
    }
    if (platformBrightnessChanged) {
      _invoke(onPlatformBrightnessChanged, _onPlatformBrightnessChangedZone);
    }
  }

  /// Whether the user has requested that [updateSemantics] be called when the
  /// semantic contents of a view changes.
  ///
  /// The [onSemanticsEnabledChanged] callback is called whenever this value
  /// changes.
  bool get semanticsEnabled => configuration.semanticsEnabled;

  /// A callback that is invoked when the value of [semanticsEnabled] changes.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get onSemanticsEnabledChanged => _onSemanticsEnabledChanged;
  VoidCallback? _onSemanticsEnabledChanged;
  Zone _onSemanticsEnabledChangedZone = Zone.root;
  set onSemanticsEnabledChanged(VoidCallback? callback) {
    _onSemanticsEnabledChanged = callback;
    _onSemanticsEnabledChangedZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _updateSemanticsEnabled(bool enabled) {
    final PlatformConfiguration previousConfiguration = configuration;
    if (previousConfiguration.semanticsEnabled == enabled) {
      return;
    }
    _configuration = previousConfiguration.copyWith(
      semanticsEnabled: enabled,
    );
    _invoke(onPlatformConfigurationChanged, _onPlatformConfigurationChangedZone);
    _invoke(onSemanticsEnabledChanged, _onSemanticsEnabledChangedZone);
  }

  /// A callback that is invoked whenever the user requests an action to be
  /// performed.
  ///
  /// This callback is used when the user expresses the action they wish to
  /// perform based on the semantics supplied by [updateSemantics].
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  SemanticsActionCallback? get onSemanticsAction => _onSemanticsAction;
  SemanticsActionCallback? _onSemanticsAction;
  Zone _onSemanticsActionZone = Zone.root;
  set onSemanticsAction(SemanticsActionCallback? callback) {
    _onSemanticsAction = callback;
    _onSemanticsActionZone = Zone.current;
  }

  // Called from the engine, via hooks.dart
  void _dispatchSemanticsAction(int id, int action, ByteData? args) {
    _invoke3<int, SemanticsAction, ByteData?>(
      onSemanticsAction,
      _onSemanticsActionZone,
      id,
      SemanticsAction.values[action]!,
      args,
    );
  }

  /// The route or path that the embedder requested when the application was
  /// launched.
  ///
  /// This will be the string "`/`" if no particular route was requested.
  ///
  /// ## Android
  ///
  /// On Android, calling
  /// [`FlutterView.setInitialRoute`](/javadoc/io/flutter/view/FlutterView.html#setInitialRoute-java.lang.String-)
  /// will set this value. The value must be set sufficiently early, i.e. before
  /// the [runApp] call is executed in Dart, for this to have any effect on the
  /// framework. The `createFlutterView` method in your `FlutterActivity`
  /// subclass is a suitable time to set the value. The application's
  /// `AndroidManifest.xml` file must also be updated to have a suitable
  /// [`<intent-filter>`](https://developer.android.com/guide/topics/manifest/intent-filter-element.html).
  ///
  /// ## iOS
  ///
  /// On iOS, calling
  /// [`FlutterViewController.setInitialRoute`](/objcdoc/Classes/FlutterViewController.html#/c:objc%28cs%29FlutterViewController%28im%29setInitialRoute:)
  /// will set this value. The value must be set sufficiently early, i.e. before
  /// the [runApp] call is executed in Dart, for this to have any effect on the
  /// framework. The `application:didFinishLaunchingWithOptions:` method is a
  /// suitable time to set this value.
  ///
  /// See also:
  ///
  ///  * [Navigator], a widget that handles routing.
  ///  * [SystemChannels.navigation], which handles subsequent navigation
  ///    requests from the embedder.
  String get defaultRouteName => _defaultRouteName();
  String _defaultRouteName() native 'PlatformConfiguration_defaultRouteName';
}
