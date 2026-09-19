import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:matlobgo/models/order_line_item.dart';

enum OrderStatus {
  pending,
  preparing,
  readyForPickup,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'قيد المراجعة',
    OrderStatus.preparing => 'جاري التحضير',
    OrderStatus.readyForPickup => 'جاهز للتوصيل',
    OrderStatus.onTheWay => 'خرج للتوصيل',
    OrderStatus.delivered => 'تم التوصيل',
    OrderStatus.cancelled => 'ملغي',
  };

  Color get color => switch (this) {
    OrderStatus.pending => const Color(0xFF2F5D8C), // info
    OrderStatus.preparing => const Color(0xFF8E6D2F), // gold deep
    OrderStatus.readyForPickup => const Color(0xFF00897B),
    OrderStatus.onTheWay => const Color(0xFF5C4B8A),
    OrderStatus.delivered => const Color(0xFF1B7A4E), // success
    OrderStatus.cancelled => const Color(0xFFC62828), // error
  };

  IconData get icon => switch (this) {
    OrderStatus.pending => Icons.hourglass_top_rounded,
    OrderStatus.preparing => Icons.inventory_2_rounded,
    OrderStatus.readyForPickup => Icons.shopping_bag_rounded,
    OrderStatus.onTheWay => Icons.delivery_dining_rounded,
    OrderStatus.delivered => Icons.check_circle_rounded,
    OrderStatus.cancelled => Icons.cancel_rounded,
  };

  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.preparing ||
      this == OrderStatus.readyForPickup ||
      this == OrderStatus.onTheWay;

  String get firestoreValue => name;

  /// Admin/store panel — تحكم كامل بالحالات بدون اعتماد على تطبيق السائق.
  List<OrderStatus> get allowedAdminTransitions => switch (this) {
    OrderStatus.pending => [
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.onTheWay,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ],
    OrderStatus.preparing => [
      OrderStatus.readyForPickup,
      OrderStatus.onTheWay,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ],
    OrderStatus.readyForPickup => [
      OrderStatus.onTheWay,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ],
    OrderStatus.onTheWay => [
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ],
    OrderStatus.delivered => const [],
    OrderStatus.cancelled => const [],
  };

  bool canAdminTransitionTo(OrderStatus next) =>
      next == this || allowedAdminTransitions.contains(next);

  /// الخطوة التالية المقترحة لمسار المتجر (بدون سائق).
  OrderStatus? get suggestedAdminNextStep => switch (this) {
    OrderStatus.pending => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.readyForPickup,
    OrderStatus.readyForPickup => OrderStatus.onTheWay,
    OrderStatus.onTheWay => OrderStatus.delivered,
    _ => null,
  };

  String get suggestedAdminNextStepLabel => switch (suggestedAdminNextStep) {
    OrderStatus.preparing => 'بدء التحضير',
    OrderStatus.readyForPickup => 'جاهز للتوصيل',
    OrderStatus.onTheWay => 'خرج للتوصيل',
    OrderStatus.delivered => 'تم التوصيل',
    _ => '',
  };

  static OrderStatus fromFirestore(String? value) {
    if (value == null || value.isEmpty) return OrderStatus.pending;
    // Cloud Function `advanceDeliveryPhase` writes `outForDelivery` when en route.
    if (value == 'outForDelivery') return OrderStatus.onTheWay;
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.storeName,
    required this.category,
    required this.itemsSummary,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.createdAt,
    this.deliveryFee = 0,
    this.storeId = '',
    this.customerId = '',
    this.customerName = '',
    this.governorate = '',
    this.deliveryId,
    this.deliveryName,
    this.deliveryPhone,
    this.deliveryVehicleType,
    this.address,
    this.addressLat,
    this.addressLng,
    this.addressPlaceId,
    this.addressFormatted,
    this.phone,
    this.driverRating,
    this.driverRatedAt,
    this.lineItems = const [],
    this.assignmentStatus,
    this.deliveryPhase,
    this.offeredDriverId,
    this.offeredAt,
    this.deliveryAcceptedAt,
    this.deliveryPickedUpAt,
    this.deliveryDeliveredAt,
    this.couponCode,
    this.discountAmount = 0,
    this.serviceFee = 0,
    this.paymentFee = 0,
    this.taxes = 0,
    this.authoritativeGrandTotal = 0,
    this.rawDeliveryFee = 0,
    this.distanceKm = 0,
    this.etaMinutes = 0,
    this.currency = 'EGP',
    this.paymentMethod = 'cash',
    this.orderNote = '',
    this.deliveryRejectReason,
    this.storeLat,
    this.storeLng,
    this.watchdogWarningAt,
    this.watchdogCriticalAt,
    this.updatedAt,
    this.storeImageUrl = '',
    this.storeRating = 0,
    this.storeVerified = false,
  });

  final String id;
  final String storeName;
  /// معرف تصنيف المورد (أو قيمة قديمة للطلبات السابقة).
  final String category;
  final String itemsSummary;
  final int itemCount;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final double deliveryFee;
  final String storeId;
  final String customerId;
  final String customerName;
  final String governorate;
  final String? deliveryId;
  final String? deliveryName;
  final String? deliveryPhone;
  final String? deliveryVehicleType;
  final String? address;
  final double? addressLat;
  final double? addressLng;
  final String? addressPlaceId;
  final String? addressFormatted;
  final String? phone;

  bool get hasDeliveryCoordinates =>
      addressLat != null &&
      addressLng != null &&
      addressLat != 0 &&
      addressLng != 0;
  final int? driverRating;
  final DateTime? driverRatedAt;
  final List<OrderLineItem> lineItems;
  final String? assignmentStatus;
  final String? deliveryPhase;
  final String? offeredDriverId;
  final DateTime? offeredAt;
  final DateTime? deliveryAcceptedAt;
  final DateTime? deliveryPickedUpAt;
  final DateTime? deliveryDeliveredAt;
  final String? couponCode;
  final double discountAmount;
  final double serviceFee;
  final double paymentFee;
  final double taxes;
  final double authoritativeGrandTotal;
  final double rawDeliveryFee;
  final double distanceKm;
  final int etaMinutes;
  final String currency;
  final String paymentMethod;
  final String orderNote;
  final String? deliveryRejectReason;
  final double? storeLat;
  final double? storeLng;
  final DateTime? watchdogWarningAt;
  final DateTime? watchdogCriticalAt;
  final DateTime? updatedAt;
  /// لوجو المورد وقت إنشاء الطلب (اختياري).
  final String storeImageUrl;
  final double storeRating;
  final bool storeVerified;

  bool get canCustomerCancel =>
      status == OrderStatus.pending ||
      status == OrderStatus.preparing ||
      status == OrderStatus.readyForPickup;

  double get payableTotal => grandTotal;

  bool get hasAssignedDriver => deliveryId != null && deliveryId!.isNotEmpty;

  bool get canRateDriver =>
      status == OrderStatus.delivered &&
      deliveryId != null &&
      deliveryId!.isNotEmpty &&
      driverRating == null;

  double get grandTotal {
    if (authoritativeGrandTotal > 0) return authoritativeGrandTotal;
    return (total +
            deliveryFee +
            serviceFee +
            paymentFee +
            taxes -
            discountAmount)
        .clamp(0, double.infinity);
  }

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Order(
      id: doc.id,
      storeId: data['storeId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      category: (data['category'] as String?)?.trim() ?? '',
      itemsSummary: data['itemsSummary'] as String? ?? '',
      itemCount: data['itemCount'] as int? ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      status: OrderStatusX.fromFirestore(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      governorate: data['governorate'] as String? ?? '',
      deliveryId: data['deliveryId'] as String?,
      deliveryName: data['deliveryName'] as String?,
      deliveryPhone: data['deliveryPhone'] as String?,
      deliveryVehicleType: data['deliveryVehicleType'] as String?,
      address: data['address'] as String?,
      addressLat: (data['addressLat'] as num?)?.toDouble(),
      addressLng: (data['addressLng'] as num?)?.toDouble(),
      addressPlaceId: data['addressPlaceId'] as String?,
      addressFormatted: data['addressFormatted'] as String?,
      phone: data['phone'] as String?,
      driverRating: data['driverRating'] as int?,
      driverRatedAt: (data['driverRatedAt'] as Timestamp?)?.toDate(),
      lineItems: _parseLineItems(data['lineItems']),
      assignmentStatus: data['assignmentStatus'] as String?,
      deliveryPhase: data['deliveryPhase'] as String?,
      offeredDriverId: data['offeredDriverId'] as String?,
      offeredAt: (data['offeredAt'] as Timestamp?)?.toDate(),
      deliveryAcceptedAt: (data['deliveryAcceptedAt'] as Timestamp?)?.toDate(),
      deliveryPickedUpAt: (data['deliveryPickedUpAt'] as Timestamp?)?.toDate(),
      deliveryDeliveredAt: (data['deliveryDeliveredAt'] as Timestamp?)
          ?.toDate(),
      couponCode: data['couponCode'] as String?,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
      serviceFee: (data['serviceFee'] as num?)?.toDouble() ?? 0,
      paymentFee: (data['paymentFee'] as num?)?.toDouble() ?? 0,
      taxes: (data['taxes'] as num?)?.toDouble() ?? 0,
      authoritativeGrandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0,
      rawDeliveryFee: (data['rawDeliveryFee'] as num?)?.toDouble() ?? 0,
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      etaMinutes: (data['etaMinutes'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'EGP',
      paymentMethod: data['paymentMethod'] as String? ?? 'cash',
      orderNote: data['orderNote'] as String? ?? '',
      deliveryRejectReason: data['deliveryRejectReason'] as String?,
      storeLat: (data['storeLat'] as num?)?.toDouble(),
      storeLng: (data['storeLng'] as num?)?.toDouble(),
      watchdogWarningAt: (data['watchdogWarningAt'] as Timestamp?)?.toDate(),
      watchdogCriticalAt: (data['watchdogCriticalAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      storeImageUrl: data['storeImageUrl'] as String? ?? '',
      storeRating: (data['storeRating'] as num?)?.toDouble() ?? 0,
      storeVerified: data['storeVerified'] as bool? ?? false,
    );
  }

  static List<OrderLineItem> _parseLineItems(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => OrderLineItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'category': category,
      'itemsSummary': itemsSummary,
      'itemCount': itemCount,
      'total': total,
      'deliveryFee': deliveryFee,
      'status': status.firestoreValue,
      'customerId': customerId,
      'customerName': customerName,
      'governorate': governorate,
      if (deliveryId != null && deliveryId!.isNotEmpty)
        'deliveryId': deliveryId,
      if (deliveryName != null && deliveryName!.isNotEmpty)
        'deliveryName': deliveryName,
      if (deliveryPhone != null && deliveryPhone!.isNotEmpty)
        'deliveryPhone': deliveryPhone,
      if (deliveryVehicleType != null && deliveryVehicleType!.isNotEmpty)
        'deliveryVehicleType': deliveryVehicleType,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (addressLat != null) 'addressLat': addressLat,
      if (addressLng != null) 'addressLng': addressLng,
      if (addressPlaceId != null && addressPlaceId!.isNotEmpty)
        'addressPlaceId': addressPlaceId,
      if (addressFormatted != null && addressFormatted!.isNotEmpty)
        'addressFormatted': addressFormatted,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (driverRating != null) 'driverRating': driverRating,
      if (driverRatedAt != null)
        'driverRatedAt': Timestamp.fromDate(driverRatedAt!),
      if (lineItems.isNotEmpty)
        'lineItems': lineItems.map((e) => e.toMap()).toList(),
      if (couponCode != null && couponCode!.isNotEmpty)
        'couponCode': couponCode,
      if (discountAmount > 0) 'discountAmount': discountAmount,
      if (serviceFee > 0) 'serviceFee': serviceFee,
      if (paymentFee > 0) 'paymentFee': paymentFee,
      if (taxes > 0) 'taxes': taxes,
      'grandTotal': grandTotal,
      if (rawDeliveryFee > 0) 'rawDeliveryFee': rawDeliveryFee,
      if (distanceKm > 0) 'distanceKm': distanceKm,
      if (etaMinutes > 0) 'etaMinutes': etaMinutes,
      'currency': currency,
      'paymentMethod': paymentMethod,
      if (orderNote.isNotEmpty) 'orderNote': orderNote,
      if (storeLat != null) 'storeLat': storeLat,
      if (storeLng != null) 'storeLng': storeLng,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Order copyWith({
    String? id,
    OrderStatus? status,
    double? total,
    double? deliveryFee,
    double? discountAmount,
    double? serviceFee,
    double? paymentFee,
    double? taxes,
    double? authoritativeGrandTotal,
    double? rawDeliveryFee,
    double? distanceKm,
    int? etaMinutes,
    String? currency,
    String? deliveryId,
    String? deliveryName,
    String? deliveryPhone,
    String? deliveryVehicleType,
    int? driverRating,
    DateTime? driverRatedAt,
    List<OrderLineItem>? lineItems,
  }) {
    return Order(
      id: id ?? this.id,
      storeName: storeName,
      category: category,
      itemsSummary: itemsSummary,
      itemCount: itemCount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      storeId: storeId,
      customerId: customerId,
      customerName: customerName,
      governorate: governorate,
      deliveryId: deliveryId ?? this.deliveryId,
      deliveryName: deliveryName ?? this.deliveryName,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      deliveryVehicleType: deliveryVehicleType ?? this.deliveryVehicleType,
      address: address,
      addressLat: addressLat,
      addressLng: addressLng,
      addressPlaceId: addressPlaceId,
      addressFormatted: addressFormatted,
      phone: phone,
      driverRating: driverRating ?? this.driverRating,
      driverRatedAt: driverRatedAt ?? this.driverRatedAt,
      lineItems: lineItems ?? this.lineItems,
      assignmentStatus: assignmentStatus,
      deliveryPhase: deliveryPhase,
      offeredDriverId: offeredDriverId,
      offeredAt: offeredAt,
      deliveryAcceptedAt: deliveryAcceptedAt,
      deliveryPickedUpAt: deliveryPickedUpAt,
      deliveryDeliveredAt: deliveryDeliveredAt,
      couponCode: couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      paymentFee: paymentFee ?? this.paymentFee,
      taxes: taxes ?? this.taxes,
      authoritativeGrandTotal:
          authoritativeGrandTotal ?? this.authoritativeGrandTotal,
      rawDeliveryFee: rawDeliveryFee ?? this.rawDeliveryFee,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod,
      orderNote: orderNote,
      deliveryRejectReason: deliveryRejectReason,
      storeLat: storeLat,
      storeLng: storeLng,
      watchdogWarningAt: watchdogWarningAt,
      watchdogCriticalAt: watchdogCriticalAt,
      updatedAt: updatedAt,
      storeImageUrl: storeImageUrl,
      storeRating: storeRating,
      storeVerified: storeVerified,
    );
  }
}
