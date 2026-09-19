import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/profile_tokens.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/profile/profile_controller.dart';

class ProfileRecentActivitySection extends StatelessWidget {
  const ProfileRecentActivitySection({
    super.key,
    required this.order,
    required this.onViewAll,
    required this.onTapOrder,
  });

  final Order? order;
  final VoidCallback onViewAll;
  final VoidCallback onTapOrder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'آخر نشاط',
                style: CartTypography.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ProfileTokens.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: ProfileTokens.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 40),
              ),
              child: Text(
                'عرض الكل',
                style: CartTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ProfileTokens.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (order == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ProfileTokens.activityBg,
              borderRadius: BorderRadius.circular(ProfileTokens.cardRadius),
            ),
            child: Text(
              'لا يوجد نشاط بعد — ابدأ بطلبك الأول',
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ProfileTokens.textSecondary,
              ),
            ),
          )
        else
          Material(
            color: ProfileTokens.activityBg,
            borderRadius: BorderRadius.circular(ProfileTokens.cardRadius),
            child: InkWell(
              onTap: onTapOrder,
              borderRadius: BorderRadius.circular(ProfileTokens.cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CatalogNetworkImage(
                          imageUrl: order!.storeImageUrl.trim().isEmpty
                              ? null
                              : order!.storeImageUrl,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(10),
                          cacheWidth: 96,
                          cacheHeight: 96,
                          fallback: Container(
                            color:
                                ProfileTokens.navy.withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: ProfileTokens.navy,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ProfileActivityFormat.title(order!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartTypography.style(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: ProfileTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order!.status.label} • ${ProfileActivityFormat.relativeTime(order!.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ProfileTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ProfileActivityFormat.price(order!),
                      style: CartTypography.style(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: ProfileTokens.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
