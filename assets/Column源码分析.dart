///Columrn 继承自Flex
class Column extends Flex {

}

/// Flex继承自MultiChildRenderObjectWidget
/// 通过RenderFlex实现布局和渲染
class Flex extends MultiChildRenderObjectWidget {
  ...
  @override
  RenderFlex createRenderObject(BuildContext context) {
    return RenderFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}



/// 在一位数组中显示它的children
///
///
class RenderFlex extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlexParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData>,
        DebugOverflowIndicatorMixin {
  //...
  @override
  void performLayout() {
    //获取布局约束
    final BoxConstraints constraints = this.constraints;

    //计算出每个child的大小尺寸和总的占用尺寸
    final _LayoutSizes sizes = _computeSizes(
      layoutChild: ChildLayoutHelper.layoutChild,
      constraints: constraints,
    );

    final double allocatedSize = sizes.allocatedSize;
    double actualSize = sizes.mainSize;
    double crossSize = sizes.crossSize;
    double maxBaselineDistance = 0.0;

    //交叉轴baseline的对其方式
    if (crossAxisAlignment == CrossAxisAlignment.baseline) {
      RenderBox? child = firstChild;
      double maxSizeAboveBaseline = 0;
      double maxSizeBelowBaseline = 0;
      while (child != null) {
        final double? distance = child.getDistanceToBaseline(textBaseline!, onlyReal: true);
        if (distance != null) {
          maxBaselineDistance = math.max(maxBaselineDistance, distance);
          maxSizeAboveBaseline = math.max(
            distance,
            maxSizeAboveBaseline,
          );
          maxSizeBelowBaseline = math.max(
            child.size.height - distance,
            maxSizeBelowBaseline,
          );
          crossSize = math.max(maxSizeAboveBaseline + maxSizeBelowBaseline, crossSize);
        }
        final FlexParentData childParentData = child.parentData! as FlexParentData;
        child = childParentData.nextSibling;
      }
    }

    // 沿着主轴排列item

    //这里主要是获取合规的布局约束，即不超过约束的尺寸
    switch (_direction) {
      case Axis.horizontal:
        size = constraints.constrain(Size(actualSize, crossSize));
        actualSize = size.width;
        crossSize = size.height;
        break;
      case Axis.vertical:
        size = constraints.constrain(Size(crossSize, actualSize));
        actualSize = size.height;
        crossSize = size.width;
        break;
    }

    //主轴方向尺寸 - 申请的尺寸
    final double actualSizeDelta = actualSize - allocatedSize;
    //判断溢出尺寸
    _overflow = math.max(0.0, -actualSizeDelta);
    //剩余的空间（也就是未分配的空间）
    final double remainingSpace = math.max(0.0, actualSizeDelta);
    //头item距离parent顶部的距离
    late final double leadingSpace;
    //两个item的间距
    late final double betweenSpace;

    // flipMainAxis用来决定是从左到右/从上到下（false），还是从右到左/从下到上（true）进行布局。
    // 如果只有一个child，且相关方向为空，那么_startIsTopLeft将返回null，在这种情况下，我们决定不翻转，但这并没有任何可检测的效果。
    final bool flipMainAxis = !(_startIsTopLeft(direction, textDirection, verticalDirection) ?? true);
    switch (_mainAxisAlignment) {
      case MainAxisAlignment.start:
        leadingSpace = 0.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.end:
        leadingSpace = remainingSpace;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.center:
        leadingSpace = remainingSpace / 2.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.spaceBetween:
        leadingSpace = 0.0;
        betweenSpace = childCount > 1 ? remainingSpace / (childCount - 1) : 0.0;
        break;
      case MainAxisAlignment.spaceAround:
        betweenSpace = childCount > 0 ? remainingSpace / childCount : 0.0;
        leadingSpace = betweenSpace / 2.0;
        break;
      case MainAxisAlignment.spaceEvenly:
        betweenSpace = childCount > 0 ? remainingSpace / (childCount + 1) : 0.0;
        leadingSpace = betweenSpace;
        break;
    }

    // 定位
    double childMainPosition = flipMainAxis ? actualSize - leadingSpace : leadingSpace;
    //下面开始遍历单链表，并定位child
    RenderBox? child = firstChild;
    while (child != null) {
      //获取child存储的parentData
      final FlexParentData childParentData = child.parentData! as FlexParentData;
      final double childCrossPosition;
      //据交叉轴的不同对其模式，计算在交叉轴的位置
      switch (_crossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition = _startIsTopLeft(flipAxis(direction), textDirection, verticalDirection)
              == (_crossAxisAlignment == CrossAxisAlignment.start)
              ? 0.0
              : crossSize - _getCrossSize(child.size);
          break;
        case CrossAxisAlignment.center:
          childCrossPosition = crossSize / 2.0 - _getCrossSize(child.size) / 2.0;
          break;
        case CrossAxisAlignment.stretch:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.baseline:
          if (_direction == Axis.horizontal) {
            assert(textBaseline != null);
            final double? distance = child.getDistanceToBaseline(textBaseline!, onlyReal: true);
            if (distance != null)
              childCrossPosition = maxBaselineDistance - distance;
            else
              childCrossPosition = 0.0;
          } else {
            childCrossPosition = 0.0;
          }
          break;
      }
      //判断主轴方向的布局是否反转
      if (flipMainAxis)
        childMainPosition -= _getMainSize(child.size);
      //对垂直布局和水平布局，分别设置对应的parentData的offset，也就是设置child的位置
      switch (_direction) {
        case Axis.horizontal:
          childParentData.offset = Offset(childMainPosition, childCrossPosition);
          break;
        case Axis.vertical:
          childParentData.offset = Offset(childCrossPosition, childMainPosition);
          break;
      }
      if (flipMainAxis) {
        //需要反转
        childMainPosition -= betweenSpace;
      } else {
        //不需要反转
        //下一个item的主轴方向的位置 = 当前item主轴方向的位置 + 当前item的尺寸 + item间距
        childMainPosition += _getMainSize(child.size) + betweenSpace;
      }
      //下一个child
      child = childParentData.nextSibling;
    }
  }

  _LayoutSizes _computeSizes({required BoxConstraints constraints, required ChildLayouter layoutChild}) {

    //确定使用过的弹性系数，size不灵活的项目，计算free空间

    int totalFlex = 0;//总的flex
    //主轴最大的尺寸，这里直接获取约束里面对应方向的最大值
    final double maxMainSize = _direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
    //判断主轴方向的尺寸是否是无限的
    final bool canFlex = maxMainSize < double.infinity;

    double crossSize = 0.0;
    double allocatedSize = 0.0; // 非flexible children的尺寸之和
    RenderBox? child = firstChild;
    RenderBox? lastFlexChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData! as FlexParentData;
      //获取child对应的flex值，非flexible child返回的值为0
      final int flex = _getFlex(child);
      if (flex > 0) {//flexible child
        totalFlex += flex;
        lastFlexChild = child;
      } else {//非flexible child（比如写死size的child）
        final BoxConstraints innerConstraints;
        if (crossAxisAlignment == CrossAxisAlignment.stretch) {
          switch (_direction) {
            case Axis.horizontal:
              innerConstraints = BoxConstraints.tightFor(height: constraints.maxHeight);
              break;
            case Axis.vertical:
              innerConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
              break;
          }
        } else {
          switch (_direction) {
            case Axis.horizontal:
              innerConstraints = BoxConstraints(maxHeight: constraints.maxHeight);
              break;
            case Axis.vertical:
              innerConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
              break;
          }
        }
        //调用layoutChild方法，据约束布局child
        final Size childSize = layoutChild(child, innerConstraints);
        //记录主轴已申请的尺寸
        allocatedSize += _getMainSize(childSize);
        //计算交叉轴方向最大的size
        crossSize = math.max(crossSize, _getCrossSize(childSize));
      }
      //下一个child
      child = childParentData.nextSibling;
    }
    //经过上面的一轮循环，可以计算出flexible children总的所具有的flex
    //还可以计算出非flexible children在主轴方向所占用的总的空间，和交叉轴方向找到最大的尺寸。

    // 下面把可用的空间分配给 flexible children

    //计算可用的空间，
    // 如果有flexible children，那么剩余的空间就是约束传入的对应主轴上的最大尺寸 - 非flexible children已占用的空间
    // 如果没有flexible children，那么可用空间就为0。
    final double freeSpace = math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
    double allocatedFlexSpace = 0.0;
    if (totalFlex > 0) {//有flexible child，且flex大于0
      //一份flex所能占有的空间
      final double spacePerFlex = canFlex ? (freeSpace / totalFlex) : double.nan;
      //下面又要开始遍历了
      child = firstChild;
      while (child != null) {
        //获取child的flex
        final int flex = _getFlex(child);
        //对具有flex的child进行操作，没有flex的child直接跳过
        if (flex > 0) {
          //据flex计算child可具有的最大尺寸
          final double maxChildExtent = canFlex ? (child == lastFlexChild ? (freeSpace - allocatedFlexSpace) : spacePerFlex * flex) : double.infinity;

          //据fit计算child能具有的最小尺寸
          late final double minChildExtent;
          switch (_getFit(child)) {
            case FlexFit.tight://tight模式下，最小值等于最大值
              minChildExtent = maxChildExtent;
              break;
            case FlexFit.loose://loose模式下，最小值为0
              minChildExtent = 0.0;
              break;
          }

          //据不同的对其方式和方向，构造对应的布局约束BoxConstraints
          final BoxConstraints innerConstraints;
          if (crossAxisAlignment == CrossAxisAlignment.stretch) {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = BoxConstraints(
                  minWidth: minChildExtent,
                  maxWidth: maxChildExtent,
                  minHeight: constraints.maxHeight,
                  maxHeight: constraints.maxHeight,
                );
                break;
              case Axis.vertical:
                innerConstraints = BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  minHeight: minChildExtent,
                  maxHeight: maxChildExtent,
                );
                break;
            }
          } else {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = BoxConstraints(
                  minWidth: minChildExtent,
                  maxWidth: maxChildExtent,
                  maxHeight: constraints.maxHeight,
                );
                break;
              case Axis.vertical:
                innerConstraints = BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  minHeight: minChildExtent,
                  maxHeight: maxChildExtent,
                );
                break;
            }
          }
          //据布局约束布局child（也就是计算child的尺寸）
          //其实就是调用child对应的layout方法：child.layout(constraints, parentUsesSize: true);
          final Size childSize = layoutChild(child, innerConstraints);

          final double childMainSize = _getMainSize(childSize);
          //记录已使用的空间尺寸，这里是据child实际大小计算出来的
          allocatedSize += childMainSize;
          //记录flexible children占用的空间尺寸
          allocatedFlexSpace += maxChildExtent;
          //继续获取交叉轴的最大尺寸
          crossSize = math.max(crossSize, _getCrossSize(childSize));
        }

        //下一个child
        final FlexParentData childParentData = child.parentData! as FlexParentData;
        child = childParentData.nextSibling;
      }
    }

    //计算主轴的尺寸
    final double idealSize = canFlex && mainAxisSize == MainAxisSize.max ? maxMainSize : allocatedSize;
    return _LayoutSizes(
      mainSize: idealSize,//主轴的尺寸
      crossSize: crossSize,//交叉轴的尺寸
      allocatedSize: allocatedSize,//实际占用的尺寸
    );
  }


  /// 绘制
  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      //没有溢出，则直接使用RenderBoxContainerDefaultsMixin提供的默认的绘制
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty)
      return;

    if (clipBehavior == Clip.none) {
      _clipRectLayer = null;
      defaultPaint(context, offset);
    } else {
      // We have overflow and the clipBehavior isn't none. Clip it.
      _clipRectLayer = context.pushClipRect(needsCompositing, offset, Offset.zero & size, defaultPaint,
          clipBehavior: clipBehavior, oldLayer: _clipRectLayer);
    }

  }


  ///命中测试
  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    //使用RenderBoxContainerDefaultsMixin提供的默认的命中测试
    return defaultHitTestChildren(result, position: position);
  }

}

///存储布局得到的尺寸
class _LayoutSizes {
  const _LayoutSizes({
    required this.mainSize,
    required this.crossSize,
    required this.allocatedSize,
  });

  final double mainSize;
  final double crossSize;
  final double allocatedSize;
}


///一个 对具有child列表的render object比较通用的mixin
///
/// 为一个render object的子类提供了child模型，该子类用双向链表组织children。
///
///[ChildType]指定了child的类型(必须是继承自RenderObject的)，比如类型可以是[RenderBox];
///[ParentDataType] 将父容器的数据存储在其子render objects上。ParentDataType必须是继承自[ContainerParentDataMixin]的，[ContainerParentDataMixin]提供了访问child的接口。
///该数据由使用该mixin的类，使用[RenderObject.setupParentData]方法填充。
///
///当使用[RenderBox]作为子类型时，您通常会希望使用[RenderBoxContainerDefaultsMixin]并扩展[ContainerBoxParentData]作为父数据。
mixin ContainerRenderObjectMixin<ChildType extends RenderObject, ParentDataType extends ContainerParentDataMixin<ChildType>> on RenderObject {

}

///对ContainerRenderObjectMixin管理children，提供了有用的默认的行为。
///该class不override任何父类的成员，相反，会提供一些有用的子类能调用的方法。
mixin RenderBoxContainerDefaultsMixin<ChildType extends RenderBox, ParentDataType extends ContainerBoxParentData<ChildType>> implements ContainerRenderObjectMixin<ChildType, ParentDataType> {

  ///向前遍历，绘制每一个child
  ///
  void defaultPaint(PaintingContext context, Offset offset) {
    //开始遍历child
    ChildType? child = firstChild;
    while (child != null) {
      //获取child存储的parentData
      final ParentDataType childParentData = child.parentData! as ParentDataType;
      //调用PaintingContext的paintChild绘制child
      context.paintChild(child, childParentData.offset + offset);
      //下一个child
      child = childParentData.nextSibling;
    }
  }

  ///反向遍历child，对每个child进行命中测试
  ///
  bool defaultHitTestChildren(BoxHitTestResult result, { required Offset position }) {
    // x、y参数以节点box的左上方为原点
    //反向遍历child
    ChildType? child = lastChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData! as ParentDataType;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformed) {
          //调用child的hitTest
          return child!.hitTest(result, position: transformed!);
        },
      );
      //如果命中，则直接停止
      if (isHit)
        return true;
      //前一个child
      child = childParentData.previousSibling;
    }
    return false;
  }



}

class BoxParentData extends ParentData {
  /// child在parent坐标系中绘制的位置
  Offset offset = Offset.zero;

}