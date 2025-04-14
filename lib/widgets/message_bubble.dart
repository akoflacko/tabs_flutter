import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool selectionModeEnabled;
  final bool isSelected;

  final VoidCallback onLongPress;
  final VoidCallback onSelect;

  const MessageBubble({
    super.key,
    required this.message,
    required this.selectionModeEnabled,
    required this.isSelected,
    required this.onLongPress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    return InkWell(
      onLongPress: selectionModeEnabled ? null : onLongPress,
      onTap: selectionModeEnabled ? onSelect : null,
      borderRadius: borderRadius,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                axisAlignment: 0.0,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              ),
            ),
            child: selectionModeEnabled
                ? _Radio(
                    isSelected: isSelected,
                  )
                : const SizedBox.shrink(),
          ),
          if (selectionModeEnabled) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getSecondaryBackground(context),
                borderRadius: borderRadius,
                border: Border.all(
                  color: AppColors.getTertiaryBackground(context),
                  width: 1,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: AppColors.getPrimaryText(context),
                  letterSpacing: 0.2,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// {@template radio}
/// _Radio widget.
/// {@endtemplate}
class _Radio extends StatelessWidget {
  /// {@macro radio}
  const _Radio({
    required this.isSelected,
    super.key, // ignore: unused_element_parameter
  });

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.getAccentBackground(context) : AppColors.getDividedColor(context),
            width: 2,
          ),
          color: isSelected ? AppColors.getAccentBackground(context) : Colors.transparent,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
