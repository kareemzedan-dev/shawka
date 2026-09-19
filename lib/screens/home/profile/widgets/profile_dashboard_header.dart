import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/profile_tokens.dart';

/// شريط علوي Navy — عنوان + إشعارات.
class ProfileDashboardHeader extends StatelessWidget {
  const ProfileDashboardHeader({
    super.key,
    required this.onNotifications,
    this.notificationCount = 0,
  });

  final VoidCallback onNotifications;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: ProfileTokens.navy,
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 12),
      child: Row(
        children: [
          const SizedBox(width: 48, height: 48),
          Expanded(
            child: Text(
              'حسابي',
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            tooltip: 'الإشعارات',
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text('$notificationCount'),
              backgroundColor: ProfileTokens.accent,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
