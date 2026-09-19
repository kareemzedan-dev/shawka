import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/config/branding/generated/branding_values.g.dart';
import 'package:matlobgo/models/bottom_nav_config.dart';
import 'package:matlobgo/models/cart_ui_settings.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';
import 'package:matlobgo/models/delivery_pricing_tier.dart';

enum AppBannerSeverity {
  error,
  warning,
  info;

  String get firestoreValue => name;

  static AppBannerSeverity fromFirestore(String? value) {
    return AppBannerSeverity.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AppBannerSeverity.warning,
    );
  }
}

/// إعدادات التطبيق العامة — مستند واحد في Firestore.
class AppSettings {
  const AppSettings({
    this.maintenanceMode = false,
    this.maintenanceTitle = 'وضع الصيانة',
    this.maintenanceMessage = 'التطبيق في وضع الصيانة — الطلبات متوقفة مؤقتاً',
    this.alertBannerEnabled = false,
    this.alertBannerTitle = '',
    this.alertBannerMessage = '',
    this.alertBannerSeverity = AppBannerSeverity.warning,
    this.alertBannerActionUrl = '',
    this.supportPhone = '',
    this.defaultDeliveryFee = 15,
    this.minOrderAmount = 50,
    this.welcomeMessage = 'مرحباً بك في ${BrandingValues.appName}',
    this.enableGuestCheckout = true,
    this.freeDeliveryThreshold = 300,
    this.enableDistanceBasedDeliveryFee = true,
    this.deliveryFeeBase = 10,
    this.deliveryFeePerKm = 2.5,
    this.deliveryMaxRadiusKm = 25,
    this.deliveryMaxRoadKm = 15,
    this.deliveryPricingTiers = DeliveryPricingTier.defaults,
    this.deliveryZoneLat = 30.0444,
    this.deliveryZoneLng = 31.2357,
    this.deliveryRoadFactor = 1.35,
    this.deliveryMinutesPerKm = 2.2,
    this.checkoutServiceFeeFixed = 0,
    this.checkoutServiceFeePercent = 0,
    this.checkoutTaxPercent = 0,
    this.enabledPaymentMethods = const ['cash'],
    this.checkoutPaymentMethods = fallbackPaymentMethods,
    this.cartUi = const CartUiSettings(),
    this.bottomNav = const BottomNavConfig(),
    this.platformCompletedOrders = 0,
    this.platformProductCount = 0,
  });

  final bool maintenanceMode;
  final String maintenanceTitle;
  final String maintenanceMessage;
  final bool alertBannerEnabled;
  final String alertBannerTitle;
  final String alertBannerMessage;
  final AppBannerSeverity alertBannerSeverity;
  final String alertBannerActionUrl;
  final String supportPhone;
  final double defaultDeliveryFee;
  final double minOrderAmount;
  final String welcomeMessage;
  final bool enableGuestCheckout;
  final double freeDeliveryThreshold;
  final bool enableDistanceBasedDeliveryFee;
  final double deliveryFeeBase;
  final double deliveryFeePerKm;
  final double deliveryMaxRadiusKm;
  final double deliveryMaxRoadKm;
  final List<DeliveryPricingTier> deliveryPricingTiers;
  final double deliveryZoneLat;
  final double deliveryZoneLng;
  final double deliveryRoadFactor;
  final double deliveryMinutesPerKm;
  final double checkoutServiceFeeFixed;
  final double checkoutServiceFeePercent;
  final double checkoutTaxPercent;
  final List<String> enabledPaymentMethods;
  final List<CheckoutPaymentMethod> checkoutPaymentMethods;
  final CartUiSettings cartUi;
  final BottomNavConfig bottomNav;

  /// إحصائية عامة للويب/التسويق (اختياري — من لوحة التحكم).
  final int platformCompletedOrders;
  final int platformProductCount;

  static const String documentId = 'config';
  static const List<CheckoutPaymentMethod> fallbackPaymentMethods = [
    CheckoutPaymentMethod(
      id: 'cash',
      name: 'الدفع عند الاستلام',
      description: 'ادفع نقداً عند استلام الطلب',
      isActive: true,
      sortOrder: 0,
    ),
  ];

  factory AppSettings.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => AppSettings.fromMap(doc.data() ?? const {});

  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      maintenanceMode: data['maintenanceMode'] as bool? ?? false,
      maintenanceTitle: data['maintenanceTitle'] as String? ?? 'وضع الصيانة',
      maintenanceMessage:
          data['maintenanceMessage'] as String? ??
          'التطبيق في وضع الصيانة — الطلبات متوقفة مؤقتاً',
      alertBannerEnabled: data['alertBannerEnabled'] as bool? ?? false,
      alertBannerTitle: data['alertBannerTitle'] as String? ?? '',
      alertBannerMessage: data['alertBannerMessage'] as String? ?? '',
      alertBannerSeverity: AppBannerSeverity.fromFirestore(
        data['alertBannerSeverity'] as String?,
      ),
      alertBannerActionUrl: data['alertBannerActionUrl'] as String? ?? '',
      supportPhone: data['supportPhone'] as String? ?? '',
      defaultDeliveryFee:
          (data['defaultDeliveryFee'] as num?)?.toDouble() ?? 15,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toDouble() ?? 50,
      welcomeMessage:
          data['welcomeMessage'] as String? ??
          'مرحباً بك في ${BrandingValues.appName}',
      enableGuestCheckout: data['enableGuestCheckout'] as bool? ?? true,
      freeDeliveryThreshold:
          (data['freeDeliveryThreshold'] as num?)?.toDouble() ?? 300,
      enableDistanceBasedDeliveryFee:
          data['enableDistanceBasedDeliveryFee'] as bool? ?? true,
      deliveryFeeBase: (data['deliveryFeeBase'] as num?)?.toDouble() ?? 10,
      deliveryFeePerKm: (data['deliveryFeePerKm'] as num?)?.toDouble() ?? 2.5,
      deliveryMaxRadiusKm:
          (data['deliveryMaxRadiusKm'] as num?)?.toDouble() ?? 25,
      deliveryMaxRoadKm: (data['deliveryMaxRoadKm'] as num?)?.toDouble() ?? 15,
      deliveryPricingTiers: DeliveryPricingTier.parseList(
        data['deliveryPricingTiers'] as List<dynamic>?,
      ),
      deliveryZoneLat: (data['deliveryZoneLat'] as num?)?.toDouble() ?? 30.0444,
      deliveryZoneLng: (data['deliveryZoneLng'] as num?)?.toDouble() ?? 31.2357,
      deliveryRoadFactor:
          (data['deliveryRoadFactor'] as num?)?.toDouble() ?? 1.35,
      deliveryMinutesPerKm:
          (data['deliveryMinutesPerKm'] as num?)?.toDouble() ?? 2.2,
      checkoutServiceFeeFixed:
          (data['checkoutServiceFeeFixed'] as num?)?.toDouble() ?? 0,
      checkoutServiceFeePercent:
          (data['checkoutServiceFeePercent'] as num?)?.toDouble() ?? 0,
      checkoutTaxPercent: (data['checkoutTaxPercent'] as num?)?.toDouble() ?? 0,
      enabledPaymentMethods: List<String>.from(
        data['enabledPaymentMethods'] as List? ?? const ['cash'],
      ),
      checkoutPaymentMethods: () {
        final parsed = (data['checkoutPaymentMethods'] as List?)
            ?.whereType<Map>()
            .map(
              (entry) => CheckoutPaymentMethod.fromMap(
                Map<String, dynamic>.from(entry),
              ),
            )
            .where((method) => method.id.isNotEmpty)
            .toList();
        if (parsed == null || parsed.isEmpty) {
          return fallbackPaymentMethods;
        }
        return parsed;
      }(),
      cartUi: CartUiSettings.fromMap(
        data['cartUi'] is Map
            ? Map<String, dynamic>.from(data['cartUi'] as Map)
            : null,
      ),
      bottomNav: BottomNavConfig.fromMap(
        data['bottomNav'] is Map
            ? Map<String, dynamic>.from(data['bottomNav'] as Map)
            : null,
      ),
      platformCompletedOrders:
          (data['platformCompletedOrders'] as num?)?.toInt() ?? 0,
      platformProductCount:
          (data['platformProductCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'maintenanceMode': maintenanceMode,
      'maintenanceTitle': maintenanceTitle,
      'maintenanceMessage': maintenanceMessage,
      'alertBannerEnabled': alertBannerEnabled,
      'alertBannerTitle': alertBannerTitle,
      'alertBannerMessage': alertBannerMessage,
      'alertBannerSeverity': alertBannerSeverity.firestoreValue,
      'alertBannerActionUrl': alertBannerActionUrl,
      'supportPhone': supportPhone,
      'defaultDeliveryFee': defaultDeliveryFee,
      'minOrderAmount': minOrderAmount,
      'welcomeMessage': welcomeMessage,
      'enableGuestCheckout': enableGuestCheckout,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'enableDistanceBasedDeliveryFee': enableDistanceBasedDeliveryFee,
      'deliveryFeeBase': deliveryFeeBase,
      'deliveryFeePerKm': deliveryFeePerKm,
      'deliveryMaxRadiusKm': deliveryMaxRadiusKm,
      'deliveryMaxRoadKm': deliveryMaxRoadKm,
      'deliveryPricingTiers': deliveryPricingTiers
          .map((t) => t.toMap())
          .toList(),
      'deliveryZoneLat': deliveryZoneLat,
      'deliveryZoneLng': deliveryZoneLng,
      'deliveryRoadFactor': deliveryRoadFactor,
      'deliveryMinutesPerKm': deliveryMinutesPerKm,
      'checkoutServiceFeeFixed': checkoutServiceFeeFixed,
      'checkoutServiceFeePercent': checkoutServiceFeePercent,
      'checkoutTaxPercent': checkoutTaxPercent,
      'enabledPaymentMethods': enabledPaymentMethods,
      'checkoutPaymentMethods': checkoutPaymentMethods
          .map((method) => method.toMap())
          .toList(),
      'cartUi': cartUi.toMap(),
      'bottomNav': bottomNav.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get hasActiveAlertBanner =>
      alertBannerEnabled &&
      (alertBannerTitle.trim().isNotEmpty ||
          alertBannerMessage.trim().isNotEmpty);

  String get effectiveMaintenanceTitle =>
      maintenanceTitle.trim().isEmpty ? 'وضع الصيانة' : maintenanceTitle.trim();

  String get effectiveMaintenanceMessage => maintenanceMessage.trim().isEmpty
      ? 'التطبيق في وضع الصيانة — الطلبات متوقفة مؤقتاً'
      : maintenanceMessage.trim();

  AppSettings copyWith({
    bool? maintenanceMode,
    String? maintenanceTitle,
    String? maintenanceMessage,
    bool? alertBannerEnabled,
    String? alertBannerTitle,
    String? alertBannerMessage,
    AppBannerSeverity? alertBannerSeverity,
    String? alertBannerActionUrl,
    String? supportPhone,
    double? defaultDeliveryFee,
    double? minOrderAmount,
    String? welcomeMessage,
    bool? enableGuestCheckout,
    double? freeDeliveryThreshold,
    bool? enableDistanceBasedDeliveryFee,
    double? deliveryFeeBase,
    double? deliveryFeePerKm,
    double? deliveryMaxRadiusKm,
    double? deliveryMaxRoadKm,
    List<DeliveryPricingTier>? deliveryPricingTiers,
    double? deliveryZoneLat,
    double? deliveryZoneLng,
    double? deliveryRoadFactor,
    double? deliveryMinutesPerKm,
    double? checkoutServiceFeeFixed,
    double? checkoutServiceFeePercent,
    double? checkoutTaxPercent,
    List<String>? enabledPaymentMethods,
    List<CheckoutPaymentMethod>? checkoutPaymentMethods,
    CartUiSettings? cartUi,
    BottomNavConfig? bottomNav,
    int? platformCompletedOrders,
    int? platformProductCount,
  }) {
    return AppSettings(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceTitle: maintenanceTitle ?? this.maintenanceTitle,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      alertBannerEnabled: alertBannerEnabled ?? this.alertBannerEnabled,
      alertBannerTitle: alertBannerTitle ?? this.alertBannerTitle,
      alertBannerMessage: alertBannerMessage ?? this.alertBannerMessage,
      alertBannerSeverity: alertBannerSeverity ?? this.alertBannerSeverity,
      alertBannerActionUrl: alertBannerActionUrl ?? this.alertBannerActionUrl,
      supportPhone: supportPhone ?? this.supportPhone,
      defaultDeliveryFee: defaultDeliveryFee ?? this.defaultDeliveryFee,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      enableGuestCheckout: enableGuestCheckout ?? this.enableGuestCheckout,
      freeDeliveryThreshold:
          freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      enableDistanceBasedDeliveryFee:
          enableDistanceBasedDeliveryFee ?? this.enableDistanceBasedDeliveryFee,
      deliveryFeeBase: deliveryFeeBase ?? this.deliveryFeeBase,
      deliveryFeePerKm: deliveryFeePerKm ?? this.deliveryFeePerKm,
      deliveryMaxRadiusKm: deliveryMaxRadiusKm ?? this.deliveryMaxRadiusKm,
      deliveryMaxRoadKm: deliveryMaxRoadKm ?? this.deliveryMaxRoadKm,
      deliveryPricingTiers: deliveryPricingTiers ?? this.deliveryPricingTiers,
      deliveryZoneLat: deliveryZoneLat ?? this.deliveryZoneLat,
      deliveryZoneLng: deliveryZoneLng ?? this.deliveryZoneLng,
      deliveryRoadFactor: deliveryRoadFactor ?? this.deliveryRoadFactor,
      deliveryMinutesPerKm: deliveryMinutesPerKm ?? this.deliveryMinutesPerKm,
      checkoutServiceFeeFixed:
          checkoutServiceFeeFixed ?? this.checkoutServiceFeeFixed,
      checkoutServiceFeePercent:
          checkoutServiceFeePercent ?? this.checkoutServiceFeePercent,
      checkoutTaxPercent: checkoutTaxPercent ?? this.checkoutTaxPercent,
      enabledPaymentMethods:
          enabledPaymentMethods ?? this.enabledPaymentMethods,
      checkoutPaymentMethods:
          checkoutPaymentMethods ?? this.checkoutPaymentMethods,
      cartUi: cartUi ?? this.cartUi,
      bottomNav: bottomNav ?? this.bottomNav,
      platformCompletedOrders:
          platformCompletedOrders ?? this.platformCompletedOrders,
      platformProductCount: platformProductCount ?? this.platformProductCount,
    );
  }

  /// رسالة الترحيب من لوحة التحكم — يدعم `{name}` للاسم.
  String resolveWelcomeMessage({
    required bool isGuest,
    required String userName,
  }) {
    final msg = welcomeMessage.trim();
    if (msg.isEmpty) {
      return isGuest ? 'أهلاً بيك 👋' : 'أهلاً $userName 👋';
    }
    if (msg.contains('{name}')) {
      final name = isGuest ? 'ضيف' : userName;
      return msg.replaceAll('{name}', name);
    }
    return msg;
  }

  bool get hasSupportPhone => supportPhone.trim().isNotEmpty;

  String get normalizedSupportPhone =>
      supportPhone.replaceAll(RegExp(r'[^\d+]'), '');

  bool qualifiesForFreeDelivery(double subtotal) =>
      freeDeliveryThreshold > 0 && subtotal >= freeDeliveryThreshold;

  double? freeDeliveryRemaining(double subtotal) {
    if (freeDeliveryThreshold <= 0 || subtotal >= freeDeliveryThreshold) {
      return null;
    }
    return freeDeliveryThreshold - subtotal;
  }

  int storeCountFromItems(Iterable<String> storeIds) => storeIds.toSet().length;

  double computeDeliveryFee({
    required double subtotal,
    required int storeCount,
    double? roadDistanceKm,
  }) {
    if (storeCount <= 0) return 0;
    if (qualifiesForFreeDelivery(subtotal)) return 0;
    if (enableDistanceBasedDeliveryFee &&
        roadDistanceKm != null &&
        roadDistanceKm > 0) {
      return computeDistanceDeliveryFee(
        roadDistanceKm: roadDistanceKm,
        storeCount: storeCount,
      );
    }
    return storeCount * defaultDeliveryFee;
  }

  /// رسوم حسب شرائح مسافة الطريق (Directions).
  double computeTierDeliveryFee({
    required double roadDistanceKm,
    List<DeliveryPricingTier>? tiers,
    double? maxRoadKm,
  }) {
    final result = DeliveryTierResult.resolve(
      roadDistanceKm: roadDistanceKm,
      tiers: tiers ?? deliveryPricingTiers,
      maxRoadKm: maxRoadKm ?? deliveryMaxRoadKm,
    );
    return result.isDeliverable ? result.fee : 0;
  }

  bool isRoadDistanceDeliverable(double roadDistanceKm, {double? maxRoadKm}) {
    return DeliveryTierResult.resolve(
      roadDistanceKm: roadDistanceKm,
      tiers: deliveryPricingTiers,
      maxRoadKm: maxRoadKm ?? deliveryMaxRoadKm,
    ).isDeliverable;
  }

  /// رسوم حسب مسافة الطريق (Directions) — legacy linear fallback.
  double computeDistanceDeliveryFee({
    required double roadDistanceKm,
    required int storeCount,
  }) {
    if (storeCount <= 0) return 0;
    if (deliveryPricingTiers.isNotEmpty) {
      return computeTierDeliveryFee(roadDistanceKm: roadDistanceKm);
    }
    final perStore = deliveryFeeBase + (roadDistanceKm * deliveryFeePerKm);
    final total = perStore * storeCount;
    return double.parse(total.toStringAsFixed(2));
  }

  double rawDeliveryFee({required int storeCount}) {
    if (storeCount <= 0) return 0;
    return storeCount * defaultDeliveryFee;
  }

  bool canCheckoutAsGuest(bool isGuest) => !isGuest;
}
