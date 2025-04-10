// widgets/side_menu.dart
import 'package:flutter/material.dart';
import 'package:tabs_test/widgets/create_tab_input.dart';
import 'package:tabs_test/widgets/tab_tile.dart';
import '../models/tab_item.dart';

class SideMenu extends StatefulWidget {
  final List<TabItem> tabs;

  final String selectedTabId;

  final Function(String) onTabSelected;

  const SideMenu({
    super.key,
    required this.tabs,
    required this.selectedTabId,
    required this.onTabSelected,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool _coloredTile = true;

  void _onTabSelected(TabItem tab) {
    widget.onTabSelected(tab.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Drawer(
        width: MediaQuery.of(context).size.width,
        backgroundColor: const Color(0xFFE2E2E2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            reverse: true,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 24,
                    ),
                    itemCount: widget.tabs.length + 1,
                    itemBuilder: (context, index) {
                      final Widget child;

                      if (index == 0) {
                        child = CreateTabInput(
                          onFocusChanged: (value) => setState(
                            () => _coloredTile = !value,
                          ),
                          onTabCreated: _onTabSelected,
                        );
                      } else {
                        final safeIndex = index - 1;

                        final tab = widget.tabs[safeIndex];
                        final isSelected =
                            widget.selectedTabId == tab.id && _coloredTile;

                        child = TabTile(
                          tabItem: widget.tabs[safeIndex],
                          isSelected: isSelected,
                          onTap: () => _onTabSelected(tab),
                        );
                      }

                      return FractionallySizedBox(
                        widthFactor: .85,
                        child: child,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
