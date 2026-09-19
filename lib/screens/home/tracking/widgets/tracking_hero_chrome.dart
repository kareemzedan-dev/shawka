import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/tracking_tokens.dart';

class TrackingBackButton extends StatelessWidget {
  const TrackingBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'رجوع',
      child: Container(
        width: TrackingTokens.backButton,
        height: TrackingTokens.backButton,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: TrackingTokens.floatingShadow,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: TrackingTokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class TrackingLiveBadge extends StatefulWidget {
  const TrackingLiveBadge({super.key, this.active = true});

  final bool active;

  @override
  State<TrackingLiveBadge> createState() => _TrackingLiveBadgeState();
}

/// هيرو عائم فوق الخريطة — عنوان التتبع + اسم المتجر.
class TrackingMapHero extends StatelessWidget {
  const TrackingMapHero({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TrackingTokens.navy.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: TrackingTokens.floatingShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CartTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CartTypography.style(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.2,
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

class _TrackingLiveBadgeState extends State<TrackingLiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TrackingTokens.radiusPill),
        boxShadow: TrackingTokens.floatingShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.active
                    ? TrackingTokens.live
                    : TrackingTokens.textMuted,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.active ? 'المندوب في الطريق' : 'بانتظار التتبع',
            style: CartTypography.style(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: TrackingTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
