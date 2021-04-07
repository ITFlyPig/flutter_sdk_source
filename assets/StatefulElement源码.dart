/// 使用[StatefulWidget]作为配置的[Element]
class StatefulElement extends ComponentElement {
  /// Element构造函数
  /// 在构造函数中，使用StatefulWidget实例创建对应的[State]实例
  StatefulElement(StatefulWidget widget)
      : state = widget.createState(),
        super(widget) {
    //为[State] 赋值 context对象
    //Wie[State]赋值 widget对象
    state._element = this;
    state._widget = widget;
  }

  @override
  Widget build() => state.build(this);

  /// The [State] instance associated with this location in the tree.
  ///
  /// There is a one-to-one relationship between [State] objects and the
  /// [StatefulElement] objects that hold them. The [State] objects are created
  /// by [StatefulElement] in [mount].
  final State<StatefulWidget> state;

  @override
  void reassemble() {
    state.reassemble();
    super.reassemble();
  }

  @override
  void _firstBuild() {
    try {
      final dynamic debugCheckForReturnedFuture = state.initState() as dynamic;
    } finally {
    }
    state.didChangeDependencies();
    super._firstBuild();
  }

  @override
  void performRebuild() {
    if (_didChangeDependencies) {
      state.didChangeDependencies();
      _didChangeDependencies = false;
    }
    super.performRebuild();
  }

  @override
  void update(StatefulWidget newWidget) {
    super.update(newWidget);
    final StatefulWidget oldWidget = state._widget!;
    // We mark ourselves as dirty before calling didUpdateWidget to
    // let authors call setState from within didUpdateWidget without triggering
    // asserts.
    _dirty = true;
    state._widget = widget as StatefulWidget;
    try {
      final dynamic debugCheckForReturnedFuture = state.didUpdateWidget(oldWidget) as dynamic;
    } finally {
    }
    rebuild();
  }

  @override
  void activate() {
    super.activate();
    // Since the State could have observed the deactivate() and thus disposed of
    // resources allocated in the build method, we have to rebuild the widget
    // so that its State can reallocate its resources.
    markNeedsBuild();
  }

  @override
  void deactivate() {
    state.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    state.dispose();
    state._element = null;
  }

  @override
  InheritedWidget dependOnInheritedElement(Element ancestor, { Object? aspect }) {
    return super.dependOnInheritedElement(ancestor as InheritedElement, aspect: aspect);
  }

  /// This controls whether we should call [State.didChangeDependencies] from
  /// the start of [build], to avoid calls when the [State] will not get built.
  /// This can happen when the widget has dropped out of the tree, but depends
  /// on an [InheritedWidget] that is still in the tree.
  ///
  /// It is set initially to false, since [_firstBuild] makes the initial call
  /// on the [state]. When it is true, [build] will call
  /// `state.didChangeDependencies` and then sets it to false. Subsequent calls
  /// to [didChangeDependencies] set it to true.
  bool _didChangeDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _didChangeDependencies = true;
  }


}
