import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/checkout_quote.dart';

class CheckoutOrderLineTile extends StatelessWidget {
  const CheckoutOrderLineTile({
    super.key,
    required this.palette,
    required this.line,
    required this.cartItem,
    required this.onQuantityChanged,
  });

  final AppPalette palette;
  final CheckoutResolvedLine line;
  final CartItem? cartItem;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final image = line.imageThumbUrl.isNotEmpty
        ? line.imageThumbUrl
        : line.imageUrl;
    return Semantics(
      container: true,
      label:
          '${line.productName}. ${line.lineTotal.toStringAsFixed(0)} جنيه. الكمية ${line.quantity}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CheckoutTokens.radiusXl - 6),
            child: SizedBox(
              width: CheckoutTokens.lineThumb + 8,
              height: CheckoutTokens.lineThumb + 8,
              child: image.isEmpty
                  ? ColoredBox(
                      color: palette.surfaceMuted,
                      child: Icon(
                        Icons.fastfood_rounded,
                        color: palette.textHint,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          ColoredBox(color: palette.surfaceMuted),
                      errorWidget: (_, _, _) => ColoredBox(
                        color: palette.surfaceMuted,
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: palette.textHint,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: CheckoutTokens.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CartTypography.style(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                if (line.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CartTypography.style(
                      fontSize: 11.5,
                      color: palette.textHint,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  '${line.lineTotal.toStringAsFixed(0)} ج.م',
                  style: CartTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CheckoutTokens.accentText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: CheckoutTokens.spaceSm),
          QuantityControl(
            quantity: line.quantity,
            enabled: cartItem != null,
            onChanged: onQuantityChanged,
          ),
        ],
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.quantity,
    required this.enabled,
    required this.onChanged,
  });

  final int quantity;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'الكمية $quantity',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CheckoutTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(CheckoutTokens.radiusXl - 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuantityButton(
              semanticLabel: 'تقليل الكمية',
              icon: quantity == 1
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              onTap: enabled ? () => onChanged(quantity - 1) : null,
            ),
            AnimatedSwitcher(
              duration: CheckoutTokens.motionFast,
              child: SizedBox(
                key: ValueKey(quantity),
                width: 25,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: CartTypography.style(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
            QuantityButton(
              semanticLabel: 'زيادة الكمية',
              icon: Icons.add_rounded,
              onTap: enabled ? () => onChanged(quantity + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityButton extends StatelessWidget {
  const QuantityButton({
    super.key,
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: CheckoutTokens.touchTarget,
        height: CheckoutTokens.touchTarget,
        child: IconButton(
          onPressed: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 17),
          color: AppColors.navy,
        ),
      ),
    );
  }
}
