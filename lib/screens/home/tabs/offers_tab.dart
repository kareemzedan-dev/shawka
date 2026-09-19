import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/store_detail_screen.dart';
import 'package:matlobgo/screens/home/widgets/home_bottom_nav.dart';
import 'package:matlobgo/screens/home/widgets/home_hero.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_feed.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/services/promotion_service.dart';
import 'package:matlobgo/shared/home/home_catalog_sections.dart';

class OffersTab extends StatelessWidget {
  const OffersTab({
    super.key,
    required this.governorateName,
    required this.cartService,
    this.onExploreStores,
  });

  final String governorateName;
  final CartService cartService;
  final ValueChanged<HomeTab>? onExploreStores;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: ColoredBox(
        color: const Color(0xFFF4F5F7),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, top + 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Text(
                'العروض والخصومات',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: PremiumBackground.body(
                context,
                _OffersBody(
                  governorateName: governorateName,
                  cartService: cartService,
                  onExploreStores: onExploreStores,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffersBody extends StatelessWidget {
  const _OffersBody({
    required this.governorateName,
    required this.cartService,
    this.onExploreStores,
  });

  final String governorateName;
  final CartService cartService;
  final ValueChanged<HomeTab>? onExploreStores;

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogService();

    return ListenableBuilder(
      listenable: PromotionService.instance,
      builder: (context, _) {
        return StreamBuilder<AppUser?>(
          stream: AuthService().watchCurrentAppUser(),
          builder: (context, userSnap) {
            return StreamBuilder<List<Store>>(
              stream: catalog.watchStores(
                governorate: governorateName,
                activityTypeId: userSnap.data?.activityTypeId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

            final stores = HomeCatalogSections.flashDealStores(
              snapshot.data ?? [],
              promotions: PromotionService.instance.promotions,
            );

            if (stores.isEmpty) {
              return AppEmptyState.preset(
                AppEmptyKind.stores,
                title: 'لا توجد عروض حالياً',
                subtitle: 'تابعنا — العروض الجديدة تظهر هنا فور إضافتها',
                onAction: onExploreStores == null
                    ? null
                    : () => onExploreStores!(HomeTab.home),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
              children: [
                ColoredBox(
                  color: MatlobHomeColors.flashDealsBg,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: MatlobFlashDealsSection(
                      stores: stores,
                      promotions: PromotionService.instance.promotions,
                      onStoreTap: (store) => openStoreDetail(
                        context,
                        store: store,
                        cartService: cartService,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'كل المتاجر ذات العروض',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...stores.map(
                  (store) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: MatlobStoreListTile(
                      store: store,
                      onTap: () => openStoreDetail(
                        context,
                        store: store,
                        cartService: cartService,
                      ),
                    ),
                  ),
                ),
              ],
            );
              },
            );
          },
        );
      },
    );
  }
}
