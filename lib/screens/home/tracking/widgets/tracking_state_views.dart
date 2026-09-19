import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/tracking_tokens.dart';
import 'package:matlobgo/screens/home/tracking/tracking_controller.dart';

/// واجهات الحالات غير النشطة لشاشة التتبع.
class TrackingPhaseBanner extends StatelessWidget {
  const TrackingPhaseBanner({super.key, required this.phase});

  final TrackingUiPhase phase;

  @override
  Widget build(BuildContext context) {
    final text = switch (phase) {
      TrackingUiPhase.loading => 'جاري تحميل التتبع...',
      TrackingUiPhase.offline => 'اتصال ضعيف — قد تتأخر التحديثات',
      TrackingUiPhase.error => 'تعذّر تحميل بيانات التتبع',
      TrackingUiPhase.cancelled => 'تم إلغاء هذا الطلب',
      TrackingUiPhase.waitingDriver => 'بانتظار تعيين مندوب توصيل',
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: phase == TrackingUiPhase.cancelled ||
                phase == TrackingUiPhase.error
            ? TrackingTokens.accent.withValues(alpha: 0.08)
            : TrackingTokens.chatButton,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: CartTypography.style(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: TrackingTokens.textSecondary,
        ),
      ),
    );
  }
}

class TrackingLoadingSheet extends StatelessWidget {
  const TrackingLoadingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: TrackingTokens.accent),
      ),
    );
  }
}
