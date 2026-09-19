import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_confirm_bar.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_payment_card.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_price_summary.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_section.dart';

/// بيانات ثابتة لـ Golden / Profile بدون Firebase.
CheckoutQuote sampleCheckoutQuote() {
  return CheckoutQuote.fromCallable({
    'pricing': {
      'currency': 'EGP',
      'subtotal': 170,
      'deliveryFee': 15,
      'discountAmount': 10,
      'serviceFee': 0,
      'paymentFee': 0,
      'taxes': 0,
      'grandTotal': 175,
      'couponCode': 'SAVE10',
      'distanceKm': 3.2,
      'etaMinutes': 25,
      'orders': [
        {
          'storeId': 'store_1',
          'subtotal': 170,
          'deliveryFee': 15,
          'rawDeliveryFee': 15,
          'discountAmount': 10,
          'serviceFee': 0,
          'paymentFee': 0,
          'taxes': 0,
          'grandTotal': 175,
          'distanceKm': 3.2,
          'etaMinutes': 25,
        },
      ],
    },
    'orders': [
      {
        'storeId': 'store_1',
        'storeName': 'متجر التجربة',
        'lineItems': [
          {
            'productId': 'product_1',
            'productName': 'برجر كلاسيك',
            'quantity': 2,
            'unitPrice': 85,
            'addonIds': <String>[],
            'note': '',
            'imageUrl': '',
            'imageThumbUrl': '',
          },
        ],
      },
    ],
    'availablePaymentMethods': ['cash', 'card'],
    'calculatedAt': 1780000000000,
  });
}

DeliveryAddress sampleCheckoutAddress() {
  return const DeliveryAddress(
    label: 'المنزل',
    governorate: 'القاهرة',
    area: 'مدينة نصر',
    street: 'شارع عباس العقاد',
    latitude: 30.0444,
    longitude: 31.2357,
    formattedAddress: 'مدينة نصر، القاهرة',
  );
}

const sampleCashMethod = CheckoutPaymentMethod(
  id: 'cash',
  name: 'الدفع عند الاستلام',
  description: 'ادفع نقداً للمندوب',
  isActive: true,
  sortOrder: 1,
);

const sampleCardMethod = CheckoutPaymentMethod(
  id: 'card',
  name: 'بطاقة',
  description: 'Visa / Mastercard',
  isActive: true,
  sortOrder: 2,
);

/// معاينة أقسام الدفع للـ Golden.
class CheckoutPaymentSectionPreview extends StatelessWidget {
  const CheckoutPaymentSectionPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(CheckoutTokens.pagePadding),
        child: CheckoutSection(
          title: 'طريقة الدفع',
          child: Column(
            children: [
              CheckoutPaymentCard(
                palette: palette,
                method: sampleCashMethod,
                selected: true,
                onTap: () {},
              ),
              const SizedBox(height: CheckoutTokens.spaceMd),
              CheckoutPaymentCard(
                palette: palette,
                method: sampleCardMethod,
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutSummaryPreview extends StatelessWidget {
  const CheckoutSummaryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(CheckoutTokens.pagePadding),
        child: CheckoutPriceSummary(
          palette: context.palette,
          quote: sampleCheckoutQuote(),
          fallbackSubtotal: 170,
          label: (_, fallback) => fallback,
          note: 'الأسعار النهائية من السيرفر',
        ),
      ),
    );
  }
}

class CheckoutConfirmBarPreview extends StatelessWidget {
  const CheckoutConfirmBarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: CheckoutConfirmBar(
        palette: context.palette,
        grandTotal: 175,
        loading: false,
        bottomPadding: 0,
        label: 'تأكيد الطلب',
        totalLabel: 'الإجمالي النهائي',
        onConfirm: () {},
      ),
    );
  }
}

/// شاشة Checkout ثابتة للـ Golden الكامل (بدون خريطة/Firebase).
class CheckoutPreviewScreen extends StatelessWidget {
  const CheckoutPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final quote = sampleCheckoutQuote();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: CheckoutTokens.headerColor,
        foregroundColor: Colors.white,
        title: const Text('إتمام الطلب'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CheckoutTokens.pagePadding),
              children: [
                CheckoutSection(
                  title: 'طريقة الدفع',
                  child: CheckoutPaymentCard(
                    palette: palette,
                    method: sampleCashMethod,
                    selected: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: CheckoutTokens.space2xl),
                CheckoutSection(
                  title: 'ملخص الدفع',
                  child: CheckoutPriceSummary(
                    palette: palette,
                    quote: quote,
                    fallbackSubtotal: quote.subtotal,
                    label: (_, fallback) => fallback,
                    note: 'الأسعار النهائية من السيرفر',
                  ),
                ),
              ],
            ),
          ),
          CheckoutConfirmBar(
            palette: palette,
            grandTotal: quote.grandTotal,
            loading: false,
            bottomPadding: 0,
            label: 'تأكيد الطلب',
            totalLabel: 'الإجمالي النهائي',
            onConfirm: () {},
          ),
        ],
      ),
    );
  }
}
