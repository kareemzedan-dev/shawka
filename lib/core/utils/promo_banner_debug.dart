import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/promo_banner_record.dart';
import 'package:matlobgo/models/store.dart';

/// Diagnostic logs for the promo-banner pipeline (Admin → Home).
/// Enable via debug builds or `--dart-define=PROMO_BANNER_DEBUG=true`.
abstract final class PromoBannerDebug {
  static bool enabled = kDebugMode ||
      bool.fromEnvironment('PROMO_BANNER_DEBUG', defaultValue: false);

  static const _tag = '[PromoBanner]';

  static void log(String message) {
    if (!enabled) return;
    debugPrint('$_tag $message');
  }

  static void exception(Object error, [StackTrace? stackTrace]) {
    if (!enabled) return;
    debugPrint('$_tag EXCEPTION: $error');
    if (stackTrace != null) {
      debugPrint('$_tag STACK: $stackTrace');
    }
  }

  /// Multi-line status dump for a single banner evaluation.
  static void dumpLiveStatus({
    required PromoBannerRecord record,
    required String requestedGovernorate,
    required DateTime now,
  }) {
    if (!enabled) return;
    final live = record.isLiveAt(now);
    final reason = exclusionReason(record, now);
    final saved = record.governorate;
    final requested = requestedGovernorate;
    final equal = saved == requested;
    final codeUnitsHint = !equal
        ? ' savedCodes=${saved.codeUnits} requestedCodes=${requested.codeUnits}'
        : '';

    debugPrint('$_tag ────────');
    debugPrint('$_tag ID: ${record.id}');
    debugPrint('$_tag Governorate: $saved');
    debugPrint('$_tag Saved Governorate: "$saved"');
    debugPrint('$_tag Requested Governorate: "$requested"');
    debugPrint('$_tag Equality Result: $equal$codeUnitsHint');
    debugPrint('$_tag Active: ${record.isActive}');
    debugPrint('$_tag Starts: ${record.startsAt?.toIso8601String() ?? "null"}');
    debugPrint('$_tag Ends: ${record.endsAt?.toIso8601String() ?? "null"}');
    if (record.endsAt != null) {
      debugPrint(
        '$_tag EndsEffective: '
        '${PromoBannerRecord.effectiveEndsAt(record.endsAt!).toIso8601String()}',
      );
    }
    debugPrint('$_tag Now: ${now.toIso8601String()}');
    debugPrint('$_tag Live: $live');
    debugPrint('$_tag imageUrl: ${_describeUrl(record.imageUrl)}');
    debugPrint('$_tag imageThumbUrl: ${_describeUrl(record.imageThumbUrl)}');
    if (live) {
      debugPrint('$_tag Reason: included');
    } else {
      debugPrint('$_tag Excluded because:');
      debugPrint('$_tag - $reason');
    }
    if (!equal) {
      debugPrint('$_tag Excluded because:');
      debugPrint('$_tag - governorate mismatch');
    }
  }

  static void dumpDisplay(PromoBanner banner) {
    if (!enabled) return;
    debugPrint('$_tag Display ID: ${banner.id}');
    debugPrint('$_tag Display hasNetwork: ${banner.hasNetworkImage}');
    debugPrint('$_tag Display imageUrl: ${_describeUrl(banner.imageUrl)}');
    debugPrint(
      '$_tag Display imageThumbUrl: ${_describeUrl(banner.imageThumbUrl)}',
    );
    if (!banner.hasNetworkImage) {
      debugPrint(
        '$_tag Excluded because: imageUrl empty/null '
        '(no network image to load)',
      );
    }
  }

  static void imageIssue({
    required String bannerId,
    required String reason,
    String? url,
    Object? error,
  }) {
    if (!enabled) return;
    debugPrint('$_tag Image issue ID: $bannerId');
    debugPrint('$_tag Excluded because: $reason');
    if (url != null) debugPrint('$_tag imageUrl: $url');
    if (error != null) debugPrint('$_tag error: $error');
  }

  /// Human-readable exclusion key for filters.
  static String? exclusionReason(PromoBannerRecord r, DateTime now) {
    if (!r.isActive) return 'inactive';
    if (r.startsAt != null && now.isBefore(r.startsAt!)) {
      return 'starts in future';
    }
    if (r.endsAt != null &&
        now.isAfter(PromoBannerRecord.effectiveEndsAt(r.endsAt!))) {
      return 'expired';
    }
    return null;
  }

  static String describeUrl(String? url) => _describeUrl(url);

  static String _describeUrl(String? url) {
    if (url == null) return 'null';
    final t = url.trim();
    if (t.isEmpty) return 'empty';
    if (t.length <= 120) return t;
    return '${t.substring(0, 56)}…${t.substring(t.length - 40)}';
  }
}
