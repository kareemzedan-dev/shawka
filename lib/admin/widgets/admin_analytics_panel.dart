import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_analytics_service.dart';
import 'package:matlobgo/admin/services/admin_funnel_calculator.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_funnel_chart.dart';
import 'package:matlobgo/admin/widgets/admin_journey_sankey.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_stat_card.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/repositories/analytics_event_repository.dart';
import 'package:matlobgo/repositories/order_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminAnalyticsPanel extends StatelessWidget {
  const AdminAnalyticsPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  Widget build(BuildContext context) {
    final orderRepo = OrderRepository();
    final storeRepo = StoreRepository();
    final userRepo = UserRepository();
    final eventsRepo = AnalyticsEventRepository();
    final session = AdminSession.instance;
    final scoped = session.isStoreScoped;
    final managedIds = session.managedStoreIds;

    final ordersStream = scoped
        ? orderRepo.watchOrdersByStoreIds(storeIds: managedIds)
        : orderRepo.watchOrdersByGovernorate(governorate: governorate.name);

    return StreamBuilder<List<Order>>(
      stream: ordersStream,
      builder: (context, orderSnap) {
        final orders = orderSnap.data ?? [];
        return StreamBuilder<List<AnalyticsEvent>>(
          stream: eventsRepo.watchRecent(limit: 500),
          builder: (context, eventSnap) {
            final events = eventSnap.data ?? [];
            final funnel = AdminFunnelCalculator.computeFunnel(events);
            final sankey = AdminFunnelCalculator.computeSankeyFlows(events);
            final sessionStats =
                AdminFunnelCalculator.computeSessionStats(events);
            final checkoutStarts = events
                .where((e) => e.type == AnalyticsEventType.checkoutStart)
                .length;
            final orderPlaced = events
                .where((e) => e.type == AnalyticsEventType.orderPlaced)
                .length;

            return StreamBuilder(
              stream: storeRepo.watchStoresByGovernorate(
                governorate: governorate.name,
              ),
              builder: (context, storeSnap) {
                final allStores = storeSnap.data ?? [];
                final stores = session.filterStores(
                  allStores,
                  idOf: (s) => s.id,
                );
                final openStores =
                    stores.where((s) => s.isOpen && s.isActive).length;

                return StreamBuilder(
                  stream: userRepo.watchUsersByRole(UserRole.customer),
                  builder: (context, userSnap) {
                    final customers = scoped ? 0 : (userSnap.data?.length ?? 0);
                    final storeIds = stores.map((s) => s.id).toSet();
                    final govEvents = events
                        .where(
                          (e) =>
                              e.storeId.isEmpty ||
                              storeIds.contains(e.storeId),
                        )
                        .toList();
                    final snapshot = AdminAnalyticsCalculator.compute(
                      orders: orders,
                      customersCount: customers,
                      openStoresCount: openStores,
                      checkoutStarts: checkoutStarts,
                      orderPlacedEvents: orderPlaced,
                      events: govEvents,
                      governorateStoreIds: storeIds,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminPanelHeader(
                            title: scoped ? 'إيرادات متجري' : 'التحليلات',
                            subtitle: scoped
                                ? 'مؤشرات أداء وإيرادات متجرك فقط'
                                : '${governorate.name} — مؤشرات الأداء والإيرادات',
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              AdminStatCard(
                                label: 'الإيرادات',
                                value: AdminFormat.currency(snapshot.revenue),
                                icon: Icons.payments_rounded,
                                color: AppColors.success,
                              ),
                              AdminStatCard(
                                label: 'متوسط قيمة الطلب',
                                value: AdminFormat.currency(
                                  snapshot.averageOrderValue,
                                ),
                                icon: Icons.shopping_bag_rounded,
                                color: AppColors.primary,
                              ),
                              AdminStatCard(
                                label: 'معدل التحويل',
                                value:
                                    '${(snapshot.conversionRate * 100).toStringAsFixed(1)}%',
                                icon: Icons.trending_up_rounded,
                                color: AppColors.navy,
                              ),
                              AdminStatCard(
                                label: 'طلبات اليوم',
                                value: '${snapshot.ordersToday}',
                                icon: Icons.today_rounded,
                                color: AppColors.info,
                              ),
                              AdminStatCard(
                                label: 'طلبات الشهر',
                                value: '${snapshot.ordersThisMonth}',
                                icon: Icons.calendar_month_rounded,
                                color: AppColors.navy,
                              ),
                              AdminStatCard(
                                label: 'العملاء',
                                value: '${snapshot.customersCount}',
                                icon: Icons.people_rounded,
                                color: AppColors.primary,
                              ),
                              AdminStatCard(
                                label: 'متوسط الجلسة',
                                value: sessionStats.totalSessions == 0
                                    ? '—'
                                    : AdminFormat.durationSeconds(
                                        sessionStats.avgDurationSeconds.round(),
                                      ),
                                icon: Icons.timer_rounded,
                                color: AppColors.primaryDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'قمع التحويل — User Journey',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${sessionStats.totalSessions} جلسة · '
                            '${sessionStats.avgEventsPerSession.toStringAsFixed(1)} حدث/جلسة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: AdminFunnelChart(steps: funnel),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: AdminJourneySankey(flows: sankey),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'الإيرادات — آخر 7 أيام',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: LineChart(
                                  _buildRevenueChart(snapshot.revenueByDay),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _RankedListSection(
                            title: 'المتاجر الأكثر مبيعاً',
                            icon: Icons.storefront_rounded,
                            items: snapshot.topStores,
                            valueFormatter: AdminFormat.currency,
                          ),
                          const SizedBox(height: 20),
                          _RankedListSection(
                            title: 'المنتجات الأكثر طلباً',
                            icon: Icons.inventory_2_outlined,
                            items: snapshot.topProducts,
                            valueFormatter: (v) => '${v.toInt()} طلب',
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  LineChartData _buildRevenueChart(List<AdminDailyMetric> metrics) {
    final spots = <FlSpot>[];
    for (var i = 0; i < metrics.length; i++) {
      spots.add(FlSpot(i.toDouble(), metrics[i].value));
    }
    final maxY = metrics.fold<double>(
      0,
      (max, m) => m.value > max ? m.value : max,
    );

    return LineChartData(
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.border,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: GoogleFonts.cairo(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= metrics.length) return const SizedBox.shrink();
              return Text(
                '${metrics[i].day.day}/${metrics[i].day.month}',
                style: GoogleFonts.cairo(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: maxY <= 0 ? 100 : maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _RankedListSection extends StatelessWidget {
  const _RankedListSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.valueFormatter,
  });

  final String title;
  final IconData icon;
  final List<AdminRankedItem> items;
  final String Function(double value) valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'لا توجد بيانات كافية لـ $title بعد.',
            style: GoogleFonts.cairo(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accentMuted,
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              title: Text(
                item.label,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                valueFormatter(item.value),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
