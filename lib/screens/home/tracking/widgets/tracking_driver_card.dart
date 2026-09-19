import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/tracking_tokens.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';

class TrackingDriverSheetCard extends StatelessWidget {
  const TrackingDriverSheetCard({
    super.key,
    required this.driver,
    required this.onCall,
    required this.onChat,
    this.waiting = false,
  });

  final TrackingDriverInfo? driver;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    if (waiting || driver == null || driver!.name.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TrackingTokens.cardRadius),
          border: Border.all(color: TrackingTokens.cardBorder),
          boxShadow: TrackingTokens.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: TrackingTokens.driverAvatar,
              height: TrackingTokens.driverAvatar,
              decoration: BoxDecoration(
                color: TrackingTokens.chatButton,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: TrackingTokens.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'جاري البحث عن مندوب توصيل...',
                style: CartTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TrackingTokens.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final d = driver!;
    final canContact = d.phone.trim().length >= 10;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TrackingTokens.cardRadius),
        border: Border.all(color: TrackingTokens.cardBorder),
        boxShadow: TrackingTokens.cardShadow,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: TrackingTokens.driverAvatar / 2,
                backgroundColor: TrackingTokens.accent.withValues(alpha: 0.12),
                child: Text(
                  d.name.isNotEmpty ? d.name[0] : 'م',
                  style: CartTypography.style(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TrackingTokens.accent,
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: TrackingTokens.verified,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CartTypography.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TrackingTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: TrackingTokens.verified,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (d.rating > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: TrackingTokens.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            d.rating.toStringAsFixed(1),
                            style: CartTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: TrackingTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      d.vehicleLabel.isNotEmpty
                          ? 'كابتن معتمد • '
                          : 'كابتن معتمد',
                      style: CartTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TrackingTokens.textSecondary,
                      ),
                    ),
                    if (d.vehicleLabel.isNotEmpty)
                      Text(
                        d.vehicleLabel,
                        style: CartTypography.style(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: TrackingTokens.accent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.phone_rounded,
            filled: true,
            enabled: canContact,
            onTap: onCall,
            semanticLabel: 'اتصال بالمندوب',
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: Icons.chat_bubble_outline_rounded,
            filled: false,
            enabled: canContact,
            onTap: onChat,
            semanticLabel: 'مراسلة المندوب',
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.filled,
    required this.enabled,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: filled ? TrackingTokens.callButton : TrackingTokens.chatButton,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 20,
                color: filled ? Colors.white : TrackingTokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
