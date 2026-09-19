import 'package:cloud_firestore/cloud_firestore.dart';

enum AnalyticsEventType {
  appOpen,
  sessionStart,
  sessionEnd,
  screenView,
  storeView,
  productView,
  addToCart,
  removeFromCart,
  cartOpen,
  cartQuantityChange,
  applyCoupon,
  removeCoupon,
  continueToCheckout,
  addSuggestionToCart,
  freeDeliveryUnlocked,
  checkoutStart,
  orderPlaced,
  favoriteToggle,
  productShare,
  productQuantityChange,
  ordersOpen,
  orderExpand,
  orderTrack,
  orderReorder,
  orderRate,
  orderCancel,
  orderInvoice,
  searchOpen,
  searchQuery,
  searchSuggestion,
  searchFilter,
  searchClearRecent,
}

extension AnalyticsEventTypeX on AnalyticsEventType {
  String get firestoreValue => name;

  String get label => switch (this) {
        AnalyticsEventType.appOpen => 'فتح التطبيق',
        AnalyticsEventType.sessionStart => 'بداية جلسة',
        AnalyticsEventType.sessionEnd => 'نهاية جلسة',
        AnalyticsEventType.screenView => 'عرض شاشة',
        AnalyticsEventType.storeView => 'فتح متجر',
        AnalyticsEventType.productView => 'عرض منتج',
        AnalyticsEventType.addToCart => 'إضافة للسلة',
        AnalyticsEventType.removeFromCart => 'حذف من السلة',
        AnalyticsEventType.cartOpen => 'فتح السلة',
        AnalyticsEventType.cartQuantityChange => 'تعديل كمية',
        AnalyticsEventType.applyCoupon => 'تطبيق كوبون',
        AnalyticsEventType.removeCoupon => 'إزالة كوبون',
        AnalyticsEventType.continueToCheckout => 'متابعة الطلب',
        AnalyticsEventType.addSuggestionToCart => 'إضافة من المقترحات',
        AnalyticsEventType.freeDeliveryUnlocked => 'الوصول للتوصيل المجاني',
        AnalyticsEventType.checkoutStart => 'بدء الدفع',
        AnalyticsEventType.orderPlaced => 'طلب مكتمل',
        AnalyticsEventType.favoriteToggle => 'تبديل المفضلة',
        AnalyticsEventType.productShare => 'مشاركة منتج',
        AnalyticsEventType.productQuantityChange => 'تعديل كمية المنتج',
        AnalyticsEventType.ordersOpen => 'فتح الطلبات',
        AnalyticsEventType.orderExpand => 'توسيع تفاصيل الطلب',
        AnalyticsEventType.orderTrack => 'تتبع الطلب',
        AnalyticsEventType.orderReorder => 'إعادة الطلب',
        AnalyticsEventType.orderRate => 'تقييم الطلب',
        AnalyticsEventType.orderCancel => 'إلغاء الطلب',
        AnalyticsEventType.orderInvoice => 'فتح الفاتورة',
        AnalyticsEventType.searchOpen => 'فتح البحث',
        AnalyticsEventType.searchQuery => 'استعلام بحث',
        AnalyticsEventType.searchSuggestion => 'اقتراح بحث',
        AnalyticsEventType.searchFilter => 'فلتر بحث',
        AnalyticsEventType.searchClearRecent => 'مسح سجل البحث',
      };

  static AnalyticsEventType fromFirestore(String? value) {
    return AnalyticsEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalyticsEventType.screenView,
    );
  }
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.screen,
    required this.label,
    required this.createdAt,
    this.storeId = '',
    this.storeName = '',
    this.productId = '',
    this.productName = '',
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String userName;
  final AnalyticsEventType type;
  final String screen;
  final String label;
  final DateTime createdAt;
  final String storeId;
  final String storeName;
  final String productId;
  final String productName;
  final Map<String, dynamic> metadata;

  factory AnalyticsEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AnalyticsEvent(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      type: AnalyticsEventTypeX.fromFirestore(data['type'] as String?),
      screen: data['screen'] as String? ?? '',
      label: data['label'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      storeId: data['storeId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.firestoreValue,
      'screen': screen,
      'label': label,
      'storeId': storeId,
      'storeName': storeName,
      'productId': productId,
      'productName': productName,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
