import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Signature for the callback passed to the [Ticker] class's constructor.
///
/// The argument is the time that the object had spent enabled so far
/// at the time of the callback being called.
typedef TickerCallback = void Function(Duration elapsed);

/// 接口，子类实现它并创建[Ticker]
///
/// 任何希望每帧都会被通知的对象，都可以使用Tickers，但是大多数情况是通过[AnimationController]来间接地使用它。
/// [AnimationController]s需要[TickerProvider]来提供[Ticker]。如果要从[State]创建
/// [AnimationController]，则可以使用[TickerProviderStateMixin]和[SingleTickerProviderStateMixin]
/// 类来获得合适的[TickerProvider]。小组件测试框架[WidgetTester]对象可以在context测试中使用一个ticker provider。
/// 在其他context中，您必须从高级别传递[TickerProvider](例如，间接从混合了[TickerProviderStateMixin]的[State]传递)，
/// 或者创建自定义[TickerProvider]子类。
///
abstract class TickerProvider {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const TickerProvider();

  /// 使用回调创建一个ticker
  ///
  /// The kind of ticker provided depends on the kind of ticker provider.
  @factory
  Ticker createTicker(TickerCallback onTick);
}
