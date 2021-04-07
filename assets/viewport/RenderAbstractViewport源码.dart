///
/// 内部较大的渲染对象（render object）的接口。
///
/// 有些渲染对象，比如[RenderViewport]，会呈现内容的一部分，可以通过[ViewportOffset]来
/// 控制。这个接口可以让框架识别这样的渲染对象，并与它们进行交互，而不需要具备所有各种类型的
/// 视窗的具体知识。
///
abstract class RenderAbstractViewport extends RenderObject {
  // This class is intended to be used as an interface, and should not be
  // extended directly; this constructor prevents instantiation and extension.
  // ignore: unused_element
  factory RenderAbstractViewport._() => throw Error();

  /// 返回最接近给定渲染对象的[RenderAbstractViewport]。
  ///
  /// 如果对象没有[RenderAbstractViewport]作为祖先，这个函数返回null。
  ///
  static RenderAbstractViewport? of(RenderObject? object) {
    while (object != null) {
      if (object is RenderAbstractViewport)
        return object;
      object = object.parent as RenderObject?;
    }
    return null;
  }

  /// 返回在视窗内显示`target`[RenderObject]所需的偏移量。
  ///
  /// 这被[RenderViewportBase.showInViewport]使用，而它本身又被[RenderObject.showOnScreen]
  /// 用于[RenderViewportBase]，而[RenderViewportBase]又被语义系统用于实现无障碍工具的
  /// 滚动。
  ///
  /// 可选的`rect`参数描述了`target`对象的哪个区域应该在视窗中被显示。如果`rect`为空，则整
  /// 个`target`[RenderObject](由其[RenderObject.paintBounds]定义)将被显示。如果提供
  /// 了rect，则必须在`target`对象的坐标系中给出。
  ///
  /// `alignment`参数描述了应用返回的偏移量后目标的位置。如果`alignment`是0.0，则子控件必
  /// 须尽可能地靠近视口的前缘。如果`alignment`是1.0，子代的位置必须尽可能靠近视口的尾部边
  /// 缘。如果`alignment`是0.5，孩子的位置必须尽可能地接近视口的中心。
  ///
  /// `target`可能不是这个视口的直接子代，但它必须是这个视口的子孙。在这个视窗和 "target "
  /// 之间的其他视窗将不会被调整。
  ///
  /// 这个方法假设视窗的内容是线性移动的，即当视窗的偏移量改变x时，那么`target`也会在视口内移动x。
  ///
  /// See also:
  /// * [RevealedOffset]，它描述了这个方法的返回值。
  ///
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment, { Rect? rect });

  /// 视窗缓存尺寸的默认值
  ///
  /// 该默认值假定为[CacheExtentStyle.pixel]。
  ///
  /// See also:
  /// * [RenderViewportBase.cacheExtent]以获取缓存尺寸的定义。
  static const double defaultCacheExtent = 250.0;
}
