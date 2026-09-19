import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/screens/home/orders/orders_controller.dart';
import 'package:matlobgo/screens/home/orders/widgets/order_card.dart';
import 'package:matlobgo/screens/home/orders/widgets/orders_header.dart';
import 'package:matlobgo/screens/home/orders/widgets/orders_segmented_tabs.dart';
import 'package:matlobgo/screens/home/orders/widgets/orders_state_views.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/services/notification_service.dart';
import 'package:matlobgo/services/order_service.dart';
import 'package:matlobgo/services/theme_service.dart';

/// شاشة الطلبات «طلباتي» — تكوين رفيع فقط (Controller + Widgets).
///
/// Reference Implementation v4 — نفس معمارية Product RI v3:
/// UI رفيع → [OrdersController] → `OrdersRepository` → Services / Cloud Functions.
///
/// توقيع الباني ثابت للتوافق مع `home_screen`.
class OrdersTab extends StatefulWidget {
  const OrdersTab({
    super.key,
    required this.orderService,
    this.onExploreStores,
    this.onNotifications,
  });

  final OrderService orderService;
  final VoidCallback? onExploreStores;
  final VoidCallback? onNotifications;

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  late final OrdersController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OrdersController(orderService: widget.orderService);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final notice = _controller.notice;
    if (notice != null) {
      _showNotice(notice);
      _controller.clearNotice();
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: CartTypography.style(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        ThemeService.instance,
        CmsTextService.instance,
        NotificationService.instance,
      ]),
      builder: (context, _) {
        return ColoredBox(
          color: AppColors.navy,
          child: Column(
            children: [
              OrdersHeader(
                title: 'طلباتي',
                subtitle: 'تابع جميع طلباتك الحالية والسابقة',
                notificationBadge: NotificationService.instance.unreadCount,
                onNotifications: widget.onNotifications,
              ),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -20,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        child: PremiumBackground.body(context, _buildBody()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (!_controller.hasAnyOrders && _controller.loading) {
      return const OrdersSkeletonList();
    }

    if (!_controller.hasAnyOrders) {
      return Padding(
        padding: const EdgeInsets.only(top: OrdersTokens.space3xl),
        child: AppEmptyState.preset(
          AppEmptyKind.ordersAll,
          onAction: widget.onExploreStores,
        ),
      );
    }

    return Column(
      children: [
        OrdersSegmentedTabs(
          selectedIndex: _controller.selectedTab,
          activeCount: _controller.activeCount,
          completedCount: _controller.completedCount,
          cancelledCount: _controller.cancelledCount,
          onSelect: _controller.selectTab,
        ),
        if (_controller.offline) const OrdersOfflineBanner(),
        Expanded(child: _buildTabPane()),
      ],
    );
  }

  Widget _buildTabPane() {
    final kind = _controller.selectedKind;
    final orders = _controller.ordersFor(kind);

    if (orders.isEmpty) {
      return OrdersEmptyView(kind: kind, onAction: widget.onExploreStores);
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          OrdersTokens.pagePadding,
          OrdersTokens.spaceMd,
          OrdersTokens.pagePadding,
          OrdersTokens.space3xl + OrdersTokens.spaceMd,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: orders.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: OrdersTokens.spaceXl),
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            key: ValueKey(order.id),
            order: order,
            expanded: _controller.isExpanded(order.id),
            onToggleExpand: () => _controller.toggleExpand(order.id),
            onTrack: () => _controller.trackOrder(context, order),
            onReorder: () => _controller.reorder(order),
          );
        },
      ),
    );
  }
}
