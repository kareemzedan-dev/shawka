import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/screens/home/orders/orders_controller.dart';

/// شريط رفيع «بدون اتصال» — يُعرض داخلياً فوق القائمة (غير معطِّل).
class OrdersOfflineBanner extends StatelessWidget {
  const OrdersOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'لا يوجد اتصال — قد لا تكون البيانات محدّثة',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          OrdersTokens.pagePadding,
          OrdersTokens.spaceMd,
          OrdersTokens.pagePadding,
          0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: OrdersTokens.spaceLg,
          vertical: OrdersTokens.spaceMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: BorderRadius.circular(OrdersTokens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: OrdersTokens.accentText,
            ),
            const SizedBox(width: OrdersTokens.spaceMd),
            Expanded(
              child: Text(
                'لا يوجد اتصال — قد لا تكون البيانات محدّثة',
                style: CartTypography.style(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: OrdersTokens.accentText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة فارغة لقسم محدّد — تعيد استخدام presets الموحّدة.
class OrdersEmptyView extends StatelessWidget {
  const OrdersEmptyView({
    super.key,
    required this.kind,
    this.onAction,
  });

  final OrdersTabKind kind;
  final VoidCallback? onAction;

  AppEmptyKind get _emptyKind => switch (kind) {
        OrdersTabKind.active => AppEmptyKind.ordersActive,
        OrdersTabKind.completed => AppEmptyKind.ordersCompleted,
        OrdersTabKind.cancelled => AppEmptyKind.ordersCancelled,
      };

  @override
  Widget build(BuildContext context) {
    return AppEmptyState.preset(
      _emptyKind,
      compact: true,
      onAction: onAction,
    );
  }
}

/// هيكل تحميل (2-3 بطاقات shimmer) أثناء عدم توفّر بيانات بعد.
class OrdersSkeletonList extends StatefulWidget {
  const OrdersSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  State<OrdersSkeletonList> createState() => _OrdersSkeletonListState();
}

class _OrdersSkeletonListState extends State<OrdersSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        OrdersTokens.pagePadding,
        OrdersTokens.spaceMd,
        OrdersTokens.pagePadding,
        OrdersTokens.space3xl,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.count,
      separatorBuilder: (_, _) => const SizedBox(height: OrdersTokens.spaceXl),
      itemBuilder: (_, _) => _SkeletonCard(animation: _shimmer),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OrdersTokens.space2xl),
      decoration: BoxDecoration(
        color: OrdersTokens.cardBackground,
        borderRadius: BorderRadius.circular(OrdersTokens.cardRadius),
        border: Border.all(color: OrdersTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Bone(
                animation: animation,
                width: OrdersTokens.storeLogo,
                height: OrdersTokens.storeLogo,
                radius: OrdersTokens.storeLogo / 2,
              ),
              const SizedBox(width: OrdersTokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(animation: animation, width: 140, height: 14),
                    const SizedBox(height: OrdersTokens.spaceSm),
                    _Bone(animation: animation, width: 90, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OrdersTokens.space2xl),
          _Bone(
            animation: animation,
            width: double.infinity,
            height: OrdersTokens.timelineDot,
            radius: OrdersTokens.radiusSm,
          ),
          const SizedBox(height: OrdersTokens.space2xl),
          _Bone(
            animation: animation,
            width: double.infinity,
            height: 56,
            radius: OrdersTokens.radiusMd,
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.animation,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final Animation<double> animation;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = (animation.value * 2) - 1;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - t, 0),
              end: Alignment(1 - t, 0),
              colors: const [
                Color(0xFFEDEFF2),
                Color(0xFFF6F7F9),
                Color(0xFFEDEFF2),
              ],
            ),
          ),
        );
      },
    );
  }
}
