import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/store.dart';

class WebPromoStrip extends StatelessWidget {
  const WebPromoStrip({super.key, required this.banners});

  final List<PromoBanner> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeTheme.pageHorizontal),
        itemCount: banners.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final banner = banners[index];
          final accent = banner.accentColor ?? AppColors.primary;
          return Container(
            width: 300,
            decoration: BoxDecoration(
              borderRadius: HomeTheme.borderLg,
              gradient: LinearGradient(
                colors: [
                  accent,
                  accent.withValues(alpha: 0.75),
                ],
              ),
              boxShadow: HomeTheme.softShadowLight,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (banner.hasNetworkImage)
                  CatalogNetworkImage(
                    imageUrl: banner.imageUrl,
                    thumbnailUrl: banner.imageThumbUrl,
                    fallback: const SizedBox.shrink(),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        banner.title,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        banner.subtitle,
                        style: GoogleFonts.cairo(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
