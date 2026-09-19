import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/tracking_tokens.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/screens/home/tracking/tracking_controller.dart';

/// بطاقة ETA وفق تصميم SSOT.
class TrackingEtaSheetCard extends StatelessWidget {
  const TrackingEtaSheetCard({
    super.key,
    required this.order,
    required this.snapshot,
  });

  final Order order;
  final OrderTrackingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final eta = TrackingTimelineData.etaMinutesLabel(order, snapshot.etaMinutes);
    final arrivalMinutes = snapshot.etaMinutes > 0
        ? snapshot.etaMinutes
        : (order.etaMinutes > 0 ? order.etaMinutes : 0);
    final arrival = order.status == OrderStatus.delivered
        ? 'تم التسليم'
        : order.status == OrderStatus.cancelled
            ? '—'
            : TrackingTimelineData.etaArrivalLabel(arrivalMinutes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TrackingTokens.cardRadius),
        border: Border.all(
          color: snapshot.isLiveDeliveryMode
              ? TrackingTokens.accent.withValues(alpha: 0.45)
              : TrackingTokens.cardBorder,
          width: snapshot.isLiveDeliveryMode ? 1.5 : 1,
        ),
        boxShadow: TrackingTokens.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eta,
                  style: CartTypography.style(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: TrackingTokens.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: TrackingTokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        arrival,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CartTypography.style(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TrackingTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        TrackingTimelineData.statusTitle(order),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CartTypography.style(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: TrackingTokens.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      order.status == OrderStatus.onTheWay ||
                              snapshot.isLiveDeliveryMode
                          ? Icons.two_wheeler_rounded
                          : order.status == OrderStatus.readyForPickup
                              ? Icons.storefront_rounded
                              : order.status.icon,
                      size: 18,
                      color: TrackingTokens.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TrackingTimelineData.statusSubtitle(order),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CartTypography.style(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TrackingTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
