import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

class CartFreeDeliveryCard extends StatelessWidget {
  const CartFreeDeliveryCard({
    super.key,
    required this.title,
    required this.body,
    required this.progress,
    required this.unlocked,
  });

  final String title;
  final String body;
  final double progress;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Semantics(
      container: true,
      label: unlocked
          ? '$title. $body. التقدم مكتمل'
          : '$title. $body. التقدم ${(clamped * 100).round()} بالمئة',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: CartTokens.pagePadding),
        padding: const EdgeInsets.fromLTRB(
          CartTokens.spaceXl,
          CartTokens.spaceLg,
          CartTokens.spaceXl,
          CartTokens.spaceLg,
        ),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(CartTokens.radiusXl),
          border: Border.all(color: context.palette.border),
          boxShadow: CartTokens.freeCardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          title,
                          style: CartTypography.style(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: CartTokens.spaceXs),
                      ExcludeSemantics(
                        child: Text.rich(
                          TextSpan(
                            style: CartTypography.style(
                              fontSize: CartTokens.captionSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            children: _bodySpans(body),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CartTokens.spaceMd),
                ExcludeSemantics(
                  child: Icon(
                    unlocked
                        ? Icons.celebration_rounded
                        : Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                    size: CartTokens.freeIcon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CartTokens.spaceLg),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CartTokens.radiusPill),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clamped),
                  duration: CartTokens.motionProgress,
                  curve: CartTokens.curveStandard,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: CartTokens.progressHeight,
                      backgroundColor: CartTokens.progressTrack,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _bodySpans(String text) {
    final match = RegExp(r'(\d+(?:\.\d+)?\s*ج\.م)').firstMatch(text);
    if (match == null) return [TextSpan(text: text)];
    final start = match.start;
    final end = match.end;
    return [
      if (start > 0) TextSpan(text: text.substring(0, start)),
      TextSpan(
        text: text.substring(start, end),
        style: CartTypography.style(
          color: CartTokens.accentText,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (end < text.length) TextSpan(text: text.substring(end)),
    ];
  }
}
