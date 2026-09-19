import 'migration.dart';

/// Flattens schema v1 payment/features into nested `{ enabled: bool }` (v2).
class MigrateV1ToV2 implements ClientMigration {
  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  String get id => 'v1_to_v2';

  @override
  Map<dynamic, dynamic> migrate(Map<dynamic, dynamic> root) {
    final client = Map<dynamic, dynamic>.from(
      root['client'] is Map ? root['client'] as Map : {},
    );
    client['schemaVersion'] = 2;
    root['client'] = client;

    root['payment'] = _migratePayment(root['payment']);
    root['features'] = _migrateFeatures(root['features']);
    return root;
  }

  Map<dynamic, dynamic> _migratePayment(dynamic raw) {
    final src = raw is Map
        ? Map<dynamic, dynamic>.from(raw)
        : <dynamic, dynamic>{};
    bool flag(String key, {bool fallback = false}) {
      final v = src[key];
      if (v is Map) return v['enabled'] == true;
      if (v is bool) return v;
      return fallback;
    }

    return {
      'paymob': {'enabled': flag('paymob')},
      'stripe': {'enabled': flag('stripe')},
      'cash': {'enabled': flag('cash', fallback: true)},
    };
  }

  Map<dynamic, dynamic> _migrateFeatures(dynamic raw) {
    final src = raw is Map
        ? Map<dynamic, dynamic>.from(raw)
        : <dynamic, dynamic>{};
    bool flag(String key, {bool fallback = false}) {
      final v = src[key];
      if (v is Map) return v['enabled'] == true;
      if (v is bool) return v;
      return fallback;
    }

    final grocery = src.containsKey('grocery')
        ? flag('grocery', fallback: true)
        : flag('groceries', fallback: true);

    return {
      'delivery': {'enabled': flag('delivery', fallback: true)},
      'pharmacy': {'enabled': flag('pharmacy', fallback: true)},
      'grocery': {'enabled': grocery},
      'wallet': {'enabled': flag('wallet')},
      'coupons': {'enabled': flag('coupons')},
      'subscriptions': {'enabled': flag('subscriptions')},
      'loyalty': {'enabled': flag('loyalty')},
      'marketplace': {'enabled': flag('marketplace')},
    };
  }
}
