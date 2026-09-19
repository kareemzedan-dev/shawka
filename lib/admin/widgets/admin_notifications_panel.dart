import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_activity_type_multi_select.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_user_multi_picker.dart';
import 'package:matlobgo/admin/widgets/push_campaign_stats_row.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/push_campaign.dart';
import 'package:matlobgo/models/push_deep_link.dart';
import 'package:matlobgo/repositories/push_campaign_repository.dart';

enum _SendMode { now, schedule }

class AdminNotificationsPanel extends StatefulWidget {
  const AdminNotificationsPanel({super.key, this.actorName = 'Admin'});

  final String actorName;

  @override
  State<AdminNotificationsPanel> createState() =>
      _AdminNotificationsPanelState();
}

class _AdminNotificationsPanelState extends State<AdminNotificationsPanel> {
  final _repo = PushCampaignRepository();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _deepLinkIdCtrl = TextEditingController();
  PushCampaignTarget _target = PushCampaignTarget.allUsers;
  PushDeepLinkRoute _deepLinkRoute = PushDeepLinkRoute.home;
  List<AppUser> _selectedUsers = [];
  final Set<String> _selectedActivityTypeIds = {};
  String _governorate = 'القاهرة';
  _SendMode _sendMode = _SendMode.now;
  DateTime? _scheduledAt;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _deepLinkIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickUsers() async {
    final picked = await showAdminUserMultiPicker(
      context,
      initial: _selectedUsers,
    );
    if (picked != null) setState(() => _selectedUsers = picked);
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'تاريخ الإرسال',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt ?? now.add(const Duration(hours: 1)),
      ),
      helpText: 'وقت الإرسال',
    );
    if (time == null || !mounted) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now.add(const Duration(minutes: 1)))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'اختر وقتاً في المستقبل',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
      return;
    }
    setState(() => _scheduledAt = scheduled);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      return;
    }
    if (_sendMode == _SendMode.schedule && _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدد موعد الجدولة أولاً', style: GoogleFonts.cairo()),
        ),
      );
      return;
    }
    if (_target == PushCampaignTarget.specificUsers &&
        _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اختر عميلاً واحداً على الأقل',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }
    if ((_deepLinkRoute == PushDeepLinkRoute.store ||
            _deepLinkRoute == PushDeepLinkRoute.order) &&
        _deepLinkIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أدخل معرف المتجر أو الطلب للـ Deep Link',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final isScheduled = _sendMode == _SendMode.schedule;
      final campaignId = await _repo.create(
        PushCampaign(
          id: '',
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          target: _target,
          status: isScheduled
              ? PushCampaignStatus.scheduled
              : PushCampaignStatus.sent,
          governorate:
              _target == PushCampaignTarget.governorate ? _governorate : '',
          targetUserIds: _selectedUsers.map((u) => u.uid).toList(),
          targetUserLabels: _selectedUsers
              .map((u) => u.name.isEmpty ? u.email : u.name)
              .toList(),
          activityTypeIds: _selectedActivityTypeIds.toList(),
          deepLinkRoute: _deepLinkRoute,
          deepLinkId: _deepLinkIdCtrl.text.trim(),
          scheduledAt: isScheduled ? _scheduledAt : null,
          createdAt: DateTime.now(),
          createdByName: widget.actorName,
        ),
      );

      await AdminSession.instance.record(
        action: AuditAction.create,
        entityType: 'push_campaign',
        entityId: campaignId,
        summary: isScheduled
            ? 'جدولة حملة إشعار: ${_titleCtrl.text.trim()}'
            : 'إرسال حملة إشعار: ${_titleCtrl.text.trim()}',
        metadata: isScheduled && _scheduledAt != null
            ? {'scheduledAt': _scheduledAt!.toIso8601String()}
            : null,
      );

      _titleCtrl.clear();
      _bodyCtrl.clear();
      _deepLinkIdCtrl.clear();
      setState(() {
        _scheduledAt = null;
        _sendMode = _SendMode.now;
        _selectedUsers = [];
        _selectedActivityTypeIds.clear();
        _deepLinkRoute = PushDeepLinkRoute.home;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isScheduled
                  ? 'تمت جدولة الحملة — سيتم الإرسال تلقائياً عند الموعد'
                  : 'تم حفظ الحملة — سيتم الإرسال عبر Cloud Function',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirestoreErrorMessage.from(e),
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelCampaign(PushCampaign campaign) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إلغاء الحملة؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '«${campaign.title}» لن تُرسل.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تراجع', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('إلغاء الحملة', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.cancel(campaign.id);
    await AdminSession.instance.record(
      action: AuditAction.statusChange,
      entityType: 'push_campaign',
      entityId: campaign.id,
      summary: 'إلغاء حملة إشعار: ${campaign.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 380,
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'إرسال إشعار',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'العنوان',
                        labelStyle: GoogleFonts.cairo(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'النص',
                        labelStyle: GoogleFonts.cairo(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PushCampaignTarget>(
                      initialValue: _target,
                      decoration: InputDecoration(
                        labelText: 'الجمهور',
                        labelStyle: GoogleFonts.cairo(),
                      ),
                      items: [
                        for (final t in PushCampaignTarget.values)
                          DropdownMenuItem(value: t, child: Text(t.label)),
                      ],
                      onChanged: (v) => setState(() => _target = v ?? _target),
                    ),
                    if (_target == PushCampaignTarget.governorate) ...[
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'المحافظة',
                        ),
                        onChanged: (v) => _governorate = v.trim(),
                      ),
                    ],
                    if (_target == PushCampaignTarget.specificUsers) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickUsers,
                        icon: const Icon(Icons.group_add_outlined),
                        label: Text(
                          _selectedUsers.isEmpty
                              ? 'اختر العملاء'
                              : '${_selectedUsers.length} عميل محدّد',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AdminActivityTypeMultiSelect(
                      selectedIds: _selectedActivityTypeIds,
                      helperText:
                          'اختياري — قيّد الإرسال لنشاط أو أكثر فوق فلتر الجمهور',
                      onChanged: (ids) => setState(() {
                        _selectedActivityTypeIds
                          ..clear()
                          ..addAll(ids);
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PushDeepLinkRoute>(
                      initialValue: _deepLinkRoute,
                      decoration: InputDecoration(
                        labelText: 'Deep Link — عند النقر',
                        labelStyle: GoogleFonts.cairo(),
                      ),
                      items: [
                        for (final r in PushDeepLinkRoute.values)
                          DropdownMenuItem(value: r, child: Text(r.label)),
                      ],
                      onChanged: (v) =>
                          setState(() => _deepLinkRoute = v ?? _deepLinkRoute),
                    ),
                    if (_deepLinkRoute == PushDeepLinkRoute.store ||
                        _deepLinkRoute == PushDeepLinkRoute.order) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _deepLinkIdCtrl,
                        decoration: InputDecoration(
                          labelText: _deepLinkRoute == PushDeepLinkRoute.store
                              ? 'معرف المتجر (storeId)'
                              : 'معرف الطلب (orderId)',
                          labelStyle: GoogleFonts.cairo(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SegmentedButton<_SendMode>(
                      segments: [
                        ButtonSegment(
                          value: _SendMode.now,
                          label: Text('فوري', style: GoogleFonts.cairo()),
                          icon: const Icon(Icons.send_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: _SendMode.schedule,
                          label: Text('جدولة', style: GoogleFonts.cairo()),
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                        ),
                      ],
                      selected: {_sendMode},
                      onSelectionChanged: (values) {
                        setState(() => _sendMode = values.first);
                      },
                    ),
                    if (_sendMode == _SendMode.schedule) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickSchedule,
                        icon: const Icon(Icons.event_rounded),
                        label: Text(
                          _scheduledAt == null
                              ? 'اختر الموعد'
                              : AdminFormat.dateTime(_scheduledAt!),
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _sendMode == _SendMode.schedule
                                  ? Icons.schedule_send_rounded
                                  : Icons.send_rounded,
                            ),
                      label: Text(
                        _sendMode == _SendMode.schedule
                            ? 'حفظ وجدولة'
                            : 'حفظ وإرسال',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPanelHeader(
                title: 'مركز الإشعارات',
                subtitle:
                    'Push — استهداف · Deep Links · إحصائيات التسليم',
              ),
              Expanded(
                child: StreamBuilder<List<PushCampaign>>(
                  stream: _repo.watchAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          FirestoreErrorMessage.from(snapshot.error!),
                          style: GoogleFonts.cairo(color: AppColors.error),
                        ),
                      );
                    }
                    final campaigns = snapshot.data ?? [];
                    if (campaigns.isEmpty) {
                      return const AdminEmptyState(
                        icon: Icons.notifications_active_outlined,
                        message: 'لا توجد حملات إشعارات بعد.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 0, 24, 24),
                      itemCount: campaigns.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = campaigns[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      c.status == PushCampaignStatus.scheduled
                                          ? Icons.schedule_rounded
                                          : Icons.notifications_rounded,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.title,
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            '${c.target.label} · ${c.status.label}'
                                            '${c.targetUserIds.isNotEmpty ? ' · ${c.targetUserIds.length} عميل' : ''}'
                                            '${c.deepLinkRoute != PushDeepLinkRoute.none ? '\nDeep Link: ${c.deepLinkRoute.label}' : ''}'
                                            '${c.scheduledAt != null ? '\nموعد: ${AdminFormat.dateTime(c.scheduledAt!)}' : ''}'
                                            '\n${c.body}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AdminFormat.relative(c.createdAt),
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                        if (c.status ==
                                            PushCampaignStatus.scheduled)
                                          TextButton(
                                            onPressed: () =>
                                                _cancelCampaign(c),
                                            child: Text(
                                              'إلغاء',
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                PushCampaignStatsRow(campaign: c),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
