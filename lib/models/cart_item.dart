export 'package:matlobgo/models/product.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.storeName,
    required this.category,
    required this.productName,
    required this.price,
    this.quantity = 1,
    this.imageUrl,
    this.imageThumbUrl,
    this.storeMinOrderAmount = 0,
    this.addonIds = const [],
    this.note = '',
    this.isAvailable = true,
    this.stockQuantity,
    this.trackStock = false,
    this.maxPerCustomer = 0,
    this.discountPercent = 0,
  });

  final String id;
  final String storeId;
  final String productId;
  final String storeName;
  /// معرف تصنيف المورد من لوحة التحكم (أو قيمة قديمة للطلبات السابقة).
  final String category;
  final String productName;
  double price;
  int quantity;
  final String? imageUrl;
  final String? imageThumbUrl;
  double storeMinOrderAmount;
  final List<String> addonIds;
  final String note;

  /// Realtime sync fields (not persisted as cart identity).
  bool isAvailable;
  int? stockQuantity;
  bool trackStock;
  /// 0 = بدون حد خاص بالعميل.
  int maxPerCustomer;
  double discountPercent;

  double get lineTotal => price * quantity;

  /// أقصى كمية مسموحة لهذا السطر (مخزون + حد العميل + حد النظام).
  int get maxOrderQuantity {
    const systemCap = 99;
    final customerCap =
        maxPerCustomer > 0 ? maxPerCustomer.clamp(1, systemCap) : systemCap;
    if (trackStock && stockQuantity != null) {
      final stockCap = stockQuantity!.clamp(0, systemCap);
      return stockCap < customerCap ? stockCap : customerCap;
    }
    return customerCap;
  }

  CartItem copyWith({
    int? quantity,
    double? price,
    String? productName,
    String? imageUrl,
    String? imageThumbUrl,
    double? storeMinOrderAmount,
    bool? isAvailable,
    int? stockQuantity,
    bool? trackStock,
    int? maxPerCustomer,
    double? discountPercent,
  }) {
    return CartItem(
      id: id,
      storeId: storeId,
      productId: productId,
      storeName: storeName,
      category: category,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      imageThumbUrl: imageThumbUrl ?? this.imageThumbUrl,
      storeMinOrderAmount: storeMinOrderAmount ?? this.storeMinOrderAmount,
      addonIds: addonIds,
      note: note,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      trackStock: trackStock ?? this.trackStock,
      maxPerCustomer: maxPerCustomer ?? this.maxPerCustomer,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}
