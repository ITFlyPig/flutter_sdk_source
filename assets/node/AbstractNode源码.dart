///
/// 树中的一个抽象节点
/// AbstractNode有深度（depth）、附着（attachment）、父母（parent）的概念，但没有children的模型。
///
/// 当一个子类改变child的parent时，它应该酌情调用`parent.adopChild(child)`或
/// `parent.dropChild(child)`。如果需要的话，子类可以公开一个API来操作树（
/// 例如，一个`child`的setter，或者一个`add()`方法来操作一个列表）。
///
/// 当前节点的父节点由[parent]属性暴露。
///
/// 当前的f附着状态由 [attached] 暴露。任何被认为是要附着的树的根部都应该通过调用[attach]
/// 来手动附着。除此之外，不应该直接调用[attach]和[detach]方法，附着是由前面提到的[adopChild]
/// 和[dropChild]方法自动管理的。
///
/// 有children的子类必须覆盖[attach]和[detach]，如这些方法的文档中所述。
///
/// 节点的深度[depth] 总是大于其祖先的。同胞之间的深度没有保证。节点的深度是用来保证节点按深
/// 度顺序处理的。子节点的深度[depth] 可以比父节点的深度[depth] 大一个以上，因为深度[depth]
/// 值永远不会减少：所有重要的是它比父节点大。考虑一棵树，它有一个根节点A，一个子节点B，和一个孙
/// 节点C，最初，A的深度[depth] 为0，B的深度[depth] 为1，C的深度[depth] 为2。如果C被移动到A的
/// 子节点，B的兄弟姐妹，那么数字不会改变。C的深度[depth] 仍然是2。深度[depth] 是由[adopChild]
/// 和[dropChild]方法自动维护的。
///
class AbstractNode {
  /// The depth of this node in the tree.
  ///
  /// The depth of nodes in a tree monotonically increases as you traverse down
  /// the tree.
  int get depth => _depth;
  int _depth = 0;

  /// Adjust the [depth] of the given [child] to be greater than this node's own
  /// [depth].
  ///
  /// Only call this method from overrides of [redepthChildren].
  @protected
  void redepthChild(AbstractNode child) {
    assert(child.owner == owner);
    if (child._depth <= _depth) {
      child._depth = _depth + 1;
      child.redepthChildren();
    }
  }

  /// Adjust the [depth] of this node's children, if any.
  ///
  /// Override this method in subclasses with child nodes to call [redepthChild]
  /// for each child. Do not call this method directly.
  void redepthChildren() {}

  /// The owner for this node (null if unattached).
  ///
  /// The entire subtree that this node belongs to will have the same owner.
  Object? get owner => _owner;
  Object? _owner;

  /// Whether this node is in a tree whose root is attached to something.
  ///
  /// This becomes true during the call to [attach].
  ///
  /// This becomes false during the call to [detach].
  bool get attached => _owner != null;

  /// Mark this node as attached to the given owner.
  ///
  /// Typically called only from the [parent]'s [attach] method, and by the
  /// [owner] to mark the root of a tree as attached.
  ///
  /// Subclasses with children should override this method to first call their
  /// inherited [attach] method, and then [attach] all their children to the
  /// same [owner].
  @mustCallSuper
  void attach(covariant Object owner) {
    assert(owner != null);
    assert(_owner == null);
    _owner = owner;
  }

  /// Mark this node as detached.
  ///
  /// Typically called only from the [parent]'s [detach], and by the [owner] to
  /// mark the root of a tree as detached.
  ///
  /// Subclasses with children should override this method to first call their
  /// inherited [detach] method, and then [detach] all their children.
  @mustCallSuper
  void detach() {
    assert(_owner != null);
    _owner = null;
    assert(parent == null || attached == parent!.attached);
  }

  /// The parent of this node in the tree.
  AbstractNode? get parent => _parent;
  AbstractNode? _parent;

  /// Mark the given node as being a child of this node.
  ///
  /// Subclasses should call this function when they acquire a new child.
  @protected
  @mustCallSuper
  void adoptChild(covariant AbstractNode child) {
    assert(child != null);
    assert(child._parent == null);
    assert(() {
      AbstractNode node = this;
      while (node.parent != null) node = node.parent!;
      assert(node != child); // indicates we are about to create a cycle
      return true;
    }());
    child._parent = this;
    if (attached) child.attach(_owner!);
    redepthChild(child);
  }

  /// Disconnect the given node from this node.
  ///
  /// Subclasses should call this function when they lose a child.
  @protected
  @mustCallSuper
  void dropChild(covariant AbstractNode child) {
    assert(child != null);
    assert(child._parent == this);
    assert(child.attached == attached);
    child._parent = null;
    if (attached) child.detach();
  }
}
