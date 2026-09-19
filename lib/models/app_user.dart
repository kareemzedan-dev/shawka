import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/models/admin_staff_role.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/services/presence_service.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.isGuest,
    required this.createdAt,
    this.role = UserRole.customer,
    this.phone = '',
    this.activityTypeId = '',
    this.activityTypeName = '',
    this.proofImageUrl = '',
    this.proofImageThumbUrl = '',
    this.address = '',
    this.customerApprovalStatus = '',
    this.customerApprovalNote = '',
    this.signupComplete = true,
    this.hasPassword = false,
    this.lastPaymentMethod = '',
    this.isActive = true,
    this.governorate = '',
    this.staffRole = AdminStaffRole.admin,
    this.managedStoreIds = const [],
    this.lastActiveAt,
    this.fcmTokenUpdatedAt,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.avgDriverRating = 0,
    this.driverRatingCount = 0,
    this.gpsTrustStatus = '',
    this.vehicleType = '',
    this.isDriverOnline = false,
    this.acceptRate,
    this.driverPerformanceScore,
    this.completedOrderCount = 0,
    this.avgDeliveryMinutes,
    this.heartbeatAt,
    this.activeOrderId,
    this.offerCooldownUntil,
    this.earningsBalance = 0,
    this.outstandingBalance = 0,
    this.netBalance = 0,
    this.driverCashBlocked = false,
    this.walletStatus = 'regular',
    this.lastSettlementAt,
  });

  final String uid;
  final String name;
  final String email;
  final bool isGuest;
  final DateTime createdAt;
  final UserRole role;
  final String phone;
  /// نوع نشاط العميل (كافيه / مطعم / …) من `customer_activity_types`.
  final String activityTypeId;
  final String activityTypeName;
  /// صورة إثبات المكان/النشاط (فندق، ماركت، …).
  final String proofImageUrl;
  final String proofImageThumbUrl;
  /// عنوان المكان بالتفصيل (إلزامي عند التسجيل).
  final String address;
  /// `incomplete` | `pending` | `approved` | `rejected` — فارغ للحسابات القديمة.
  final String customerApprovalStatus;
  final String customerApprovalNote;
  /// `false` بعد OTP/كلمة المرور وقبل إكمال الإثبات+العنوان.
  /// الافتراضي `true` للحسابات القديمة بلا الحقل.
  final bool signupComplete;
  final bool hasPassword;
  final String lastPaymentMethod;
  final bool isActive;
  final String governorate;
  final AdminStaffRole staffRole;
  /// متاجر يديرها صاحب المتجر (`staffRole == storeManager`).
  final List<String> managedStoreIds;
  final DateTime? lastActiveAt;
  final DateTime? fcmTokenUpdatedAt;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  final double avgDriverRating;
  final int driverRatingCount;
  final String gpsTrustStatus;
  final String vehicleType;
  final bool isDriverOnline;
  final double? acceptRate;
  final int? driverPerformanceScore;
  final int completedOrderCount;
  final double? avgDeliveryMinutes;
  final DateTime? heartbeatAt;
  final String? activeOrderId;
  final DateTime? offerCooldownUntil;
  final double earningsBalance;
  final double outstandingBalance;
  final double netBalance;
  final bool driverCashBlocked;
  final String walletStatus;
  final DateTime? lastSettlementAt;

  bool get isOnOfferCooldown =>
      offerCooldownUntil != null &&
      DateTime.now().isBefore(offerCooldownUntil!);

  int get offerCooldownMinutesRemaining {
    if (!isOnOfferCooldown) return 0;
    return offerCooldownUntil!
        .difference(DateTime.now())
        .inMinutes
        .clamp(0, 999);
  }

  bool get isDriverOnlineEffective => isDriverOnline || isOnline;

  bool get isGpsTrusted =>
      gpsTrustStatus.isEmpty || gpsTrustStatus == 'trusted';

  bool get isAdmin => role == UserRole.admin;
  bool get isDelivery => role == UserRole.delivery;

  /// تسجيل توقّف قبل إكمال الإثبات/العنوان (لا يُسمح بدخول التطبيق).
  bool get isCustomerSignupIncomplete {
    if (role != UserRole.customer || isGuest) return false;
    final status = customerApprovalStatus.trim();
    if (status == 'incomplete') return true;
    if (!signupComplete) return true;
    // جلسة مهجورة قبل نشر حقل signupComplete: باسورد محفوظ بلا إثبات.
    if (hasPassword &&
        status.isEmpty &&
        proofImageUrl.trim().isEmpty) {
      return true;
    }
    return false;
  }

  /// عميل بانتظار موافقة الأدمن بعد التسجيل بالصورة.
  bool get isCustomerPendingApproval =>
      role == UserRole.customer &&
      !isGuest &&
      signupComplete &&
      customerApprovalStatus == 'pending';

  /// عميل مسموح له باستخدام التطبيق (معتمد ونشط، أو ضيف، أو حساب قديم مكتمل).
  bool get isCustomerApprovedForApp {
    if (role != UserRole.customer || isGuest) return true;
    if (isCustomerSignupIncomplete) return false;
    if (customerApprovalStatus == 'pending') return false;
    if (customerApprovalStatus == 'rejected') return false;
    if (customerApprovalStatus == 'approved') return isActive;
    // فارغ = حساب قديم مكتمل قبل نظام الموافقة.
    return isActive;
  }

  /// صاحب متجر مقيّد بمتاجر محددة.
  bool get isStoreOwner =>
      isAdmin && staffRole.isStoreScoped && managedStoreIds.isNotEmpty;

  bool get managesScopedStores =>
      isAdmin && staffRole.isStoreScoped;

  bool canManageStore(String storeId) {
    if (!isAdmin) return false;
    if (!staffRole.isStoreScoped) return true;
    return managedStoreIds.contains(storeId);
  }

  bool get isOnline => PresenceService.isOnline(lastActiveAt);

  bool get hasLiveLocation =>
      latitude != null &&
      longitude != null &&
      locationUpdatedAt != null &&
      DateTime.now().difference(locationUpdatedAt!) <
          const Duration(minutes: 10);

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final coords = _readCoords(data);
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isGuest: data['isGuest'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: UserRoleX.fromFirestore(
        data['role'] as String? ?? data['rule'] as String?,
      ),
      phone: data['phone'] as String? ?? '',
      activityTypeId: data['activityTypeId'] as String? ?? '',
      activityTypeName: data['activityTypeName'] as String? ?? '',
      proofImageUrl: data['proofImageUrl'] as String? ?? '',
      proofImageThumbUrl: data['proofImageThumbUrl'] as String? ?? '',
      address: data['address'] as String? ?? '',
      customerApprovalStatus: data['customerApprovalStatus'] as String? ?? '',
      customerApprovalNote: data['customerApprovalNote'] as String? ?? '',
      signupComplete: data['signupComplete'] as bool? ?? true,
      hasPassword: data['hasPassword'] as bool? ?? false,
      lastPaymentMethod: data['lastPaymentMethod'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      governorate: data['governorate'] as String? ?? '',
      staffRole: AdminStaffRoleX.fromFirestore(data['staffRole'] as String?),
      managedStoreIds: List<String>.from(
        data['managedStoreIds'] as List? ?? const [],
      ),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      fcmTokenUpdatedAt: (data['fcmTokenUpdatedAt'] as Timestamp?)?.toDate(),
      latitude: coords?.$1,
      longitude: coords?.$2,
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
      avgDriverRating: (data['avgDriverRating'] as num?)?.toDouble() ?? 0,
      driverRatingCount: data['driverRatingCount'] as int? ?? 0,
      gpsTrustStatus: data['gpsTrustStatus'] as String? ?? '',
      vehicleType: data['vehicleType'] as String? ?? '',
      isDriverOnline: data['isDriverOnline'] as bool? ?? false,
      acceptRate: (data['acceptRate'] as num?)?.toDouble(),
      driverPerformanceScore: data['driverPerformanceScore'] as int?,
      completedOrderCount: data['completedOrderCount'] as int? ?? 0,
      avgDeliveryMinutes: (data['avgDeliveryMinutes'] as num?)?.toDouble(),
      heartbeatAt: (data['heartbeatAt'] as Timestamp?)?.toDate(),
      activeOrderId: data['activeOrderId'] as String?,
      offerCooldownUntil: (data['offerCooldownUntil'] as Timestamp?)?.toDate(),
      earningsBalance: (data['earningsBalance'] as num?)?.toDouble() ?? 0,
      outstandingBalance: (data['outstandingBalance'] as num?)?.toDouble() ?? 0,
      netBalance:
          (data['netBalance'] as num?)?.toDouble() ??
          (((data['earningsBalance'] as num?)?.toDouble() ?? 0) -
              ((data['outstandingBalance'] as num?)?.toDouble() ?? 0)),
      driverCashBlocked: data['driverCashBlocked'] as bool? ?? false,
      walletStatus: data['walletStatus'] as String? ?? 'regular',
      lastSettlementAt: (data['lastSettlementAt'] as Timestamp?)?.toDate(),
    );
  }

  static (double, double)? _readCoords(Map<String, dynamic> data) {
    final location = data['location'];
    if (location is GeoPoint) {
      return (location.latitude, location.longitude);
    }
    if (location is Map) {
      final lat = location['latitude'] ?? location['lat'];
      final lng = location['longitude'] ?? location['lng'];
      if (lat is num && lng is num) {
        return (lat.toDouble(), lng.toDouble());
      }
    }
    final lat = data['latitude'];
    final lng = data['longitude'];
    if (lat is num && lng is num) {
      return (lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'isGuest': isGuest,
      'role': role.firestoreValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'phone': phone,
      'activityTypeId': activityTypeId,
      'activityTypeName': activityTypeName,
      'proofImageUrl': proofImageUrl,
      'proofImageThumbUrl': proofImageThumbUrl,
      'address': address,
      if (customerApprovalStatus.isNotEmpty)
        'customerApprovalStatus': customerApprovalStatus,
      'signupComplete': signupComplete,
      'isActive': isActive,
      'governorate': governorate,
    };
    if (isAdmin) {
      data['staffRole'] = staffRole.firestoreValue;
      data['managedStoreIds'] = managedStoreIds;
    }
    return data;
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? activityTypeId,
    String? activityTypeName,
    String? proofImageUrl,
    String? proofImageThumbUrl,
    String? address,
    String? customerApprovalStatus,
    String? customerApprovalNote,
    bool? signupComplete,
    bool? hasPassword,
    String? lastPaymentMethod,
    bool? isActive,
    String? governorate,
    AdminStaffRole? staffRole,
    List<String>? managedStoreIds,
    DateTime? lastActiveAt,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    double? avgDriverRating,
    int? driverRatingCount,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      isGuest: isGuest,
      createdAt: createdAt,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      activityTypeId: activityTypeId ?? this.activityTypeId,
      activityTypeName: activityTypeName ?? this.activityTypeName,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      proofImageThumbUrl: proofImageThumbUrl ?? this.proofImageThumbUrl,
      address: address ?? this.address,
      customerApprovalStatus:
          customerApprovalStatus ?? this.customerApprovalStatus,
      customerApprovalNote: customerApprovalNote ?? this.customerApprovalNote,
      signupComplete: signupComplete ?? this.signupComplete,
      hasPassword: hasPassword ?? this.hasPassword,
      lastPaymentMethod: lastPaymentMethod ?? this.lastPaymentMethod,
      isActive: isActive ?? this.isActive,
      governorate: governorate ?? this.governorate,
      staffRole: staffRole ?? this.staffRole,
      managedStoreIds: managedStoreIds ?? this.managedStoreIds,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      fcmTokenUpdatedAt: fcmTokenUpdatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      avgDriverRating: avgDriverRating ?? this.avgDriverRating,
      driverRatingCount: driverRatingCount ?? this.driverRatingCount,
      earningsBalance: earningsBalance,
      outstandingBalance: outstandingBalance,
      netBalance: netBalance,
      driverCashBlocked: driverCashBlocked,
      walletStatus: walletStatus,
      lastSettlementAt: lastSettlementAt,
    );
  }
}
