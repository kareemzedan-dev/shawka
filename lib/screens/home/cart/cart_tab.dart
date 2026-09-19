import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/cart_repository.dart';
import 'package:matlobgo/screens/home/cart/cart_controller.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_coupon_and_note.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_empty_state.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_free_delivery_card.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_header.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_item_card.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_suggested_products.dart';
import 'package:matlobgo/screens/home/cart/widgets/cart_summary_and_bar.dart';
import 'package:matlobgo/screens/home/checkout/checkout_draft.dart';
import 'package:matlobgo/screens/home/checkout/checkout_navigation.dart';
import 'package:matlobgo/screens/home/checkout/guest_checkout_gate.dart';
import 'package:matlobgo/services/analytics_service.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/services/delivery_address_session.dart';

/// شاشة السلة — Pixel Perfect وفق التصميم المعتمد (بدون عنوان/دفع).
class CartTab extends StatefulWidget {
  const CartTab({
    super.key,
    required this.cartService,
    required this.governorate,
    this.user,
    this.onGoHome,
    this.onOrderPlaced,
  });

  final CartService cartService;
  final Governorate governorate;
  final AppUser? user;
  final VoidCallback? onGoHome;
  final VoidCallback? onOrderPlaced;

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  late final CartController _controller;
  late final TextEditingController _noteController;
  late final TextEditingController _couponController;
  bool _continuing = false;

  @override
  void initState() {
    super.initState();
    _controller = CartController(
      governorateName: widget.governorate.name,
      repository: CartRepository(service: widget.cartService),
    );
    _noteController = TextEditingController(text: _controller.orderNote);
    _couponController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  String _text(String key, String fallback) =>
      CmsTextService.instance.resolve(key, fallback: fallback);

  Future<void> _removeWithUndo(CartItem item, {required bool swipe}) async {
    final removed = _controller.removeItem(item.id, swipe: swipe);
    if (removed == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'تم حذف ${removed.productName}',
          style: CartTypography.style(fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => _controller.restoreItem(removed),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _continue() async {
    if (_continuing) return;
    setState(() => _continuing = true);
    try {
      final settings = AppConfigService.instance.settings;
      if (settings.maintenanceMode) {
        if (!mounted) return;
        showAuthMessage(context, 'التطبيق في وضع الصيانة — حاول لاحقاً');
        return;
      }

      final user = await ensureApprovedAccountForCheckout(context);
      if (user == null || !mounted) return;

      final gate = _controller.validateBeforeCheckout();
      if (gate != null) {
        showAuthMessage(context, gate);
        return;
      }

      final draft = CheckoutDraft(
        deliveryAddress: DeliveryAddressSession.instance.address,
        initialCouponCode: _controller.appliedCoupon?.code ?? '',
        orderNote: _controller.orderNote,
      );

      unawaited(
        AnalyticsService.instance.track(
          type: AnalyticsEventType.continueToCheckout,
          screen: 'cart',
          label: 'متابعة الطلب',
          metadata: {
            'itemCount': _controller.itemCount,
            'subtotal': _controller.subtotal,
            'discount': _controller.discountAmount,
          },
        ),
      );
      unawaited(
        AnalyticsService.instance.track(
          type: AnalyticsEventType.checkoutStart,
          screen: 'checkout',
          label: 'بدء الدفع من السلة',
        ),
      );

      await openCheckoutScreen(
        context,
        cartService: widget.cartService,
        governorate: widget.governorate,
        user: user,
        draft: draft,
        onGoHome: widget.onGoHome,
        onOrderPlaced: widget.onOrderPlaced,
      );
    } finally {
      if (mounted) setState(() => _continuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        CmsTextService.instance,
      ]),
      builder: (context, _) {
        final pageBg = context.palette.background;
        if (_controller.isEmpty) {
          return ColoredBox(
            color: pageBg,
            child: Column(
              children: [
                CartHeader(
                  title: _text(CmsKeys.cartTitle, 'سلة التسوق'),
                  subtitle: _text(
                    CmsKeys.emptyCartSubtitle,
                    'ابدأ بإضافة منتجاتك المفضلة',
                  ),
                  onBack: widget.onGoHome,
                  compact: true,
                ),
                Expanded(
                  child: CartEmptyState(
                    onShop: widget.onGoHome ?? () {},
                    title: _text(CmsKeys.emptyCartTitle, 'سلتك فارغة'),
                    subtitle:
                        'أضف منتجاتك المفضلة وسنجهّزها للتوصيل',
                    actionLabel: 'ابدأ التسوق',
                  ),
                ),
              ],
            ),
          );
        }

        final remaining = _controller.freeDeliveryRemaining;
        final unlocked = _controller.hasFreeDelivery;
        final freeTitle = unlocked
            ? _text(
                CmsKeys.cartFreeDeliveryUnlockedTitle,
                'مبروك! التوصيل مجاني',
              )
            : _text(
                CmsKeys.cartFreeDeliveryNearTitle,
                'توصيل مجاني يقترب!',
              );
        final freeBody = unlocked
            ? _text(
                CmsKeys.cartFreeDeliveryUnlockedBody,
                'وصلت للحد الأدنى — استمتع بالتوصيل المجاني',
              )
            : _text(
                    CmsKeys.cartFreeDeliveryNearBody,
                    'أضف {amount} ج.م للحصول على العرض',
                  )
                  .replaceAll(
                    '{amount}',
                    (remaining ?? 0).toStringAsFixed(0),
                  );

        final showFreeCard = _controller.freeDeliveryEnabled;

        return ColoredBox(
          color: pageBg,
          child: Column(
            children: [
              CartHeader(
                title: _text(CmsKeys.cartTitle, 'سلة التسوق'),
                subtitle: _text(
                  CmsKeys.cartSubtitle,
                  '{count} أصناف في سلتك',
                ).replaceAll('{count}', '${_controller.itemCount}'),
                onBack: widget.onGoHome,
                // مساحة كحلية أسفل النص فقط — البطاقة تتداخل عليها بدون تغطية العنوان
                bottomExtra: showFreeCard ? CartTokens.freeCardOverlap : 0,
              ),
              // بطاقة التوصيل خارج الـ ListView حتى لا يدخل التمرير فوق الهيرو
              if (showFreeCard)
                Transform.translate(
                  offset: const Offset(0, -CartTokens.freeCardOverlap),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CartFreeDeliveryCard(
                        title: freeTitle,
                        body: freeBody,
                        progress: _controller.freeDeliveryProgress,
                        unlocked: unlocked,
                      ),
                      const SizedBox(height: CartTokens.freeCardOverlap),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.fromLTRB(
                        CartTokens.pagePadding,
                        showFreeCard
                            ? CartTokens.spaceSm
                            : CartTokens.spaceMd,
                        CartTokens.pagePadding,
                        CartTokens.listBottomClearance,
                      ),
                      children: [
                        if (_controller.offline ||
                            _controller.notice != null ||
                            _controller.error != null) ...[
                          _Banner(
                            message: _controller.error ??
                                (_controller.offline
                                    ? 'أنت غير متصل — بعض البيانات قد تكون قديمة'
                                    : _controller.notice!),
                            isError: _controller.error != null ||
                                _controller.offline,
                            onClose: _controller.clearNotice,
                          ),
                          const SizedBox(height: CartTokens.spaceLg),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _text(
                                  CmsKeys.cartSelectedItemsTitle,
                                  'الأصناف المختارة',
                                ),
                                style: CartTypography.style(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      'مسح السلة؟',
                                      style: CartTypography.style(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    content: Text(
                                      'سيتم حذف جميع المنتجات من سلتك.',
                                      style: CartTypography.style(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(
                                          'إلغاء',
                                          style: CartTypography.style(),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          'مسح الكل',
                                          style: CartTypography.style(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  _controller.clearAll();
                                }
                              },
                              child: Text(
                                _text(CmsKeys.cartClearAll, 'مسح الكل'),
                                style: CartTypography.style(
                                  fontWeight: FontWeight.w800,
                                  color: CartTokens.accentText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: CartTokens.spaceMd),
                        for (final item in _controller.items) ...[
                          CartItemCard(
                            item: item,
                            maxQuantity: _controller.maxQuantityFor(item),
                            onQuantityChanged: (qty) =>
                                _controller.updateQuantity(item.id, qty),
                            onRemove: () =>
                                _removeWithUndo(item, swipe: false),
                            onSwiped: () =>
                                _removeWithUndo(item, swipe: true),
                          ),
                          const SizedBox(height: CartTokens.spaceMd),
                        ],
                        const SizedBox(height: 6),
                        CartOrderNoteField(
                          controller: _noteController,
                          hint: _text(
                            CmsKeys.cartOrderNoteHint,
                            'إضافة ملاحظة للطلب...',
                          ),
                          onChanged: _controller.setOrderNote,
                        ),
                        const SizedBox(height: CartTokens.spaceLg),
                        CartCouponCard(
                          title: _text(
                            CmsKeys.cartCouponTitle,
                            'كوبون الخصم',
                          ),
                          applyLabel: _text(
                            CmsKeys.cartCouponApply,
                            'تطبيق',
                          ),
                          controller: _couponController,
                          busy: _controller.couponBusy,
                          appliedCode: _controller.appliedCoupon?.code,
                          onApply: () =>
                              _controller.applyCoupon(_couponController.text),
                          onRemove: () {
                            _couponController.clear();
                            _controller.removeCoupon();
                          },
                        ),
                        if (_controller.suggestionsEnabled) ...[
                          const SizedBox(height: CartTokens.space3xl),
                          CartSuggestedProductsSection(
                            title: _text(
                              CmsKeys.cartSuggestionsTitle,
                              'مقترحات لك',
                            ),
                            products: _controller.suggestions,
                            loading: _controller.suggestionsLoading,
                            onAdd: (product) {
                              unawaited(_controller.addSuggestion(product));
                            },
                          ),
                        ],
                        const SizedBox(height: CartTokens.space3xl),
                        CartPriceSummary(
                          itemCount: _controller.itemCount,
                          subtotal: _controller.subtotal,
                          discount: _controller.discountAmount,
                          subtotalLabel: _text(
                            CmsKeys.cartSubtotal,
                            'المجموع الفرعي',
                          ),
                          discountLabel: _text(
                            CmsKeys.cartDiscountTotal,
                            'إجمالي الخصم',
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CartContinueBar(
                        totalLabel: _text(CmsKeys.cartTotal, 'المجموع'),
                        total: _controller.currentTotal,
                        ctaLabel: _text(CmsKeys.cartContinue, 'متابعة الطلب'),
                        enabled: !_continuing,
                        onContinue: _continuing ? null : _continue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.isError,
    required this.onClose,
  });

  final String message;
  final bool isError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: CartTypography.style(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}
