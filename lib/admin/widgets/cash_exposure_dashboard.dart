import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/widgets/admin_stat_card.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/app_user.dart';

class CashExposureDashboard extends StatelessWidget {
  const CashExposureDashboard({super.key, required this.drivers});

  final List<AppUser> drivers;

  @override
  Widget build(BuildContext context) {
    final deliveryDrivers = drivers.where((d) => d.isDelivery).toList();
    final totalOutstanding = deliveryDrivers.fold<double>(
      0,
      (sum, d) => sum + d.outstandingBalance,
    );
    final above300 =
        deliveryDrivers.where((d) => d.outstandingBalance >= 300).length;
    final above450 =
        deliveryDrivers.where((d) => d.outstandingBalance >= 450).length;
    final blocked =
        deliveryDrivers.where((d) => d.driverCashBlocked).length;
    final avgOutstanding = deliveryDrivers.isEmpty
        ? 0.0
        : totalOutstanding / deliveryDrivers.length;

    final topRisk = [...deliveryDrivers]
      ..sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
    final top10 = topRisk.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Exposure',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            AdminStatCard(
              label: 'Total Outstanding Cash',
              value: '${totalOutstanding.toStringAsFixed(0)} ج',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.navy,
            ),
            AdminStatCard(
              label: 'Drivers Above 300',
              value: '$above300',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            AdminStatCard(
              label: 'Drivers Above 450',
              value: '$above450',
              icon: Icons.report_rounded,
              color: AppColors.error,
            ),
            AdminStatCard(
              label: 'Blocked Drivers',
              value: '$blocked',
              icon: Icons.block_rounded,
              color: AppColors.error,
            ),
            AdminStatCard(
              label: 'Average Outstanding',
              value: '${avgOutstanding.toStringAsFixed(0)} ج',
              icon: Icons.analytics_outlined,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Top Risk Drivers',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Driver', style: GoogleFonts.cairo())),
                DataColumn(label: Text('Outstanding', style: GoogleFonts.cairo())),
                DataColumn(label: Text('Status', style: GoogleFonts.cairo())),
                DataColumn(label: Text('Governorate', style: GoogleFonts.cairo())),
                DataColumn(label: Text('Accept Rate', style: GoogleFonts.cairo())),
                DataColumn(label: Text('Last Delivery', style: GoogleFonts.cairo())),
              ],
              rows: top10.map((driver) {
                final statusColor = _statusColor(driver.walletStatus);
                final acceptRate = driver.acceptRate != null
                    ? '${(driver.acceptRate!.clamp(0, 1) * 100).toStringAsFixed(0)}%'
                    : '—';
                final lastDelivery = driver.lastActiveAt != null
                    ? '${driver.lastActiveAt!.day}/${driver.lastActiveAt!.month}/${driver.lastActiveAt!.year}'
                    : '—';

                return DataRow(cells: [
                  DataCell(Text(driver.name, style: GoogleFonts.cairo())),
                  DataCell(Text(
                    '${driver.outstandingBalance.toStringAsFixed(0)} ج',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  )),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(driver.walletStatus),
                        style: GoogleFonts.cairo(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(driver.governorate, style: GoogleFonts.cairo())),
                  DataCell(Text(acceptRate, style: GoogleFonts.cairo())),
                  DataCell(Text(lastDelivery, style: GoogleFonts.cairo())),
                ]);
              }).toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) => switch (status) {
        'needs_attention' => AppColors.warning,
        'near_block' => AppColors.error,
        'blocked' => AppColors.error,
        _ => AppColors.success,
      };

  String _statusLabel(String status) => switch (status) {
        'needs_attention' => 'Yellow',
        'near_block' => 'Orange',
        'blocked' => 'Red',
        _ => 'Green',
      };
}
