/// [StatefulWidget]控件的逻辑和内部状态
///
/// State是(1)可在小组件构建时同步读取的信息，(2)可能在小组件的生命周期内发生变化。小组件实
/// 现者有责任使用[State.setState]确保在状态发生变化时及时通知[State]。
///
/// [State]对象由框架在将[StatefulWidget]膨胀以将其插入树中时调用[StatefulWidget.createState]
/// 方法创建。由于给定的 [StatefulWidget] 实例可以多次膨胀（例如，小组件同时被纳入树的多
/// 个位置），因此，给定的 [StatefulWidget] 实例可能有多个 [State] 对象。同样，如果一
/// 个[StatefulWidget]从树中移除，随后又被插入到树中，框架将再次调用[StatefulWidget.createState]
/// 来创建一个新的[State]对象，从而简化了[State]对象的生命周期。
///
/// [State]对象有如下的生命周期：
/// * 框架通过调用[StatefulWidget.createState]创建一个[State]对象。
/// * 新创建的 [State] 对象与 [BuildContext] 相关联。这种关联是永久性的：[State]对象永
///   远不会改变它的[BuildContext]。但是，[BuildContext]本身可以和它的子树一起在树上移动。
///   此时，[State]对象被视为[mounted]。
/// * 框架调用[initState]。[State]的子类应该重写[initState]来执行一次性初始化，这取依赖
///   于[BuildContext]或widget，当调用[initState]方法时，它们分别作为[context]
///   和[widget]属性可用。
/// * 框架调用[didChangeDependencies]方法。[State]的子类应该覆盖[didChangeDependencies]
///   来执行涉及[InheritedWidget]的初始化。如果调用了[BuildContext.dependOnheritedWidgetOfExactType]，
///   如果继承的widget随后发生变化或者widget在树中移动，[didChangeDependencies]方法将被再次调用。
/// * 此时，[State]对象已经完全初始化了，框架可以任意多次调用它的[build]方法来获取这个子树
///   的用户界面的描述。[State]对象可以通过调用其[setState]方法自发地请求重建其子树，这表明
///   其内部的一些状态发生了变化，可能会影响到这个子树的用户界面。
/// * 在此期间，父 widget 可能会重建并请求更新树中的此位置，以显示具有相同 [runtimeType]
///   和 [Widget.key] 的新 widget。当这种情况发生时，框架将更新[widget]属性以引用新的
///   widget，然后以之前的widget作为参数调用[didUpdateWidget]方法。[State]对象应该覆
///   盖[didUpdateWidget]，以响应其关联widget的变化（例如，启动隐式动画）。框架总是在
///   调用[didUpdateWidget]之后调用[build]，这意味着在[didUpdateWidget]中对[setState]的任何调用都是多余的。
/// * 在开发过程中，如果发生热重装（无论是通过按`r`从命令行`flutter`工具启动，还是从IDE启动），
///   [reassemble]方法会被调用。这为[initState]方法中准备的任何数据提供了重新初始化的机会。
/// * 如果包含 [State] 对象的子树被从树中删除（例如，因为父类用不同的 [runtimeType]
///   或 [Widget.key] 构建了一个 widget），框架会调用 [deactivate] 方法。子类应该重写这
///   个方法来清理这个对象和树中其他元素之间的任何连接（例如，如果你为祖先提供了指向子孙[RenderObject]的指针）。
/// * 此时，框架可能会将这个子树重新插入到树的另一部分。如果发生这种情况，框架会确保调用[build]，
///   让[State]对象有机会适应它在树中的新位置。如果框架确实重新插入这个子树，它将在子树被从
///   树中移除的动画帧结束之前进行。出于这个原因，[State]对象可以推迟释放大部分资源，直到框
///   架调用其[dispose]方法。
/// * 如果框架在当前动画帧结束前没有重新插入这个子树，框架将调用[dispose]，这表明这个[State]
///   对象将永远不会再构建（build）。子类应该重写这个方法来释放这个对象保留的任何资源（例如，
///   停止任何活动的动画）。
/// * 框架调用[dispose]后，[State]对象被认为是未挂载的，[mounted]属性为false。
///   此时调用[setState]是一个错误。生命周期的这个阶段是终结性的：没有办法重新挂载一个已经
///   被disposed的[State]对象。
///
///
@optionalTypeArgs
abstract class State<T extends StatefulWidget> with Diagnosticable {
  /// State当前的配置
  ///
  ///一个[State]对象的配置就是对应的[StatefulWidget]实例。
  ///此属性在调用[initState]之前由框架初始化。如果父对象将树中的此位置更新为与当前配置具有相同 [runtimeType] 和 [Widget.key]
  /// 的新的小组件，框架将更新此属性以引用新小组件，然后调用 [didUpdateWidget]，将旧配置作
  /// 为参数传递进去。
  T get widget => _widget!;
  T? _widget;

  /// The current stage in the lifecycle for this state object.
  ///
  /// This field is used by the framework when asserts are enabled to verify
  /// that [State] objects move through their lifecycle in an orderly fashion.
  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  /// 当前widget在树上构建(build)时的位置
  ///
  /// 在使用 [StatefulWidget.createState] 创建 [State] 对象后，框架会在调用 [initState]
  /// 之前将其与 [BuildContext] 关联。这种关联是永久性的：[State]对象永远不会改变它的
  /// [BuildContext]。但是，[BuildContext]本身可以在树上移动。
  ///
  /// 调用[dispose]后，框架会切断[State]对象与[BuildContext]的连接。
  BuildContext get context {
    //返回element对象
    return _element!;
  }
  StatefulElement? _element;

  /// 该属性表示这个[State]对象当前是否在树中。
  ///
  /// 在创建[State]对象后，调用[initState]之前，框架通过将[State]对象与[BuildContext]关
  /// 联来 "mounts "该对象。在框架调用[dispose]之前，[State]对象一直保持挂载状态，调用[dispose]之后，
  /// 框架将不再使用[State]对象[build]。
  ///
  /// 只有[mounted]为true的时候，才能调用[setState]，否则是错误的行为。
  bool get mounted => _element != null;

  /// 当该对象被插入到树中后，这个方法会被调用。
  ///
  /// 框架对于每一个[State]对象，只会调用一次这个方法。
  ///
  /// 重写该方法执行依赖于[context]和[widget]的初始化。
  ///
  /// 如果一个[State]的[build]方法依赖于一个本身可以改变状态的对象，例如一个[ChangeNotifier]或[Stream]，
  /// 或者其他一些可以订阅接收通知的对象，那么一定要在[initState]、[didUpdateWidget]和[dispose]
  /// 中正确地订阅和退订：
  ///  * 在[initState]方法中，开始订阅
  ///  * 在[didUpdateWidget]中，如果更新后的widget配置会替换你在[initState]中订阅的对象，
  ///    则在该方法从旧对象退订并订阅新对象。
  ///  * 在[dispose]方法中，退订
  ///
  /// 不能在这个方法中调用 [BuildContext.dependOnInheritedWidgetOfExactType] 。但是，
  /// [didChangeDependencies]将在本方法之后立即被调用，所以[BuildContext.dependOnInheritedWidgetOfExactType]
  /// 可以在那里调用。
  ///
  /// 如果重写了这个方法，请确保你的方法以调用super.initState()开始的。
  @protected
  @mustCallSuper
  void initState() {
    assert(_debugLifecycleState == _StateLifecycle.created);
  }

  /// Called whenever the widget configuration changes.
  ///
  /// If the parent widget rebuilds and request that this location in the tree
  /// update to display a new widget with the same [runtimeType] and
  /// [Widget.key], the framework will update the [widget] property of this
  /// [State] object to refer to the new widget and then call this method
  /// with the previous widget as an argument.
  ///
  /// Override this method to respond when the [widget] changes (e.g., to start
  /// implicit animations).
  ///
  /// The framework always calls [build] after calling [didUpdateWidget], which
  /// means any calls to [setState] in [didUpdateWidget] are redundant.
  ///
  /// {@macro flutter.widgets.State.initState}
  ///
  /// If you override this, make sure your method starts with a call to
  /// super.didUpdateWidget(oldWidget).
  @mustCallSuper
  @protected
  void didUpdateWidget(covariant T oldWidget) { }

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
  void reassemble() { }

  /// Notify the framework that the internal state of this object has changed.
  ///
  /// Whenever you change the internal state of a [State] object, make the
  /// change in a function that you pass to [setState]:
  ///
  /// ```dart
  /// setState(() { _myState = newValue; });
  /// ```
  ///
  /// The provided callback is immediately called synchronously. It must not
  /// return a future (the callback cannot be `async`), since then it would be
  /// unclear when the state was actually being set.
  ///
  /// Calling [setState] notifies the framework that the internal state of this
  /// object has changed in a way that might impact the user interface in this
  /// subtree, which causes the framework to schedule a [build] for this [State]
  /// object.
  ///
  /// If you just change the state directly without calling [setState], the
  /// framework might not schedule a [build] and the user interface for this
  /// subtree might not be updated to reflect the new state.
  ///
  /// Generally it is recommended that the `setState` method only be used to
  /// wrap the actual changes to the state, not any computation that might be
  /// associated with the change. For example, here a value used by the [build]
  /// function is incremented, and then the change is written to disk, but only
  /// the increment is wrapped in the `setState`:
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
  ///
  /// It is an error to call this method after the framework calls [dispose].
  /// You can determine whether it is legal to call this method by checking
  /// whether the [mounted] property is true.
  @protected
  void setState(VoidCallback fn) {
    final dynamic result = fn() as dynamic;
    _element!.markNeedsBuild();
  }

  /// 当此对象从树上移除时调用。
  ///
  /// The framework calls this method whenever it removes this [State] object
  /// from the tree. In some cases, the framework will reinsert the [State]
  /// object into another part of the tree (e.g., if the subtree containing this
  /// [State] object is grafted from one location in the tree to another). If
  /// that happens, the framework will ensure that it calls [build] to give the
  /// [State] object a chance to adapt to its new location in the tree. If
  /// the framework does reinsert this subtree, it will do so before the end of
  /// the animation frame in which the subtree was removed from the tree. For
  /// this reason, [State] objects can defer releasing most resources until the
  /// framework calls their [dispose] method.
  ///
  /// Subclasses should override this method to clean up any links between
  /// this object and other elements in the tree (e.g. if you have provided an
  /// ancestor with a pointer to a descendant's [RenderObject]).
  ///
  /// If you override this, make sure to end your method with a call to
  /// super.deactivate().
  ///
  /// See also:
  ///
  ///  * [dispose], which is called after [deactivate] if the widget is removed
  ///    from the tree permanently.
  @protected
  @mustCallSuper
  void deactivate() { }

  /// 当此对象从树上永久移除时调用。
  ///
  /// The framework calls this method when this [State] object will never
  /// build again. After the framework calls [dispose], the [State] object is
  /// considered unmounted and the [mounted] property is false. It is an error
  /// to call [setState] at this point. This stage of the lifecycle is terminal:
  /// there is no way to remount a [State] object that has been disposed.
  ///
  /// Subclasses should override this method to release any resources retained
  /// by this object (e.g., stop any active animations).
  ///
  /// {@macro flutter.widgets.State.initState}
  ///
  /// If you override this, make sure to end your method with a call to
  /// super.dispose().
  ///
  /// See also:
  ///
  ///  * [deactivate], which is called prior to [dispose].
  @protected
  @mustCallSuper
  void dispose() {
  }

  /// 描述此widget所代表的用户界面
  ///
  /// 框架在许多不同的情况下都会调用这个方法。例如：
  /// * 调用[initState]方法之后会被调用
  /// * 调用[didUpdateWidget]方法之后会被调用
  /// * 收到一个[setState]调用之后
  /// * 在这个[State]对象的依赖发生变化后（例如，之前[build]里面引用的[InheritedWidget]
  ///   发生了变化）。
  /// * 在调用[deactivate]后，再将[State] 对象重新插入到树的另一个位置，也会被调用
  ///
  /// 这个方法有可能在每帧中被调用，除了构建一个widget之外，不应该有任何其他作用。
  ///
  /// 框架用本方法返回的widget替换该widget下面的子树，具体替换方法是更新现有的子树，或者是删除子树
  /// 并填充一个新的子树，这取决于本方法返回的widget是否能更新现有子树的根节点，
  /// 这由[Widget.canUpdate]方法确定。
  ///
  /// 通常情况下，实现方法会返回一个新创建的一系列widget，这些widget会使用widget构造方法、
  /// 传递进来的[BuildContext]和该[State] 对象这些提供的信息来配置自己。
  ///
  /// 给定的 [BuildContext] 包含正在构建的widget在树中的位置相关的信息。例如，context提
  /// 供了树中此位置inherited小组件的集合。[BuildContext] 参数始终与此 [State] 对象的
  /// [context] 属性相同，并将在此对象的生命周期内保持相同。[BuildContext]参数在这里是多
  /// 余提供的，因此该方法与[WidgetBuilder]的签名一致。
  ///
  /// ## 设计相关的讨论
  ///
  /// ### 为什么把[build]方法放在[State]，而不是[StatefulWidget]？
  ///
  /// 将 "Widget build(BuildContext context) "方法放在[State]上，而不是将
  /// "Widget build(BuildContext context，State state) "方法放在[StatefulWidget]上，
  /// 让开发者在写[StatefulWidget]子类时更加灵活。
  ///
  /// 例如，[AnimatedWidget]是[StatefulWidget]的一个子类，它引入了一个抽象的
  /// "Widget build(BuildContext context) "方法供它的子类实现。如果[StatefulWidget]
  /// 已经有一个[build]方法接受了一个[State]参数，[AnimatedWidget]将被迫向子类提供它的
  /// [State]对象，尽管它的[State]对象是[AnimatedWidget]的内部实现细节。
  ///
  /// 概念上，[StatelessWidget]也可以用类似的方式实现为[StatefulWidget]的一个子类。
  /// 如果[build]方法是在[StatefulWidget]上而不是在[State]上，那就不可能了。
  ///
  /// 将 [build] 函数放在 [State] 而不是 [StatefulWidget] 上还有助于避免一类与闭包隐式
  /// 捕获`this`有关的错误。如果您在[StatefulWidget]上的[build]函数中定义了一个闭包，该
  /// 闭包将隐式捕获`this`，即当前小组件实例，并将该实例的（不可变）字段置于作用域中:
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
  /// 例如，假设父代在构建`MyButton`时，`color`是蓝色的，那么打印函数中的`$color`是指蓝
  /// 色的，正如预期的那样。现在，假设父代用绿色重新构建`MyButton`。第一次创建的闭包仍然隐
  /// 式地指向原始widget，即使widget已经更新为绿色，`$color`仍然打印蓝色。
  ///
  /// 相反，在[State]对象上使用[build]函数，在[build]期间创建的闭包会隐式地捕获[State]
  /// 实例，而不是widget实例。:
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
  /// 现在，当父体用绿色重构`MyButton`时，第一次重构创建的闭包仍然引用了[State]对象，该对
  /// 象在不同的重构中被保留，但框架已经更新了该[State]对象的[widget]属性，引用了新
  /// 的`MyButton`实例，`${widget.color}`按预期打印出绿色。
  ///
  /// See also:
  ///
  ///  * [StatefulWidget], which contains the discussion on performance considerations.
  @protected
  Widget build(BuildContext context);

  /// Called when a dependency of this [State] object changes.
  ///
  /// For example, if the previous call to [build] referenced an
  /// [InheritedWidget] that later changed, the framework would call this
  /// method to notify this object about the change.
  ///
  /// This method is also called immediately after [initState]. It is safe to
  /// call [BuildContext.dependOnInheritedWidgetOfExactType] from this method.
  ///
  /// Subclasses rarely override this method because the framework always
  /// calls [build] after a dependency changes. Some subclasses do override
  /// this method because they need to do some expensive work (e.g., network
  /// fetches) when their dependencies change, and that work would be too
  /// expensive to do for every build.
  @protected
  @mustCallSuper
  void didChangeDependencies() { }

}
