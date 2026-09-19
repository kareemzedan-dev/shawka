import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/cart_item.dart';

class CartQuantityStepper extends StatelessWidget {
  const CartQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.maxQuantity,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int? maxQuantity;

  @override
  Widget build(BuildContext context) {
    final atMax = maxQuantity != null && quantity >= maxQuantity!;
    return Semantics(
      label: 'الكمية $quantity',
      child: Container(
        height: CartTokens.stepperHeight,
        decoration: BoxDecoration(
          color: CartTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(CartTokens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              semanticLabel: 'تقليل الكمية',
              onTap: quantity <= 1 ? null : () => onChanged(quantity - 1),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 28),
              child: AnimatedSwitcher(
                duration: CartTokens.motionFast,
                switchInCurve: CartTokens.curveStandard,
                switchOutCurve: CartTokens.curveIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Text(
                  '$quantity',
                  key: ValueKey(quantity),
                  textAlign: TextAlign.center,
                  style: CartTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              semanticLabel: 'زيادة الكمية',
              onTap: atMax ? null : () => onChanged(quantity + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CartTokens.touchTarget,
      height: CartTokens.touchTarget,
      child: IconButton(
        tooltip: semanticLabel,
        padding: EdgeInsets.zero,
        onPressed: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        icon: Icon(
          icon,
          size: CartTokens.stepperIcon,
          color: onTap == null ? AppColors.textHint : AppColors.navy,
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onSwiped,
    this.maxQuantity,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onSwiped;
  final int? maxQuantity;

  String get _stockLabel {
    if (!item.isAvailable) return 'غير متاح حالياً';
    if (item.trackStock && item.stockQuantity != null) {
      if (item.stockQuantity! <= 0) return 'نفد المخزون';
      if (item.maxPerCustomer > 0) {
        return 'المتوفر ${item.stockQuantity} · حد العميل ${item.maxPerCustomer}';
      }
      return 'المتوفر ${item.stockQuantity}';
    }
    if (item.maxPerCustomer > 0) {
      return 'حد الطلب ${item.maxPerCustomer}';
    }
    return 'متاح';
  }

  String get _semanticsLabel {
    final price = '${item.price.toStringAsFixed(2)} جنيه';
    return '${item.productName}. السعر $price. الكمية ${item.quantity}. $_stockLabel';
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = maxQuantity ?? item.maxOrderQuantity;
    final discount = item.discountPercent.round();

    return Semantics(
      container: true,
      label: _semanticsLabel,
      child: Dismissible(
        key: ValueKey('cart_swipe_${item.id}'),
        direction: DismissDirection.startToEnd,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          onSwiped();
        },
        background: Container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.only(start: CartTokens.space3xl),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(CartTokens.radiusXl),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        ),
        child: Container(
          padding: const EdgeInsets.all(CartTokens.spaceLg),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(CartTokens.radiusXl),
            boxShadow: CartTokens.cardShadow,
          ),
          child: Opacity(
            opacity: item.isAvailable ? 1 : 0.55,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Semantics(
                          button: true,
                          label: 'حذف ${item.productName}',
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onRemove();
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.textHint.withValues(alpha: 0.9),
                              size: CartTokens.stepperIcon,
                            ),
                          ),
                        ),
                      ),
                      ExcludeSemantics(
                        child: Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CartTypography.style(
                            fontSize: CartTokens.itemTitleSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.note.isNotEmpty || item.addonIds.isNotEmpty) ...[
                        const SizedBox(height: CartTokens.spaceXs),
                        Text(
                          item.note.isNotEmpty
                              ? item.note
                              : '${item.addonIds.length} إضافات',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CartTypography.style(
                            fontSize: CartTokens.metaSize,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (!item.isAvailable) ...[
                        const SizedBox(height: CartTokens.spaceXs),
                        Semantics(
                          liveRegion: true,
                          label: _stockLabel,
                          child: Text(
                            'غير متاح حالياً',
                            style: CartTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: CartTokens.dangerText,
                            ),
                          ),
                        ),
                      ] else if ((item.trackStock && item.stockQuantity != null) ||
                          item.maxPerCustomer > 0) ...[
                        const SizedBox(height: CartTokens.spaceXs),
                        Semantics(
                          label: _stockLabel,
                          child: Text(
                            _stockLabel,
                            style: CartTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: CartTokens.spaceSm),
                      Semantics(
                        label: 'السعر ${item.price.toStringAsFixed(2)} جنيه',
                        child: Text(
                          '${item.price.toStringAsFixed(2)} ج.م',
                          style: CartTypography.style(
                            fontSize: CartTokens.priceSize,
                            fontWeight: FontWeight.w800,
                            color: CartTokens.accentText,
                          ),
                        ),
                      ),
                      const SizedBox(height: CartTokens.spaceMd),
                      CartQuantityStepper(
                        quantity: item.quantity,
                        maxQuantity: maxQty,
                        onChanged: onQuantityChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CartTokens.spaceMd),
                ExcludeSemantics(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(CartTokens.radiusMd),
                        child: SizedBox(
                          width: CartTokens.productImage,
                          height: CartTokens.productImage,
                          child: CatalogNetworkImage(
                            imageUrl: item.imageUrl,
                            thumbnailUrl: item.imageThumbUrl,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: CartTokens.surfaceMuted,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (discount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(CartTokens.radiusXs),
                            ),
                            child: Text(
                              'خصم $discount%',
                              style: CartTypography.style(
                                fontSize: CartTokens.badgeSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
