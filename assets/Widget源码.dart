/// [Element]的配置
///
///A widget是对用户界面一部分的不可改变的描述。widget可以膨胀成element，它管理底层的渲染树。
///
///Widgets本身没有可更改的状态（它们的所有字段必须是final的）。如果您希望将可更改的状态与widget关联起来，
///请考虑使用 [StatefulWidget]，当它被膨胀成一个element并纳入树中时，
///它会创建一个 [State] 对象（通过 [StatefulWidget.createState]）。
///
///一个widget可以被包含在树中零次或多次。特别是，一个给定的widget可以被多次放入树中。
///每当一个widget被放置在树中，它就会被膨胀成一个 [Element]，这意味着一个多次被纳入树中的widget会被膨胀多次。
///
/// [key]属性控制一个widget如何替换树中的另一个widget。
/// 如果两个widget的 [runtimeType] 和 [key] 属性分别相等 [operator==]，则新widget通过更新底层element（即用新widget调用 [Element.update] ）来替换旧的widget。
/// 否则，旧element将从树中移除，新widget将被膨胀为一个新element，新element将插入树中。
///
///

@immutable
abstract class Widget extends DiagnosticableTree {
  /// Initializes [key] for subclasses.
  const Widget({ this.key });

  /// 控制一个widget如何替换树中的另一个widget。
  ///
  /// 如果两个widget的 [runtimeType] 和 [key] 属性分别相等 [operator==]，
  /// 那么新widget通过更新底层元素（即用新widget调用 [Element.update] ）来替换旧widget。
  /// 否则，旧element将从树中移除，新widget将被膨胀为一个新element，新element将插入树中。
  ///
  ///   此外，使用[GlobalKey]作为widget的[key]，允许该元素（element）在树上移动（更换parent）而不丢失状态。
  ///   当发现一个新的widget（它的key和type与同一位置的前一个widget不匹配），但在前一帧树的其他地方有一个具有
  ///   相同global key的widget，那么该widget的元素将被移动到新的位置。
  ///
  /// 一般来说，一个widget是另一个widget的唯一孩子，不需要显式key。
  ///
  final Key? key;

  ///将此配置注入到一个具体的实例中
  ///
  ///一个给定的widget可以被包含在树中零次或多次。特别是，一个给定的widget可以被多次放入树中。
  ///每当一个widget被放置在树中，它就会被膨胀成一个[Element]，这意味着一个多次被纳入树中的小组件会被膨胀多次。
  ///
  /// 在Element的inflateWidget方法中被调用：
  /// Element inflateWidget(Widget newWidget, dynamic newSlot) {
  ///   ...
  ///   final Element newChild = newWidget.createElement();
  ///   ...
  /// }
  ///
  @protected
  @factory
  Element createElement();


  ///"newWidget "是否可用于更新目前以 "oldWidget "为配置的[Element]。
  ///
  /// 使用给定widget作为配置的element可以被更新为使用另一个widget作为配置，
  /// 条件是且仅当两个widget的[runtimeType]和[key]属性相等[operator==]。
  ///
  /// 如果widgets没有key（它们的key是空的），
  /// 那么如果它们具有相同的类型，即使它们的子代完全不同，也被认为是相等的。
  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType
        && oldWidget.key == newWidget.key;
  }

}
