import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/utils/phone_launcher.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/screens/home/widgets/order_timeline.dart';
import 'package:url_launcher/url_launcher.dart';

/// ETA + distance hero card below the map.
class TrackingEtaCard extends StatelessWidget {
  const TrackingEtaCard({
    super.key,
    required this.snapshot,
    required this.palette,
    required this.order,
  });

  final OrderTrackingSnapshot snapshot;
  final AppPalette palette;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final delivered = order.status == OrderStatus.delivered;
    final cancelled = order.status == OrderStatus.cancelled;
    final ready = order.status == OrderStatus.readyForPickup;
    final pending = order.status == OrderStatus.pending;
    final preparing = order.status == OrderStatus.preparing;
    final onTheWay = order.status == OrderStatus.onTheWay;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.isDark
              ? [const Color(0xFF1a2838), palette.card]
              : [AppColors.white, AppColors.accentMuted],
        ),
        borderRadius: HomeTheme.borderLg,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: palette.isDark ? 0.35 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: palette.isDark ? 0.12 : 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          ...HomeTheme.softShadow(palette),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivered
                      ? 'تم التوصيل'
                      : cancelled
                          ? '—'
                          : ready
                              ? '📍 الاستلام'
                              : pending
                                  ? 'حالة الطلب'
                                  : preparing
                                      ? '⏱ الوقت المتوقع للتوصيل'
                                      : onTheWay
                                          ? '⏱ الوقت المتبقي'
                                          : '⏱ الوقت المتوقع',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  delivered
                      ? 'بالهناء والشفاء 🎉'
                      : cancelled
                          ? 'الطلب ملغي'
                          : ready
                              ? 'جاهز من المتجر'
                              : pending
                                  ? 'بانتظار قبول المتجر'
                                  : preparing
                                      ? '~${snapshot.etaMinutes} دقيقة'
                                      : onTheWay
                                          ? snapshot.usesLiveDriverGps
                                              ? '${snapshot.etaMinutes} دقيقة متبقية'
                                              : '~${snapshot.etaMinutes} دقيقة (تقدير)'
                                          : '${snapshot.etaMinutes} دقيقة',
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: delivered ? AppColors.success : AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: palette.border,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending || preparing
                      ? '📏 مسافة التوصيل (تقريبية)'
                      : onTheWay && !snapshot.usesLiveDriverGps
                          ? '📏 المسافة (تقدير)'
                          : '📏 المسافة المتبقية',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  delivered || ready
                      ? '0 كم'
                      : '${snapshot.distanceKm.toStringAsFixed(1)} كم',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
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

/// Dynamic live status banner.
class TrackingStatusBanner extends StatelessWidget {
  const TrackingStatusBanner({
    super.key,
    required this.message,
    required this.palette,
    required this.status,
  });

  final String message;
  final AppPalette palette;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final accent = status.color;
    return AnimatedContainer(
      duration: HomeTheme.animStandard,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: palette.isDark ? 0.2 : 0.1),
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium vertical timeline for tracking screen.
class TrackingPremiumTimeline extends StatelessWidget {
  const TrackingPremiumTimeline({
    super.key,
    required this.status,
    required this.palette,
  });

  final OrderStatus status;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: palette.border),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مسار الطلب',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          OrderProgressTimeline(status: status, palette: palette),
        ],
      ),
    );
  }
}

/// Driver card when order is out for delivery or delivered.
class TrackingDriverCard extends StatelessWidget {
  const TrackingDriverCard({
    super.key,
    required this.driver,
    required this.palette,
    required this.onCall,
    required this.onMessage,
  });

  final TrackingDriverInfo driver;
  final AppPalette palette;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: palette.border),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مندوب التوصيل',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  driver.name.isNotEmpty ? driver.name[0] : 'م',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (driver.vehicleLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        driver.vehicleLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                    if (driver.rating > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '⭐ ${driver.rating.toStringAsFixed(1)}'
                        '${driver.ratingCount > 0 ? ' (${driver.ratingCount})' : ''}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DriverActionButton(
                  label: 'اتصال',
                  icon: Icons.phone_rounded,
                  onTap: driver.phone.trim().length >= 10 ? onCall : () {},
                  filled: true,
                  enabled: driver.phone.trim().length >= 10,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DriverActionButton(
                  label: 'مراسلة',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: driver.phone.trim().length >= 10 ? onMessage : () {},
                  filled: false,
                  enabled: driver.phone.trim().length >= 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverActionButton extends StatefulWidget {
  const _DriverActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  @override
  State<_DriverActionButton> createState() => _DriverActionButtonState();
}

class _DriverActionButtonState extends State<_DriverActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: Listener(
      onPointerDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: HomeTheme.animPress,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: HomeTheme.borderSm,
            child: Ink(
              decoration: BoxDecoration(
                color: widget.filled
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: HomeTheme.borderSm,
                border: widget.filled
                    ? null
                    : Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.filled ? AppColors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: widget.filled ? AppColors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Compact order summary.
class TrackingOrderSummaryCard extends StatelessWidget {
  const TrackingOrderSummaryCard({
    super.key,
    required this.order,
    required this.palette,
    required this.formatDate,
    required this.paymentLabel,
  });

  final Order order;
  final AppPalette palette;
  final String Function(DateTime) formatDate;
  final String paymentLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: palette.border),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الطلب',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            palette: palette,
            icon: Icons.storefront_rounded,
            label: 'المتجر',
            value: order.storeName,
          ),
          _SummaryRow(
            palette: palette,
            icon: Icons.tag_rounded,
            label: 'رقم الطلب',
            value: '#${_shortId(order.id)}',
          ),
          _SummaryRow(
            palette: palette,
            icon: Icons.shopping_bag_outlined,
            label: 'المنتجات',
            value: '${order.itemCount} منتجات · ${order.itemsSummary}',
            maxLines: 2,
          ),
          _SummaryRow(
            palette: palette,
            icon: Icons.payments_outlined,
            label: 'الإجمالي',
            value: '${order.grandTotal.toStringAsFixed(0)} ج.م',
            valueColor: AppColors.primary,
          ),
          _SummaryRow(
            palette: palette,
            icon: Icons.schedule_rounded,
            label: 'وقت الطلب',
            value: formatDate(order.createdAt),
          ),
          _SummaryRow(
            palette: palette,
            icon: Icons.account_balance_wallet_outlined,
            label: 'طريقة الدفع',
            value: paymentLabel,
          ),
          if (order.address != null && order.address!.trim().isNotEmpty)
            _SummaryRow(
              palette: palette,
              icon: Icons.location_on_outlined,
              label: 'عنوان التوصيل',
              value: order.address!.trim(),
              maxLines: 3,
            ),
        ],
      ),
    );
  }

  static String _shortId(String id) =>
      id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines = 1,
  });

  final AppPalette palette;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: palette.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? palette.textPrimary,
                    height: 1.35,
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

enum TrackingBottomActionMode {
  beforeDispatch,
  onTheWay,
  delivered,
  cancelled,
}

/// Sticky bottom actions bar.
class TrackingBottomBar extends StatelessWidget {
  const TrackingBottomBar({
    super.key,
    required this.mode,
    required this.palette,
    required this.onPrimary,
    this.onSecondary,
    this.driverPhone,
  });

  final TrackingBottomActionMode mode;
  final AppPalette palette;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final String? driverPhone;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: palette.isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: _buildActions(context),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return switch (mode) {
      TrackingBottomActionMode.beforeDispatch => _TrackingActionButton(
          label: 'إلغاء الطلب',
          icon: Icons.cancel_outlined,
          destructive: true,
          onTap: onPrimary,
        ),
      TrackingBottomActionMode.onTheWay => Row(
          children: [
            Expanded(
              child: _TrackingActionButton(
                label: 'اتصال بالمندوب',
                icon: Icons.phone_rounded,
                onTap: onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrackingActionButton(
                label: 'مراسلة المندوب',
                icon: Icons.chat_outlined,
                outlined: true,
                onTap: onSecondary ?? onPrimary,
              ),
            ),
          ],
        ),
      TrackingBottomActionMode.delivered => _TrackingActionButton(
          label: 'إعادة الطلب',
          icon: Icons.replay_rounded,
          onTap: onPrimary,
        ),
      TrackingBottomActionMode.cancelled => _TrackingActionButton(
          label: 'العودة للطلبات',
          icon: Icons.arrow_back_rounded,
          outlined: true,
          onTap: onPrimary,
        ),
    };
  }
}

class _TrackingActionButton extends StatefulWidget {
  const _TrackingActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  final bool outlined;

  @override
  State<_TrackingActionButton> createState() => _TrackingActionButtonState();
}

class _TrackingActionButtonState extends State<_TrackingActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.destructive
        ? AppColors.error.withValues(alpha: 0.1)
        : widget.outlined
            ? Colors.transparent
            : AppColors.primary;
    final fg = widget.destructive
        ? AppColors.error
        : widget.outlined
            ? AppColors.primary
            : AppColors.white;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: HomeTheme.animPress,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: HomeTheme.borderMd,
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: HomeTheme.borderMd,
                border: widget.outlined || widget.destructive
                    ? Border.all(
                        color: widget.destructive
                            ? AppColors.error.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.4),
                      )
                    : null,
                boxShadow: widget.outlined || widget.destructive
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> trackingCallDriver(String phone) async {
  HapticFeedback.lightImpact();
  final ok = await launchPhoneCall(phone);
  if (!ok) {
    // ignore: avoid_print
    debugPrint('Could not launch phone: $phone');
  }
}

Future<void> trackingMessageDriver(String phone) async {
  HapticFeedback.lightImpact();
  final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final uri = Uri.parse('sms:$normalized');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
