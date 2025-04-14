import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabs_test/models/tab_item.dart';
import 'package:tabs_test/theme/app_colors.dart';
import 'package:tabs_test/widgets/side_menu_tile_wrapper.dart';

/// {@template tab_tile}
/// TabTile widget.
/// {@endtemplate}
class TabTile extends StatelessWidget {
  /// {@macro tab_tile}
  const TabTile({
    required this.tabItem,
    required this.onTap,
    this.isSelected = false,
    super.key, // ignore: unused_element
  });

  final TabItem tabItem;

  final bool isSelected;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SideMenuTileWrapper(
        backgroundColor: isSelected ? AppColors.getSecondaryBackground(context) : AppColors.getPrimaryBackground(context),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(tabItem.emoji ?? '', style: TextStyle(fontSize: 20, fontFamily: GoogleFonts.inter().fontFamily)),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      color: AppColors.getPrimaryText(context),
                      fontSize: 17,
                      letterSpacing: 0.2,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                    child: Text(tabItem.title),
                  ),
                ),
                if (tabItem.isInbox) ...[
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
                      colorFilter: ColorFilter.mode(AppColors.getSecondaryText(context), BlendMode.srcIn),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
