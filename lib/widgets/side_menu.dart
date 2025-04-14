// widgets/side_menu.dart
import 'package:flutter/material.dart';
import 'package:tabs_test/widgets/create_tab_input.dart';
import 'package:tabs_test/widgets/tab_tile.dart';
import '../models/tab_item.dart';

class SideMenu extends StatefulWidget {
  final List<TabItem> tabs;

  final PageController pageController;

  const SideMenu({
    super.key,
    required this.tabs,
    required this.pageController,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool _coloredTile = true;

  void _onTabSelected(TabItem tab) {
    final index = widget.tabs.indexWhere((t) => t.id == tab.id);
    if (index == -1) return;

    widget.pageController.jumpToPage(index);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Drawer(
        width: MediaQuery.of(context).size.width,
        backgroundColor: const Color(0xFFE2E2E2),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                  itemCount: widget.tabs.length,
                  itemBuilder: (context, index) {
                    final tab = widget.tabs[index];
                    final isSelected = index == widget.pageController.page?.round() && _coloredTile;

                    return FractionallySizedBox(
                      widthFactor: .85,
                      child: TabTile(
                        tabItem: widget.tabs[index],
                        isSelected: isSelected,
                        onTap: () => _onTabSelected(tab),
                      ),
                    );
                  },
                ),
              ),
              FractionallySizedBox(
                widthFactor: .85,
                child: CreateTabInput(
                  onFocusChanged: (value) => setState(() => _coloredTile = !value),
                  onTabCreated: (tab) => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
}
