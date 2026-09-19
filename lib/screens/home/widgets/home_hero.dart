import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matlobgo/services/cms_text_service.dart';
import 'package:matlobgo/core/theme/home_typography.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/home_theme.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/widgets/matlob_home_ui_primitives.dart';

/// MatlobGo home — light design system palette (mockup-driven).
abstract final class MatlobHomeColors {
  static const Color navy = AppColors.navy;
  static const Color navyLight = AppColors.navyLight;
  static const Color navyMuted = AppColors.navyMuted;
  static const Color headerSurface = Color(0xFF1A1A1A);
  static const Color bodyBg = AppColors.background;
  static const Color flashDealsBg = AppColors.accentMuted;
  static const Color categoryCardBg = AppColors.surfaceMuted;

  // ── Light home tokens ──
  /// خلفية الهيدر الفاتح — نفس خلفية الصفحة لدمج سلس.
  static const Color headerBg = bodyBg;
  static const Color searchFieldBg = AppColors.surface;
  static const Color openBadgeBg = AppColors.success;
  static const Color verifiedBlue = AppColors.info;
  static const Color navActivePill = AppColors.navy;
  static const Color navInactive = Color(0xFF9AA3AF);
  static const Color offersHalo = Color(0xFFF8F1DE);

  static List<BoxShadow> get lightCardShadow => [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get navShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, -6),
    ),
  ];

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), navy],
  );

  /// Soft gold tint — featured / trending sections.
  static const Color sectionWarmBg = Color(0xFFF8F1DE);

  /// Pure white — store listing sections.
  static const Color sectionWhiteBg = Color(0xFFFFFFFF);
}

/// Layout metrics for the floating home shell.
abstract final class MatlobHomeLayout {
  static const double heroTopInset = 6;

  /// صفّ الترحيب — سطران (تحية + اسم) بجوار الجرس والموقع.
  static const double heroTopBarH = 46;
  static const double heroBeforeSearchGap = 12;
  static const double heroSearchH = 50;
  static const double heroBottomPad = 12;
  static const double heroLayoutSlack = 12;

  /// الهيدر مثبّت بارتفاع ثابت — منطقة الترحيب جزء من الهوية ولا تُقص
  /// عند التمرير.
  static double _heroContentHeight({required bool collapsed}) {
    return heroTopInset +
        heroTopBarH +
        heroBeforeSearchGap +
        heroSearchH +
        heroBottomPad +
        heroLayoutSlack;
  }

  static double heroExpandedHeight(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return top + _heroContentHeight(collapsed: false);
  }

  static double heroCollapsedHeight(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return top + _heroContentHeight(collapsed: true);
  }

  @Deprecated('Use heroExpandedHeight')
  static double heroExtent(BuildContext context) => heroExpandedHeight(context);

  static double scrollBottomInset(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return 80 + bottom;
  }

  static const double heroToContentGap = 18;
}

/// Hero header: profile, location, notifications, greeting, search.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.governorate,
    required this.onNotificationTap,
    required this.onSearchTap,
    this.onLocationTap,
    this.locationLabel,
    this.onProfileTap,
    this.onFilterTap,
    this.notificationCount = 0,
    this.userName,
    this.isGuest = true,
    this.welcomeMessage,
    this.searchHint,
    this.ordersCount = 0,
    this.collapseT = 0,
    this.useSafeTopInset = true,
  });

  final Governorate governorate;
  final VoidCallback? onLocationTap;
  final String? locationLabel;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFilterTap;
  final int notificationCount;
  final String? userName;
  final bool isGuest;
  final String? welcomeMessage;
  final String? searchHint;
  final int ordersCount;
  final double collapseT;
  final bool useSafeTopInset;

  /// تحية بحسب وقت اليوم — عنصر هوية وليس عرض بيانات حساب.
  static String timeGreeting(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 12) return 'صباح الخير ☀️';
    if (h >= 12 && h < 17) return 'مساء الخير 🌤️';
    return 'مساء الخير 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final name = userName ?? 'ضيف';
    final t = collapseT.clamp(0.0, 1.0);
    final iconSize = 40 - t * 5;
    final topPad = top + MatlobHomeLayout.heroTopInset;
    final bottomPad = MatlobHomeLayout.heroBottomPad;

    final greeting = CmsTextService.instance.timeGreeting(
      DateTime.now(),
      city: governorate.name,
    );
    final headline = isGuest
        ? (welcomeMessage ?? CmsTextService.instance.guestHeadline())
        : name;

    return Container(
      width: double.infinity,
      color: MatlobHomeColors.headerBg,
      padding: EdgeInsets.fromLTRB(
        HomeTheme.pageHorizontal,
        topPad,
        HomeTheme.pageHorizontal,
        bottomPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: MatlobHomeLayout.heroTopBarH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Semantics(
                    button: onProfileTap != null,
                    label: '$greeting $headline',
                    child: GestureDetector(
                      onTap: onProfileTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.15,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeTypography.style(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _HeaderCircleButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: onNotificationTap,
                  badge: notificationCount,
                  size: iconSize,
                ),
                if (onLocationTap != null) ...[
                  const SizedBox(width: 8),
                  _LocationPill(
                    governorateName: locationLabel ?? governorate.name,
                    onTap: onLocationTap,
                    compact: t > 0.25,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: MatlobHomeLayout.heroBeforeSearchGap),
          SizedBox(
            height: MatlobHomeLayout.heroSearchH,
            child: MatlobHomeSearchBar(
              onSearchTap: onSearchTap,
              onFilterTap: onFilterTap,
              hintText: searchHint,
              compact: t > 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search row inside the hero.
class MatlobHomeSearchBar extends StatelessWidget {
  const MatlobHomeSearchBar({
    super.key,
    required this.onSearchTap,
    this.onFilterTap,
    this.hintText,
    this.compact = false,
  });

  final VoidCallback onSearchTap;
  final VoidCallback? onFilterTap;
  final String? hintText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fieldHeight = MatlobHomeLayout.heroSearchH;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: hintText ?? 'ابحث',
            child: MatlobPressableScale(
              onTap: onSearchTap,
              child: SizedBox(
                height: fieldHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: MatlobHomeColors.searchFieldBg,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      height: fieldHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.navy.withValues(alpha: 0.08),
                        ),
                      ),
                      padding: const EdgeInsetsDirectional.only(
                        start: 16,
                        end: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _RotatingHomeSearchPlaceholder(
                              hintText: hintText,
                              compact: compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.search_rounded,
                            size: compact ? 22 : 24,
                            color: AppColors.navy.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'تصفية النتائج',
            child: MatlobPressableScale(
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterTap!();
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: fieldHeight,
                    height: fieldHeight,
                    child: Icon(
                      Icons.tune_rounded,
                      size: compact ? 18 : 20,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RotatingHomeSearchPlaceholder extends StatefulWidget {
  const _RotatingHomeSearchPlaceholder({this.hintText, required this.compact});

  final String? hintText;
  final bool compact;

  @override
  State<_RotatingHomeSearchPlaceholder> createState() =>
      _RotatingHomeSearchPlaceholderState();
}

class _RotatingHomeSearchPlaceholderState
    extends State<_RotatingHomeSearchPlaceholder> {
  static const _interval = Duration(seconds: 2);
  static const _fadeDuration = Duration(milliseconds: 250);

  Timer? _timer;
  int _index = 0;
  List<String> _hints = CmsTextService.instance.homeSearchHints();

  @override
  void initState() {
    super.initState();
    CmsTextService.instance.addListener(_onCmsChanged);
    _restartTimer();
  }

  void _onCmsChanged() {
    final next = CmsTextService.instance.homeSearchHints();
    if (listEquals(next, _hints)) return;
    setState(() {
      _hints = next;
      _index = 0;
    });
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_hints.length <= 1) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _hints.length;
      });
    });
  }

  @override
  void dispose() {
    CmsTextService.instance.removeListener(_onCmsChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hints = _hints;
    final fallback =
        widget.hintText ?? CmsTextService.instance.homeSearchHint();
    final text = hints.isEmpty ? fallback : hints[_index % hints.length];
    final fontSize = widget.compact ? 13.0 : 14.5;

    return AnimatedSwitcher(
      duration: _fadeDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        text,
        key: ValueKey<String>(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: HomeTypography.style(
          fontSize: fontSize,
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Collapsing hero sliver — shrinks while scrolling.
class MatlobHomeHeroDelegate extends SliverPersistentHeaderDelegate {
  MatlobHomeHeroDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.governorate,
    required this.onNotificationTap,
    required this.onSearchTap,
    this.onLocationTap,
    this.locationLabel,
    this.onProfileTap,
    this.onFilterTap,
    this.notificationCount = 0,
    this.userName,
    this.isGuest = true,
    this.welcomeMessage,
    this.searchHint,
    this.ordersCount = 0,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final Governorate governorate;
  final VoidCallback? onLocationTap;
  final String? locationLabel;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFilterTap;
  final int notificationCount;
  final String? userName;
  final bool isGuest;
  final String? welcomeMessage;
  final String? searchHint;
  final int ordersCount;

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent =>
      collapsedHeight <= expandedHeight ? collapsedHeight : expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final t = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 0.0;
    final height = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    return DecoratedBox(
      decoration: const BoxDecoration(color: MatlobHomeColors.headerBg),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: HomeHero(
              governorate: governorate,
              locationLabel: locationLabel,
              onLocationTap: onLocationTap,
              onNotificationTap: onNotificationTap,
              onSearchTap: onSearchTap,
              onProfileTap: onProfileTap,
              onFilterTap: onFilterTap,
              notificationCount: notificationCount,
              userName: userName,
              isGuest: isGuest,
              welcomeMessage: welcomeMessage,
              searchHint: searchHint,
              ordersCount: ordersCount,
              collapseT: t,
              useSafeTopInset: false,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant MatlobHomeHeroDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        governorate != oldDelegate.governorate ||
        locationLabel != oldDelegate.locationLabel ||
        notificationCount != oldDelegate.notificationCount ||
        userName != oldDelegate.userName ||
        isGuest != oldDelegate.isGuest ||
        welcomeMessage != oldDelegate.welcomeMessage ||
        searchHint != oldDelegate.searchHint ||
        ordersCount != oldDelegate.ordersCount;
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.governorateName,
    this.onTap,
    this.compact = false,
  });

  final String governorateName;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    return Semantics(
      button: interactive,
      label: interactive
          ? 'تغيير الموقع: $governorateName'
          : 'موقعك الحالي: $governorateName',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEDEFF2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: compact ? 14 : 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 128),
                  child: Text(
                    governorateName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeTypography.style(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
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

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.5;
    return Semantics(
      button: true,
      label: badge > 0 ? 'الإشعارات — $badge غير مقروء' : 'الإشعارات',
      child: Material(
        color: AppColors.white,
        shape: CircleBorder(side: const BorderSide(color: Color(0xFFEDEFF2))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.navy, size: iconSize),
                if (badge > 0)
                  PositionedDirectional(
                    top: size * 0.18,
                    end: size * 0.2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
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
