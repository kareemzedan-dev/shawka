import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_settlement_service.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';

class AdminSettlementRequestsPanel extends StatefulWidget {
  const AdminSettlementRequestsPanel({super.key});

  @override
  State<AdminSettlementRequestsPanel> createState() =>
      _AdminSettlementRequestsPanelState();
}

class _AdminSettlementRequestsPanelState
    extends State<AdminSettlementRequestsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _service = AdminSettlementService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPanelHeader(
            title: 'Settlement Requests',
            subtitle: 'مراجعة طلبات تسوية المندوبين',
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabs,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _RequestsList(status: 'pending', service: _service),
                _RequestsList(status: 'approved', service: _service),
                _RequestsList(status: 'rejected', service: _service),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.status, required this.service});

  final String status;
  final AdminSettlementService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settlement_requests')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'لا توجد طلبات',
              style: GoogleFonts.cairo(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return _RequestCard(
              requestId: doc.id,
              data: data,
              status: status,
              service: service,
            );
          },
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.requestId,
    required this.data,
    required this.status,
    required this.service,
  });

  final String requestId;
  final Map<String, dynamic> data;
  final String status;
  final AdminSettlementService service;

  @override
  Widget build(BuildContext context) {
    final driverName = data['driverName'] as String? ?? '—';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final methodLabel = data['methodLabel'] as String? ?? data['method'] ?? '—';
    final reference = data['transactionReference'] as String?;
    final notes = data['notes'] as String?;
    final receiptUrl = data['receiptImageUrl'] as String?;
    final reviewReason = data['reviewReason'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    driverName,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('الطريقة: $methodLabel', style: GoogleFonts.cairo()),
            if (reference != null && reference.isNotEmpty)
              Text('مرجع: $reference', style: GoogleFonts.cairo()),
            if (notes != null && notes.isNotEmpty)
              Text('ملاحظات: $notes', style: GoogleFonts.cairo()),
            if (reviewReason != null && reviewReason.isNotEmpty)
              Text(
                'سبب الرفض: $reviewReason',
                style: GoogleFonts.cairo(color: AppColors.error),
              ),
            if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text('عرض الإيصال', style: GoogleFonts.cairo()),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => _approve(context),
                    child: Text('Approve', style: GoogleFonts.cairo()),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _reject(context),
                    child: Text('Reject', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    try {
      await service.reviewRequest(
        requestId: requestId,
        action: 'approve',
        amount: (data['amount'] as num?)?.toDouble(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم اعتماد الطلب', style: GoogleFonts.cairo()),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FirestoreErrorMessage.from(e), style: GoogleFonts.cairo()),
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('رفض الطلب', style: GoogleFonts.cairo()),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'سبب الرفض'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('رفض', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed != true || reasonCtrl.text.trim().isEmpty) return;

    try {
      await service.reviewRequest(
        requestId: requestId,
        action: 'reject',
        reviewReason: reasonCtrl.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفض الطلب', style: GoogleFonts.cairo()),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FirestoreErrorMessage.from(e), style: GoogleFonts.cairo()),
        ),
      );
    }
  }
}
