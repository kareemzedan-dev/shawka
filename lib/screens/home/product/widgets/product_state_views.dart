import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';

/// شريط رفيع لحالة عدم الاتصال — يُعرض داخلياً فوق المحتوى.
///
/// لدينا دائماً بيانات المنتج الأولية من التنقّل، لذا الحالة الصحيحة
/// عند فقد الاتصال هي تنبيه غير معطِّل (لا شاشة كاملة).
class ProductOfflineBanner extends StatelessWidget {
  const ProductOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'لا يوجد اتصال — قد لا تكون البيانات محدّثة',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: ProductTokens.spaceLg),
        padding: const EdgeInsets.symmetric(
          horizontal: ProductTokens.spaceLg,
          vertical: ProductTokens.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: ProductTokens.accentText,
            ),
            const SizedBox(width: ProductTokens.spaceMd),
            Expanded(
              child: Text(
                'لا يوجد اتصال — قد لا تكون البيانات محدّثة',
                style: CartTypography.style(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ProductTokens.accentText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عرض موحّد ملء الشاشة للحالات النهائية (المنتج لم يعد متاحاً).
class ProductMessageView extends StatelessWidget {
  const ProductMessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  factory ProductMessageView.unavailable({required VoidCallback onBack}) {
    return ProductMessageView(
      icon: Icons.remove_shopping_cart_outlined,
      title: 'المنتج غير متاح',
      message: 'لم يعد هذا المنتج متاحاً حالياً.',
      actionLabel: 'العودة',
      onAction: onBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProductTokens.space3xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: ProductTokens.cardFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: ProductTokens.textMuted),
            ),
            const SizedBox(height: ProductTokens.space2xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ProductTokens.textPrimary,
              ),
            ),
            const SizedBox(height: ProductTokens.spaceSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: ProductTokens.bodySize,
                fontWeight: FontWeight.w500,
                color: ProductTokens.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: ProductTokens.space2xl),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: ProductTokens.ctaBackground,
                minimumSize: const Size(180, ProductTokens.touchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ProductTokens.radiusLg),
                ),
              ),
              child: Text(
                actionLabel,
                style: CartTypography.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
