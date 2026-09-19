import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/screens/home/checkout/checkout_draft.dart';

void main() {
  test('parses every authoritative Checkout monetary field', () {
    final quote = CheckoutQuote.fromCallable({
      'pricing': {
        'currency': 'EGP',
        'subtotal': 200,
        'deliveryFee': 15,
        'discountAmount': 20,
        'serviceFee': 12,
        'paymentFee': 3,
        'taxes': 27.3,
        'grandTotal': 237.3,
        'couponCode': 'SAVE10',
        'couponExpiresAt': 1785000000000,
        'distanceKm': 4.2,
        'etaMinutes': 18,
        'orders': [
          {
            'storeId': 'store-1',
            'subtotal': 200,
            'deliveryFee': 15,
            'rawDeliveryFee': 15,
            'discountAmount': 20,
            'serviceFee': 12,
            'paymentFee': 3,
            'taxes': 27.3,
            'grandTotal': 237.3,
            'distanceKm': 4.2,
            'etaMinutes': 18,
          },
        ],
      },
      'orders': [
        {
          'storeId': 'store-1',
          'storeName': 'Store',
          'lineItems': [
            {
              'productId': 'product-1',
              'productName': 'Product',
              'quantity': 2,
              'unitPrice': 100,
              'addonIds': <String>[],
              'note': '',
              'imageUrl': 'https://example.com/product.jpg',
              'imageThumbUrl': '',
            },
          ],
        },
      ],
      'availablePaymentMethods': ['cash', 'card'],
      'calculatedAt': 1780000000000,
    });

    expect(quote.subtotal, 200);
    expect(quote.deliveryFee, 15);
    expect(quote.discountAmount, 20);
    expect(quote.serviceFee, 12);
    expect(quote.paymentFee, 3);
    expect(quote.taxes, 27.3);
    expect(quote.grandTotal, 237.3);
    expect(quote.orders.single.grandTotal, 237.3);
    expect(quote.resolvedOrders.single.lineItems.single.lineTotal, 200);
    expect(quote.availablePaymentMethods, ['cash', 'card']);
    expect(quote.couponExpiresAt, isNotNull);
  });

  test('round-trips CMS payment eligibility and fee configuration', () {
    const method = CheckoutPaymentMethod(
      id: 'card',
      name: 'بطاقة',
      description: 'Visa / Mastercard',
      logoUrl: 'https://example.com/card.png',
      isActive: true,
      sortOrder: 2,
      feeFixed: 1.5,
      feePercent: 2,
      governorates: ['القاهرة'],
      storeIds: ['store-1'],
      categoryIds: ['restaurant'],
      minOrderAmount: 50,
      maxOrderAmount: 1000,
      unavailableReason: 'غير متاحة',
    );

    final decoded = CheckoutPaymentMethod.fromMap(method.toMap());
    expect(decoded.id, method.id);
    expect(decoded.feeFixed, 1.5);
    expect(decoded.feePercent, 2);
    expect(decoded.governorates, ['القاهرة']);
    expect(decoded.storeIds, ['store-1']);
    expect(decoded.categoryIds, ['restaurant']);
    expect(decoded.minOrderAmount, 50);
    expect(decoded.maxOrderAmount, 1000);
  });

  test('CheckoutDraft carries orderNote and coupon into checkout', () {
    const draft = CheckoutDraft(
      initialCouponCode: 'SAVE10',
      orderNote: 'بدون بصل',
      areaLine: '',
      streetLine: '',
    );
    expect(draft.initialCouponCode, 'SAVE10');
    expect(draft.orderNote, 'بدون بصل');
    expect(draft.hasValidGeoAddress, isFalse);
  });

  test('CheckoutTokens reuse Cart motion and contrast-safe CTA', () {
    expect(CheckoutTokens.ctaBackground, CartTokens.ctaBackground);
    expect(CheckoutTokens.accentText, CartTokens.accentText);
    expect(CheckoutTokens.motionFast, CartTokens.motionFast);
    expect(CheckoutTokens.quoteDebounce, const Duration(milliseconds: 350));
  });
}
