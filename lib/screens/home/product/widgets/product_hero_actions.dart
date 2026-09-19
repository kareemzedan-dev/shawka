import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';

/// زر دائري أبيض فوق الصورة (رجوع/مشاركة/مفضلة).
class ProductHeroCircleButton extends StatelessWidget {
  const ProductHeroCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconColor = ProductTokens.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: ProductTokens.heroButtonShadow,
            ),
            child: SizedBox(
              width: ProductTokens.touchTarget,
              height: ProductTokens.touchTarget,
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط الإجراءات العلوي فوق الـ hero: رجوع (بداية) + مشاركة/مفضلة (نهاية).
class ProductHeroActions extends StatelessWidget {
  const ProductHeroActions({
    super.key,
    required this.isFavorite,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
  });

  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProductHeroCircleButton(
          icon: Icons.arrow_forward_ios_rounded,
          semanticLabel: 'رجوع',
          onTap: onBack,
        ),
        const Spacer(),
        ProductHeroCircleButton(
          icon: Icons.share_outlined,
          semanticLabel: 'مشاركة المنتج',
          onTap: onShare,
        ),
        const SizedBox(width: ProductTokens.spaceMd),
        ProductHeroCircleButton(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          iconColor: AppColors.error,
          semanticLabel: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
          onTap: onToggleFavorite,
        ),
      ],
    );
  }
}
