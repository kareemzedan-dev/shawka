import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

export 'package:matlobgo/shared/design_system/components/catalog_product_card.dart'
    show CatalogProductCard;

/// Web product row — always shows a fixed image slot.
class WebPremiumProductCard extends StatelessWidget {
  const WebPremiumProductCard({
    super.key,
    required this.store,
    required this.product,
    this.onTap,
    this.onAdd,
  });

  final Store store;
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TarfaTokens.surface,
      borderRadius: TarfaTokens.borderRadius,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TarfaTokens.borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: TarfaTokens.surface,
            borderRadius: TarfaTokens.borderRadius,
            border: Border.all(color: TarfaTokens.divider),
            boxShadow: TarfaTokens.shadowSm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TarfaTokens.s12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TarfaWebImage(
                    kind: TarfaImageKind.product,
                    width: 88,
                    height: 88,
                    imageUrl: product.imageUrl,
                    thumbnailUrl: product.imageThumbUrl,
                  ),
                ),
                const SizedBox(width: TarfaTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.navy,
                        ),
                      ),
                      if (product.description != null &&
                          product.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${product.price.toStringAsFixed(0)} ج.م',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: TarfaTokens.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TarfaTokens.s8),
                if (product.isInStock && onAdd != null)
                  FilledButton(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(
                      backgroundColor: TarfaTokens.secondary,
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, size: 22),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
