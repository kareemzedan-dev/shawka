import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_operations_service.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_stat_card.dart';
import 'package:matlobgo/admin/widgets/cash_exposure_dashboard.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/order_repository.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminOperationsPanel extends StatefulWidget {
  const AdminOperationsPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  State<AdminOperationsPanel> createState() => _AdminOperationsPanelState();
}

class _AdminOperationsPanelState extends State<AdminOperationsPanel> {
  final _orderRepo = OrderRepository();
  final _userRepo = UserRepository();
  Timer? _refreshTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _lastUpdated = DateTime.now());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _mins(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} د';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _orderRepo.watchOrdersByGovernorate(
        governorate: widget.governorate.name,
      ),
      builder: (context, orderSnap) {
        final orders = orderSnap.data ?? [];
        return StreamBuilder(
          stream: _userRepo.watchDeliveryAgents(
            governorate: widget.governorate.name,
          ),
          builder: (context, driverSnap) {
            final drivers = driverSnap.data ?? [];
            final ops = AdminOperationsService.compute(
              orders: orders,
              drivers: drivers,
              governorateFilter: widget.governorate.name,
            );
            final watchdog = AdminOperationsService.computeWatchdog(
              orders: orders,
              drivers: drivers,
              governorateFilter: widget.governorate.name,
            );
            if (_lastUpdated == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _lastUpdated = ops.computedAt);
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPanelHeader(
                    title: 'مركز العمليات',
                    subtitle:
                        '${widget.governorate.name} — مراقبة التخصيص والتوصيل والـ SLA',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'آخر تحديث: ${_formatTime(_lastUpdated ?? ops.computedAt)}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ops.warnings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...ops.warnings.map(_WarningBanner.new),
                  ],
                  const SizedBox(height: 20),
                  CashExposureDashboard(drivers: drivers),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      AdminStatCard(
                        label: 'بانتظار تخصيص',
                        value: '${ops.pendingAssignment}',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                      ),
                      AdminStatCard(
                        label: 'عروض معلّقة',
                        value: '${ops.offered}',
                        icon: Icons.local_offer_rounded,
                        color: AppColors.primary,
                      ),
                      AdminStatCard(
                        label: 'توصيلات نشطة',
                        value: '${ops.active}',
                        icon: Icons.delivery_dining_rounded,
                        color: AppColors.info,
                      ),
                      AdminStatCard(
                        label: 'تم التسليم اليوم',
                        value: '${ops.deliveredToday}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      AdminStatCard(
                        label: 'تخصيص فاشل',
                        value: '${ops.failedAssignments}',
                        icon: Icons.error_outline_rounded,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'المندوبون',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      AdminStatCard(
                        label: 'Online',
                        value: '${ops.driversOnline}',
                        icon: Icons.wifi_rounded,
                        color: AppColors.success,
                      ),
                      AdminStatCard(
                        label: 'Offline',
                        value: '${ops.driversOffline}',
                        icon: Icons.wifi_off_rounded,
                        color: AppColors.textSecondary,
                      ),
                      AdminStatCard(
                        label: 'بدون GPS',
                        value: '${ops.driversWithoutGps}',
                        icon: Icons.location_off_rounded,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'مؤشرات الأداء',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      AdminStatCard(
                        label: 'متوسط قبول العرض',
                        value: _mins(ops.avgAcceptanceMinutes),
                        icon: Icons.timer_rounded,
                        color: AppColors.navy,
                      ),
                      AdminStatCard(
                        label: 'متوسط وقت التوصيل',
                        value: _mins(ops.avgDeliveryMinutes),
                        icon: Icons.route_rounded,
                        color: AppColors.navy,
                      ),
                      AdminStatCard(
                        label: 'متوسط Fulfillment',
                        value: _mins(ops.avgFulfillmentMinutes),
                        icon: Icons.timeline_rounded,
                        color: AppColors.navy,
                      ),
                      AdminStatCard(
                        label: 'SLA Success',
                        value: '${ops.slaSuccessRate.toStringAsFixed(0)}%',
                        icon: Icons.verified_rounded,
                        color: AppColors.success,
                      ),
                      AdminStatCard(
                        label: 'SLA Failure',
                        value: '${ops.slaFailureRate.toStringAsFixed(0)}%',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  if (ops.activeByGovernorate.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'توصيلات نشطة حسب المحافظة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ...ops.activeByGovernorate.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(e.key, style: GoogleFonts.cairo()),
                            ),
                            Text(
                              '${e.value}',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (drivers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Driver Watchdog',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (watchdog.isEmpty)
                      Text(
                        'لا يوجد مندوبون متوقفون حالياً',
                        style: GoogleFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      )
                    else
                      ...watchdog.take(8).map(
                            (w) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    w.severity == OpsWarningSeverity.critical
                                        ? Icons.error_rounded
                                        : Icons.warning_amber_rounded,
                                    size: 16,
                                    color: w.severity ==
                                            OpsWarningSeverity.critical
                                        ? AppColors.error
                                        : AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${w.driverName} · ${w.idleMinutes} د · ${w.storeName}',
                                      style: GoogleFonts.cairo(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '#${w.orderId.substring(0, 6)}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                  if (drivers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'أفضل المندوبين',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._topDrivers(drivers).map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.name.isEmpty ? 'مندوب' : d.name,
                                style: GoogleFonts.cairo(fontSize: 13),
                              ),
                            ),
                            if (d.driverPerformanceScore != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${d.driverPerformanceScore}',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            if (d.avgDriverRating > 0) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.warning),
                              Text(
                                d.avgDriverRating.toStringAsFixed(1),
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static List<AppUser> _topDrivers(List<AppUser> drivers) {
    final sorted = [...drivers]
      ..sort((a, b) {
        final sa = a.driverPerformanceScore ?? 0;
        final sb = b.driverPerformanceScore ?? 0;
        if (sb != sa) return sb.compareTo(sa);
        return b.avgDriverRating.compareTo(a.avgDriverRating);
      });
    return sorted.take(5).toList();
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner(this.warning);

  final OpsWarning warning;

  @override
  Widget build(BuildContext context) {
    final color = switch (warning.severity) {
      OpsWarningSeverity.critical => AppColors.error,
      OpsWarningSeverity.warning => AppColors.warning,
      OpsWarningSeverity.info => AppColors.navy,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning.message,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
