import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/ui_polish_tokens.dart';
import 'package:matlobgo/core/widgets/app_empty_state_presets.dart';
import 'package:matlobgo/core/widgets/staggered_fade_in.dart';
import 'package:matlobgo/core/widgets/tab_page_layout.dart';
import 'package:matlobgo/models/app_notification.dart';
import 'package:matlobgo/models/push_deep_link.dart';
import 'package:matlobgo/screens/home/widgets/polish/notification_category.dart';
import 'package:matlobgo/screens/home/widgets/polish/polished_notification_card.dart';
import 'package:matlobgo/services/notification_service.dart';
import 'package:matlobgo/services/push_deep_link_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.notificationService,
  });

  final NotificationService notificationService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationUiCategory _tab = NotificationUiCategory.all;
  bool _unreadOnly = false;

  List<AppNotification> _filtered(List<AppNotification> all) {
    var list = all;
    if (_tab != NotificationUiCategory.all) {
      list = list.where((n) => categorizeNotification(n) == _tab).toList();
    }
    if (_unreadOnly) {
      list = list.where((n) => !n.isRead).toList();
    }
    return list;
  }

  Map<String, List<AppNotification>> _groupByDay(List<AppNotification> items) {
    final map = <String, List<AppNotification>>{};
    for (final n in items) {
      final key = notificationDayGroupLabel(n.createdAt);
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    // Stream هو المصدر — نكتفي بتحديث الواجهة بعد لحظة قصيرة.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() {});
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var unreadOnly = _unreadOnly;
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECF3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'تصفية الإشعارات',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: UiPolishTokens.navy,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'غير المقروء فقط',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    value: unreadOnly,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setModal(() => unreadOnly = v),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, unreadOnly),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'تطبيق',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() => _unreadOnly = result);
  }

  Future<void> _onTapNotification(AppNotification n) async {
    HapticFeedback.selectionClick();
    if (!n.isRead) {
      await widget.notificationService.markAsRead(n.id);
    }
    if (!mounted) return;
    final link = n.toPushDeepLink();
    if (link.route == PushDeepLinkRoute.none && link.id.isEmpty) return;

    // ارجع للـ Shell أولاً حتى يعمل deep link على HomeScreen.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    await PushDeepLinkService.instance.handleData({
      'deepLink': link.route.name,
      'deepLinkId': link.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.lightStatusBar,
      child: Scaffold(
        backgroundColor: UiPolishTokens.navy,
        body: ListenableBuilder(
          listenable: widget.notificationService,
          builder: (context, _) {
            final all = widget.notificationService.notifications;
            final items = _filtered(all);
            final unread = widget.notificationService.unreadCount;
            final groups = _groupByDay(items);
            final groupOrder = ['اليوم', 'أمس', 'هذا الأسبوع', 'أقدم'];

            return TabPageLayout(
              title: 'الإشعارات',
              subtitle: unread > 0
                  ? '$unread غير مقروءة'
                  : 'كل الإشعارات مقروءة',
              leading: TabIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unread',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  TabIconButton(
                    icon: _unreadOnly
                        ? Icons.filter_alt_rounded
                        : Icons.filter_list_rounded,
                    onTap: _openFilterSheet,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  if (unread > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () async {
                            await widget.notificationService.markAllAsRead();
                            HapticFeedback.lightImpact();
                          },
                          icon: const Icon(
                            Icons.done_all_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'تحديد الكل كمقروء',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  _NotificationTabs(
                    selected: _tab,
                    onSelected: (t) => setState(() => _tab = t),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? TabEmptyState(
                            kind: AppEmptyKind.notifications,
                            title: _tab == NotificationUiCategory.all &&
                                    !_unreadOnly
                                ? null
                                : 'لا إشعارات في هذا التصنيف',
                            onAction: () {
                              final nav = Navigator.of(context);
                              if (nav.canPop()) nav.pop();
                            },
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _onRefresh,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                UiPolishTokens.spaceMd,
                                8,
                                UiPolishTokens.spaceMd,
                                UiPolishTokens.spaceLg + 12,
                              ),
                              children: [
                                for (final label in groupOrder)
                                  if (groups[label]?.isNotEmpty == true) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        4,
                                        10,
                                        4,
                                        10,
                                      ),
                                      child: Text(
                                        label,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    ...List.generate(groups[label]!.length, (i) {
                                      final n = groups[label]![i];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: StaggeredFadeIn(
                                          index: i,
                                          child: PolishedNotificationCard(
                                            notification: n,
                                            onTap: () => _onTapNotification(n),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTabs extends StatelessWidget {
  const _NotificationTabs({
    required this.selected,
    required this.onSelected,
  });

  final NotificationUiCategory selected;
  final ValueChanged<NotificationUiCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: UiPolishTokens.spaceMd),
        itemCount: NotificationUiCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = NotificationUiCategory.values[index];
          final isSelected = tab == selected;
          return FilterChip(
            label: Text(
              tab.label,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(tab),
            backgroundColor: Colors.white,
            selectedColor: AppColors.primary,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }
}
