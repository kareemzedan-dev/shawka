import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/widgets/admin_driver_map_panel.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_stat_card.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/repositories/order_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/repositories/user_repository.dart';

class AdminLiveMonitorPanel extends StatelessWidget {
  const AdminLiveMonitorPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  Widget build(BuildContext context) {
    final orderRepo = OrderRepository();
    final storeRepo = StoreRepository();
    final userRepo = UserRepository();

    return StreamBuilder<List<Order>>(
      stream: orderRepo.watchOrdersByGovernorate(governorate: governorate.name),
      builder: (context, orderSnap) {
        final orders = orderSnap.data ?? [];
        final activeOrders = orders.where((o) => o.status.isActive).toList();

        return StreamBuilder(
          stream: storeRepo.watchStoresByGovernorate(
            governorate: governorate.name,
          ),
          builder: (context, storeSnap) {
            final stores = storeSnap.data ?? [];
            final openStores =
                stores.where((s) => s.isOpen && s.isActive).length;

            return StreamBuilder(
              stream: userRepo.watchDeliveryAgents(
                governorate: governorate.name,
              ),
              builder: (context, deliverySnap) {
                final allDrivers = deliverySnap.data ?? [];
                final liveDrivers = userRepo.onlineDrivers(allDrivers);

                return StreamBuilder(
                  stream: userRepo.watchUsersByRole(UserRole.customer),
                  builder: (context, customerSnap) {
                    final customers = customerSnap.data ?? [];
                    final onlineCustomers = userRepo.countOnlineCustomers(
                      customers: customers,
                      governorate: governorate.name,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminPanelHeader(
                            title: 'المراقبة المباشرة',
                            subtitle:
                                'Presence حقيقي · GPS المندوبين — ${governorate.name}',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Live — lastActiveAt ≤ 5 د',
                                style: GoogleFonts.cairo(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              AdminStatCard(
                                label: 'طلبات نشطة الآن',
                                value: '${activeOrders.length}',
                                icon: Icons.receipt_long_rounded,
                                color: AppColors.primary,
                              ),
                              AdminStatCard(
                                label: 'متاجر مفتوحة',
                                value: '$openStores',
                                icon: Icons.store_rounded,
                                color: AppColors.success,
                              ),
                              AdminStatCard(
                                label: 'عملاء online',
                                value: '$onlineCustomers',
                                icon: Icons.wifi_tethering_rounded,
                                color: AppColors.info,
                              ),
                              AdminStatCard(
                                label: 'مندوبون live + GPS',
                                value: '${liveDrivers.length}',
                                icon: Icons.delivery_dining_rounded,
                                color: AppColors.navy,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'خريطة المندوبين — GPS Live',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AdminDriverMapPanel(drivers: liveDrivers),
                          const SizedBox(height: 28),
                          Text(
                            'الطلبات الجارية',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (activeOrders.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: AdminEmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  message: 'لا توجد طلبات نشطة حالياً',
                                ),
                              ),
                            )
                          else
                            ...activeOrders.take(12).map(
                                  (order) => Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            order.status.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        child: Icon(
                                          order.status.icon,
                                          color: order.status.color,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        order.storeName,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${order.status.label} · ${order.customerName}'
                                        '${order.deliveryName != null ? ' · ${order.deliveryName}' : ''}',
                                        style: GoogleFonts.cairo(fontSize: 12),
                                      ),
                                      trailing: Text(
                                        '${order.grandTotal.toStringAsFixed(0)} ج.م',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
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
}
