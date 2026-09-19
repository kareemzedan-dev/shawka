import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/product_addon.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/product/product_details_controller.dart';
import 'package:matlobgo/screens/home/product/widgets/product_add_to_cart_bar.dart';
import 'package:matlobgo/screens/home/product/widgets/product_addons.dart';
import 'package:matlobgo/screens/home/product/widgets/product_attributes.dart';
import 'package:matlobgo/screens/home/product/widgets/product_description_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_notes_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_price_section.dart';
import 'package:matlobgo/screens/home/product/widgets/product_quantity_card.dart';
import 'package:matlobgo/screens/home/product/widgets/product_suggested_section.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_analytics_service.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/services/tarfa_cart_drawer_controller.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_product_hero.dart';

class WebProductScreen extends StatefulWidget {
  const WebProductScreen({
    super.key,
    required this.storeId,
    required this.productId,
  });

  final String storeId;
  final String productId;

  @override
  State<WebProductScreen> createState() => _WebProductScreenState();
}

class _WebProductScreenState extends State<WebProductScreen> {
  final _catalog = CatalogService();
  Store? _store;
  Product? _product;
  List<Product> _suggestions = const [];
  bool _loading = true;
  bool _notFound = false;

  int _quantity = 1;
  final Set<String> _selectedAddonIds = {};
  final _notesController = TextEditingController();
  String _note = '';
  ProductCtaState _ctaState = ProductCtaState.normal;
  bool _successHandled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = await _catalog.getStore(widget.storeId);
    if (!mounted) return;
    if (store == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    final products = await _catalog.watchProducts(store).first;
    if (!mounted) return;

    final product =
        products.where((p) => p.id == widget.productId).firstOrNull;
    if (product == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    final suggestions = products
        .where((p) => p.id != product.id && p.isInStock)
        .take(10)
        .toList(growable: false);

    setState(() {
      _store = store;
      _product = product;
      _suggestions = suggestions;
      _loading = false;
    });

    WebAnalyticsService.instance.productOpen(store: store, product: product);
    WebSeoService.instance.apply(
      title: '${product.name} — ${store.name}',
      description:
          product.description ?? 'اطلب ${product.name} من ${store.name}',
      canonicalPath: WebConstants.productPath(store.id, product.id),
      imageUrl: product.imageUrl,
      jsonLd: {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'name': product.name,
        'image': product.imageUrl,
        'offers': {
          '@type': 'Offer',
          'price': product.price,
          'priceCurrency': 'EGP',
        },
      },
    );
  }

  List<ProductAddon> get _availableAddons =>
      _product?.addons.where((a) => a.isAvailable).toList(growable: false) ??
      const [];

  double get _addonsTotal => _availableAddons
      .where((a) => _selectedAddonIds.contains(a.id))
      .fold(0.0, (sum, a) => sum + a.price);

  double get _unitPrice => (_product?.price ?? 0) + _addonsTotal;

  double get _lineTotal => _unitPrice * _quantity;

  int get _maxQuantity {
    final product = _product;
    if (product == null) return 1;
    if (product.trackStock) {
      return product.stockQuantity > 0 ? product.stockQuantity : 1;
    }
    return 99;
  }

  bool get _isPurchasable {
    final store = _store;
    final product = _product;
    if (store == null || product == null) return false;
    return product.isInStock && store.isSellable;
  }

  String? get _unavailableReason {
    final store = _store;
    final product = _product;
    if (store == null || product == null) return 'المنتج غير متاح';
    if (!product.isAvailable) return 'المنتج غير متاح حالياً';
    if (product.trackStock && product.stockQuantity <= 0) {
      return 'نفد المخزون';
    }
    if (!store.isSellable) return 'المتجر مغلق حالياً';
    return null;
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
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
    final store = _store;
    final product = _product;
    if (store == null || product == null) return;
    final text =
        '${product.name}\n${product.price.toStringAsFixed(0)} ج.م · ${store.name}';
    await Clipboard.setData(ClipboardData(text: text));
    _showNotice('تم نسخ تفاصيل المنتج للمشاركة');
  }

  void _increment() {
    if (_quantity >= _maxQuantity) {
      _showNotice('وصلت للحد الأقصى المتاح من المخزون');
      return;
    }
    setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
  }

  void _toggleAddon(String addonId) {
    setState(() {
      if (_selectedAddonIds.contains(addonId)) {
        _selectedAddonIds.remove(addonId);
      } else {
        _selectedAddonIds.add(addonId);
      }
      if (_ctaState == ProductCtaState.success) {
        _ctaState = ProductCtaState.normal;
      }
    });
  }

  void _setNote(String value) {
    final next = value.length > 200 ? value.substring(0, 200) : value;
    if (next == _note) return;
    setState(() => _note = next);
  }

  String _displayName() {
    final product = _product!;
    final labels = _availableAddons
        .where((a) => _selectedAddonIds.contains(a.id))
        .map((a) => a.name)
        .toList();
    var name = product.name;
    if (labels.isNotEmpty) name = '$name (${labels.join('، ')})';
    final note = _note.trim();
    if (note.isNotEmpty) name = '$name • $note';
    return name;
  }

  Future<void> _addToCart() async {
    if (_ctaState == ProductCtaState.loading) return;
    final store = _store;
    final product = _product;
    if (store == null || product == null) return;

    final blockReason = _unavailableReason;
    if (blockReason != null) {
      _showNotice(blockReason);
      setState(() => _ctaState = ProductCtaState.error);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _ctaState == ProductCtaState.error) {
          setState(() => _ctaState = ProductCtaState.normal);
        }
      });
      return;
    }

    setState(() => _ctaState = ProductCtaState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 280));

    final ok = WebCartService.instance.addProduct(
      store: store,
      product: product,
      quantity: _quantity,
      unitPrice: _unitPrice,
      displayName: _displayName(),
    );

    if (!mounted) return;
    if (!ok) {
      setState(() => _ctaState = ProductCtaState.error);
      _showNotice('المتجر مغلق حالياً — لا يمكن الطلب الآن');
      return;
    }

    setState(() => _ctaState = ProductCtaState.success);
    if (!_successHandled) {
      _successHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccessSheet());
    }
  }

  void _addSuggestionToCart(Product suggestion) {
    final store = _store;
    if (store == null) return;
    if (!store.isSellable || !suggestion.isInStock) {
      _showNotice('تعذّرت الإضافة — المنتج أو المتجر غير متاح');
      return;
    }
    WebCartService.instance.addProduct(
      store: store,
      product: suggestion,
      quantity: 1,
      unitPrice: suggestion.price,
    );
    _showNotice('تمت إضافة ${suggestion.name} إلى السلة');
  }

  Future<void> _showSuccessSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddedToCartSheet(
        onViewCart: () {
          Navigator.pop(sheetContext);
          TarfaCartDrawerController.instance.open();
        },
        onContinue: () => Navigator.pop(sheetContext),
      ),
    );
    if (mounted) {
      setState(() {
        _ctaState = ProductCtaState.normal;
        _successHandled = false;
      });
    }
  }

  bool _hasAttributes(Product product) =>
      product.calories > 0 ||
      product.portionSize.trim().isNotEmpty ||
      product.natureLabel.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: ProductTokens.sheet,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _store == null || _product == null) {
      return Scaffold(
        backgroundColor: ProductTokens.sheet,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: ProductTokens.textMuted,
                ),
                const SizedBox(height: ProductTokens.spaceXl),
                Text(
                  'المنتج غير متاح',
                  style: CartTypography.style(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ProductTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: ProductTokens.space2xl),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('رجوع'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final store = _store!;
    final product = _product!;
    final isWide = MediaQuery.sizeOf(context).width >= TarfaTokens.tabletBreakpoint;
    final heroHeight = isWide ? 380.0 : ProductTokens.heroHeight;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomClearance =
        ProductTokens.ctaHeight + bottomInset + ProductTokens.space3xl * 2;

    return Scaffold(
      backgroundColor: ProductTokens.sheet,
      resizeToAvoidBottomInset: true,
      body: Stack(
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
                    TarfaProductHero(
                      store: store,
                      product: product,
                      heroHeight: heroHeight,
                      onBack: () => context.pop(),
                      onShare: _onShare,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -ProductTokens.sheetOverlap),
                      child: _sheet(store, product, bottomClearance),
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
              state: _isPurchasable
                  ? _ctaState
                  : ProductCtaState.disabled,
              total: _lineTotal,
              unavailableReason: _unavailableReason,
              onAdd: _addToCart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheet(Store store, Product product, double bottomClearance) {
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
          ProductPriceSection(product: product),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductDescriptionSection(
            product: product,
            storeName: store.name,
          ),
          _gapIf(_hasAttributes(product)),
          if (_hasAttributes(product)) ProductAttributes(product: product),
          _gapIf(_availableAddons.isNotEmpty),
          if (_availableAddons.isNotEmpty)
            ProductAddons(
              addons: _availableAddons,
              selectedIds: _selectedAddonIds,
              onToggle: _toggleAddon,
            ),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductQuantityCard(
            quantity: _quantity,
            canIncrement: _quantity < _maxQuantity,
            canDecrement: _quantity > 1,
            onIncrement: _increment,
            onDecrement: _decrement,
          ),
          const SizedBox(height: ProductTokens.space3xl + 4),
          ProductNotesSection(
            controller: _notesController,
            length: _note.length,
            maxLength: 200,
            onChanged: _setNote,
          ),
          const SizedBox(height: ProductTokens.space3xl + 8),
          ProductSuggestedSection(
            products: _suggestions,
            loading: false,
            onViewAll: () => context.push(WebConstants.storePath(store.id)),
            onProductTap: (p) => context.push(
              WebConstants.productPath(store.id, p.id),
            ),
            onAdd: _addSuggestionToCart,
          ),
        ],
      ),
    );
  }

  Widget _gapIf(bool show) => show
      ? const SizedBox(height: ProductTokens.space3xl + 4)
      : const SizedBox.shrink();
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
