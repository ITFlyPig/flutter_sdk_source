import 'package:flutter/rendering.dart';

import '../StatefulWidget源码.dart';
import '../State源码.dart';
import 'TickerProvider源码.dart';
import 'TickerProvider源码.dart';
import 'Ticker源码.dart';

/// 提供单个[Ticker]，这个[Ticker]被配置为只有在当前树是可用的情况下才会进行滴答（tick）。
///
/// 当在[State]中创建并使用一个[AnimationController] 时，可以混入这个类。
///
/// 这个mixin指挥产生一个ticker，在[State]的生命中，如果你想产生多个ticker，请使用[TickerProviderStateMixin]。
@optionalTypeArgs
mixin SingleTickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            '$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.'),
        ErrorDescription(
            'A SingleTickerProviderStateMixin can only be used as a TickerProvider once.'),
        ErrorHint(
            'If a State is used for multiple AnimationController objects, or if it is passed to other '
            'objects and those objects might use it more than one time in total, then instead of '
            'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.')
      ]);
    }());
    _ticker =
        Ticker(onTick, debugLabel: kDebugMode ? 'created by $this' : null);
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.of(context) would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    return _ticker!;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription(
            '$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
            'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
            'be disposed before calling super.dispose().'),
        ErrorHint('Tickers used by AnimationControllers '
            'should be disposed by calling dispose() on the AnimationController itself. '
            'Otherwise, the ticker will leak.'),
        _ticker!.describeForError('The offending ticker was')
      ]);
    }());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_ticker != null) _ticker!.muted = !TickerMode.of(context);
    super.didChangeDependencies();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    String? tickerDescription;
    if (_ticker != null) {
      if (_ticker!.isActive && _ticker!.muted)
        tickerDescription = 'active but muted';
      else if (_ticker!.isActive)
        tickerDescription = 'active';
      else if (_ticker!.muted)
        tickerDescription = 'inactive and muted';
      else
        tickerDescription = 'inactive';
    }
    properties.add(DiagnosticsProperty<Ticker>('ticker', _ticker,
        description: tickerDescription,
        showSeparator: false,
        defaultValue: null));
  }
}
