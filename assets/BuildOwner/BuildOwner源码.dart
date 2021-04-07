class BuildOwner {
  /// Creates an object that manages widgets.
  BuildOwner({ this.onBuildScheduled, FocusManager? focusManager }) :
        focusManager = focusManager ?? FocusManager();

  /// Called on each build pass when the first buildable element is marked
  /// dirty.
  VoidCallback? onBuildScheduled;

  final _InactiveElements _inactiveElements = _InactiveElements();

  final List<Element> _dirtyElements = <Element>[];
  bool _scheduledFlushDirtyElements = false;

  /// Whether [_dirtyElements] need to be sorted again as a result of more
  /// elements becoming dirty during the build.
  ///
  /// This is necessary to preserve the sort order defined by [Element._sort].
  ///
  /// This field is set to null when [buildScope] is not actively rebuilding
  /// the widget tree.
  bool? _dirtyElementsNeedsResorting;

  /// Whether [buildScope] is actively rebuilding the widget tree.
  ///
  /// [scheduleBuildFor] should only be called when this value is true.
  bool get _debugIsInBuildScope => _dirtyElementsNeedsResorting != null;

  /// The object in charge of the focus tree.
  ///
  /// Rarely used directly. Instead, consider using [FocusScope.of] to obtain
  /// the [FocusScopeNode] for a given [BuildContext].
  ///
  /// See [FocusManager] for more details.
  FocusManager focusManager;

  /// Adds an element to the dirty elements list so that it will be rebuilt
  /// when [WidgetsBinding.drawFrame] calls [buildScope].
  void scheduleBuildFor(Element element) {
    assert(element != null);
    assert(element.owner == this);
    assert(() {
      if (debugPrintScheduleBuildForStacks)
        debugPrintStack(label: 'scheduleBuildFor() called for $element${_dirtyElements.contains(element) ? " (ALREADY IN LIST)" : ""}');
      if (!element.dirty) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('scheduleBuildFor() called for a widget that is not marked as dirty.'),
          element.describeElement('The method was called for the following element'),
          ErrorDescription(
              'This element is not current marked as dirty. Make sure to set the dirty flag before '
                  'calling scheduleBuildFor().'),
          ErrorHint(
              'If you did not attempt to call scheduleBuildFor() yourself, then this probably '
                  'indicates a bug in the widgets framework. Please report it:\n'
                  '  https://github.com/flutter/flutter/issues/new?template=2_bug.md'
          ),
        ]);
      }
      return true;
    }());
    if (element._inDirtyList) {
      assert(() {
        if (debugPrintScheduleBuildForStacks)
          debugPrintStack(label: 'BuildOwner.scheduleBuildFor() called; _dirtyElementsNeedsResorting was $_dirtyElementsNeedsResorting (now true); dirty list is: $_dirtyElements');
        if (!_debugIsInBuildScope) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('BuildOwner.scheduleBuildFor() called inappropriately.'),
            ErrorHint(
                'The BuildOwner.scheduleBuildFor() method should only be called while the '
                    'buildScope() method is actively rebuilding the widget tree.'
            ),
          ]);
        }
        return true;
      }());
      _dirtyElementsNeedsResorting = true;
      return;
    }
    if (!_scheduledFlushDirtyElements && onBuildScheduled != null) {
      _scheduledFlushDirtyElements = true;
      onBuildScheduled!();
    }
    _dirtyElements.add(element);
    element._inDirtyList = true;
    assert(() {
      if (debugPrintScheduleBuildForStacks)
        debugPrint('...dirty list is now: $_dirtyElements');
      return true;
    }());
  }

  int _debugStateLockLevel = 0;
  bool get _debugStateLocked => _debugStateLockLevel > 0;

  /// Whether this widget tree is in the build phase.
  ///
  /// Only valid when asserts are enabled.
  bool get debugBuilding => _debugBuilding;
  bool _debugBuilding = false;
  Element? _debugCurrentBuildTarget;

  /// Establishes a scope in which calls to [State.setState] are forbidden, and
  /// calls the given `callback`.
  ///
  /// This mechanism is used to ensure that, for instance, [State.dispose] does
  /// not call [State.setState].
  void lockState(void callback()) {
    assert(callback != null);
    assert(_debugStateLockLevel >= 0);
    assert(() {
      _debugStateLockLevel += 1;
      return true;
    }());
    try {
      callback();
    } finally {
      assert(() {
        _debugStateLockLevel -= 1;
        return true;
      }());
    }
    assert(_debugStateLockLevel >= 0);
  }

  ///
  /// 建立更新widget树的作用域，并调用给定的 "回调"（如果有）。然后，按照深度顺序，使用
  /// [scheduleBuildFor]构建所有被标记为dirty的元素。
  ///
  /// 这种机制可以防止构建方法中要求其他构建方法运行，从而可能造成无限循环。
  ///
  /// dirty列表在`callback`返回后进行处理，按照深度顺序使用[scheduleBuildFor]构建所有被
  /// 标记为dirty的元素。如果元素在本方法运行时被标记为dirty，它们必须比`context`节点更深，
  /// 并且比本通道中任何先前构建的节点更深。
  ///
  /// 为了在不执行任何其他工作的情况下刷新当前的脏列表，可以调用这个函数而不进行回调。这就是
  /// 框架在[WidgetsBinding.drawFrame]中，每一帧所做的工作。
  ///
  /// 一次只能激活一个[buildScope]。
  ///
  /// 一个[buildScope]也意味着一个[lockState]作用域。
  ///
  /// 要在每次调用该方法时打印一条控制台消息，请将 [debugPrintBuildScope] 设置为 true。
  /// 这在调试涉及小组件未被标记为脏或标记为脏的频率过高的问题时很有用。
  ///
  void buildScope(Element context, [ VoidCallback? callback ]) {
    if (callback == null && _dirtyElements.isEmpty)
      return;
    Timeline.startSync('Build', arguments: timelineArgumentsIndicatingLandmarkEvent);
    try {
      _scheduledFlushDirtyElements = true;
      if (callback != null) {
        Element? debugPreviousBuildTarget;
        _dirtyElementsNeedsResorting = false;
        try {
          callback();
        } finally {
        }
      }
      _dirtyElements.sort(Element._sort);
      _dirtyElementsNeedsResorting = false;
      int dirtyCount = _dirtyElements.length;
      int index = 0;
      while (index < dirtyCount) {
        try {
          //重新构建
          _dirtyElements[index].rebuild();
        } catch (e, stack) {
        }
        index += 1;
        if (dirtyCount < _dirtyElements.length || _dirtyElementsNeedsResorting!) {
          _dirtyElements.sort(Element._sort);
          _dirtyElementsNeedsResorting = false;
          dirtyCount = _dirtyElements.length;
          while (index > 0 && _dirtyElements[index - 1].dirty) {
            // It is possible for previously dirty but inactive widgets to move right in the list.
            // We therefore have to move the index left in the list to account for this.
            // We don't know how many could have moved. However, we do know that the only possible
            // change to the list is that nodes that were previously to the left of the index have
            // now moved to be to the right of the right-most cleaned node, and we do know that
            // all the clean nodes were to the left of the index. So we move the index left
            // until just after the right-most clean node.
            index -= 1;
          }
        }
      }
    } finally {
      for (final Element element in _dirtyElements) {
        element._inDirtyList = false;
      }
      _dirtyElements.clear();
      _scheduledFlushDirtyElements = false;
      _dirtyElementsNeedsResorting = null;
      Timeline.finishSync();
    }
  }

  Map<Element, Set<GlobalKey>>? _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans;

  void _debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans(Element node, GlobalKey key) {
    _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans ??= HashMap<Element, Set<GlobalKey>>();
    final Set<GlobalKey> keys = _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans!
        .putIfAbsent(node, () => HashSet<GlobalKey>());
    keys.add(key);
  }

  void _debugElementWasRebuilt(Element node) {
    _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans?.remove(node);
  }

  /// Complete the element build pass by unmounting any elements that are no
  /// longer active.
  ///
  /// This is called by [WidgetsBinding.drawFrame].
  ///
  /// In debug mode, this also runs some sanity checks, for example checking for
  /// duplicate global keys.
  ///
  /// After the current call stack unwinds, a microtask that notifies listeners
  /// about changes to global keys will run.
  void finalizeTree() {
    Timeline.startSync('Finalize tree', arguments: timelineArgumentsIndicatingLandmarkEvent);
    try {
      lockState(() {
        _inactiveElements._unmountAll(); // this unregisters the GlobalKeys
      });
      assert(() {
        try {
          GlobalKey._debugVerifyGlobalKeyReservation();
          GlobalKey._debugVerifyIllFatedPopulation();
          if (_debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans != null &&
              _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans!.isNotEmpty) {
            final Set<GlobalKey> keys = HashSet<GlobalKey>();
            for (final Element element in _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans!.keys) {
              if (element._lifecycleState != _ElementLifecycle.defunct)
                keys.addAll(_debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans![element]!);
            }
            if (keys.isNotEmpty) {
              final Map<String, int> keyStringCount = HashMap<String, int>();
              for (final String key in keys.map<String>((GlobalKey key) => key.toString())) {
                if (keyStringCount.containsKey(key)) {
                  keyStringCount.update(key, (int value) => value + 1);
                } else {
                  keyStringCount[key] = 1;
                }
              }
              final List<String> keyLabels = <String>[];
              keyStringCount.forEach((String key, int count) {
                if (count == 1) {
                  keyLabels.add(key);
                } else {
                  keyLabels.add('$key ($count different affected keys had this toString representation)');
                }
              });
              final Iterable<Element> elements = _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans!.keys;
              final Map<String, int> elementStringCount = HashMap<String, int>();
              for (final String element in elements.map<String>((Element element) => element.toString())) {
                if (elementStringCount.containsKey(element)) {
                  elementStringCount.update(element, (int value) => value + 1);
                } else {
                  elementStringCount[element] = 1;
                }
              }
              final List<String> elementLabels = <String>[];
              elementStringCount.forEach((String element, int count) {
                if (count == 1) {
                  elementLabels.add(element);
                } else {
                  elementLabels.add('$element ($count different affected elements had this toString representation)');
                }
              });
              assert(keyLabels.isNotEmpty);
              final String the = keys.length == 1 ? ' the' : '';
              final String s = keys.length == 1 ? '' : 's';
              final String were = keys.length == 1 ? 'was' : 'were';
              final String their = keys.length == 1 ? 'its' : 'their';
              final String respective = elementLabels.length == 1 ? '' : ' respective';
              final String those = keys.length == 1 ? 'that' : 'those';
              final String s2 = elementLabels.length == 1 ? '' : 's';
              final String those2 = elementLabels.length == 1 ? 'that' : 'those';
              final String they = elementLabels.length == 1 ? 'it' : 'they';
              final String think = elementLabels.length == 1 ? 'thinks' : 'think';
              final String are = elementLabels.length == 1 ? 'is' : 'are';
              // TODO(jacobr): make this error more structured to better expose which widgets had problems.
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Duplicate GlobalKey$s detected in widget tree.'),
                // TODO(jacobr): refactor this code so the elements are clickable
                // in GUI debug tools.
                ErrorDescription(
                    'The following GlobalKey$s $were specified multiple times in the widget tree. This will lead to '
                        'parts of the widget tree being truncated unexpectedly, because the second time a key is seen, '
                        'the previous instance is moved to the new location. The key$s $were:\n'
                        '- ${keyLabels.join("\n  ")}\n'
                        'This was determined by noticing that after$the widget$s with the above global key$s $were moved '
                        'out of $their$respective previous parent$s2, $those2 previous parent$s2 never updated during this frame, meaning '
                        'that $they either did not update at all or updated before the widget$s $were moved, in either case '
                        'implying that $they still $think that $they should have a child with $those global key$s.\n'
                        'The specific parent$s2 that did not update after having one or more children forcibly removed '
                        'due to GlobalKey reparenting $are:\n'
                        '- ${elementLabels.join("\n  ")}'
                        '\nA GlobalKey can only be specified on one widget at a time in the widget tree.'
                ),
              ]);
            }
          }
        } finally {
          _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans?.clear();
        }
        return true;
      }());
    } catch (e, stack) {
      // Catching the exception directly to avoid activating the ErrorWidget.
      // Since the tree is in a broken state, adding the ErrorWidget would
      // cause more exceptions.
      _debugReportException(ErrorSummary('while finalizing the widget tree'), e, stack);
    } finally {
      Timeline.finishSync();
    }
  }

  /// Cause the entire subtree rooted at the given [Element] to be entirely
  /// rebuilt. This is used by development tools when the application code has
  /// changed and is being hot-reloaded, to cause the widget tree to pick up any
  /// changed implementations.
  ///
  /// This is expensive and should not be called except during development.
  void reassemble(Element root) {
    Timeline.startSync('Dirty Element Tree');
    try {
      assert(root._parent == null);
      assert(root.owner == this);
      root.reassemble();
    } finally {
      Timeline.finishSync();
    }
  }
}
