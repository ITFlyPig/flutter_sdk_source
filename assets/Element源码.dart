///一个[Widget]在树的特定位置的实例化。
///
/// widgets描述了如何配置一个子树，但由于widgets是不可改变的，所以同一个widget可以同时用于配置多个子树。
/// [Element]表示使用widget来配置树中的特定位置。随着时间的推移，与给定元素相关联的widget可能会发生变化，
/// 例如，如果父widget重建并为该位置创建一个新的widget。
///
/// 大多数元素都有一个唯一的子元素，但一些widgets（例如，[RenderObjectElement]的子类）可以有多个子元素。
///
/// 元素的生命周期如下：
/// * 框架通过调用[Widget.createElement]在widget上创建一个元素，该widget将被用作元素的初始配置。
/// * 框架调用[mount]将新创建的元素添加到给定父节点的给定槽位的树上。[mount]方法负责对任何子widget进行膨胀（inflate），
///   并在必要时调用[attachRenderObject]将任何相关的render objects附加到渲染树上。
/// * 此时，该element被认为是 "active "的，可能会出现在屏幕上。
/// * 在某些时候，父元素可能会决定改变用于配置该元素的widget，例如因为父元素用新的状态（new state）重建。当这种情况发生时，
///   框架会用新的widget调用[update]，新的widget将始终拥有与旧widget相同的[runtimeType]和key。如果parent希望更改树中此
///   位置的widget的 [runtimeType] 或 key，它可以通过卸载此元素（unmount element）并在此位置膨胀新widget来实现。
/// * 在某些时候，一个祖先可能会决定将这个元素从树中移除，祖先通过调用[deactivateChild]进行移除。停用（Deactivating）祖先将导
///   致从渲染树中删除该元素的渲染对象，并将该元素添加到[owner]的非活动元素列表中(inactive elements)，导致框架对该元素调用[deactivate]。
/// * 此时，该元素被认为是 不活动 （inactive）的，不会出现在屏幕上。一个元素只能保持在非活动状态，直到当前动画帧的结束。在动画帧结束时，
///   任何仍处于非活动状态的元素将被取消挂载（unmounted）。
/// * 如果该元素被重新纳入到树中（例如，因为它或它的一个祖先有一个全局键global key被重用），框架将从[owner]的非活动元素列表中删除该元素，
///   在该元素上调用[activate]，并将该元素的渲染对象重新连接到渲染树上（此时，该元素再次被认为是 “活动的（active）"，并可能出现在屏幕上）。
/// * 如果元素在当前动画帧结束前没有被重新纳入树中，框架将对元素调用[unmount]。
/// * 此时，该元素被认为是 “失效（defunct） "的，今后将不会被纳入该树。
///
abstract class Element extends DiagnosticableTree implements BuildContext {
  /// 使用一个给定的widget配置创建元素element
  ///
  /// 通常由[Widget.createElement]的重写方法调用
  Element(Widget widget)
      :_widget = widget;

  Element? _parent;

  ///parent设置的信息，用于定义该child在其parent的child列表中的位置。
  ///
  /// Subclasses of Element that only have one child should use null for
  /// the slot for that child.
  dynamic get slot => _slot;
  dynamic _slot;

  /// 表示深度
  int get depth {
    return _depth;
  }
  late int _depth;

  static int _sort(Element a, Element b) {
    if (a.depth < b.depth)
      return -1;
    if (b.depth < a.depth)
      return 1;
    if (b.dirty && !a.dirty)
      return -1;
    if (a.dirty && !b.dirty)
      return 1;
    return 0;
  }

  /// 该元素的配置
  @override
  Widget get widget => _widget;
  Widget _widget;

  /// 管理该元素生命周期的对象
  @override
  BuildOwner? get owner => _owner;
  BuildOwner? _owner;

  /// The render object at (or below) this location in the tree.
  ///
  /// If this object is a [RenderObjectElement], the render object is the one at
  /// this location in the tree. Otherwise, this getter will walk down the tree
  /// until it finds a [RenderObjectElement].
  RenderObject? get renderObject {
    RenderObject? result;
    void visit(Element element) {
      if (element is RenderObjectElement)
        result = element.renderObject;
      else
        element.visitChildren(visit);
    }
    visit(this);
    return result;
  }

  // This is used to verify that Element objects move through life in an
  // orderly fashion.
  _ElementLifecycle _lifecycleState = _ElementLifecycle.initial;

  /// Calls the argument for each child. Must be overridden by subclasses that
  /// support having children.
  ///
  /// There is no guaranteed order in which the children will be visited, though
  /// it should be consistent over time.
  ///
  /// Calling this during build is dangerous: the child list might still be
  /// being updated at that point, so the children might not be constructed yet,
  /// or might be old children that are going to be replaced. This method should
  /// only be called if it is provable that the children are available.
  void visitChildren(ElementVisitor visitor) { }

  /// Wrapper around [visitChildren] for [BuildContext].
  @override
  void visitChildElements(ElementVisitor visitor) {
    visitChildren(visitor);
  }

  /// Update the given child with the given new configuration.
  ///
  /// This method is the core of the widgets system. It is called each time we
  /// are to add, update, or remove a child based on an updated configuration.
  ///
  /// The `newSlot` argument specifies the new value for this element's [slot].
  ///
  /// If the `child` is null, and the `newWidget` is not null, then we have a new
  /// child for which we need to create an [Element], configured with `newWidget`.
  ///
  /// If the `newWidget` is null, and the `child` is not null, then we need to
  /// remove it because it no longer has a configuration.
  ///
  /// If neither are null, then we need to update the `child`'s configuration to
  /// be the new configuration given by `newWidget`. If `newWidget` can be given
  /// to the existing child (as determined by [Widget.canUpdate]), then it is so
  /// given. Otherwise, the old child needs to be disposed and a new child
  /// created for the new configuration.
  ///
  /// If both are null, then we don't have a child and won't have a child, so we
  /// do nothing.
  ///
  /// The [updateChild] method returns the new child, if it had to create one,
  /// or the child that was passed in, if it just had to update the child, or
  /// null, if it removed the child and did not replace it.
  ///
  /// The following table summarizes the above:
  ///
  /// |                     | **newWidget == null**  | **newWidget != null**   |
  /// | :-----------------: | :--------------------- | :---------------------- |
  /// |  **child == null**  |  Returns null.         |  Returns new [Element]. |
  /// |  **child != null**  |  Old child is removed, returns null. | Old child updated if possible, returns child or new [Element]. |
  ///
  /// The `newSlot` argument is used only if `newWidget` is not null. If `child`
  /// is null (or if the old child cannot be updated), then the `newSlot` is
  /// given to the new [Element] that is created for the child, via
  /// [inflateWidget]. If `child` is not null (and the old child _can_ be
  /// updated), then the `newSlot` is given to [updateSlotForChild] to update
  /// its slot, in case it has moved around since it was last built.
  ///
  /// See the [RenderObjectElement] documentation for more information on slots.
  @protected
  Element? updateChild(Element? child, Widget? newWidget, dynamic newSlot) {
    if (newWidget == null) {
      if (child != null)
        deactivateChild(child);
      return null;
    }
    final Element newChild;
    if (child != null) {
      bool hasSameSuperclass = true;
      // When the type of a widget is changed between Stateful and Stateless via
      // hot reload, the element tree will end up in a partially invalid state.
      // That is, if the widget was a StatefulWidget and is now a StatelessWidget,
      // then the element tree currently contains a StatefulElement that is incorrectly
      // referencing a StatelessWidget (and likewise with StatelessElement).
      //
      // To avoid crashing due to type errors, we need to gently guide the invalid
      // element out of the tree. To do so, we ensure that the `hasSameSuperclass` condition
      // returns false which prevents us from trying to update the existing element
      // incorrectly.
      //
      // For the case where the widget becomes Stateful, we also need to avoid
      // accessing `StatelessElement.widget` as the cast on the getter will
      // cause a type error to be thrown. Here we avoid that by short-circuiting
      // the `Widget.canUpdate` check once `hasSameSuperclass` is false.
      if (hasSameSuperclass && child.widget == newWidget) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        newChild = child;
      } else if (hasSameSuperclass && Widget.canUpdate(child.widget, newWidget)) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        child.update(newWidget);
        assert(child.widget == newWidget);
        assert(() {
          child.owner!._debugElementWasRebuilt(child);
          return true;
        }());
        newChild = child;
      } else {
        deactivateChild(child);
        assert(child._parent == null);
        newChild = inflateWidget(newWidget, newSlot);
      }
    } else {
      newChild = inflateWidget(newWidget, newSlot);
    }
    return newChild;
  }

  ///
  /// 通过将当前元素添加到parent的给定槽位，以将该元素添加到树中。
  ///
  /// 当一个新创建的元素第一次被添加到树中时，框架会调用这个函数。使用这个方法来初始化依赖于有一个父元素的state，
  /// 独立于父元素的state可以更容易地在构造函数中初始化。
  ///
  /// 该方法将元素从 "initial "生命周期状态转换到 "active "生命周期状态。
  ///
  /// 如果子类复写了该方法，那么它很可能也该复写
  /// [update], [visitChildren], [RenderObjectElement.insertRenderObjectChild],
  /// [RenderObjectElement.moveRenderObjectChild], and
  /// [RenderObjectElement.removeRenderObjectChild].
  @mustCallSuper
  void mount(Element? parent, dynamic newSlot) {
    //记录parent
    _parent = parent;
    //记录在parent中的槽位slot
    _slot = newSlot;
    //更新生命周期为active
    _lifecycleState = _ElementLifecycle.active;
    _depth = _parent != null ? _parent!.depth + 1 : 1;
    if (parent != null) // Only assign ownership if the parent is non-null
      _owner = parent.owner;
    final Key? key = widget.key;
    //GlobalKey中记录对应的element
    if (key is GlobalKey) {
      key._register(this);
    }
    _updateInheritance();
  }

  /// Change the widget used to configure this element.
  ///
  /// The framework calls this function when the parent wishes to use a
  /// different widget to configure this element. The new widget is guaranteed
  /// to have the same [runtimeType] as the old widget.
  ///
  /// This function is called only during the "active" lifecycle state.
  @mustCallSuper
  void update(covariant Widget newWidget) {
    // This Element was told to update and we can now release all the global key
    // reservations of forgotten children. We cannot do this earlier because the
    // forgotten children still represent global key duplications if the element
    // never updates (the forgotten children are not removed from the tree
    // until the call to update happens)
    _widget = newWidget;
  }

  /// Change the slot that the given child occupies in its parent.
  ///
  /// Called by [MultiChildRenderObjectElement], and other [RenderObjectElement]
  /// subclasses that have multiple children, when child moves from one position
  /// to another in this element's child list.
  @protected
  void updateSlotForChild(Element child, dynamic newSlot) {
    void visit(Element element) {
      element._updateSlot(newSlot);
      if (element is! RenderObjectElement)
        element.visitChildren(visit);
    }
    visit(child);
  }

  void _updateSlot(dynamic newSlot) {
    assert(_lifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(_parent != null);
    assert(_parent!._lifecycleState == _ElementLifecycle.active);
    assert(depth != null);
    _slot = newSlot;
  }

  void _updateDepth(int parentDepth) {
    final int expectedDepth = parentDepth + 1;
    if (_depth < expectedDepth) {
      _depth = expectedDepth;
      visitChildren((Element child) {
        child._updateDepth(expectedDepth);
      });
    }
  }

  /// Remove [renderObject] from the render tree.
  ///
  /// The default implementation of this function simply calls
  /// [detachRenderObject] recursively on each child. The
  /// [RenderObjectElement.detachRenderObject] override does the actual work of
  /// removing [renderObject] from the render tree.
  ///
  /// This is called by [deactivateChild].
  void detachRenderObject() {
    visitChildren((Element child) {
      child.detachRenderObject();
    });
    _slot = null;
  }

  /// Add [renderObject] to the render tree at the location specified by `newSlot`.
  ///
  /// The default implementation of this function simply calls
  /// [attachRenderObject] recursively on each child. The
  /// [RenderObjectElement.attachRenderObject] override does the actual work of
  /// adding [renderObject] to the render tree.
  ///
  /// The `newSlot` argument specifies the new value for this element's [slot].
  void attachRenderObject(dynamic newSlot) {
    assert(_slot == null);
    visitChildren((Element child) {
      child.attachRenderObject(newSlot);
    });
    _slot = newSlot;
  }

  Element? _retakeInactiveElement(GlobalKey key, Widget newWidget) {
    // The "inactivity" of the element being retaken here may be forward-looking: if
    // we are taking an element with a GlobalKey from an element that currently has
    // it as a child, then we know that element will soon no longer have that
    // element as a child. The only way that assumption could be false is if the
    // global key is being duplicated, and we'll try to track that using the
    // _debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans call below.
    final Element? element = key._currentElement;
    if (element == null)
      return null;
    if (!Widget.canUpdate(element.widget, newWidget))
      return null;
    final Element? parent = element._parent;
    if (parent != null) {
      parent.forgetChild(element);
      parent.deactivateChild(element);
    }
    owner!._inactiveElements.remove(element);
    return element;
  }

  /// Create an element for the given widget and add it as a child of this
  /// element in the given slot.
  ///
  /// This method is typically called by [updateChild] but can be called
  /// directly by subclasses that need finer-grained control over creating
  /// elements.
  ///
  /// If the given widget has a global key and an element already exists that
  /// has a widget with that global key, this function will reuse that element
  /// (potentially grafting it from another location in the tree or reactivating
  /// it from the list of inactive elements) rather than creating a new element.
  ///
  /// The `newSlot` argument specifies the new value for this element's [slot].
  ///
  /// The element returned by this function will already have been mounted and
  /// will be in the "active" lifecycle state.
  @protected
  Element inflateWidget(Widget newWidget, dynamic newSlot) {
    final Key? key = newWidget.key;
    if (key is GlobalKey) {
      //全局key，尝试复用。即从非活动列表寻找是否有满足条件的element
      final Element? newChild = _retakeInactiveElement(key, newWidget);
      if (newChild != null) {
        //将非活动的element重新转为active状态
        newChild._activateWithParent(this, newSlot);
        //使用widget更新找到的element
        final Element? updatedChild = updateChild(newChild, newWidget, newSlot);
        return updatedChild!;
      }
    }
    //创建element
    final Element newChild = newWidget.createElement();
    //挂载element
    newChild.mount(this, newSlot);
    return newChild;
  }

  /// Move the given element to the list of inactive elements and detach its
  /// render object from the render tree.
  ///
  /// This method stops the given element from being a child of this element by
  /// detaching its render object from the render tree and moving the element to
  /// the list of inactive elements.
  ///
  /// This method (indirectly) calls [deactivate] on the child.
  ///
  /// The caller is responsible for removing the child from its child model.
  /// Typically [deactivateChild] is called by the element itself while it is
  /// updating its child model; however, during [GlobalKey] reparenting, the new
  /// parent proactively calls the old parent's [deactivateChild], first using
  /// [forgetChild] to cause the old parent to update its child model.
  @protected
  void deactivateChild(Element child) {
    assert(child != null);
    assert(child._parent == this);
    child._parent = null;
    child.detachRenderObject();
    owner!._inactiveElements.add(child); // this eventually calls child.deactivate()
  }

  // The children that have been forgotten by forgetChild. This will be used in
  // [update] to remove the global key reservations of forgotten children.
  final Set<Element> _debugForgottenChildrenWithGlobalKey = HashSet<Element>();

  /// Remove the given child from the element's child list, in preparation for
  /// the child being reused elsewhere in the element tree.
  ///
  /// This updates the child model such that, e.g., [visitChildren] does not
  /// walk that child anymore.
  ///
  /// The element will still have a valid parent when this is called, and the
  /// child's [Element.slot] value will be valid in the context of that parent.
  /// After this is called, [deactivateChild] is called to sever the link to
  /// this object.
  ///
  /// The [update] is responsible for updating or creating the new child that
  /// will replace this [child].
  @protected
  @mustCallSuper
  void forgetChild(Element child) {
    // This method is called on the old parent when the given child (with a
    // global key) is given a new parent. We cannot remove the global key
    // reservation directly in this method because the forgotten child is not
    // removed from the tree until this Element is updated in [update]. If
    // [update] is never called, the forgotten child still represents a global
    // key duplication that we need to catch.
  }

  void _activateWithParent(Element parent, dynamic newSlot) {
    _parent = parent;
    _updateDepth(_parent!.depth);
    _activateRecursively(this);
    attachRenderObject(newSlot);
  }

  static void _activateRecursively(Element element) {
    assert(element._lifecycleState == _ElementLifecycle.inactive);
    element.activate();
    assert(element._lifecycleState == _ElementLifecycle.active);
    element.visitChildren(_activateRecursively);
  }

  /// Transition from the "inactive" to the "active" lifecycle state.
  ///
  /// The framework calls this method when a previously deactivated element has
  /// been reincorporated into the tree. The framework does not call this method
  /// the first time an element becomes active (i.e., from the "initial"
  /// lifecycle state). Instead, the framework calls [mount] in that situation.
  ///
  /// See the lifecycle documentation for [Element] for additional information.
  @mustCallSuper
  void activate() {
    final bool hadDependencies = (_dependencies != null && _dependencies!.isNotEmpty) || _hadUnsatisfiedDependencies;
    _lifecycleState = _ElementLifecycle.active;
    // We unregistered our dependencies in deactivate, but never cleared the list.
    // Since we're going to be reused, let's clear our list now.
    _dependencies?.clear();
    _hadUnsatisfiedDependencies = false;
    _updateInheritance();
    if (_dirty)
      owner!.scheduleBuildFor(this);
    if (hadDependencies)
      didChangeDependencies();
  }

  /// Transition from the "active" to the "inactive" lifecycle state.
  ///
  /// The framework calls this method when a previously active element is moved
  /// to the list of inactive elements. While in the inactive state, the element
  /// will not appear on screen. The element can remain in the inactive state
  /// only until the end of the current animation frame. At the end of the
  /// animation frame, if the element has not be reactivated, the framework will
  /// unmount the element.
  ///
  /// This is (indirectly) called by [deactivateChild].
  ///
  /// See the lifecycle documentation for [Element] for additional information.
  @mustCallSuper
  void deactivate() {
    if (_dependencies != null && _dependencies!.isNotEmpty) {
      for (final InheritedElement dependency in _dependencies!)
        dependency._dependents.remove(this);
      // For expediency, we don't actually clear the list here, even though it's
      // no longer representative of what we are registered with. If we never
      // get re-used, it doesn't matter. If we do, then we'll clear the list in
      // activate(). The benefit of this is that it allows Element's activate()
      // implementation to decide whether to rebuild based on whether we had
      // dependencies here.
    }
    _inheritedWidgets = null;
    _lifecycleState = _ElementLifecycle.inactive;
  }

  /// Transition from the "inactive" to the "defunct" lifecycle state.
  ///
  /// Called when the framework determines that an inactive element will never
  /// be reactivated. At the end of each animation frame, the framework calls
  /// [unmount] on any remaining inactive elements, preventing inactive elements
  /// from remaining inactive for longer than a single animation frame.
  ///
  /// After this function is called, the element will not be incorporated into
  /// the tree again.
  ///
  /// See the lifecycle documentation for [Element] for additional information.
  @mustCallSuper
  void unmount() {
    assert(_lifecycleState == _ElementLifecycle.inactive);
    assert(_widget != null); // Use the private property to avoid a CastError during hot reload.
    assert(depth != null);
    // Use the private property to avoid a CastError during hot reload.
    final Key? key = _widget.key;
    if (key is GlobalKey) {
      key._unregister(this);
    }
    _lifecycleState = _ElementLifecycle.defunct;
  }

  @override
  RenderObject? findRenderObject() => renderObject;

  @override
  Size? get size {
    final RenderObject? renderObject = findRenderObject();
    if (renderObject is RenderBox)
      return renderObject.size;
    return null;
  }

  Map<Type, InheritedElement>? _inheritedWidgets;
  Set<InheritedElement>? _dependencies;
  bool _hadUnsatisfiedDependencies = false;

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, { Object? aspect }) {
    assert(ancestor != null);
    _dependencies ??= HashSet<InheritedElement>();
    _dependencies!.add(ancestor);
    ancestor.updateDependencies(this, aspect);
    return ancestor.widget;
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    final InheritedElement? ancestor = _inheritedWidgets == null ? null : _inheritedWidgets![T];
    if (ancestor != null) {
      assert(ancestor is InheritedElement);
      return dependOnInheritedElement(ancestor, aspect: aspect) as T;
    }
    _hadUnsatisfiedDependencies = true;
    return null;
  }

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    final InheritedElement? ancestor = _inheritedWidgets == null ? null : _inheritedWidgets![T];
    return ancestor;
  }

  void _updateInheritance() {
    assert(_lifecycleState == _ElementLifecycle.active);
    _inheritedWidgets = _parent?._inheritedWidgets;
  }

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null && ancestor.widget.runtimeType != T)
      ancestor = ancestor._parent;
    return ancestor?.widget as T?;
  }

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is StatefulElement && ancestor.state is T)
        break;
      ancestor = ancestor._parent;
    }
    final StatefulElement? statefulAncestor = ancestor as StatefulElement?;
    return statefulAncestor?.state as T?;
  }

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    StatefulElement? statefulAncestor;
    while (ancestor != null) {
      if (ancestor is StatefulElement && ancestor.state is T)
        statefulAncestor = ancestor;
      ancestor = ancestor._parent;
    }
    return statefulAncestor?.state as T?;
  }

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is RenderObjectElement && ancestor.renderObject is T)
        return ancestor.renderObject as T;
      ancestor = ancestor._parent;
    }
    return null;
  }

  @override
  void visitAncestorElements(bool visitor(Element element)) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element? ancestor = _parent;
    while (ancestor != null && visitor(ancestor))
      ancestor = ancestor._parent;
  }

  /// Called when a dependency of this element changes.
  ///
  /// The [dependOnInheritedWidgetOfExactType] registers this element as depending on
  /// inherited information of the given type. When the information of that type
  /// changes at this location in the tree (e.g., because the [InheritedElement]
  /// updated to a new [InheritedWidget] and
  /// [InheritedWidget.updateShouldNotify] returned true), the framework calls
  /// this function to notify this element of the change.
  @mustCallSuper
  void didChangeDependencies() {
    markNeedsBuild();
  }

  /// Returns true if the element has been marked as needing rebuilding.
  bool get dirty => _dirty;
  bool _dirty = true;

  // Whether this is in owner._dirtyElements. This is used to know whether we
  // should be adding the element back into the list when it's reactivated.
  bool _inDirtyList = false;

  // Whether we've already built or not. Set in [rebuild].
  bool _debugBuiltOnce = false;

  // We let widget authors call setState from initState, didUpdateWidget, and
  // build even when state is locked because its convenient and a no-op anyway.
  // This flag ensures that this convenience is only allowed on the element
  // currently undergoing initState, didUpdateWidget, or build.
  bool _debugAllowIgnoredCallsToMarkNeedsBuild = false;
  bool _debugSetAllowIgnoredCallsToMarkNeedsBuild(bool value) {
    assert(_debugAllowIgnoredCallsToMarkNeedsBuild == !value);
    _debugAllowIgnoredCallsToMarkNeedsBuild = value;
    return true;
  }

  /// Marks the element as dirty and adds it to the global list of widgets to
  /// rebuild in the next frame.
  ///
  /// Since it is inefficient to build an element twice in one frame,
  /// applications and widgets should be structured so as to only mark
  /// widgets dirty during event handlers before the frame begins, not during
  /// the build itself.
  void markNeedsBuild() {
    if (_lifecycleState != _ElementLifecycle.active)
      return;
    if (dirty)
      return;
    _dirty = true;
    owner!.scheduleBuildFor(this);
  }

  /// Called by the [BuildOwner] when [BuildOwner.scheduleBuildFor] has been
  /// called to mark this element dirty, by [mount] when the element is first
  /// built, and by [update] when the widget has changed.
  void rebuild() {
    if (_lifecycleState != _ElementLifecycle.active || !_dirty)
      return;
    Element? debugPreviousBuildTarget;
    performRebuild();
  }

  /// Called by rebuild() after the appropriate checks have been made.
  @protected
  void performRebuild();
}
