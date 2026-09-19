import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/promotion.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/cart_promo_resolver.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/screens/home/widgets/cart_item_thumbnail.dart';

/// UI-only promo codes for cart (لا يغيّر منطق الطلب في الخادم).
class CartPromoOffer {
  const CartPromoOffer({
    required this.code,
    required this.title,
    required this.discountFor,
  });

  final String code;
  final String title;
  final double Function(double subtotal) discountFor;

  static CartPromoOffer? resolve(String raw) {
    final code = raw.trim().toUpperCase();
    for (final offer in _catalog) {
      if (offer.code == code) return offer;
    }
    return null;
  }

  factory CartPromoOffer.fromPromotion(Promotion promo) {
    return CartPromoOffer(
      code: promo.code,
      title: promo.title,
      discountFor: (subtotal) {
        if (subtotal < promo.minOrderAmount) return 0;
        return promo.discountFor(subtotal);
      },
    );
  }

  static const _catalog = [
    CartPromoOffer(
      code: 'MATLOB10',
      title: 'خصم 10% على المنتجات',
      discountFor: _percent10,
    ),
    CartPromoOffer(
      code: 'WELCOME15',
      title: 'خصم 15 ج.م ترحيبي',
      discountFor: _flat15,
    ),
    CartPromoOffer(
      code: 'FREE5',
      title: 'خصم 5 ج.م',
      discountFor: _flat5,
    ),
  ];

  static double _percent10(double subtotal) => (subtotal * 0.1).clamp(0, 80);

  static double _flat15(double subtotal) =>
      subtotal >= 50 ? 15 : 0;

  static double _flat5(double subtotal) =>
      subtotal >= 30 ? 5 : 0;
}

/// عرض وسيلة الدفع (UI فقط).
enum CartPaymentUi { cash, card, wallet }

extension CartPaymentUiX on CartPaymentUi {
  String get emojiLabel => switch (this) {
        CartPaymentUi.cash => '💵 الدفع عند الاستلام',
        CartPaymentUi.card => '💳 بطاقة بنكية',
        CartPaymentUi.wallet => '📱 محفظة إلكترونية',
      };

  String get checkoutSubtitle => switch (this) {
        CartPaymentUi.cash => 'ادفع نقداً عند استلام الطلب',
        CartPaymentUi.card => 'Visa **** 4582',
        CartPaymentUi.wallet => 'فودافون كاش / محفظة',
      };

  String get confirmationLabel => switch (this) {
        CartPaymentUi.cash => 'الدفع عند الاستلام',
        CartPaymentUi.card => 'بطاقة بنكية',
        CartPaymentUi.wallet => 'محفظة إلكترونية',
      };

  IconData get icon => switch (this) {
        CartPaymentUi.cash => Icons.payments_rounded,
        CartPaymentUi.card => Icons.credit_card_rounded,
        CartPaymentUi.wallet => Icons.account_balance_wallet_rounded,
      };

}

/// وسائل الدفع المعروضة في السلة والـ Checkout.
const kCartPaymentOptions = [
  CartPaymentUi.cash,
  CartPaymentUi.card,
  CartPaymentUi.wallet,
];

/// 📍 عنوان التوصيل
class CartAddressPreview extends StatelessWidget {
  const CartAddressPreview({
    super.key,
    required this.hasAddress,
    this.areaLine = '',
    this.streetLine = '',
    this.displayPrimary,
    this.displaySecondary,
    required this.palette,
    required this.onAddOrChange,
  });

  final bool hasAddress;
  final String areaLine;
  final String streetLine;
  final String? displayPrimary;
  final String? displaySecondary;
  final AppPalette palette;
  final VoidCallback onAddOrChange;

  @override
  Widget build(BuildContext context) {
    return _CartSurfaceCard(
      palette: palette,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: HomeTheme.borderSm,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasAddress) ...[
                  Text(
                    'لم يتم تحديد عنوان التوصيل',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أضف عنوانك لإتمام الطلب بسرعة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.textSecondary,
                    ),
                  ),
                ] else ...[
                  Text(
                    '📍 ${displayPrimary ?? areaLine}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((displaySecondary ?? streetLine).trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      displaySecondary ?? streetLine,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onAddOrChange,
            child: Text(
              hasAddress ? 'تغيير' : 'إضافة عنوان',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 💳 وسيلة الدفع
class CartPaymentPreview extends StatelessWidget {
  const CartPaymentPreview({
    super.key,
    required this.payment,
    required this.palette,
    required this.onChange,
  });

  final CartPaymentUi payment;
  final AppPalette palette;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return _CartSurfaceCard(
      palette: palette,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: HomeTheme.borderSm,
              border: Border.all(color: palette.border),
            ),
            child: Icon(payment.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وسيلة الدفع',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        payment.emojiLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment == CartPaymentUi.cash ? 'افتراضي' : 'محفوظة',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(
              'تعديل',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎟 كوبون الخصم
class CartPromoSection extends StatefulWidget {
  const CartPromoSection({
    super.key,
    required this.palette,
    required this.applied,
    required this.onApply,
    required this.onClear,
    this.storeIdsInCart = const {},
  });

  final AppPalette palette;
  final CartPromoOffer? applied;
  final ValueChanged<CartPromoOffer> onApply;
  final VoidCallback onClear;
  final Set<String> storeIdsInCart;

  @override
  State<CartPromoSection> createState() => _CartPromoSectionState();
}

class _CartPromoSectionState extends State<CartPromoSection>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _error;
  late final AnimationController _appliedPop;
  late final Animation<double> _appliedScale;

  @override
  void initState() {
    super.initState();
    _appliedPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _appliedScale = CurvedAnimation(
      parent: _appliedPop,
      curve: Curves.elasticOut,
    );
    if (widget.applied != null) _appliedPop.value = 1;
  }

  @override
  void didUpdateWidget(CartPromoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.applied != null && oldWidget.applied == null) {
      _appliedPop.forward(from: 0);
    }
    if (widget.applied == null) _appliedPop.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    _appliedPop.dispose();
    super.dispose();
  }

  void _submit() {
    final offer = CartPromoResolver.resolve(
      _controller.text,
      storeIdsInCart: widget.storeIdsInCart,
    );
    if (offer == null) {
      setState(() => _error = 'كود غير صالح — جرّب MATLOB10 أو كود من لوحة التحكم');
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _error = null);
    HapticFeedback.lightImpact();
    widget.onApply(offer);
    _appliedPop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.applied;
    return _CartSurfaceCard(
      palette: widget.palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🎟 كوبون الخصم',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: widget.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CmsTextService.instance.promoHint(),
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              color: widget.palette.textSecondary,
            ),
          ),
          if (applied != null) ...[
            const SizedBox(height: 10),
            ScaleTransition(
              scale: _appliedScale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: widget.palette.isDark ? 0.18 : 0.1,
                  ),
                  borderRadius: HomeTheme.borderSm,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${applied.code} — ${applied.title}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _controller.clear();
                        widget.onClear();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: widget.palette.textHint,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      color: widget.palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'أدخل الكود',
                      hintStyle: GoogleFonts.cairo(
                        color: widget.palette.textHint,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: widget.palette.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: HomeTheme.borderSm,
                        borderSide: BorderSide(color: widget.palette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: HomeTheme.borderSm,
                        borderSide: BorderSide(color: widget.palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: HomeTheme.borderSm,
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: HomeTheme.borderSm,
                    ),
                  ),
                  child: Text(
                    'تطبيق',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// ملخص الطلب
class CartOrderSummaryCard extends StatelessWidget {
  const CartOrderSummaryCard({
    super.key,
    required this.palette,
    required this.subtotal,
    required this.deliveryFee,
    required this.rawDeliveryFee,
    required this.discount,
    required this.hasFreeDelivery,
    this.distanceKm,
    this.deliveryBlockedMessage,
  });

  final AppPalette palette;
  final double subtotal;
  final double deliveryFee;
  final double rawDeliveryFee;
  final double discount;
  final bool hasFreeDelivery;
  final double? distanceKm;
  final String? deliveryBlockedMessage;

  double get grandTotal =>
      (subtotal + deliveryFee - discount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    return _CartSurfaceCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ملخص الطلب',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryLine(
            palette: palette,
            label: 'إجمالي المنتجات',
            value: '${subtotal.toStringAsFixed(0)} ج.م',
          ),
          const SizedBox(height: 8),
          if (distanceKm != null && distanceKm! > 0) ...[
            _SummaryLine(
              palette: palette,
              label: 'مسافة التوصيل',
              value: '${distanceKm!.toStringAsFixed(1)} كم',
            ),
            const SizedBox(height: 8),
          ],
          _SummaryLine(
            palette: palette,
            label: 'رسوم التوصيل',
            value: deliveryBlockedMessage != null
                ? 'غير متاح'
                : (hasFreeDelivery
                    ? 'مجاني'
                    : '${deliveryFee.toStringAsFixed(0)} ج.م'),
            valueColor: deliveryBlockedMessage != null
                ? AppColors.error
                : (hasFreeDelivery ? AppColors.success : null),
            strikeValue: hasFreeDelivery && rawDeliveryFee > 0
                ? '${rawDeliveryFee.toStringAsFixed(0)} ج.م'
                : null,
          ),
          if (deliveryBlockedMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              deliveryBlockedMessage!,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _SummaryLine(
              palette: palette,
              label: 'الخصومات',
              value: '- ${discount.toStringAsFixed(0)} ج.م',
              valueColor: AppColors.success,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: palette.border, height: 1),
          ),
          _SummaryLine(
            palette: palette,
            label: 'الإجمالي النهائي',
            value: '${grandTotal.toStringAsFixed(0)} ج.م',
            bold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.palette,
    required this.label,
    required this.value,
    this.valueColor,
    this.strikeValue,
    this.bold = false,
  });

  final AppPalette palette;
  final String label;
  final String value;
  final Color? valueColor;
  final String? strikeValue;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ),
        if (strikeValue != null) ...[
          Text(
            strikeValue!,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: palette.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: bold ? 17 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Premium sticky checkout bar
class CartPremiumCheckoutBar extends StatefulWidget {
  const CartPremiumCheckoutBar({
    super.key,
    required this.palette,
    required this.grandTotal,
    required this.itemCount,
    this.onCheckout,
    this.loading = false,
    this.pulseTotal = false,
  });

  final AppPalette palette;
  final double grandTotal;
  final int itemCount;
  final VoidCallback? onCheckout;
  final bool loading;
  final bool pulseTotal;

  @override
  State<CartPremiumCheckoutBar> createState() => _CartPremiumCheckoutBarState();
}

class _CartPremiumCheckoutBarState extends State<CartPremiumCheckoutBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(CartPremiumCheckoutBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseTotal && oldWidget.grandTotal != widget.grandTotal) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final itemsLabel = widget.itemCount == 1
        ? 'عنصر واحد'
        : '${widget.itemCount} عناصر';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.palette.card,
        border: Border(top: BorderSide(color: widget.palette.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(
              alpha: widget.palette.isDark ? 0.45 : 0.1,
            ),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 14, 18, 12 + bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 1, end: 1.05).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
                    ),
                    child: Text(
                      '${widget.grandTotal.toStringAsFixed(0)} ج.م',
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.05,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    itemsLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 148,
              child: _CheckoutCta(
                loading: widget.loading,
                onTap: widget.onCheckout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutCta extends StatefulWidget {
  const _CheckoutCta({required this.loading, this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_CheckoutCta> createState() => _CheckoutCtaState();
}

class _CheckoutCtaState extends State<_CheckoutCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: HomeTheme.animPress,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.loading ? null : widget.onTap,
            borderRadius: HomeTheme.borderMd,
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: HomeTheme.borderMd,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: widget.loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      'متابعة الطلب',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class CartPremiumStoreGroup extends StatelessWidget {
  const CartPremiumStoreGroup({
    super.key,
    required this.storeName,
    required this.category,
    required this.items,
    required this.palette,
    required this.onUpdate,
    required this.onRemove,
  });

  final String storeName;
  final String category;
  final List<CartItem> items;
  final AppPalette palette;
  final void Function(String id, int qty) onUpdate;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    return _CartSurfaceCard(
      palette: palette,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  storeCategoryIcon(category),
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeName,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.border),
          for (var i = 0; i < items.length; i++) ...[
            CartPremiumItemTile(
              key: ValueKey(items[i].id),
              item: items[i],
              palette: palette,
              onUpdate: onUpdate,
              onRemove: onRemove,
            ),
            if (i < items.length - 1)
              Divider(height: 1, indent: 16, endIndent: 16, color: palette.border),
          ],
        ],
      ),
    );
  }
}

class CartPremiumItemTile extends StatefulWidget {
  const CartPremiumItemTile({
    super.key,
    required this.item,
    required this.palette,
    required this.onUpdate,
    required this.onRemove,
  });

  final CartItem item;
  final AppPalette palette;
  final void Function(String id, int qty) onUpdate;
  final void Function(String id) onRemove;

  @override
  State<CartPremiumItemTile> createState() => _CartPremiumItemTileState();
}

class _CartPremiumItemTileState extends State<CartPremiumItemTile> {
  bool _removing = false;

  Future<void> _remove() async {
    if (_removing) return;
    setState(() => _removing = true);
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) widget.onRemove(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: HomeTheme.animStandard,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _removing ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CartItemThumbnail(
                item: widget.item,
                palette: widget.palette,
                size: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: widget.palette.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.item.price.toStringAsFixed(0)} ج.م',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CartAnimatedQuantity(
                      quantity: widget.item.quantity,
                      palette: widget.palette,
                      onChanged: (q) {
                        HapticFeedback.selectionClick();
                        widget.onUpdate(widget.item.id, q);
                      },
                    ),
                  ],
                ),
              ),
              Material(
                color: widget.palette.surfaceMuted,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _remove,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: widget.palette.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartAnimatedQuantity extends StatefulWidget {
  const CartAnimatedQuantity({
    super.key,
    required this.quantity,
    required this.palette,
    required this.onChanged,
  });

  final int quantity;
  final AppPalette palette;
  final ValueChanged<int> onChanged;

  @override
  State<CartAnimatedQuantity> createState() => _CartAnimatedQuantityState();
}

class _CartAnimatedQuantityState extends State<CartAnimatedQuantity> {
  int _prev = 1;

  @override
  void didUpdateWidget(CartAnimatedQuantity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _prev = oldWidget.quantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final increasing = widget.quantity >= _prev;
    return Container(
      decoration: BoxDecoration(
        color: widget.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyTap(
            icon: Icons.remove_rounded,
            onTap: () => widget.onChanged(widget.quantity - 1),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) {
              final offset = increasing
                  ? Tween<Offset>(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    ).animate(anim)
                  : Tween<Offset>(
                      begin: const Offset(0, -0.35),
                      end: Offset.zero,
                    ).animate(anim);
              return SlideTransition(
                position: offset,
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: Padding(
              key: ValueKey<int>(widget.quantity),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${widget.quantity}',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: widget.palette.textPrimary,
                ),
              ),
            ),
          ),
          _QtyTap(
            icon: Icons.add_rounded,
            onTap: () => widget.onChanged(widget.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QtyTap extends StatelessWidget {
  const _QtyTap({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: HomeTheme.borderSm,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _CartSurfaceCard extends StatelessWidget {
  const _CartSurfaceCard({
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final AppPalette palette;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: palette.border),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: child,
    );
  }
}

/// Premium free-delivery progress banner.
class CartFreeDeliveryHint extends StatelessWidget {
  const CartFreeDeliveryHint({
    super.key,
    required this.remaining,
    required this.threshold,
    required this.palette,
  });

  final double remaining;
  final double threshold;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (remaining / threshold).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: palette.isDark ? 0.22 : 0.08),
            palette.card,
          ],
        ),
        borderRadius: HomeTheme.borderMd,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🎉 متبقي ${remaining.ceil()} ج.م للحصول على التوصيل المجاني',
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: HomeTheme.animStandard,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: palette.surfaceMuted,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CartFreeDeliveryBadge extends StatelessWidget {
  const CartFreeDeliveryBadge({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: palette.isDark ? 0.25 : 0.14),
            palette.card,
          ],
        ),
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'حصلت على التوصيل المجاني',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 22),
        ],
      ),
    );
  }
}
