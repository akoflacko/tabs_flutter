import 'package:flutter/material.dart';
import 'package:tabs_test/models/tab_item.dart';

import '../theme/app_colors.dart';

class InputBar extends StatefulWidget {
  final TextEditingController controller;

  final FocusNode focusNode;

  final VoidCallback onSendPressed;

  final VoidCallback onAttachPressed;

  final String hintText;

  final bool isSelectionMode;

  final String? tabIdOfSelectedMessages;

  final int selectedCount;

  final VoidCallback onDelete;

  final ValueChanged<String> onMove;

  final List<TabItem> tabs;

  const InputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSendPressed,
    required this.onAttachPressed,
    required this.hintText,
    this.isSelectionMode = false,
    this.selectedCount = 0,
    required this.onDelete,
    required this.onMove,
    required this.tabs,
    this.tabIdOfSelectedMessages,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  bool get isTextEmpty => widget.controller.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = AppColors.getPrimaryBackground(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.getPrimaryBackground(context),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              spreadRadius: 8,
            ),
          ],
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: widget.isSelectionMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: _EditModeWidget(
            selectedCount: widget.selectedCount,
            tabs: List.of(widget.tabs)
              ..removeWhere(
                (tab) => tab.id == widget.tabIdOfSelectedMessages,
              ),
            onMove: widget.onMove,
            onDelete: widget.onDelete,
          ),
          secondChild: _InputBarWidget(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onSendPressed: isTextEmpty ? null : widget.onSendPressed,
            onAttachPressed: widget.onAttachPressed,
          ),
        ),
      ),
    );
  }
}

/// {@template input_bar}
/// _InputBarWidget widget.
/// {@endtemplate}
class _InputBarWidget extends StatelessWidget {
  /// {@macro input_bar}
  const _InputBarWidget({
    required this.controller,
    required this.focusNode,
    this.onSendPressed,
    this.onAttachPressed,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final VoidCallback? onSendPressed;
  final VoidCallback? onAttachPressed;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.getSecondaryBackground(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.getTertiaryBackground(context), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 1,
                style: TextStyle(color: AppColors.getPrimaryText(context), fontSize: 17, letterSpacing: 0.2),
                decoration: InputDecoration(
                  hintText: 'Новая заметка...',
                  hintStyle: TextStyle(color: AppColors.getSecondaryText(context), letterSpacing: 0.2),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendPressed?.call(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _AttachButton(onPressed: onAttachPressed),
                  const Spacer(),
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, child) => _SendButton(
                      onPressed: onSendPressed,
                      isEnabled: value.text.isNotEmpty,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// {@template input_bar}
/// _EditModeWidget widget.
/// {@endtemplate}
class _EditModeWidget extends StatelessWidget {
  /// {@macro input_bar}
  const _EditModeWidget({
    required this.selectedCount,
    required this.tabs,
    this.onMove,
    this.onDelete,
  });

  final int selectedCount;
  final List<TabItem> tabs;

  final ValueChanged<String>? onMove;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.getSecondaryBackground(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.getTertiaryBackground(context), width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '$selectedCount выбрано',
                style: TextStyle(color: AppColors.getPrimaryText(context), fontSize: 17, letterSpacing: 0.2),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    itemBuilder: (context) => List.generate(
                      tabs.length,
                      (index) => PopupMenuItem(
                        value: tabs[index].id,
                        child: Text(
                          tabs[index].title,
                        ),
                      ),
                    ),
                    onSelected: onMove,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                    color: AppColors.getPrimaryText(context),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _AttachButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AttachButton({
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.getTertiaryBackground(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(41), blurRadius: 2, offset: const Offset(0, 1))],
            ),
            child: Icon(Icons.add, size: 20, color: AppColors.getPrimaryText(context)),
          ),
        ),
      );
}

class _SendButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final bool isEnabled;

  const _SendButton({
    this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.getAccentBackground(context) : AppColors.getSecondaryText(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.arrow_upward, size: 16, color: AppColors.getAccentText(context)),
          ),
        ),
      );
}
