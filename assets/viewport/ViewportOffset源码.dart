abstract class ViewportOffset extends ChangeNotifier {
  /// Default constructor.
  ///
  /// Allows subclasses to construct this object directly.
  ViewportOffset();

  /// Creates a viewport offset with the given [pixels] value.
  ///
  /// The [pixels] value does not change unless the viewport issues a
  /// correction.
  factory ViewportOffset.fixed(double value) = _FixedViewportOffset;

  /// Creates a viewport offset with a [pixels] value of 0.0.
  ///
  /// The [pixels] value does not change unless the viewport issues a
  /// correction.
  factory ViewportOffset.zero() = _FixedViewportOffset.zero;

  /// 与轴方向相反的children偏移的像素数。
  ///
  /// 例如，如果轴的方向是向下的，那么像素值就代表children屏幕向上移动的逻辑像素数。同理，
  /// 如果轴的方向是左，那么像素值代表将children向右移动的逻辑像素数。
  ///
  /// 当这个值发生变化时，这个对象会通知它的监听器（除了由于[correctBy]导致值发生变化时）。
  double get pixels;

  /// Whether the [pixels] property is available.
  bool get hasPixels;

  /// Called when the viewport's extents are established.
  ///
  /// The argument is the dimension of the [RenderViewport] in the main axis
  /// (e.g. the height, for a vertical viewport).
  ///
  /// This may be called redundantly, with the same value, each frame. This is
  /// called during layout for the [RenderViewport]. If the viewport is
  /// configured to shrink-wrap its contents, it may be called several times,
  /// since the layout is repeated each time the scroll offset is corrected.
  ///
  /// If this is called, it is called before [applyContentDimensions]. If this
  /// is called, [applyContentDimensions] will be called soon afterwards in the
  /// same layout phase. If the viewport is not configured to shrink-wrap its
  /// contents, then this will only be called when the viewport recomputes its
  /// size (i.e. when its parent lays out), and not during normal scrolling.
  ///
  /// If applying the viewport dimensions changes the scroll offset, return
  /// false. Otherwise, return true. If you return false, the [RenderViewport]
  /// will be laid out again with the new scroll offset. This is expensive. (The
  /// return value is answering the question "did you accept these viewport
  /// dimensions unconditionally?"; if the new dimensions change the
  /// [ViewportOffset]'s actual [pixels] value, then the viewport will need to
  /// be laid out again.)
  bool applyViewportDimension(double viewportDimension);

  /// Called when the viewport's content extents are established.
  ///
  /// The arguments are the minimum and maximum scroll extents respectively. The
  /// minimum will be equal to or less than the maximum. In the case of slivers,
  /// the minimum will be equal to or less than zero, the maximum will be equal
  /// to or greater than zero.
  ///
  /// The maximum scroll extent has the viewport dimension subtracted from it.
  /// For instance, if there is 100.0 pixels of scrollable content, and the
  /// viewport is 80.0 pixels high, then the minimum scroll extent will
  /// typically be 0.0 and the maximum scroll extent will typically be 20.0,
  /// because there's only 20.0 pixels of actual scroll slack.
  ///
  /// If applying the content dimensions changes the scroll offset, return
  /// false. Otherwise, return true. If you return false, the [RenderViewport]
  /// will be laid out again with the new scroll offset. This is expensive. (The
  /// return value is answering the question "did you accept these content
  /// dimensions unconditionally?"; if the new dimensions change the
  /// [ViewportOffset]'s actual [pixels] value, then the viewport will need to
  /// be laid out again.)
  ///
  /// This is called at least once each time the [RenderViewport] is laid out,
  /// even if the values have not changed. It may be called many times if the
  /// scroll offset is corrected (if this returns false). This is always called
  /// after [applyViewportDimension], if that method is called.
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent);

  /// Apply a layout-time correction to the scroll offset.
  ///
  /// This method should change the [pixels] value by `correction`, but without
  /// calling [notifyListeners]. It is called during layout by the
  /// [RenderViewport], before [applyContentDimensions]. After this method is
  /// called, the layout will be recomputed and that may result in this method
  /// being called again, though this should be very rare.
  ///
  /// See also:
  ///
  ///  * [jumpTo], for also changing the scroll position when not in layout.
  ///    [jumpTo] applies the change immediately and notifies its listeners.
  void correctBy(double correction);

  /// Jumps [pixels] from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  ///
  /// See also:
  ///
  ///  * [correctBy], for changing the current offset in the middle of layout
  ///    and that defers the notification of its listeners until after layout.
  void jumpTo(double pixels);

  /// Animates [pixels] from its current value to the given value.
  ///
  /// The returned [Future] will complete when the animation ends, whether it
  /// completed successfully or whether it was interrupted prematurely.
  ///
  /// The duration must not be zero. To jump to a particular value without an
  /// animation, use [jumpTo].
  Future<void> animateTo(
      double to, {
        required Duration duration,
        required Curve curve,
      });

  /// Calls [jumpTo] if duration is null or [Duration.zero], otherwise
  /// [animateTo] is called.
  ///
  /// If [animateTo] is called then [curve] defaults to [Curves.ease]. The
  /// [clamp] parameter is ignored by this stub implementation but subclasses
  /// like [ScrollPosition] handle it by adjusting [to] to prevent over or
  /// underscroll.
  Future<void> moveTo(
      double to, {
        Duration? duration,
        Curve? curve,
        bool? clamp,
      }) {
    assert(to != null);
    if (duration == null || duration == Duration.zero) {
      jumpTo(to);
      return Future<void>.value();
    } else {
      return animateTo(to, duration: duration, curve: curve ?? Curves.ease);
    }
  }

  /// The direction in which the user is trying to change [pixels], relative to
  /// the viewport's [RenderViewportBase.axisDirection].
  ///
  /// If the _user_ is not scrolling, this will return [ScrollDirection.idle]
  /// even if there is (for example) a [ScrollActivity] currently animating the
  /// position.
  ///
  /// This is exposed in [SliverConstraints.userScrollDirection], which is used
  /// by some slivers to determine how to react to a change in scroll offset.
  /// For example, [RenderSliverFloatingPersistentHeader] will only expand a
  /// floating app bar when the [userScrollDirection] is in the positive scroll
  /// offset direction.
  ScrollDirection get userScrollDirection;

  /// Whether a viewport is allowed to change [pixels] implicitly to respond to
  /// a call to [RenderObject.showOnScreen].
  ///
  /// [RenderObject.showOnScreen] is for example used to bring a text field
  /// fully on screen after it has received focus. This property controls
  /// whether the viewport associated with this offset is allowed to change the
  /// offset's [pixels] value to fulfill such a request.
  bool get allowImplicitScrolling;

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '${describeIdentity(this)}(${description.join(", ")})';
  }

  /// Add additional information to the given description for use by [toString].
  ///
  /// This method makes it easier for subclasses to coordinate to provide a
  /// high-quality [toString] implementation. The [toString] implementation on
  /// the [State] base class calls [debugFillDescription] to collect useful
  /// information from subclasses to incorporate into its return value.
  ///
  /// If you override this, make sure to start your method with a call to
  /// `super.debugFillDescription(description)`.
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (hasPixels) {
      description.add('offset: ${pixels.toStringAsFixed(1)}');
    }
  }
}
