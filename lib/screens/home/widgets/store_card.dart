import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/shared/design_system/components/catalog_section_header.dart';
import 'package:matlobgo/shared/design_system/components/catalog_store_card.dart';

export 'package:matlobgo/shared/design_system/components/catalog_store_card.dart'
    show CatalogStoreCard, CatalogStoreCardVariant, CatalogStoreCardSkeleton;

typedef StoreCard = CatalogStoreCard;
typedef StoreCardVariant = CatalogStoreCardVariant;

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CatalogSectionHeader(
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      padding: const EdgeInsets.fromLTRB(
        HomeTheme.pageHorizontal,
        0,
        HomeTheme.pageHorizontal,
        HomeTheme.itemGap,
      ),
    );
  }
}
