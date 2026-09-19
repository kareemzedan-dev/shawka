import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/checkout_tokens.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/checkout_payment_method.dart';
import 'package:matlobgo/models/checkout_quote.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/checkout_repository.dart';
import 'package:matlobgo/screens/home/addresses/addresses_screen.dart';
import 'package:matlobgo/screens/home/addresses/map_address_picker_screen.dart';
import 'package:matlobgo/screens/home/checkout/checkout_controller.dart';
import 'package:matlobgo/screens/home/checkout/checkout_draft.dart';
import 'package:matlobgo/screens/home/checkout/checkout_navigation.dart';
import 'package:matlobgo/screens/home/checkout/guest_checkout_gate.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_address_card.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_banners.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_confirm_bar.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_coupon_card.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_order_line.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_payment_card.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_price_summary.dart';
import 'package:matlobgo/screens/home/checkout/widgets/checkout_section.dart';
import 'package:matlobgo/screens/home/widgets/delivery_address_picker_sheet.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/services/delivery_address_session.dart';
import 'package:matlobgo/services/theme_service.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cartService,
    required this.governorate,
    required this.user,
    required this.initialDraft,
    this.onGoHome,
    this.onOrderPlaced,
  });

  final CartService cartService;
  final Governorate governorate;
  final AppUser? user;
  final CheckoutDraft initialDraft;
  final VoidCallback? onGoHome;
  final VoidCallback? onOrderPlaced;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _couponController = TextEditingController();
  CheckoutController? _controller;

  @override
  void initState() {
    super.initState();
    _couponController.text = widget.initialDraft.initialCouponCode;
    final user = widget.user;
    if (user != null) {
      _controller = CheckoutController(
        governorate: widget.governorate,
        user: user,
        draft: widget.initialDraft,
        repository: CheckoutRepository(cartService: widget.cartService),
      );
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _editAddress() async {
    final user = widget.user;
    if (user != null) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final palette =
              Theme.of(ctx).extension<AppPalette>() ?? AppPalette.light;
          return Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.bookmark_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'اختيار من عناويني',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'العناوين المحفوظة في حسابك',
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(ctx, 'saved'),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.map_rounded,
                      color: AppColors.navy,
                    ),
                    title: Text(
                      'عنوان جديد على الخريطة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'ابحث وحرّك الدبوس بدقة',
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(ctx, 'map'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.search_rounded,
                      color: palette.textSecondary,
                    ),
                    title: Text(
                      'بحث سريع',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                    ),
                    onTap: () => Navigator.pop(ctx, 'search'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
      if (!mounted || choice == null) return;

      DeliveryAddress? result;
      if (choice == 'saved') {
        result = await Navigator.of(context).push<DeliveryAddress>(
          MaterialPageRoute(
            builder: (_) => AddressesScreen(
              user: user,
              governorate: widget.governorate,
              selectionMode: true,
            ),
          ),
        );
      } else if (choice == 'map') {
        result = await openMapAddressPicker(
          context,
          governorate: widget.governorate,
          initial: _controller?.deliveryAddress ??
              widget.initialDraft.deliveryAddress,
          title: 'عنوان التوصيل',
        );
      } else {
        result = await showDeliveryAddressPicker(
          context,
          governorate: widget.governorate,
          cartService: widget.cartService,
          initial: _controller?.deliveryAddress ??
              widget.initialDraft.deliveryAddress,
          user: user,
        );
      }
      if (result == null || !mounted) return;
      DeliveryAddressSession.instance.setAddress(result);
      _controller?.setAddress(result);
      HapticFeedback.lightImpact();
      return;
    }

    final result = await showDeliveryAddressPicker(
      context,
      governorate: widget.governorate,
      cartService: widget.cartService,
      initial: _controller?.deliveryAddress ?? widget.initialDraft.deliveryAddress,
      user: widget.user,
    );
    if (result == null || !mounted) return;
    DeliveryAddressSession.instance.setAddress(result);
    _controller?.setAddress(result);
    HapticFeedback.lightImpact();
  }

  CartItem? _cartItemFor(CheckoutResolvedLine line) =>
      _controller?.cartItemFor(line);

  Future<void> _confirmOrder() async {
    final approved = await ensureApprovedAccountForCheckout(context);
    if (approved == null || !mounted) return;

    final controller = _controller;
    if (controller == null) return;
    if (!controller.canSubmit) return;

    HapticFeedback.mediumImpact();
    final addressError = controller.repository.validateDeliveryAddress(
      controller.deliveryAddress,
    );
    if (addressError != null) {
      await _editAddress();
      return;
    }

    final orders = await controller.placeOrder();
    if (!mounted) return;
    if (orders == null || orders.isEmpty) return;

    final goOrders = widget.onOrderPlaced;
    final paymentLabel = controller.selectedPaymentMethod?.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      goOrders?.call();
      try {
        replaceCheckoutWithTracking(context, order: orders.first);
      } catch (_) {
        // نجاح الإنشاء مع فشل الانتقال — لا نُنشئ طلباً جديداً؛ نعرض التأكيد.
        openOrderConfirmation(
          context,
          orders: orders,
          onGoHome: widget.onGoHome,
          onGoOrders: goOrders,
          paymentLabel: paymentLabel,
        );
      }
    });
  }

  String _text(String key, String fallback) =>
      CmsTextService.instance.resolve(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Controller يستمع للسلة والجلسة — لا تكرار على cartService لتقليل Rebuilds.
      listenable: Listenable.merge([
        ?_controller,
        CmsTextService.instance,
        ThemeService.instance,
      ]),
      builder: (context, _) {
        final palette = context.palette;
        final controller = _controller;
        final quote = controller?.quote;
        final cartSubtotal = (controller?.items ?? widget.cartService.items)
            .fold<double>(0, (total, item) => total + item.lineTotal);
        final displayError = controller?.displayError;
        final bottomPadding = MediaQuery.paddingOf(context).bottom;

        if ((controller?.isEmpty ?? widget.cartService.isEmpty)) {
          return Scaffold(
            backgroundColor: PremiumBackground.scaffoldColor(context),
            appBar: _appBar(),
            body: AppEmptyState.preset(
              AppEmptyKind.cart,
              onAction: () => Navigator.of(context).pop(),
            ),
          );
        }

        final lines = quote?.resolvedOrders
                .expand((order) => order.lineItems)
                .toList(growable: false) ??
            const <CheckoutResolvedLine>[];
        final sourceItems = controller?.items ?? widget.cartService.items;
        final reviewLines = lines.isNotEmpty
            ? lines
            : sourceItems
                .map(
                  (item) => CheckoutResolvedLine(
                    productId: item.productId,
                    productName: item.productName,
                    quantity: item.quantity,
                    unitPrice: item.price,
                    addonIds: item.addonIds,
                    note: item.note,
                    imageUrl: item.imageUrl ?? '',
                    imageThumbUrl: item.imageThumbUrl ?? '',
                  ),
                )
                .toList(growable: false);
        final busy = controller?.confirming == true ||
            controller?.isPlacing == true ||
            controller?.isLoading == true;

        return Scaffold(
          backgroundColor: PremiumBackground.scaffoldColor(context),
          appBar: _appBar(),
          body: Column(
            children: [
              if (_controller?.isLoading == true)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        CheckoutTokens.pagePadding + 2,
                        CheckoutTokens.space3xl,
                        CheckoutTokens.pagePadding + 2,
                        CheckoutTokens.space3xl + 8,
                      ),
                      children: [
                        if (displayError != null) ...[
                          CheckoutErrorBanner(
                            message: displayError,
                            palette: palette,
                            onRetry: () =>
                                _controller?.refreshQuote(immediate: true),
                          ),
                          const SizedBox(height: CheckoutTokens.space3xl),
                        ],
                        if (_controller?.notice != null) ...[
                          CheckoutNoticeBanner(
                            message: _controller!.notice!,
                            palette: palette,
                          ),
                          const SizedBox(height: CheckoutTokens.space3xl),
                        ],
                        CheckoutSection(
                          title: _text(
                            CmsKeys.checkoutDeliveryTo,
                            'التوصيل إلى',
                          ),
                          child: CheckoutAddressCard(
                            palette: palette,
                            address: (_controller?.deliveryAddress),
                            quote: quote,
                            onEdit: _editAddress,
                            changeLabel: _text(
                              CmsKeys.checkoutChangeAddress,
                              'تعديل',
                            ),
                            addAddressLabel: _text(
                              CmsKeys.checkoutAddAddress,
                              'إضافة عنوان التوصيل',
                            ),
                          ),
                        ),
                        const SizedBox(height: CheckoutTokens.space3xl + 6),
                        CheckoutSection(
                          title: _text(
                            CmsKeys.checkoutPaymentTitle,
                            'طريقة الدفع',
                          ),
                          child: Column(
                            children: [
                              for (final method
                                  in _controller?.paymentMethods ??
                                      const <CheckoutPaymentMethod>[]) ...[
                                CheckoutPaymentCard(
                                  palette: palette,
                                  method: method,
                                  selected:
                                      _controller?.paymentMethodId == method.id,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _controller?.setPaymentMethod(method.id);
                                  },
                                ),
                                if (method != _controller?.paymentMethods.last)
                                  const SizedBox(height: CheckoutTokens.spaceMd),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: CheckoutTokens.space3xl + 6),
                        CheckoutSection(
                          title: _text(
                            CmsKeys.checkoutOrderReviewTitle,
                            'مراجعة الطلب',
                          ),
                          child: CheckoutSurfaceCard(
                            palette: palette,
                            padding: const EdgeInsets.all(
                              CheckoutTokens.spaceXl,
                            ),
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < reviewLines.length;
                                  index++
                                ) ...[
                                  CheckoutOrderLineTile(
                                    palette: palette,
                                    line: reviewLines[index],
                                    cartItem: _cartItemFor(reviewLines[index]),
                                    onQuantityChanged: (quantity) {
                                      final cartItem = _cartItemFor(
                                        reviewLines[index],
                                      );
                                      if (cartItem != null) {
                                        _controller?.updateLineQuantity(
                                          cartItem.id,
                                          quantity,
                                        );
                                      }
                                    },
                                  ),
                                  if (index != reviewLines.length - 1)
                                    Divider(height: 25, color: palette.border),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: CheckoutTokens.spaceXl + 4),
                        CheckoutCouponCard(
                          palette: palette,
                          expanded: (_controller?.couponExpanded == true),
                          code: _controller?.couponCode ?? '',
                          discount: quote?.discountAmount ?? 0,
                          controller: _couponController,
                          title: _text(
                            CmsKeys.checkoutCouponTitle,
                            'هل لديك كود خصم؟',
                          ),
                          hint: _text(
                            CmsKeys.checkoutCouponHint,
                            'أدخل كود الخصم',
                          ),
                          applyLabel: _text(
                            CmsKeys.checkoutApplyCoupon,
                            'تطبيق',
                          ),
                          ctaSubtitle: _text(
                            CmsKeys.checkoutCouponCtaSubtitle,
                            'أضف الكود واستمتع بالخصم',
                          ),
                          savingsTemplate: _text(
                            CmsKeys.checkoutCouponSavings,
                            'تم توفير {amount} ج.م',
                          ),
                          onToggle: () => _controller?.setCouponExpanded(
                            !(_controller?.couponExpanded == true),
                          ),
                          onApply: () =>
                              _controller?.applyCoupon(_couponController.text),
                          onRemove: () {
                            _couponController.clear();
                            _controller?.removeCoupon();
                          },
                        ),
                        const SizedBox(height: CheckoutTokens.space3xl + 6),
                        CheckoutSection(
                          title: _text(
                            CmsKeys.checkoutSummaryTitle,
                            'ملخص الدفع',
                          ),
                          child: CheckoutPriceSummary(
                            palette: palette,
                            quote: quote,
                            fallbackSubtotal: cartSubtotal,
                            loading: controller?.isLoading == true,
                            label: _text,
                            note: _text(
                              CmsKeys.checkoutSummaryNote,
                              'سيتم احتساب الإجمالي النهائي في الشريط أدناه',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CheckoutConfirmBar(
                palette: palette,
                grandTotal: quote?.grandTotal ?? 0,
                loading: busy,
                bottomPadding: bottomPadding,
                label: _text(CmsKeys.checkoutConfirmOrder, 'تأكيد الطلب'),
                totalLabel: _text(CmsKeys.checkoutTotal, 'الإجمالي النهائي'),
                onConfirm: busy || _controller?.canSubmit != true
                    ? null
                    : _confirmOrder,
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      toolbarHeight: 82,
      backgroundColor: CheckoutTokens.headerColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: CheckoutTokens.pagePadding + 2,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(CmsKeys.checkoutTitle, 'إتمام الطلب'),
            style: CartTypography.style(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            _text(CmsKeys.checkoutSubtitle, 'باقي خطوة واحدة ويبدأ تجهيز طلبك'),
            style: CartTypography.style(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      leadingWidth: 66,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 14),
        child: Center(
          child: Semantics(
            button: true,
            label: 'رجوع',
            child: Material(
              color: Colors.white.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_forward_rounded, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
