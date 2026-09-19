import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_assets.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/core/widgets/safe_asset_image.dart';

/// Horizontal category tile — image, gradient overlay, selection state.
class CatalogCategoryCard extends StatefulWidget {
  const CatalogCategoryCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.imageAsset,
    this.imageUrl,
    this.imageThumbUrl,
    this.palette,
  });

  final String label;
  final String subtitle;
  final String? imageAsset;
  final String? imageUrl;
  final String? imageThumbUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final AppPalette? palette;

  @override
  State<CatalogCategoryCard> createState() => _CatalogCategoryCardState();
}

class _CatalogCategoryCardState extends State<CatalogCategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette ?? context.palette;
    final selectedScale = widget.isSelected ? 1.03 : 1.0;
    final pressScale = _pressed ? 0.97 : selectedScale;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressScale,
        duration: HomeTheme.animPress,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: HomeTheme.animNormal,
          curve: Curves.easeOutCubic,
          width: 84,
          decoration: BoxDecoration(
            borderRadius: HomeTheme.borderMd,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : palette.border,
              width: widget.isSelected ? 2.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? HomeTheme.categorySelectedGlow
                : HomeTheme.softShadow(palette),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HomeTheme.radiusMd - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.navy.withValues(alpha: 0.02),
                        AppColors.navy.withValues(alpha: 0.78),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'مختار',
                            style: GoogleFonts.cairo(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        widget.label,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty) {
      return CatalogNetworkImage(
        imageUrl: widget.imageUrl,
        thumbnailUrl: widget.imageThumbUrl,
        fit: BoxFit.cover,
        cacheWidth: 200,
        cacheHeight: 260,
        fallback: SafeAssetImage(
          asset: widget.imageAsset ?? AppAssets.categoryAll,
          fallbackIcon: Icons.category_rounded,
        ),
      );
    }
    return SafeAssetImage(
      asset: widget.imageAsset ?? AppAssets.categoryAll,
      fallbackIcon: Icons.category_rounded,
    );
  }
}
