import 'dart:io';

import 'package:matlobgo/config/branding/client_config.dart';
import 'package:path/path.dart' as p;

/// Shared codegen for generate_brand / update_brand.
void writeBrandGeneratedFiles(Directory root, ClientConfig c) {
  final dir = Directory(
    p.join(root.path, 'lib', 'config', 'branding', 'generated'),
  );
  dir.createSync(recursive: true);

  final header =
      '// GENERATED CODE — do not edit by hand.\n'
      '// Regenerate: dart run tool/generate_brand.dart --client=${c.id}\n'
      '// ignore_for_file: type=lint\n';

  File(p.join(dir.path, 'colors.g.dart')).writeAsStringSync('''
$header
/// Brand colors for the active White Label client.
abstract final class BrandingColors {
  static const int primaryValue = ${_colorConst(c.primaryHex)};
  static const int primaryDarkValue = ${_colorConst(c.primaryDarkHex)};
  static const int primaryLightValue = ${_colorConst(c.primaryLightHex)};
  static const int secondaryValue = ${_colorConst(c.secondaryHex)};
  static const int secondaryLightValue = ${_colorConst(c.secondaryLightHex)};
  static const int accentValue = ${_colorConst(c.accentHex)};

  static const String primaryHex = '${_esc(c.primaryHex)}';
  static const String secondaryHex = '${_esc(c.secondaryHex)}';
}
''');

  File(p.join(dir.path, 'strings.g.dart')).writeAsStringSync('''
$header
/// Brand strings for the active White Label client.
abstract final class BrandingStrings {
  static const String appName = '${_esc(c.appName)}';
  static const String companyName = '${_esc(c.companyName)}';
  static const String tagline = '${_esc(c.tagline)}';
  static const String adminPanelTitle = '${_esc(c.adminPanelTitle)}';
  static const String driverAppName = '${_esc(c.driverAppName)}';
  static const String supportEmail = '${_esc(c.supportEmail)}';
  static const String supportPhone = '${_esc(c.supportPhone)}';
  static const String website = '${_esc(c.website)}';
  static const String address = '${_esc(c.address)}';
}
''');

  File(p.join(dir.path, 'assets.g.dart')).writeAsStringSync('''
$header
/// Brand asset paths for the active White Label client.
abstract final class BrandingAssets {
  static const String logoAsset = 'assets/branding/current/logo.png';
  static const String splashAsset = 'assets/branding/current/splash.png';
  static const String faviconAsset = 'assets/branding/current/favicon.png';
}
''');

  File(p.join(dir.path, 'branding.g.dart')).writeAsStringSync('''
$header
/// Client meta, Firebase, payment & feature flags.
abstract final class BrandingMeta {
  static const String clientId = '${_esc(c.id)}';
  static const String version = '${_esc(c.version)}';
  static const int schemaVersion = ${c.schemaVersion};
  static const String packageName = '${_esc(c.packageName)}';
  static const String bundleId = '${_esc(c.bundleId)}';
  static const String firebaseProjectId = '${_esc(c.firebaseProjectId)}';
  static const String firebaseRegion = '${_esc(c.firebaseRegion)}';
  static const String mapsProvider = '${_esc(c.mapsProvider)}';

  static const bool paymentPaymob = ${c.paymentPaymob};
  static const bool paymentStripe = ${c.paymentStripe};
  static const bool paymentCash = ${c.paymentCash};

  static const bool featureDelivery = ${c.featureDelivery};
  static const bool featurePharmacy = ${c.featurePharmacy};
  static const bool featureGrocery = ${c.featureGrocery};
  static const bool featureWallet = ${c.featureWallet};
  static const bool featureCoupons = ${c.featureCoupons};
  static const bool featureSubscriptions = ${c.featureSubscriptions};
  static const bool featureLoyalty = ${c.featureLoyalty};
  static const bool featureMarketplace = ${c.featureMarketplace};
}
''');

  // Backward-compatible aggregator used by AppColors / AppBranding / Branding.current
  File(p.join(dir.path, 'branding_values.g.dart')).writeAsStringSync('''
$header
import 'package:matlobgo/config/branding/generated/assets.g.dart';
import 'package:matlobgo/config/branding/generated/branding.g.dart';
import 'package:matlobgo/config/branding/generated/colors.g.dart';
import 'package:matlobgo/config/branding/generated/strings.g.dart';

/// Aggregated branding constants (compat facade over split generated files).
abstract final class BrandingValues {
  static const String clientId = BrandingMeta.clientId;
  static const String version = BrandingMeta.version;
  static const int schemaVersion = BrandingMeta.schemaVersion;

  static const String appName = BrandingStrings.appName;
  static const String companyName = BrandingStrings.companyName;
  static const String packageName = BrandingMeta.packageName;
  static const String bundleId = BrandingMeta.bundleId;
  static const String tagline = BrandingStrings.tagline;
  static const String adminPanelTitle = BrandingStrings.adminPanelTitle;
  static const String driverAppName = BrandingStrings.driverAppName;

  static const String firebaseProjectId = BrandingMeta.firebaseProjectId;
  static const String firebaseRegion = BrandingMeta.firebaseRegion;

  static const int primaryValue = BrandingColors.primaryValue;
  static const int primaryDarkValue = BrandingColors.primaryDarkValue;
  static const int primaryLightValue = BrandingColors.primaryLightValue;
  static const int secondaryValue = BrandingColors.secondaryValue;
  static const int secondaryLightValue = BrandingColors.secondaryLightValue;
  static const int accentValue = BrandingColors.accentValue;

  static const String primaryHex = BrandingColors.primaryHex;
  static const String secondaryHex = BrandingColors.secondaryHex;

  static const String supportEmail = BrandingStrings.supportEmail;
  static const String supportPhone = BrandingStrings.supportPhone;
  static const String website = BrandingStrings.website;
  static const String address = BrandingStrings.address;

  static const bool paymob = BrandingMeta.paymentPaymob;
  static const bool stripe = BrandingMeta.paymentStripe;
  static const bool cash = BrandingMeta.paymentCash;
  static const String mapsProvider = BrandingMeta.mapsProvider;

  static const bool featureDelivery = BrandingMeta.featureDelivery;
  static const bool featurePharmacy = BrandingMeta.featurePharmacy;
  static const bool featureGroceries = BrandingMeta.featureGrocery;
  static const bool featureGrocery = BrandingMeta.featureGrocery;
  static const bool featureWallet = BrandingMeta.featureWallet;
  static const bool featureCoupons = BrandingMeta.featureCoupons;
  static const bool featureSubscriptions = BrandingMeta.featureSubscriptions;
  static const bool featureLoyalty = BrandingMeta.featureLoyalty;
  static const bool featureMarketplace = BrandingMeta.featureMarketplace;

  static const String logoAsset = BrandingAssets.logoAsset;
  static const String splashAsset = BrandingAssets.splashAsset;
  static const String faviconAsset = BrandingAssets.faviconAsset;
}
''');

  File(p.join(dir.path, 'active_client_id.g.dart')).writeAsStringSync('''
$header
/// Active White Label client id (mirrors BrandingMeta.clientId).
const String kActiveClientId = '${_esc(c.id)}';
''');
}

void copyBrandAssets(Directory root, String clientId) {
  final srcDir = Directory(p.join(root.path, 'clients', clientId));
  final destDir = Directory(p.join(root.path, 'assets', 'branding', 'current'));
  destDir.createSync(recursive: true);

  for (final name in ['logo.png', 'splash.png', 'favicon.png']) {
    final src = File(p.join(srcDir.path, name));
    final dest = File(p.join(destDir.path, name));
    if (src.existsSync() && src.lengthSync() > 0) {
      src.copySync(dest.path);
    } else if (!dest.existsSync()) {
      stdout.writeln('Warning: missing clients/$clientId/$name');
    }
  }
}

void ensurePubspecBrandAsset(Directory root) {
  final file = File(p.join(root.path, 'pubspec.yaml'));
  var text = file.readAsStringSync();
  if (!text.contains('assets/branding/current/')) {
    text = text.replaceFirst(
      '    - assets/images/banners/\n',
      '    - assets/images/banners/\n    - assets/branding/current/\n',
    );
    file.writeAsStringSync(text);
  }
}

String _esc(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

String _colorConst(String hex) {
  final h = hex.replaceAll('#', '').toUpperCase();
  return '0xFF$h';
}
