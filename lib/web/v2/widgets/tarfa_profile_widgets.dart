import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/screens/home/widgets/profile_widgets.dart';
import 'package:matlobgo/services/theme_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';

// ─── Page header ─────────────────────────────────────────────────────────────

class TarfaProfileHeader extends StatelessWidget {
  const TarfaProfileHeader({
    super.key,
    required this.onNotifications,
    this.avatarInitials = 'م',
    this.notificationCount = 0,
  });

  final VoidCallback onNotifications;
  final String avatarInitials;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TarfaTokens.s16,
        top + TarfaTokens.s8,
        TarfaTokens.s16,
        TarfaTokens.s16,
      ),
      child: Row(
        children: [
          _MiniAvatar(initials: avatarInitials),
          const Spacer(),
          Text(
            'حسابي',
            style: TarfaTokens.headlineMedium(context).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onNotifications,
            style: IconButton.styleFrom(
              backgroundColor: TarfaTokens.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text('$notificationCount'),
              backgroundColor: TarfaTokens.secondary,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: TarfaTokens.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TarfaTokens.labelLarge(context).copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Hero profile card ───────────────────────────────────────────────────────

class TarfaProfileHeroCard extends StatelessWidget {
  const TarfaProfileHeroCard({
    super.key,
    required this.name,
    required this.email,
    required this.isGuest,
    this.joinDate,
    this.ordersCount = 0,
    this.onEdit,
    this.showMemberChrome = false,
  });

  final String name;
  final String email;
  final bool isGuest;
  final DateTime? joinDate;
  final int ordersCount;
  final VoidCallback? onEdit;
  final bool showMemberChrome;

  @override
  Widget build(BuildContext context) {
    final tier = showMemberChrome && isGuest
        ? ProfileMembershipTier.active
        : profileMembershipTier(
            isGuest: isGuest,
            ordersCount: ordersCount,
            joinDate: joinDate,
          );
    final showChrome = showMemberChrome || !isGuest;
    final memberLabel = switch (tier) {
      ProfileMembershipTier.guest => 'زائر',
      ProfileMembershipTier.active => 'عضو ${AppBranding.shortName}',
      ProfileMembershipTier.gold => 'عضو ${AppBranding.shortName} Plus',
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF0A0A0A),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowGold.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ProfileDotsPattern(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(TarfaTokens.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showChrome)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _GlassPill(label: memberLabel),
                                  ),
                                const SizedBox(height: TarfaTokens.s12),
                                Text(
                                  name,
                                  style: TarfaTokens.headlineMedium(context)
                                      .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: TarfaTokens.s4),
                                  Text(
                                    email,
                                    textDirection: TextDirection.ltr,
                                    style: TarfaTokens.bodyMedium(context)
                                        .copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: TarfaTokens.s16),
                          _ProfileAvatarSquare(
                            name: name,
                            tier: tier,
                          ),
                        ],
                      ),
                      const SizedBox(height: TarfaTokens.s16),
                      Row(
                        children: [
                          if (onEdit != null)
                            _EditProfileButton(onTap: onEdit!),
                          const Spacer(),
                          if (showChrome && joinDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: TarfaTokens.s4),
                                Text(
                                  profileFormatJoinDate(joinDate!),
                                  style: TarfaTokens.labelMedium(context)
                                      .copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarSquare extends StatelessWidget {
  const _ProfileAvatarSquare({
    required this.name,
    required this.tier,
  });

  final String name;
  final ProfileMembershipTier tier;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.white.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Text(
                  profileInitials(name),
                  style: TarfaTokens.headlineLarge(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (tier != ProfileMembershipTier.guest)
          Positioned(
            bottom: -4,
            left: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TarfaTokens.s8,
                vertical: TarfaTokens.s4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: TarfaTokens.shadowSm,
              ),
              child: Text(
                'مفعّل',
                style: TarfaTokens.labelMedium(context).copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TarfaTokens.s12,
            vertical: TarfaTokens.s4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: TarfaTokens.labelMedium(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TarfaTokens.s16,
                vertical: TarfaTokens.s8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: TarfaTokens.s8),
                  Text(
                    'تعديل الملف',
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

class _ProfileDotsPattern extends CustomPainter {
  _ProfileDotsPattern({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileDotsPattern old) =>
      old.color != color;
}

// ─── Activity stats ──────────────────────────────────────────────────────────

class TarfaProfileActivityRow extends StatelessWidget {
  const TarfaProfileActivityRow({
    super.key,
    required this.orders,
    required this.favorites,
    required this.addresses,
    this.onOrdersTap,
    this.onFavoritesTap,
    this.onAddressesTap,
  });

  final int orders;
  final int favorites;
  final int addresses;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onFavoritesTap;
  final VoidCallback? onAddressesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TarfaProfileSectionTitle(title: 'نشاطك'),
        const SizedBox(height: TarfaTokens.s12),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: TarfaTokens.s24,
            horizontal: TarfaTokens.s8,
          ),
          decoration: BoxDecoration(
            color: TarfaTokens.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: TarfaTokens.shadowSm,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ActivityStat(
                    icon: Icons.shopping_bag_rounded,
                    iconColor: const Color(0xFF92400E),
                    iconBg: AppColors.accentMuted,
                    value: '$orders',
                    label: 'طلباتي',
                    onTap: onOrdersTap,
                  ),
                ),
                VerticalDivider(
                  color: TarfaTokens.divider,
                  width: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                Expanded(
                  child: _ActivityStat(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFDB2777),
                    iconBg: const Color(0xFFFCE7F3),
                    value: '$favorites',
                    label: 'المفضلة',
                    onTap: onFavoritesTap,
                  ),
                ),
                VerticalDivider(
                  color: TarfaTokens.divider,
                  width: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                Expanded(
                  child: _ActivityStat(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFDBEAFE),
                    value: '$addresses',
                    label: 'عناوين',
                    onTap: onAddressesTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TarfaTokens.s4),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: TarfaTokens.s12),
              Text(
                value,
                style: TarfaTokens.headlineMedium(context).copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: TarfaTokens.s4),
              Text(
                label,
                style: TarfaTokens.labelMedium(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu sections ─────────────────────────────────────────────────────────

class TarfaProfileSectionTitle extends StatelessWidget {
  const TarfaProfileSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TarfaTokens.s12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryLight, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: TarfaTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TarfaTokens.titleLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TarfaTokens.bodyMedium(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TarfaProfileMenuCard extends StatelessWidget {
  const TarfaProfileMenuCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TarfaTokens.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: TarfaTokens.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 68,
                endIndent: TarfaTokens.s16,
                color: TarfaTokens.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class TarfaProfileMenuTile extends StatelessWidget {
  const TarfaProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive ? TarfaTokens.error : TarfaTokens.secondary;
    final textColor = destructive ? TarfaTokens.error : TarfaTokens.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TarfaTokens.s16,
            vertical: TarfaTokens.s16,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: TarfaTokens.s12),
              Expanded(
                child: Text(
                  label,
                  style: TarfaTokens.titleMedium(context).copyWith(
                    color: textColor,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: TarfaTokens.s8),
              ],
              if (showChevron && onTap != null)
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: TarfaTokens.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TarfaProfileDarkModeTile extends StatelessWidget {
  const TarfaProfileDarkModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark;
        return Padding(
          padding: const EdgeInsets.all(TarfaTokens.s16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TarfaTokens.s16,
              vertical: TarfaTokens.s16,
            ),
            decoration: BoxDecoration(
              color: TarfaTokens.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark
                      ? const Color(0xFF818CF8)
                      : TarfaTokens.secondary,
                  size: 26,
                ),
                const SizedBox(width: TarfaTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوضع الداكن',
                        style: TarfaTokens.titleMedium(context),
                      ),
                      Text(
                        isDark
                            ? 'مفعّل — مريح للعين ليلاً'
                            : 'مظهر فاتح افتراضي',
                        style: TarfaTokens.bodyMedium(context),
                      ),
                    ],
                  ),
                ),
                _ThemeSwitch(
                  value: isDark,
                  onChanged: ThemeService.instance.setDarkMode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: TarfaTokens.animNormal,
        curve: TarfaTokens.curve,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: value
                ? [TarfaTokens.primary, AppColors.inkElevated]
                : [AppColors.borderStrong, AppColors.border],
          ),
        ),
        child: AnimatedAlign(
          duration: TarfaTokens.animNormal,
          curve: TarfaTokens.curve,
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TarfaProfileLogoutButton extends StatelessWidget {
  const TarfaProfileLogoutButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLogin = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final color = isLogin ? TarfaTokens.secondary : TarfaTokens.error;

    return Material(
      color: TarfaTokens.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: TarfaTokens.primary.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: TarfaTokens.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: TarfaTokens.shadowSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLogin ? Icons.login_rounded : Icons.logout_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: TarfaTokens.s8),
              Text(
                label,
                style: TarfaTokens.titleMedium(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TarfaProfileVersionBadge extends StatelessWidget {
  const TarfaProfileVersionBadge({super.key, this.version = '1.0.0'});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'v$version',
          style: TarfaTokens.labelLarge(context).copyWith(
            color: TarfaTokens.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: TarfaTokens.s4),
        Icon(
          Icons.verified_rounded,
          size: 18,
          color: TarfaTokens.secondary.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}
