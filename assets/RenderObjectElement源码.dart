
/// 一个使用[RenderObjectWidget]作为配置的[Element]
///
/// [RenderObjectElement]对象在渲染树中有一个关联的[RenderObject]，该对象负责
/// 处理具体的操作，比如layout、绘制和命中测试。
///
/// 对比[ComponentElement]。
///
/// 关于[Element]的生命周期，请参见[Element]的讨论。
///
/// 1. 如何写一个RenderObjectElement的子类
/// 大多数[RenderObject]使用的child模型一般有三个：
/// * 叶子节点模型，没有children，[LeafRenderObjectElement]类用来处理这种情况；
/// * 具有一个child的模型：[SingleChildRenderObjectElement]类用来处理这种情况；
/// * 具有链表children的模型：[MultiChildRenderObjectElement]类用来处理这种情况。
///
/// 但是，有时一个render object的子模型是比较复杂的，可能是一个二维的数组、也可能按需构造
/// child、也许具有多个列表。在这种情况下，该[RenderObject]的配置[Widget]对应的[Element]
/// 将是[RenderObjectElement]的一个新的子类。
///
/// 这样的子类负责管理children，特别是这个对象的[Element]的children，以及其对应的[RenderObject]
/// 的children。
///
/// 1.1 对于getter方法
/// [RenderObjectElement]对象作为[widget]和[renderObject]之间的中介需要花很多时间。为了
/// 使这一点更容易理解，大多数[RenderObjectElement]子类重写了这些getter方法，以便它们返回
/// [element]期望的特定类型。
///
/// ```dart
/// class FooElement extends RenderObjectElement {
///
///   @override
///   Foo get widget => super.widget as Foo;
///
///   @override
///   RenderFoo get renderObject => super.renderObject as RenderFoo;
///
///   // ...
/// }
/// ```
///
/// 1.2 槽位（slots）
///
/// 每一个子[Element]对应一个[RenderObject]，这个子[RenderObject]应该作为一个child并附
/// 着到当前element的渲染对象（render object）上。
///
/// 然而，element的直接children可能不是最终产生它们所对应的实际[RenderObject]的children。
/// 例如一个[StatelessElement]（一个[StatelessWidget]的元素）只是对应于它的子元素
/// （由[StatelessWidget.build]方法返回的元素）所对应的[RenderObject]。
///
/// 因此，每个子节点都被分配了一个_slot_标记。这是一个标识符，其含义是这个[RenderObjectElement]
/// 节点的私有标识。当最终产生[RenderObject]的子代准备将其附加到这个节点的渲染对象上时，它就会将
/// 这个槽令牌传回给这个节点，这样就可以让这个节点快递地识别出子代渲染对象相对于父代渲染对象中其他渲染对象的位置。
///
/// 1.3 更新children
///
/// 在元素的生命周期早期，框架会调用[mount]方法。这个方法应该为每个子元素调用[updateChild]，
/// 并传入该子元素的widget，以及该子元素的slot，从而获得一个子[Element]的列表。
///
/// 随后，框架将调用[update]方法。在这个方法中，[RenderObjectElement]应该为每个子对象调
/// 用[updateChild]，传入在[mount]期间或上次运行[update]时获得的[Element]（以最近发生的为准）、
/// 新的[Widget]和槽。这将为对象提供一个新的[Element] 对象列表。
///
/// 在可能的情况下，[update]方法应尝试将上次传递的元素映射到新传递的小组件（widgets）。例如，
/// 如果上一次传递的元素中的一个元素配置了特定的 [Key]，而新传递中的一个小组件具有相同的 Key，
/// 则应将它们配对，并将旧元素与小组件（以及与新小组件的新位置相对应的插槽）一起更新。在这方面，
/// [updateChildren]方法可能很有用。
///
/// [updateChild]应该按照逻辑顺序为子程序调用。顺序可能很重要；例如，如果两个子代在它们的构
/// 建（build）方法中使用了[PageStorage]的 "writeState "功能（并且都没有[Widget.key]），
/// 那么第一个子代写入的状态将被第二个子代覆盖。
///
/// 1.3.1 在构建（build）阶段，动态地确定子代（children）的身份
/// Child widgets不一定要从这个元素的widget中逐字逐句地产生，它们可以从回调中动态生成，或
/// 者以其他更有创意的方式生成。
///
/// 1.3.2 在布局过程中动态地确定子代
///
/// 如果要在布局时生成widgets，那么在[mount]和[update]方法中生成widgets是行不通的：此时
/// 这个元素的渲染对象的布局还没有开始。相反，[update]方法可以将渲染对象标记为需要布局
/// （参见[RenderObject.markNeedsLayout]），然后渲染对象的[RenderObject.performLayout]
/// 方法可以回调到该element，让它生成widgets，并相应调用[updateChild]。
///
/// 对于渲染对象（render object ）在布局期间调用元素（element），它必须使用
/// [RenderObject.invokeLayoutCallback]。对于一个元素（element）在其[update]方法之外调用
/// [updateChild]，它必须使用[BuildOwner.buildScope]。
///
/// 框架在正常操作中提供了比在布局时进行构建时更多的检查。出于这个原因，创建具有布局时构建语
/// 义的widget应该非常小心。
///
/// 1.3.3 处理构建（build）时的错误
///
/// 如果一个元素（element）调用builder函数为它的子元素获取widgets，它可能会发现build会抛
/// 出一个异常。这种异常应该使用[FlutterError.reportError]来捕获和报告。如果需要一个子元素，
/// 但构建器以这种方式失败了，可以使用[ErrorWidget]的实例来代替。
///
/// 1.4 脱离children
///
/// 当使用[GlobalKey]时，有可能在这个元素更新之前，另一个元素就主动删除了一个子树。具体来说，
/// 当根植于具有特定[GlobalKey]的小组件（widget）的子树被从这个元素移动到构建阶段早期处理的
/// 元素（element）时，就会发生这种情况）。当这种情况发生时，这个元素的[forgetChild]方法将
/// 被调用，并引用到受影响的子元素。
///
/// [RenderObjectElement]子类的[forgetChild]方法必须从其子元素列表中删除子元素，这样当它
/// 下次[update]其子元素时，就不会考虑删除的子元素。
///
/// 出于性能的考虑，如果有很多元素（element），通过将它们存储在[Set]中来跟踪哪些元素被遗忘，
/// 而不是主动突变子列表的本地记录和所有插槽的身份，可能会更快。例如，参见[MultiChildRenderObjectElement]的实现。
///
/// 1.5 维护渲染对象树
///
/// 一旦子代产生一个渲染对象，它将调用[insertRenderObjectChild]。如果子孙的槽位改变身份，
/// 它将调用[moveRenderObjectChild]。如果一个子代消失了，它将调用[removeRenderObjectChild]。
///
/// 这三个方法应该相应地更新渲染树，分别将给定的子渲染对象从这个元素自己的渲染对象上附加、移动、脱离。
///
/// 1.6 遍历 children
///
/// 如果一个[RenderObjectElement]对象有任何子对象[Element]，它必须在实现[visitChildren]方法时暴露它们。
/// 这个方法被框架的许多内部机制使用，所以应该是快速的。它也被测试框架和[debugDumpApp]使用。
///
abstract class RenderObjectElement extends Element {
  /// Creates an element that uses the given widget as its configuration.
  /// 使用给定的配置创建一个新的element
  RenderObjectElement(RenderObjectWidget widget) : super(widget);

  @override
  RenderObjectWidget get widget => super.widget as RenderObjectWidget;

  /// The underlying [RenderObject] for this element.
  /// 该元素的底层[RenderObject]
  @override
  RenderObject get renderObject => _renderObject!;
  RenderObject? _renderObject;

  RenderObjectElement? _ancestorRenderObjectElement;

  RenderObjectElement? _findAncestorRenderObjectElement() {
    Element? ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement)
      ancestor = ancestor._parent;
    return ancestor as RenderObjectElement?;
  }

  ParentDataElement<ParentData>? _findAncestorParentDataElement() {
    Element? ancestor = _parent;
    ParentDataElement<ParentData>? result;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      if (ancestor is ParentDataElement<ParentData>) {
        result = ancestor;
        break;
      }
      ancestor = ancestor._parent;
    }
    return result;
  }

  ///
  /// 在挂载[mount]的时候，使用widget#createRenderObject 创建对应的RenderObject
  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    //创建RenderObject
    _renderObject = widget.createRenderObject(this);
    //将RenderObject附着到新的槽位
    attachRenderObject(newSlot);
    //标记为dirty
    _dirty = false;
  }

  @override
  void update(covariant RenderObjectWidget newWidget) {
    super.update(newWidget);
    //更新RenderObject
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  ///重新构建
  @override
  void performRebuild() {
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  /// Updates the children of this element to use new widgets.
  ///
  /// Attempts to update the given old children list using the given new
  /// widgets, removing obsolete elements and introducing new ones as necessary,
  /// and then returns the new child list.
  ///
  /// During this function the `oldChildren` list must not be modified. If the
  /// caller wishes to remove elements from `oldChildren` re-entrantly while
  /// this function is on the stack, the caller can supply a `forgottenChildren`
  /// argument, which can be modified while this function is on the stack.
  /// Whenever this function reads from `oldChildren`, this function first
  /// checks whether the child is in `forgottenChildren`. If it is, the function
  /// acts as if the child was not in `oldChildren`.
  ///
  /// This function is a convenience wrapper around [updateChild], which updates
  /// each individual child. When calling [updateChild], this function uses an
  /// [IndexedSlot<Element>] as the value for the `newSlot` argument.
  /// [IndexedSlot.index] is set to the index that the currently processed
  /// `child` corresponds to in the `newWidgets` list and [IndexedSlot.value] is
  /// set to the [Element] of the previous widget in that list (or null if it is
  /// the first child).
  ///
  /// When the [slot] value of an [Element] changes, its
  /// associated [renderObject] needs to move to a new position in the child
  /// list of its parents. If that [RenderObject] organizes its children in a
  /// linked list (as is done by the [ContainerRenderObjectMixin]) this can
  /// be implemented by re-inserting the child [RenderObject] into the
  /// list after the [RenderObject] associated with the [Element] provided as
  /// [IndexedSlot.value] in the [slot] object.
  ///
  /// Simply using the previous sibling as a [slot] is not enough, though, because
  /// child [RenderObject]s are only moved around when the [slot] of their
  /// associated [RenderObjectElement]s is updated. When the order of child
  /// [Element]s is changed, some elements in the list may move to a new index
  /// but still have the same previous sibling. For example, when
  /// `[e1, e2, e3, e4]` is changed to `[e1, e3, e4, e2]` the element e4
  /// continues to have e3 as a previous sibling even though its index in the list
  /// has changed and its [RenderObject] needs to move to come before e2's
  /// [RenderObject]. In order to trigger this move, a new [slot] value needs to
  /// be assigned to its [Element] whenever its index in its
  /// parent's child list changes. Using an [IndexedSlot<Element>] achieves
  /// exactly that and also ensures that the underlying parent [RenderObject]
  /// knows where a child needs to move to in a linked list by providing its new
  /// previous sibling.
  @protected
  List<Element> updateChildren(List<Element> oldChildren, List<Widget> newWidgets, { Set<Element>? forgottenChildren }) {

    Element? replaceWithNullIfForgotten(Element child) {
      return forgottenChildren != null && forgottenChildren.contains(child) ? null : child;
    }

    // This attempts to diff the new child list (newWidgets) with
    // the old child list (oldChildren), and produce a new list of elements to
    // be the new list of child elements of this element. The called of this
    // method is expected to update this render object accordingly.

    // The cases it tries to optimize for are:
    //  - the old list is empty
    //  - the lists are identical
    //  - there is an insertion or removal of one or more widgets in
    //    only one place in the list
    // If a widget with a key is in both lists, it will be synced.
    // Widgets without keys might be synced but there is no guarantee.

    // The general approach is to sync the entire new list backwards, as follows:
    // 1. Walk the lists from the top, syncing nodes, until you no longer have
    //    matching nodes.
    // 2. Walk the lists from the bottom, without syncing nodes, until you no
    //    longer have matching nodes. We'll sync these nodes at the end. We
    //    don't sync them now because we want to sync all the nodes in order
    //    from beginning to end.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys and sync null with non-keyed items.
    // 4. Walk the narrowed part of the new list forwards:
    //     * Sync non-keyed items with null
    //     * Sync keyed items with the source if it exists, else with null.
    // 5. Walk the bottom of the list again, syncing the nodes.
    // 6. Sync null with any items in the list of keys that are still
    //    mounted.

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    final List<Element> newChildren = oldChildren.length == newWidgets.length ?
    oldChildren : List<Element>.filled(newWidgets.length, _NullElement.instance, growable: false);

    Element? previousChild;

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
      final Widget newWidget = newWidgets[newChildrenTop];
      assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      final Element newChild = updateChild(oldChild, newWidget, IndexedSlot<Element?>(newChildrenTop, previousChild))!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenBottom]);
      final Widget newWidget = newWidgets[newChildrenBottom];
      assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element>? oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, Element>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final Element? oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
        assert(oldChild == null || oldChild._lifecycleState == _ElementLifecycle.active);
        if (oldChild != null) {
          if (oldChild.widget.key != null)
            oldKeyedChildren[oldChild.widget.key!] = oldChild;
          else
            deactivateChild(oldChild);
        }
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      Element? oldChild;
      final Widget newWidget = newWidgets[newChildrenTop];
      if (haveOldChildren) {
        final Key? key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren![key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || Widget.canUpdate(oldChild.widget, newWidget));
      final Element newChild = updateChild(oldChild, newWidget, IndexedSlot<Element?>(newChildrenTop, previousChild))!;
      assert(newChild._lifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild == null || oldChild._lifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
    }

    // We've scanned the whole list.
    newChildrenBottom = newWidgets.length - 1;
    oldChildrenBottom = oldChildren.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild = oldChildren[oldChildrenTop];
      final Widget newWidget = newWidgets[newChildrenTop];
      final Element newChild = updateChild(oldChild, newWidget, IndexedSlot<Element?>(newChildrenTop, previousChild))!;
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Clean up any of the remaining middle nodes from the old list.
    if (haveOldChildren && oldKeyedChildren!.isNotEmpty) {
      for (final Element oldChild in oldKeyedChildren.values) {
        if (forgottenChildren == null || !forgottenChildren.contains(oldChild))
          deactivateChild(oldChild);
      }
    }
    assert(newChildren.every((Element element) => element is! _NullElement));
    return newChildren;
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    widget.didUnmountRenderObject(renderObject);
  }

  void _updateParentData(ParentDataWidget<ParentData> parentDataWidget) {
    bool applyParentData = true;
    if (applyParentData)
      parentDataWidget.applyParentData(renderObject);
  }

  @override
  void _updateSlot(dynamic newSlot) {
    final dynamic oldSlot = slot;
    super._updateSlot(newSlot);
    _ancestorRenderObjectElement!.moveRenderObjectChild(renderObject, oldSlot, slot);
  }

  /// 附着RenderObject
  @override
  void attachRenderObject(dynamic newSlot) {
    //记录新的槽位
    _slot = newSlot;
    //找到祖先RenderObjectElement
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    //将RenderObject插入到祖先RenderObjectElement
    _ancestorRenderObjectElement?.insertRenderObjectChild(renderObject, newSlot);

    final ParentDataElement<ParentData>? parentDataElement = _findAncestorParentDataElement();
    if (parentDataElement != null)
      _updateParentData(parentDataElement.widget);
  }

  ///脱离RenderObject
  @override
  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement!.removeRenderObjectChild(renderObject, slot);
      _ancestorRenderObjectElement = null;
    }
    _slot = null;
  }

  /// Insert the given child into [renderObject] at the given slot.
  ///
  /// {@macro flutter.widgets.RenderObjectElement.insertRenderObjectChild}
  ///
  /// ## Deprecation
  ///
  /// This method has been deprecated in favor of [insertRenderObjectChild].
  ///
  /// The reason for the deprecation is to provide the `oldSlot` argument to
  /// the [moveRenderObjectChild] method (such an argument was missing from
  /// the now-deprecated [moveChildRenderObject] method) and the `slot`
  /// argument to the [removeRenderObjectChild] method (such an argument was
  /// missing from the now-deprecated [removeChildRenderObject] method). While
  /// no argument was added to [insertRenderObjectChild], the name change (and
  /// corresponding deprecation) was made to maintain naming parity with the
  /// other two methods.
  ///
  /// To migrate, simply override [insertRenderObjectChild] instead of
  /// [insertChildRenderObject]. The arguments stay the same. Subclasses should
  /// _not_ call `super.insertRenderObjectChild(...)`.
  @protected
  @mustCallSuper
  @Deprecated(
      'Override insertRenderObjectChild instead. '
          'This feature was deprecated after v1.21.0-9.0.pre.'
  )
  void insertChildRenderObject(covariant RenderObject child, covariant dynamic slot) {
  }

  /// 将传入的child插入到[renderObject]的给定槽位
  ///
  /// {@template flutter.widgets.RenderObjectElement.insertRenderObjectChild}
  /// The semantics of `slot` are determined by this element. For example, if
  /// this element has a single child, the slot should always be null. If this
  /// element has a list of children, the previous sibling element wrapped in an
  /// [IndexedSlot] is a convenient value for the slot.
  /// {@endtemplate}
  @protected
  void insertRenderObjectChild(covariant RenderObject child, covariant dynamic slot) {
    insertChildRenderObject(child, slot);
  }

  /// Move the given child to the given slot.
  ///
  /// The given child is guaranteed to have [renderObject] as its parent.
  ///
  /// {@macro flutter.widgets.RenderObjectElement.insertRenderObjectChild}
  ///
  /// This method is only ever called if [updateChild] can end up being called
  /// with an existing [Element] child and a `slot` that differs from the slot
  /// that element was previously given. [MultiChildRenderObjectElement] does this,
  /// for example. [SingleChildRenderObjectElement] does not (since the `slot` is
  /// always null). An [Element] that has a specific set of slots with each child
  /// always having the same slot (and where children in different slots are never
  /// compared against each other for the purposes of updating one slot with the
  /// element from another slot) would never call this.
  ///
  /// ## Deprecation
  ///
  /// This method has been deprecated in favor of [moveRenderObjectChild].
  ///
  /// The reason for the deprecation is to provide the `oldSlot` argument to
  /// the [moveRenderObjectChild] method (such an argument was missing from
  /// the now-deprecated [moveChildRenderObject] method) and the `slot`
  /// argument to the [removeRenderObjectChild] method (such an argument was
  /// missing from the now-deprecated [removeChildRenderObject] method). While
  /// no argument was added to [insertRenderObjectChild], the name change (and
  /// corresponding deprecation) was made to maintain naming parity with the
  /// other two methods.
  ///
  /// To migrate, simply override [moveRenderObjectChild] instead of
  /// [moveChildRenderObject]. The `slot` argument becomes the `newSlot`
  /// argument, and the method will now take a new `oldSlot` argument that
  /// subclasses may find useful. Subclasses should _not_ call
  /// `super.moveRenderObjectChild(...)`.
  @protected
  @mustCallSuper
  @Deprecated(
      'Override moveRenderObjectChild instead. '
          'This feature was deprecated after v1.21.0-9.0.pre.'
  )
  void moveChildRenderObject(covariant RenderObject child, covariant dynamic slot) {
  }

  /// Move the given child from the given old slot to the given new slot.
  ///
  /// The given child is guaranteed to have [renderObject] as its parent.
  ///
  /// {@macro flutter.widgets.RenderObjectElement.insertRenderObjectChild}
  ///
  /// This method is only ever called if [updateChild] can end up being called
  /// with an existing [Element] child and a `slot` that differs from the slot
  /// that element was previously given. [MultiChildRenderObjectElement] does this,
  /// for example. [SingleChildRenderObjectElement] does not (since the `slot` is
  /// always null). An [Element] that has a specific set of slots with each child
  /// always having the same slot (and where children in different slots are never
  /// compared against each other for the purposes of updating one slot with the
  /// element from another slot) would never call this.
  @protected
  void moveRenderObjectChild(covariant RenderObject child, covariant dynamic oldSlot, covariant dynamic newSlot) {
    moveChildRenderObject(child, newSlot);
  }

  /// Remove the given child from [renderObject].
  ///
  /// The given child is guaranteed to have [renderObject] as its parent.
  ///
  /// ## Deprecation
  ///
  /// This method has been deprecated in favor of [removeRenderObjectChild].
  ///
  /// The reason for the deprecation is to provide the `oldSlot` argument to
  /// the [moveRenderObjectChild] method (such an argument was missing from
  /// the now-deprecated [moveChildRenderObject] method) and the `slot`
  /// argument to the [removeRenderObjectChild] method (such an argument was
  /// missing from the now-deprecated [removeChildRenderObject] method). While
  /// no argument was added to [insertRenderObjectChild], the name change (and
  /// corresponding deprecation) was made to maintain naming parity with the
  /// other two methods.
  ///
  /// To migrate, simply override [removeRenderObjectChild] instead of
  /// [removeChildRenderObject]. The method will now take a new `slot` argument
  /// that subclasses may find useful. Subclasses should _not_ call
  /// `super.removeRenderObjectChild(...)`.
  @protected
  @mustCallSuper
  @Deprecated(
      'Override removeRenderObjectChild instead. '
          'This feature was deprecated after v1.21.0-9.0.pre.'
  )
  void removeChildRenderObject(covariant RenderObject child) {
  }

  /// Remove the given child from [renderObject].
  ///
  /// The given child is guaranteed to have been inserted at the given `slot`
  /// and have [renderObject] as its parent.
  @protected
  void removeRenderObjectChild(covariant RenderObject child, covariant dynamic slot) {
    removeChildRenderObject(child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RenderObject>('renderObject', _renderObject, defaultValue: null));
  }
}
