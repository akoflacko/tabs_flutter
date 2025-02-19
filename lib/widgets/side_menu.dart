// widgets/side_menu.dart
import 'package:flutter/material.dart';
import '../models/tab_item.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DragToOpenWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onOpenMenu;
  final double dragWidth;

  const DragToOpenWrapper({
    super.key,
    required this.child,
    required this.onOpenMenu,
    this.dragWidth = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: dragWidth,
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              if (details.localPosition.dx <= dragWidth) {
                onOpenMenu();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class SideMenu extends StatefulWidget {
  final List<TabItem> tabs;
  final int selectedIndex;
  final Function(int) onTabSelected;

  const SideMenu({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool _isCreateTabFocused = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Просто фон без размытия
        Container(
          color: const Color(0xFFE2E2E2),
        ),
        // Само меню
        Drawer(
          width: MediaQuery.of(context).size.width,
          backgroundColor: Colors.transparent,
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
                        return Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: SideMenuTab(
                              emoji: index == 0
                                  ? null
                                  : widget.tabs[index - 1].emoji,
                              title: index == 0
                                  ? null
                                  : widget.tabs[index - 1].title,
                              isSelected: index == 0
                                  ? _isCreateTabFocused
                                  : !_isCreateTabFocused &&
                                      widget.selectedIndex == index - 1,
                              onTap: index == 0
                                  ? null
                                  : () {
                                      print(
                                          '🔵 SideMenu: onTap for index ${index - 1}');
                                      widget.onTabSelected(index - 1);
                                      Future.delayed(Duration.zero, () {
                                        print(
                                            '🔵 SideMenu: calling Navigator.pop');
                                        Navigator.pop(context);
                                      });
                                    },
                              onCreateTab: index == 0
                                  ? (String title) {
                                      Navigator.pop(context);
                                    }
                                  : null,
                              onFocusChange: index == 0
                                  ? (focused) {
                                      setState(() {
                                        _isCreateTabFocused = focused;
                                      });
                                    }
                                  : null,
                              isCreateTab: index == 0,
                              index: index,
                              tabsCount: widget.tabs.length + 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SideMenuTab extends StatefulWidget {
  final String? emoji; // Может быть null для состояния создания
  final String? title; // Может быть null для состояния создания
  final bool isSelected;
  final VoidCallback? onTap; // Для обычного таба
  final Function(bool)? onFocusChange; // Для таба создания
  final bool isCreateTab; // Флаг, указывающий, что это таб создания
  final int index;
  final int tabsCount;
  final Function(String)? onCreateTab; // Для создания нового таба

  const SideMenuTab({
    super.key,
    this.emoji,
    this.title,
    required this.isSelected,
    this.onTap,
    this.onFocusChange,
    this.isCreateTab = false,
    required this.index,
    required this.tabsCount,
    this.onCreateTab,
  });

  @override
  State<SideMenuTab> createState() => _SideMenuTabState();
}

class _SideMenuTabState extends State<SideMenuTab> {
  bool _visible = false;
  bool _isEditing = false;
  String? _selectedEmoji;
  String? _lastText;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });

    if (widget.isCreateTab) {
      _focusNode.addListener(() {
        widget.onFocusChange?.call(_focusNode.hasFocus);
        setState(() {});
      });

      // Слушаем изменения текста
      _controller.addListener(() {
        final text = _controller.text;
        print('🔵 TextField: текущий текст: "$text"');
        print('🔵 TextField: длина текста: ${text.length}');
        print('🔵 TextField: длина в рунах: ${text.runes.length}');
        print('🔵 TextField: текущая эмодзи: $_selectedEmoji');

        if (text.isEmpty) {
          // Удаляем эмодзи ТОЛЬКО если:
          // 1. Эмодзи существует
          // 2. Текстовое поле было пустым до этого (значит это backspace)
          // 3. Курсор в начале поля
          if (_selectedEmoji != null &&
              _lastText?.isEmpty == true &&
              _controller.selection.baseOffset == 0) {
            print(
                '🔵 TextField: удаляем эмодзи и возвращаемся к исходному состоянию');
            setState(() {
              _selectedEmoji = null;
              _isEditing = false;
            });

            // Небольшая задержка перед новым фокусом
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                setState(() => _isEditing = true);
                _focusNode.requestFocus();
              }
            });
          }
        } else {
          if (_selectedEmoji == null) {
            final isEmojiResult = isEmoji(text);
            print('🔵 TextField: проверка на эмодзи: $isEmojiResult');

            if (isEmojiResult) {
              print('🔵 TextField: обнаружена эмодзи, сохраняем: "$text"');
              final emoji = text;
              _controller.clear();
              setState(() {
                _selectedEmoji = emoji;
                print('🔵 TextField: эмодзи установлена: $_selectedEmoji');
              });
            }
          }
        }
        _lastText = text;
      });
    }
  }

  bool isEmoji(String text) {
    if (text.isEmpty) {
      print('🔵 isEmoji: текст пустой');
      return false;
    }

    final runes = text.runes.toList();
    print('🔵 isEmoji: проверяем текст: "$text"');
    print('🔵 isEmoji: количество рун: ${runes.length}');
    print(
        '🔵 isEmoji: коды: ${runes.map((r) => '0x${r.toRadixString(16)}').join(", ")}');

    // Проверяем диапазоны эмодзи
    for (final rune in runes) {
      final isInRange =
          (rune >= 0x1F300 && rune <= 0x1F9FF) || // Основные эмодзи
              (rune >= 0x2600 && rune <= 0x26FF) || // Разные символы
              (rune >= 0x2700 && rune <= 0x27BF) || // Dingbats
              (rune >= 0xFE00 && rune <= 0xFE0F); // Вариации

      print(
          '🔵 isEmoji: руна 0x${rune.toRadixString(16)} ${isInRange ? 'в диапазоне' : 'не в диапазоне'}');

      if (!isInRange) {
        print('🔵 isEmoji: не эмодзи');
        return false;
      }
    }

    print('🔵 isEmoji: это эмодзи');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: _visible ? 0.0 : -1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * 100, 0),
          child: Opacity(
            opacity: value == -1 ? 0 : 1,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SmoothContainer(
          smoothness: 0.6,
          borderRadius: BorderRadius.circular(12),
          color:
              (widget.isCreateTab && _focusNode.hasFocus) || widget.isSelected
                  ? AppColors.getSecondaryBackground(context)
                  : AppColors.getPrimaryBackground(context),
          side: (widget.isCreateTab && _focusNode.hasFocus) || widget.isSelected
              ? BorderSide(
                  color: AppColors.getTertiaryBackground(context),
                  width: 1,
                )
              : BorderSide.none,
          child: Material(
            color: Colors.transparent,
            child: widget.isCreateTab
                ? _buildCreateTab(context)
                : _buildNormalTab(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTab(BuildContext context) {
    return _isEditing
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Показываем эмодзи если она выбрана
                if (_selectedEmoji != null) ...[
                  Text(
                    _selectedEmoji!,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: AppColors.getPrimaryText(context),
                      fontSize: 17,
                      letterSpacing: 0.2,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Make a Tab',
                      hintStyle: TextStyle(
                        color: AppColors.getSecondaryText(context),
                        fontSize: 17,
                        letterSpacing: 0.2,
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && _selectedEmoji != null) {
                        widget.onCreateTab?.call('$_selectedEmoji $value');
                        setState(() {
                          _isEditing = false;
                          _controller.clear();
                          _selectedEmoji = null;
                        });
                      }
                    },
                  ),
                ),
                if (_controller.text.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      if (_controller.text.isNotEmpty) {
                        widget.onFocusChange?.call(false);
                        setState(() {
                          _isEditing = false;
                          _controller.clear();
                        });
                      }
                    },
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        'assets/icons/tab_check.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          AppColors.getSecondaryText(context),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        : InkWell(
            onTap: () {
              setState(() => _isEditing = true);
              Future.delayed(const Duration(milliseconds: 50), () {
                _focusNode.requestFocus();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Make a Tab',
                    style: TextStyle(
                      color: AppColors.getSecondaryText(context),
                      fontSize: 17,
                      letterSpacing: 0.2,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildNormalTab(BuildContext context) {
    return InkWell(
      onTap: () {
        print('🔵 SideMenuTab: onTap called');
        widget.onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              widget.emoji ?? '',
              style: TextStyle(
                fontSize: 20,
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: AppColors.getPrimaryText(context),
                  fontSize: 17,
                  letterSpacing: 0.2,
                  fontWeight:
                      widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
                child: Text(widget.title ?? ''),
              ),
            ),
            if (widget.index == 1) ...[
              // Показываем иконку только для Inbox
              const SizedBox(width: 16),
              SizedBox(
                // Оборачиваем в SizedBox фиксированного размера
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/icons/tab_pin.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    AppColors.getSecondaryText(context),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
