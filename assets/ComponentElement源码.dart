
/// 用来组成其他[Element]
///
/// [ComponentElement]不是直接创建一个[RenderObject]，而是通过创建其他[Element]间接创建[RenderObject]。
///
/// 对比[RenderObjectElement]
abstract class ComponentElement extends Element {
  /// Creates an element that uses the given widget as its configuration.
  ComponentElement(Widget widget) : super(widget);

  Element? _child;

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _firstBuild();
  }

  /// 第一次构建
  void _firstBuild() {
    rebuild();
  }

  /// 调用[StatelessWidget]对象的[StatelessWidget.build]方法（对于无状态小组件）
  /// 或[State]对象的[State.build]方法（对于有状态小组件），然后更新小组件树。
  ///
  /// 在[mount]时自动调用，生成第一次构建，当元素需要更新时，由[rebuild]调用。
  @override
  void performRebuild() {

    Widget? built;
    try {
      built = build();
    } catch (e, stack) {
    } finally {
      // We delay marking the element as clean until after calling build() so
      // that attempts to markNeedsBuild() during build() will be ignored.
      _dirty = false;
    }
    try {
      _child = updateChild(_child, built, slot);
    } catch (e, stack) {
      _child = updateChild(null, built, slot);
    }

    if (!kReleaseMode && debugProfileBuildsEnabled)
      Timeline.finishSync();
  }

  /// Subclasses should override this function to actually call the appropriate
  /// `build` function (e.g., [StatelessWidget.build] or [State.build]) for
  /// their widget.
  @protected
  Widget build();

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child!);
  }

  @override
  void forgetChild(Element child) {
    _child = null;
    super.forgetChild(child);
  }
}
