abstract class StatefulWidget extends Widget {
  /// Initializes [key] for subclasses.
  const StatefulWidget({Key? key}) : super(key: key);

  /// Creates a [StatefulElement] to manage this widget's location in the tree.
  ///
  /// It is uncommon for subclasses to override this method.
  @override
  StatefulElement createElement() => StatefulElement(this);

  /// 在树中给定的位置为这个部件创建可变的状态。
  ///
  /// 子类应该覆盖这个方法以返回其相关的[State]子类的一个新创建的实例。
  ///
  /// ```dart
  /// @override
  /// _MyState createState() => _MyState();
  /// ```
  ///
  /// 框架可以在一个[StatefulWidget]的生命周期内多次调用这个方法。例如，如果该部件被插入到
  /// 树的多个位置，框架将为每个位置创建一个单独的[State]对象。同样地，如果该部件从树上被移除，
  /// 后来又被插入树中，框架将再次调用[createState]来创建一个新的[State]对象，从而简化了[State]对象的生命周期。
  @protected
  @factory
  State
      createState(); // ignore: no_logic_in_create_state, this is the original sin
}
