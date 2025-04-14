import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/tab_item.dart';

/// A scrollable tab bar that synchronizes with a page controller.
///
/// This widget creates horizontal scrollable tabs that automatically center
/// the selected tab in the viewport.
class ScrollTabs extends StatefulWidget {
  /// Creates a ScrollTabs widget.
  ///
  /// The [tabs] and [pageController] parameters must not be null.
  const ScrollTabs({
    super.key,
    required this.tabs,
    required this.pageController,
    this.initialIndex = 0,
    this.onTabSelected,
  });

  /// The list of tabs to display.
  final List<TabItem> tabs;

  /// The page controller to synchronize with.
  final PageController pageController;

  /// The initial selected tab index.
  final int initialIndex;

  /// Callback that is called when a tab is selected.
  final Function(int index)? onTabSelected;

  @override
  State<ScrollTabs> createState() => _ScrollTabsState();
}

class _ScrollTabsState extends State<ScrollTabs> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _tabKeys = [];
  late int _selectedIndex;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Initialize tab keys
    _tabKeys.addAll(
      List.generate(
        widget.tabs.length,
        (index) => GlobalKey(),
      ),
    );

    // Setup page controller listener
    widget.pageController.addListener(_pageControllerListener);

    // Schedule initial scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure the render objects are laid out
      if (mounted) {
        _scrollToSelectedTab(false);
        _isInitialized = true;
      }
    });
  }

  void _pageControllerListener() {
    final index = widget.pageController.page?.round() ?? 0;

    if (index != _selectedIndex && mounted) {
      setState(() => _selectedIndex = index);

      // Only scroll automatically after initialization to avoid
      // conflicts with the initial scroll
      if (_isInitialized) {
        _scrollToSelectedTab();
      }
    }
  }

  @override
  void didUpdateWidget(covariant ScrollTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update tab keys if the tabs list has changed
    if (!const ListEquality().equals(widget.tabs, oldWidget.tabs)) {
      _tabKeys.clear();
      _tabKeys.addAll(
        List.generate(
          widget.tabs.length,
          (index) => GlobalKey(),
        ),
      );

      // Schedule a scroll update after updating keys
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToSelectedTab();
        }
      });
    }

    // Update controller listener if the controller has changed
    if (widget.pageController != oldWidget.pageController) {
      oldWidget.pageController.removeListener(_pageControllerListener);
      widget.pageController.addListener(_pageControllerListener);
    }
  }

  void _scrollToSelectedTab([bool animated = true]) {
    if (!mounted || _tabKeys.isEmpty) return;

    // Safely get the current tab's context
    final tabKey = _selectedIndex < _tabKeys.length ? _tabKeys[_selectedIndex] : _tabKeys.last;

    final context = tabKey.currentContext;
    if (context == null) return;

    try {
      final RenderBox tabBox = context.findRenderObject() as RenderBox;
      final RenderBox listBox = this.context.findRenderObject() as RenderBox;

      // Calculate the center position of the tab
      final double tabCenter = tabBox.localToGlobal(Offset.zero).dx + tabBox.size.width / 2;
      final double listCenter = listBox.localToGlobal(Offset.zero).dx + listBox.size.width / 2;
      final double scrollOffset = _scrollController.offset + (tabCenter - listCenter);

      // Animate to the target position, ensuring we don't go beyond scroll bounds
      if (animated) {
        _scrollController.animateTo(
          scrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpTo(
          scrollOffset.clamp(
            0,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }
    } catch (e) {
      // Handle potential render errors silently
      debugPrint('Error scrolling to tab: $e');
    }
  }

  void _handleTabTap(int index) {
    if (index != _selectedIndex) {
      widget.pageController.jumpToPage(index);
      widget.onTabSelected?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.getPrimaryBackground(context),
          boxShadow: [
            BoxShadow(color: AppColors.getPrimaryBackground(context), blurRadius: 16, spreadRadius: 8),
            BoxShadow(color: AppColors.getPrimaryBackground(context), blurRadius: 16, spreadRadius: 8),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: List.generate(
              widget.tabs.length,
              (index) => _TabItem(
                tabItem: widget.tabs[index],
                isSelected: index == _selectedIndex,
                key: _tabKeys[index],
                onTap: () => _handleTabTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.pageController.removeListener(_pageControllerListener);
    super.dispose();
  }
}

/// Individual tab widget that displays a tab item
class _TabItem extends StatelessWidget {
  /// Creates a tab item.
  const _TabItem({
    required this.tabItem,
    required this.isSelected,
    this.onTap,
    super.key,
  });

  /// The tab item data to display.
  final TabItem tabItem;

  /// Whether the tab is currently selected.
  final bool isSelected;

  /// Callback when the tab is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? AppColors.getSecondaryBackground(context) : AppColors.getPrimaryBackground(context);

    final borderColor = isSelected ? AppColors.getDividedColor(context) : AppColors.getTertiaryBackground(context);

    final textColor = isSelected ? AppColors.getPrimaryText(context) : AppColors.getSecondaryText(context);

    final borderRadius = BorderRadius.circular(20);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (tabItem.emoji != null)
                    Text(
                      tabItem.emoji!,
                      style: const TextStyle(fontSize: 16, height: 1),
                    ),
                  Text(
                    tabItem.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      height: 1,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
