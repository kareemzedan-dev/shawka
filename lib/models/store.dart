import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/delivery_pricing_tier.dart';
import 'package:matlobgo/models/store_operating_hours.dart';

/// أيقونة افتراضية لبطاقة المورد / الشركة.
IconData storeCategoryIcon([String? categoryId]) => Icons.storefront_rounded;

/// تسمية عامة عند غياب اسم التصنيف من لوحة التحكم.
const String kDefaultStoreCategoryLabel = 'مورد';

/// وصف قصير يظهر تحت اسم المورد.
const String kDefaultStoreCategorySubtitle = 'مواد غذائية بالجملة';

class Store {
  const Store({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryIds = const [],
    this.activityTypeIds = const [],
    this.productActivityTypeIds = const [],
    required this.rating,
    required this.deliveryMinutes,
    required this.deliveryFee,
    required this.fallbackOpen,
    required this.tags,
    required this.governorate,
    this.isFeatured = false,
    this.discountLabel,
    this.imageUrl,
    this.imageThumbUrl,
    this.coverUrl,
    this.coverThumbUrl,
    this.logoUrl,
    this.logoThumbUrl,
    this.description,
    this.isActive = true,
    this.minOrderAmount = 0,
    this.area = '',
    this.zoneId = '',
    this.zoneName = '',
    this.latitude,
    this.longitude,
    this.operatingHours = const StoreOperatingHours(days: {}),
    this.forceClosed = false,
    this.useGlobalDeliveryPricing = true,
    this.deliveryPricingTiers = const [],
    this.freeDeliveryThreshold = 0,
    this.isVerified = false,
    this.featuredPriority = 0,
    this.featuredStartsAt,
    this.featuredEndsAt,
    this.reviewCount = 0,
    this.totalOrders = 0,
    this.totalFavorites = 0,
    this.totalViews = 0,
    this.supportsCash = true,
    this.supportsCard = false,
    this.supportsInstapay = false,
    this.supportsVodafoneCash = false,
    this.supportsOnlinePayment = false,
  });

  final String id;
  final String name;
  final String categoryId;
  /// كل التصنيفات (رئيسية/فرعية) المرتبطة بالمتجر.
  final List<String> categoryIds;
  /// أنشطة الظهور (فارغ = كل الأنشطة).
  final List<String> activityTypeIds;
  /// اتحاد أنشطة المنتجات المستقلة — يُحدَّث تلقائياً عند حفظ المنتجات.
  final List<String> productActivityTypeIds;
  final double rating;
  final int deliveryMinutes;
  final double deliveryFee;

  /// fallback عند عدم وجود جدول ساعات (حقل isOpen القديم في Firestore).
  final bool fallbackOpen;
  final List<String> tags;
  final String governorate;
  final bool isFeatured;
  final String? discountLabel;
  final String? imageUrl;
  final String? imageThumbUrl;
  final String? coverUrl;
  final String? coverThumbUrl;
  final String? logoUrl;
  final String? logoThumbUrl;
  final String? description;
  final bool isActive;
  final double minOrderAmount;
  final String area;
  final String zoneId;
  final String zoneName;
  final double? latitude;
  final double? longitude;
  final StoreOperatingHours operatingHours;
  final bool forceClosed;
  final bool useGlobalDeliveryPricing;
  final List<DeliveryPricingTier> deliveryPricingTiers;

  /// 0 = استخدم الإعداد العام من app_settings.
  final double freeDeliveryThreshold;
  final bool isVerified;
  final int featuredPriority;
  final DateTime? featuredStartsAt;
  final DateTime? featuredEndsAt;
  final int reviewCount;
  final int totalOrders;
  final int totalFavorites;
  final int totalViews;
  final bool supportsCash;
  final bool supportsCard;
  final bool supportsInstapay;
  final bool supportsVodafoneCash;
  final bool supportsOnlinePayment;

  IconData get categoryIcon => storeCategoryIcon(categoryId);
  String get categoryLabel => kDefaultStoreCategoryLabel;
  String get categorySubtitle => kDefaultStoreCategorySubtitle;

  String? get displayCoverUrl => coverUrl ?? imageUrl;

  String? get displayCoverThumbUrl => coverThumbUrl ?? imageThumbUrl;

  String? get displayLogoUrl => logoUrl;

  String? get displayLogoThumbUrl => logoThumbUrl;

  /// Cover أولاً ثم الشعار — للبطاقات والقوائم.
  String? get displayHeroImageUrl => displayCoverUrl ?? displayLogoUrl;

  String? get displayHeroThumbUrl =>
      displayCoverThumbUrl ?? displayLogoThumbUrl;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isOpenNow {
    if (forceClosed) return false;
    if (operatingHours.hasSchedule) {
      return operatingHours.isOpenNowInCairo();
    }
    return fallbackOpen;
  }

  /// للتوافق مع الكود السابق — يعكس الحالة الفعلية الآن.
  bool get isOpen => isOpenNow;

  /// يمكن الطلب منه الآن (نشط + غير مغلق قسرياً + ضمن ساعات العمل).
  bool get isSellable => isActive && !forceClosed && isOpenNow;

  bool get isFeaturedNow {
    if (!isFeatured) return false;
    final now = DateTime.now();
    if (featuredStartsAt != null && now.isBefore(featuredStartsAt!)) {
      return false;
    }
    if (featuredEndsAt != null && now.isAfter(featuredEndsAt!)) {
      return false;
    }
    return true;
  }

  List<DeliveryPricingTier> pricingTiersFor(AppSettings settings) {
    if (useGlobalDeliveryPricing || deliveryPricingTiers.isEmpty) {
      return settings.deliveryPricingTiers;
    }
    return deliveryPricingTiers;
  }

  double freeDeliveryThresholdFor(AppSettings settings) =>
      freeDeliveryThreshold > 0
      ? freeDeliveryThreshold
      : settings.freeDeliveryThreshold;

  factory Store.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Store.fromMap(id: doc.id, data: doc.data() ?? const {});

  factory Store.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final categoryId =
        data['categoryId'] as String? ??
        data['category'] as String? ??
        '';
    final categoryIdsRaw = List<String>.from(
      data['categoryIds'] as List? ?? const [],
    );
    final categoryIds = categoryIdsRaw.isNotEmpty
        ? categoryIdsRaw
        : (categoryId.isEmpty ? const <String>[] : <String>[categoryId]);
    return Store(
      id: id,
      name: data['name'] as String? ?? '',
      categoryId: categoryId,
      categoryIds: categoryIds,
      activityTypeIds: ActivityScopeUtils.readIds(data['activityTypeIds']),
      productActivityTypeIds:
          ActivityScopeUtils.readIds(data['productActivityTypeIds']),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      deliveryMinutes: data['deliveryMinutes'] as int? ?? 30,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      fallbackOpen: data['isOpen'] as bool? ?? true,
      tags: List<String>.from(data['tags'] as List? ?? []),
      governorate: data['governorate'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      discountLabel: data['discountLabel'] as String?,
      imageUrl: normalizeStoredImageUrl(
        data['imageUrl'] as String? ?? data['coverUrl'] as String?,
      ),
      imageThumbUrl: normalizeStoredImageUrl(
        data['imageThumbUrl'] as String? ?? data['coverThumbUrl'] as String?,
      ),
      coverUrl: normalizeStoredImageUrl(
        data['coverUrl'] as String? ?? data['imageUrl'] as String?,
      ),
      coverThumbUrl: normalizeStoredImageUrl(
        data['coverThumbUrl'] as String? ?? data['imageThumbUrl'] as String?,
      ),
      logoUrl: normalizeStoredImageUrl(data['logoUrl'] as String?),
      logoThumbUrl: normalizeStoredImageUrl(data['logoThumbUrl'] as String?),
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toDouble() ?? 0,
      area: data['area'] as String? ?? '',
      zoneId: data['zoneId'] as String? ?? '',
      zoneName: data['zoneName'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      operatingHours: StoreOperatingHours.fromFirestore(
        data['operatingHours'] is Map
            ? Map<String, dynamic>.from(data['operatingHours'] as Map)
            : null,
      ),
      forceClosed: data['forceClosed'] as bool? ?? false,
      useGlobalDeliveryPricing:
          data['useGlobalDeliveryPricing'] as bool? ?? true,
      deliveryPricingTiers: DeliveryPricingTier.parseList(
        data['deliveryPricingTiers'] as List<dynamic>?,
      ),
      freeDeliveryThreshold:
          (data['freeDeliveryThreshold'] as num?)?.toDouble() ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      featuredPriority: (data['featuredPriority'] as num?)?.toInt() ?? 0,
      featuredStartsAt: (data['featuredStartsAt'] as Timestamp?)?.toDate(),
      featuredEndsAt: (data['featuredEndsAt'] as Timestamp?)?.toDate(),
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      totalFavorites: (data['totalFavorites'] as num?)?.toInt() ?? 0,
      totalViews: (data['totalViews'] as num?)?.toInt() ?? 0,
      supportsCash: data['supportsCash'] as bool? ?? true,
      supportsCard: data['supportsCard'] as bool? ?? false,
      supportsInstapay: data['supportsInstapay'] as bool? ?? false,
      supportsVodafoneCash: data['supportsVodafoneCash'] as bool? ?? false,
      supportsOnlinePayment: data['supportsOnlinePayment'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    final cover = coverUrl ?? imageUrl;
    final coverThumb = coverThumbUrl ?? imageThumbUrl;
    return {
      'name': name,
      'categoryId': categoryId,
      'category': categoryId,
      'categoryIds': categoryIds.isNotEmpty
          ? categoryIds
          : (categoryId.isEmpty ? <String>[] : <String>[categoryId]),
      'activityTypeIds': activityTypeIds,
      'productActivityTypeIds': productActivityTypeIds,
      'rating': rating,
      'deliveryMinutes': deliveryMinutes,
      'deliveryFee': deliveryFee,
      'isOpen': fallbackOpen,
      'tags': tags,
      'governorate': governorate,
      'isFeatured': isFeatured,
      'discountLabel': discountLabel,
      'imageUrl': cover,
      'imageThumbUrl': coverThumb,
      'coverUrl': cover,
      'coverThumbUrl': coverThumb,
      'logoUrl': logoUrl,
      'logoThumbUrl': logoThumbUrl,
      'description': description,
      'isActive': isActive,
      'minOrderAmount': minOrderAmount,
      'area': area,
      'zoneId': zoneId,
      'zoneName': zoneName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (operatingHours.days.isNotEmpty)
        'operatingHours': operatingHours.toFirestore(),
      'forceClosed': forceClosed,
      'useGlobalDeliveryPricing': useGlobalDeliveryPricing,
      if (deliveryPricingTiers.isNotEmpty)
        'deliveryPricingTiers': deliveryPricingTiers
            .map((t) => t.toMap())
            .toList(),
      if (freeDeliveryThreshold > 0)
        'freeDeliveryThreshold': freeDeliveryThreshold,
      'isVerified': isVerified,
      'featuredPriority': featuredPriority,
      if (featuredStartsAt != null)
        'featuredStartsAt': Timestamp.fromDate(featuredStartsAt!),
      if (featuredEndsAt != null)
        'featuredEndsAt': Timestamp.fromDate(featuredEndsAt!),
      'reviewCount': reviewCount,
      'totalOrders': totalOrders,
      'totalFavorites': totalFavorites,
      'totalViews': totalViews,
      'supportsCash': supportsCash,
      'supportsCard': supportsCard,
      'supportsInstapay': supportsInstapay,
      'supportsVodafoneCash': supportsVodafoneCash,
      'supportsOnlinePayment': supportsOnlinePayment,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Store copyWith({
    String? name,
    String? categoryId,
    List<String>? categoryIds,
    List<String>? activityTypeIds,
    List<String>? productActivityTypeIds,
    double? rating,
    int? deliveryMinutes,
    double? deliveryFee,
    bool? fallbackOpen,
    List<String>? tags,
    String? governorate,
    bool? isFeatured,
    String? discountLabel,
    String? imageUrl,
    String? imageThumbUrl,
    String? coverUrl,
    String? coverThumbUrl,
    String? logoUrl,
    String? logoThumbUrl,
    String? description,
    bool? isActive,
    double? minOrderAmount,
    String? area,
    String? zoneId,
    String? zoneName,
    double? latitude,
    double? longitude,
    StoreOperatingHours? operatingHours,
    bool? forceClosed,
    bool? useGlobalDeliveryPricing,
    List<DeliveryPricingTier>? deliveryPricingTiers,
    double? freeDeliveryThreshold,
    bool? isVerified,
    int? featuredPriority,
    DateTime? featuredStartsAt,
    DateTime? featuredEndsAt,
    int? reviewCount,
    int? totalOrders,
    int? totalFavorites,
    int? totalViews,
    bool? supportsCash,
    bool? supportsCard,
    bool? supportsInstapay,
    bool? supportsVodafoneCash,
    bool? supportsOnlinePayment,
    bool clearCover = false,
    bool clearLogo = false,
    bool clearLocation = false,
    bool clearFeaturedStartsAt = false,
    bool clearFeaturedEndsAt = false,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryIds: categoryIds ?? this.categoryIds,
      activityTypeIds: activityTypeIds ?? this.activityTypeIds,
      productActivityTypeIds:
          productActivityTypeIds ?? this.productActivityTypeIds,
      rating: rating ?? this.rating,
      deliveryMinutes: deliveryMinutes ?? this.deliveryMinutes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      fallbackOpen: fallbackOpen ?? this.fallbackOpen,
      tags: tags ?? this.tags,
      governorate: governorate ?? this.governorate,
      isFeatured: isFeatured ?? this.isFeatured,
      discountLabel: discountLabel ?? this.discountLabel,
      imageUrl: clearCover ? null : (imageUrl ?? this.imageUrl),
      imageThumbUrl: clearCover ? null : (imageThumbUrl ?? this.imageThumbUrl),
      coverUrl: clearCover ? null : (coverUrl ?? this.coverUrl),
      coverThumbUrl: clearCover ? null : (coverThumbUrl ?? this.coverThumbUrl),
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
      logoThumbUrl: clearLogo ? null : (logoThumbUrl ?? this.logoThumbUrl),
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      area: area ?? this.area,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      operatingHours: operatingHours ?? this.operatingHours,
      forceClosed: forceClosed ?? this.forceClosed,
      useGlobalDeliveryPricing:
          useGlobalDeliveryPricing ?? this.useGlobalDeliveryPricing,
      deliveryPricingTiers: deliveryPricingTiers ?? this.deliveryPricingTiers,
      freeDeliveryThreshold:
          freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      isVerified: isVerified ?? this.isVerified,
      featuredPriority: featuredPriority ?? this.featuredPriority,
      featuredStartsAt: clearFeaturedStartsAt
          ? null
          : (featuredStartsAt ?? this.featuredStartsAt),
      featuredEndsAt: clearFeaturedEndsAt
          ? null
          : (featuredEndsAt ?? this.featuredEndsAt),
      reviewCount: reviewCount ?? this.reviewCount,
      totalOrders: totalOrders ?? this.totalOrders,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      totalViews: totalViews ?? this.totalViews,
      supportsCash: supportsCash ?? this.supportsCash,
      supportsCard: supportsCard ?? this.supportsCard,
      supportsInstapay: supportsInstapay ?? this.supportsInstapay,
      supportsVodafoneCash: supportsVodafoneCash ?? this.supportsVodafoneCash,
      supportsOnlinePayment:
          supportsOnlinePayment ?? this.supportsOnlinePayment,
    );
  }
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cta,
    this.description = '',
    this.imageAsset = '',
    this.imageUrl,
    this.imageThumbUrl,
    this.accentColor,
    this.ctaColor,
    this.deepLinkRoute = 'home',
    this.deepLinkId = '',
    this.targetCategoryIds = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String cta;
  final String description;
  final String imageAsset;
  final String? imageUrl;
  final String? imageThumbUrl;
  final Color? accentColor;
  final Color? ctaColor;
  final String deepLinkRoute;
  final String deepLinkId;
  final List<String> targetCategoryIds;

  bool get hasNetworkImage =>
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (imageThumbUrl != null && imageThumbUrl!.trim().isNotEmpty);

  bool get hasDeepLink =>
      deepLinkRoute.trim().isNotEmpty && deepLinkRoute != 'home' ||
      deepLinkId.trim().isNotEmpty;
}

class Governorate {
  const Governorate({
    required this.id,
    required this.name,
    required this.isAvailable,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final bool isAvailable;
  final int sortOrder;

  factory Governorate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Governorate(
      id: doc.id,
      name: data['name'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isAvailable': isAvailable,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Governorate copyWith({String? name, bool? isAvailable, int? sortOrder}) {
    return Governorate(
      id: id,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Governorate && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
