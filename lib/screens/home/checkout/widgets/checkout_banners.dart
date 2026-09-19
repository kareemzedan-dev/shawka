import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';

class CheckoutErrorBanner extends StatelessWidget {
  const CheckoutErrorBanner({
    super.key,
    required this.message,
    required this.palette,
    this.onRetry,
  });

  final String message;
  final AppPalette palette;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CheckoutTokens.dangerText.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(CheckoutTokens.radiusXl - 6),
          border: Border.all(
            color: CheckoutTokens.dangerText.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: CheckoutTokens.dangerText,
              ),
              const SizedBox(width: CheckoutTokens.spaceMd - 1),
              Expanded(
                child: Text(
                  message,
                  style: CartTypography.style(
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (onRetry != null)
                Semantics(
                  button: true,
                  label: 'إعادة المحاولة',
                  child: TextButton(
                    onPressed: onRetry,
                    child: Text(
                      'إعادة المحاولة',
                      style: CartTypography.style(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: CheckoutTokens.dangerText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutNoticeBanner extends StatelessWidget {
  const CheckoutNoticeBanner({
    super.key,
    required this.message,
    required this.palette,
  });

  final String message;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(CheckoutTokens.radiusXl - 6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              const Icon(Icons.sync_rounded, color: AppColors.success),
              const SizedBox(width: CheckoutTokens.spaceMd - 1),
              Expanded(
                child: Text(
                  message,
                  style: CartTypography.style(
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
