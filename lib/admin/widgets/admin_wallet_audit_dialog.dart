import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

Future<void> showWalletAuditTrailDialog(
  BuildContext context, {
  required String driverId,
  required String driverName,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'سجل التدقيق — $driverName',
        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 560,
        height: 480,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('wallet_transactions')
              .where('driverId', isEqualTo: driverId)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Text('لا توجد عمليات', style: GoogleFonts.cairo()),
              );
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                final balanceBefore =
                    (data['balanceBefore'] as num?)?.toDouble() ?? 0;
                final balanceAfter =
                    (data['balanceAfter'] as num?)?.toDouble() ?? 0;
                final performedBy = data['performedBy'] as String? ??
                    data['createdBy'] as String? ??
                    'system';
                final performedByRole =
                    data['performedByRole'] as String? ?? '—';
                final source = data['source'] as String? ?? '—';
                final txType = data['transactionType'] as String? ??
                    data['type'] as String? ??
                    '—';
                final notes = data['notes'] as String?;
                final createdAt = data['createdAt'] as Timestamp?;
                final when = createdAt?.toDate();
                final whenLabel = when == null
                    ? '—'
                    : '${when.day}/${when.month}/${when.year} ${when.hour}:${when.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  title: Text(
                    '$txType · ${amount.toStringAsFixed(2)} ج.م',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      whenLabel,
                      'بواسطة: $performedBy ($performedByRole)',
                      'المصدر: $source',
                      if (notes != null && notes.isNotEmpty) notes,
                      'الرصيد: ${balanceBefore.toStringAsFixed(0)} → ${balanceAfter.toStringAsFixed(0)}',
                    ].join('\n'),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('إغلاق', style: GoogleFonts.cairo()),
        ),
      ],
    ),
  );
}
