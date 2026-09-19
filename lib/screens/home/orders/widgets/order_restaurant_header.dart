import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart' show storeCategoryIcon;

/// رأس بطاقة الطلب — شعار المتجر + الاسم (+ توثيق) + المعرّف والوقت + التقييم.
class OrderRestaurantHeader extends StatelessWidget {
  const OrderRestaurantHeader({
    super.key,
    required this.order,
  });

  final Order order;

  static String shortId(String id) => id.length > 6
      ? id.substring(id.length - 6).toUpperCase()
      : id.toUpperCase();

  static String formatRelative(DateTime date, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    const tint = AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StoreLogo(order: order, tint: tint),
        const SizedBox(width: OrdersTokens.spaceLg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      order.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CartTypography.style(
                        fontSize: OrdersTokens.storeNameSize,
                        fontWeight: FontWeight.w800,
                        color: OrdersTokens.textPrimary,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (order.storeVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: OrdersTokens.verified,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '#${shortId(order.id)} • ${formatRelative(order.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CartTypography.style(
                  fontSize: OrdersTokens.metaSize,
                  fontWeight: FontWeight.w600,
                  color: OrdersTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (order.storeRating > 0) ...[
          const SizedBox(width: OrdersTokens.spaceSm),
          _RatingPill(rating: order.storeRating),
        ],
      ],
    );
  }
}

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({required this.order, required this.tint});

  final Order order;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: tint.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(storeCategoryIcon(order.category), color: tint, size: 24),
    );

    return SizedBox(
      width: OrdersTokens.storeLogo,
      height: OrdersTokens.storeLogo,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OrdersTokens.storeLogo / 2),
        child: order.storeImageUrl.isEmpty
            ? fallback
            : CatalogNetworkImage(
                imageUrl: order.storeImageUrl,
                fallback: fallback,
                borderRadius:
                    BorderRadius.circular(OrdersTokens.storeLogo / 2),
                cacheWidth: 120,
                cacheHeight: 120,
              ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OrdersTokens.spaceSm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: OrdersTokens.star.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(OrdersTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: CartTypography.style(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF8A6200),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 14, color: OrdersTokens.star),
        ],
      ),
    );
  }
}
