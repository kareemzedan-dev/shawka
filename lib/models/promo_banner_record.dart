import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/core/utils/catalog_image_url_resolver.dart';
import 'package:matlobgo/models/store.dart';

/// بانر عرض قابل للإدارة من Firestore.
class PromoBannerRecord {
  const PromoBannerRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cta,
    this.description = '',
    this.imageUrl,
    this.imageThumbUrl,
    this.imageAsset,
    this.accentColorArgb,
    this.ctaColorArgb,
    required this.governorate,
    this.isActive = true,
    this.sortOrder = 0,
    this.startsAt,
    this.endsAt,
    this.deepLinkRoute = 'home',
    this.deepLinkId = '',
    this.targetCategoryIds = const [],
    this.activityTypeIds = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String cta;
  final String description;
  final String? imageUrl;
  final String? imageThumbUrl;
  final String? imageAsset;
  final int? accentColorArgb;
  final int? ctaColorArgb;
  final String governorate;
  final bool isActive;
  final int sortOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String deepLinkRoute;
  final String deepLinkId;
  final List<String> targetCategoryIds;
  /// أنشطة الظهور (فارغ = كل الأنشطة).
  final List<String> activityTypeIds;

  Color? get accentColor =>
      accentColorArgb != null ? Color(accentColorArgb!) : null;

  Color? get ctaColor =>
      ctaColorArgb != null ? Color(ctaColorArgb!) : accentColor;

  /// Inclusive through end of calendar day when [endsAt] is date-only (00:00:00).
  static DateTime effectiveEndsAt(DateTime endsAt) {
    final dateOnly = endsAt.hour == 0 &&
        endsAt.minute == 0 &&
        endsAt.second == 0 &&
        endsAt.millisecond == 0 &&
        endsAt.microsecond == 0;
    if (dateOnly) {
      return DateTime(
        endsAt.year,
        endsAt.month,
        endsAt.day,
        23,
        59,
        59,
        999,
      );
    }
    return endsAt;
  }

  bool isLiveAt(DateTime now) {
    if (!isActive) return false;
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(effectiveEndsAt(endsAt!))) return false;
    return true;
  }

  factory PromoBannerRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PromoBannerRecord(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      cta: data['cta'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: normalizeStoredImageUrl(data['imageUrl'] as String?),
      imageThumbUrl: normalizeStoredImageUrl(data['imageThumbUrl'] as String?),
      imageAsset: data['imageAsset'] as String?,
      accentColorArgb: data['accentColor'] as int?,
      ctaColorArgb: data['ctaColor'] as int?,
      governorate: data['governorate'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      startsAt: (data['startsAt'] as Timestamp?)?.toDate(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
      deepLinkRoute: data['deepLinkRoute'] as String? ?? 'home',
      deepLinkId: data['deepLinkId'] as String? ?? '',
      targetCategoryIds:
          List<String>.from(data['targetCategoryIds'] as List? ?? const []),
      activityTypeIds: ActivityScopeUtils.readIds(data['activityTypeIds']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'cta': cta,
      'description': description,
      'imageUrl': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'imageAsset': imageAsset,
      'accentColor': accentColorArgb,
      'ctaColor': ctaColorArgb,
      'governorate': governorate,
      'isActive': isActive,
      'sortOrder': sortOrder,
      if (startsAt != null) 'startsAt': Timestamp.fromDate(startsAt!),
      if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
      'deepLinkRoute': deepLinkRoute,
      'deepLinkId': deepLinkId,
      'targetCategoryIds': targetCategoryIds,
      'activityTypeIds': activityTypeIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PromoBanner toDisplayBanner() {
    return PromoBanner(
      id: id,
      title: title,
      subtitle: subtitle,
      cta: cta,
      description: description,
      imageAsset: imageAsset ?? '',
      imageUrl: imageUrl,
      imageThumbUrl: imageThumbUrl,
      accentColor: accentColor,
      ctaColor: ctaColor,
      deepLinkRoute: deepLinkRoute,
      deepLinkId: deepLinkId,
      targetCategoryIds: targetCategoryIds,
    );
  }

  PromoBannerRecord copyWith({
    String? title,
    String? subtitle,
    String? cta,
    String? description,
    String? imageUrl,
    String? imageThumbUrl,
    String? imageAsset,
    int? accentColorArgb,
    int? ctaColorArgb,
    String? governorate,
    bool? isActive,
    int? sortOrder,
    DateTime? startsAt,
    DateTime? endsAt,
    String? deepLinkRoute,
    String? deepLinkId,
    List<String>? targetCategoryIds,
    List<String>? activityTypeIds,
    bool clearSchedule = false,
  }) {
    return PromoBannerRecord(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      cta: cta ?? this.cta,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageThumbUrl: imageThumbUrl ?? this.imageThumbUrl,
      imageAsset: imageAsset ?? this.imageAsset,
      accentColorArgb: accentColorArgb ?? this.accentColorArgb,
      ctaColorArgb: ctaColorArgb ?? this.ctaColorArgb,
      governorate: governorate ?? this.governorate,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      startsAt: clearSchedule ? null : (startsAt ?? this.startsAt),
      endsAt: clearSchedule ? null : (endsAt ?? this.endsAt),
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
      deepLinkId: deepLinkId ?? this.deepLinkId,
      targetCategoryIds: targetCategoryIds ?? this.targetCategoryIds,
      activityTypeIds: activityTypeIds ?? this.activityTypeIds,
    );
  }
}
