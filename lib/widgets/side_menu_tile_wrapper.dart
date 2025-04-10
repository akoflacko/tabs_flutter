import 'package:flutter/material.dart';

class SideMenuTileWrapper extends StatefulWidget {
  final VoidCallback? onTap; // Для обычного таба

  const SideMenuTileWrapper({
    super.key,
    this.onTap,
    required this.child,
    required this.backgroundColor,
    this.border,
  });

  final Widget child;

  final Color backgroundColor;

  final Border? border;

  @override
  State<SideMenuTileWrapper> createState() => _SideMenuTileWrapperState();
}

class _SideMenuTileWrapperState extends State<SideMenuTileWrapper> {
  bool _visible = false;
  String? _lastText;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.backgroundColor,
            border: widget.border,
          ),
          child: Material(
            color: Colors.transparent,
            child: widget.child,
          ),
        ),
      );
}
