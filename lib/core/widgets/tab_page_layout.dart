import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/core/widgets/app_empty_state.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';

/// Shared shell: navy header + white rounded body (matches home screen).
class TabPageLayout extends StatelessWidget {
  const TabPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    required this.child,
    this.bottom,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final Widget child;
  final Widget? bottom;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: AppColors.navy,
      child: Column(
        children: [
          _TabHeader(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            leading: leading,
            topPadding: top,
            centerTitle: centerTitle,
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -20,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: PremiumBackground.body(context, child),
                  ),
                ),
              ],
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    required this.topPadding,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final double topPadding;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    if (centerTitle) {
      return Stack(
        children: [
          const Positioned.fill(child: _HeaderBackground()),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 22),
            child: Row(
              children: [
                leading ?? const SizedBox(width: 42, height: 42),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.15,
                    ),
                  ),
                ),
                trailing ?? const SizedBox(width: 42, height: 42),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: _HeaderBackground()),
        Padding(
          padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.inkElevated,
                AppColors.ink,
                AppColors.black,
              ],
              stops: [0, 0.5, 1],
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tab empty state — uses unified [AppEmptyState] presets.
class TabEmptyState extends StatelessWidget {
  const TabEmptyState({
    super.key,
    required this.kind,
    this.title,
    this.subtitle,
    this.description,
    this.actionLabel,
    this.buttonText,
    this.onAction,
    this.onPressed,
    this.compact = false,
  });

  final AppEmptyKind kind;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? actionLabel;
  final String? buttonText;
  final VoidCallback? onAction;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState.preset(
      kind,
      title: title,
      subtitle: subtitle,
      description: description,
      actionLabel: actionLabel,
      buttonText: buttonText,
      onAction: onAction ?? onPressed,
      compact: compact,
    );
  }
}

class TabIconButton extends StatelessWidget {
  const TabIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: AppColors.white, size: 22),
                  if (badge != null && badge! > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badge! > 9 ? '9+' : '$badge',
                          style: GoogleFonts.cairo(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnPrimary,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
