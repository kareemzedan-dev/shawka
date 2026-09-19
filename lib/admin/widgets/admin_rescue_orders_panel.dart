import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_rescue_actions_service.dart';
import 'package:matlobgo/admin/services/admin_rescue_service.dart';
import 'package:matlobgo/admin/services/ops_incident_repository.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_stat_card.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/order_repository.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminRescueOrdersPanel extends StatefulWidget {
  const AdminRescueOrdersPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  State<AdminRescueOrdersPanel> createState() => _AdminRescueOrdersPanelState();
}

class _AdminRescueOrdersPanelState extends State<AdminRescueOrdersPanel> {
  final _orderRepo = OrderRepository();
  final _incidentRepo = OpsIncidentRepository();
  final _userRepo = UserRepository();
  final _actions = AdminRescueActionsService();

  RescueFailureType? _typeFilter;
  int? _maxAgeMinutes;
  String? _busyOrderId;

  Future<void> _run(String orderId, Future<void> Function() action) async {
    setState(() => _busyOrderId = orderId);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تنفيذ الإجراء', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FirestoreErrorMessage.from(e), style: GoogleFonts.cairo()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _manualAssign(RescueOrderItem item) async {
    final agents = await _userRepo
        .watchDeliveryAgents(governorate: widget.governorate.name)
        .first;
    if (!mounted) return;
    final online = agents
        .where((d) => d.isActive && d.isDriverOnlineEffective && !d.isOnOfferCooldown)
        .toList();
    if (online.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يوجد مندوبون متاحون', style: GoogleFonts.cairo()),
        ),
      );
      return;
    }

    final picked = await showDialog<AppUser>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('اختر مندوباً', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        children: online
            .map(
              (d) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, d),
                child: Text(d.name.isEmpty ? d.uid : d.name, style: GoogleFonts.cairo()),
              ),
            )
            .toList(),
      ),
    );
    if (picked == null) return;

    await _run(
      item.order.id,
      () => _actions.assignManually(orderId: item.order.id, driverId: picked.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _orderRepo.watchOrdersByGovernorate(
        governorate: widget.governorate.name,
      ),
      builder: (context, orderSnap) {
        final orders = orderSnap.data ?? [];
        return StreamBuilder<List<OpsIncident>>(
          stream: _incidentRepo.watchRecent(limit: 100),
          builder: (context, incSnap) {
            final incidents = incSnap.data ?? [];
            final queue = AdminRescueService.buildQueue(
              orders: orders,
              incidents: incidents,
              governorateFilter: widget.governorate.name,
              typeFilter: _typeFilter,
              maxAgeMinutes: _maxAgeMinutes,
            );
            final kpis = AdminRescueService.computeKpis(
              queue: queue,
              incidents: incidents,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: AdminPanelHeader(
                    title: 'Rescue Orders',
                    subtitle:
                        '${widget.governorate.name} — طلبات تحتاج تدخل تشغيلي',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      AdminStatCard(
                        label: 'Rescue Queue',
                        value: '${kpis.queueCount}',
                        icon: Icons.sos_rounded,
                        color: AppColors.error,
                      ),
                      AdminStatCard(
                        label: 'Avg Rescue Time',
                        value: kpis.avgRescueMinutes == null
                            ? '—'
                            : '${kpis.avgRescueMinutes!.toStringAsFixed(0)} د',
                        icon: Icons.timer_rounded,
                        color: AppColors.navy,
                      ),
                      AdminStatCard(
                        label: 'Resolved Today',
                        value: '${kpis.resolvedToday}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text('الكل', style: GoogleFonts.cairo()),
                        selected: _typeFilter == null,
                        onSelected: (_) => setState(() => _typeFilter = null),
                      ),
                      ...RescueFailureType.values.map(
                        (t) => FilterChip(
                          label: Text(t.label, style: GoogleFonts.cairo(fontSize: 11)),
                          selected: _typeFilter == t,
                          onSelected: (_) => setState(() => _typeFilter = t),
                        ),
                      ),
                      FilterChip(
                        label: Text('< 30 د', style: GoogleFonts.cairo()),
                        selected: _maxAgeMinutes == 30,
                        onSelected: (_) => setState(
                          () => _maxAgeMinutes = _maxAgeMinutes == 30 ? null : 30,
                        ),
                      ),
                      FilterChip(
                        label: Text('< 60 د', style: GoogleFonts.cairo()),
                        selected: _maxAgeMinutes == 60,
                        onSelected: (_) => setState(
                          () => _maxAgeMinutes = _maxAgeMinutes == 60 ? null : 60,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: queue.isEmpty
                      ? AdminEmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          message: 'لا توجد طلبات rescue حالياً',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          itemCount: queue.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final item = queue[i];
                            final busy = _busyOrderId == item.order.id;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '#${item.order.id.substring(0, 8)} · ${item.order.storeName}',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.type.label,
                                            style: GoogleFonts.cairo(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.order.customerName} · ${item.ageMinutes} د · ${item.order.governorate}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: busy
                                              ? null
                                              : () => _run(
                                                    item.order.id,
                                                    () => _actions.retryAssignment(
                                                      item.order.id,
                                                    ),
                                                  ),
                                          icon: busy
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(Icons.refresh, size: 18),
                                          label: Text(
                                            'Retry',
                                            style: GoogleFonts.cairo(),
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: busy
                                              ? null
                                              : () => _manualAssign(item),
                                          child: Text(
                                            'Manual Assign',
                                            style: GoogleFonts.cairo(),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: busy
                                              ? null
                                              : () => _run(
                                                    item.order.id,
                                                    () => _actions.cancelOrder(
                                                      item.order.id,
                                                    ),
                                                  ),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.cairo(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
