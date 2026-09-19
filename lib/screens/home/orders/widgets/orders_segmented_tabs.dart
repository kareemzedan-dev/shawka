import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';

/// شرائح الأقسام (segmented) — نشطة | مكتملة | ملغية، المحدّدة حبّة بيضاء.
class OrdersSegmentedTabs extends StatelessWidget {
  const OrdersSegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.activeCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.onSelect,
  });

  final int selectedIndex;
  final int activeCount;
  final int completedCount;
  final int cancelledCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OrdersTokens.pagePadding,
        OrdersTokens.spaceXl,
        OrdersTokens.pagePadding,
        OrdersTokens.spaceSm,
      ),
      child: Container(
        height: OrdersTokens.segmentHeight,
        padding: const EdgeInsets.all(OrdersTokens.spaceXs),
        decoration: BoxDecoration(
          color: OrdersTokens.segmentTrack,
          borderRadius: BorderRadius.circular(OrdersTokens.radiusXl + 4),
        ),
        child: Row(
          children: [
            _Segment(
              label: 'نشطة',
              count: activeCount,
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            _Segment(
              label: 'مكتملة',
              count: completedCount,
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            _Segment(
              label: 'ملغية',
              count: cancelledCount,
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = count > 0 ? '$label ($count)' : label;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: text,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: OrdersTokens.motionStandard,
            curve: OrdersTokens.curveStandard,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? OrdersTokens.segmentSelected
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(OrdersTokens.radiusXl),
              boxShadow: selected ? OrdersTokens.segmentShadow : null,
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CartTypography.style(
                fontSize: OrdersTokens.segmentSize,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? OrdersTokens.textPrimary
                    : OrdersTokens.segmentUnselectedText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
