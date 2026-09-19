import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/repositories/order_repository.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/repositories/store_category_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';

class AdminOverviewPanel extends StatelessWidget {
  const AdminOverviewPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  Widget build(BuildContext context) {
    final storeRepo = StoreRepository();
    final orderRepo = OrderRepository();
    final categoryRepo = StoreCategoryRepository();

    return StreamBuilder<List<Store>>(
      stream: storeRepo.watchStoresByGovernorate(governorate: governorate.name),
      builder: (context, snapshot) {
        final stores = snapshot.data ?? [];
        final active = stores.where((s) => s.isActive).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enterprise Dashboard — ${governorate.name}',
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'إحصائيات المتاجر في المحافظة المحددة أعلى الشاشة',
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'إجمالي المتاجر',
                    value: '${stores.length}',
                    icon: Icons.store_rounded,
                    color: AppColors.navy,
                  ),
                  _StatCard(
                    label: 'نشطة',
                    value: '$active',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder(
                stream: categoryRepo.watchByGovernorate(governorate.name),
                builder: (context, catSnap) {
                  final cats = catSnap.data ?? [];
                  if (cats.isEmpty) return const SizedBox.shrink();
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cats.map((cat) {
                      final count = stores
                          .where((s) => StoreCatalogUtils.matchesCategory(s, cat.id))
                          .length;
                      return _StatCard(
                        label: cat.name,
                        value: '$count',
                        icon: cat.icon,
                        color: AppColors.primary,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'الطلبات',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Order>>(
                stream: orderRepo.watchOrdersByGovernorate(
                  governorate: governorate.name,
                ),
                builder: (context, orderSnap) {
                  final orders = orderSnap.data ?? [];
                  final activeOrders =
                      orders.where((o) => o.status.isActive).length;
                  final pending =
                      orders.where((o) => o.status == OrderStatus.pending).length;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        label: 'إجمالي الطلبات',
                        value: '${orders.length}',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.navy,
                      ),
                      _StatCard(
                        label: 'نشطة الآن',
                        value: '$activeOrders',
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.primary,
                      ),
                      _StatCard(
                        label: 'بانتظار المراجعة',
                        value: '$pending',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.info,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
