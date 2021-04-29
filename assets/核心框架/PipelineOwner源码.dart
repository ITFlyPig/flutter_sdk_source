/// PipelineOwner管理渲染管道
///
/// PipelineOwner提供了一个驱动渲染管道的接口，并存储了关于在管道的每个阶段中哪些渲染对象请
/// 求被访问的状态。要刷管道，请依次调用以下函数：
///
/// 1. [flushLayout] 更新任何需要计算布局的渲染对象。在这个阶段，计算每个渲染对象的大小和位
///    置。在这个阶段，渲染对象可能会弄脏(dirty)它们的绘制或合成状态。
/// 2. [flushCompositingBits] 更新任何有脏合成位(dirty compositing bits)的渲染对象。
///    在这个阶段，每个渲染对象都会了解它的任何子对象是否需要合成。在绘制阶段，当选择如何实现
///    视觉效果（如剪裁）时，会用到这些信息。如果一个渲染对象有一个合成的child对象，其需要使
///    用图层[Layer] 来创剪裁，以便将剪裁应用于合成的子对象（该子对象将被绘制到自己的图层[Layer]中）。
/// 3. [flushPaint]访问任何需要绘制的渲染对象。在这个阶段，渲染对象有机会将绘制命令记录到
///    [PictureLayer]中，并构造其他合成的[Layer]。
/// 4. 最后，如果语义被启用，[flushSemantics]将编译渲染对象的语义。辅助技术会使用这些语义
///    信息来改善渲染树的可访问性。
///
/// [RendererBinding]持有屏幕上可见的渲染对象的pipeline owner。你可以创建其他pipeline owner
/// 来管理屏幕外的对象，这些对象可以独立于屏幕上的渲染对象来刷新它们的管道。
///
class PipelineOwner {
  /// Creates a pipeline owner.
  ///
  /// Typically created by the binding (e.g., [RendererBinding]), but can be
  /// created separately from the binding to drive off-screen render objects
  /// through the rendering pipeline.
  PipelineOwner({
    this.onNeedVisualUpdate,
    this.onSemanticsOwnerCreated,
    this.onSemanticsOwnerDisposed,
  });

  /// Called when a render object associated with this pipeline owner wishes to
  /// update its visual appearance.
  ///
  /// Typical implementations of this function will schedule a task to flush the
  /// various stages of the pipeline. This function might be called multiple
  /// times in quick succession. Implementations should take care to discard
  /// duplicate calls quickly.
  final VoidCallback? onNeedVisualUpdate;

  /// Called whenever this pipeline owner creates a semantics object.
  ///
  /// Typical implementations will schedule the creation of the initial
  /// semantics tree.
  final VoidCallback? onSemanticsOwnerCreated;

  /// Called whenever this pipeline owner disposes its semantics owner.
  ///
  /// Typical implementations will tear down the semantics tree.
  final VoidCallback? onSemanticsOwnerDisposed;

  /// Calls [onNeedVisualUpdate] if [onNeedVisualUpdate] is not null.
  ///
  /// Used to notify the pipeline owner that an associated render object wishes
  /// to update its visual appearance.
  void requestVisualUpdate() {
    if (onNeedVisualUpdate != null) onNeedVisualUpdate!();
  }

  /// The unique object managed by this pipeline that has no parent.
  ///
  /// This object does not have to be a [RenderObject].
  AbstractNode? get rootNode => _rootNode;
  AbstractNode? _rootNode;
  set rootNode(AbstractNode? value) {
    if (_rootNode == value) return;
    _rootNode?.detach();
    _rootNode = value;
    _rootNode?.attach(this);
  }

  List<RenderObject> _nodesNeedingLayout = <RenderObject>[];

  /// Whether this pipeline is currently in the layout phase.
  ///
  /// Specifically, whether [flushLayout] is currently running.
  ///
  /// Only valid when asserts are enabled; in release builds, this
  /// always returns false.
  bool get debugDoingLayout => _debugDoingLayout;
  bool _debugDoingLayout = false;

  /// 更新所有的dirty render object的布局信息
  ///
  /// 这个功能是渲染管线的核心阶段之一。在绘制之前，布局信息会被清理，这样渲染对象就会以其最
  /// 新的位置出现在屏幕上。
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void flushLayout() {
    if (!kReleaseMode) {
      Timeline.startSync('Layout',
          arguments: timelineArgumentsIndicatingLandmarkEvent);
    }
    assert(() {
      _debugDoingLayout = true;
      return true;
    }());
    try {
      // TODO(ianh): assert that we're not allowing previously dirty nodes to redirty themselves
      while (_nodesNeedingLayout.isNotEmpty) {
        final List<RenderObject> dirtyNodes = _nodesNeedingLayout;
        _nodesNeedingLayout = <RenderObject>[];
        for (final RenderObject node in dirtyNodes
          ..sort((RenderObject a, RenderObject b) => a.depth - b.depth)) {
          if (node._needsLayout && node.owner == this)
            node._layoutWithoutResize();
        }
      }
    } finally {
      assert(() {
        _debugDoingLayout = false;
        return true;
      }());
      if (!kReleaseMode) {
        Timeline.finishSync();
      }
    }
  }

  // This flag is used to allow the kinds of mutations performed by GlobalKey
  // reparenting while a LayoutBuilder is being rebuilt and in so doing tries to
  // move a node from another LayoutBuilder subtree that hasn't been updated
  // yet. To set this, call [_enableMutationsToDirtySubtrees], which is called
  // by [RenderObject.invokeLayoutCallback].
  bool _debugAllowMutationsToDirtySubtrees = false;

  // See [RenderObject.invokeLayoutCallback].
  void _enableMutationsToDirtySubtrees(VoidCallback callback) {
    assert(_debugDoingLayout);
    bool? oldState;
    assert(() {
      oldState = _debugAllowMutationsToDirtySubtrees;
      _debugAllowMutationsToDirtySubtrees = true;
      return true;
    }());
    try {
      callback();
    } finally {
      assert(() {
        _debugAllowMutationsToDirtySubtrees = oldState!;
        return true;
      }());
    }
  }

  final List<RenderObject> _nodesNeedingCompositingBitsUpdate =
      <RenderObject>[];

  /// Updates the [RenderObject.needsCompositing] bits.
  ///
  /// Called as part of the rendering pipeline after [flushLayout] and before
  /// [flushPaint].
  void flushCompositingBits() {
    if (!kReleaseMode) {
      Timeline.startSync('Compositing bits');
    }
    _nodesNeedingCompositingBitsUpdate
        .sort((RenderObject a, RenderObject b) => a.depth - b.depth);
    for (final RenderObject node in _nodesNeedingCompositingBitsUpdate) {
      if (node._needsCompositingBitsUpdate && node.owner == this)
        node._updateCompositingBits();
    }
    _nodesNeedingCompositingBitsUpdate.clear();
    if (!kReleaseMode) {
      Timeline.finishSync();
    }
  }

  List<RenderObject> _nodesNeedingPaint = <RenderObject>[];

  /// Whether this pipeline is currently in the paint phase.
  ///
  /// Specifically, whether [flushPaint] is currently running.
  ///
  /// Only valid when asserts are enabled. In release builds,
  /// this always returns false.
  bool get debugDoingPaint => _debugDoingPaint;
  bool _debugDoingPaint = false;

  /// Update the display lists for all render objects.
  ///
  /// This function is one of the core stages of the rendering pipeline.
  /// Painting occurs after layout and before the scene is recomposited so that
  /// scene is composited with up-to-date display lists for every render object.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void flushPaint() {
    if (!kReleaseMode) {
      Timeline.startSync('Paint',
          arguments: timelineArgumentsIndicatingLandmarkEvent);
    }
    assert(() {
      _debugDoingPaint = true;
      return true;
    }());
    try {
      final List<RenderObject> dirtyNodes = _nodesNeedingPaint;
      _nodesNeedingPaint = <RenderObject>[];
      // Sort the dirty nodes in reverse order (deepest first).
      for (final RenderObject node in dirtyNodes
        ..sort((RenderObject a, RenderObject b) => b.depth - a.depth)) {
        assert(node._layer != null);
        if (node._needsPaint && node.owner == this) {
          if (node._layer!.attached) {
            //绘制child
            PaintingContext.repaintCompositedChild(node);
          } else {
            node._skippedPaintingOnLayer();
          }
        }
      }
      assert(_nodesNeedingPaint.isEmpty);
    } finally {
      assert(() {
        _debugDoingPaint = false;
        return true;
      }());
      if (!kReleaseMode) {
        Timeline.finishSync();
      }
    }
  }

  /// The object that is managing semantics for this pipeline owner, if any.
  ///
  /// An owner is created by [ensureSemantics]. The owner is valid for as long
  /// there are [SemanticsHandle]s returned by [ensureSemantics] that have not
  /// yet been disposed. Once the last handle has been disposed, the
  /// [semanticsOwner] field will revert to null, and the previous owner will be
  /// disposed.
  ///
  /// When [semanticsOwner] is null, the [PipelineOwner] skips all steps
  /// relating to semantics.
  SemanticsOwner? get semanticsOwner => _semanticsOwner;
  SemanticsOwner? _semanticsOwner;

  /// The number of clients registered to listen for semantics.
  ///
  /// The number is increased whenever [ensureSemantics] is called and decreased
  /// when [SemanticsHandle.dispose] is called.
  int get debugOutstandingSemanticsHandles => _outstandingSemanticsHandles;
  int _outstandingSemanticsHandles = 0;

  /// Opens a [SemanticsHandle] and calls [listener] whenever the semantics tree
  /// updates.
  ///
  /// The [PipelineOwner] updates the semantics tree only when there are clients
  /// that wish to use the semantics tree. These clients express their interest
  /// by holding [SemanticsHandle] objects that notify them whenever the
  /// semantics tree updates.
  ///
  /// Clients can close their [SemanticsHandle] by calling
  /// [SemanticsHandle.dispose]. Once all the outstanding [SemanticsHandle]
  /// objects for a given [PipelineOwner] are closed, the [PipelineOwner] stops
  /// maintaining the semantics tree.
  SemanticsHandle ensureSemantics({VoidCallback? listener}) {
    _outstandingSemanticsHandles += 1;
    if (_outstandingSemanticsHandles == 1) {
      assert(_semanticsOwner == null);
      _semanticsOwner = SemanticsOwner();
      if (onSemanticsOwnerCreated != null) onSemanticsOwnerCreated!();
    }
    return SemanticsHandle._(this, listener);
  }

  void _didDisposeSemanticsHandle() {
    assert(_semanticsOwner != null);
    _outstandingSemanticsHandles -= 1;
    if (_outstandingSemanticsHandles == 0) {
      _semanticsOwner!.dispose();
      _semanticsOwner = null;
      if (onSemanticsOwnerDisposed != null) onSemanticsOwnerDisposed!();
    }
  }

  bool _debugDoingSemantics = false;
  final Set<RenderObject> _nodesNeedingSemantics = <RenderObject>{};

  /// Update the semantics for render objects marked as needing a semantics
  /// update.
  ///
  /// Initially, only the root node, as scheduled by
  /// [RenderObject.scheduleInitialSemantics], needs a semantics update.
  ///
  /// This function is one of the core stages of the rendering pipeline. The
  /// semantics are compiled after painting and only after
  /// [RenderObject.scheduleInitialSemantics] has been called.
  ///
  /// See [RendererBinding] for an example of how this function is used.
  void flushSemantics() {
    if (_semanticsOwner == null) return;
    if (!kReleaseMode) {
      Timeline.startSync('Semantics');
    }
    assert(_semanticsOwner != null);
    assert(() {
      _debugDoingSemantics = true;
      return true;
    }());
    try {
      final List<RenderObject> nodesToProcess = _nodesNeedingSemantics.toList()
        ..sort((RenderObject a, RenderObject b) => a.depth - b.depth);
      _nodesNeedingSemantics.clear();
      for (final RenderObject node in nodesToProcess) {
        if (node._needsSemanticsUpdate && node.owner == this)
          node._updateSemantics();
      }
      _semanticsOwner!.sendSemanticsUpdate();
    } finally {
      assert(_nodesNeedingSemantics.isEmpty);
      assert(() {
        _debugDoingSemantics = false;
        return true;
      }());
      if (!kReleaseMode) {
        Timeline.finishSync();
      }
    }
  }
}
