import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_customer_review_service.dart';
import 'package:matlobgo/admin/services/admin_funnel_calculator.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/admin_csv_export.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_funnel_chart.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_registration_requests_panel.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/egyptian_phone.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/repositories/analytics_event_repository.dart';
import 'package:matlobgo/repositories/order_repository.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminCustomersPanel extends StatefulWidget {
  const AdminCustomersPanel({
    super.key,
    required this.governorate,
    this.onOpenRegistrationRequests,
    this.initialTab = 0,
  });

  final Governorate governorate;
  final VoidCallback? onOpenRegistrationRequests;
  /// 0 = العملاء، 1 = طلبات التسجيل
  final int initialTab;

  @override
  State<AdminCustomersPanel> createState() => _AdminCustomersPanelState();
}

class _AdminCustomersPanelState extends State<AdminCustomersPanel>
    with SingleTickerProviderStateMixin {
  final _repo = UserRepository();
  final _orderRepo = OrderRepository();
  final _review = AdminCustomerReviewService();
  final _search = TextEditingController();
  String _query = '';
  final _deletingIds = <String>{};
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _exportCustomersCsv(
    BuildContext context,
    List<AppUser> users,
  ) async {
    final csv = AdminCsvExport.build(
      headers: [
        'uid',
        'name',
        'phone',
        'activityType',
        'email',
        'governorate',
        'createdAt',
      ],
      rows: users.map((u) {
        return [
          u.uid,
          u.name,
          u.phone,
          u.activityTypeName,
          u.email,
          u.governorate,
          u.createdAt.toIso8601String(),
        ];
      }).toList(),
    );
    await AdminCsvExport.share(
      context,
      filename: 'customers_${widget.governorate.id}.csv',
      csv: csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'العملاء',
          subtitle: 'إدارة العملاء وطلبات التسجيل الجديدة',
          trailing: ListenableBuilder(
            listenable: _tabs,
            builder: (context, _) {
              if (_tabs.index != 0) return const SizedBox.shrink();
              return StreamBuilder<List<AppUser>>(
                stream: _repo.watchUsersByRole(UserRole.customer),
                builder: (context, snap) {
                  final users = snap.data ?? [];
                  return OutlinedButton.icon(
                    onPressed: users.isEmpty
                        ? null
                        : () => _exportCustomersCsv(context, users),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('CSV', style: GoogleFonts.cairo()),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: StreamBuilder<List<AppUser>>(
            stream: _repo.watchUsersByRole(UserRole.customer),
            builder: (context, snap) {
              final pendingCount = (snap.data ?? [])
                  .where((u) => u.isCustomerPendingApproval)
                  .length;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                  unselectedLabelStyle:
                      GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  tabs: [
                    const Tab(text: 'كل العملاء'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('طلبات التسجيل', style: GoogleFonts.cairo()),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$pendingCount',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildCustomersTab(),
              const AdminRegistrationRequestsPanel(embedded: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو البريد أو الهاتف...',
              hintStyle: GoogleFonts.cairo(),
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _repo.watchUsersByRole(UserRole.customer),
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
              var users = (snapshot.data ?? [])
                  .where((u) => !u.isCustomerPendingApproval)
                  .toList();
              if (_query.isNotEmpty) {
                users = users
                    .where(
                      (u) =>
                          u.name.toLowerCase().contains(_query) ||
                          u.email.toLowerCase().contains(_query) ||
                          u.phone.contains(_query) ||
                          u.activityTypeName.toLowerCase().contains(_query),
                    )
                    .toList();
              }
              if (users.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.people_outline_rounded,
                  message: _query.isEmpty
                      ? 'لا يوجد عملاء مسجّلون بعد.'
                      : 'لا توجد نتائج للبحث «$_query».',
                );
              }
              return StreamBuilder<List<Order>>(
                stream: _orderRepo.watchOrdersByGovernorate(
                  governorate: widget.governorate.name,
                ),
                builder: (context, orderSnap) {
                  final allOrders = orderSnap.data ?? [];
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final user = users[i];
                      final userOrders = allOrders
                          .where((o) => o.customerId == user.uid)
                          .toList();
                      final spent = userOrders
                          .where((o) => o.status == OrderStatus.delivered)
                          .fold<double>(0, (s, o) => s + o.grandTotal);
                      return _CustomerCard(
                        user: user,
                        orderCount: userOrders.length,
                        totalSpent: spent,
                        lastActivity: user.lastActiveAt ?? user.createdAt,
                        isOnline: user.isOnline,
                        deleting: _deletingIds.contains(user.uid),
                        onTap: () => _openCrmSheet(context, user, userOrders),
                        onDelete: () => _deleteCustomer(user),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  Future<void> _deleteCustomer(AppUser user) async {
    final label = user.name.isNotEmpty
        ? user.name
        : (user.phone.isNotEmpty
            ? EgyptianPhone.toLocalDisplay(user.phone)
            : user.email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف حساب العميل؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيتم حذف حساب «$label» نهائياً من التطبيق (الملف + تسجيل الدخول + صور الإثبات). لا يمكن التراجع.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف نهائي', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deletingIds.add(user.uid));
    try {
      await _review.deleteCustomer(user.uid);
      await AdminSession.instance.record(
        action: AuditAction.delete,
        entityType: 'user',
        entityId: user.uid,
        summary: 'حذف حساب عميل: $label',
        metadata: {
          if (user.phone.isNotEmpty) 'phone': user.phone,
          if (user.email.isNotEmpty) 'email': user.email,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف حساب العميل',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirestoreErrorMessage.from(e),
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(user.uid));
    }
  }

  Future<void> _openCrmSheet(
    BuildContext context,
    AppUser user,
    List<Order> orders,
  ) async {
    final eventsRepo = AnalyticsEventRepository();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return StreamBuilder<List<AnalyticsEvent>>(
              stream: eventsRepo.watchByUser(user.uid),
              builder: (context, eventSnap) {
                final events = eventSnap.data ?? [];
                final spent = orders
                    .where((o) => o.status == OrderStatus.delivered)
                    .fold<double>(0, (s, o) => s + o.grandTotal);
                final funnel = AdminFunnelCalculator.userFunnelProgress(events);
                final funnelLabels = [
                  '',
                  'فتح متجر',
                  'عرض منتج',
                  'إضافة للسلة',
                  'بدء الدفع',
                  'طلب مكتمل',
                ];
                final maxStep = funnel['maxStep'] ?? 0;

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      [
                        if (user.phone.isNotEmpty) user.phone,
                        if (user.activityTypeName.isNotEmpty)
                          user.activityTypeName,
                        if (user.email.isNotEmpty) user.email,
                      ].join(' · '),
                      style: GoogleFonts.cairo(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: user.isOnline
                                ? AppColors.success
                                : AppColors.textHint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.isOnline
                              ? 'متصل الآن'
                              : user.lastActiveAt != null
                                  ? 'آخر نشاط ${AdminFormat.relative(user.lastActiveAt!)}'
                                  : 'غير نشط',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: user.isOnline
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _CrmChip(
                          label: 'الطلبات',
                          value: '${orders.length}',
                        ),
                        _CrmChip(
                          label: 'الإنفاق',
                          value: AdminFormat.currency(spent),
                        ),
                        _CrmChip(
                          label: 'الأحداث',
                          value: '${events.length}',
                        ),
                        if (maxStep > 0)
                          _CrmChip(
                            label: 'مرحلة القمع',
                            value: funnelLabels[maxStep],
                          ),
                      ],
                    ),
                    if (maxStep > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Funnel — تقدم الرحلة',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AdminFunnelChart(
                        steps: AdminFunnelCalculator.computeFunnel(events),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'رحلة المستخدم',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (events.isEmpty)
                      Text(
                        'لا توجد أحداث مسجّلة بعد',
                        style: GoogleFonts.cairo(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      ...events.take(20).map(
                            (e) {
                              final sessionId =
                                  e.metadata['sessionId'] as String? ?? '';
                              return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                _eventIcon(e.type),
                                color: AppColors.primary,
                                size: 20,
                              ),
                              title: Text(
                                e.label,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${e.type.label} · ${e.screen}'
                                '${sessionId.isNotEmpty ? ' · جلسة ${sessionId.substring(0, 6)}…' : ''}'
                                ' · ${AdminFormat.relative(e.createdAt)}',
                                style: GoogleFonts.cairo(fontSize: 11),
                              ),
                            );
                            },
                          ),
                    const SizedBox(height: 16),
                    Text(
                      'الطلبات',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    ...orders.take(10).map(
                          (o) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(o.storeName),
                            subtitle: Text(o.status.label),
                            trailing: Text(
                              AdminFormat.currency(o.grandTotal),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _eventIcon(AnalyticsEventType type) => switch (type) {
        AnalyticsEventType.sessionStart ||
        AnalyticsEventType.sessionEnd =>
          Icons.timelapse_rounded,
        AnalyticsEventType.screenView => Icons.smartphone_rounded,
        AnalyticsEventType.storeView => Icons.storefront_rounded,
        AnalyticsEventType.productView => Icons.fastfood_rounded,
        AnalyticsEventType.addToCart ||
        AnalyticsEventType.addSuggestionToCart =>
          Icons.add_shopping_cart_rounded,
        AnalyticsEventType.removeFromCart => Icons.remove_shopping_cart_rounded,
        AnalyticsEventType.cartOpen => Icons.shopping_cart_rounded,
        AnalyticsEventType.cartQuantityChange ||
        AnalyticsEventType.productQuantityChange =>
          Icons.tune_rounded,
        AnalyticsEventType.applyCoupon ||
        AnalyticsEventType.removeCoupon =>
          Icons.local_offer_rounded,
        AnalyticsEventType.continueToCheckout ||
        AnalyticsEventType.checkoutStart =>
          Icons.payment_rounded,
        AnalyticsEventType.freeDeliveryUnlocked => Icons.delivery_dining_rounded,
        AnalyticsEventType.orderPlaced => Icons.check_circle_rounded,
        AnalyticsEventType.appOpen => Icons.launch_rounded,
        AnalyticsEventType.favoriteToggle => Icons.favorite_rounded,
        AnalyticsEventType.productShare => Icons.share_rounded,
        AnalyticsEventType.ordersOpen => Icons.receipt_long_rounded,
        AnalyticsEventType.orderExpand => Icons.expand_more_rounded,
        AnalyticsEventType.orderTrack => Icons.location_on_rounded,
        AnalyticsEventType.orderReorder => Icons.replay_rounded,
        AnalyticsEventType.orderRate => Icons.star_rounded,
        AnalyticsEventType.orderCancel => Icons.cancel_rounded,
        AnalyticsEventType.orderInvoice => Icons.picture_as_pdf_rounded,
        AnalyticsEventType.searchOpen ||
        AnalyticsEventType.searchQuery ||
        AnalyticsEventType.searchSuggestion ||
        AnalyticsEventType.searchFilter ||
        AnalyticsEventType.searchClearRecent =>
          Icons.search_rounded,
      };
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.user,
    required this.orderCount,
    required this.totalSpent,
    required this.lastActivity,
    required this.isOnline,
    required this.onTap,
    required this.onDelete,
    this.deleting = false,
  });

  final AppUser user;
  final int orderCount;
  final double totalSpent;
  final DateTime lastActivity;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: deleting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isOnline
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.navy.withValues(alpha: 0.1),
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    color: isOnline ? AppColors.success : AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'بدون اسم' : user.name,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      user.phone.isNotEmpty
                          ? EgyptianPhone.toLocalDisplay(user.phone)
                          : (user.email.isNotEmpty ? user.email : '—'),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user.activityTypeName.isNotEmpty)
                      Text(
                        user.activityTypeName,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AdminFormat.currency(totalSpent),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '$orderCount طلب',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    AdminFormat.relative(lastActivity),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              if (deleting)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: 'حذف الحساب',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrmChip extends StatelessWidget {
  const _CrmChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
