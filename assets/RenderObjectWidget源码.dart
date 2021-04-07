///
/// [RenderObjectElement]的配置，并提供具有渲染能力的[RenderObject]。
///
/// 提供了[RenderObject]的创建、更新和卸载操作
///
abstract class RenderObjectWidget extends Widget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RenderObjectWidget({ Key? key }) : super(key: key);

  /// RenderObjectWidgets always inflate to a [RenderObjectElement] subclass.
  @override
  @factory
  RenderObjectElement createElement();

  /// Creates an instance of the [RenderObject] class that this
  /// [RenderObjectWidget] represents, using the configuration described by this
  /// [RenderObjectWidget].
  ///
  /// This method should not do anything with the children of the render object.
  /// That should instead be handled by the method that overrides
  /// [RenderObjectElement.mount] in the object rendered by this object's
  /// [createElement] method. See, for example,
  /// [SingleChildRenderObjectElement.mount].
  @protected
  @factory
  RenderObject createRenderObject(BuildContext context);

  /// Copies the configuration described by this [RenderObjectWidget] to the
  /// given [RenderObject], which will be of the same type as returned by this
  /// object's [createRenderObject].
  ///
  /// This method should not do anything to update the children of the render
  /// object. That should instead be handled by the method that overrides
  /// [RenderObjectElement.update] in the object rendered by this object's
  /// [createElement] method. See, for example,
  /// [SingleChildRenderObjectElement.update].
  @protected
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) { }

  /// A render object previously associated with this widget has been removed
  /// from the tree. The given [RenderObject] will be of the same type as
  /// returned by this object's [createRenderObject].
  @protected
  void didUnmountRenderObject(covariant RenderObject renderObject) { }
}
