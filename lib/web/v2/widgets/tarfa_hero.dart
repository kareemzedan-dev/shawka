import 'package:flutter/material.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_search_bar.dart';

class TarfaHero extends StatelessWidget {
  const TarfaHero({
    super.key,
    required this.locationLabel,
    required this.onLocationTap,
    this.onSearchTap,
    this.onSearchSubmit,
    this.onCategoryTap,
    this.compact = false,
  });

  final String locationLabel;
  final VoidCallback onLocationTap;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSearchSubmit;
  final ValueChanged<String>? onCategoryTap;
  final bool compact;

  // التصنيفات تُدار بالكامل من لوحة التحكم لكل محافظة.
  static const _quickCategories = <(String, String, String)>[];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            TarfaTokens.primary,
            TarfaTokens.primary.withValues(alpha: 0.92),
            const Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _GlowOrb(
              size: 280,
              color: TarfaTokens.secondary.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -20,
            child: _GlowOrb(
              size: 200,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? TarfaTokens.s16 : TarfaTokens.s48,
              vertical: compact ? TarfaTokens.s32 : TarfaTokens.s56,
            ),
            child: isMobile ? _buildMobile(context) : _buildDesktop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'كل اللي تحتاجه...',
                style: TarfaTokens.displayLarge(context).copyWith(
                  color: Colors.white,
                  fontSize: 52,
                ),
              ),
              Text(
                'يوصلك في دقائق.',
                style: TarfaTokens.displayLarge(context).copyWith(
                  color: TarfaTokens.secondary,
                  fontSize: 52,
                ),
              ),
              const SizedBox(height: TarfaTokens.s16),
              Text(
                'اطلب من موردي المواد الغذائية بالجملة — توصيل سريع لباب شركتك.',
                style: TarfaTokens.bodyLarge(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: TarfaTokens.s32),
              TarfaSearchBar(
                large: true,
                readOnly: onSearchTap != null,
                onTap: onSearchTap,
                onSubmitted: onSearchSubmit,
                showLocation: true,
                locationLabel: locationLabel,
                onLocationTap: onLocationTap,
              ),
              const SizedBox(height: TarfaTokens.s24),
              _QuickCategoryChips(onCategoryTap: onCategoryTap),
            ],
          ),
        ),
        const SizedBox(width: TarfaTokens.s48),
        const Expanded(
          flex: 4,
          child: _HeroIllustration(),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كل اللي تحتاجه...',
          style: TarfaTokens.headlineLarge(context).copyWith(
            color: Colors.white,
            fontSize: 32,
          ),
        ),
        Text(
          'يوصلك في دقائق.',
          style: TarfaTokens.headlineLarge(context).copyWith(
            color: TarfaTokens.secondary,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: TarfaTokens.s12),
        Text(
          'اطلب من أفضل المتاجر في منطقتك',
          style: TarfaTokens.bodyMedium(context).copyWith(
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: TarfaTokens.s24),
        TarfaSearchBar(
          large: true,
          readOnly: onSearchTap != null,
          onTap: onSearchTap,
          onSubmitted: onSearchSubmit,
          showLocation: true,
          locationLabel: locationLabel,
          onLocationTap: onLocationTap,
        ),
        const SizedBox(height: TarfaTokens.s16),
        _QuickCategoryChips(onCategoryTap: onCategoryTap),
        if (!compact) ...[
          const SizedBox(height: TarfaTokens.s24),
          const SizedBox(
            height: 200,
            child: _HeroIllustration(),
          ),
        ],
      ],
    );
  }
}

class _QuickCategoryChips extends StatelessWidget {
  const _QuickCategoryChips({this.onCategoryTap});

  final ValueChanged<String>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TarfaTokens.s8,
      runSpacing: TarfaTokens.s8,
      children: [
        for (final (label, emoji, id) in TarfaHero._quickCategories)
          _CategoryChip(
            label: label,
            emoji: emoji,
            onTap: () => onCategoryTap?.call(id),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    this.onTap,
  });

  final String label;
  final String emoji;
  final VoidCallback? onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.04 : 1,
        duration: TarfaTokens.animFast,
        curve: TarfaTokens.curve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(40),
            child: AnimatedContainer(
              duration: TarfaTokens.animFast,
              padding: const EdgeInsets.symmetric(
                horizontal: TarfaTokens.s16,
                vertical: TarfaTokens.s8,
              ),
              decoration: BoxDecoration(
                color: _hovered
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: _hovered ? 0.4 : 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: TarfaTokens.s8),
                  Text(
                    widget.label,
                    style: TarfaTokens.labelLarge(context).copyWith(
                      color: Colors.white,
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
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TarfaTokens.secondary.withValues(alpha: 0.12),
          ),
        ),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(TarfaTokens.radiusLg),
            boxShadow: TarfaTokens.shadowLg,
          ),
          child: const Icon(
            Icons.delivery_dining_rounded,
            size: 80,
            color: TarfaTokens.secondary,
          ),
        ),
        Positioned(
          top: 20,
          right: 30,
          child: _FloatingBadge(emoji: '📦', label: 'موردين'),
        ),
        Positioned(
          bottom: 40,
          left: 10,
          child: _FloatingBadge(emoji: '🌾', label: 'جملة'),
        ),
        Positioned(
          top: 60,
          left: 0,
          child: _FloatingBadge(emoji: '🚚', label: 'توصيل'),
        ),
      ],
    );
  }
}

class _FloatingBadge extends StatefulWidget {
  const _FloatingBadge({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  State<_FloatingBadge> createState() => _FloatingBadgeState();
}

class _FloatingBadgeState extends State<_FloatingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _controller.value * 8 - 4),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TarfaTokens.s12,
          vertical: TarfaTokens.s8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: TarfaTokens.shadowMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: TarfaTokens.s4),
            Text(
              widget.label,
              style: TarfaTokens.labelMedium(context).copyWith(
                color: TarfaTokens.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
