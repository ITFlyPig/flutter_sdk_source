abstract class StatefulWidget extends Widget {
  /// Initializes [key] for subclasses.
  const StatefulWidget({ Key? key }) : super(key: key);

  /// 创建一个[StatefulElement]来管理该widget在树上的位置
  ///
  /// 子类一般是不覆盖这个方法的。
  @override
  StatefulElement createElement() => StatefulElement(this);

  /// 在树中给定的位置为该widget创建可变状态。
  ///
  /// 子类应该重写这个方法，以返回一个新创建的和widget关联的[State]子类实例：
  ///
  /// ```dart
  /// @override
  /// _MyState createState() => _MyState();
  /// ```
  /// 框架可以在[StatefulWidget]的生命周期内多次调用该方法。例如，如果小组件插入树中多个
  /// 位置，则框架将为每个位置创建一个单独的 [State] 对象。同样，如果小组件从树中移除，然后
  /// 再次插入树中，框架将再次调用[createState]来创建一个新的[State]对象，从而简化了[State]对象的生命周期。
  ///
  @protected
  @factory
  State createState(); // ignore: no_logic_in_create_state, this is the original sin
}
