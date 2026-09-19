import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';

class CartHeader extends StatelessWidget {
  const CartHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.compact = false,
    /// مساحة إضافية أسفل النص لاستقبال تداخل بطاقة التوصيل المجاني.
    this.bottomExtra = 0,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool compact;
  final double bottomExtra;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final titleSize = compact ? 20.0 : CartTokens.titleSize;
    final subtitleSize = compact ? 12.0 : 13.0;
    final bottomPad =
        (compact ? 18.0 : CartTokens.headerBottom) + bottomExtra;
    final backSize = compact ? 38.0 : CartTokens.backButton;

    return Semantics(
      container: true,
      header: true,
      label: '$title. $subtitle',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          CartTokens.headerHorizontal,
          top + (compact ? CartTokens.spaceMd : CartTokens.spaceLg),
          CartTokens.headerHorizontal,
          bottomPad,
        ),
        decoration: const BoxDecoration(color: AppColors.navy),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      title,
                      style: CartTypography.style(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: CartTokens.spaceXs),
                  ExcludeSemantics(
                    child: Text(
                      subtitle,
                      style: CartTypography.style(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onBack != null)
              Semantics(
                button: true,
                label: 'رجوع',
                child: Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onBack!();
                    },
                    child: SizedBox(
                      width: backSize,
                      height: backSize,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: compact ? 14 : 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
