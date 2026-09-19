import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/profile_tokens.dart';

class ProfileStatsPair extends StatelessWidget {
  const ProfileStatsPair({
    super.key,
    required this.ordersCount,
    required this.favoritesCount,
    required this.onOrdersTap,
    required this.onFavoritesTap,
  });

  final int ordersCount;
  final int favoritesCount;
  final VoidCallback onOrdersTap;
  final VoidCallback onFavoritesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_bag_rounded,
            iconColor: ProfileTokens.navy,
            value: '$ordersCount',
            valueColor: ProfileTokens.navy,
            label: 'الطلبات',
            onTap: onOrdersTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_rounded,
            iconColor: ProfileTokens.heart,
            value: '$favoritesCount',
            valueColor: ProfileTokens.heart,
            label: 'المفضلة',
            onTap: onFavoritesTap,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(ProfileTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ProfileTokens.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ProfileTokens.cardRadius),
            border: Border.all(color: ProfileTokens.cardBorder),
            boxShadow: ProfileTokens.softShadow,
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: CartTypography.style(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: CartTypography.style(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ProfileTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
