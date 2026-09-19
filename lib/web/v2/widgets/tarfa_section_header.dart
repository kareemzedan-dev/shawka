import 'package:flutter/material.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

class TarfaSectionHeader extends StatelessWidget {
  const TarfaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TarfaTokens.s24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TarfaTokens.headlineMedium(context)),
                if (subtitle != null) ...[
                  const SizedBox(height: TarfaTokens.s4),
                  Text(subtitle!, style: TarfaTokens.bodyMedium(context)),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TarfaTokens.labelLarge(context).copyWith(
                      color: TarfaTokens.secondary,
                    ),
                  ),
                  const SizedBox(width: TarfaTokens.s4),
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: TarfaTokens.secondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
