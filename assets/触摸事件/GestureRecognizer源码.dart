import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

/// 所有手势识别器都继承自该基类
///
/// 提供了一个基本的API，可以被那些与手势识别器一起工作但不关心手势识别器本身具体细节的类所使用。
///
///
abstract class GestureRecognizer extends GestureArenaMember
    with DiagnosticableTreeMixin {
  /// Initializes the gesture recognizer.
  ///
  /// The argument is optional and is only used for debug purposes (e.g. in the
  /// [toString] serialization).
  ///
  /// {@template flutter.gestures.GestureRecognizer.kind}
  /// It's possible to limit this recognizer to a specific [PointerDeviceKind]
  /// by providing the optional [kind] argument. If [kind] is null,
  /// the recognizer will accept pointer events from all device kinds.
  /// {@endtemplate}
  GestureRecognizer({this.debugOwner, PointerDeviceKind? kind})
      : _kindFilter = kind;

  /// The recognizer's owner.
  ///
  /// This is used in the [toString] serialization to report the object for which
  /// this gesture recognizer was created, to aid in debugging.
  final Object? debugOwner;

  /// The kind of device that's allowed to be recognized. If null, events from
  /// all device kinds will be tracked and recognized.
  final PointerDeviceKind? _kindFilter;

  /// Holds a mapping between pointer IDs and the kind of devices they are
  /// coming from.
  final Map<int, PointerDeviceKind> _pointerToKind = <int, PointerDeviceKind>{};

  ///
  /// 注册一个可能与这个手势识别器有关的新指针事件。
  //
  // 这个手势识别器的所有者用每个可能与该手势有关的指针事件PointerDownEvent调用addPointer()。
  //
  // 然后，GestureRecognizer有责任将自己添加到全局指针事件路由器（见[PointerRouter]），
  // 以接收该指针事件的后续事件，并将该指针事件添加到全局手势竞技场管理器（见[GestureArenaManager]）以跟踪该指针。
  //
  // 这个方法对每个和所有被添加的指针都被调用。在大多数情况下，你想覆盖[addAllowedPointer]来代替。
  void addPointer(PointerDownEvent event) {
    _pointerToKind[event.pointer] = event.kind;
    if (isPointerAllowed(event)) {
      addAllowedPointer(event);
    } else {
      handleNonAllowedPointer(event);
    }
  }

  /// 注册一个新的指针事件。
  ///
  /// Registers a new pointer that's been checked to be allowed by this gesture
  /// recognizer.
  ///
  /// Subclasses of [GestureRecognizer] are supposed to override this method
  /// instead of [addPointer] because [addPointer] will be called for each
  /// pointer being added while [addAllowedPointer] is only called for pointers
  /// that are allowed by this recognizer.
  @protected
  void addAllowedPointer(PointerDownEvent event) {}

  /// Handles a pointer being added that's not allowed by this recognizer.
  ///
  /// Subclasses can override this method and reject the gesture.
  ///
  /// See:
  /// - [OneSequenceGestureRecognizer.handleNonAllowedPointer].
  @protected
  void handleNonAllowedPointer(PointerDownEvent event) {}

  /// 检查一个指针事件是否允许改识别器跟踪
  /// Checks whether or not a pointer is allowed to be tracked by this recognizer.
  @protected
  bool isPointerAllowed(PointerDownEvent event) {
    // Currently, it only checks for device kind. But in the future we could check
    // for other things e.g. mouse button.
    return _kindFilter == null || _kindFilter == event.kind;
  }

  /// For a given pointer ID, returns the device kind associated with it.
  ///
  /// The pointer ID is expected to be a valid one i.e. an event was received
  /// with that pointer ID.
  @protected
  PointerDeviceKind getKindForPointer(int pointer) {
    assert(_pointerToKind.containsKey(pointer));
    return _pointerToKind[pointer]!;
  }

  /// Releases any resources used by the object.
  ///
  /// This method is called by the owner of this gesture recognizer
  /// when the object is no longer needed (e.g. when a gesture
  /// recognizer is being unregistered from a [GestureDetector], the
  /// GestureDetector widget calls this method).
  @mustCallSuper
  void dispose() {}

  /// Returns a very short pretty description of the gesture that the
  /// recognizer looks for, like 'tap' or 'horizontal drag'.
  String get debugDescription;

  /// Invoke a callback provided by the application, catching and logging any
  /// exceptions.
  ///
  /// The `name` argument is ignored except when reporting exceptions.
  ///
  /// The `debugReport` argument is optional and is used when
  /// [debugPrintRecognizerCallbacksTrace] is true. If specified, it must be a
  /// callback that returns a string describing useful debugging information,
  /// e.g. the arguments passed to the callback.
  @protected
  T? invokeCallback<T>(String name, RecognizerCallback<T> callback,
      {String Function()? debugReport}) {
    assert(callback != null);
    T? result;
    try {
      assert(() {
        if (debugPrintRecognizerCallbacksTrace) {
          final String? report = debugReport != null ? debugReport() : null;
          // The 19 in the line below is the width of the prefix used by
          // _debugLogDiagnostic in arena.dart.
          final String prefix =
              debugPrintGestureArenaDiagnostics ? ' ' * 19 + '❙ ' : '';
          debugPrint(
              '$prefix$this calling $name callback.${report?.isNotEmpty == true ? " $report" : ""}');
        }
        return true;
      }());
      result = callback();
    } catch (exception, stack) {
      InformationCollector? collector;
      assert(() {
        collector = () sync* {
          yield StringProperty('Handler', name);
          yield DiagnosticsProperty<GestureRecognizer>('Recognizer', this,
              style: DiagnosticsTreeStyle.errorProperty);
        };
        return true;
      }());
      FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'gesture',
          context: ErrorDescription('while handling a gesture'),
          informationCollector: collector));
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('debugOwner', debugOwner,
        defaultValue: null));
  }
}
