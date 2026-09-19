import 'package:flutter/material.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_web_image.dart';

String tarfaCategoryEmoji(StoreCategoryDef category) {
  final key = '${category.id}_${category.name}'.toLowerCase();
  if (key.contains('oil') || category.name.contains('زيت')) {
    return '🫒';
  }
  if (key.contains('dairy') ||
      category.name.contains('ألبان') ||
      category.name.contains('جبن')) {
    return '🧀';
  }
  if (key.contains('meat') ||
      category.name.contains('لحم') ||
      category.name.contains('دواجن')) {
    return '🥩';
  }
  if (key.contains('produce') ||
      category.name.contains('خضار') ||
      category.name.contains('فاكهة')) {
    return '🥬';
  }
  if (key.contains('bakery') ||
      category.name.contains('مخب') ||
      category.name.contains('دقيق')) {
    return '🌾';
  }
  if (key.contains('dry') ||
      category.name.contains('تموين') ||
      category.name.contains('جملة')) {
    return '📦';
  }
  if (key.contains('sweet') ||
      category.name.contains('حلو') ||
      category.name.contains('كيك')) {
    return '🎂';
  }
  return '🏪';
}

class TarfaCategoryGrid extends StatelessWidget {
  const TarfaCategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.onMoreTap,
    this.selectedId,
  });

  final List<StoreCategoryDef> categories;
  final ValueChanged<StoreCategoryDef> onCategoryTap;
  final VoidCallback? onMoreTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;
    final items = categories.take(isMobile ? 8 : 10).toList();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: TarfaTokens.s24),
        child: Text(
          'لا توجد تصنيفات حالياً',
          style: TarfaTokens.bodyMedium(context),
        ),
      );
    }

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: TarfaTokens.s12,
          crossAxisSpacing: TarfaTokens.s12,
          childAspectRatio: 0.9,
        ),
        itemCount: items.length + 1,
        itemBuilder: (context, index) => _buildItem(context, items, index),
      );
    }

    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: TarfaTokens.s16),
        itemBuilder: (context, index) => SizedBox(
          width: 140,
          height: 156,
          child: _buildItem(context, items, index),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    List<StoreCategoryDef> items,
    int index,
  ) {
    if (index == items.length) {
      return TarfaCategoryCard(
        emoji: '✨',
        label: 'المزيد...',
        selected: false,
        onTap: onMoreTap,
      );
    }
    final cat = items[index];
    return TarfaCategoryCard(
      emoji: tarfaCategoryEmoji(cat),
      label: cat.name,
      imageUrl: cat.imageUrl,
      imageThumbUrl: cat.imageThumbUrl,
      imageAsset: cat.imageAsset,
      selected: selectedId == cat.id,
      onTap: () => onCategoryTap(cat),
    );
  }
}

class TarfaCategoryCard extends StatefulWidget {
  const TarfaCategoryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    this.imageUrl,
    this.imageThumbUrl,
    this.imageAsset,
    this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final String? imageUrl;
  final String? imageThumbUrl;
  final String? imageAsset;
  final VoidCallback? onTap;

  @override
  State<TarfaCategoryCard> createState() => _TarfaCategoryCardState();
}

class _TarfaCategoryCardState extends State<TarfaCategoryCard> {
  bool _hovered = false;

  bool get _hasNetworkImage =>
      widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1,
        duration: TarfaTokens.animFast,
        curve: TarfaTokens.curve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: TarfaTokens.borderRadius,
            child: AnimatedContainer(
              duration: TarfaTokens.animFast,
              curve: TarfaTokens.curve,
              decoration: BoxDecoration(
                color: TarfaTokens.surface,
                borderRadius: TarfaTokens.borderRadius,
                boxShadow:
                    _hovered ? TarfaTokens.shadowHover : TarfaTokens.shadowSm,
                border: widget.selected
                    ? Border.all(color: TarfaTokens.secondary, width: 2)
                    : Border.all(color: TarfaTokens.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Always paint a visible base so empty cards never happen.
                  _assetOrEmojiBg(),
                  if (_hasNetworkImage)
                    TarfaWebImage(
                      kind: TarfaImageKind.category,
                      fill: true,
                      imageUrl: widget.imageUrl,
                      thumbnailUrl: widget.imageThumbUrl,
                      fallback: const SizedBox.shrink(),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x990A0A0A),
                          Color(0xE00A0A0A),
                        ],
                        stops: [0.25, 0.7, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(TarfaTokens.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const Spacer(),
                        Text(
                          widget.label,
                          style: TarfaTokens.titleMedium(context).copyWith(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _assetOrEmojiBg() {
    if (widget.imageAsset != null && widget.imageAsset!.isNotEmpty) {
      return SafeAssetImage(
        asset: widget.imageAsset!,
        fallbackIcon: Icons.category_rounded,
      );
    }
    return ColoredBox(
      color: TarfaTokens.primary.withValues(alpha: 0.08),
      child: Center(
        child: Text(widget.emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}
