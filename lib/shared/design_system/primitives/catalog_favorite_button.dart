import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/services/favorites_service.dart';

/// Heart toggle for stores (and products via same service).
class CatalogFavoriteButton extends StatefulWidget {
  const CatalogFavoriteButton({
    super.key,
    required this.targetId,
    this.size = 32,
    this.iconSize = 17,
  });

  final String targetId;
  final double size;
  final double iconSize;

  @override
  State<CatalogFavoriteButton> createState() => _CatalogFavoriteButtonState();
}

class _CatalogFavoriteButtonState extends State<CatalogFavoriteButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    final wasFavorite = FavoritesService.instance.isFavorite(widget.targetId);
    await FavoritesService.instance.toggle(widget.targetId);
    if (!wasFavorite &&
        FavoritesService.instance.isFavorite(widget.targetId)) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final isFavorite =
            FavoritesService.instance.isFavorite(widget.targetId);

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1,
            duration: HomeTheme.animPress,
            curve: Curves.easeOutCubic,
            child: AnimatedBuilder(
              animation: CurvedAnimation(
                parent: _bounceController,
                curve: Curves.elasticOut,
              ),
              builder: (context, child) {
                final bounce = 1 + (_bounceController.value * 0.22);
                return Transform.scale(scale: bounce, child: child);
              },
              child: AnimatedContainer(
                duration: HomeTheme.animStandard,
                curve: Curves.easeOutCubic,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: isFavorite
                      ? AppColors.primary.withValues(alpha: 0.92)
                      : AppColors.black.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFavorite
                        ? AppColors.primaryLight.withValues(alpha: 0.5)
                        : AppColors.white.withValues(alpha: 0.22),
                  ),
                  boxShadow: isFavorite
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: HomeTheme.animStandard,
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey<bool>(isFavorite),
                    size: widget.iconSize,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
