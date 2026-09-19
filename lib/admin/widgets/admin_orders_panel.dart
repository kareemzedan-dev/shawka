import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/utils/admin_csv_export.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/repositories/order_repository.dart';

class AdminOrdersPanel extends StatefulWidget {
  const AdminOrdersPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  State<AdminOrdersPanel> createState() => _AdminOrdersPanelState();
}

class _AdminOrdersPanelState extends State<AdminOrdersPanel> {
  final _repo = OrderRepository();
  OrderStatus? _filter;

  Stream<List<Order>> _ordersStream() {
    final session = AdminSession.instance;
    if (session.isStoreScoped) {
      return _repo.watchOrdersByStoreIds(
        storeIds: session.managedStoreIds,
        status: _filter,
      );
    }
    return _repo.watchOrdersByGovernorate(
      governorate: widget.governorate.name,
      status: _filter,
    );
  }

  Future<void> _exportOrdersCsv(BuildContext context, List<Order> orders) async {
    final csv = AdminCsvExport.build(
      headers: [
        'id',
        'createdAt',
        'status',
        'storeName',
        'customerName',
        'total',
        'itemCount',
        'governorate',
      ],
      rows: orders.map((o) {
        return [
          o.id,
          AdminFormat.dateTime(o.createdAt),
          o.status.label,
          o.storeName,
          o.customerName,
          o.total.toStringAsFixed(2),
          o.itemCount.toString(),
          o.governorate,
        ];
      }).toList(),
    );
    await AdminCsvExport.share(
      context,
      filename: 'orders_${widget.governorate.id}.csv',
      csv: csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: AdminSession.instance.isStoreScoped
              ? 'طلبات متجري'
              : 'الطلبات',
          subtitle: AdminSession.instance.isStoreScoped
              ? 'متابعة طلبات متجرك فقط'
              : '${widget.governorate.name} — متابعة وتحديث حالة الطلبات',
          trailing: StreamBuilder<List<Order>>(
            stream: _ordersStream(),
            builder: (context, snap) {
              final orders = snap.data ?? [];
              return OutlinedButton.icon(
                onPressed: orders.isEmpty
                    ? null
                    : () => _exportOrdersCsv(context, orders),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('تصدير CSV', style: GoogleFonts.cairo()),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _StatusFilterBar(
          selected: _filter,
          onSelected: (s) => setState(() => _filter = s),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Order>>(
            stream: _ordersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    FirestoreErrorMessage.from(snapshot.error!),
                    style: GoogleFonts.cairo(color: AppColors.error),
                  ),
                );
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: AdminSession.instance.isStoreScoped
                      ? 'لا توجد طلبات لمتجرك حالياً.'
                      : 'لا توجد طلبات في هذه المحافظة.\nستظهر هنا عند إنشاء العملاء لطلبات جديدة.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _OrderCard(
                  order: orders[i],
                  onTap: () => _openOrderSheet(context, orders[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openOrderSheet(BuildContext context, Order order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderDetailSheet(
        order: order,
        onUpdated: () => Navigator.pop(ctx),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onSelected});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _Chip(
            label: 'الكل',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...OrderStatus.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: s.label,
                selected: selected == s,
                color: s.color,
                onTap: () => onSelected(s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.navy;
    return FilterChip(
      label: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.withValues(alpha: 0.15),
      checkmarkColor: c,
      labelStyle: GoogleFonts.cairo(
        color: selected ? c : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(order.status.icon, color: order.status.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.storeName,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.itemsSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AdminFormat.currency(order.grandTotal)} · ${order.itemCount} صنف · ${AdminFormat.relative(order.createdAt)}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  const _OrderDetailSheet({
    required this.order,
    required this.onUpdated,
  });

  final Order order;
  final VoidCallback onUpdated;

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  final _orderRepo = OrderRepository();
  late Order _order;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _setStatus(OrderStatus status) async {
    if (!_order.status.canAdminTransitionTo(status)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن الانتقال من ${_order.status.label} إلى ${status.label}',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
      return;
    }
    setState(() => _busy = true);
    final prevStatus = _order.status;
    try {
      await _orderRepo.updateStatus(_order.id, status);
      setState(() => _order = _order.copyWith(status: status));
      await AdminAuditRecord.fields(
        action: AuditAction.statusChange,
        entityType: 'order',
        entityId: _order.id,
        summary:
            'تغيير حالة الطلب #${_order.id.substring(_order.id.length.clamp(0, 8))} من ${prevStatus.label} إلى ${status.label}',
        before: {'status': prevStatus.firestoreValue},
        after: {'status': status.firestoreValue},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث الحالة إلى ${status.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scroll) => Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'طلب #${_order.id.length > 8 ? _order.id.substring(0, 8) : _order.id}',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _order.storeName,
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _InfoRow('العميل', _order.customerName.isEmpty ? '—' : _order.customerName),
              _InfoRow('الهاتف', _order.phone ?? '—'),
              _InfoRow('العنوان', _order.address ?? '—'),
              _InfoRow('الأصناف', _order.itemsSummary),
              _InfoRow('رسوم التوصيل', AdminFormat.currency(_order.deliveryFee)),
              _InfoRow('الإجمالي', AdminFormat.currency(_order.grandTotal)),
              _InfoRow('التاريخ', AdminFormat.dateTime(_order.createdAt)),
              const Divider(height: 32),
              Text(
                'تحديث الحالة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'مسار الطلب من اللوحة: قيد المراجعة → جاري التحضير → جاهز للتوصيل → خرج للتوصيل → تم التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'يمكنك اختيار أي حالة تالية مباشرة — بدون تطبيق سائق',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_order.status.suggestedAdminNextStep != null)
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _setStatus(_order.status.suggestedAdminNextStep!),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        _order.status.suggestedAdminNextStepLabel,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (_order.status.canAdminTransitionTo(OrderStatus.cancelled) &&
                      _order.status != OrderStatus.cancelled)
                    OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _setStatus(OrderStatus.cancelled),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        'إلغاء الطلب',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OrderStatus.values.map((s) {
                  final allowed = _order.status.canAdminTransitionTo(s);
                  return ChoiceChip(
                    label: Text(s.label, style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _order.status == s,
                    onSelected: (!_busy && allowed && _order.status != s)
                        ? (_) => _setStatus(s)
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onUpdated,
                  child: Text(
                    'إغلاق',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
