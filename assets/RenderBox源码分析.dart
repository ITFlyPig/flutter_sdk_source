///一个二维笛卡尔坐标中的render object(渲染对象)。
///
/// 每个Box的Size使用一个width和一个height来表示，每个Box都有自己的坐标系，左上角位于(0,0)
/// 右下角位于(width, height)。
///
///Box的布局是通过在树上，从上往下传递布局约束[BoxConstraints] 对象完成的。
///[BoxConstraints] 布局约束条件规定了child的宽和高分别能取到的最大值和最小值。
///在确定其大小时，child必须遵守parent给它的布局约束[BoxConstraints]。
///
/// 1、如何创建一个RenderBox的子类
/// 为了描述一个新的布局模型、绘制模型或者事件命中模型，人们一般会实现一个新的[RenderBox]。这些都是在
/// [RenderBox]所定义的笛卡尔坐标空间中。如果要创建一个新的协议，考虑集成自[RenderObject]来实现。
///
///  1.1 子类的构造函数和属性
///  构造函数通常会为类的每个属性创建一个命名参数，并且会在构造函数内校验参数的正确性（比如不应该为null，那就使用asserts断言不为null）
///
///  属性通常糊提供getter/setter方法，如下
///
/// ```dart
/// AxisDirection get axis => _axis;
/// AxisDirection _axis;
/// set axis(AxisDirection value) {
///   assert(value != null); // same check as in the constructor
///   if (value == _axis)
///     return;
///   _axis = value;
///   markNeedsLayout();
/// }
/// ```
///  在setter函数中，如果布局使用该属性，应该调用[markNeedsLayout]标记需要布局，
///  如果绘制使用了该属性，应该调用[markNeedsPaint]标记需要绘制。这两个方法，不应该
///  同时调用两个，只应该调用其中一个（[markNeedsLayout]意味着[markNeedsPaint]）。
///
///  1.2 Children
///  如果一个render object是渲染树中的叶子节点，那么忽略本章节。目前已有的叶子render object有
///  RenderImage、RenderParagraph等。
///
///  对于带有children的render object，有一下四种可能的情况：
///  a. 如果只具有一个[RenderBox]child，在这种情况下：
///     如果parent和child的size一样大，那么考虑继承[RenderProxyBox] ；
///     如果child的size比parent的小，那么考虑使用[RenderShiftedBox] 。
///  b. 只有一个child，但是child的类型不是[RenderBox]，那么考虑使用[RenderObjectWithChildMixin] mixin。
///  c. 只有一个child 列表的模型，使用[ContainerRenderObjectMixin] mixin。
///  d. 更复杂的child模型。
///
///  1.2.1 使用RenderProxyBox
///  1.2.2 使用RenderShiftedBox
///  1.2.3 child的种类和child的具体数据
///    一个[RenderBox]的children不一定是[RenderBox]类型的，也可以使用[RenderObject]的另一个子类。
///
///    children可以拥有parent所拥有的额外的数据，但是[parentData]字段存储child身上。数据所使用的类
///    必须继承自[ParentData]。当child被附着时（attached），使用[setupParentData]方法初始化child的[parentData]字段。
///
///    按照惯例，一个[RenderBox]对象，如果拥有[RenderBox]类型的children，那么使用[BoxParentData] 类存数据，该类有一个[BoxParentData.offset]
///    字段来存储child相对于parent的位置。[RenderProxyBox]是例外。
///
///  1.2.4 RenderObjectWithChildMixin
///    如果一个render object 只有一个child，并且它还不是[RenderBox]类型的，那么[RenderObjectWithChildMixin]类就会很有用，
///    它是一个mixin，具有管理一个child的样板。
///    它是一个通用类，有一个child的类型参数。例如，如果你正在构建一个`RenderFoo` 类，它有一个`RenderBar`类型的child，
///    那么你可以像下面使用mixin：
/// ```dart
/// class RenderFoo extends RenderBox
///   with RenderObjectWithChildMixin<RenderBar> {
///   // ...
/// }
/// ```
///     在这种情况下，`RenderFoo`仍是一个[RenderBox]，所以要实现[RenderBox]的布局、绘制、事件命中测试等。
///
///  1.2.5 ContainerRenderObjectMixin
///    如果render box有多个children，那么可以使用[ContainerRenderObjectMixin] mixin来处理。它使用单链表的child模型，
///    这种模型易于动态修改，方便遍历。但是随机访问不高效，如果需要随机访问child，那么考虑使用下一节更复杂的模型。

///    ContainerRenderObjectMixin有两个类型参数：第一个是child的类型；第二个是child他们的[parentData]的类型。
///    用于[parentData]的类，它自己必须混入[ContainerParentDataMixin]，这是[ContainerRenderObjectMixin]存储链表的地方。
///    我们自定义[parentData]的类时，可以继承自[ContainerBoxParentData]，它本质上是[BoxParentData]，并混入了[ContainerParentDataMixin]。
///
///    例如，`RenderFoo`类希望有一个链表模型的[RenderBox]类型的children，那可以创建如下的`FooParentData`类：
///    ```dart
///    class FooParentData extends ContainerBoxParentData<RenderBox> {
///      // (any fields you might need for these children)
///    }
///    ```
///    当在[RenderBox]中使用[ContainerRenderObjectMixin]时，可以考虑混入[RenderBoxContainerDefaultsMixin]，它提供了实现[RenderBox]协议通用部分的实用方法集合（如绘制children）。
///
///    `RenderFoo`类的申明看起来如下：
///     ```dart
///     class RenderFoo extends RenderBox with
///       ContainerRenderObjectMixin<RenderBox, FooParentData>,
///        RenderBoxContainerDefaultsMixin<RenderBox, FooParentData> {
///       // ...
///      }
///     ```
///     当遍历children（例如layout（布局）期间）时，通常使用如下模式（这里假设child都是[RenderBox]类型的，并且child的[parentData]字段使用`FooParentData`）：
///     ```dart
///     RenderBox child = firstChild;
///     while (child != null) {
///       final FooParentData childParentData = child.parentData;
///       // ...operate on child and childParentData...
///       assert(child.parentData == childParentData);
///       child = childParentData.nextSibling;
///     }
///     ```
///  1.2.6 更复杂的child模型
///    Render object可以有更复杂的模型，例如，二维网格需要随机访问child、对个child列表等。如果一个Render object的模型不能被
///    上面的mixin处理的时候，必须实现[RenderObject] child 协议，如下：
///    a.任何时候，一个child被移除，调用[dropChild]方法
///    b.任何时候，一个child被添加，调用[adoptChild]方法
///    c.实现[attach]使其在每个child上调用[attach]
///    d.实现[detach] 使其在每个child上调用[detach]
///    e.实现[redepthChildren]使其在每个child上调用[redepthChild]
///    f.实现[visitChildren]方法
///    g.实现[debugDescribeChildren]，使其为每个子节点输出一个[DiagnosticsNode]。
///
///   落实这七个要点，基本上就是上述两个mixin的全部工作。
///
///
///  1.3 布局(layout)
///    [RenderBox]布局就是据提供的约束（constraints）和 其他的输入（如它的children或属性）来确定自己的大小。
///
///    在实现[RenderBox]子类时，必须做出选择。是完全根据约束条件来确定大小，还是使用其他信息来确定大小？纯粹基于约束条件进行大小调整的一个例子fit parent（也就是填充parent）。
///
///    纯粹根据约束条件进行大小调整，可以让系统进行一些显著的优化。使用这种方法的类应该重载[sizedByParent]来返回true，然后重载[computeDryLayout]来计算[Size]。例如：
///    ```dart
///    @override
///    bool get sizedByParent => true;
///
///    @override
///    Size computeDryLayout(BoxConstraints constraints) {
///      return constraints.smallest;
///    }
///    ```
///    否则，在[performLayout]方法中计算size。
///
///    [performLayout]方法中计算自己的大小和决定child的位置。
///
///  1.3.1 RenderBox类型children的布局
///    在[performLayout]函数中，应该调用每个box child的[layout]方法，并给该方法传递一个布局约束对象[BoxConstraints]。
///    向child传递严格的约束[BoxConstraints.isTight]，将允许渲染库应用一些优化，因为它知道是严格的，即使child的位置发生了
///    变化，child的尺寸也不会改变。
///
///    在[performLayout] 方法中，如果会使用child的size来影响布局layout，例如，如果render box
///    是包裹child的，或根据children的size来定位children，那么必须给child的[layout]函数指定`parentUsesSize`参数，并设置为true。
///
///    `parentUsesSize`这个标志会关闭一些优化，不依赖child大小的算法会更高效。特别是，依赖child的[Size]意味着，如果child的布局被标记为脏，
///    那么父代的布局可能也会被标记为脏，除非父代给子代的[constraints]是严格的约束）。
///
///    对于没有继承[RenderProxyBox]的[RenderBox]类来说，一旦laid（布局）好了自己的children，也应该对它们进行定位，
///    通过设置每个子类[parentData]对象的[BoxParentData.offset]字段。
///
///  1.3.1 非 RenderBox类型children的布局
///    [RenderBox]的children不一定非得是[RenderBox]类型的，如果它们使用了另一个协议，那么parent就会传入一个合适的[Constraints]子类作为约束，而不再是
///    [BoxConstraints]。parent将不读取child的size，而是读取对应该布局协议的[layout] 的输出。`parentUsesSize`标志仍然用来指示父类是否要读取该输出，
///    如果子类有严格的约束（由[Constraints.isTight]定义），优化仍然会启动。
///
///  1.3 Painting（绘制）
///
///  通过实现[paint] 方法，描述一个render box如何绘制。该[paint]方法会传入一个[PaintingContext] 对象和一个[Offset]对象。
///  [PaintingContext] 提供了影响图层树的方法，同时还提供了一个[PaintingContext.canvas]用来添加绘制的命令。canvas不应该被缓存。
///  每次调用[PaintingContext]上的方法时，都会有一个画布改变身份（identity）的机会。
///  [Offset]偏移量指定box的左上角在[PaintingContext.canvas]坐标系中的位置。
///
///  使用[TextPainter]可以在canvas绘制text
///
///  使用[paintImage]方法，可以将image绘制在canvas上
///
///  在[RenderBox]中，使用[PaintingContext]上的方法引入新图层时，应该覆盖[alwaysNeedsCompositing] getter 方法，并将其设置为true。
///  如果对象有时这样做，有时不这样做，它可以让该getter在某些情况下返回true，而在其他情况下返回false。在这种情况下，只要返回值会改变，就调用[markNeedsCompositingBitsUpdate]。
///  (当添加或删除一个child时，这将自动完成，所以如果[alwaysNeedsCompositing]getter只根据child的存在或不存在来改变值，你不必显式地调用它。)
///
///  任何时候，只要对象上有任何变化，就会导致[paint]方法绘制不同的地方（但不会导致布局改变），对象就应该调用[markNeedsPaint]。
///
///  1.3.1 Painting children（绘制children）
///
///  [paint]方法的`context`参数有一个[PaintingContext.paintChild]方法，它应该为每个要绘制的child调用。它应被该给一个对child的引用和一个[Offset]，[Offset]给出child相对于parent的位置。
///
///  如果[paint]方法在绘制children之前对painting contex进行了变换（或者通常在它自己作为参数给出的偏移量之外应用额外的偏移量），那么[applyPaintTransform]方法也应该被重写。
///  该方法必须以在绘制给定的child之前变换painting contex和偏移(offset)的同样方式调整它所给定的矩阵。这被[globalToLocal]和[localToGlobal]方法使用。
///
///  1.3.2 Hit Tests（命中测试）
///
///  render box的命中测试是由[hitTest]方法实现的，该方法的默认实现遵从[hitTestSelf]和[hitTestChildren]。在实现hit testing时，你可以重写后两个方法，或者忽略它们而直接重写[hitTest]。
///
///  [hitTest]方法本身被传入了一个[Offset]，如果该对象或它的一个child对象已经命中，则必须返回true（防止这个对象以下的对象被命中）；如果hit可以继续到这个对象以下的其他对象，则返回false。
///
///  对于每个child [RenderBox]，应该使用相同的[HitTestResult]参数调用child上的[hitTest]方法，并将该触摸点转化为child的坐标空间（与[applyPaintTransform]方法的方式相同）。
///  默认的实现推迟到[hitTestChildren]来调用child。[RenderBoxContainerDefaultsMixin]提供了一个[RenderBoxContainerDefaultsMixin.defaultHitTestChildren]方法，该方法假设child是轴对齐的，而不是变换的，
///  并且根据[parentData]的[BoxParentData.offset]字段定位的；更复杂的box可以相应地覆盖[hitTestChildren]。
///
///  如果对象被命中，那么它也应该使用[HitTestResult.add]将自己添加到作为[hitTest]方法参数的[HitTestResult]对象中。默认的实现会遵从[hitTestSelf]来确定box是否被命中。如果对象在children添加自己之前添加了自己，
///  那么就会像对象在children之上一样。如果它在children之后添加自己，那么它将被视为在children的下面（也就是above和below的关系，符合视觉效果）。
///  添加到[HitTestResult]对象的Entry应该使用[BoxHitTestEntry]类。随后，系统会按照添加的顺序对这些Entry进行遍历，对于每一个Entry，都会调用目标(即RenderBox)的[handleEvent]方法，传入[HitTestEntry]对象。
///
///  命中测试（hit test）不能依赖于发生过的绘制。
///
///  1.4 Semantics（语义）
///
///  为了让render box 能够被访问，实现[describeApproximatePaintClip]、[visitChildrenForSemantics]和[describeSemanticsConfiguration]方法。对于只影响布局(layout)的对象来说，默认的实现就足够了，
///  但代表交互式组件或信息（图表、文本、图像等）的节点应该提供更完整的实现。
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
///
abstract class RenderBox extends RenderObject {
  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  Map<_IntrinsicDimensionsCacheEntry, double>? _cachedIntrinsicDimensions;

  ///计算内在尺寸
  double _computeIntrinsicDimension(_IntrinsicDimension dimension,
      double argument, double computer(double argument)) {
    //增加cache的功能，具体的计算逻辑还是computer来实现
    bool shouldCache = true;
    if (shouldCache) {
      _cachedIntrinsicDimensions ??= <_IntrinsicDimensionsCacheEntry, double>{};
      return _cachedIntrinsicDimensions!.putIfAbsent(
        _IntrinsicDimensionsCacheEntry(dimension, argument),
        () => computer(argument),
      );
    }
    return computer(argument);
  }

  /// 返回这个盒子（box）的最小宽度，在这个尺寸内能正确绘制内容并且不会有裁剪。
  ///
  /// height参数可以给出一个具体的高度来假设。给定的高度可以是无限的，也就是说，要求的是无约
  /// 束环境下宽度。给定的高度绝对不应该是负值或空值。
  ///
  /// 这个函数只能在自己的孩子身上调用。调用这个函数可以将子代与父代结合起来，这样当子代的布
  /// 局发生变化时，父代就会得到通知（通过[markNeedsLayout]）。
  ///
  /// 调用这个函数代价是昂贵的，因为它可能导致O(N^2)的时间花费。
  ///
  /// 不要复写这个方法，相反的，实现[computeMinIntrinsicWidth]方法
  @mustCallSuper
  double getMinIntrinsicWidth(double height) {
    return _computeIntrinsicDimension(
        _IntrinsicDimension.minWidth, height, computeMinIntrinsicWidth);
  }

  /// Computes the value returned by [getMinIntrinsicWidth]. Do not call this
  /// function directly, instead, call [getMinIntrinsicWidth].
  ///
  /// Override in subclasses that implement [performLayout]. This method should
  /// return the minimum width that this box could be without failing to
  /// correctly paint its contents within itself, without clipping.
  ///
  /// If the layout algorithm is independent of the context (e.g. it always
  /// tries to be a particular size), or if the layout algorithm is
  /// width-in-height-out, or if the layout algorithm uses both the incoming
  /// width and height constraints (e.g. it always sizes itself to
  /// [BoxConstraints.biggest]), then the `height` argument should be ignored.
  ///
  /// If the layout algorithm is strictly height-in-width-out, or is
  /// height-in-width-out when the width is unconstrained, then the height
  /// argument is the height to use.
  ///
  /// The `height` argument will never be negative or null. It may be infinite.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// Be sure to set [debugCheckIntrinsicSizes] to true in your unit tests if
  /// you do override this method, which will add additional checks to help
  /// validate your implementation.
  ///
  /// ## Examples
  ///
  /// ### Text
  ///
  /// Text is the canonical example of a width-in-height-out algorithm. The
  /// `height` argument is therefore ignored.
  ///
  /// Consider the string "Hello World" The _maximum_ intrinsic width (as
  /// returned from [computeMaxIntrinsicWidth]) would be the width of the string
  /// with no line breaks.
  ///
  /// The minimum intrinsic width would be the width of the widest word, "Hello"
  /// or "World". If the text is rendered in an even narrower width, however, it
  /// might still not overflow. For example, maybe the rendering would put a
  /// line-break half-way through the words, as in "Hel⁞lo⁞Wor⁞ld". However,
  /// this wouldn't be a _correct_ rendering, and [computeMinIntrinsicWidth] is
  /// supposed to render the minimum width that the box could be without failing
  /// to _correctly_ paint the contents within itself.
  ///
  /// The minimum intrinsic _height_ for a given width smaller than the minimum
  /// intrinsic width could therefore be greater than the minimum intrinsic
  /// height for the minimum intrinsic width.
  ///
  /// ### Viewports (e.g. scrolling lists)
  ///
  /// Some render boxes are intended to clip their children. For example, the
  /// render box for a scrolling list might always size itself to its parents'
  /// size (or rather, to the maximum incoming constraints), regardless of the
  /// children's sizes, and then clip the children and position them based on
  /// the current scroll offset.
  ///
  /// The intrinsic dimensions in these cases still depend on the children, even
  /// though the layout algorithm sizes the box in a way independent of the
  /// children. It is the size that is needed to paint the box's contents (in
  /// this case, the children) _without clipping_ that matters.
  ///
  /// ### When the intrinsic dimensions cannot be known
  ///
  /// There are cases where render objects do not have an efficient way to
  /// compute their intrinsic dimensions. For example, it may be prohibitively
  /// expensive to reify and measure every child of a lazy viewport (viewports
  /// generally only instantiate the actually visible children), or the
  /// dimensions may be computed by a callback about which the render object
  /// cannot reason.
  ///
  /// In such cases, it may be impossible (or at least impractical) to actually
  /// return a valid answer. In such cases, the intrinsic functions should throw
  /// when [RenderObject.debugCheckingIntrinsics] is false and asserts are
  /// enabled, and return 0.0 otherwise.
  ///
  /// See the implementations of [LayoutBuilder] or [RenderViewportBase] for
  /// examples (in particular,
  /// [RenderViewportBase.debugThrowIfNotCheckingIntrinsics]).
  ///
  /// ### Aspect-ratio-driven boxes
  ///
  /// Some boxes always return a fixed size based on the constraints. For these
  /// boxes, the intrinsic functions should return the appropriate size when the
  /// incoming `height` or `width` argument is finite, treating that as a tight
  /// constraint in the respective direction and treating the other direction's
  /// constraints as unbounded. This is because the definitions of
  /// [computeMinIntrinsicWidth] and [computeMinIntrinsicHeight] are in terms of
  /// what the dimensions _could be_, and such boxes can only be one size in
  /// such cases.
  ///
  /// When the incoming argument is not finite, then they should return the
  /// actual intrinsic dimensions based on the contents, as any other box would.
  ///
  /// See also:
  ///
  ///  * [computeMaxIntrinsicWidth], which computes the smallest width beyond
  ///    which increasing the width never decreases the preferred height.
  @protected
  double computeMinIntrinsicWidth(double height) {
    return 0.0;
  }

  /// Returns the smallest width beyond which increasing the width never
  /// decreases the preferred height. The preferred height is the value that
  /// would be returned by [getMinIntrinsicHeight] for that width.
  ///
  /// The height argument may give a specific height to assume. The given height
  /// can be infinite, meaning that the intrinsic width in an unconstrained
  /// environment is being requested. The given height should never be negative
  /// or null.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// Calling this function is expensive as it can result in O(N^2) behavior.
  ///
  /// Do not override this method. Instead, implement
  /// [computeMaxIntrinsicWidth].
  @mustCallSuper
  double getMaxIntrinsicWidth(double height) {
    return _computeIntrinsicDimension(
        _IntrinsicDimension.maxWidth, height, computeMaxIntrinsicWidth);
  }

  /// Computes the value returned by [getMaxIntrinsicWidth]. Do not call this
  /// function directly, instead, call [getMaxIntrinsicWidth].
  ///
  /// Override in subclasses that implement [performLayout]. This should return
  /// the smallest width beyond which increasing the width never decreases the
  /// preferred height. The preferred height is the value that would be returned
  /// by [computeMinIntrinsicHeight] for that width.
  ///
  /// If the layout algorithm is strictly height-in-width-out, or is
  /// height-in-width-out when the width is unconstrained, then this should
  /// return the same value as [computeMinIntrinsicWidth] for the same height.
  ///
  /// Otherwise, the height argument should be ignored, and the returned value
  /// should be equal to or bigger than the value returned by
  /// [computeMinIntrinsicWidth].
  ///
  /// The `height` argument will never be negative or null. It may be infinite.
  ///
  /// The value returned by this method might not match the size that the object
  /// would actually take. For example, a [RenderBox] subclass that always
  /// exactly sizes itself using [BoxConstraints.biggest] might well size itself
  /// bigger than its max intrinsic size.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// Be sure to set [debugCheckIntrinsicSizes] to true in your unit tests if
  /// you do override this method, which will add additional checks to help
  /// validate your implementation.
  ///
  /// See also:
  ///
  ///  * [computeMinIntrinsicWidth], which has usage examples.
  @protected
  double computeMaxIntrinsicWidth(double height) {
    return 0.0;
  }

  /// Returns the minimum height that this box could be without failing to
  /// correctly paint its contents within itself, without clipping.
  ///
  /// The width argument may give a specific width to assume. The given width
  /// can be infinite, meaning that the intrinsic height in an unconstrained
  /// environment is being requested. The given width should never be negative
  /// or null.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// Calling this function is expensive as it can result in O(N^2) behavior.
  ///
  /// Do not override this method. Instead, implement
  /// [computeMinIntrinsicHeight].
  @mustCallSuper
  double getMinIntrinsicHeight(double width) {
    return _computeIntrinsicDimension(
        _IntrinsicDimension.minHeight, width, computeMinIntrinsicHeight);
  }

  /// Computes the value returned by [getMinIntrinsicHeight]. Do not call this
  /// function directly, instead, call [getMinIntrinsicHeight].
  ///
  /// Override in subclasses that implement [performLayout]. Should return the
  /// minimum height that this box could be without failing to correctly paint
  /// its contents within itself, without clipping.
  ///
  /// If the layout algorithm is independent of the context (e.g. it always
  /// tries to be a particular size), or if the layout algorithm is
  /// height-in-width-out, or if the layout algorithm uses both the incoming
  /// height and width constraints (e.g. it always sizes itself to
  /// [BoxConstraints.biggest]), then the `width` argument should be ignored.
  ///
  /// If the layout algorithm is strictly width-in-height-out, or is
  /// width-in-height-out when the height is unconstrained, then the width
  /// argument is the width to use.
  ///
  /// The `width` argument will never be negative or null. It may be infinite.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// Be sure to set [debugCheckIntrinsicSizes] to true in your unit tests if
  /// you do override this method, which will add additional checks to help
  /// validate your implementation.
  ///
  /// See also:
  ///
  ///  * [computeMinIntrinsicWidth], which has usage examples.
  ///  * [computeMaxIntrinsicHeight], which computes the smallest height beyond
  ///    which increasing the height never decreases the preferred width.
  @protected
  double computeMinIntrinsicHeight(double width) {
    return 0.0;
  }

  /// Returns the smallest height beyond which increasing the height never
  /// decreases the preferred width. The preferred width is the value that
  /// would be returned by [getMinIntrinsicWidth] for that height.
  ///
  /// The width argument may give a specific width to assume. The given width
  /// can be infinite, meaning that the intrinsic height in an unconstrained
  /// environment is being requested. The given width should never be negative
  /// or null.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// Calling this function is expensive as it can result in O(N^2) behavior.
  ///
  /// Do not override this method. Instead, implement
  /// [computeMaxIntrinsicHeight].
  @mustCallSuper
  double getMaxIntrinsicHeight(double width) {
    return _computeIntrinsicDimension(
        _IntrinsicDimension.maxHeight, width, computeMaxIntrinsicHeight);
  }

  /// Computes the value returned by [getMaxIntrinsicHeight]. Do not call this
  /// function directly, instead, call [getMaxIntrinsicHeight].
  ///
  /// Override in subclasses that implement [performLayout]. Should return the
  /// smallest height beyond which increasing the height never decreases the
  /// preferred width. The preferred width is the value that would be returned
  /// by [computeMinIntrinsicWidth] for that height.
  ///
  /// If the layout algorithm is strictly width-in-height-out, or is
  /// width-in-height-out when the height is unconstrained, then this should
  /// return the same value as [computeMinIntrinsicHeight] for the same width.
  ///
  /// Otherwise, the width argument should be ignored, and the returned value
  /// should be equal to or bigger than the value returned by
  /// [computeMinIntrinsicHeight].
  ///
  /// The `width` argument will never be negative or null. It may be infinite.
  ///
  /// The value returned by this method might not match the size that the object
  /// would actually take. For example, a [RenderBox] subclass that always
  /// exactly sizes itself using [BoxConstraints.biggest] might well size itself
  /// bigger than its max intrinsic size.
  ///
  /// If this algorithm depends on the intrinsic dimensions of a child, the
  /// intrinsic dimensions of that child should be obtained using the functions
  /// whose names start with `get`, not `compute`.
  ///
  /// This function should never return a negative or infinite value.
  ///
  /// Be sure to set [debugCheckIntrinsicSizes] to true in your unit tests if
  /// you do override this method, which will add additional checks to help
  /// validate your implementation.
  ///
  /// See also:
  ///
  ///  * [computeMinIntrinsicWidth], which has usage examples.
  @protected
  double computeMaxIntrinsicHeight(double width) {
    return 0.0;
  }

  Map<BoxConstraints, Size>? _cachedDryLayoutSizes;
  bool _computingThisDryLayout = false;

  /// Returns the [Size] that this [RenderBox] would like to be given the
  /// provided [BoxConstraints].
  ///
  /// The size returned by this method is guaranteed to be the same size that
  /// this [RenderBox] computes for itself during layout given the same
  /// constraints.
  ///
  /// This function should only be called on one's children. Calling this
  /// function couples the child with the parent so that when the child's layout
  /// changes, the parent is notified (via [markNeedsLayout]).
  ///
  /// This layout is called "dry" layout as opposed to the regular "wet" layout
  /// run performed by [performLayout] because it computes the desired size for
  /// the given constraints without changing any internal state.
  ///
  /// Calling this function is expensive as it can result in O(N^2) behavior.
  ///
  /// Do not override this method. Instead, implement [computeDryLayout].
  @mustCallSuper
  Size getDryLayout(BoxConstraints constraints) {
    bool shouldCache = true;
    if (shouldCache) {
      _cachedDryLayoutSizes ??= <BoxConstraints, Size>{};
      return _cachedDryLayoutSizes!
          .putIfAbsent(constraints, () => _computeDryLayout(constraints));
    }
    return _computeDryLayout(constraints);
  }

  Size _computeDryLayout(BoxConstraints constraints) {
    final Size result = computeDryLayout(constraints);
    return result;
  }

  /// Computes the value returned by [getDryLayout]. Do not call this
  /// function directly, instead, call [getDryLayout].
  ///
  /// Override in subclasses that implement [performLayout] or [performResize]
  /// or when setting [sizedByParent] to true without overriding
  /// [performResize]. This method should return the [Size] that this
  /// [RenderBox] would like to be given the provided [BoxConstraints].
  ///
  /// The size returned by this method must match the [size] that the
  /// [RenderBox] will compute for itself in [performLayout] (or
  /// [performResize], if [sizedByParent] is true).
  ///
  /// If this algorithm depends on the size of a child, the size of that child
  /// should be obtained using its [getDryLayout] method.
  ///
  /// This layout is called "dry" layout as opposed to the regular "wet" layout
  /// run performed by [performLayout] because it computes the desired size for
  /// the given constraints without changing any internal state.
  ///
  /// ### When the size cannot be known
  ///
  /// There are cases where render objects do not have an efficient way to
  /// compute their size without doing a full layout. For example, the size
  /// may depend on the baseline of a child (which is not available without
  /// doing a full layout), it may be computed by a callback about which the
  /// render object cannot reason, or the layout is so complex that it
  /// is simply impractical to calculate the size in an efficient way.
  ///
  /// In such cases, it may be impossible (or at least impractical) to actually
  /// return a valid answer. In such cases, the function should call
  /// [debugCannotComputeDryLayout] from within an assert and and return a dummy
  /// value of `const Size(0, 0)`.
  @protected
  Size computeDryLayout(BoxConstraints constraints) {
    return Size.zero;
  }

  static bool _dryLayoutCalculationValid = true;

  /// Called from [computeDryLayout] within an assert if the given [RenderBox]
  /// subclass does not support calculating a dry layout.
  ///
  /// When asserts are enabled and [debugCheckingIntrinsics] is not true, this
  /// method will either throw the provided [FlutterError] or it will create and
  /// throw a [FlutterError] with the provided `reason`. Otherwise, it will
  /// simply return true.
  ///
  /// One of the arguments has to be provided.
  ///
  /// See also:
  ///
  ///  * [computeDryLayout], which lists some reasons why it may not be feasible
  ///    to compute the dry layout.
  bool debugCannotComputeDryLayout({String? reason, FlutterError? error}) {
    return true;
  }

  /// Whether this render object has undergone layout and has a [size].
  bool get hasSize => _size != null;

  /// The size of this render box computed during layout.
  ///
  /// This value is stale whenever this object is marked as needing layout.
  /// During [performLayout], do not read the size of a child unless you pass
  /// true for parentUsesSize when calling the child's [layout] function.
  ///
  /// The size of a box should be set only during the box's [performLayout] or
  /// [performResize] functions. If you wish to change the size of a box outside
  /// of those functions, call [markNeedsLayout] instead to schedule a layout of
  /// the box.
  Size get size {
    return _size!;
  }

  Size? _size;

  /// Setting the size, in checked mode, triggers some analysis of the render box,
  /// as implemented by [debugAssertDoesMeetConstraints], including calling the intrinsic
  /// sizing methods and checking that they meet certain invariants.
  @protected
  set size(Size value) {
    _size = value;
  }

  /// Claims ownership of the given [Size].
  ///
  /// In debug mode, the [RenderBox] class verifies that [Size] objects obtained
  /// from other [RenderBox] objects are only used according to the semantics of
  /// the [RenderBox] protocol, namely that a [Size] from a [RenderBox] can only
  /// be used by its parent, and then only if `parentUsesSize` was set.
  ///
  /// Sometimes, a [Size] that can validly be used ends up no longer being valid
  /// over time. The common example is a [Size] taken from a child that is later
  /// removed from the parent. In such cases, this method can be called to first
  /// check whether the size can legitimately be used, and if so, to then create
  /// a new [Size] that can be used going forward, regardless of what happens to
  /// the original owner.
  Size debugAdoptSize(Size value) {
    Size result = value;
    return result;
  }

  @override
  Rect get semanticBounds => Offset.zero & size;

  @override
  void debugResetSize() {
    // updates the value of size._canBeUsedByParent if necessary
    size = size;
  }

  Map<TextBaseline, double?>? _cachedBaselines;
  static bool _debugDoingBaseline = false;
  static bool _debugSetDoingBaseline(bool value) {
    _debugDoingBaseline = value;
    return true;
  }

  /// Returns the distance from the y-coordinate of the position of the box to
  /// the y-coordinate of the first given baseline in the box's contents.
  ///
  /// Used by certain layout models to align adjacent boxes on a common
  /// baseline, regardless of padding, font size differences, etc. If there is
  /// no baseline, this function returns the distance from the y-coordinate of
  /// the position of the box to the y-coordinate of the bottom of the box
  /// (i.e., the height of the box) unless the caller passes true
  /// for `onlyReal`, in which case the function returns null.
  ///
  /// Only call this function after calling [layout] on this box. You
  /// are only allowed to call this from the parent of this box during
  /// that parent's [performLayout] or [paint] functions.
  ///
  /// When implementing a [RenderBox] subclass, to override the baseline
  /// computation, override [computeDistanceToActualBaseline].
  double? getDistanceToBaseline(TextBaseline baseline,
      {bool onlyReal = false}) {
    final double? result = getDistanceToActualBaseline(baseline);
    if (result == null && !onlyReal) return size.height;
    return result;
  }

  /// Calls [computeDistanceToActualBaseline] and caches the result.
  ///
  /// This function must only be called from [getDistanceToBaseline] and
  /// [computeDistanceToActualBaseline]. Do not call this function directly from
  /// outside those two methods.
  @protected
  @mustCallSuper
  double? getDistanceToActualBaseline(TextBaseline baseline) {
    _cachedBaselines ??= <TextBaseline, double?>{};
    _cachedBaselines!
        .putIfAbsent(baseline, () => computeDistanceToActualBaseline(baseline));
    return _cachedBaselines![baseline];
  }

  /// 返回盒子（box）y轴坐标位置到盒子内容基线的y轴的距离（如果有的话），否则为空。
  ///
  /// 不要直接调用这个函数。如果你需要调用[performLayout]或[paint]时知道子代的基线，请调
  /// 用[getDistanceToBaseline]。
  ///
  /// 子类应该重载这个方法来提供到其基线的距离。在实现该方法时，一般有三种策略：
  /// * 对于使用[ContainerRenderObjectMixin] child模型的类，可以考虑在
  ///   [RenderBoxContainerDefaultsMixin]类中混合使用[RenderBoxContainerDefaultsMixin.defaultComputeDistanceToFirstActualBaseline]。
  ///
  /// * 对于自己定义特定基线的类，直接返回值。
  ///
  /// Subclasses should override this method to supply the distances to their
  /// baselines. When implementing this method, there are generally three
  /// strategies:
  ///
  ///  * For classes that use the [ContainerRenderObjectMixin] child model,
  ///    consider mixing in the [RenderBoxContainerDefaultsMixin] class and
  ///    using
  ///    [RenderBoxContainerDefaultsMixin.defaultComputeDistanceToFirstActualBaseline].
  ///
  ///  * For classes that define a particular baseline themselves, return that
  ///    value directly.
  ///
  ///  * 对于有子类并希望推迟计算的类，在子类上调用[getDistanceToActualBaseline]
  ///    （不是内部实现[computeDistanceToActualBaseline]，也不是这个API的公共入口[getDistanceToBaseline]）。
  @protected
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return null;
  }

  /// The box constraints most recently received from the parent.
  @override
  BoxConstraints get constraints => super.constraints as BoxConstraints;

  @override
  void debugAssertDoesMeetConstraints() {}

  @override
  void markNeedsLayout() {
    if ((_cachedBaselines != null && _cachedBaselines!.isNotEmpty) ||
        (_cachedIntrinsicDimensions != null &&
            _cachedIntrinsicDimensions!.isNotEmpty) ||
        (_cachedDryLayoutSizes != null && _cachedDryLayoutSizes!.isNotEmpty)) {
      // If we have cached data, then someone must have used our data.
      // Since the parent will shortly be marked dirty, we can forget that they
      // used the baseline and/or intrinsic dimensions. If they use them again,
      // then we'll fill the cache again, and if we get dirty again, we'll
      // notify them again.
      _cachedBaselines?.clear();
      _cachedIntrinsicDimensions?.clear();
      _cachedDryLayoutSizes?.clear();
      if (parent is RenderObject) {
        markParentNeedsLayout();
        return;
      }
    }
    super.markNeedsLayout();
  }

  /// {@macro flutter.rendering.RenderObject.performResize}
  ///
  /// By default this method calls [getDryLayout] with the current
  /// [constraints]. Instead of overriding this method, consider overriding
  /// [computeDryLayout] (the backend implementation of [getDryLayout]).
  @override
  void performResize() {
    // default behavior for subclasses that have sizedByParent = true
    size = computeDryLayout(constraints);
    assert(size.isFinite);
  }

  @override
  void performLayout() {}

  /// 确定位于给定位置的渲染对象集。
  ///
  /// 如果该渲染对象或其子对象之一吸收了命中(防止命中此对象以下的对象)，则返回TRUE，
  /// 并将包含该点的任何渲染对象添加到给定的命中测试结果中。如果可以继续命中此对象以下的其他对象，则返回False。
  ///
  ///调用方负责将[Position]从全局坐标转换到相对于此[RenderBox]原点的位置。此[RenderBox]
  ///负责检查给定位置是否在其边界内。
  ///
  /// 如果需要转换，调用方需要调用[BoxHitTestResult.addWithPaintTransform]
  /// 、[BoxHitTestResult.addWithPaintOffset]或[BoxHitTestResult.addWithRawTransform]
  /// 在[HitTestResult]中记录所需的转换操作。这些方法还有助于将变换应用于`position`。
  ///
  /// 命中测试要求布局是最新的，但不要求绘画是最新的。这意味着渲染对象可以依赖于在[hitTest]中调用了[PerformLayout]，但不能依赖于调用了[Paint]。
  /// 例如，渲染对象可能是[RenderOpacity]对象的子对象，该对象在其不透明度为零时对其子对象调用[hitTest]，即使它不会[paint]其子对象(children)。
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // 判断是否包含坐标
    if (_size!.contains(position)) {
      // 如果child或者自己吸收了命中测试，则将自己添加到命中测试结果中
      if (hitTestChildren(result, position: position) ||
          hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }

  /// 即使未命中此渲染对象的子对象，但可以命中该渲染对象，则重写此方法。
  ///
  ///如果指定的`postion`应被视为此渲染对象上的命中，则返回TRUE。
  ///
  /// 调用方负责将[Position]从全局坐标转换到相对于此[RenderBox]原点的位置。
  /// 此[RenderBox]负责检查给定位置是否在其边界内。
  ///
  /// 由[hitTest]使用。如果覆写[hitTest]并且不调用此函数，则不需要实现此函数。
  ///
  @protected
  bool hitTestSelf(Offset position) => false;

  /// 覆写此方法以检查给定位置是否有children。
  ///
  /// 如果至少有一个child报告在指定位置命中，则Subclasses应返回True。
  ///
  ///通常情况下，应该以和绘制顺序相反的方向对child进行命中测试，以便在child重叠的位置进行命中测试，
  ///从而命中视觉上“在上面”的child(即，稍后进行绘制)。
  ///
  /// 如果需要转换，subclasses需要调用[BoxHitTestResult.addWithPaintTransform]、
  /// [BoxHitTestResult.addWithPaintOffset]或[BoxHitTestResult.addWithRawTransform]，
  /// 将需要的转换操作记录在[BoxHitTestResult]中。这些方法还有助于将转换应用于`position`。
  ///
  /// 由[hitTest]使用。如果覆写[hitTest]并且不调用此函数，则不需要实现此函数。
  ///
  @protected
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;

  /// Multiply the transform from the parent's coordinate system to this box's
  /// coordinate system into the given transform.
  ///
  /// This function is used to convert coordinate systems between boxes.
  /// Subclasses that apply transforms during painting should override this
  /// function to factor those transforms into the calculation.
  ///
  /// The [RenderBox] implementation takes care of adjusting the matrix for the
  /// position of the given child as determined during layout and stored on the
  /// child's [parentData] in the [BoxParentData.offset] field.
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    final Offset offset = childParentData.offset;
    transform.translate(offset.dx, offset.dy);
  }

  /// Convert the given point from the global coordinate system in logical pixels
  /// to the local coordinate system for this box.
  ///
  /// This method will un-project the point from the screen onto the widget,
  /// which makes it different from [MatrixUtils.transformPoint].
  ///
  /// If the transform from global coordinates to local coordinates is
  /// degenerate, this function returns [Offset.zero].
  ///
  /// If `ancestor` is non-null, this function converts the given point from the
  /// coordinate system of `ancestor` (which must be an ancestor of this render
  /// object) instead of from the global coordinate system.
  ///
  /// This method is implemented in terms of [getTransformTo].
  Offset globalToLocal(Offset point, {RenderObject? ancestor}) {
    // We want to find point (p) that corresponds to a given point on the
    // screen (s), but that also physically resides on the local render plane,
    // so that it is useful for visually accurate gesture processing in the
    // local space. For that, we can't simply transform 2D screen point to
    // the 3D local space since the screen space lacks the depth component |z|,
    // and so there are many 3D points that correspond to the screen point.
    // We must first unproject the screen point onto the render plane to find
    // the true 3D point that corresponds to the screen point.
    // We do orthogonal unprojection after undoing perspective, in local space.
    // The render plane is specified by renderBox offset (o) and Z axis (n).
    // Unprojection is done by finding the intersection of the view vector (d)
    // with the local X-Y plane: (o-s).dot(n) == (p-s).dot(n), (p-s) == |z|*d.
    final Matrix4 transform = getTransformTo(ancestor);
    final double det = transform.invert();
    if (det == 0.0) return Offset.zero;
    final Vector3 n = Vector3(0.0, 0.0, 1.0);
    final Vector3 i = transform.perspectiveTransform(Vector3(0.0, 0.0, 0.0));
    final Vector3 d =
        transform.perspectiveTransform(Vector3(0.0, 0.0, 1.0)) - i;
    final Vector3 s =
        transform.perspectiveTransform(Vector3(point.dx, point.dy, 0.0));
    final Vector3 p = s - d * (n.dot(s) / n.dot(d));
    return Offset(p.x, p.y);
  }

  /// Convert the given point from the local coordinate system for this box to
  /// the global coordinate system in logical pixels.
  ///
  /// If `ancestor` is non-null, this function converts the given point to the
  /// coordinate system of `ancestor` (which must be an ancestor of this render
  /// object) instead of to the global coordinate system.
  ///
  /// This method is implemented in terms of [getTransformTo]. If the transform
  /// matrix puts the given `point` on the line at infinity (for instance, when
  /// the transform matrix is the zero matrix), this method returns (NaN, NaN).
  Offset localToGlobal(Offset point, {RenderObject? ancestor}) {
    return MatrixUtils.transformPoint(getTransformTo(ancestor), point);
  }

  /// Returns a rectangle that contains all the pixels painted by this box.
  ///
  /// The paint bounds can be larger or smaller than [size], which is the amount
  /// of space this box takes up during layout. For example, if this box casts a
  /// shadow, that shadow might extend beyond the space allocated to this box
  /// during layout.
  ///
  /// The paint bounds are used to size the buffers into which this box paints.
  /// If the box attempts to paints outside its paint bounds, there might not be
  /// enough memory allocated to represent the box's visual appearance, which
  /// can lead to undefined behavior.
  ///
  /// The returned paint bounds are in the local coordinate system of this box.
  @override
  Rect get paintBounds => Offset.zero & size;

  /// Override this method to handle pointer events that hit this render object.
  ///
  /// For [RenderBox] objects, the `entry` argument is a [BoxHitTestEntry]. From this
  /// object you can determine the [PointerDownEvent]'s position in local coordinates.
  /// (This is useful because [PointerEvent.position] is in global coordinates.)
  ///
  /// If you override this, consider calling [debugHandleEvent] as follows, so
  /// that you can support [debugPaintPointersEnabled]:
  ///
  /// ```dart
  /// @override
  /// void handleEvent(PointerEvent event, HitTestEntry entry) {
  ///   assert(debugHandleEvent(event, entry));
  ///   // ... handle the event ...
  /// }
  /// ```
  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    super.handleEvent(event, entry);
  }

  int _debugActivePointers = 0;

  /// Implements the [debugPaintPointersEnabled] debugging feature.
  ///
  /// [RenderBox] subclasses that implement [handleEvent] should call
  /// [debugHandleEvent] from their [handleEvent] method, as follows:
  ///
  /// ```dart
  /// @override
  /// void handleEvent(PointerEvent event, HitTestEntry entry) {
  ///   assert(debugHandleEvent(event, entry));
  ///   // ... handle the event ...
  /// }
  /// ```
  ///
  /// If you call this for a [PointerDownEvent], make sure you also call it for
  /// the corresponding [PointerUpEvent] or [PointerCancelEvent].
  bool debugHandleEvent(PointerEvent event, HitTestEntry entry) {
    assert(() {
      if (debugPaintPointersEnabled) {
        if (event is PointerDownEvent) {
          _debugActivePointers += 1;
        } else if (event is PointerUpEvent || event is PointerCancelEvent) {
          _debugActivePointers -= 1;
        }
        markNeedsPaint();
      }
      return true;
    }());
    return true;
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled) debugPaintSize(context, offset);
      if (debugPaintBaselinesEnabled) debugPaintBaselines(context, offset);
      if (debugPaintPointersEnabled) debugPaintPointers(context, offset);
      return true;
    }());
  }

  /// In debug mode, paints a border around this render box.
  ///
  /// Called for every [RenderBox] when [debugPaintSizeEnabled] is true.
  @protected
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF00FFFF);
      context.canvas.drawRect((offset & size).deflate(0.5), paint);
      return true;
    }());
  }

  /// In debug mode, paints a line for each baseline.
  ///
  /// Called for every [RenderBox] when [debugPaintBaselinesEnabled] is true.
  @protected
  void debugPaintBaselines(PaintingContext context, Offset offset) {
    assert(() {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.25;
      Path path;
      // ideographic baseline
      final double? baselineI =
          getDistanceToBaseline(TextBaseline.ideographic, onlyReal: true);
      if (baselineI != null) {
        paint.color = const Color(0xFFFFD000);
        path = Path();
        path.moveTo(offset.dx, offset.dy + baselineI);
        path.lineTo(offset.dx + size.width, offset.dy + baselineI);
        context.canvas.drawPath(path, paint);
      }
      // alphabetic baseline
      final double? baselineA =
          getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);
      if (baselineA != null) {
        paint.color = const Color(0xFF00FF00);
        path = Path();
        path.moveTo(offset.dx, offset.dy + baselineA);
        path.lineTo(offset.dx + size.width, offset.dy + baselineA);
        context.canvas.drawPath(path, paint);
      }
      return true;
    }());
  }

  /// In debug mode, paints a rectangle if this render box has counted more
  /// pointer downs than pointer up events.
  ///
  /// Called for every [RenderBox] when [debugPaintPointersEnabled] is true.
  ///
  /// By default, events are not counted. For details on how to ensure that
  /// events are counted for your class, see [debugHandleEvent].
  @protected
  void debugPaintPointers(PaintingContext context, Offset offset) {}

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Size>('size', _size, missingIfNull: true));
  }
}
