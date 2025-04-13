import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/tab_item.dart';

class ScrollTabs extends StatefulWidget {
  final List<TabItem> tabs;

  final int selectedIndex;
  final Function(int) onTabSelected;

  const ScrollTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<ScrollTabs> createState() => _ScrollTabsState();
}

class _ScrollTabsState extends State<ScrollTabs> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _tabKeys.addAll(
      List.generate(
        widget.tabs.length,
        (index) => GlobalKey(),
      ),
    );
  }

  @override
  void didUpdateWidget(ScrollTabs oldWidget) {
    // Update _tabKeys if the tabs list has changed
    final equality = const ListEquality();
    if (!equality.equals(widget.tabs, oldWidget.tabs)) {
      _tabKeys.clear();
      _tabKeys.addAll(
        List.generate(
          widget.tabs.length,
          (index) => GlobalKey(),
        ),
      );
    }

    // Scroll to the selected tab
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _scrollToSelectedTab();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _scrollToSelectedTab() {
    if (!mounted) return;

    // Проверяем валидность индекса
    if (widget.selectedIndex >= _tabKeys.length) return;

    final context = _tabKeys[widget.selectedIndex].currentContext;
    if (context == null) return;

    final RenderBox tabBox = context.findRenderObject() as RenderBox;
    final RenderBox listBox = this.context.findRenderObject() as RenderBox;

    final double tabCenter =
        tabBox.localToGlobal(Offset.zero).dx + tabBox.size.width / 2;

    final double listCenter =
        listBox.localToGlobal(Offset.zero).dx + listBox.size.width / 2;

    final double scrollOffset =
        _scrollController.offset + (tabCenter - listCenter);

    _scrollController.animateTo(
      scrollOffset.clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleTabTap(int index) {
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.getPrimaryBackground(context),
            boxShadow: [
              BoxShadow(
                color: AppColors.getPrimaryBackground(context),
                blurRadius: 16,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: AppColors.getPrimaryBackground(context),
                blurRadius: 16,
                spreadRadius: 8,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: _buildItems(),
            ),
          ),
        ),
      );

  List<Widget> _buildItems() => List.generate(
        widget.tabs.length,
        (index) => _Tab(
          tabItem: widget.tabs[index],
          isSelected: index == widget.selectedIndex,
          key: _tabKeys[index],
          onTap: () => _handleTabTap(index),
        ),
      );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// {@template tabs_tab_bar}
/// _Tab widget.
/// {@endtemplate}
class _Tab extends StatelessWidget {
  /// {@macro tabs_tab_bar}
  const _Tab({
    required this.tabItem,
    required this.isSelected,
    this.onTap,
    super.key, // ignore: unused_element
  });

  final TabItem tabItem;

  final bool isSelected;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? AppColors.getSecondaryBackground(context)
        : AppColors.getPrimaryBackground(context);

    final borderColor = isSelected
        ? AppColors.getDividedColor(context)
        : AppColors.getTertiaryBackground(context);

    final textColor = isSelected
        ? AppColors.getPrimaryText(context)
        : AppColors.getSecondaryText(context);

    final borderRadius = BorderRadius.circular(20);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (tabItem.emoji != null)
                    Text(
                      tabItem.emoji!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1,
                      ),
                    ),
                  Text(
                    tabItem.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      height: 1,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
