import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/screens/home/store_detail_screen.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_feed.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/catalog_service.dart';

/// تصفّح شجري للتصنيفات: فروع ← فروع… أو متاجر عند الورقة.
class CategoryBrowseScreen extends StatelessWidget {
  CategoryBrowseScreen({
    super.key,
    required this.governorate,
    required this.category,
    required this.cartService,
    CatalogService? catalogService,
  }) : catalogService = catalogService ?? CatalogService();

  final String governorate;
  final StoreCategoryDef category;
  final CartService cartService;
  final CatalogService catalogService;

  static Future<void> open(
    BuildContext context, {
    required String governorate,
    required StoreCategoryDef category,
    required CartService cartService,
    CatalogService? catalogService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryBrowseScreen(
          governorate: governorate,
          category: category,
          cartService: cartService,
          catalogService: catalogService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().watchCurrentAppUser(),
      builder: (context, userSnap) {
        final activityTypeId = userSnap.data?.activityTypeId;
        return StreamBuilder<List<StoreCategoryDef>>(
          stream: catalogService.watchCategories(
            governorate,
            activityTypeId: activityTypeId,
          ),
          builder: (context, catSnap) {
            return StreamBuilder<List<Store>>(
              stream: catalogService.watchStores(
                governorate: governorate,
                activityTypeId: activityTypeId,
              ),
              builder: (context, storeSnap) {
                final allCats = catSnap.data ?? const <StoreCategoryDef>[];
                final stores = storeSnap.data ?? const <Store>[];
                final current = StoreCatalogUtils.byId(allCats, category.id) ??
                    category;
                final crumbs = StoreCatalogUtils.breadcrumb(allCats, current);
                final children =
                    StoreCatalogUtils.childrenOf(allCats, current.id)
                        .where((c) => c.isActive)
                        .toList();
                final loading =
                    (catSnap.connectionState == ConnectionState.waiting &&
                        !catSnap.hasData) ||
                    (storeSnap.connectionState == ConnectionState.waiting &&
                        !storeSnap.hasData);

                return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  current.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
              ),
              body: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (crumbs.length > 1)
                          _BreadcrumbBar(
                            crumbs: crumbs,
                            onTap: (c) {
                              if (c.id == current.id) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => CategoryBrowseScreen(
                                    governorate: governorate,
                                    category: c,
                                    cartService: cartService,
                                    catalogService: catalogService,
                                  ),
                                ),
                              );
                            },
                          ),
                        Expanded(
                          child: children.isNotEmpty
                              ? _SubcategoryGrid(
                                  children: children,
                                  allCats: allCats,
                                  stores: stores,
                                  onTap: (child) {
                                    HapticFeedback.selectionClick();
                                    CategoryBrowseScreen.open(
                                      context,
                                      governorate: governorate,
                                      category: child,
                                      cartService: cartService,
                                      catalogService: catalogService,
                                    );
                                  },
                                )
                              : _StoreResults(
                                  category: current,
                                  stores: stores
                                      .where(
                                        (s) => StoreCatalogUtils.matchesCategory(
                                          s,
                                          current.id,
                                        ),
                                      )
                                      .toList(),
                                  onStoreTap: (store) {
                                    openStoreDetail(
                                      context,
                                      store: store,
                                      cartService: cartService,
                                      catalogService: catalogService,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            );
              },
            );
          },
        );
      },
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.crumbs, required this.onTap});

  final List<StoreCategoryDef> crumbs;
  final ValueChanged<StoreCategoryDef> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            InkWell(
              onTap: () => onTap(crumbs[i]),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  crumbs[i].name,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: i == crumbs.length - 1
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: i == crumbs.length - 1
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubcategoryGrid extends StatelessWidget {
  const _SubcategoryGrid({
    required this.children,
    required this.allCats,
    required this.stores,
    required this.onTap,
  });

  final List<StoreCategoryDef> children;
  final List<StoreCategoryDef> allCats;
  final List<Store> stores;
  final ValueChanged<StoreCategoryDef> onTap;

  int _countFor(StoreCategoryDef def) {
    final subtree = {def.id, ...StoreCatalogUtils.descendantIds(allCats, def.id)};
    return stores
        .where((s) => subtree.any((id) => StoreCatalogUtils.matchesCategory(s, id)))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final def = children[index];
        final count = _countFor(def);
        final hasKids = StoreCatalogUtils.hasChildren(allCats, def.id);
        return Material(
          color: AppColors.surface,
          borderRadius: HomeTheme.borderMd,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(def),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CatalogNetworkImage(
                    imageUrl: def.imageUrl,
                    thumbnailUrl: def.imageThumbUrl,
                    fit: BoxFit.cover,
                    fallback: ColoredBox(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        def.icon,
                        size: 40,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasKids
                            ? 'تصنيفات فرعية'
                            : (count > 0 ? '$count متجر' : 'تصفح'),
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StoreResults extends StatelessWidget {
  const _StoreResults({
    required this.category,
    required this.stores,
    required this.onStoreTap,
  });

  final StoreCategoryDef category;
  final List<Store> stores;
  final ValueChanged<Store> onStoreTap;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return AppEmptyState(
        icon: Icons.storefront_outlined,
        title: 'لا متاجر هنا بعد',
        subtitle: 'لم يُربط أي متجر بتصنيف «${category.name}» حالياً.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: stores.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final store = stores[index];
        return MatlobStoreListTile(
          store: store,
          onTap: () => onStoreTap(store),
        );
      },
    );
  }
}
