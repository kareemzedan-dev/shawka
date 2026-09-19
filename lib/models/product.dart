import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';
import 'package:matlobgo/models/product_addon.dart';

class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.imageThumbUrl,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.ingredients = const [],
    this.addons = const [],
    this.trackStock = false,
    this.stockQuantity = 0,
    this.maxPerCustomer = 0,
    this.category = '',
    this.oldPrice = 0,
    this.discountPercent = 0,
    this.bestSeller = false,
    this.isNew = false,
    this.isFeatured = false,
    this.tags = const [],
    this.reviewCount = 0,
    this.rating = 0,
    this.preparationTime = 0,
    this.viewsCount = 0,
    this.ordersCount = 0,
    this.calories = 0,
    this.portionSize = '',
    this.natureLabel = '',
    this.activityTypeIds = const [],
  });

  final String id;
  final String storeId;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final String? imageThumbUrl;
  final bool isAvailable;
  final int sortOrder;
  final List<String> ingredients;
  final List<ProductAddon> addons;
  final bool trackStock;
  final int stockQuantity;

  /// 0 = بدون حد خاص بالعميل (يُطبَّق حد النظام 99 فقط).
  final int maxPerCustomer;
  final String category;
  final double oldPrice;
  final double discountPercent;
  final bool bestSeller;
  final bool isNew;
  final bool isFeatured;
  final List<String> tags;
  final int reviewCount;
  final double rating;
  final int preparationTime;
  final int viewsCount;
  final int ordersCount;
  /// سعرات حرارية اختيارية من Firestore.
  final int calories;
  /// مثال: وسط
  final String portionSize;
  /// مثال: 100% عضوي
  final String natureLabel;
  /// أنشطة الظهور (فارغ = كل الأنشطة).
  final List<String> activityTypeIds;

  bool get isInStock => isAvailable && (!trackStock || stockQuantity > 0);

  /// أقصى كمية مسموحة للعميل: الحد الأدنى بين مخزون المنتج وحد العميل (إن وُجد).
  int get maxOrderQuantity {
    const systemCap = 99;
    final customerCap =
        maxPerCustomer > 0 ? maxPerCustomer.clamp(1, systemCap) : systemCap;
    if (trackStock) {
      final stockCap = stockQuantity.clamp(0, systemCap);
      return stockCap < customerCap ? stockCap : customerCap;
    }
    return customerCap;
  }

  double get effectiveDiscountPercent {
    if (discountPercent > 0) return discountPercent;
    if (oldPrice > price && oldPrice > 0) {
      return ((oldPrice - price) / oldPrice) * 100;
    }
    return 0;
  }

  String? get badgeLabel {
    if (!isInStock) return null;
    if (bestSeller) return 'الأكثر مبيعاً';
    if (isNew) return 'جديد';
    if (effectiveDiscountPercent > 0) {
      return 'خصم ${effectiveDiscountPercent.round()}%';
    }
    if (isFeatured) return 'مميز';
    return null;
  }

  factory Product.fromFirestore({
    required String storeId,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) => Product.fromMap(
    storeId: storeId,
    id: doc.id,
    data: doc.data() ?? const {},
  );

  factory Product.fromMap({
    required String storeId,
    required String id,
    required Map<String, dynamic> data,
  }) {
    final addonsRaw = data['addons'] as List? ?? [];
    return Product(
      id: id,
      storeId: storeId,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String?,
      imageUrl: normalizeStoredImageUrl(data['imageUrl'] as String?),
      imageThumbUrl: normalizeStoredImageUrl(data['imageThumbUrl'] as String?),
      isAvailable: data['isAvailable'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      ingredients: List<String>.from(data['ingredients'] as List? ?? []),
      addons: addonsRaw
          .map((e) => ProductAddon.fromMap(Map<String, dynamic>.from(e as Map)))
          .where((a) => a.id.isNotEmpty && a.name.isNotEmpty)
          .toList(),
      trackStock: data['trackStock'] as bool? ?? false,
      stockQuantity: data['stockQuantity'] as int? ?? 0,
      maxPerCustomer: (data['maxPerCustomer'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? '',
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0,
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0,
      bestSeller: data['bestSeller'] as bool? ?? false,
      isNew: data['isNew'] as bool? ?? false,
      isFeatured: data['isFeatured'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List? ?? const []),
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      preparationTime: (data['preparationTime'] as num?)?.toInt() ?? 0,
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      ordersCount: (data['ordersCount'] as num?)?.toInt() ?? 0,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      portionSize: data['portionSize'] as String? ??
          data['size'] as String? ??
          '',
      natureLabel: data['natureLabel'] as String? ??
          data['nature'] as String? ??
          '',
      activityTypeIds: ActivityScopeUtils.readIds(data['activityTypeIds']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'isAvailable': isAvailable,
      'sortOrder': sortOrder,
      'ingredients': ingredients,
      'addons': addons.map((a) => a.toMap()).toList(),
      'trackStock': trackStock,
      'stockQuantity': stockQuantity,
      'maxPerCustomer': maxPerCustomer,
      'category': category,
      'oldPrice': oldPrice,
      'discountPercent': discountPercent,
      'bestSeller': bestSeller,
      'isNew': isNew,
      'isFeatured': isFeatured,
      'tags': tags,
      'reviewCount': reviewCount,
      'rating': rating,
      'preparationTime': preparationTime,
      'viewsCount': viewsCount,
      'ordersCount': ordersCount,
      if (calories > 0) 'calories': calories,
      if (portionSize.isNotEmpty) 'portionSize': portionSize,
      if (natureLabel.isNotEmpty) 'natureLabel': natureLabel,
      'activityTypeIds': activityTypeIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Product copyWith({
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    String? imageThumbUrl,
    bool? isAvailable,
    int? sortOrder,
    List<String>? ingredients,
    List<ProductAddon>? addons,
    bool? trackStock,
    int? stockQuantity,
    int? maxPerCustomer,
    String? category,
    double? oldPrice,
    double? discountPercent,
    bool? bestSeller,
    bool? isNew,
    bool? isFeatured,
    List<String>? tags,
    int? reviewCount,
    double? rating,
    int? preparationTime,
    int? viewsCount,
    int? ordersCount,
    int? calories,
    String? portionSize,
    String? natureLabel,
    List<String>? activityTypeIds,
    bool clearImage = false,
  }) {
    return Product(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      imageThumbUrl: clearImage ? null : (imageThumbUrl ?? this.imageThumbUrl),
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      ingredients: ingredients ?? this.ingredients,
      addons: addons ?? this.addons,
      trackStock: trackStock ?? this.trackStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      maxPerCustomer: maxPerCustomer ?? this.maxPerCustomer,
      category: category ?? this.category,
      oldPrice: oldPrice ?? this.oldPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      bestSeller: bestSeller ?? this.bestSeller,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      reviewCount: reviewCount ?? this.reviewCount,
      rating: rating ?? this.rating,
      preparationTime: preparationTime ?? this.preparationTime,
      viewsCount: viewsCount ?? this.viewsCount,
      ordersCount: ordersCount ?? this.ordersCount,
      calories: calories ?? this.calories,
      portionSize: portionSize ?? this.portionSize,
      natureLabel: natureLabel ?? this.natureLabel,
      activityTypeIds: activityTypeIds ?? this.activityTypeIds,
    );
  }
}
