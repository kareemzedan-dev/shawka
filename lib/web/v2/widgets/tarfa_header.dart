import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matlobgo/core/widgets/brand_logo.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/services/tarfa_cart_drawer_controller.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_glass.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_search_bar.dart';

class TarfaHeader extends StatelessWidget {
  const TarfaHeader({
    super.key,
    required this.govId,
    required this.onLocationTap,
    this.onSearchTap,
    this.onSearchSubmit,
  });

  final String govId;

  final VoidCallback onLocationTap;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSearchSubmit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WebGovernorateService.instance,
      builder: (context, _) {
        final location = WebGovernorateService.instance.governorateName;

        return Material(
          color: TarfaTokens.surface.withValues(alpha: 0.85),
          elevation: 0,
          child: ClipRect(
            child: TarfaGlass(
              borderRadius: BorderRadius.zero,
              opacity: 0.9,
              blur: 16,
              padding: const EdgeInsets.symmetric(
                horizontal: TarfaTokens.s32,
                vertical: TarfaTokens.s16,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go(WebConstants.governoratePath(govId)),
                      borderRadius: TarfaTokens.borderRadius,
                      child: const BrandLogo(
                        width: 110,
                        style: BrandLogoStyle.standalone,
                      ),
                    ),
                    const SizedBox(width: TarfaTokens.s32),
                    Expanded(
                      child: TarfaSearchBar(
                        readOnly: onSearchTap != null,
                        onTap: onSearchTap,
                        onSubmitted: onSearchSubmit,
                        showLocation: true,
                        locationLabel: location,
                        onLocationTap: onLocationTap,
                      ),
                    ),
                    const SizedBox(width: TarfaTokens.s24),
                    ListenableBuilder(
                      listenable: WebCartService.instance,
                      builder: (context, _) {
                        final count = WebCartService.instance.itemCount;
                        return _HeaderIconButton(
                          icon: Icons.shopping_bag_outlined,
                          tooltip: 'السلة',
                          badge: count > 0 ? '$count' : null,
                          onPressed: TarfaCartDrawerController.instance.open,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final String? badge;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TarfaTokens.s4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.08 : 1,
          duration: TarfaTokens.animFast,
          curve: TarfaTokens.curve,
          child: IconButton(
            tooltip: widget.tooltip,
            onPressed: widget.onPressed,
            style: IconButton.styleFrom(
              backgroundColor: _hovered
                  ? TarfaTokens.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Badge(
              isLabelVisible: widget.badge != null,
              label: Text(widget.badge ?? ''),
              backgroundColor: TarfaTokens.secondary,
              child: Icon(
                widget.icon,
                color: TarfaTokens.primary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
