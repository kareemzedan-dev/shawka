import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/bottom_nav_config.dart';
import 'package:matlobgo/models/cart_coupon_preview.dart';
import 'package:matlobgo/models/cart_ui_settings.dart';
import 'package:matlobgo/screens/home/checkout/checkout_draft.dart';

void main() {
  test('parses validateCartCoupon preview contract', () {
    final preview = CartCouponPreview.fromCallable({
      'valid': true,
      'code': 'save10',
      'discountAmount': 12.5,
      'type': 'percent',
      'freeDelivery': false,
      'expiresAt': 1785000000000,
      'rejectionCode': '',
      'message': '',
    });

    expect(preview.valid, isTrue);
    expect(preview.code, 'SAVE10');
    expect(preview.discountAmount, 12.5);
    expect(preview.expiresAt, isNotNull);
  });

  test('keeps core bottom nav tabs visible even if CMS hides them', () {
    final config = BottomNavConfig.fromMap({
      'badgeEnabled': false,
      'tabs': [
        {'id': 'home', 'visible': false, 'sortOrder': 0},
        {'id': 'search', 'visible': false, 'sortOrder': 1},
        {'id': 'cart', 'visible': false, 'sortOrder': 2, 'showBadge': true},
        {'id': 'orders', 'visible': false, 'sortOrder': 3},
        {'id': 'profile', 'visible': false, 'sortOrder': 4},
      ],
    });

    expect(config.badgeEnabled, isFalse);
    expect(
      config.tabs.where((tab) => tab.visible).map((tab) => tab.id),
      containsAll(['home', 'cart', 'orders', 'profile']),
    );
    expect(
      config.tabs.firstWhere((tab) => tab.id == 'favorites').visible,
      isFalse,
    );
  });

  test('round-trips cart UI and bottom nav inside AppSettings', () {
    final settings = AppSettings.fromMap({
      'cartUi': {
        'suggestionsEnabled': false,
        'freeDeliveryProgressEnabled': true,
        'sectionOrder': ['items', 'coupon', 'summary'],
      },
      'bottomNav': {
        'badgeEnabled': true,
        'tabs': [
          {'id': 'home', 'visible': true, 'sortOrder': 0},
          {'id': 'favorites', 'visible': true, 'sortOrder': 1},
          {'id': 'cart', 'visible': true, 'sortOrder': 2, 'showBadge': true},
          {'id': 'orders', 'visible': true, 'sortOrder': 3},
          {'id': 'profile', 'visible': true, 'sortOrder': 4},
        ],
      },
    });

    expect(settings.cartUi.suggestionsEnabled, isFalse);
    expect(settings.cartUi.sectionOrder.first, 'items');
    expect(settings.bottomNav.tabs.where((t) => t.showBadge).single.id, 'cart');
    expect(settings.toFirestore()['cartUi'], isA<Map>());
    expect(settings.toFirestore()['bottomNav'], isA<Map>());
  });

  test('CheckoutDraft carries orderNote from cart', () {
    const draft = CheckoutDraft(
      initialCouponCode: 'SAVE10',
      orderNote: 'بدون بصل',
    );
    expect(draft.orderNote, 'بدون بصل');
    expect(draft.initialCouponCode, 'SAVE10');
  });

  test('CartUiSettings falls back to default section order', () {
    const settings = CartUiSettings();
    expect(settings.sectionOrder, CartUiSettings.defaultSectionOrder);
  });
}
