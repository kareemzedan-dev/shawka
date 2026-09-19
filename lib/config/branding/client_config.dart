/// Typed White Label client configuration (schemaVersion 2).
///
/// Source of truth: `clients/<id>/client.yaml`.
/// Runtime values come from generated `branding_*.g.dart` files.
class ClientConfig {
  static const supportedSchemaVersion = 2;

  const ClientConfig({
    required this.id,
    required this.version,
    required this.schemaVersion,
    required this.appName,
    required this.companyName,
    required this.packageName,
    required this.bundleId,
    required this.tagline,
    required this.adminPanelTitle,
    required this.driverAppName,
    required this.firebaseProjectId,
    required this.firebaseRegion,
    required this.primaryHex,
    required this.primaryDarkHex,
    required this.primaryLightHex,
    required this.secondaryHex,
    required this.secondaryLightHex,
    required this.accentHex,
    required this.supportEmail,
    required this.supportPhone,
    required this.website,
    required this.address,
    required this.paymentPaymob,
    required this.paymentStripe,
    required this.paymentCash,
    required this.mapsProvider,
    required this.featureDelivery,
    required this.featurePharmacy,
    required this.featureGrocery,
    required this.featureWallet,
    required this.featureCoupons,
    required this.featureSubscriptions,
    required this.featureLoyalty,
    required this.featureMarketplace,
  });

  final String id;
  final String version;
  final int schemaVersion;
  final String appName;
  final String companyName;
  final String packageName;
  final String bundleId;
  final String tagline;
  final String adminPanelTitle;
  final String driverAppName;
  final String firebaseProjectId;
  final String firebaseRegion;
  final String primaryHex;
  final String primaryDarkHex;
  final String primaryLightHex;
  final String secondaryHex;
  final String secondaryLightHex;
  final String accentHex;
  final String supportEmail;
  final String supportPhone;
  final String website;
  final String address;
  final bool paymentPaymob;
  final bool paymentStripe;
  final bool paymentCash;
  final String mapsProvider;
  final bool featureDelivery;
  final bool featurePharmacy;
  final bool featureGrocery;
  final bool featureWallet;
  final bool featureCoupons;
  final bool featureSubscriptions;
  final bool featureLoyalty;
  final bool featureMarketplace;

  /// Backward-compatible aliases (Phase 1 call sites / generated BrandingValues).
  bool get paymob => paymentPaymob;
  bool get stripe => paymentStripe;
  bool get featureGroceries => featureGrocery;

  /// Parses a YAML/JSON-like map produced by `package:yaml`.
  factory ClientConfig.fromMap(Map<dynamic, dynamic> root) {
    final client = _map(root['client']);
    final firebase = _map(root['firebase']);
    final branding = _map(root['branding']);
    final support = _map(root['support']);
    final payment = _map(root['payment']);
    final maps = _map(root['maps']);
    final features = _map(root['features']);

    final schemaVersion = _int(client['schemaVersion'], fallback: 0);
    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException(
        'Unsupported client schemaVersion=$schemaVersion '
        '(supported=$supportedSchemaVersion). '
        'Run: dart run tool/migrate_client.dart --client=<id>',
      );
    }

    final appName = _str(client['app_name']);
    return ClientConfig(
      id: _str(client['id']),
      version: _str(client['version'], fallback: '1.0.0'),
      schemaVersion: schemaVersion,
      appName: appName,
      companyName: _str(client['company_name'], fallback: appName),
      packageName: _str(client['package_name']),
      bundleId: _str(
        client['bundle_id'],
        fallback: _str(client['package_name']),
      ),
      tagline: _str(client['tagline']),
      adminPanelTitle: _str(
        client['admin_panel_title'],
        fallback: '$appName Admin',
      ),
      driverAppName: _str(
        client['driver_app_name'],
        fallback: '$appName Driver',
      ),
      firebaseProjectId: _str(firebase['project_id']),
      firebaseRegion: _str(firebase['region'], fallback: 'us-central1'),
      primaryHex: _normalizeHex(_str(branding['primary'])),
      primaryDarkHex: _normalizeHex(
        _str(branding['primary_dark'], fallback: _str(branding['primary'])),
      ),
      primaryLightHex: _normalizeHex(
        _str(branding['primary_light'], fallback: _str(branding['accent'])),
      ),
      secondaryHex: _normalizeHex(_str(branding['secondary'])),
      secondaryLightHex: _normalizeHex(
        _str(
          branding['secondary_light'],
          fallback: _str(branding['secondary']),
        ),
      ),
      accentHex: _normalizeHex(
        _str(branding['accent'], fallback: _str(branding['primary_light'])),
      ),
      supportEmail: _str(support['email']),
      supportPhone: _str(support['phone']),
      website: _str(support['website']),
      address: _str(support['address']),
      paymentPaymob: _featureEnabled(payment['paymob'], fallback: false),
      paymentStripe: _featureEnabled(payment['stripe'], fallback: false),
      paymentCash: _featureEnabled(payment['cash'], fallback: true),
      mapsProvider: _str(maps['provider'], fallback: 'google'),
      featureDelivery: _featureEnabled(features['delivery'], fallback: true),
      featurePharmacy: _featureEnabled(features['pharmacy'], fallback: true),
      featureGrocery: _featureEnabled(
        features['grocery'] ?? features['groceries'],
        fallback: true,
      ),
      featureWallet: _featureEnabled(features['wallet'], fallback: false),
      featureCoupons: _featureEnabled(features['coupons'], fallback: false),
      featureSubscriptions: _featureEnabled(
        features['subscriptions'],
        fallback: false,
      ),
      featureLoyalty: _featureEnabled(features['loyalty'], fallback: false),
      featureMarketplace: _featureEnabled(
        features['marketplace'],
        fallback: false,
      ),
    );
  }

  /// Accepts either `true` / `false` or `{ enabled: true }`.
  static bool _featureEnabled(dynamic value, {bool fallback = false}) {
    if (value is Map) {
      return _bool(value['enabled'], fallback: fallback);
    }
    return _bool(value, fallback: fallback);
  }

  static Map<dynamic, dynamic> _map(dynamic value) {
    if (value is Map) return value;
    return const {};
  }

  static String _str(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return fallback;
  }

  static String _normalizeHex(String raw) {
    var h = raw.trim();
    if (h.isEmpty) {
      throw const FormatException('Empty branding color hex.');
    }
    if (!h.startsWith('#')) h = '#$h';
    if (h.length == 4) {
      h = '#${h[1]}${h[1]}${h[2]}${h[2]}${h[3]}${h[3]}';
    }
    if (h.length != 7) {
      throw FormatException('Invalid color hex "$raw" (expected #RRGGBB).');
    }
    return h.toUpperCase();
  }

  static int hexToColorValue(String hex) {
    final h = _normalizeHex(hex).substring(1);
    return int.parse('FF$h', radix: 16);
  }
}
