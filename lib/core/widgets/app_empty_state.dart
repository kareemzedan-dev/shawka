import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';

/// Premium unified empty state — MatlobGo design system.
///
/// One primary visual only (icon or custom illustration). No stacked badges.
class AppEmptyState extends StatefulWidget {
  const AppEmptyState({
    super.key,
    this.kind,
    required this.icon,
    required this.title,
    this.subtitle,
    this.description,
    this.actionLabel,
    this.buttonText,
    this.onAction,
    this.onPressed,
    this.actionIcon,
    this.iconColor,
    this.illustration,
    this.compact = false,
    this.animate = true,
  });

  /// Preset from [AppEmptyKind] with optional copy/action overrides.
  factory AppEmptyState.preset(
    AppEmptyKind kind, {
    Key? key,
    String? title,
    String? subtitle,
    String? description,
    String? actionLabel,
    String? buttonText,
    VoidCallback? onAction,
    VoidCallback? onPressed,
    IconData? actionIcon,
    bool compact = false,
    bool animate = true,
  }) {
    final p = AppEmptyPresets.forKind(kind);
    return AppEmptyState(
      key: key,
      kind: kind,
      icon: p.icon,
      title: title ?? p.title,
      subtitle: subtitle ?? description ?? p.subtitle,
      actionLabel: actionLabel ?? buttonText ?? p.actionLabel,
      onAction: onAction ?? onPressed,
      actionIcon: actionIcon ?? p.actionIcon,
      compact: compact,
      animate: animate,
    );
  }

  final AppEmptyKind? kind;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? description;
  final String? actionLabel;
  final String? buttonText;
  final VoidCallback? onAction;
  final VoidCallback? onPressed;
  final IconData? actionIcon;
  final Color? iconColor;
  final Widget? illustration;
  final bool compact;
  final bool animate;

  String? get _body => (description ?? subtitle)?.trim();
  String? get _ctaLabel => actionLabel ?? buttonText;
  VoidCallback? get _ctaHandler => onAction ?? onPressed;

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.animate) {
        _entrance.forward();
      } else {
        _entrance.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = widget.iconColor ?? AppColors.primary;
    // عند ضيق المساحة (كيبورد مفتوح) ندخل الوضع المضغوط تلقائياً
    // حتى لو لم يمرّر المستدعي compact: true.
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final compact = widget.compact || viewInsetsBottom > 0;
    final body = widget._body;

    final hPad = compact ? HomeTheme.spaceLg : HomeTheme.spaceXl;
    final vPad = compact ? HomeTheme.spaceMd : HomeTheme.space2xl;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.illustration ??
            _EmptyStateIcon(
              icon: widget.icon,
              accent: accent,
              palette: palette,
              compact: compact,
            ),
        SizedBox(height: compact ? HomeTheme.spaceMd : HomeTheme.spaceXl),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            height: 1.3,
            letterSpacing: -0.2,
          ),
        ),
        if (body != null && body.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : HomeTheme.spaceSm),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 280 : 320),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
        if (widget._ctaLabel != null && widget._ctaHandler != null) ...[
          SizedBox(height: compact ? HomeTheme.spaceMd : HomeTheme.spaceXl),
          _EmptyStateCta(
            label: widget._ctaLabel!,
            icon: widget.actionIcon ?? Icons.explore_rounded,
            onPressed: widget._ctaHandler!,
            compact: compact,
          ),
        ],
      ],
    );

    final animated = widget.animate
        ? FadeTransition(
            opacity: _fade,
            child: ScaleTransition(scale: _scale, child: content),
          )
        : content;

    // LayoutBuilder + ScrollView يمنع BOTTOM OVERFLOW عند تقلّص الارتفاع
    // (لوحة المفاتيح / شاشات قصيرة) مع الإبقاء على التوسيط عند اتساع المساحة.
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = (constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0.0)
            .clamp(0.0, double.infinity);
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (minHeight - (vPad * 2)).clamp(0.0, double.infinity),
            ),
            child: Center(child: animated),
          ),
        );
      },
    );
  }
}

/// Single primary icon — 64–72px inside a soft container. No overlays.
class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon({
    required this.icon,
    required this.accent,
    required this.palette,
    required this.compact,
  });

  final IconData icon;
  final Color accent;
  final AppPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final boxSize = compact ? 80.0 : 96.0;
    final iconSize = compact ? 64.0 : 72.0;
    final radius = compact ? 24.0 : 28.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: palette.isDark
            ? accent.withValues(alpha: 0.14)
            : accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: palette.isDark ? 0.28 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(
              alpha: palette.isDark ? 0.35 : 0.06,
            ),
            blurRadius: palette.isDark ? 8 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: accent,
      ),
    );
  }
}

class _EmptyStateCta extends StatefulWidget {
  const _EmptyStateCta({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  State<_EmptyStateCta> createState() => _EmptyStateCtaState();
}

class _EmptyStateCtaState extends State<_EmptyStateCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: HomeTheme.animPress,
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: HomeTheme.borderMd,
            splashColor: AppColors.primary.withValues(alpha: 0.12),
            highlightColor: AppColors.primary.withValues(alpha: 0.06),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: HomeTheme.borderMd,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 20 : 28,
                  vertical: widget.compact ? 11 : 13,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 20, color: AppColors.textOnPrimary),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: GoogleFonts.cairo(
                        fontSize: widget.compact ? 14 : 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
