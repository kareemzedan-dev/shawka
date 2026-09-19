import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matlobgo/core/utils/activity_scope_utils.dart';
import 'package:matlobgo/models/push_deep_link.dart';

enum PushCampaignStatus {
  draft,
  scheduled,
  sent,
  cancelled,
}

enum PushCampaignTarget {
  allUsers,
  governorate,
  inactiveUsers,
  specificUsers,
}

extension PushCampaignStatusX on PushCampaignStatus {
  String get firestoreValue => name;

  String get label => switch (this) {
        PushCampaignStatus.draft => 'مسودة',
        PushCampaignStatus.scheduled => 'مجدول',
        PushCampaignStatus.sent => 'تم الإرسال',
        PushCampaignStatus.cancelled => 'ملغي',
      };

  static PushCampaignStatus fromFirestore(String? value) {
    return PushCampaignStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PushCampaignStatus.draft,
    );
  }
}

extension PushCampaignTargetX on PushCampaignTarget {
  String get firestoreValue => name;

  String get label => switch (this) {
        PushCampaignTarget.allUsers => 'جميع المستخدمين',
        PushCampaignTarget.governorate => 'محافظة محددة',
        PushCampaignTarget.inactiveUsers => 'عملاء غير نشطين',
        PushCampaignTarget.specificUsers => 'عملاء محددون',
      };

  static PushCampaignTarget fromFirestore(String? value) {
    return PushCampaignTarget.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PushCampaignTarget.allUsers,
    );
  }
}

class PushCampaign {
  const PushCampaign({
    required this.id,
    required this.title,
    required this.body,
    required this.target,
    required this.status,
    this.governorate = '',
    this.targetUserIds = const [],
    this.targetUserLabels = const [],
    this.activityTypeIds = const [],
    this.deepLinkRoute = PushDeepLinkRoute.none,
    this.deepLinkId = '',
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
    this.createdByName = '',
    this.tokensTargeted = 0,
    this.deliverySuccess = 0,
    this.deliveryFailure = 0,
    this.deliveryNote = '',
  });

  final String id;
  final String title;
  final String body;
  final PushCampaignTarget target;
  final PushCampaignStatus status;
  final String governorate;
  final List<String> targetUserIds;
  final List<String> targetUserLabels;
  /// قيد إضافي على نشاط العميل (فارغ = بدون قيد نشاط).
  final List<String> activityTypeIds;
  final PushDeepLinkRoute deepLinkRoute;
  final String deepLinkId;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;
  final String createdByName;
  final int tokensTargeted;
  final int deliverySuccess;
  final int deliveryFailure;
  final String deliveryNote;

  bool get hasDeliveryStats =>
      status == PushCampaignStatus.sent &&
      (deliverySuccess > 0 ||
          deliveryFailure > 0 ||
          tokensTargeted > 0 ||
          deliveryNote.isNotEmpty);

  double get deliverySuccessRate {
    if (tokensTargeted <= 0) return 0;
    return (deliverySuccess / tokensTargeted).clamp(0.0, 1.0);
  }

  factory PushCampaign.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final idsRaw = data['targetUserIds'] as List? ?? [];
    final labelsRaw = data['targetUserLabels'] as List? ?? [];
    return PushCampaign(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      target: PushCampaignTargetX.fromFirestore(data['target'] as String?),
      status: PushCampaignStatusX.fromFirestore(data['status'] as String?),
      governorate: data['governorate'] as String? ?? '',
      targetUserIds: idsRaw.map((e) => e.toString()).toList(),
      targetUserLabels: labelsRaw.map((e) => e.toString()).toList(),
      activityTypeIds: ActivityScopeUtils.readIds(data['activityTypeIds']),
      deepLinkRoute: PushDeepLinkRouteX.fromFirestore(
        data['deepLinkRoute'] as String?,
      ),
      deepLinkId: data['deepLinkId'] as String? ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByName: data['createdByName'] as String? ?? '',
      tokensTargeted: data['tokensTargeted'] as int? ?? 0,
      deliverySuccess: data['deliverySuccess'] as int? ?? 0,
      deliveryFailure: data['deliveryFailure'] as int? ?? 0,
      deliveryNote: data['deliveryNote'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'target': target.firestoreValue,
      'status': status.firestoreValue,
      'governorate': governorate,
      if (targetUserIds.isNotEmpty) 'targetUserIds': targetUserIds,
      if (targetUserLabels.isNotEmpty) 'targetUserLabels': targetUserLabels,
      'activityTypeIds': activityTypeIds,
      if (deepLinkRoute != PushDeepLinkRoute.none)
        'deepLinkRoute': deepLinkRoute.firestoreValue,
      if (deepLinkId.isNotEmpty) 'deepLinkId': deepLinkId,
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
