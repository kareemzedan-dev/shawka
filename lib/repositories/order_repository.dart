import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/order.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.orders);

  Stream<List<Order>> watchOrdersByGovernorate({
    required String governorate,
    OrderStatus? status,
  }) {
    return _collection
        .where('governorate', isEqualTo: governorate)
        .snapshots()
        .map((snap) {
          var orders = snap.docs.map(Order.fromFirestore).toList();
          if (status != null) {
            orders = orders.where((o) => o.status == status).toList();
          }
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// طلبات متاجر محددة (لصاحب المتجر). Firestore `in` بحد أقصى 10.
  Stream<List<Order>> watchOrdersByStoreIds({
    required List<String> storeIds,
    OrderStatus? status,
  }) {
    final ids = storeIds.where((id) => id.isNotEmpty).take(10).toList();
    if (ids.isEmpty) {
      return Stream.value(const <Order>[]);
    }
    return _collection.where('storeId', whereIn: ids).snapshots().map((snap) {
      var orders = snap.docs.map(Order.fromFirestore).toList();
      if (status != null) {
        orders = orders.where((o) => o.status == status).toList();
      }
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> updateStatus(String orderId, OrderStatus status) {
    final data = <String, dynamic>{
      'status': status.firestoreValue,
      'fulfillmentMode': 'admin',
      'skipDriverAssignment': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    switch (status) {
      case OrderStatus.pending:
        data['deliveryPhase'] = FieldValue.delete();
        data['assignmentStatus'] = FieldValue.delete();
        break;
      case OrderStatus.preparing:
        data['deliveryPhase'] = 'preparing';
        data['assignmentStatus'] = 'manual';
        break;
      case OrderStatus.readyForPickup:
        data['deliveryPhase'] = 'readyForPickup';
        data['assignmentStatus'] = 'manual';
        break;
      case OrderStatus.onTheWay:
        // متوافق مع مسار السائق القديم في التطبيق.
        data['status'] = 'outForDelivery';
        data['deliveryPhase'] = 'outForDelivery';
        data['assignmentStatus'] = 'manual';
        break;
      case OrderStatus.delivered:
        data['deliveryPhase'] = 'delivered';
        data['assignmentStatus'] = 'completed';
        break;
      case OrderStatus.cancelled:
        data['deliveryPhase'] = 'cancelled';
        data['assignmentStatus'] = 'cancelled';
        break;
    }

    return _collection.doc(orderId).update(data);
  }

  Future<void> assignDelivery({
    required String orderId,
    required String deliveryId,
    required String deliveryName,
  }) {
    return _collection.doc(orderId).update({
      'deliveryId': deliveryId,
      'deliveryName': deliveryName,
      'status': OrderStatus.onTheWay.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearDelivery(String orderId) {
    return _collection.doc(orderId).update({
      'deliveryId': FieldValue.delete(),
      'deliveryName': FieldValue.delete(),
      'deliveryPhone': FieldValue.delete(),
      'deliveryVehicleType': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Order>> watchByCustomer(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
          final orders = snap.docs.map(Order.fromFirestore).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Future<String> createOrder(Order order) async {
    final created = await createOrders([order]);
    return created.single.id;
  }

  /// إنشاء checkout كامل ذريًا عبر Cloud Function. يحتفظ بالـ API القديم
  /// `createOrder` للتوافق، لكن لا توجد أي كتابة طلب حساسة من العميل.
  Future<List<Order>> createOrders(
    List<Order> drafts, {
    String? checkoutRequestId,
  }) async {
    if (drafts.isEmpty) return const [];
    final result = await _functions
        .httpsCallable(
          'createCustomerOrders',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
        )
        .call(_checkoutPayload(drafts, checkoutRequestId: checkoutRequestId));

    final raw = result.data;
    if (raw is! Map) {
      throw StateError('Invalid createCustomerOrders response');
    }
    final data = Map<String, dynamic>.from(raw);
    final serverOrders = (data['orders'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    if (serverOrders.length != drafts.length) {
      throw StateError('Invalid createCustomerOrders response');
    }

    return List.generate(drafts.length, (index) {
      final server = serverOrders[index];
      return drafts[index].copyWith(
        id: server['id'] as String? ?? '',
        total: (server['total'] as num?)?.toDouble(),
        deliveryFee: (server['deliveryFee'] as num?)?.toDouble(),
        discountAmount: (server['discountAmount'] as num?)?.toDouble(),
        serviceFee: (server['serviceFee'] as num?)?.toDouble(),
        paymentFee: (server['paymentFee'] as num?)?.toDouble(),
        taxes: (server['taxes'] as num?)?.toDouble(),
        authoritativeGrandTotal: (server['grandTotal'] as num?)?.toDouble(),
        rawDeliveryFee: (server['rawDeliveryFee'] as num?)?.toDouble(),
        distanceKm: (server['distanceKm'] as num?)?.toDouble(),
        etaMinutes: (server['etaMinutes'] as num?)?.toInt(),
      );
    });
  }

  /// معاينة خادمية read-only للأسعار والتوفر قبل إنشاء الطلب.
  Future<CheckoutQuote> previewCheckout(List<Order> drafts) async {
    if (drafts.isEmpty) {
      throw ArgumentError.value(drafts, 'drafts', 'Checkout cannot be empty');
    }
    final result = await _functions
        .httpsCallable(
          'previewCustomerCheckout',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call(_checkoutPayload(drafts));
    final raw = result.data;
    if (raw is! Map) {
      throw StateError('Invalid previewCustomerCheckout response');
    }
    return CheckoutQuote.fromCallable(Map<String, dynamic>.from(raw));
  }

  Map<String, dynamic> _checkoutPayload(
    List<Order> drafts, {
    String? checkoutRequestId,
  }) {
    final first = drafts.first;
    return {
      if (checkoutRequestId != null && checkoutRequestId.isNotEmpty)
        'checkoutRequestId': checkoutRequestId,
      'customerName': first.customerName,
      'phone': first.phone,
      'governorate': first.governorate,
      'address': first.address,
      'addressLat': first.addressLat,
      'addressLng': first.addressLng,
      'addressPlaceId': first.addressPlaceId,
      'addressFormatted': first.addressFormatted,
      'paymentMethod': first.paymentMethod,
      'couponCode': first.couponCode,
      if (first.orderNote.isNotEmpty) 'orderNote': first.orderNote,
      'orders': drafts
          .map(
            (order) => {
              'storeId': order.storeId,
              'category': order.category,
              'lineItems': order.lineItems
                  .map(
                    (line) => {
                      'productId': line.productId,
                      'quantity': line.quantity,
                      'addonIds': line.addonIds,
                      'note': line.note,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }
}
