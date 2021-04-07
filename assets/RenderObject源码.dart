///
/// 渲染树中的一个对象
///
/// [RenderObject]类族时渲染库的核心。
///
/// [RenderObject]有一个[parent]，并有一个名为[parentData]的插槽，父[RenderObject]可以在这个插槽中存储特关于child的
/// 数据，例如，child的位置。[RenderObject]类还实现了基本的布局和绘制协议。
///
/// 然而，[RenderObject]类并没有定义child模型（例如，一个节点是否有零个、一个或多个子节点）。它也没有定义坐标系（例如子节
/// 点是以笛卡尔坐标定位，还是以极坐标定位等等），也没有定义具体的布局协议（例如布局是宽进高出，还是约束大小出，或者父节点是
/// 在子节点布局之前还是之后设置子节点的大小和位置等等；或者实际上是否允许子节点读取父节点的[parentData]槽）。
///
/// [RenderBox]子类使用笛卡尔坐标系进行布局
///
/// 1. 如何写一个RenderObject的子类
///
/// 在大多数情况下，不应该直接继承自[RenderObject]，[RenderBox]会是一个更好的选择。然而，如果一个渲染对象不想使用笛卡尔坐标系，
/// 那么它确实应该直接继承[RenderObject]。这使得它可以通过使用约束[Constraints]的一个新的子类而不是使用[BoxConstraints]来定
/// 义自己的布局协议，并且可能使用一套全新的对象和值来表示输出的结果，而不仅仅是一个[Size]。这种灵活性的增加是以不能依赖[RenderBox]
/// 的功能为代价的。例如，[RenderBox]实现了一个内在的尺寸协议，它允许你在不完全布局的情况下测量一个child，这样一来，如果该child改
/// 变了尺寸，parent将重新布局（以考虑到child的新尺寸）。这是个微妙且容易出错的功能，要做好。
///
/// 如何编写[RenderBox]的大部分方面也适用于如何编写[RenderObject]，因此推荐阅读[RenderBox]的讨论。主要的区别是围绕着布局和命中测试，
/// 因为这些是[RenderBox]主要擅长的方面。
///
/// 1.1 Layout（布局）
/// 布局协议以[Constraints]的子类开始的。有关如何编写[Constraints]子类的更多信息，请参见[Constraints]的讨论。
///
/// [performLayout]方法应该获取[constraints]，并应用它们。布局算法的输出是在对象上设置的字段，这些字段描述了对象的几何形状，以便于parent的布局。
/// 例如，对于[RenderBox]，输出的是[RenderBox.size]字段。只有当parent在child上调用[layout]时指定`parentUsesSize`为true时，parent才应该读取这个输出。
///
/// render object上任何时候任何事的改变都会影响该对象的布局，都应该调用[markNeedsLayout]。
///
/// 1.2 Hit Testing（命中测试）
///
/// 命中测试比布局更开放。没有方法可以覆盖，希望你能提供一个方法。
///
/// 您的命中测试方法的一般行为应该与 [RenderBox] 的行为相似。主要的区别是，输入不需要是 [Offset]。当向[HitTestResult]添加Entry时，您也可以使用[HitTestEntry]
/// 的不同子类。当调用[handleEvent]方法时，添加到[HitTestResult]中的同一个对象将被传递进来，因此，无论新布局协议使用什么坐标系，它都可以被用来跟踪诸如命中的精确坐标等信息。
///
/// 1.3 从一个协议到另一个协议的适配
///
/// 一般来说，Flutter渲染对象树的根是一个[RenderView]。这个对象有一个单一的child，它必须是一个[RenderBox]。因此，如果你想在渲染树中拥有一个自定义的[RenderObject]子类，
/// 你有两个选择：要么你需要替换[RenderView]本身，要么你自己的类是[RenderBox]的child。后者是更常见的情况）。
///
/// 这个[RenderBox]子类将盒子协议转换为你自己类的协议。
///
/// 特别是，这意味着对于命中测试，应该覆盖[RenderBox.hitTest]，然后调用你的类中的任何方法进行命中测试。
///
/// 同样，应该重写[performLayout]来创建一个适合你自己类的[Constraints]对象，并将其传递给子类的[layout]方法。
///
/// 1.4 render object之间的布局交互
///
/// 一般来说，渲染对象的布局只应该依赖于其child布局的输出，只有在[layout]调用中`parentUsesSize`被设置为true的情况下才可以。
/// 此外，如果它被设置为true，父对象必须在子对象要渲染时调用子对象的[layout]，因为否则当子对象改变其布局输出时，父对象将不会得到通知。
///
/// 可以使用渲染对象的协议传递额外的信息。例如，在[RenderBox]协议中，你可以查询child的固有尺寸和基线。然而，如果这样做，那么child必须在
/// 附加信息发生变化的任何时候对父代调用[markNeedsLayout]，如果父代在最后的布局阶段使用了它。有关如何实现这一功能的例子，
/// 请参见[RenderBox.markNeedsLayout]方法。它覆盖了[RenderObject.markNeedsLayout]，所以如果父体已经查询了内在信息或基线信息，每当子
/// 体的几何体发生变化时，它就会被标记为脏。
///

abstract class RenderObject extends AbstractNode with DiagnosticableTreeMixin implements HitTestTarget {
  /// Initializes internal fields for subclasses.
  RenderObject() {
    _needsCompositing = isRepaintBoundary || alwaysNeedsCompositing;
  }

  /// Cause the entire subtree rooted at the given [RenderObject] to be marked
  /// dirty for layout, paint, etc, so that the effects of a hot reload can be
  /// seen, or so that the effect of changing a global debug flag (such as
  /// [debugPaintSizeEnabled]) can be applied.
  ///
  /// This is called by the [RendererBinding] in response to the
  /// `ext.flutter.reassemble` hook, which is used by development tools when the
  /// application code has changed, to cause the widget tree to pick up any
  /// changed implementations.
  ///
  /// This is expensive and should not be called except during development.
  ///
  /// See also:
  ///
  ///  * [BindingBase.reassembleApplication]
  void reassemble() {
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
    visitChildren((RenderObject child) {
      child.reassemble();
    });
  }

  // LAYOUT

  ///供父render object对象使用的数据
  ///
  /// parent data由布局（lay out）这个对象的render object （通常是这个对象在渲染树中的parent）使用，
  /// 用以存储与自己和任何其他碰巧知道数据确切含义的节点相关的信息。parent data对child是不透明的。
  ///
  /// * 除了在父节点上调用[setupParentData]设置parent data字段的值外，不能直接设置parent data字段的值。
  /// * parent data字段的数据可以在子节点添加到父节点之前，通过调用未来父节点上的[setupParentData]来设置。
  /// * 使用parent data的惯例取决于parent和child之间使用的布局协议。例如，在box布局中，父数据是完全不透明的，
  ///   但在扇形布局中，允许child读取parent data的某些字段。
  ParentData? parentData;

  /// Override to setup parent data correctly for your children.
  ///
  /// You can call this function to set up the parent data for child before the
  /// child is added to the parent's child list.
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! ParentData)
      child.parentData = ParentData();
  }

  /// 当子类（subclasses）决定收纳这个render object时，就会调用这个方法
  ///
  /// 仅供子类（subclasses）在改变他们的child列表时使用。在其他情况下调用该函数会导致树不一致，并可能导致崩溃。
  @override
  void adoptChild(RenderObject child) {
    setupParentData(child);
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
    super.adoptChild(child);
  }

  /// Called by subclasses when they decide a render object is no longer a child.
  ///
  /// Only for use by subclasses when changing their child lists. Calling this
  /// in other cases will lead to an inconsistent tree and probably cause crashes.
  @override
  void dropChild(RenderObject child) {
    child._cleanRelayoutBoundary();
    child.parentData!.detach();
    child.parentData = null;
    super.dropChild(child);
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  /// Calls visitor for each immediate child of this render object.
  ///
  /// Override in subclasses with children and call the visitor for each child.
  void visitChildren(RenderObjectVisitor visitor) { }

  @override
  PipelineOwner? get owner => super.owner as PipelineOwner?;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // If the node was dirtied in some way while unattached, make sure to add
    // it to the appropriate dirty list now that an owner is available
    if (_needsLayout && _relayoutBoundary != null) {
      // Don't enter this block if we've never laid out at all;
      // scheduleInitialLayout() will handle it
      _needsLayout = false;
      markNeedsLayout();
    }
    if (_needsCompositingBitsUpdate) {
      _needsCompositingBitsUpdate = false;
      markNeedsCompositingBitsUpdate();
    }
    if (_needsPaint && _layer != null) {
      // Don't enter this block if we've never painted at all;
      // scheduleInitialPaint() will handle it
      _needsPaint = false;
      markNeedsPaint();
    }
    if (_needsSemanticsUpdate && _semanticsConfiguration.isSemanticBoundary) {
      // Don't enter this block if we've never updated semantics at all;
      // scheduleInitialSemantics() will handle it
      _needsSemanticsUpdate = false;
      markNeedsSemanticsUpdate();
    }
  }


  bool _needsLayout = true;

  RenderObject? _relayoutBoundary;

  /// Whether [invokeLayoutCallback] for this render object is currently running.
  bool get debugDoingThisLayoutWithCallback => _doingThisLayoutWithCallback;
  bool _doingThisLayoutWithCallback = false;

  /// The layout constraints most recently supplied by the parent.
  ///
  /// If layout has not yet happened, accessing this getter will
  /// throw a [StateError] exception.
  @protected
  Constraints get constraints {
    if (_constraints == null)
      throw StateError('A RenderObject does not have any constraints before it has been laid out.');
    return _constraints!;
  }
  Constraints? _constraints;

  /// Mark this render object's layout information as dirty, and either register
  /// this object with its [PipelineOwner], or defer to the parent, depending on
  /// whether this object is a relayout boundary or not respectively.
  ///
  /// ## Background
  ///
  /// Rather than eagerly updating layout information in response to writes into
  /// a render object, we instead mark the layout information as dirty, which
  /// schedules a visual update. As part of the visual update, the rendering
  /// pipeline updates the render object's layout information.
  ///
  /// This mechanism batches the layout work so that multiple sequential writes
  /// are coalesced, removing redundant computation.
  ///
  /// If a render object's parent indicates that it uses the size of one of its
  /// render object children when computing its layout information, this
  /// function, when called for the child, will also mark the parent as needing
  /// layout. In that case, since both the parent and the child need to have
  /// their layout recomputed, the pipeline owner is only notified about the
  /// parent; when the parent is laid out, it will call the child's [layout]
  /// method and thus the child will be laid out as well.
  ///
  /// Once [markNeedsLayout] has been called on a render object,
  /// [debugNeedsLayout] returns true for that render object until just after
  /// the pipeline owner has called [layout] on the render object.
  ///
  /// ## Special cases
  ///
  /// Some subclasses of [RenderObject], notably [RenderBox], have other
  /// situations in which the parent needs to be notified if the child is
  /// dirtied (e.g., if the child's intrinsic dimensions or baseline changes).
  /// Such subclasses override markNeedsLayout and either call
  /// `super.markNeedsLayout()`, in the normal case, or call
  /// [markParentNeedsLayout], in the case where the parent needs to be laid out
  /// as well as the child.
  ///
  /// If [sizedByParent] has changed, calls
  /// [markNeedsLayoutForSizedByParentChange] instead of [markNeedsLayout].
  void markNeedsLayout() {
    assert(_debugCanPerformMutations);
    if (_needsLayout) {
      assert(_debugSubtreeRelayoutRootAlreadyMarkedNeedsLayout());
      return;
    }
    assert(_relayoutBoundary != null);
    if (_relayoutBoundary != this) {
      markParentNeedsLayout();
    } else {
      _needsLayout = true;
      if (owner != null) {
        assert(() {
          if (debugPrintMarkNeedsLayoutStacks)
            debugPrintStack(label: 'markNeedsLayout() called for $this');
          return true;
        }());
        owner!._nodesNeedingLayout.add(this);
        owner!.requestVisualUpdate();
      }
    }
  }

  /// Mark this render object's layout information as dirty, and then defer to
  /// the parent.
  ///
  /// This function should only be called from [markNeedsLayout] or
  /// [markNeedsLayoutForSizedByParentChange] implementations of subclasses that
  /// introduce more reasons for deferring the handling of dirty layout to the
  /// parent. See [markNeedsLayout] for details.
  ///
  /// Only call this if [parent] is not null.
  @protected
  void markParentNeedsLayout() {
    _needsLayout = true;
    assert(this.parent != null);
    final RenderObject parent = this.parent! as RenderObject;
    if (!_doingThisLayoutWithCallback) {
      parent.markNeedsLayout();
    } else {
      assert(parent._debugDoingThisLayout);
    }
    assert(parent == this.parent);
  }

  /// Mark this render object's layout information as dirty (like
  /// [markNeedsLayout]), and additionally also handle any necessary work to
  /// handle the case where [sizedByParent] has changed value.
  ///
  /// This should be called whenever [sizedByParent] might have changed.
  ///
  /// Only call this if [parent] is not null.
  void markNeedsLayoutForSizedByParentChange() {
    markNeedsLayout();
    markParentNeedsLayout();
  }

  void _cleanRelayoutBoundary() {
    if (_relayoutBoundary != this) {
      _relayoutBoundary = null;
      _needsLayout = true;
      visitChildren(_cleanChildRelayoutBoundary);
    }
  }

  // Reduces closure allocation for visitChildren use cases.
  static void _cleanChildRelayoutBoundary(RenderObject child) {
    child._cleanRelayoutBoundary();
  }

  /// Bootstrap the rendering pipeline by scheduling the very first layout.
  ///
  /// Requires this render object to be attached and that this render object
  /// is the root of the render tree.
  ///
  /// See [RenderView] for an example of how this function is used.
  void scheduleInitialLayout() {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner!._debugDoingLayout);
    assert(_relayoutBoundary == null);
    _relayoutBoundary = this;
    assert(() {
      _debugCanParentUseSize = false;
      return true;
    }());
    owner!._nodesNeedingLayout.add(this);
  }

  void _layoutWithoutResize() {
    assert(_relayoutBoundary == this);
    RenderObject? debugPreviousActiveLayout;
    assert(!_debugMutationsLocked);
    assert(!_doingThisLayoutWithCallback);
    assert(_debugCanParentUseSize != null);
    assert(() {
      _debugMutationsLocked = true;
      _debugDoingThisLayout = true;
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = this;
      if (debugPrintLayouts)
        debugPrint('Laying out (without resize) $this');
      return true;
    }());
    try {
      performLayout();
      markNeedsSemanticsUpdate();
    } catch (e, stack) {
      _debugReportException('performLayout', e, stack);
    }
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugMutationsLocked = false;
      return true;
    }());
    _needsLayout = false;
    markNeedsPaint();
  }

  /// 计算该渲染对象的布局
  ///
  ///这个方法是parent要它的children更新布局信息的主要切入点。parent传递一个约束对象，
  ///告知children哪些布局是允许的。children必须遵守给定的约束条件。
  ///
  /// 如果父代读取子代布局期间计算的信息，父代必须为`parentUsesSize`传递true。在这种
  /// 情况下，只要子代被标记为需要布局，父代就会被标记为需要布局，因为父代的布局信息取决
  /// 于子代的布局信息。如果父代使用`parentUsesSize`的默认值(false)，子代可以改变其布
  /// 局信息(受给定约束)，而不通知父代。
  ///
  /// 子类不应该直接覆盖[layout]方法。相反，它们应该覆盖 [performResize] 和/或
  /// [performLayout]。[layout]方法将实际工作委托给[performResize]和[performLayout]。
  ///
  /// 父类的[performLayout]方法应该无条件地调用其所有子类的[layout]。如果子代不需要做任何
  /// 工作来更新它的布局信息，那么[layout]方法有责任（就像这里实现的）提前返回。
  void layout(Constraints constraints, { bool parentUsesSize = false }) {

    RenderObject? relayoutBoundary;

    if (!parentUsesSize        //parent不使用child的size
        || sizedByParent       //size是否是唯一根据约束来计算的，这种情况下，约束不变，那么size就不需要在计算
        || constraints.isTight //严格的约束
        || parent is! RenderObject) {//parent不是RenderObject
      //满足上面这些条件之一，那么当前对象就是布局边界
      relayoutBoundary = this;
    } else {
      //循着parent向上找到布局边界
      relayoutBoundary = (parent! as RenderObject)._relayoutBoundary;
    }
    if (!_needsLayout                               //不需要布局
        && constraints == _constraints              //约束约束不变
        && relayoutBoundary == _relayoutBoundary) { //布局边界不变
      //都满足上面的条件，那么就直接退出，不需要布局
      return;
    }
    //记录布局约束
    _constraints = constraints;

    //本次布局边界和上一次的布局边界不一样了
    if (_relayoutBoundary != null && relayoutBoundary != _relayoutBoundary) {
      // 本地的布局边界发生了变化，一定要通知孩子，以防他们也需要更新。
      // 否则，他们以后会搞不清自己的实际布局边界是什么。
      // 其实所做的工作就是递归的清除child的布局边界，并标记为需要重新布局：
      // * _relayoutBoundary = null;
      // * _needsLayout = true;
      visitChildren(_cleanChildRelayoutBoundary);
    }
    //记录布局边界
    _relayoutBoundary = relayoutBoundary;

    if (sizedByParent) {
      //只需要约束条件就能计算尺寸Size的情况（对比的情况就是计算Size还需要child的布局信息）
      try {
        //在该方法里，使用约束条件进行尺寸的计算
        performResize();
      } catch (e, stack) {
      }
    }

    try {
      //计算布局，这里可能需要child的布局信息才能计算该对象的布局
      performLayout();
      //更新语义
      markNeedsSemanticsUpdate();
    } catch (e, stack) {
    }
    _needsLayout = false;
    //标记需要绘制
    markNeedsPaint();
  }

  /// If a subclass has a "size" (the state controlled by `parentUsesSize`,
  /// whatever it is in the subclass, e.g. the actual `size` property of
  /// [RenderBox]), and the subclass verifies that in checked mode this "size"
  /// property isn't used when [debugCanParentUseSize] isn't set, then that
  /// subclass should override [debugResetSize] to reapply the current values of
  /// [debugCanParentUseSize] to that state.
  @protected
  void debugResetSize() { }

  /// Whether the constraints are the only input to the sizing algorithm (in
  /// particular, child nodes have no impact).
  ///
  /// Returning false is always correct, but returning true can be more
  /// efficient when computing the size of this render object because we don't
  /// need to recompute the size if the constraints don't change.
  ///
  /// Typically, subclasses will always return the same value. If the value can
  /// change, then, when it does change, the subclass should make sure to call
  /// [markNeedsLayoutForSizedByParentChange].
  ///
  /// Subclasses that return true must not change the dimensions of this render
  /// object in [performLayout]. Instead, that work should be done by
  /// [performResize] or - for subclasses of [RenderBox] - in
  /// [RenderBox.computeDryLayout].
  @protected
  bool get sizedByParent => false;

  ///仅使用约束条件计算渲染对象的size。
  ///
  ///不要直接调用这个函数，可以调用[layout]。当这个渲染对象在布局过程中实际有工作要做时，这
  ///个函数就会被[layout]调用。父对象提供的布局约束可以通过[constraints] getter方法获得。
  ///
  /// 只有当[sizedByParent] 为true，这个方法才会被调用
  ///
  /// 将[sizedByParent]设置为true的子类应该覆盖这个方法来计算它们的大小。[RenderBox]的子
  /// 类应该考虑覆盖[RenderBox.computeDryLayout]来代替。
  @protected
  void performResize();

  ///为该渲染对象计算布局
  ///
  ///不要直接调用这个函数，可以调用[layout]。当这个渲染对象在布局过程中实际有工作要做时，这
  ///个函数就会被[layout]调用。父对象提供的布局约束可以通过[constraints] getter方法获得。
  ///
  /// 如果 [sizedByParent] 为true，那么这个函数实际上不应该改变这个渲染对象的尺寸。相反，
  /// 这项工作应该由 [performResize] 来完成。如果 [sizedByParent] 为false，那么这个函
  /// 数应该既改变这个渲染对象的尺寸，又指示它的子代进行布局。
  ///
  /// 在实现这个函数时，你必须对你的每个子代调用[layout]，如果你的布局信息依赖于你子代的布
  /// 局信息，则传递的parentUsesSize为true。为parentUsesSize传递true可以确保如果子代进
  /// 行布局，这个渲染对象将重新进行布局。否则，子代可以在不通知这个渲染对象的情况下改变其布
  /// 局信息。
  @protected
  void performLayout();

  ///
  /// 允许对这个对象的子列表（和任何后裔）以及渲染树中与这个对象相同的[PipelineOwner]所拥
  /// 有的任何其他脏节点进行突变。`callback`参数是同步调用的，只允许在该回调执行期间进行突变。
  ///
  /// 它的存在是为了允许在布局过程中按需建立子列表（例如基于对象的大小），并使节点能够在此过程
  /// 中在树上移动（例如处理[GlobalKey]reparenting），同时仍然确保任何特定的节点每帧只布局一次。
  ///
  /// 调用这个函数会禁用一些旨在捕捉可能的错误的断言。因此，一般不鼓励使用这个函数。
  ///
  /// 这个函数只有在布局（layout）期间才能调用
  @protected
  void invokeLayoutCallback<T extends Constraints>(LayoutCallback<T> callback) {
    _doingThisLayoutWithCallback = true;
    try {
      owner!._enableMutationsToDirtySubtrees(() { callback(constraints as T); });
    } finally {
      _doingThisLayoutWithCallback = false;
    }
  }

  /// Rotate this render object (not yet implemented).
  void rotate({
    int? oldAngle, // 0..3
    int? newAngle, // 0..3
    Duration? time,
  }) { }

  // when the parent has rotated (e.g. when the screen has been turned
  // 90 degrees), immediately prior to layout() being called for the
  // new dimensions, rotate() is called with the old and new angles.
  // The next time paint() is called, the coordinate space will have
  // been rotated N quarter-turns clockwise, where:
  //    N = newAngle-oldAngle
  // ...but the rendering is expected to remain the same, pixel for
  // pixel, on the output device. Then, the layout() method or
  // equivalent will be called.


  // PAINTING


  /// Whether this render object always needs compositing.
  ///
  /// Override this in subclasses to indicate that your paint function always
  /// creates at least one composited layer. For example, videos should return
  /// true if they use hardware decoders.
  ///
  /// You must call [markNeedsCompositingBitsUpdate] if the value of this getter
  /// changes. (This is implied when [adoptChild] or [dropChild] are called.)
  @protected
  bool get alwaysNeedsCompositing => false;

  /// The compositing layer that this render object uses to repaint.
  ///
  /// If this render object is not a repaint boundary, it is the responsibility
  /// of the [paint] method to populate this field. If [needsCompositing] is
  /// true, this field may be populated with the root-most layer used by the
  /// render object implementation. When repainting, instead of creating a new
  /// layer the render object may update the layer stored in this field for better
  /// performance. It is also OK to leave this field as null and create a new
  /// layer on every repaint, but without the performance benefit. If
  /// [needsCompositing] is false, this field must be set to null either by
  /// never populating this field, or by setting it to null when the value of
  /// [needsCompositing] changes from true to false.
  ///
  /// If this render object is a repaint boundary, the framework automatically
  /// creates an [OffsetLayer] and populates this field prior to calling the
  /// [paint] method. The [paint] method must not replace the value of this
  /// field.
  @protected
  ContainerLayer? get layer {
    assert(!isRepaintBoundary || (_layer == null || _layer is OffsetLayer));
    return _layer;
  }

  @protected
  set layer(ContainerLayer? newLayer) {
    assert(
    !isRepaintBoundary,
    'Attempted to set a layer to a repaint boundary render object.\n'
        'The framework creates and assigns an OffsetLayer to a repaint '
        'boundary automatically.',
    );
    _layer = newLayer;
  }
  ContainerLayer? _layer;



  bool _needsCompositingBitsUpdate = false; // set to true when a child is added
  /// Mark the compositing state for this render object as dirty.
  ///
  /// This is called to indicate that the value for [needsCompositing] needs to
  /// be recomputed during the next [PipelineOwner.flushCompositingBits] engine
  /// phase.
  ///
  /// When the subtree is mutated, we need to recompute our
  /// [needsCompositing] bit, and some of our ancestors need to do the
  /// same (in case ours changed in a way that will change theirs). To
  /// this end, [adoptChild] and [dropChild] call this method, and, as
  /// necessary, this method calls the parent's, etc, walking up the
  /// tree to mark all the nodes that need updating.
  ///
  /// This method does not schedule a rendering frame, because since
  /// it cannot be the case that _only_ the compositing bits changed,
  /// something else will have scheduled a frame for us.
  void markNeedsCompositingBitsUpdate() {
    if (_needsCompositingBitsUpdate)
      return;
    _needsCompositingBitsUpdate = true;
    if (parent is RenderObject) {
      final RenderObject parent = this.parent! as RenderObject;
      if (parent._needsCompositingBitsUpdate)
        return;
      if (!isRepaintBoundary && !parent.isRepaintBoundary) {
        parent.markNeedsCompositingBitsUpdate();
        return;
      }
    }
    // parent is fine (or there isn't one), but we are dirty
    if (owner != null)
      owner!._nodesNeedingCompositingBitsUpdate.add(this);
  }

  late bool _needsCompositing; // initialized in the constructor
  /// Whether we or one of our descendants has a compositing layer.
  ///
  /// If this node needs compositing as indicated by this bit, then all ancestor
  /// nodes will also need compositing.
  ///
  /// Only legal to call after [PipelineOwner.flushLayout] and
  /// [PipelineOwner.flushCompositingBits] have been called.
  bool get needsCompositing {
    assert(!_needsCompositingBitsUpdate); // make sure we don't use this bit when it is dirty
    return _needsCompositing;
  }

  void _updateCompositingBits() {
    if (!_needsCompositingBitsUpdate)
      return;
    final bool oldNeedsCompositing = _needsCompositing;
    _needsCompositing = false;
    visitChildren((RenderObject child) {
      child._updateCompositingBits();
      if (child.needsCompositing)
        _needsCompositing = true;
    });
    if (isRepaintBoundary || alwaysNeedsCompositing)
      _needsCompositing = true;
    if (oldNeedsCompositing != _needsCompositing)
      markNeedsPaint();
    _needsCompositingBitsUpdate = false;
  }

  bool _needsPaint = true;

  /// 标记此渲染对象的视觉外观已改变
  ///
  ///  我们没有马上更新这个渲染对象的显示以响应写入，而是将渲染对象标记为需要绘制，从而安排
  ///  视觉更新。作为视觉更新的一部分，渲染管道将给这个渲染对象一个更新其显示的机会。
  ///
  /// 这种机制将绘制工作分批进行，去除多余的计算。
  ///
  /// 一旦在渲染对象上调用了[markNeedsPaint]，[debugNeedsPaint]就会为该渲染对象返回true，
  /// 直到管道所有者在渲染对象上调用[paint]之后。
  ///
  /// See also:
  ///
  ///  * [RepaintBoundary], 限制[markNeedsPaint] 标记为dirty的节点数。
  void markNeedsPaint() {
    //已标记过，直接退出
    if (_needsPaint)
      return;
    //标记为需要绘制
    _needsPaint = true;

    if (isRepaintBoundary) {
      //如果我们始终有自己的图层，那么我们就可以只重绘自己，而不涉及其他节点。
      if (owner != null) {
        owner!._nodesNeedingPaint.add(this);
        owner!.requestVisualUpdate();
      }
    } else if (parent is RenderObject) {
      //循着parent向上标记为需要绘制的
      final RenderObject parent = this.parent! as RenderObject;
      parent.markNeedsPaint();
    } else {
      // 如果我们是渲染树的根(可能是RenderView)，那么我们就必须绘制自己，因为没有人可以绘
      // 制我们。在这种情况下，我们不会把自己添加到_nodesNeedingPaint中，因为无论如何都会
      // 告诉根部要绘制。
      if (owner != null)
        owner!.requestVisualUpdate();
    }
  }

  // Called when flushPaint() tries to make us paint but our layer is detached.
  // To make sure that our subtree is repainted when it's finally reattached,
  // even in the case where some ancestor layer is itself never marked dirty, we
  // have to mark our entire detached subtree as dirty and needing to be
  // repainted. That way, we'll eventually be repainted.
  void _skippedPaintingOnLayer() {
    assert(attached);
    assert(isRepaintBoundary);
    assert(_needsPaint);
    assert(_layer != null);
    assert(!_layer!.attached);
    AbstractNode? node = parent;
    while (node is RenderObject) {
      if (node.isRepaintBoundary) {
        if (node._layer == null)
          break; // looks like the subtree here has never been painted. let it handle itself.
        if (node._layer!.attached)
          break; // it's the one that detached us, so it's the one that will decide to repaint us.
        node._needsPaint = true;
      }
      node = node.parent;
    }
  }

  /// Bootstrap the rendering pipeline by scheduling the very first paint.
  ///
  /// Requires that this render object is attached, is the root of the render
  /// tree, and has a composited layer.
  ///
  /// See [RenderView] for an example of how this function is used.
  void scheduleInitialPaint(ContainerLayer rootLayer) {
    assert(rootLayer.attached);
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner!._debugDoingPaint);
    assert(isRepaintBoundary);
    assert(_layer == null);
    _layer = rootLayer;
    assert(_needsPaint);
    owner!._nodesNeedingPaint.add(this);
  }

  /// Replace the layer. This is only valid for the root of a render
  /// object subtree (whatever object [scheduleInitialPaint] was
  /// called on).
  ///
  /// This might be called if, e.g., the device pixel ratio changed.
  void replaceRootLayer(OffsetLayer rootLayer) {
    assert(rootLayer.attached);
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner!._debugDoingPaint);
    assert(isRepaintBoundary);
    assert(_layer != null); // use scheduleInitialPaint the first time
    _layer!.detach();
    _layer = rootLayer;
    markNeedsPaint();
  }

  /// 使用PaintingContext进行绘制
  void _paintWithContext(PaintingContext context, Offset offset) {
    //如果我们仍然需要布局，那么这意味着我们在布局阶段被跳过，因此不需要绘制。我们可能还不知道（
    // 也就是说，我们的图层可能还没有被分离），因为在布局阶段跳过我们的同一个节点在树的上方（很明显），因
    // 此可能还没有机会绘制（因为树的绘制顺序是相反的）。特别是如果他们有不同的图层，这种情况会发生，因为
    // 我们之间有一个重新绘制的边界。
    if (_needsLayout)
      return;
    _needsPaint = false;
    try {
      paint(context, offset);
    } catch (e, stack) {
      _debugReportException('paint', e, stack);
    }
  }

  /// An estimate of the bounds within which this render object will paint.
  /// Useful for debugging flags such as [debugPaintLayerBordersEnabled].
  ///
  /// These are also the bounds used by [showOnScreen] to make a [RenderObject]
  /// visible on screen.
  Rect get paintBounds;

  ///
  ///
  /// 在给定的偏移量下，将此渲染对象绘制到给定的context中。
  ///
  /// 子类（Subclasse）应该重写这个方法来为自己提供一个视觉外观。渲染对象的局部坐标系与上下
  /// 文画布的坐标系进行轴对齐，渲染对象的局部原点（即x=0和y=0）被放置在上下文画布的给定偏移处。
  ///
  ///不要直接调用这个函数。如果你想绘制自己，请调用[markNeedsPaint]来安排对这个函数的调用。如
  ///果你想画你的一个child，在给定的`context`上调用[PaintingContext.paintChild]。
  ///
  /// 当绘制你的一个child时，上下文（context）持有的当前画布可能会改变，因为在绘制子代（child）
  /// 之前和之后的绘制操作可能需要记录在不同的合成层上。
  void paint(PaintingContext context, Offset offset) { }

  /// Applies the transform that would be applied when painting the given child
  /// to the given matrix.
  ///
  /// Used by coordinate conversion functions to translate coordinates local to
  /// one render object into coordinates local to another render object.
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    assert(child.parent == this);
  }

  /// Applies the paint transform up the tree to `ancestor`.
  ///
  /// Returns a matrix that maps the local paint coordinate system to the
  /// coordinate system of `ancestor`.
  ///
  /// If `ancestor` is null, this method returns a matrix that maps from the
  /// local paint coordinate system to the coordinate system of the
  /// [PipelineOwner.rootNode]. For the render tree owner by the
  /// [RendererBinding] (i.e. for the main render tree displayed on the device)
  /// this means that this method maps to the global coordinate system in
  /// logical pixels. To get physical pixels, use [applyPaintTransform] from the
  /// [RenderView] to further transform the coordinate.
  Matrix4 getTransformTo(RenderObject? ancestor) {
    final bool ancestorSpecified = ancestor != null;
    assert(attached);
    if (ancestor == null) {
      final AbstractNode? rootNode = owner!.rootNode;
      if (rootNode is RenderObject)
        ancestor = rootNode;
    }
    final List<RenderObject> renderers = <RenderObject>[];
    for (RenderObject renderer = this; renderer != ancestor; renderer = renderer.parent! as RenderObject) {
      assert(renderer != null); // Failed to find ancestor in parent chain.
      renderers.add(renderer);
    }
    if (ancestorSpecified)
      renderers.add(ancestor!);
    final Matrix4 transform = Matrix4.identity();
    for (int index = renderers.length - 1; index > 0; index -= 1) {
      renderers[index].applyPaintTransform(renderers[index - 1], transform);
    }
    return transform;
  }


  /// Returns a rect in this object's coordinate system that describes
  /// the approximate bounding box of the clip rect that would be
  /// applied to the given child during the paint phase, if any.
  ///
  /// Returns null if the child would not be clipped.
  ///
  /// This is used in the semantics phase to avoid including children
  /// that are not physically visible.
  Rect? describeApproximatePaintClip(covariant RenderObject child) => null;

  /// Returns a rect in this object's coordinate system that describes
  /// which [SemanticsNode]s produced by the `child` should be included in the
  /// semantics tree. [SemanticsNode]s from the `child` that are positioned
  /// outside of this rect will be dropped. Child [SemanticsNode]s that are
  /// positioned inside this rect, but outside of [describeApproximatePaintClip]
  /// will be included in the tree marked as hidden. Child [SemanticsNode]s
  /// that are inside of both rect will be included in the tree as regular
  /// nodes.
  ///
  /// This method only returns a non-null value if the semantics clip rect
  /// is different from the rect returned by [describeApproximatePaintClip].
  /// If the semantics clip rect and the paint clip rect are the same, this
  /// method returns null.
  ///
  /// A viewport would typically implement this method to include semantic nodes
  /// in the semantics tree that are currently hidden just before the leading
  /// or just after the trailing edge. These nodes have to be included in the
  /// semantics tree to implement implicit accessibility scrolling on iOS where
  /// the viewport scrolls implicitly when moving the accessibility focus from
  /// a the last visible node in the viewport to the first hidden one.
  ///
  /// See also:
  ///
  /// * [RenderViewportBase.cacheExtent], used by viewports to extend their
  ///   semantics clip beyond their approximate paint clip.
  Rect? describeSemanticsClip(covariant RenderObject? child) => null;

  // SEMANTICS

  /// Bootstrap the semantics reporting mechanism by marking this node
  /// as needing a semantics update.
  ///
  /// Requires that this render object is attached, and is the root of
  /// the render tree.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void scheduleInitialSemantics() {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner!._debugDoingSemantics);
    assert(_semantics == null);
    assert(_needsSemanticsUpdate);
    assert(owner!._semanticsOwner != null);
    owner!._nodesNeedingSemantics.add(this);
    owner!.requestVisualUpdate();
  }

  /// Report the semantics of this node, for example for accessibility purposes.
  ///
  /// This method should be overridden by subclasses that have interesting
  /// semantic information.
  ///
  /// The given [SemanticsConfiguration] object is mutable and should be
  /// annotated in a manner that describes the current state. No reference
  /// should be kept to that object; mutating it outside of the context of the
  /// [describeSemanticsConfiguration] call (for example as a result of
  /// asynchronous computation) will at best have no useful effect and at worse
  /// will cause crashes as the data will be in an inconsistent state.
  ///
  /// {@tool snippet}
  ///
  /// The following snippet will describe the node as a button that responds to
  /// tap actions.
  ///
  /// ```dart
  /// abstract class SemanticButtonRenderObject extends RenderObject {
  ///   @override
  ///   void describeSemanticsConfiguration(SemanticsConfiguration config) {
  ///     super.describeSemanticsConfiguration(config);
  ///     config
  ///       ..onTap = _handleTap
  ///       ..label = 'I am a button'
  ///       ..isButton = true;
  ///   }
  ///
  ///   void _handleTap() {
  ///     // Do something.
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  @protected
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    // Nothing to do by default.
  }

  /// Sends a [SemanticsEvent] associated with this render object's [SemanticsNode].
  ///
  /// If this render object has no semantics information, the first parent
  /// render object with a non-null semantic node is used.
  ///
  /// If semantics are disabled, no events are dispatched.
  ///
  /// See [SemanticsNode.sendEvent] for a full description of the behavior.
  void sendSemanticsEvent(SemanticsEvent semanticsEvent) {
    if (owner!.semanticsOwner == null)
      return;
    if (_semantics != null && !_semantics!.isMergedIntoParent) {
      _semantics!.sendEvent(semanticsEvent);
    } else if (parent != null) {
      final RenderObject renderParent = parent! as RenderObject;
      renderParent.sendSemanticsEvent(semanticsEvent);
    }
  }

  // Use [_semanticsConfiguration] to access.
  SemanticsConfiguration? _cachedSemanticsConfiguration;

  SemanticsConfiguration get _semanticsConfiguration {
    if (_cachedSemanticsConfiguration == null) {
      _cachedSemanticsConfiguration = SemanticsConfiguration();
      describeSemanticsConfiguration(_cachedSemanticsConfiguration!);
    }
    return _cachedSemanticsConfiguration!;
  }

  /// The bounding box, in the local coordinate system, of this
  /// object, for accessibility purposes.
  Rect get semanticBounds;

  bool _needsSemanticsUpdate = true;
  SemanticsNode? _semantics;

  /// The semantics of this render object.
  ///
  /// Exposed only for testing and debugging. To learn about the semantics of
  /// render objects in production, obtain a [SemanticsHandle] from
  /// [PipelineOwner.ensureSemantics].
  ///
  /// Only valid in debug and profile mode. In release builds, always returns
  /// null.
  SemanticsNode? get debugSemantics {
    if (!kReleaseMode) {
      return _semantics;
    }
    return null;
  }

  /// Removes all semantics from this render object and its descendants.
  ///
  /// Should only be called on objects whose [parent] is not a [RenderObject].
  ///
  /// Override this method if you instantiate new [SemanticsNode]s in an
  /// overridden [assembleSemanticsNode] method, to dispose of those nodes.
  @mustCallSuper
  void clearSemantics() {
    _needsSemanticsUpdate = true;
    _semantics = null;
    visitChildren((RenderObject child) {
      child.clearSemantics();
    });
  }

  /// 将此节点标记为需要更新其语义描述
  ///
  /// 每当由[descriptionSemanticsConfiguration]注释的这个[RenderObject]的语义配置以
  /// 任何方式改变时，必须调用这个函数来更新语义树。
  void markNeedsSemanticsUpdate() {
    assert(!attached || !owner!._debugDoingSemantics);
    if (!attached || owner!._semanticsOwner == null) {
      _cachedSemanticsConfiguration = null;
      return;
    }

    // Dirty the semantics tree starting at `this` until we have reached a
    // RenderObject that is a semantics boundary. All semantics past this
    // RenderObject are still up-to date. Therefore, we will later only rebuild
    // the semantics subtree starting at the identified semantics boundary.

    final bool wasSemanticsBoundary = _semantics != null && _cachedSemanticsConfiguration?.isSemanticBoundary == true;
    _cachedSemanticsConfiguration = null;
    bool isEffectiveSemanticsBoundary = _semanticsConfiguration.isSemanticBoundary && wasSemanticsBoundary;
    RenderObject node = this;

    while (!isEffectiveSemanticsBoundary && node.parent is RenderObject) {
      if (node != this && node._needsSemanticsUpdate)
        break;
      node._needsSemanticsUpdate = true;

      node = node.parent! as RenderObject;
      isEffectiveSemanticsBoundary = node._semanticsConfiguration.isSemanticBoundary;
      if (isEffectiveSemanticsBoundary && node._semantics == null) {
        // We have reached a semantics boundary that doesn't own a semantics node.
        // That means the semantics of this branch are currently blocked and will
        // not appear in the semantics tree. We can abort the walk here.
        return;
      }
    }
    if (node != this && _semantics != null && _needsSemanticsUpdate) {
      // If `this` node has already been added to [owner._nodesNeedingSemantics]
      // remove it as it is no longer guaranteed that its semantics
      // node will continue to be in the tree. If it still is in the tree, the
      // ancestor `node` added to [owner._nodesNeedingSemantics] at the end of
      // this block will ensure that the semantics of `this` node actually gets
      // updated.
      // (See semantics_10_test.dart for an example why this is required).
      owner!._nodesNeedingSemantics.remove(this);
    }
    if (!node._needsSemanticsUpdate) {
      node._needsSemanticsUpdate = true;
      if (owner != null) {
        assert(node._semanticsConfiguration.isSemanticBoundary || node.parent is! RenderObject);
        owner!._nodesNeedingSemantics.add(node);
        owner!.requestVisualUpdate();
      }
    }
  }

  /// Updates the semantic information of the render object.
  void _updateSemantics() {
    assert(_semanticsConfiguration.isSemanticBoundary || parent is! RenderObject);
    if (_needsLayout) {
      // There's not enough information in this subtree to compute semantics.
      // The subtree is probably being kept alive by a viewport but not laid out.
      return;
    }
    final _SemanticsFragment fragment = _getSemanticsForParent(
      mergeIntoParent: _semantics?.parent?.isPartOfNodeMerging ?? false,
    );
    assert(fragment is _InterestingSemanticsFragment);
    final _InterestingSemanticsFragment interestingFragment = fragment as _InterestingSemanticsFragment;
    final List<SemanticsNode> result = <SemanticsNode>[];
    interestingFragment.compileChildren(
      parentSemanticsClipRect: _semantics?.parentSemanticsClipRect,
      parentPaintClipRect: _semantics?.parentPaintClipRect,
      elevationAdjustment: _semantics?.elevationAdjustment ?? 0.0,
      result: result,
    );
    final SemanticsNode node = result.single;
    // Fragment only wants to add this node's SemanticsNode to the parent.
    assert(interestingFragment.config == null && node == _semantics);
  }

  /// Returns the semantics that this node would like to add to its parent.
  _SemanticsFragment _getSemanticsForParent({
    required bool mergeIntoParent,
  }) {
    assert(mergeIntoParent != null);
    assert(!_needsLayout, 'Updated layout information required for $this to calculate semantics.');

    final SemanticsConfiguration config = _semanticsConfiguration;
    bool dropSemanticsOfPreviousSiblings = config.isBlockingSemanticsOfPreviouslyPaintedNodes;

    final bool producesForkingFragment = !config.hasBeenAnnotated && !config.isSemanticBoundary;
    final List<_InterestingSemanticsFragment> fragments = <_InterestingSemanticsFragment>[];
    final Set<_InterestingSemanticsFragment> toBeMarkedExplicit = <_InterestingSemanticsFragment>{};
    final bool childrenMergeIntoParent = mergeIntoParent || config.isMergingSemanticsOfDescendants;

    // When set to true there's currently not enough information in this subtree
    // to compute semantics. In this case the walk needs to be aborted and no
    // SemanticsNodes in the subtree should be updated.
    // This will be true for subtrees that are currently kept alive by a
    // viewport but not laid out.
    bool abortWalk = false;

    visitChildrenForSemantics((RenderObject renderChild) {
      if (abortWalk || _needsLayout) {
        abortWalk = true;
        return;
      }
      final _SemanticsFragment parentFragment = renderChild._getSemanticsForParent(
        mergeIntoParent: childrenMergeIntoParent,
      );
      if (parentFragment.abortsWalk) {
        abortWalk = true;
        return;
      }
      if (parentFragment.dropsSemanticsOfPreviousSiblings) {
        fragments.clear();
        toBeMarkedExplicit.clear();
        if (!config.isSemanticBoundary)
          dropSemanticsOfPreviousSiblings = true;
      }
      // Figure out which child fragments are to be made explicit.
      for (final _InterestingSemanticsFragment fragment in parentFragment.interestingFragments) {
        fragments.add(fragment);
        fragment.addAncestor(this);
        fragment.addTags(config.tagsForChildren);
        if (config.explicitChildNodes || parent is! RenderObject) {
          fragment.markAsExplicit();
          continue;
        }
        if (!fragment.hasConfigForParent || producesForkingFragment)
          continue;
        if (!config.isCompatibleWith(fragment.config))
          toBeMarkedExplicit.add(fragment);
        final int siblingLength = fragments.length - 1;
        for (int i = 0; i < siblingLength; i += 1) {
          final _InterestingSemanticsFragment siblingFragment = fragments[i];
          if (!fragment.config!.isCompatibleWith(siblingFragment.config)) {
            toBeMarkedExplicit.add(fragment);
            toBeMarkedExplicit.add(siblingFragment);
          }
        }
      }
    });

    if (abortWalk) {
      return _AbortingSemanticsFragment(owner: this);
    }

    for (final _InterestingSemanticsFragment fragment in toBeMarkedExplicit)
      fragment.markAsExplicit();

    _needsSemanticsUpdate = false;

    _SemanticsFragment result;
    if (parent is! RenderObject) {
      assert(!config.hasBeenAnnotated);
      assert(!mergeIntoParent);
      result = _RootSemanticsFragment(
        owner: this,
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
    } else if (producesForkingFragment) {
      result = _ContainerSemanticsFragment(
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
    } else {
      result = _SwitchableSemanticsFragment(
        config: config,
        mergeIntoParent: mergeIntoParent,
        owner: this,
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
      if (config.isSemanticBoundary) {
        final _SwitchableSemanticsFragment fragment = result as _SwitchableSemanticsFragment;
        fragment.markAsExplicit();
      }
    }

    result.addAll(fragments);

    return result;
  }

  /// Called when collecting the semantics of this node.
  ///
  /// The implementation has to return the children in paint order skipping all
  /// children that are not semantically relevant (e.g. because they are
  /// invisible).
  ///
  /// The default implementation mirrors the behavior of
  /// [visitChildren] (which is supposed to walk all the children).
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren(visitor);
  }

  /// Assemble the [SemanticsNode] for this [RenderObject].
  ///
  /// If [describeSemanticsConfiguration] sets
  /// [SemanticsConfiguration.isSemanticBoundary] to true, this method is called
  /// with the `node` created for this [RenderObject], the `config` to be
  /// applied to that node and the `children` [SemanticsNode]s that descendants
  /// of this RenderObject have generated.
  ///
  /// By default, the method will annotate `node` with `config` and add the
  /// `children` to it.
  ///
  /// Subclasses can override this method to add additional [SemanticsNode]s
  /// to the tree. If new [SemanticsNode]s are instantiated in this method
  /// they must be disposed in [clearSemantics].
  void assembleSemanticsNode(
      SemanticsNode node,
      SemanticsConfiguration config,
      Iterable<SemanticsNode> children,
      ) {
    assert(node == _semantics);
    // TODO(a14n): remove the following cast by updating type of parameter in either updateWith or assembleSemanticsNode
    node.updateWith(config: config, childrenInInversePaintOrder: children as List<SemanticsNode>);
  }

  // EVENTS

  /// Override this method to handle pointer events that hit this render object.
  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) { }


  // HIT TESTING

  // RenderObject subclasses are expected to have a method like the following
  // (with the signature being whatever passes for coordinates for this
  // particular class):
  //
  // bool hitTest(HitTestResult result, { Offset position }) {
  //   // If the given position is not inside this node, then return false.
  //   // Otherwise:
  //   // For each child that intersects the position, in z-order starting from
  //   // the top, call hitTest() for that child, passing it /result/, and the
  //   // coordinates converted to the child's coordinate origin, and stop at
  //   // the first child that returns true.
  //   // Then, add yourself to /result/, and return true.
  // }
  //
  // If you add yourself to /result/ and still return false, then that means you
  // will see events but so will objects below you.


  /// Returns a human understandable name.
  @override
  String toStringShort() {
    String header = describeIdentity(this);
    if (_relayoutBoundary != null && _relayoutBoundary != this) {
      int count = 1;
      RenderObject? target = parent as RenderObject?;
      while (target != null && target != _relayoutBoundary) {
        target = target.parent as RenderObject?;
        count += 1;
      }
      header += ' relayoutBoundary=up$count';
    }
    if (_needsLayout)
      header += ' NEEDS-LAYOUT';
    if (_needsPaint)
      header += ' NEEDS-PAINT';
    if (_needsCompositingBitsUpdate)
      header += ' NEEDS-COMPOSITING-BITS-UPDATE';
    if (!attached)
      header += ' DETACHED';
    return header;
  }

  @override
  String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) => toStringShort();

  /// Returns a description of the tree rooted at this node.
  /// If the prefix argument is provided, then every line in the output
  /// will be prefixed by that string.
  @override
  String toStringDeep({
    String prefixLineOne = '',
    String? prefixOtherLines = '',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    RenderObject? debugPreviousActiveLayout;
    assert(() {
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = null;
      return true;
    }());
    final String result = super.toStringDeep(
      prefixLineOne: prefixLineOne,
      prefixOtherLines: prefixOtherLines,
      minLevel: minLevel,
    );
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      return true;
    }());
    return result;
  }

  /// Returns a one-line detailed description of the render object.
  /// This description is often somewhat long.
  ///
  /// This includes the same information for this RenderObject as given by
  /// [toStringDeep], but does not recurse to any children.
  @override
  String toStringShallow({
    String joiner = ', ',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    RenderObject? debugPreviousActiveLayout;
    assert(() {
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = null;
      return true;
    }());
    final String result = super.toStringShallow(joiner: joiner, minLevel: minLevel);
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      return true;
    }());
    return result;
  }

  @protected
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('needsCompositing', value: _needsCompositing, ifTrue: 'needs compositing'));
    properties.add(DiagnosticsProperty<Object?>('creator', debugCreator, defaultValue: null, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<ParentData>('parentData', parentData, tooltip: _debugCanParentUseSize == true ? 'can use size' : null, missingIfNull: true));
    properties.add(DiagnosticsProperty<Constraints>('constraints', _constraints, missingIfNull: true));
    // don't access it via the "layer" getter since that's only valid when we don't need paint
    properties.add(DiagnosticsProperty<ContainerLayer>('layer', _layer, defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsNode>('semantics node', _semantics, defaultValue: null));
    properties.add(FlagProperty(
      'isBlockingSemanticsOfPreviouslyPaintedNodes',
      value: _semanticsConfiguration.isBlockingSemanticsOfPreviouslyPaintedNodes,
      ifTrue: 'blocks semantics of earlier render objects below the common boundary',
    ));
    properties.add(FlagProperty('isSemanticBoundary', value: _semanticsConfiguration.isSemanticBoundary, ifTrue: 'semantic boundary'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[];

  /// Attempt to make (a portion of) this or a descendant [RenderObject] visible
  /// on screen.
  ///
  /// If `descendant` is provided, that [RenderObject] is made visible. If
  /// `descendant` is omitted, this [RenderObject] is made visible.
  ///
  /// The optional `rect` parameter describes which area of that [RenderObject]
  /// should be shown on screen. If `rect` is null, the entire
  /// [RenderObject] (as defined by its [paintBounds]) will be revealed. The
  /// `rect` parameter is interpreted relative to the coordinate system of
  /// `descendant` if that argument is provided and relative to this
  /// [RenderObject] otherwise.
  ///
  /// The `duration` parameter can be set to a non-zero value to bring the
  /// target object on screen in an animation defined by `curve`.
  ///
  /// See also:
  ///
  /// * [RenderViewportBase.showInViewport], which [RenderViewportBase] and
  ///   [SingleChildScrollView] delegate this method to.
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (parent is RenderObject) {
      final RenderObject renderParent = parent! as RenderObject;
      renderParent.showOnScreen(
        descendant: descendant ?? this,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Adds a debug representation of a [RenderObject] optimized for including in
  /// error messages.
  ///
  /// The default [style] of [DiagnosticsTreeStyle.shallow] ensures that all of
  /// the properties of the render object are included in the error output but
  /// none of the children of the object are.
  ///
  /// You should always include a RenderObject in an error message if it is the
  /// [RenderObject] causing the failure or contract violation of the error.
  DiagnosticsNode describeForError(String name, { DiagnosticsTreeStyle style = DiagnosticsTreeStyle.shallow }) {
    return toDiagnosticsNode(name: name, style: style);
  }
}
