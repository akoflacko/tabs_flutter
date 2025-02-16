import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onSelect;
  final _dateFormat = DateFormat('HH:mm');

  MessageBubble({
    super.key,
    required this.message,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onLongPress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: isSelectionMode ? onSelect : null,
      child: Row(
        children: [
          if (isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Transform.scale(
                scale: 1.2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.getAccentBackground(context)
                          : AppColors.getDividedColor(context),
                      width: 2,
                    ),
                    color: isSelected
                        ? AppColors.getAccentBackground(context)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.getAccentText(context),
                        )
                      : null,
                ),
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.getSecondaryBackground(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.getDividedColor(context),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: AppColors.getPrimaryText(context),
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text(
                        _dateFormat.format(message.timestamp),
                        style: TextStyle(
                          color: AppColors.getSecondaryText(context),
                          fontSize: 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
