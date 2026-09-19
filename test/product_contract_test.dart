import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/theme/product_tokens.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/product_addon.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/product_details_repository.dart';
import 'package:matlobgo/screens/home/product/product_details_controller.dart';
import 'package:matlobgo/services/cart_service.dart';

/// مستودع بديل بلا Firebase — يوفّر بيانات ثابتة لعقد الـ Controller.
class _FakeProductDetailsRepository extends ProductDetailsRepository {
  _FakeProductDetailsRepository({this.cartLine});

  final ({int quantity, String note, List<String> addonIds})? cartLine;

  final List<({Product product, int quantity, double unitPrice})> added = [];

  @override
  Stream<Product?> watchProduct({
    required String storeId,
    required String productId,
  }) =>
      const Stream.empty();

  @override
  Stream<Store?> watchStore(String storeId) => const Stream.empty();

  @override
  Future<List<Product>> fetchSuggestions({
    required String storeId,
    required String excludeProductId,
    String preferredCategory = '',
    int limit = 10,
  }) async =>
      const [];

  bool favorite = false;

  @override
  bool isFavorite(String storeId, String productId) => favorite;

  @override
  Future<void> toggleFavorite(String storeId, String productId) async {
    favorite = !favorite;
  }

  @override
  void addFavoritesListener(VoidCallback listener) {}

  @override
  void removeFavoritesListener(VoidCallback listener) {}

  @override
  ({int quantity, String note, List<String> addonIds})? existingCartLine({
    required String storeId,
    required String productId,
  }) =>
      cartLine;

  @override
  void addToCart({
    required Store store,
    required Product product,
    required int quantity,
    required double unitPrice,
    required String displayName,
    required String cartLineId,
    required List<String> addonIds,
    required String note,
  }) {
    added.add((product: product, quantity: quantity, unitPrice: unitPrice));
  }
}

Store _store({bool open = true}) => Store(
      id: 's1',
      name: 'مطعم الاختبار',
      categoryId: 'restaurant',
      rating: 4.5,
      deliveryMinutes: 30,
      deliveryFee: 10,
      fallbackOpen: open,
      tags: const [],
      governorate: 'g1',
      logoUrl: null,
    );

Product _product({
  double price = 50,
  double oldPrice = 0,
  bool bestSeller = false,
  bool trackStock = false,
  int stockQuantity = 0,
  List<ProductAddon> addons = const [],
  int calories = 0,
  String portionSize = '',
  String natureLabel = '',
}) =>
    Product(
      id: 'p1',
      storeId: 's1',
      name: 'برجر',
      price: price,
      oldPrice: oldPrice,
      bestSeller: bestSeller,
      trackStock: trackStock,
      stockQuantity: stockQuantity,
      addons: addons,
      calories: calories,
      portionSize: portionSize,
      natureLabel: natureLabel,
    );

ProductDetailsController _controller(
  _FakeProductDetailsRepository repo, {
  Product? product,
  Store? store,
}) =>
    ProductDetailsController(
      initialStore: store ?? _store(),
      initialProduct: product ?? _product(),
      relatedProducts: const [],
      cartService: CartService.instance,
      repository: repo,
    );

void main() {
  group('ProductTokens contract', () {
    test('hero + sheet tokens match design SSOT', () {
      expect(ProductTokens.heroHeight, 320);
      expect(ProductTokens.sheetRadius, 28);
      expect(ProductTokens.noteMaxLength, 200);
    });

    test('aliases Cart tokens for a consistent CTA/accent', () {
      expect(ProductTokens.ctaBackground, CartTokens.ctaBackground);
      expect(ProductTokens.accentText, CartTokens.accentText);
    });
  });

  group('ProductDetailsController pricing', () {
    test('unit price includes selected available addons only', () {
      final repo = _FakeProductDetailsRepository();
      final controller = _controller(
        repo,
        product: _product(
          price: 50,
          addons: const [
            ProductAddon(id: 'a', name: 'جبنة', price: 10),
            ProductAddon(id: 'b', name: 'صوص', price: 5, isAvailable: false),
          ],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.unitPrice, 50);
      controller.toggleAddon('a');
      expect(controller.unitPrice, 60);
      controller.increment();
      expect(controller.lineTotal, 120);
    });
  });

  group('ProductDetailsController quantity + stock', () {
    test('clamps to stock when tracking and blocks over-increment', () {
      final repo = _FakeProductDetailsRepository();
      final controller = _controller(
        repo,
        product: _product(trackStock: true, stockQuantity: 2),
      );
      addTearDown(controller.dispose);

      expect(controller.maxQuantity, 2);
      controller.increment();
      expect(controller.quantity, 2);
      controller.increment();
      expect(controller.quantity, 2);
      expect(controller.canIncrement, isFalse);
    });
  });

  group('ProductDetailsController notes', () {
    test('enforces 200-char cap', () {
      final repo = _FakeProductDetailsRepository();
      final controller = _controller(repo);
      addTearDown(controller.dispose);

      controller.setNote('x' * 250);
      expect(controller.noteLength, 200);
    });
  });

  group('ProductDetailsController cart restore + add', () {
    test('restores quantity/note/addons from an existing cart line', () {
      final repo = _FakeProductDetailsRepository(
        cartLine: (quantity: 3, note: 'بدون بصل', addonIds: ['a']),
      );
      final controller = _controller(
        repo,
        product: _product(
          addons: const [ProductAddon(id: 'a', name: 'جبنة', price: 10)],
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.quantity, 3);
      expect(controller.note, 'بدون بصل');
      expect(controller.selectedAddonIds, contains('a'));
    });

    test('addToCart routes through repository with computed unit price', () async {
      final repo = _FakeProductDetailsRepository();
      final controller = _controller(
        repo,
        product: _product(
          price: 40,
          addons: const [ProductAddon(id: 'a', name: 'جبنة', price: 10)],
        ),
      );
      addTearDown(controller.dispose);

      controller.toggleAddon('a');
      await controller.addToCart();

      expect(repo.added, hasLength(1));
      expect(repo.added.single.unitPrice, 50);
      expect(controller.ctaState, ProductCtaState.success);
    });

    test('blocks add when store is closed', () async {
      final repo = _FakeProductDetailsRepository();
      final controller = _controller(repo, store: _store(open: false));
      addTearDown(controller.dispose);

      await controller.addToCart();
      expect(repo.added, isEmpty);
      expect(controller.unavailableReason, isNotNull);
    });
  });
}
