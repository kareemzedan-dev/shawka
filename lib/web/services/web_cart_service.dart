import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/web/services/web_analytics_service.dart';

/// سلة وهمية للويب — بدون checkout فعلي.
class WebCartService extends ChangeNotifier {
  WebCartService._();
  static final WebCartService instance = WebCartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.lineTotal);
  bool get isEmpty => _items.isEmpty;

  double get deliveryFee {
    if (_items.isEmpty) return 0;
    final settings = AppConfigService.instance.settings;
    final storeCount =
        settings.storeCountFromItems(_items.map((e) => e.storeId));
    return settings.computeDeliveryFee(subtotal: subtotal, storeCount: storeCount);
  }

  double get total => subtotal + deliveryFee;

  bool addProduct({
    required Store store,
    required Product product,
    int quantity = 1,
    double? unitPrice,
    String? displayName,
  }) {
    if (!store.isSellable) return false;
    final lineId = '${store.id}_${product.id}';
    final maxQty = product.maxOrderQuantity;
    if (maxQty <= 0) return false;
    final existing = _items.where((i) => i.id == lineId);
    if (existing.isNotEmpty) {
      final item = existing.first;
      final next = (item.quantity + quantity).clamp(1, maxQty);
      if (next == item.quantity) return false;
      item.quantity = next;
      item.trackStock = product.trackStock;
      item.stockQuantity = product.stockQuantity;
      item.maxPerCustomer = product.maxPerCustomer;
    } else {
      _items.add(
        CartItem(
          id: lineId,
          storeId: store.id,
          productId: product.id,
          storeName: store.name,
          category: store.categoryId,
          productName: displayName ?? product.name,
          price: unitPrice ?? product.price,
          quantity: quantity.clamp(1, maxQty),
          imageUrl: product.imageUrl,
          imageThumbUrl: product.imageThumbUrl,
          storeMinOrderAmount: store.minOrderAmount,
          trackStock: product.trackStock,
          stockQuantity: product.stockQuantity,
          maxPerCustomer: product.maxPerCustomer,
        ),
      );
    }
    notifyListeners();
    WebAnalyticsService.instance.addToCart(
      store: store,
      product: product,
      quantity: quantity,
    );
    return true;
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final item = _items.firstWhere((e) => e.id == itemId);
    item.quantity = quantity.clamp(1, item.maxOrderQuantity);
    notifyListeners();
  }

  void removeItem(String itemId) {
    final item = _items.where((e) => e.id == itemId).firstOrNull;
    if (item != null) {
      WebAnalyticsService.instance.removeFromCart(item: item);
    }
    _items.removeWhere((e) => e.id == itemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
