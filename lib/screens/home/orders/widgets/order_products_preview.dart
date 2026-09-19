import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/orders_tokens.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/order_line_item.dart';

/// معاينة منتجات الطلب — صورة حقيقية + اسم + كمية (+N للبقية).
class OrderProductsPreview extends StatelessWidget {
  const OrderProductsPreview({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final items = order.lineItems;
    if (items.isEmpty) {
      if (order.itemsSummary.trim().isEmpty) return const SizedBox.shrink();
      return _SummaryFallback(summary: order.itemsSummary);
    }

    final visible = items.take(2).toList(growable: false);
    final remaining = items.length - visible.length;

    return Container(
      padding: const EdgeInsets.all(OrdersTokens.spaceMd),
      decoration: BoxDecoration(
        color: OrdersTokens.previewFill,
        borderRadius: BorderRadius.circular(OrdersTokens.radiusMd),
      ),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: OrdersTokens.spaceSm),
            _ProductRow(
              item: visible[i],
              storeId: order.storeId,
              trailing: i == 0 && remaining > 0
                  ? _MoreBadge(count: remaining)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.item,
    required this.storeId,
    this.trailing,
  });

  final OrderLineItem item;
  final String storeId;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ItemImage(item: item, storeId: storeId),
        const SizedBox(width: OrdersTokens.spaceLg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CartTypography.style(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: OrdersTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'عدد ${item.quantity} قطعة',
                style: CartTypography.style(
                  fontSize: OrdersTokens.metaSize,
                  fontWeight: FontWeight.w600,
                  color: OrdersTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: OrdersTokens.spaceSm),
          trailing!,
        ],
      ],
    );
  }
}

class _ItemImage extends StatefulWidget {
  const _ItemImage({
    required this.item,
    required this.storeId,
  });

  final OrderLineItem item;
  final String storeId;

  @override
  State<_ItemImage> createState() => _ItemImageState();
}

class _ItemImageState extends State<_ItemImage> {
  late String _imageUrl;
  late String _thumbUrl;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.item.imageUrl.trim();
    _thumbUrl = widget.item.imageThumbUrl.trim();
    if (_imageUrl.isEmpty && _thumbUrl.isEmpty) {
      _resolveFromCatalog();
    }
  }

  @override
  void didUpdateWidget(covariant _ItemImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.productId != widget.item.productId ||
        oldWidget.item.imageUrl != widget.item.imageUrl ||
        oldWidget.storeId != widget.storeId) {
      _imageUrl = widget.item.imageUrl.trim();
      _thumbUrl = widget.item.imageThumbUrl.trim();
      if (_imageUrl.isEmpty && _thumbUrl.isEmpty) {
        _resolveFromCatalog();
      }
    }
  }

  Future<void> _resolveFromCatalog() async {
    final storeId = widget.storeId.trim();
    final productId = widget.item.productId.trim();
    if (storeId.isEmpty || productId.isEmpty || _resolving) return;
    _resolving = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.storeProducts(storeId))
          .doc(productId)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final full = normalizeStoredImageUrl(data['imageUrl'] as String?) ?? '';
      final thumb =
          normalizeStoredImageUrl(data['imageThumbUrl'] as String?) ?? full;
      if (full.isEmpty && thumb.isEmpty) return;
      setState(() {
        _imageUrl = full;
        _thumbUrl = thumb;
      });
    } catch (_) {
      // نُبقي الـ fallback الأيقوني.
    } finally {
      _resolving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        size: 22,
        color: OrdersTokens.textMuted,
      ),
    );

    final hasImage = _thumbUrl.isNotEmpty || _imageUrl.isNotEmpty;

    return SizedBox(
      width: OrdersTokens.previewImage,
      height: OrdersTokens.previewImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OrdersTokens.radiusSm),
        child: hasImage
            ? CatalogNetworkImage(
                imageUrl: _imageUrl.isNotEmpty ? _imageUrl : null,
                thumbnailUrl: _thumbUrl.isNotEmpty ? _thumbUrl : null,
                fallback: fallback,
                fit: BoxFit.cover,
                cacheWidth: 160,
                cacheHeight: 160,
              )
            : fallback,
      ),
    );
  }
}

class _MoreBadge extends StatelessWidget {
  const _MoreBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count أصناف إضافية',
      child: Container(
        width: OrdersTokens.previewMoreBadge,
        height: OrdersTokens.previewMoreBadge,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '+$count',
          style: CartTypography.style(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: OrdersTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryFallback extends StatelessWidget {
  const _SummaryFallback({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OrdersTokens.spaceLg),
      decoration: BoxDecoration(
        color: OrdersTokens.previewFill,
        borderRadius: BorderRadius.circular(OrdersTokens.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_rounded,
            size: 18,
            color: OrdersTokens.textMuted,
          ),
          const SizedBox(width: OrdersTokens.spaceSm),
          Expanded(
            child: Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CartTypography.style(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: OrdersTokens.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
