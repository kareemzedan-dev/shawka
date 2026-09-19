import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_tokens.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';

/// حالة السلة الفارغة — مظهر بريميوم مضغوط ومنظّم.
class CartEmptyState extends StatefulWidget {
  const CartEmptyState({
    super.key,
    required this.onShop,
    this.title = 'سلتك فارغة',
    this.subtitle = 'أضف منتجاتك المفضلة وسنجهّزها للتوصيل',
    this.actionLabel = 'ابدأ التسوق',
  });

  final VoidCallback onShop;
  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  State<CartEmptyState> createState() => _CartEmptyStateState();
}

class _CartEmptyStateState extends State<CartEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PremiumCartIcon(),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: CartTypography.style(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: CartTypography.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Semantics(
                  button: true,
                  label: widget.actionLabel,
                  child: Listener(
                    onPointerDown: (_) => setState(() => _pressed = true),
                    onPointerUp: (_) => setState(() => _pressed = false),
                    onPointerCancel: (_) => setState(() => _pressed = false),
                    child: AnimatedScale(
                      scale: _pressed ? 0.97 : 1,
                      duration: CartTokens.motionFast,
                      curve: Curves.easeOutCubic,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 0,
                        shadowColor: AppColors.primary.withValues(alpha: 0.35),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onShop();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 168),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                  color: AppColors.textOnPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.actionLabel,
                                  style: CartTypography.style(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnPrimary,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCartIcon extends StatelessWidget {
  const _PremiumCartIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 28,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
