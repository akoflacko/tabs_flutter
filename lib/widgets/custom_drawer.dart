import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class CustomDrawerController with ChangeNotifier {
  bool isOpen = false;

  void toggle() {
    isOpen = !isOpen;
    notifyListeners();
  }

  void open() {
    isOpen = true;
    notifyListeners();
  }

  void close() {
    isOpen = false;
    notifyListeners();
  }
}

/// {@template custom_drawer}
/// CustomDrawer widget.
/// {@endtemplate}
class CustomDrawer extends StatefulWidget {
  /// {@macro custom_drawer}
  const CustomDrawer({
    required this.width,
    required this.drawer,
    required this.child,
    required this.controller,
    super.key, // ignore: unused_element
  });

  final double width;

  final Widget drawer;

  final Widget child;

  final CustomDrawerController controller;

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

/// State for widget CustomDrawer.
class _CustomDrawerState extends State<CustomDrawer> {
  double _currentVisibleWidth = 0.0;

  void _controllerListener() {
    setState(
      () =>
          _currentVisibleWidth = widget.controller.isOpen ? widget.width : 0.0,
    );
  }

  void _updateVisibleWidth(double value) {
    setState(
      () => _currentVisibleWidth = value,
    );
  }

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
  }

  @override
  void didUpdateWidget(covariant CustomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget configuration changed
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The configuration of InheritedWidgets has changed
    // Also called after initState but before build
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    super.dispose();
  }
  /* #endregion */

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: _currentVisibleWidth,
          top: 0,
          bottom: 0,
          width: widget.width,
          child: widget.drawer,
        ),
        widget.child,
      ],
    );
  }
}
