///
/// 一个使用[AlignmentGeometry]来实现child 布局的抽象类，
///
abstract class RenderAligningShiftedBox extends RenderShiftedBox {
  /// Initializes member variables for subclasses.
  ///
  /// The [alignment] argument must not be null.
  ///
  /// The [textDirection] must be non-null if the [alignment] is
  /// direction-sensitive.
  RenderAligningShiftedBox({
    AlignmentGeometry alignment = Alignment.center,
    required TextDirection? textDirection,
    RenderBox? child,
  }) :
        _alignment = alignment,
        _textDirection = textDirection,
        super(child);

  /// A constructor to be used only when the extending class also has a mixin.
  // TODO(gspencer): Remove this constructor once https://github.com/dart-lang/sdk/issues/31543 is fixed.
  @protected
  RenderAligningShiftedBox.mixin(AlignmentGeometry alignment, TextDirection? textDirection, RenderBox? child)
      : this(alignment: alignment, textDirection: textDirection, child: child);

  Alignment? _resolvedAlignment;

  void _resolve() {
    if (_resolvedAlignment != null)
      return;
    _resolvedAlignment = alignment.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// If this is set to an [AlignmentDirectional] object, then
  /// [textDirection] must not be null.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  /// Sets the alignment to a new value, and triggers a layout update.
  ///
  /// The new alignment must not be null.
  set alignment(AlignmentGeometry value) {
    if (_alignment == value)
      return;
    _alignment = value;
    _markNeedResolution();
  }

  /// The text direction with which to resolve [alignment].
  ///
  /// This may be changed to null, but only after [alignment] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value)
      return;
    _textDirection = value;
    _markNeedResolution();
  }

  /// 实现child的对齐方式
  ///
  /// Apply the current [alignment] to the [child].
  ///
  /// Subclasses should call this method if they have a child, to have
  /// this class perform the actual alignment. If there is no child,
  /// do not call this method.
  ///
  /// This method must be called after the child has been laid out and
  /// this object's own size has been set.
  @protected
  void alignChild() {
    _resolve();
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    //本质也就是计算offset，只不过将不同对其方式的计算放到了Alignment类中
    childParentData.offset = _resolvedAlignment!.alongOffset(size - child!.size as Offset);
  }

}
