import 'internal.dart';

// TODO: Missing Documentation
class TreeView extends StatefulWidget {
  const TreeView({
    Key? key,
    required this.nodeBuilder,
    required this.controller,
    this.shrinkWrap = false,
    this.onTap,
    this.onLongPress,
    this.theme = const TreeViewTheme(),
  }) : super(key: key);

  /// The instance of [TreeController] to expand/collapse nodes.
  final TreeViewController controller;

  /// The instance of [TreeViewTheme] that controls the theme of the [TreeView].
  final TreeViewTheme theme;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// See [AnimatedList.shrinkWrap]
  final bool shrinkWrap;

  /// Called, as needed, to build node widgets.
  /// Nodes are only built when they're scrolled into view.
  ///
  /// The Widget returned by this function will get wrapped in an [InkWell] and
  /// left padded with lines (if lines are enabled).
  final NodeBuilder nodeBuilder;

  /// Callback for when user taps on a node.
  final TreeViewCallback? onTap;

  /// Callback for when user long presses a node.
  final TreeViewCallback? onLongPress;

  @override
  _TreeViewState createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  late final TreeViewController controller;

  /// A key to control the animation of adding/removing nodes
  final _animatedListKey = GlobalKey<AnimatedListState>();
  AnimatedListState get _animatedList => _animatedListKey.currentState!;

  /// The list of nodes that are currently visible in the [TreeView]
  List<TreeNode> get visibleNodes => _visibleNodes;
  late final List<TreeNode> _visibleNodes;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    controller.eventDispatcher.addListener(treeViewEventHandler);

    _visibleNodes = List<TreeNode>.from(controller.rootNode.children);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      shrinkWrap: widget.shrinkWrap,
      key: _animatedListKey,
      initialItemCount: visibleNodes.length,
      itemBuilder: (_, int index, Animation<double> animation) {
        return _buildNode(_nodeAt(index), animation);
      },
    );
  }

  /// The callback to build the widget that will get animated
  /// when a node is inserted/removed from de tree.
  Widget _buildNode(TreeNode node, Animation<double> animation) {
    return NodeWidget(
      key: node.key,
      animation: animation,
      node: node,
      theme: widget.theme,
      controller: controller,
      nodeBuilder: widget.nodeBuilder,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }

  /// Event handler for expanding/collapsing nodes.
  void treeViewEventHandler() {
    final event = controller.eventDispatcher.event;

    if (event is NodeExpandedEvent) {
      _insertAll(
        _indexOf(event.node) + 1,
        event.node.children,
      );
    } else if (event is NodeCollapsedEvent) {
      _removeAll(event.nodes);
    }
  }

  // PRIVATE METHODS

  TreeNode _nodeAt(int index) => _visibleNodes[index];

  int _indexOf(TreeNode node) => _visibleNodes.indexOf(node);

  void _insert(int index, TreeNode node) {
    _visibleNodes.insert(index, node);
    _animatedList.insertItem(index);
  }

  void _insertAll(int index, List<TreeNode> nodes) {
    // The list must be reversed for the order to not get messed up
    nodes.reversed.forEach((node) => _insert(index, node));
  }

  void _removeAt(int index) {
    final removedItem = _visibleNodes.removeAt(index);
    _animatedList.removeItem(
      index,
      (_, animation) => _buildNode(removedItem, animation),
    );
  }

  void _removeAll(List<TreeNode> nodes) {
    nodes.forEach((node) {
      if (_visibleNodes.contains(node)) {
        _removeAt(_indexOf(node));
      }
    });
  }

  @override
  void dispose() {
    controller.eventDispatcher.removeListener(treeViewEventHandler);
    super.dispose();
  }
}
