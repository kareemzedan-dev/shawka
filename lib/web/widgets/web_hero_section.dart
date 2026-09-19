import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';

class WebHeroSection extends StatelessWidget {
  const WebHeroSection({
    super.key,
    this.onSearchTap,
    this.compact = false,
  });

  final VoidCallback? onSearchTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, compact ? 16 : 24, 20, compact ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                WebConstants.siteName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: compact ? 20 : 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _GovernorateChip(),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              WebConstants.siteTagline,
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textHint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ابحث عن مورد، منتج...',
                        style: GoogleFonts.cairo(
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GovernorateChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WebGovernorateService.instance,
      builder: (context, _) {
        final gov = WebGovernorateService.instance.governorate;
        return PopupMenuButton<Governorate>(
          onSelected: (g) async {
            await WebGovernorateService.instance.setGovernorate(g);
            if (context.mounted) {
              context.go(WebConstants.governoratePath(g.id));
            }
          },
          itemBuilder: (context) => EgyptGovernorates.available
              .map(
                (g) => PopupMenuItem(
                  value: g,
                  child: Text(g.name, style: GoogleFonts.cairo()),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  gov.name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
