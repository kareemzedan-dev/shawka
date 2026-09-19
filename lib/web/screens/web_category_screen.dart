import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/catalog_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/widgets/web_section_header.dart';
import 'package:matlobgo/web/widgets/web_store_row.dart';

class WebCategoryScreen extends StatefulWidget {
  const WebCategoryScreen({
    super.key,
    required this.govId,
    required this.categoryId,
  });

  final String govId;
  final String categoryId;

  @override
  State<WebCategoryScreen> createState() => _WebCategoryScreenState();
}

class _WebCategoryScreenState extends State<WebCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WebGovernorateService.instance.setGovernorateById(widget.govId);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogService();
    final govName = WebGovernorateService.instance.governorateName;

    WebSeoService.instance.apply(
      title: 'تصنيف ${widget.categoryId} — $govName',
      description:
          'موردون في تصنيف ${widget.categoryId} في $govName على ${AppBranding.shortName}.',
      canonicalPath: WebConstants.categoryPath(widget.govId, widget.categoryId),
    );

    return PremiumBackground.body(
      context,
      StreamBuilder<List<Store>>(
        stream: catalog.watchStores(governorate: govName),
        builder: (context, snap) {
          final stores = StoreCatalogUtils.filterStores(
            snap.data ?? [],
            categoryId: widget.categoryId,
          ).where((s) => s.isOpen).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.navy,
                title: Text(
                  'تصنيف',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
              ),
              SliverToBoxAdapter(
                child: WebSectionHeader(
                  title: widget.categoryId,
                  subtitle: '${stores.length} متجر',
                ),
              ),
              SliverToBoxAdapter(child: WebStoreGrid(stores: stores)),
            ],
          );
        },
      ),
    );
  }
}
