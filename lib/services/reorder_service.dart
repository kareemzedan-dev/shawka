import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/order.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/services/cart_service.dart';

/// إعادة ملء السلة من طلب سابق.
class ReorderService {
  ReorderService({
    CartService? cart,
    StoreRepository? stores,
  })  : _cart = cart ?? CartService.instance,
        _stores = stores ?? StoreRepository();

  final CartService _cart;
  final StoreRepository _stores;

  Future<int> refillFromOrder(Order order) async {
    if (order.lineItems.isEmpty) return 0;

    final store = order.storeId.isNotEmpty
        ? await _stores.getStore(order.storeId)
        : null;
    if (store == null) return 0;

    var added = 0;
    for (final line in order.lineItems) {
      final productId =
          line.productId.isNotEmpty ? line.productId : 'reorder_${line.productName.hashCode}';
      final ok = _cart.addProduct(
        store: store,
        product: Product(
          id: productId,
          storeId: order.storeId,
          name: line.productName,
          price: line.unitPrice,
        ),
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        displayName: line.productName,
      );
      if (ok) added += line.quantity;
    }
    return added;
  }
}
