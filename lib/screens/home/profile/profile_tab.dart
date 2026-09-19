import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/legal/app_legal_content.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/theme/profile_tokens.dart';
import 'package:matlobgo/core/utils/phone_launcher.dart';
import 'package:matlobgo/core/widgets/auth_layout.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/screens/auth/login_screen.dart';
import 'package:matlobgo/screens/auth/signup_screen.dart';
import 'package:matlobgo/screens/home/addresses/addresses_screen.dart';
import 'package:matlobgo/screens/home/notifications_screen.dart';
import 'package:matlobgo/screens/home/checkout/order_details_screen.dart';
import 'package:matlobgo/screens/home/profile/edit_profile_screen.dart';
import 'package:matlobgo/screens/home/profile/legal_document_screen.dart';
import 'package:matlobgo/screens/home/profile/profile_controller.dart';
import 'package:matlobgo/screens/home/profile/widgets/profile_dashboard_header.dart';
import 'package:matlobgo/screens/home/profile/widgets/profile_hero_card.dart';
import 'package:matlobgo/screens/home/profile/widgets/profile_quick_actions.dart';
import 'package:matlobgo/screens/home/profile/widgets/profile_recent_activity.dart';
import 'package:matlobgo/screens/home/profile/widgets/profile_settings.dart';
import 'package:matlobgo/screens/home/profile/widgets/profile_stats_pair.dart';
import 'package:matlobgo/screens/home/widgets/home_bottom_nav.dart';
import 'package:matlobgo/services/auth_service.dart';
import 'package:matlobgo/services/notification_service.dart';
import 'package:matlobgo/services/theme_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// يطابق `version` في pubspec.yaml (versionName قبل +).
const _kAppVersion = '1.0.6';

/// شاشة حسابي — تكوين رفيع (RI v8).
///
/// التوقيع ثابت للتوافق مع `home_screen`.
class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.user,
    required this.authService,
    required this.notificationService,
    required this.governorateName,
    this.onTabChanged,
    this.onUserUpdated,
    this.onExploreStores,
  });

  final AppUser? user;
  final AuthService authService;
  final NotificationService notificationService;
  final String governorateName;
  final ValueChanged<HomeTab>? onTabChanged;
  final VoidCallback? onUserUpdated;
  final VoidCallback? onExploreStores;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(
      user: widget.user,
      authService: widget.authService,
      notificationService: widget.notificationService,
      governorateName: widget.governorateName,
    );
    _controller.addListener(_onController);
    widget.notificationService.addListener(_onNotifications);
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _controller.updateUser(widget.user);
    }
    if (oldWidget.notificationService != widget.notificationService) {
      oldWidget.notificationService.removeListener(_onNotifications);
      widget.notificationService.addListener(_onNotifications);
    }
  }

  void _onNotifications() => setState(() {});

  void _onController() {
    final notice = _controller.notice;
    if (notice != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              notice,
              style: CartTypography.style(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.navy,
          ),
        );
      _controller.clearNotice();
    }
  }

  @override
  void dispose() {
    widget.notificationService.removeListener(_onNotifications);
    _controller.removeListener(_onController);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NotificationsScreen(
          notificationService: widget.notificationService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _openEditProfile() async {
    if (_controller.isGuest || _controller.user == null) {
      showAuthMessage(context, 'سجّل دخولك لتعديل ملفك الشخصي');
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      widget.onUserUpdated?.call();
      return;
    }
    await openEditProfileScreen(
      context,
      user: _controller.user!,
      authService: widget.authService,
      onSaved: () => widget.onUserUpdated?.call(),
    );
  }

  Future<void> _openAddresses() async {
    if (_controller.isGuest || _controller.user == null) {
      if (!mounted) return;
      showAuthMessage(context, 'سجّل دخولك لإدارة عناوينك');
      return;
    }
    final governorate = EgyptGovernorates.byName(widget.governorateName) ??
        EgyptGovernorates.defaultGovernorate;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddressesScreen(
          user: _controller.user!,
          governorate: governorate,
        ),
      ),
    );
  }

  Future<void> _openFavorites() async {
    widget.onTabChanged?.call(HomeTab.favorites);
  }

  Future<void> _showInfo(String title, String body) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ProfileTokens.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: CartTypography.style(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ProfileTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: CartTypography.style(
                      fontSize: 14,
                      height: 1.6,
                      color: ProfileTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSupport(AppSettings settings) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ProfileTokens.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'المساعدة والدعم',
                    style: CartTypography.style(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ProfileTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.hasSupportPhone
                        ? 'تواصل مع فريق الدعم على الرقم التالي'
                        : 'راسلنا على البريد الإلكتروني',
                    style: CartTypography.style(
                      fontSize: 13,
                      color: ProfileTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (settings.hasSupportPhone) ...[
                    FilledButton.icon(
                      onPressed: () async {
                        final ok =
                            await launchPhoneCall(settings.supportPhone);
                        if (!context.mounted) return;
                        if (!ok) {
                          showAuthMessage(
                            context,
                            'تعذّر فتح تطبيق الاتصال',
                            isError: true,
                          );
                        }
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: Text(
                        'اتصل ${settings.supportPhone.trim()}',
                        style: CartTypography.style(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ProfileTokens.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ] else
                    Text(
                      AppBranding.supportEmail,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: CartTypography.style(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ProfileTokens.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPaymentMethods() async {
    final method = _controller.user?.lastPaymentMethod.trim();
    final label = (method == null || method.isEmpty)
        ? 'الدفع عند الاستلام'
        : method;
    await _showInfo(
      'طرق الدفع',
      'طريقة الدفع الحالية المعتمدة في طلباتك: $label.\n\n'
          'يمكنك اختيار طريقة الدفع عند إتمام الطلب من شاشة الدفع.',
    );
  }

  Future<void> _showCoupons() async {
    final codes = _controller.usedCouponCodes;
    if (codes.isEmpty) {
      await _showInfo(
        'قسائم الخصم',
        'لا توجد قسائم مستخدمة بعد.\n'
            'يمكنك إدخال كود الخصم من السلة أو عند إتمام الطلب.',
      );
      return;
    }
    await _showInfo(
      'قسائم الخصم',
      'القسائم التي استخدمتها:\n\n${codes.map((c) => '• $c').join('\n')}',
    );
  }

  Future<void> _inviteFriend() async {
    final text = _controller.inviteShareText(WebConstants.canonicalOrigin);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAuthMessage(context, 'تم نسخ رسالة الدعوة — شاركها مع أصدقائك');
  }

  Future<void> _deleteAccount() async {
    if (_controller.isGuest) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف الحساب؟',
          style: CartTypography.style(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سيتم حذف حسابك وبيانات ملفك الشخصي نهائياً. '
              'لا يمكن التراجع عن هذا الإجراء.',
              style: CartTypography.style(height: 1.4),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(AppLegalContent.deleteAccountUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(
                'طلب الحذف عبر الويب',
                style: CartTypography.style(
                  fontWeight: FontWeight.w700,
                  color: ProfileTokens.accent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AuthService().deleteMyAccount();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      widget.onUserUpdated?.call();
      showAuthMessage(context, 'تم حذف حسابك بنجاح');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final message = e is StateError
          ? e.message
          : 'تعذّر حذف الحساب — حاول لاحقاً أو تواصل مع الدعم';
      showAuthMessage(context, message, isError: true);
    }
  }

  Future<void> _handleAuth() async {
    if (_controller.isGuest) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      widget.onUserUpdated?.call();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: CartTypography.style(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'هل تريد تسجيل الخروج من حسابك؟',
          style: CartTypography.style(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ProfileTokens.accent),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _controller.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, ThemeService.instance]),
      builder: (context, _) {
        final c = _controller;
        final subtitle = c.email.isNotEmpty
            ? c.email
            : (c.phone.isNotEmpty ? c.phone : c.membershipLabel);

        return ColoredBox(
          color: PremiumBackground.scaffoldColor(context),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: ProfileDashboardHeader(
                  onNotifications: _openNotifications,
                  notificationCount: c.unreadNotifications,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (c.offline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'اتصال ضعيف — قد تتأخر بعض التحديثات',
                          style: CartTypography.style(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: ProfileTokens.accent,
                          ),
                        ),
                      ),
                    ProfileHeroCard(
                      name: c.displayName,
                      subtitle: subtitle,
                      initials: c.initials,
                      membershipLabel: c.membershipLabel,
                      isGuest: c.isGuest,
                      onEdit: _openEditProfile,
                    ),
                    if (c.isGuest) ...[
                      const SizedBox(height: 12),
                      _GuestBanner(
                        onSignUp: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                          widget.onUserUpdated?.call();
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    ProfileStatsPair(
                      ordersCount: c.ordersCount,
                      favoritesCount: c.favoritesCount,
                      onOrdersTap: () =>
                          widget.onTabChanged?.call(HomeTab.orders),
                      onFavoritesTap: _openFavorites,
                    ),
                    const SizedBox(height: 22),
                    ProfileQuickActionsSection(
                      actions: [
                        ProfileQuickActionItem(
                          icon: Icons.location_on_outlined,
                          label: 'عناوينى',
                          onTap: _openAddresses,
                        ),
                        ProfileQuickActionItem(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'طرق الدفع',
                          onTap: _showPaymentMethods,
                        ),
                        ProfileQuickActionItem(
                          icon: Icons.confirmation_number_outlined,
                          label: 'قسائم الخصم',
                          onTap: _showCoupons,
                        ),
                        ProfileQuickActionItem(
                          icon: Icons.person_add_alt_1_outlined,
                          label: 'دعوة صديق',
                          onTap: _inviteFriend,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ProfileRecentActivitySection(
                      order: c.lastOrder,
                      onViewAll: () =>
                          widget.onTabChanged?.call(HomeTab.orders),
                      onTapOrder: () {
                        final order = c.lastOrder;
                        if (order == null) return;
                        openOrderDetailsScreen(context, order: order);
                      },
                    ),
                    const SizedBox(height: 22),
                    ProfileSettingsSection(
                      title: 'الإعدادات',
                      tiles: [
                        ProfileSettingsTileData(
                          icon: Icons.lock_outline_rounded,
                          label: 'الأمان وكلمة المرور',
                          onTap: c.isGuest
                              ? () => showAuthMessage(
                                    context,
                                    'سجّل دخولك لإدارة كلمة المرور',
                                  )
                              : () => c.sendPasswordReset(),
                        ),
                        ProfileSettingsTileData(
                          icon: Icons.dark_mode_outlined,
                          label: 'الوضع الداكن',
                          showChevron: false,
                          trailing: ProfileDarkModeSwitch(
                            value: c.isDark,
                            onChanged: c.setDarkMode,
                          ),
                        ),
                        ProfileSettingsTileData(
                          icon: Icons.notifications_outlined,
                          label: 'إشعارات التطبيق',
                          onTap: _openNotifications,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ProfileSettingsSection(
                      title: 'المساعدة',
                      tiles: [
                        ProfileSettingsTileData(
                          icon: Icons.help_outline_rounded,
                          label: 'مركز المساعدة والدردشة',
                          onTap: () => _showSupport(c.settings),
                        ),
                        ProfileSettingsTileData(
                          icon: Icons.privacy_tip_outlined,
                          label: 'سياسة الخصوصية',
                          onTap: () => LegalDocumentScreen.open(
                            context,
                            document: AppLegalDocument.privacyPolicy,
                          ),
                        ),
                        ProfileSettingsTileData(
                          icon: Icons.description_outlined,
                          label: 'الشروط والأحكام',
                          onTap: () => LegalDocumentScreen.open(
                            context,
                            document: AppLegalDocument.termsOfService,
                          ),
                        ),
                        if (!c.isGuest)
                          ProfileSettingsTileData(
                            icon: Icons.delete_forever_outlined,
                            label: 'حذف الحساب',
                            onTap: _deleteAccount,
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ProfileLogoutFooter(
                      label: c.isGuest ? 'تسجيل الدخول' : 'تسجيل الخروج',
                      isLogin: c.isGuest,
                      version: _kAppVersion,
                      onTap: _handleAuth,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onSignUp});

  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileTokens.navy.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onSignUp,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded,
                  color: ProfileTokens.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'أنشئ حساباً لحفظ طلباتك ومفضلتك',
                  style: CartTypography.style(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ProfileTokens.navy,
                  ),
                ),
              ),
              const Icon(Icons.chevron_left_rounded,
                  color: ProfileTokens.navy),
            ],
          ),
        ),
      ),
    );
  }
}
