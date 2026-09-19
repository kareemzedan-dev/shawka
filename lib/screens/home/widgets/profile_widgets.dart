import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/services/theme_service.dart';
import 'package:matlobgo/core/constants/app_branding.dart';

String profileFormatJoinDate(DateTime date) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return 'انضم في ${date.day} ${months[date.month - 1]} ${date.year}';
}

String profileInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'م';
  if (parts.length == 1) return parts.first.characters.first;
  return '${parts.first.characters.first}${parts[1].characters.first}';
}

enum ProfileMembershipTier { guest, active, gold }

ProfileMembershipTier profileMembershipTier({
  required bool isGuest,
  required int ordersCount,
  DateTime? joinDate,
}) {
  if (isGuest) return ProfileMembershipTier.guest;
  final daysSinceJoin =
      joinDate != null ? DateTime.now().difference(joinDate).inDays : 0;
  if (ordersCount >= 8 ||
      (ordersCount >= 3 && daysSinceJoin >= 90)) {
    return ProfileMembershipTier.gold;
  }
  return ProfileMembershipTier.active;
}

// ─── Page header (حسابي) ─────────────────────────────────────────────────────

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({
    super.key,
    required this.palette,
    required this.onNotifications,
    this.avatarInitials = 'م',
    this.notificationCount = 0,
  });

  final AppPalette palette;
  final VoidCallback onNotifications;
  final String avatarInitials;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 16),
      child: Row(
        children: [
          _MiniProfileAvatar(initials: avatarInitials),
          const Spacer(),
          Text(
            'حسابي',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onNotifications,
            style: IconButton.styleFrom(
              backgroundColor: palette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text('$notificationCount'),
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProfileAvatar extends StatelessWidget {
  const _MiniProfileAvatar({required this.initials});

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
        style: GoogleFonts.cairo(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ─── Premium header ───────────────────────────────────────────────────────────

class ProfileUserCard extends StatelessWidget {
  const ProfileUserCard({
    super.key,
    required this.user,
    required this.name,
    required this.email,
    required this.isGuest,
    required this.palette,
    this.ordersCount = 0,
    this.onEdit,
  });

  final AppUser? user;
  final String name;
  final String email;
  final bool isGuest;
  final AppPalette palette;
  final int ordersCount;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final joinDate = user?.createdAt;
    final tier = profileMembershipTier(
      isGuest: isGuest,
      ordersCount: ordersCount,
      joinDate: joinDate,
    );
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
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: palette.isDark
                    ? const [
                        Color(0xFF1A1A1A),
                        Color(0xFF0A0A0A),
                        Color(0xFF000000),
                      ]
                    : const [
                        Color(0xFF1A1A1A),
                        Color(0xFF0A0A0A),
                        Color(0xFF000000),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ProfileHeaderPattern(
                      color: AppColors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
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
                                if (!isGuest)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _GlassMemberPill(label: memberLabel),
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                    height: 1.15,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.ltr,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _ProfileAvatarSquare(name: name, tier: tier),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (onEdit != null) _EditProfileButton(onTap: onEdit!),
                          const Spacer(),
                          if (!isGuest && joinDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: AppColors.white.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profileFormatJoinDate(joinDate),
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.white.withValues(alpha: 0.75),
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
                    color: AppColors.white.withValues(alpha: 0.18),
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
  const _ProfileAvatarSquare({required this.name, required this.tier});

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
                color: AppColors.black.withValues(alpha: 0.15),
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
                color: AppColors.white.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Text(
                  profileInitials(name),
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'مفعّل',
                style: GoogleFonts.cairo(
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

class _GlassMemberPill extends StatelessWidget {
  const _GlassMemberPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'تعديل الملف',
                    style: GoogleFonts.cairo(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

class _ProfileHeaderPattern extends CustomPainter {
  _ProfileHeaderPattern({required this.color});

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
  bool shouldRepaint(covariant _ProfileHeaderPattern oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Activity stats (نشاطك) ──────────────────────────────────────────────────

class ProfileActivityRow extends StatelessWidget {
  const ProfileActivityRow({
    super.key,
    required this.palette,
    required this.orders,
    required this.favorites,
    required this.addresses,
    this.onOrdersTap,
    this.onFavoritesTap,
    this.onAddressesTap,
  });

  final AppPalette palette;
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
        ProfileSectionTitle(title: 'نشاطك', palette: palette),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
            boxShadow: HomeTheme.softShadow(palette),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ProfileActivityStat(
                    icon: Icons.shopping_bag_rounded,
                    iconColor: const Color(0xFF92400E),
                    iconBg: AppColors.accentMuted,
                    value: '$orders',
                    label: 'طلباتي',
                    onTap: onOrdersTap,
                  ),
                ),
                VerticalDivider(
                  color: palette.border,
                  width: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                Expanded(
                  child: _ProfileActivityStat(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFDB2777),
                    iconBg: const Color(0xFFFCE7F3),
                    value: '$favorites',
                    label: 'المفضلة',
                    onTap: onFavoritesTap,
                  ),
                ),
                VerticalDivider(
                  color: palette.border,
                  width: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                Expanded(
                  child: _ProfileActivityStat(
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

class _ProfileActivityStat extends StatelessWidget {
  const _ProfileActivityStat({
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
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({
    super.key,
    required this.palette,
    required this.label,
    required this.onTap,
    this.isLogin = false,
  });

  final AppPalette palette;
  final String label;
  final VoidCallback onTap;
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final color = isLogin ? AppColors.primary : AppColors.error;

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
            boxShadow: HomeTheme.softShadow(palette),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLogin ? Icons.login_rounded : Icons.logout_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileVersionBadge extends StatelessWidget {
  const ProfileVersionBadge({super.key, this.version = '1.0.0'});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'v$version',
          style: GoogleFonts.cairo(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.verified_rounded,
          size: 18,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────

class ProfileQuickAction {
  const ProfileQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    this.count,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final int? count;
}

class ProfileQuickActionsGrid extends StatelessWidget {
  const ProfileQuickActionsGrid({
    super.key,
    required this.actions,
    required this.palette,
  });

  final List<ProfileQuickAction> actions;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ProfileQuickActionTile(
          icon: action.icon,
          label: action.label,
          accent: action.accent,
          count: action.count,
          onTap: action.onTap,
          palette: palette,
        );
      },
    );
  }
}

class _ProfileQuickActionTile extends StatefulWidget {
  const _ProfileQuickActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    required this.palette,
    this.count,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final AppPalette palette;
  final int? count;

  @override
  State<_ProfileQuickActionTile> createState() =>
      _ProfileQuickActionTileState();
}

class _ProfileQuickActionTileState extends State<_ProfileQuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: HomeTheme.borderMd,
        splashColor: widget.accent.withValues(alpha: 0.12),
        highlightColor: widget.accent.withValues(alpha: 0.06),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: HomeTheme.animPress,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: HomeTheme.animStandard,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: widget.palette.card,
              borderRadius: HomeTheme.borderMd,
              border: Border.all(
                color: _pressed
                    ? widget.accent.withValues(alpha: 0.35)
                    : widget.palette.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(
                    alpha: _pressed ? 0.14 : 0.06,
                  ),
                  blurRadius: _pressed ? 18 : 12,
                  offset: Offset(0, _pressed ? 6 : 4),
                ),
                ...HomeTheme.softShadow(widget.palette),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accent.withValues(alpha: 0.18),
                            widget.accent.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: widget.accent,
                      ),
                    ),
                    const Spacer(),
                    if (widget.count != null && widget.count! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.count}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: widget.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.label,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: widget.palette.textPrimary,
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

// ─── Stats dashboard ──────────────────────────────────────────────────────────

class ProfileStatItem {
  const ProfileStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({
    super.key,
    required this.stats,
    required this.palette,
    this.onExplore,
  });

  final List<ProfileStatItem> stats;
  final AppPalette palette;
  final VoidCallback? onExplore;

  bool get _isEmpty => stats.every((s) => s.value == '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: HomeTheme.borderMd,
        border: Border.all(color: palette.border),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'نشاطك',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (_isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: _ProfileInlineEmpty(
                palette: palette,
                onExplore: onExplore,
              ),
            )
          else
            IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: palette.border.withValues(alpha: 0.9),
                        indent: 12,
                        endIndent: 12,
                      ),
                    Expanded(
                      child: _ProfileStatCell(
                        stat: stats[i],
                        palette: palette,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!_isEmpty) const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ProfileStatCell extends StatelessWidget {
  const _ProfileStatCell({
    required this.stat,
    required this.palette,
  });

  final ProfileStatItem stat;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(stat.icon, size: 18, color: AppColors.primary.withValues(alpha: 0.85)),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInlineEmpty extends StatelessWidget {
  const _ProfileInlineEmpty({
    required this.palette,
    this.onExplore,
  });

  final AppPalette palette;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: HomeTheme.borderSm,
        border: Border.all(color: palette.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 32,
            color: palette.textHint,
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ رحلتك مع ${AppBranding.shortName}',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اطلب الآن لترى طلباتك ومفضلاتك وعناوينك هنا',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              height: 1.45,
              color: palette.textSecondary,
            ),
          ),
          if (onExplore != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExplore,
              child: Text(
                'استكشف المتاجر',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sections & menu ──────────────────────────────────────────────────────────

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    super.key,
    required this.title,
    required this.palette,
    this.subtitle,
  });

  final String title;
  final AppPalette palette;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 2),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    super.key,
    required this.palette,
    required this.children,
  });

  final AppPalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 64,
                endIndent: 16,
                color: palette.border.withValues(alpha: 0.75),
              ),
          ],
        ],
      ),
    );
  }
}

class ProfileMenuTile extends StatefulWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.palette,
    this.trailing,
    this.isDestructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final AppPalette palette;
  final Widget? trailing;
  final bool isDestructive;
  final bool showChevron;

  @override
  State<ProfileMenuTile> createState() => _ProfileMenuTileState();
}

class _ProfileMenuTileState extends State<ProfileMenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isDestructive ? AppColors.error : widget.palette.textPrimary;
    final iconColor =
        widget.isDestructive ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onHighlightChanged:
            widget.onTap == null ? null : (v) => setState(() => _pressed = v),
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: HomeTheme.animPress,
          color: _pressed
              ? widget.palette.surfaceMuted.withValues(alpha: 0.65)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              AnimatedScale(
                scale: _pressed ? 0.94 : 1,
                duration: HomeTheme.animPress,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isDestructive
                        ? AppColors.error.withValues(alpha: 0.1)
                        : widget.palette.accentMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, size: 20, color: iconColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                widget.trailing!,
                const SizedBox(width: 6),
              ],
              if (widget.showChevron && widget.onTap != null)
                AnimatedOpacity(
                  opacity: _pressed ? 1 : 0.55,
                  duration: HomeTheme.animPress,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: widget.palette.textHint,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileDarkModeTile extends StatelessWidget {
  const ProfileDarkModeTile({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.borderLight),
            ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: HomeTheme.animStandard,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                  color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الوضع الداكن',
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      isDark ? 'مفعّل — مريح للعين ليلاً' : 'مظهر فاتح افتراضي',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _PremiumThemeSwitch(
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

class _PremiumThemeSwitch extends StatelessWidget {
  const _PremiumThemeSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 54,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value
              ? LinearGradient(
                  colors: [
                    AppColors.navy,
                    AppColors.navyLight,
                  ],
                )
              : LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: (value ? AppColors.navy : AppColors.primary)
                  .withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileGuestCard extends StatelessWidget {
  const ProfileGuestCard({
    super.key,
    required this.onSignUp,
    required this.palette,
  });

  final VoidCallback onSignUp;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary.withValues(alpha: palette.isDark ? 0.12 : 0.08),
            palette.card,
          ],
        ),
        borderRadius: HomeTheme.borderMd,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
        boxShadow: HomeTheme.softShadow(palette),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أنشئ حسابك',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  'احفظ طلباتك واستمتع بعروض حصرية',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onSignUp,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'سجّل',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileNotificationBadge extends StatelessWidget {
  const ProfileNotificationBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }
}
