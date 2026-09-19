import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_conversion_service.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_section_header.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_skeleton.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_store_card.dart';

class TarfaCategoryScreen extends StatefulWidget {
  const TarfaCategoryScreen({
    super.key,
    required this.govId,
    required this.categoryId,
  });

  final String govId;
  final String categoryId;

  @override
  State<TarfaCategoryScreen> createState() => _TarfaCategoryScreenState();
}

class _TarfaCategoryScreenState extends State<TarfaCategoryScreen> {
  final _catalog = CatalogService();

  @override
  void initState() {
    super.initState();
    WebGovernorateService.instance.setGovernorateById(widget.govId);
    WebSeoService.instance.apply(
      title: 'تصنيف ${widget.categoryId}',
      description: AppBranding.categorySeoDescription(
        widget.categoryId,
        WebGovernorateService.instance.governorateName,
      ),
      canonicalPath:
          WebConstants.categoryPath(widget.govId, widget.categoryId),
    );
  }

  void _openStore(Store store) {
    if (!store.isActive) return;
    WebConversionService.instance.recordStoreVisit(store.id);
    context.push(WebConstants.storePath(store.id));
  }

  @override
  Widget build(BuildContext context) {
    final govName = WebGovernorateService.instance.governorateName;
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;
    final padding = isMobile ? TarfaTokens.s16 : TarfaTokens.s40;
    final crossAxisCount = isMobile ? 1 : 3;

    return StreamBuilder<List<Store>>(
      stream: _catalog.watchStores(governorate: govName),
      builder: (context, snap) {
        final stores = StoreCatalogUtils.filterStores(
          snap.data ?? [],
          categoryId: widget.categoryId,
        ).where((s) => s.isOpen).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(padding, TarfaTokens.s24, padding, 0),
                child: TarfaSectionHeader(
                  title: widget.categoryId,
                  subtitle:
                      '${stores.length} متجر في ${WebGovernorateService.instance.governorateName}',
                ),
              ),
            ),
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData)
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: TarfaTokens.s24,
                    crossAxisSpacing: TarfaTokens.s24,
                    childAspectRatio: TarfaTokens.storeGridAspectRatio(isMobile),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => const TarfaStoreCardSkeleton(),
                    childCount: 6,
                  ),
                ),
              )
            else if (stores.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'لا توجد متاجر في هذا التصنيف',
                    style: TarfaTokens.bodyLarge(context),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: TarfaTokens.s24,
                    crossAxisSpacing: TarfaTokens.s24,
                    childAspectRatio: TarfaTokens.storeGridAspectRatio(isMobile),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => TarfaStoreCard(
                      store: stores[index],
                      onTap: () => _openStore(stores[index]),
                    ),
                    childCount: stores.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: TarfaTokens.s80)),
          ],
        );
      },
    );
  }
}
