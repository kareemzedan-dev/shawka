import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';

/// رأس شاشة الطلبات (navy) — عنوان مركزي + وصف + جرس الإشعارات.
class OrdersHeader extends StatelessWidget {
  const OrdersHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.notificationBadge,
    this.onNotifications,
  });

  final String title;
  final String subtitle;
  final int notificationBadge;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        const Positioned.fill(child: _HeaderBackground()),
        Padding(
          padding: EdgeInsets.fromLTRB(
            OrdersTokens.space2xl,
            top + OrdersTokens.spaceMd,
            OrdersTokens.space2xl,
            OrdersTokens.space3xl + OrdersTokens.spaceXs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // موازنة بصرية مع زر الإشعارات لإبقاء العنوان في الوسط
              const SizedBox(
                width: OrdersTokens.touchTarget,
                height: OrdersTokens.touchTarget,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: CartTypography.style(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CartTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotifications,
                badge: notificationBadge,
                semanticLabel: 'الإشعارات',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OrdersTokens.radiusSm),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(OrdersTokens.radiusSm),
            child: InkWell(
              onTap: onTap ?? () {},
              borderRadius: BorderRadius.circular(OrdersTokens.radiusSm),
              child: SizedBox(
                width: OrdersTokens.touchTarget,
                height: OrdersTokens.touchTarget,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: AppColors.white, size: 22),
                    if (badge != null && badge! > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badge! > 9 ? '9+' : '$badge',
                            textAlign: TextAlign.center,
                            style: CartTypography.style(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.inkElevated,
                AppColors.navy,
                AppColors.black,
              ],
              stops: [0, 0.5, 1],
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
