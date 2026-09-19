import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/repositories/product_repository.dart';
import 'package:matlobgo/services/order_cancel_service.dart';
import 'package:matlobgo/services/order_service.dart';
import 'package:matlobgo/services/reorder_service.dart';

/// طبقة مستودع الطلبات — واجهة مستقرة للـ [OrdersController].
///
/// تغلّف [OrderService] (القوائم والبث اللحظي) + [ReorderService] (إعادة الطلب)
/// + [OrderCancelService] (الإلغاء) + [ProductRepository] (استكمال صور الطلبات
/// القديمة اختيارياً) بحيث لا يلمس الـ UI الـ Services أو Firestore مباشرة.
///
/// مرجع: [ProductDetailsRepository].
class OrdersRepository {
  OrdersRepository({
    OrderService? orderService,
    ReorderService? reorderService,
    OrderCancelService? cancelService,
    ProductRepository? productRepository,
  })  : _orderServiceOverride = orderService,
        _reorderOverride = reorderService,
        _cancelOverride = cancelService,
        _productsOverride = productRepository;

  // التبعيات مُهيّأة بكسل — لا نلمس Firebase حتى أول استخدام فعلي
  // (يُسهّل حقن بدائل الاختبار دون تهيئة Firebase).
  final OrderService? _orderServiceOverride;
  final ReorderService? _reorderOverride;
  final OrderCancelService? _cancelOverride;
  final ProductRepository? _productsOverride;

  ReorderService? _reorderCached;
  OrderCancelService? _cancelCached;
  ProductRepository? _productsCached;

  OrderService get _orderService =>
      _orderServiceOverride ?? OrderService.instance;
  ReorderService get _reorder =>
      _reorderOverride ?? (_reorderCached ??= ReorderService());
  OrderCancelService get _cancel =>
      _cancelOverride ?? (_cancelCached ??= OrderCancelService());
  ProductRepository get _products =>
      _productsOverride ?? (_productsCached ??= ProductRepository());

  /// مصدر الإشعار اللحظي — يستمع له الـ Controller.
  Listenable get ordersListenable => _orderService;

  /// اللقطة الحالية لطلبات العميل (مرتّبة الأحدث أولاً من [OrderService]).
  List<Order> get orders => _orderService.orders;

  /// إعادة ملء السلة من طلب سابق — يوجَّه عبر [ReorderService].
  /// يعيد عدد الأصناف المضافة (0 إذا تعذّر).
  Future<int> reorder(Order order) => _reorder.refillFromOrder(order);

  /// إلغاء الطلب عبر Cloud Function ([OrderCancelService]).
  Future<void> cancel({
    required String orderId,
    String reason = 'customer_cancelled',
  }) =>
      _cancel.cancelOrder(orderId: orderId, reason: reason);

  // ── استكمال صور المنتجات للطلبات القديمة (اختياري، لا يحجب الواجهة) ──
  final Map<String, String> _imageCacheByProduct = {};

  /// يحاول إيجاد صورة منتج مفقودة من كتالوج المتجر (cache بالـ productId).
  /// لا يرمي أبداً — يعيد null عند التعذّر.
  Future<String?> resolveProductImage({
    required String storeId,
    required String productId,
  }) async {
    if (productId.isEmpty || storeId.isEmpty) return null;
    final cached = _imageCacheByProduct[productId];
    if (cached != null) return cached.isEmpty ? null : cached;
    try {
      final products = await _products.fetchProductsOnce(storeId);
      for (final product in products) {
        final url = product.imageUrl ?? '';
        if (url.isNotEmpty) {
          _imageCacheByProduct[product.id] = url;
        }
      }
      // علّم المفقود بقيمة فارغة لتفادي إعادة الجلب.
      _imageCacheByProduct.putIfAbsent(productId, () => '');
      final resolved = _imageCacheByProduct[productId] ?? '';
      return resolved.isEmpty ? null : resolved;
    } catch (_) {
      return null;
    }
  }

  /// تحديث يدوي (سحب للتحديث). البث لحظي عبر [OrderService] لذا لا حاجة
  /// لإعادة الربط — نُبقيها كنقطة امتداد مستقبلية.
  Future<void> refresh() async {}
}
