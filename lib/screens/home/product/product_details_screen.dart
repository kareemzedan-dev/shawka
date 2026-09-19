import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/product/product_details_controller.dart';
import 'package:matlobgo/screens/home/product/product_details_navigation.dart';
import 'package:matlobgo/screens/home/product/widgets/product_add_to_cart_bar.dart';
import 'package:matlobgo/screens/home/product/widgets/product_addons.dart';
import 'package:matlobgo/screens/home/product/widgets/product_attributes.dart';
import 'package:matlobgo/screens/home/product/widgets/product_description_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_hero.dart';
import 'package:matlobgo/screens/home/product/widgets/product_notes_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_price_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_quantity_card.dart';
import 'package:matlobgo/screens/home/product/widgets/product_state_views.dart';
import 'package:matlobgo/screens/home/product/widgets/product_suggested_section.dart';
import 'package:matlobgo/screens/home/store_detail_screen.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/theme_service.dart';

/// شاشة تفاصيل المنتج — تكوين رفيع فقط (Controller + Widgets).
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.store,
    required this.product,
    required this.relatedProducts,
    required this.cartService,
  });

  final Store store;
  final Product product;
  final List<Product> relatedProducts;
  final CartService cartService;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final ProductDetailsController _controller;
  late final TextEditingController _notesController;
  bool _successHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = ProductDetailsController(
      initialStore: widget.store,
      initialProduct: widget.product,
      relatedProducts: widget.relatedProducts,
      cartService: widget.cartService,
    );
    _notesController = TextEditingController(text: _controller.note);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _notesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final notice = _controller.notice;
    if (notice != null) {
      _showNotice(notice);
      _controller.clearNotice();
    }
    if (_controller.ctaState == ProductCtaState.success && !_successHandled) {
      _successHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccessSheet());
    } else if (_controller.ctaState != ProductCtaState.success) {
      _successHandled = false;
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: CartTypography.style(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
        ),
      );
  }

  Future<void> _onShare() async {
    await _controller.share();
    if (!mounted) return;
    _showNotice('تم نسخ تفاصيل المنتج للمشاركة');
  }

  void _onViewAll() {
    Navigator.of(context).pop();
    openStoreDetail(
      context,
      store: _controller.store,
      cartService: widget.cartService,
    );
  }

  void _openSuggestion(Product product) {
    replaceWithProductDetail(
      context,
      store: _controller.store,
      product: product,
      relatedProducts: _controller.suggestions
          .where((p) => p.id != product.id)
          .toList(growable: false),
      cartService: widget.cartService,
    );
  }

  Future<void> _showSuccessSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddedToCartSheet(
        onViewCart: () {
          Navigator.pop(sheetContext);
          Navigator.of(context).maybePop();
        },
        onContinue: () => Navigator.pop(sheetContext),
      ),
    );
    _controller.acknowledgeCtaSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, ThemeService.instance]),
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: ProductTokens.sheet,
            resizeToAvoidBottomInset: true,
            body: _buildBody(context),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.productMissing) {
      return SafeArea(
        child: ProductMessageView.unavailable(
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomClearance =
        ProductTokens.ctaHeight + bottomInset + ProductTokens.space3xl * 2;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductHero(
                    store: _controller.store,
                    product: _controller.product,
                    isFavorite: _controller.isFavorite,
                    onBack: () => Navigator.of(context).maybePop(),
                    onShare: _onShare,
                    onToggleFavorite: _controller.toggleFavorite,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -ProductTokens.sheetOverlap),
                    child: _sheet(bottomClearance),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ProductAddToCartBar(
            state: _controller.isPurchasable
                ? _controller.ctaState
                : ProductCtaState.disabled,
            total: _controller.lineTotal,
            unavailableReason: _controller.unavailableReason,
            onAdd: _controller.addToCart,
          ),
        ),
      ],
    );
  }

  Widget _sheet(double bottomClearance) {
    final product = _controller.product;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ProductTokens.sheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ProductTokens.sheetRadius),
        ),
        boxShadow: ProductTokens.sheetShadow,
      ),
      padding: EdgeInsets.fromLTRB(
        ProductTokens.pagePadding,
        ProductTokens.space3xl,
        ProductTokens.pagePadding,
        bottomClearance,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller.offline) const ProductOfflineBanner(),
          ProductPriceSection(product: product),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductDescriptionSection(
            product: product,
            storeName: _controller.store.name,
          ),
          _gapIf(_hasAttributes(product)),
          if (_hasAttributes(product)) ProductAttributes(product: product),
          _gapIf(_controller.availableAddons.isNotEmpty),
          if (_controller.availableAddons.isNotEmpty)
            ProductAddons(
              addons: _controller.availableAddons,
              selectedIds: _controller.selectedAddonIds,
              onToggle: _controller.toggleAddon,
            ),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductQuantityCard(
            quantity: _controller.quantity,
            canIncrement: _controller.canIncrement,
            canDecrement: _controller.canDecrement,
            onIncrement: _controller.increment,
            onDecrement: _controller.decrement,
          ),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductNotesSection(
            controller: _notesController,
            length: _controller.noteLength,
            maxLength: _controller.noteMaxLength,
            onChanged: _controller.setNote,
          ),
          const SizedBox(height: ProductTokens.space3xl + 8),
          ProductSuggestedSection(
            products: _controller.suggestions,
            loading: _controller.suggestionsLoading,
            onViewAll: _onViewAll,
            onProductTap: _openSuggestion,
            onAdd: _controller.addSuggestionToCart,
          ),
        ],
      ),
    );
  }

  bool _hasAttributes(Product product) =>
      product.calories > 0 ||
      product.portionSize.trim().isNotEmpty ||
      product.natureLabel.trim().isNotEmpty;

  Widget _gapIf(bool show) =>
      show ? const SizedBox(height: ProductTokens.space3xl + 4) : const SizedBox.shrink();
}

class _AddedToCartSheet extends StatelessWidget {
  const _AddedToCartSheet({
    required this.onViewCart,
    required this.onContinue,
  });

  final VoidCallback onViewCart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ProductTokens.pagePadding,
        0,
        ProductTokens.pagePadding,
        ProductTokens.space3xl + bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ProductTokens.radiusXl),
          boxShadow: ProductTokens.sheetShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 30,
              ),
            ),
            const SizedBox(height: ProductTokens.spaceXl),
            Text(
              'تمت إضافة المنتج إلى السلة',
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ProductTokens.textPrimary,
              ),
            ),
            const SizedBox(height: ProductTokens.space2xl),
            SizedBox(
              width: double.infinity,
              height: ProductTokens.touchTarget,
              child: FilledButton(
                onPressed: onViewCart,
                style: FilledButton.styleFrom(
                  backgroundColor: ProductTokens.ctaBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
                  ),
                ),
                child: Text(
                  'عرض السلة',
                  style: CartTypography.style(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ProductTokens.spaceMd),
            SizedBox(
              width: double.infinity,
              height: ProductTokens.touchTarget,
              child: OutlinedButton(
                onPressed: onContinue,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ProductTokens.radiusMd),
                  ),
                ),
                child: Text(
                  'متابعة التسوق',
                  style: CartTypography.style(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ProductTokens.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
