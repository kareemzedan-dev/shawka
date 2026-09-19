import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/constants/app_branding.dart';
import 'package:matlobgo/admin/models/admin_permissions.dart';
import 'package:matlobgo/admin/models/admin_section.dart';
import 'package:matlobgo/admin/screens/admin_login_screen.dart';
import 'package:matlobgo/admin/services/admin_auth_service.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/admin/widgets/admin_activity_types_panel.dart';
import 'package:matlobgo/admin/widgets/admin_alerts_panel.dart';
import 'package:matlobgo/admin/widgets/admin_analytics_panel.dart';
import 'package:matlobgo/admin/widgets/admin_audit_panel.dart';
import 'package:matlobgo/admin/widgets/admin_categories_panel.dart';
import 'package:matlobgo/admin/widgets/admin_cms_texts_panel.dart';
import 'package:matlobgo/admin/widgets/admin_search_page_panel.dart';
import 'package:matlobgo/admin/widgets/admin_customers_panel.dart';
import 'package:matlobgo/admin/widgets/admin_delivery_panel.dart';
import 'package:matlobgo/admin/widgets/admin_delivery_pricing_panel.dart';
import 'package:matlobgo/admin/widgets/admin_governorate_bar.dart';
import 'package:matlobgo/admin/widgets/admin_job_queue_panel.dart';
import 'package:matlobgo/admin/widgets/admin_live_monitor_panel.dart';
import 'package:matlobgo/admin/widgets/admin_governorates_panel.dart';
import 'package:matlobgo/admin/widgets/admin_incidents_panel.dart';
import 'package:matlobgo/admin/widgets/admin_operations_panel.dart';
import 'package:matlobgo/admin/widgets/admin_rescue_orders_panel.dart';
import 'package:matlobgo/admin/widgets/admin_notifications_panel.dart';
import 'package:matlobgo/admin/widgets/admin_orders_panel.dart';
import 'package:matlobgo/admin/widgets/admin_overview_panel.dart';
import 'package:matlobgo/admin/widgets/admin_promo_banners_panel.dart';
import 'package:matlobgo/admin/widgets/admin_promotions_panel.dart';
import 'package:matlobgo/admin/widgets/admin_reviews_panel.dart';
import 'package:matlobgo/admin/widgets/admin_most_ordered_panel.dart';
import 'package:matlobgo/admin/widgets/admin_roles_panel.dart';
import 'package:matlobgo/admin/widgets/admin_settlement_requests_panel.dart';
import 'package:matlobgo/admin/widgets/admin_settings_panel.dart';
import 'package:matlobgo/admin/widgets/admin_stores_panel.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/brand_logo.dart';
import 'package:matlobgo/models/admin_staff_role.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.user});

  final AppUser? user;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _shellNavKey = GlobalKey<NavigatorState>();
  AdminSection _section = AdminSection.overview;
  Governorate _governorate = EgyptGovernorates.defaultGovernorate;
  StoreCategoryDef? _storesCategoryFilter;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    AdminSession.instance.bind(_user);
    final visible = _visibleSections;
    if (visible.isNotEmpty && !visible.contains(_section)) {
      _section = visible.first;
    }
  }

  AdminStaffRole get _staffRole => _user?.staffRole ?? AdminStaffRole.admin;

  List<AdminSection> get _visibleSections => AdminSection.values
      .where((s) => AdminPermissions.canAccess(_staffRole, s))
      .toList();

  void _selectSection(AdminSection section) {
    if (!AdminPermissions.canAccess(_staffRole, section)) return;
    if (_section == section) return;
    if (kDebugMode) {
      debugPrint(
        '[AdminShell] _selectSection ${_section.name} → ${section.name} '
        'routes=${_shellNavKey.currentState?.widget.toString()}',
      );
      debugPrint('[AdminShell] STACK:\n${StackTrace.current}');
    }
    setState(() {
      _section = section;
      if (section != AdminSection.allStores) {
        _storesCategoryFilter = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        debugPrint(
          '[AdminShell] pushReplacement sectionBody '
          '(this pops any open form routes)',
        );
      }
      _shellNavKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => _sectionBody()),
      );
    });
  }

  void _pushPage(Widget page) {
    if (kDebugMode) {
      debugPrint(
        '[AdminShell] _pushPage ${page.runtimeType} '
        'hash=${page.hashCode}',
      );
    }
    _shellNavKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _sectionBody() {
    return switch (_section) {
      AdminSection.overview => AdminOverviewPanel(governorate: _governorate),
      AdminSection.analytics =>
        AdminAnalyticsPanel(governorate: _governorate),
      AdminSection.operations =>
        AdminOperationsPanel(governorate: _governorate),
      AdminSection.liveMonitor =>
        AdminLiveMonitorPanel(governorate: _governorate),
      AdminSection.rescueOrders =>
        AdminRescueOrdersPanel(governorate: _governorate),
      AdminSection.incidents => AdminIncidentsPanel(),
      AdminSection.categories => AdminCategoriesPanel(
          governorate: _governorate,
          onPushPage: _pushPage,
          onOpenStores: _openStoresForCategory,
        ),
      AdminSection.allStores => AdminStoresPanel(
          governorate: _governorate,
          categoryFilter: _storesCategoryFilter,
          onPushPage: _pushPage,
          onClearCategoryFilter: () =>
              setState(() => _storesCategoryFilter = null),
        ),
      AdminSection.orders => AdminOrdersPanel(governorate: _governorate),
      AdminSection.customers => AdminCustomersPanel(
          governorate: _governorate,
          onOpenRegistrationRequests: () =>
              _selectSection(AdminSection.registrationRequests),
        ),
      AdminSection.registrationRequests => AdminCustomersPanel(
          governorate: _governorate,
          initialTab: 1,
        ),
      AdminSection.delivery => AdminDeliveryPanel(governorate: _governorate),
      AdminSection.settlementRequests => const AdminSettlementRequestsPanel(),
      AdminSection.promoBanners => AdminPromoBannersPanel(
          governorate: _governorate,
          onPushPage: _pushPage,
        ),
      AdminSection.promotions =>
        AdminPromotionsPanel(governorate: _governorate),
      AdminSection.reviews => const AdminReviewsPanel(),
      AdminSection.mostOrdered =>
        AdminMostOrderedPanel(governorate: _governorate),
      AdminSection.cmsTexts => const AdminCmsTextsPanel(),
      AdminSection.searchPage => const AdminSearchPagePanel(),
      AdminSection.activityTypes => const AdminActivityTypesPanel(),
      AdminSection.alerts => const AdminAlertsPanel(),
      AdminSection.notifications => AdminNotificationsPanel(
          actorName: _user?.name ?? 'Admin',
        ),
      AdminSection.governorates => const AdminGovernoratesPanel(),
      AdminSection.deliveryPricing => const AdminDeliveryPricingPanel(),
      AdminSection.settings => const AdminSettingsPanel(),
      AdminSection.roles => AdminRolesPanel(
        currentUser: _user,
        governorate: _governorate,
      ),
      AdminSection.auditLogs => const AdminAuditPanel(),
      AdminSection.jobQueue => const AdminJobQueuePanel(),
    };
  }

  void _openStoresForCategory(StoreCategoryDef category) {
    setState(() {
      _storesCategoryFilter = category;
      _section = AdminSection.allStores;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shellNavKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => _sectionBody()),
      );
    });
  }

  Future<void> _signOut() async {
    AdminSession.instance.clear();
    await AdminAuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final visible = _visibleSections;

    return Scaffold(
      backgroundColor: AdminTheme.contentBg,
      body: Row(
        children: [
          if (!compact)
            _Sidebar(
              selected: _section,
              sections: visible,
              userName: _user?.name ?? 'المدير',
              staffRole: _staffRole.label,
              onSelect: _selectSection,
              onSignOut: _signOut,
            ),
          Expanded(
            child: Column(
              children: [
                if (_section.usesGovernorateFilter)
                  AdminGovernorateBar(
                    selected: _governorate,
                    onChanged: (g) {
                      if (g.id == _governorate.id) return;
                      if (kDebugMode) {
                        debugPrint(
                          '[AdminShell] governorate ${_governorate.id} → ${g.id} '
                          '(setState — must NOT dispose open form routes)',
                        );
                      }
                      setState(() => _governorate = g);
                    },
                  ),
                if (compact)
                  _MobileHeader(
                    section: _section,
                    onMenu: () => _openDrawer(context, visible),
                    onSignOut: _signOut,
                  ),
                Expanded(
                  child: Navigator(
                    key: _shellNavKey,
                    onGenerateRoute: (_) => MaterialPageRoute(
                      settings: RouteSettings(name: _section.name),
                      builder: (_) => _sectionBody(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: compact
          ? Drawer(
              child: _Sidebar(
                selected: _section,
                sections: visible,
                userName: _user?.name ?? 'المدير',
                staffRole: _staffRole.label,
                onSelect: (s) {
                  Navigator.pop(context);
                  _selectSection(s);
                },
                onSignOut: _signOut,
              ),
            )
          : null,
    );
  }

  void _openDrawer(BuildContext context, List<AdminSection> sections) {
    Scaffold.of(context).openDrawer();
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.sections,
    required this.userName,
    required this.staffRole,
    required this.onSelect,
    required this.onSignOut,
  });

  final AdminSection selected;
  final List<AdminSection> sections;
  final String userName;
  final String staffRole;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AdminSection>>{};
    for (final section in sections) {
      final group = section.group ?? 'أخرى';
      groups.putIfAbsent(group, () => []).add(section);
    }

    return Container(
      width: AdminTheme.sidebarWidth,
      decoration: const BoxDecoration(
        color: AdminTheme.sidebar,
        border: Border(
          left: BorderSide(color: Color(0xFF1F1F1F)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(
                  width: 132,
                  style: BrandLogoStyle.standalone,
                ),
                const SizedBox(height: 14),
                Text(
                  AppBranding.adminPanelTitle,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enterprise Console',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userName.trim().isEmpty
                              ? 'A'
                              : String.fromCharCodes(
                                  userName.trim().runes.take(1),
                                ),
                          style: GoogleFonts.cairo(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              staffRole,
                              style: GoogleFonts.cairo(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                for (final entry in groups.entries) ...[
                  _NavGroup(title: entry.key),
                  ...entry.value.map(
                    (s) => _NavItem(
                      section: s,
                      selected: selected,
                      onTap: onSelect,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: TextButton.icon(
              onPressed: onSignOut,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  const _NavGroup({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.cairo(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AdminSection section;
  final AdminSection selected;
  final ValueChanged<AdminSection> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = section == selected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected ? AdminTheme.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        child: InkWell(
          onTap: () => onTap(section),
          hoverColor: AdminTheme.sidebarHover,
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (isSelected)
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                else
                  const SizedBox(width: 11),
                Icon(
                  section.icon,
                  size: 20,
                  color: isSelected ? AppColors.primaryLight : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
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

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.section,
    required this.onMenu,
    required this.onSignOut,
  });

  final AdminSection section;
  final VoidCallback onMenu;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminTheme.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded),
                  color: AppColors.textPrimary,
                ),
                Expanded(
                  child: Text(
                    section.title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
