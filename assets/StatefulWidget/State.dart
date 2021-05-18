/// State是有状态小组件[StatefulWidget]的逻辑和内部状态。状态信息可以：
/// (1) 在小组件建立时同步读取；
/// (2) 在小组件的生命周期内可能发生变化。
/// 小部件实现者有责任确保在这种状态改变时，使用[State.setState]及时通知[State]。
///
/// 当膨胀[inflate]一个[StatefulWidget]以将其插入到树中时，框架通过调用
/// [StatefulWidget.createState]方法来创建[State]对象。因为一个给定的[StatefulWidget]
/// 实例可以被膨胀(inflated)多次（例如，该部件一次在多个地方被纳入树中），所以可能会有一个以
/// 上的[State]对象与一个给定的[StatefulWidget]实例相关。同样，如果一个[StatefulWidget]
/// 被从树中移除，后来又被插入到树中，框架将再次调用[StatefulWidget.createState]来创建一个
/// 新的[State]对象，从而简化了[State]对象的生命周期。
///
/// [State]对象具有以下的生命周期：
/// * 框架调用[StatefulWidget.createState]创建一个[State]对象。
/// * 新创建的[State]对象与一个[BuildContext]相关联。这种关联是永久性的：[State]对象将永
///   远不会改变它的[BuildContext]。然而，[BuildContext]本身可以和它的子树一起在树上移动。
///   此时，[State]对象被认为是[mounted]的。
/// * 然后框架调用[initState]。[State]的子类应该覆盖[initState]来执行一次性初始化，这取
///   决于[BuildContext]或部件，当[initState]方法被调用时，它们分别作为[context]和[widget]属性可用。
/// * 然后框架调用[didChangeDependencies]。[State]的子类应该覆盖[didChangeDependencies]
///   来执行涉及[InheritedWidget]的初始化。如果[BuildContext.dependOnInheritedWidgetOfExactType]
///   被调用，如果继承的部件随后发生变化，或者部件在树中移动，[didChangeDependencies]方法将
///   被再次调用。
/// * 此时，[State]对象已经完全初始化，框架可能会多次调用其[build]方法以获得该子树的用户界
///   面的描述。[State]对象可以通过调用它们的[setState]方法自发地请求重建它们的子树，这表
///   明它们的一些内部状态已经发生了变化，可能影响到这个子树的用户界面。
/// * 在这段时间里，一个父部件可能会重建并请求更新树中的这个位置以显示一个具有相同[runtimeType]
///   和[Widget.key]的新部件。当这种情况发生时，框架将更新[widget]属性以引用新的widget，然后
///   调用[didUpdateWidget]方法，并将旧的的widget作为参数。[State]对象应该覆盖[didUpdateWidget]
///   以响应其相关的widget的变化（例如，启动隐含的动画）。框架总是在调用[didUpdateWidget]后调用
///   [build]，这意味着在[didUpdateWidget]中对[setState]的任何调用都是多余的。
/// * 在开发过程中，如果发生热重载（无论是从命令行`flutter`工具按`r`启动，还是从IDE启动），
///   [reassemble]方法被调用。这提供了一个机会来重新初始化在[initState]方法中准备的任何数据。
/// * 如果包含[State]对象的子树被从树中移除（例如，因为父类建立了一个具有不同[runtimeType]或[Widget.key]的部件），
///   框架会调用[deactivate]方法。子类应该覆盖这个方法来清理这个对象和树中其他元素之间的任何
///   链接（例如，如果你为祖先提供了一个指向子孙的[RenderObject]的指针）。
/// * 此时，框架可能会将这个子树重新插入到树的另一部分。如果发生这种情况，框架将确保它调用[build]
///   来给[State]对象一个机会来适应它在树中的新位置。如果框架真的重新插入这个子树，它将在子
///   树被从树中移除的动画帧结束前完成。由于这个原因，[State]对象可以推迟释放大部分资源，直到
///   框架调用它们的[dispose]方法。
/// * 如果框架在当前动画帧结束前没有重新插入这个子树，框架将调用[dispose]，这表明这个[State]
///   对象将不再使用。子类应该覆盖这个方法来释放这个对象所保留的任何资源（例如，停止任何活动的动画）。
/// * 在框架调用[dispose]后，[State]对象被认为是未挂载(unmounted)的，[mounted]属性为假。
///   在这个时候调用[setState]是一个错误。生命周期终结了：没有办法重新安装一个已经被disposed的[State]对象。
///
/// See also:
///
/// * [InheritedWidget]，用于引入环境状态的小组件，这些状态可以被后代小组件读取。
///
@optionalTypeArgs
abstract class State<T extends StatefulWidget> with Diagnosticable {
  /// The current configuration.
  ///
  /// A [State] object's configuration is the corresponding [StatefulWidget]
  /// instance. This property is initialized by the framework before calling
  /// [initState]. If the parent updates this location in the tree to a new
  /// widget with the same [runtimeType] and [Widget.key] as the current
  /// configuration, the framework will update this property to refer to the new
  /// widget and then call [didUpdateWidget], passing the old configuration as
  /// an argument.
  T get widget => _widget!;
  T? _widget;

  /// The current stage in the lifecycle for this state object.
  ///
  /// This field is used by the framework when asserts are enabled to verify
  /// that [State] objects move through their lifecycle in an orderly fashion.
  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  /// Verifies that the [State] that was created is one that expects to be
  /// created for that particular [Widget].
  bool _debugTypesAreRight(Widget widget) => widget is T;

  /// The location in the tree where this widget builds.
  ///
  /// The framework associates [State] objects with a [BuildContext] after
  /// creating them with [StatefulWidget.createState] and before calling
  /// [initState]. The association is permanent: the [State] object will never
  /// change its [BuildContext]. However, the [BuildContext] itself can be moved
  /// around the tree.
  ///
  /// After calling [dispose], the framework severs the [State] object's
  /// connection with the [BuildContext].
  BuildContext get context {
    assert(() {
      if (_element == null) {
        throw FlutterError(
            'This widget has been unmounted, so the State no longer has a context (and should be considered defunct). \n'
            'Consider canceling any active work during "dispose" or using the "mounted" getter to determine if the State is still active.');
      }
      return true;
    }());
    return _element!;
  }

  StatefulElement? _element;

  /// 表示当前[State]对象是否在树中
  ///
  ///
  /// 在创建一个[State]对象之后，在调用[initState]之前，框架通过将其与[BuildContext]相关
  /// 联来 “挂载[mounts] "该[State]对象。在框架调用[dispose]之前，[State]对象一直被挂载，
  /// 之后框架将不再要求[State]对象进行[build]。
  ///
  /// 除非[mounted]为true，否则调用[setState]是一个错误。
  bool get mounted => _element != null;

  /// 当这个对象被插入到树中时被调用。
  ///
  /// 框架将为其创建的每个[State]对象精确地调用该方法一次。
  ///
  /// 覆盖此方法以执行初始化，这取决于此对象被插入树中的位置（即[context]）或用于配置此对象
  /// 的部件（即[widget]）。
  ///
  /// 如果一个[State]的[build]方法依赖于一个本身可以改变状态的对象，例如[ChangeNotifier]
  /// 或[Stream]，或者其他可以订阅接收通知的对象，那么一定要在[initState]、[didUpdateWidget]
  /// 和[dispose]中正确订阅和取消订阅：
  /// * 在[initState]中开始订阅；
  /// * 在[didUpdateWidget]中，取消对旧对象的订阅，开始对新的对象订阅；
  /// * 在[dispose]中，取消订阅
  ///
  /// 你不能从这个方法中使用 [BuildContext.dependOnInheritedWidgetOfExactType] 。
  /// 然而，[didChangeDependencies]将在此方法之后立即被调用，[BuildContext.dependOnInheritedWidgetOfExactType]可以在那里使用。
  ///
  /// 如果你覆盖了这个，请确保你的方法以调用super.initState()开始。
  @protected
  @mustCallSuper
  void initState() {
    assert(_debugLifecycleState == _StateLifecycle.created);
  }

  /// 每当小组件配置发生变化时，就会调用。
  ///
  /// 如果父部件重建并要求树中的这个位置更新以显示具有相同[runtimeType]和[Widget.key]的新
  /// 部件，框架将更新这个[State]对象的[widget]属性以引用新部件，然后以之前的部件作为参数调用这个方法。
  ///
  /// 覆盖此方法，以便在[widget]发生变化时做出反应（例如，启动隐含的动画）。
  ///
  /// 框架总是在调用[didUpdateWidget]后调用[build]，这意味着在[didUpdateWidget]中对
  /// [setState]的任何调用都是多余的。
  ///
  /// 如果你覆盖了这个，确保你的方法以调用super.didUpdateWidget(oldWidget)开始。
  ///
  @mustCallSuper
  @protected
  void didUpdateWidget(covariant T oldWidget) {}

  /// {@macro flutter.widgets.Element.reassemble}
  ///
  /// In addition to this method being invoked, it is guaranteed that the
  /// [build] method will be invoked when a reassemble is signaled. Most
  /// widgets therefore do not need to do anything in the [reassemble] method.
  ///
  /// See also:
  ///
  ///  * [Element.reassemble]
  ///  * [BindingBase.reassembleApplication]
  ///  * [Image], which uses this to reload images.
  @protected
  @mustCallSuper
  void reassemble() {}

  /// 通知框架这个对象的内部状态已经改变。
  ///
  /// 每当你改变一个[State]对象的内部状态时，在一个传递给[setState]的函数中做改变。
  ///
  /// ```dart
  /// setState(() { _myState = newValue; });
  /// ```
  ///
  /// 提供的回调被立即同步调用。它不能返回一个future（回调不能是 "async"），因为那样的话，
  /// 就不清楚状态到底是什么时候被设置的。
  ///
  /// 调用[setState]通知框架，这个对象的内部状态发生了变化，可能会影响到这个子树的用户界面，
  /// 这将导致框架为这个[State]对象安排一次[build]。
  ///
  /// 如果你只是直接改变状态而不调用[setState]，框架可能不会安排[build]，这个子树的用户界
  /// 面可能不会被更新以反映新的状态。
  ///
  /// 一般来说，我们建议`setState`方法只用来包装对状态的实际改变，而不是任何可能与改变有关的
  /// 计算。例如，这里[build]函数使用的一个值被递增，然后变化被写入磁盘，但只有递增被包裹在`setState`中。
  ///
  /// ```dart
  /// Future<void> _incrementCounter() async {
  ///   setState(() {
  ///     _counter++;
  ///   });
  ///   Directory directory = await getApplicationDocumentsDirectory();
  ///   final String dirName = directory.path;
  ///   await File('$dir/counter.txt').writeAsString('$_counter');
  /// }
  /// ```
  /// 在框架调用[dispose]后在调用此方法是一个错误。你可以通过检查[mounted]属性是否为true来
  /// 确定调用此方法是否合法。
  ///
  @protected
  void setState(VoidCallback fn) {
    assert(fn != null);
    assert(() {
      if (_debugLifecycleState == _StateLifecycle.defunct) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() called after dispose(): $this'),
          ErrorDescription(
              'This error happens if you call setState() on a State object for a widget that '
              'no longer appears in the widget tree (e.g., whose parent widget no longer '
              'includes the widget in its build). This error can occur when code calls '
              'setState() from a timer or an animation callback.'),
          ErrorHint('The preferred solution is '
              'to cancel the timer or stop listening to the animation in the dispose() '
              'callback. Another solution is to check the "mounted" property of this '
              'object before calling setState() to ensure the object is still in the '
              'tree.'),
          ErrorHint(
              'This error might indicate a memory leak if setState() is being called '
              'because another object is retaining a reference to this State object '
              'after it has been removed from the tree. To avoid memory leaks, '
              'consider breaking the reference to this object during dispose().'),
        ]);
      }
      if (_debugLifecycleState == _StateLifecycle.created && !mounted) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() called in constructor: $this'),
          ErrorHint(
              'This happens when you call setState() on a State object for a widget that '
              "hasn't been inserted into the widget tree yet. It is not necessary to call "
              'setState() in the constructor, since the state is already assumed to be dirty '
              'when it is initially created.'),
        ]);
      }
      return true;
    }());
    final dynamic result = fn() as dynamic;
    assert(() {
      if (result is Future) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() callback argument returned a Future.'),
          ErrorDescription(
              'The setState() method on $this was called with a closure or method that '
              'returned a Future. Maybe it is marked as "async".'),
          ErrorHint(
              'Instead of performing asynchronous work inside a call to setState(), first '
              'execute the work (without updating the widget state), and then synchronously '
              'update the state inside a call to setState().'),
        ]);
      }
      // We ignore other types of return values so that you can do things like:
      //   setState(() => x = 3);
      return true;
    }());
    _element!.markNeedsBuild();
  }

  /// 当此对象从树中删除时被调用。
  ///
  /// 每当框架将这个[State]对象从树中移除时，都会调用这个方法。在某些情况下，框架会将[State]
  /// 对象重新插入到树的另一部分（例如，如果包含这个[State]对象的子树从树的一个位置嫁接到另一个位置）。
  /// 如果发生这种情况，框架将确保它调用[build]，以使[State]对象有机会适应它在树中的新位置。
  /// 如果框架真的重新插入这个子树，它将在子树被从树上移除的动画帧结束前完成。由于这个原因，
  /// [State]对象可以推迟释放大部分资源，直到框架调用它们的[dispose]方法。
  ///
  /// 子类应该覆盖这个方法，以清理这个对象和树中其他元素之间的任何链接（例如，如果你为一个祖
  /// 先提供了一个指向一个后代的[RenderObject]的指针）。
  ///
  /// 如果你覆盖了这一点，请确保在你的方法结束时调用super.deactivate（）。
  ///
  /// See also:
  /// * 在[deactivate]之后被调用后，如果该部件被永久地从树中移除会调用[dispose]。
  ///
  @protected
  @mustCallSuper
  void deactivate() {}

  /// 当此对象从树中永久移除时调用。
  ///
  /// 当这个[State]对象将不再build时，框架会调用这个方法。在框架调用[dispose]后，[State]
  /// 对象被认为是unmounted的，[mounted]属性为false。在这个时候调用[setState]是一个错误。
  /// 生命周期的这一阶段是终结的：没有办法重新安装一个已经被disposed的[State]对象。
  ///
  /// 子类应该覆盖这个方法来释放这个对象所保留的任何资源（例如，停止任何活动的动画）。
  ///
  /// 如果你覆盖了这一点，请确保以调用super.dispose()来结束你的方法。
  ///
  /// See also:
  ///
  ///  * [deactivate], which is called prior to [dispose].
  @protected
  @mustCallSuper
  void dispose() {
    assert(_debugLifecycleState == _StateLifecycle.ready);
    assert(() {
      _debugLifecycleState = _StateLifecycle.defunct;
      return true;
    }());
  }

  /// 描述了这个部件所代表的用户界面的部分。
  ///
  /// 该框架在许多不同的情况下调用这个方法。比如说：
  /// * 在调用[initState]之后
  /// * 在调用[didUpdateWidget]之后
  /// * 在收到对[setState]的调用后
  /// * 在这个[State]对象的依赖关系发生变化后（例如，之前的[build]所引用的[InheritedWidget]发生变化）
  /// * 在调用[deactivate]后，再将[State]对象重新插入树中的另一个位置
  ///
  /// 这个方法有可能在每一帧中被调用，除了建立一个小部件外，不应该有任别的作用。
  ///
  /// 框架用这个方法返回的部件替换这个部件下面的子树，要么更新现有的子树，要么删除子树并膨胀
  /// 一个新的子树，这取决于这个方法返回的部件是否可以更新现有子树的根，这一点通过调用[Widget.canUpdate]来确定。
  ///
  /// 通常情况下，实现会返回一个新创建的小组件，这些小组件的配置信息来自这个小组件的构造函数、
  /// 给定的[BuildContext]，以及这个[State]对象的内部状态。
  ///
  /// 给定的[BuildContext]包含了关于该部件在树中的位置的信息，在该位置该部件正在被构建。
  /// 例如，该上下文（context）提供了树中这个位置的继承部件的集合。[BuildContext]参数总是与
  /// 这个[State]对象的[context]属性相同，并且在这个对象的生命周期内保持相同。[BuildContext]
  /// 参数在这里是多余的，以便这个方法与[WidgetBuilder]的签名相匹配。
  ///
  ///
  /// ## 设计讨论
  ///
  /// ### 为什么[build]方法是在[State]上，而不是[StatefulWidget]?
  ///
  /// 将 "Widget build(BuildContext context) "方法放在[State]上，而不是将
  /// "Widget build(BuildContext context, State state) "方法放在[StatefulWidget]上，
  /// 会使开发者在子类化[StatefulWidget]时更有灵活性。
  ///
  /// 例如，[AnimatedWidget]是[StatefulWidget]的一个子类，它引入了一个抽象的
  /// `Widget build(BuildContext context)`方法供其子类实现。如果[StatefulWidget]
  /// 已经有一个接受[State]参数的[build]方法，[AnimatedWidget]将被迫向子类提供其[State]对象，
  /// 尽管其[State]对象是[AnimatedWidget]的内部实现细节。
  ///
  /// 在概念上，[StatelessWidget]也可以以类似的方式实现为[StatefulWidget]的子类。
  /// 如果[build]方法是在[StatefulWidget]而不是[State]上，那就不可能了。
  ///
  /// 将[build]函数放在[State]而不是[StatefulWidget]上，也有助于避免一类与闭包隐含捕获`this`有关的错误。
  /// 如果你在[build]函数中对[StatefulWidget]定义了一个闭包，这个闭包将隐含地捕获`this`，
  /// 也就是当前的 widget 实例，并将该实例的（不可变的）字段纳入作用域。
  ///
  /// ```dart
  /// class MyButton extends StatefulWidget {
  ///   ...
  ///   final Color color;
  ///
  ///   @override
  ///   Widget build(BuildContext context, MyButtonState state) {
  ///     ... () { print("color: $color"); } ...
  ///   }
  /// }
  /// ```
  ///
  /// 例如，假设父代建立`MyButton`时，`color`是蓝色的，打印函数中的`$color`指的是蓝色，如预期。
  /// 现在，假设父类重建的`MyButton'是绿色的。由第一次构建创建的闭包仍然隐含地指向原始的部件，
  /// 并且`$color`仍然打印为蓝色，即使该部件已经被更新为绿色。
  ///
  /// 与此相反，通过[build]函数对[State]对象的处理，在[build]过程中创建的闭包隐含地捕获了
  /// [State]实例而不是widget实例：
  ///
  /// ```dart
  /// class MyButtonState extends State<MyButton> {
  ///   ...
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     ... () { print("color: ${widget.color}"); } ...
  ///   }
  /// }
  /// ```
  ///
  /// 现在，当父代用绿色重建`MyButton'时，第一次构建所创建的闭包仍然指向[State]对象，该对
  /// 象在不同的重建中被保留，但框架已经更新了该[State]对象的[widget]属性以指向新的`MyButton'实例，
  /// 并且`${widget.color}`打印为绿色，正如预期。
  ///
  /// See also:
  ///
  ///  * [StatefulWidget], which contains the discussion on performance considerations.
  @protected
  Widget build(BuildContext context);

  /// 当此[State]对象的依赖关系发生变化时调用。
  ///
  /// 例如，如果之前对[build]的调用引用了一个后来发生变化的[InheritedWidget]，框架会调用这
  /// 个方法来通知这个对象的变化。
  ///
  /// 这个方法也会在[initState]之后立即被调用。从这个方法调用[BuildContext.dependOnInheritedWidgetOfExactType]是安全的
  ///
  ///
  /// 子类很少覆盖这个方法，因为框架总是在依赖关系改变后调用[build]。有些子类确实覆盖了这个方法，
  /// 因为当他们的依赖关系发生变化时，他们需要做一些昂贵的工作（例如，网络检索），而这些工作如
  /// 果在每次构建时都做的话，就太昂贵了。
  @protected
  @mustCallSuper
  void didChangeDependencies() {}

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    assert(() {
      properties.add(EnumProperty<_StateLifecycle>(
          'lifecycle state', _debugLifecycleState,
          defaultValue: _StateLifecycle.ready));
      return true;
    }());
    properties
        .add(ObjectFlagProperty<T>('_widget', _widget, ifNull: 'no widget'));
    properties.add(ObjectFlagProperty<StatefulElement>('_element', _element,
        ifNull: 'not mounted'));
  }
}
