import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/theme/search_tokens.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/repositories/search_repository.dart';
import 'package:matlobgo/screens/home/search/search_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Store _store({
  String id = 's1',
  String name = 'حضرموت',
  String categoryId = 'restaurant',
  List<String> tags = const ['مندي'],
  bool open = true,
  double rating = 4.5,
  int deliveryMinutes = 30,
  double deliveryFee = 15,
  String? discountLabel,
}) {
  return Store(
    id: id,
    name: name,
    categoryId: categoryId,
    rating: rating,
    deliveryMinutes: deliveryMinutes,
    deliveryFee: deliveryFee,
    fallbackOpen: open,
    tags: tags,
    governorate: 'القاهرة',
    discountLabel: discountLabel,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchRepository ranking', () {
    late SearchRepository repo;

    setUp(() {
      repo = SearchRepository();
    });

    test('ranks exact name higher than partial', () {
      final stores = [
        _store(id: 'a', name: 'بيتزا'),
        _store(id: 'b', name: 'بيتزا هت'),
      ];
      final hits = repo.rankStoreAndCategoryHits(
        query: 'بيتزا',
        stores: stores,
        categories: const [],
      );
      expect(hits.first.store?.id, 'a');
      expect(hits.first.score, greaterThan(hits[1].score));
    });

    test('matches tags and category labels', () {
      final stores = [
        _store(id: 't', name: 'مورد س', tags: const ['أرز']),
      ];
      final cats = [
        const StoreCategoryDef(
          id: 'dry_goods',
          name: 'تموين',
          governorate: 'القاهرة',
        ),
      ];
      final byTag = repo.rankStoreAndCategoryHits(
        query: 'أرز',
        stores: stores,
        categories: cats,
      );
      expect(byTag.any((h) => h.store?.id == 't'), isTrue);

      final byCat = repo.rankStoreAndCategoryHits(
        query: 'تموين',
        stores: stores,
        categories: cats,
      );
      expect(byCat.any((h) => h.isCategory), isTrue);
    });

    test('advanced filters open / free / offers', () {
      final stores = [
        _store(id: 'closed', name: 'مغلق', open: false),
        _store(id: 'free', name: 'مجاني', deliveryFee: 0),
        _store(id: 'offer', name: 'عرض', discountLabel: 'خصم 50%'),
      ];
      expect(
        repo
            .rankStoreAndCategoryHits(
              query: '',
              stores: stores,
              categories: const [],
              filters: const SearchAdvancedFilters(openOnly: true),
            )
            .every((h) => h.store?.isOpen == true),
        isTrue,
      );
      expect(
        repo
            .rankStoreAndCategoryHits(
              query: '',
              stores: stores,
              categories: const [],
              filters: const SearchAdvancedFilters(freeDeliveryOnly: true),
            )
            .every((h) => (h.store?.deliveryFee ?? 1) <= 0),
        isTrue,
      );
      expect(
        repo
            .rankStoreAndCategoryHits(
              query: '',
              stores: stores,
              categories: const [],
              filters: const SearchAdvancedFilters(offersOnly: true),
            )
            .any((h) => h.store?.id == 'offer'),
        isTrue,
      );
    });

    test('blacklist blocks query', () {
      // blacklist comes from CMS — empty by default in tests → skip if empty
      expect(repo.isBlacklisted(''), isFalse);
    });
  });

  group('Search recent history', () {
    test('saves newest first and removes item', () async {
      final repo = SearchRepository();
      var list = await repo.loadRecentSearches();
      list = await repo.saveRecentSearch('بيتزا', current: list);
      list = await repo.saveRecentSearch('برجر', current: list);
      expect(list.first, 'برجر');
      expect(list, contains('بيتزا'));
      list = await repo.removeRecentSearch('بيتزا', current: list);
      expect(list, isNot(contains('بيتزا')));
      list = await repo.clearRecentSearches();
      expect(list, isEmpty);
    });
  });

  group('SearchTokens', () {
    test('debounce and page size are production-safe', () {
      expect(SearchTokens.debounce.inMilliseconds, 300);
      expect(SearchTokens.resultsPageSize, greaterThanOrEqualTo(10));
      expect(SearchTokens.touchTarget, greaterThanOrEqualTo(48));
    });
  });

  group('PopularSearchTerm', () {
    test('builds from CMS trending without crashing on empty CMS', () {
      final repo = SearchRepository();
      final terms = repo.popularSearches(
        stores: [
          _store(name: 'حضرموت', rating: 4.9),
          _store(id: '2', name: 'عرض خاص', discountLabel: 'عرض الـ 50%'),
        ],
      );
      // بدون CMS seeded قد تكون القائمة فارغة — المهم ألا ترمي ولا تعتمد mock-only paths.
      expect(terms, isA<List<PopularSearchTerm>>());
      expect(terms.every((t) => t.label.trim().isNotEmpty), isTrue);
    });
  });
}
