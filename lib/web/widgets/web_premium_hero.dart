import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/brand_logo.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/shared/design_system/components/catalog_home_header.dart';
import 'package:matlobgo/shared/design_system/components/catalog_search_bar.dart';
import 'package:matlobgo/web/services/web_live_stats_service.dart';

class WebPremiumHero extends StatefulWidget {
  const WebPremiumHero({
    super.key,
    this.onSearchSubmit,
    this.compact = false,
  });

  final ValueChanged<String>? onSearchSubmit;
  final bool compact;

  @override
  State<WebPremiumHero> createState() => _WebPremiumHeroState();
}

class _WebPremiumHeroState extends State<WebPremiumHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final welcome = CmsTextService.instance.welcomeMessage(
      isGuest: true,
      userName: 'ضيف',
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Stack(
        children: [
          const Positioned.fill(child: CatalogHeroBackground()),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0, _float.value * 8 - 4),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, widget.compact ? 18 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const BrandLogo(width: 120, style: BrandLogoStyle.onDark),
                    const Spacer(),
                    _GovernorateMenu(),
                  ],
                ),
                if (!widget.compact) ...[
                  const SizedBox(height: 16),
                  Text(
                    welcome,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _StatsRow(),
                const SizedBox(height: 16),
                CatalogSearchBar.editable(
                  controller: _searchController,
                  onSubmit: (q) {
                    if (widget.onSearchSubmit != null) {
                      widget.onSearchSubmit!(q);
                    } else {
                      final gov = WebGovernorateService.instance.governorateId;
                      context.push('${WebConstants.storesPath(gov)}?q=$q');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        WebLiveStats.instance,
        AppConfigService.instance,
      ]),
      builder: (context, _) {
        final stats = WebLiveStats.instance;
        final orders = stats.completedOrders;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.storefront_rounded,
                    value: '${stats.openStoreCount}',
                    label: 'متجر',
                  ),
                  _divider(),
                  _StatChip(
                    icon: Icons.fastfood_rounded,
                    value: stats.loadingProducts
                        ? '...'
                        : '${stats.productCount}',
                    label: 'منتج',
                  ),
                  if (orders != null && orders > 0) ...[
                    _divider(),
                    _StatChip(
                      icon: Icons.check_circle_outline_rounded,
                      value: _formatCount(orders),
                      label: 'طلب',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white24,
      );

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GovernorateMenu extends StatelessWidget {
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
          itemBuilder: (context) => WebGovernorateService.instance.available
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
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  gov.name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.expand_more_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
