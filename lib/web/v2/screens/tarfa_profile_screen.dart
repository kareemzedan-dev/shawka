import 'package:flutter/material.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/screens/home/widgets/profile_widgets.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/favorites_service.dart';
import 'package:matlobgo/services/order_service.dart';
import 'package:matlobgo/services/theme_service.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_governorate_service.dart';
import 'package:matlobgo/web/services/web_seo_service.dart';
import 'package:matlobgo/web/v2/design/tarfa_tokens.dart';
import 'package:matlobgo/web/v2/services/tarfa_ui_service.dart';
import 'package:matlobgo/web/v2/widgets/tarfa_profile_widgets.dart';
import 'package:matlobgo/web/widgets/web_app_conversion_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _kAppVersion = '1.0.1';

class TarfaProfileScreen extends StatefulWidget {
  const TarfaProfileScreen({super.key, this.govId});

  final String? govId;

  @override
  State<TarfaProfileScreen> createState() => _TarfaProfileScreenState();
}

class _TarfaProfileScreenState extends State<TarfaProfileScreen> {
  String _guestName = 'ضيف';
  String _guestEmail = '';
  DateTime? _joinDate;

  @override
  void initState() {
    super.initState();
    _loadGuestMeta();
    final govId = widget.govId ?? WebGovernorateService.instance.governorateId;
    WebSeoService.instance.apply(
      title: 'حسابي — ${AppBranding.shortName}',
      canonicalPath: WebConstants.profilePath(govId),
    );
  }

  Future<void> _loadGuestMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final created = prefs.getString('web_guest_created');
    if (!mounted) return;
    setState(() {
      _guestName = prefs.getString('web_guest_name') ?? 'ضيف';
      _guestEmail = prefs.getString('web_guest_email') ?? '';
      if (created != null) {
        _joinDate = DateTime.tryParse(created);
      } else {
        _joinDate = DateTime.now();
        prefs.setString('web_guest_created', _joinDate!.toIso8601String());
      }
    });
  }

  int _addressCount() {
    final unique = <String>{};
    for (final order in OrderService.instance.orders) {
      final address = order.address?.trim();
      if (address != null && address.isNotEmpty) unique.add(address);
    }
    if (unique.isNotEmpty) return unique.length;
    final gov = WebGovernorateService.instance.governorateName;
    return gov.isNotEmpty ? 1 : 0;
  }

  int _favoritesCount() {
    final mobile = FavoritesService.instance.totalCount;
    final web = TarfaFavoritesService.instance.count;
    return mobile > 0 ? mobile : web;
  }

  void _showInfo(String title, String body) {
    showModalBottomSheet<void>(
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
              decoration: BoxDecoration(
                color: TarfaTokens.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(TarfaTokens.s24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TarfaTokens.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: TarfaTokens.s24),
                  Text(title, style: TarfaTokens.headlineMedium(context)),
                  const SizedBox(height: TarfaTokens.s12),
                  Text(body, style: TarfaTokens.bodyLarge(context)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < TarfaTokens.mobileBreakpoint;
    final hPad = isMobile ? TarfaTokens.s16 : TarfaTokens.s40;

    return ListenableBuilder(
      listenable: Listenable.merge([
        OrderService.instance,
        FavoritesService.instance,
        TarfaFavoritesService.instance,
        ThemeService.instance,
        AppConfigService.instance,
      ]),
      builder: (context, _) {
        final ordersCount = OrderService.instance.orders.length;
        final favoritesCount = _favoritesCount();
        final addressesCount = _addressCount();
        final settings = AppConfigService.instance.settings;
        const isGuest = true;
        final name = _guestName;
        final email = _guestEmail;

        return ColoredBox(
          color: TarfaTokens.background,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: TarfaProfileHeader(
                  avatarInitials: profileInitials(name),
                  onNotifications: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppBranding.notificationsInAppMessage),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, TarfaTokens.s80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    TarfaProfileHeroCard(
                      name: name,
                      email: email,
                      isGuest: isGuest,
                      joinDate: _joinDate,
                      ordersCount: ordersCount,
                      showMemberChrome: true,
                      onEdit: () => showWebAppConversionModal(context),
                    ),
                    const SizedBox(height: TarfaTokens.s24),
                    TarfaProfileActivityRow(
                      orders: ordersCount,
                      favorites: favoritesCount,
                      addresses: addressesCount,
                      onOrdersTap: () => showWebAppConversionModal(context),
                      onFavoritesTap: () => showWebAppConversionModal(context),
                      onAddressesTap: () => showWebAppConversionModal(context),
                    ),
                    const SizedBox(height: TarfaTokens.s32),
                    const TarfaProfileSectionTitle(title: 'حسابي'),
                    TarfaProfileMenuCard(
                      children: [
                        TarfaProfileMenuTile(
                          icon: Icons.edit_outlined,
                          label: 'تعديل الملف الشخصي',
                          onTap: () => showWebAppConversionModal(context),
                        ),
                        TarfaProfileMenuTile(
                          icon: Icons.notifications_outlined,
                          label: 'الإشعارات',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppBranding.notificationsInAppMessage,
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        TarfaProfileMenuTile(
                          icon: Icons.help_outline_rounded,
                          label: 'المساعدة والدعم',
                          trailing: settings.hasSupportPhone
                              ? Text(
                                  settings.supportPhone.trim(),
                                  style: TarfaTokens.labelMedium(context)
                                      .copyWith(
                                    color: TarfaTokens.secondary,
                                  ),
                                )
                              : null,
                          onTap: () => _showInfo(
                            'المساعدة والدعم',
                            settings.hasSupportPhone
                                ? 'تواصل معنا: ${settings.supportPhone}'
                                : AppBranding.supportEmail,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TarfaTokens.s32),
                    const TarfaProfileSectionTitle(
                      title: 'الإعدادات',
                      subtitle: 'تخصيص تجربة التطبيق',
                    ),
                    TarfaProfileMenuCard(
                      children: const [
                        TarfaProfileDarkModeTile(),
                      ],
                    ),
                    const SizedBox(height: TarfaTokens.s32),
                    const TarfaProfileSectionTitle(
                      title: 'عن التطبيق',
                      subtitle: 'معلومات قانونية وإصدار التطبيق',
                    ),
                    TarfaProfileMenuCard(
                      children: [
                        TarfaProfileMenuTile(
                          icon: Icons.info_outline_rounded,
                          label: 'عن التطبيق',
                          onTap: () => _showInfo(
                            'عن ${AppBranding.shortName}',
                            AppBranding.aboutDescription,
                          ),
                        ),
                        TarfaProfileMenuTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'سياسة الخصوصية',
                          onTap: () => _showInfo(
                            'سياسة الخصوصية',
                            'نحن نحترم خصوصيتك ونعمل على حماية بياناتك الشخصية. '
                            'يتم استخدام معلوماتك فقط لتقديم خدمات التطبيق، مثل إنشاء الحساب، '
                            'تنفيذ الطلبات، وتحسين تجربة الاستخدام. '
                            'لا نقوم ببيع أو مشاركة بياناتك مع أي طرف إلا عند الحاجة لتنفيذ الخدمة '
                            'أو وفقًا لما يقتضيه القانون.\n\n'
                            'باستخدام التطبيق فإنك توافق على سياسة الخصوصية الخاصة بنا.',
                          ),
                        ),
                        TarfaProfileMenuTile(
                          icon: Icons.description_outlined,
                          label: 'الشروط والأحكام',
                          onTap: () => _showInfo(
                            'الشروط والأحكام',
                            'باستخدام تطبيق ${AppBranding.shortName} فإنك توافق على الالتزام بشروط الاستخدام. '
                            'يتحمل المستخدم مسؤولية صحة بياناته واستخدام التطبيق بشكل قانوني. '
                            'قد تختلف الأسعار وأوقات التوصيل حسب المتجر أو المورد، '
                            'ويتم عرض التفاصيل قبل تأكيد الطلب. '
                            'يحتفظ ${AppBranding.shortName} بالحق في تحديث الخدمات أو هذه الشروط في أي وقت '
                            'بما يضمن تحسين جودة الخدمة.',
                          ),
                        ),
                        TarfaProfileMenuTile(
                          icon: Icons.star_outline_rounded,
                          label: 'تقييم التطبيق',
                          onTap: () async {
                            final uri = Uri.parse(WebConstants.googlePlayUrl);
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                        TarfaProfileMenuTile(
                          icon: Icons.verified_outlined,
                          label: 'إصدار التطبيق',
                          showChevron: false,
                          onTap: null,
                          trailing: const TarfaProfileVersionBadge(
                            version: _kAppVersion,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TarfaTokens.s24),
                    TarfaProfileLogoutButton(
                      label: 'تسجيل الخروج',
                      onTap: () => showWebAppConversionModal(context),
                    ),
                    const SizedBox(height: TarfaTokens.s16),
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
