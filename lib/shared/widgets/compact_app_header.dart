import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'notification_bell_widget.dart';

/// Compact header used in all tabs except home.
/// Same teal background, hamburger right, bell left, title + logo center.
class CompactAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CompactAppHeader({super.key, required this.title});

  @override
  Size get preferredSize {
    // height will be overridden by AppBar but we keep it for PreferredSizeWidget
    return const Size.fromHeight(64);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Platform.isIOS ? 30 : 22),
          bottomRight: Radius.circular(Platform.isIOS ? 30 : 22),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hamburger (RTL → right side visually)
          Builder(
            builder: (ctx) => _IconBtn(
              icon: Icons.menu_rounded,
              onTap: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),

          // Center: title only
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Notifications bell
          NotificationBellWidget(
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(Platform.isIOS ? 20 : 12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
