import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/config/branding/branding.dart';
import 'package:matlobgo/config/branding/client_config.dart';
import 'package:matlobgo/config/branding/generated/active_client_id.g.dart';
import 'package:matlobgo/config/branding/generated/branding.g.dart';
import 'package:matlobgo/config/branding/generated/branding_values.g.dart';
import 'package:matlobgo/config/branding/generated/colors.g.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

void main() {
  group('ClientConfig', () {
    test('parses schemaVersion 2 nested features/payment', () {
      final config = ClientConfig.fromMap({
        'client': {
          'id': 'shawka',
          'version': '1.0.0',
          'schemaVersion': 2,
          'app_name': 'Shawka',
          'company_name': 'Xyronix',
          'package_name': 'com.xyronix.shawka',
          'bundle_id': 'com.xyronix.shawka',
          'tagline': 'tag',
        },
        'firebase': {'project_id': 'shawka-689fa', 'region': 'us-central1'},
        'branding': {
          'primary': '#D4AF37',
          'primary_dark': '#8E6D2F',
          'primary_light': '#F1D27B',
          'secondary': '#0A0A0A',
          'secondary_light': '#1A1A1A',
          'accent': '#E8C547',
        },
        'support': {
          'email': 'support@shawka.app',
          'phone': '01016370062',
          'website': 'https://matlobgo.web.app',
          'address': 'Benha',
        },
        'payment': {
          'paymob': {'enabled': true},
          'stripe': {'enabled': false},
          'cash': {'enabled': true},
        },
        'maps': {'provider': 'google'},
        'features': {
          'delivery': {'enabled': true},
          'pharmacy': {'enabled': true},
          'grocery': {'enabled': true},
          'wallet': {'enabled': true},
          'coupons': {'enabled': false},
          'subscriptions': {'enabled': false},
          'loyalty': {'enabled': true},
          'marketplace': {'enabled': false},
        },
      });

      expect(config.id, 'shawka');
      expect(config.schemaVersion, 2);
      expect(config.primaryHex, '#D4AF37');
      expect(config.paymentPaymob, isTrue);
      expect(config.paymentCash, isTrue);
      expect(config.featureWallet, isTrue);
      expect(config.featureMarketplace, isFalse);
      expect(ClientConfig.hexToColorValue(config.primaryHex), 0xFFD4AF37);
    });

    test('rejects unsupported schemaVersion', () {
      expect(
        () => ClientConfig.fromMap({
          'client': {
            'id': 'x',
            'schemaVersion': 99,
            'app_name': 'X',
            'package_name': 'com.x',
          },
          'firebase': {'project_id': 'x'},
          'branding': {'primary': '#FFFFFF', 'secondary': '#000000'},
          'support': {
            'email': 'a@b.c',
            'phone': '1',
            'website': 'https://x',
            'address': 'a',
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects schemaVersion 1 without migration', () {
      expect(
        () => ClientConfig.fromMap({
          'client': {
            'id': 'x',
            'schemaVersion': 1,
            'app_name': 'X',
            'package_name': 'com.x.app',
          },
          'firebase': {'project_id': 'x'},
          'branding': {'primary': '#FFFFFF', 'secondary': '#000000'},
          'support': {
            'email': 'a@b.c',
            'phone': '1',
            'website': 'https://x.com',
            'address': 'a',
          },
          'payment': {'paymob': true},
          'features': {'delivery': true},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Branding.current', () {
    test('matches generated Shawka identity', () {
      expect(kActiveClientId, 'shawka');
      expect(BrandingValues.clientId, 'shawka');
      expect(BrandingMeta.schemaVersion, 2);
      expect(BrandingColors.primaryValue, 0xFFD4AF37);
      expect(Branding.current.appName, 'شوكة و سكينة');
      expect(AppBranding.shortName, 'شوكة و سكينة');
      expect(AppBranding.displayName, 'شوكة و سكينة');
      expect(AppBranding.nameAr, 'شوكة و سكينة');
      expect(AppColors.primary, const Color(0xFFD4AF37));
      expect(AppColors.navy, const Color(0xFF0A0A0A));
      expect(Branding.current.featureDelivery, isTrue);
    });
  });
}
