import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/audit_diff.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/repositories/app_settings_repository.dart';

/// CMS للتنبيهات وبانر الصيانة — يظهر فوراً في تطبيق العميل.
class AdminAlertsPanel extends StatefulWidget {
  const AdminAlertsPanel({super.key});

  @override
  State<AdminAlertsPanel> createState() => _AdminAlertsPanelState();
}

class _AdminAlertsPanelState extends State<AdminAlertsPanel> {
  final _repo = AppSettingsRepository();
  final _formKey = GlobalKey<FormState>();
  final _maintenanceTitle = TextEditingController();
  final _maintenanceMessage = TextEditingController();
  final _alertTitle = TextEditingController();
  final _alertMessage = TextEditingController();
  final _alertActionUrl = TextEditingController();
  bool _maintenanceMode = false;
  bool _alertEnabled = false;
  AppBannerSeverity _alertSeverity = AppBannerSeverity.warning;
  AppSettings? _before;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _maintenanceTitle.dispose();
    _maintenanceMessage.dispose();
    _alertTitle.dispose();
    _alertMessage.dispose();
    _alertActionUrl.dispose();
    super.dispose();
  }

  void _apply(AppSettings s) {
    _before = s;
    _maintenanceMode = s.maintenanceMode;
    _maintenanceTitle.text = s.maintenanceTitle;
    _maintenanceMessage.text = s.maintenanceMessage;
    _alertEnabled = s.alertBannerEnabled;
    _alertTitle.text = s.alertBannerTitle;
    _alertMessage.text = s.alertBannerMessage;
    _alertActionUrl.text = s.alertBannerActionUrl;
    _alertSeverity = s.alertBannerSeverity;
    _loaded = true;
  }

  AppSettings _build() {
    final prev = _before ?? const AppSettings();
    return prev.copyWith(
      maintenanceMode: _maintenanceMode,
      maintenanceTitle: _maintenanceTitle.text.trim(),
      maintenanceMessage: _maintenanceMessage.text.trim(),
      alertBannerEnabled: _alertEnabled,
      alertBannerTitle: _alertTitle.text.trim(),
      alertBannerMessage: _alertMessage.text.trim(),
      alertBannerSeverity: _alertSeverity,
      alertBannerActionUrl: _alertActionUrl.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final next = _build();
      await _repo.save(next);
      await AdminSession.instance.recordWithDiff(
        action: AuditAction.update,
        entityType: 'app_alerts',
        entityId: AppSettings.documentId,
        summary: 'تحديث تنبيهات وبانر الصيانة',
        before: _before != null
            ? AuditDiff.snapshot(_before!.toFirestore())
            : null,
        after: AuditDiff.snapshot(next.toFirestore()),
      );
      _before = next;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التنبيهات — تظهر فوراً في التطبيق')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppSettings>(
      stream: _repo.watch(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_loaded) {
          _apply(snapshot.data!);
        }
        if (snapshot.connectionState == ConnectionState.waiting && !_loaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final preview = _build();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPanelHeader(
                title: 'التنبيهات والبانر',
                subtitle:
                    'CMS — صيانة التطبيق وبانر تنبيه عام يظهر في الصفحة الرئيسية',
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _section('وضع الصيانة'),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'تفعيل وضع الصيانة',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'يوقف الطلبات ويعرض بانر أحمر في التطبيق',
                                    style: GoogleFonts.cairo(fontSize: 12),
                                  ),
                                  value: _maintenanceMode,
                                  onChanged: (v) =>
                                      setState(() => _maintenanceMode = v),
                                ),
                                PremiumInputField(
                                  controller: _maintenanceTitle,
                                  label: 'عنوان بانر الصيانة',
                                ),
                                PremiumInputField(
                                  controller: _maintenanceMessage,
                                  label: 'نص بانر الصيانة',
                                ),
                                const SizedBox(height: 24),
                                _section('بانر تنبيه عام'),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'عرض بانر التنبيه',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  value: _alertEnabled,
                                  onChanged: (v) =>
                                      setState(() => _alertEnabled = v),
                                ),
                                PremiumInputField(
                                  controller: _alertTitle,
                                  label: 'عنوان التنبيه (اختياري)',
                                ),
                                PremiumInputField(
                                  controller: _alertMessage,
                                  label: 'نص التنبيه',
                                ),
                                PremiumInputField(
                                  controller: _alertActionUrl,
                                  label: 'رابط إجراء (اختياري)',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'درجة الأهمية',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<AppBannerSeverity>(
                                  segments: const [
                                    ButtonSegment(
                                      value: AppBannerSeverity.error,
                                      label: Text('حرج'),
                                      icon: Icon(Icons.error_outline),
                                    ),
                                    ButtonSegment(
                                      value: AppBannerSeverity.warning,
                                      label: Text('تحذير'),
                                      icon: Icon(Icons.warning_amber_outlined),
                                    ),
                                    ButtonSegment(
                                      value: AppBannerSeverity.info,
                                      label: Text('معلومة'),
                                      icon: Icon(Icons.info_outline),
                                    ),
                                  ],
                                  selected: {_alertSeverity},
                                  onSelectionChanged: (s) => setState(
                                    () => _alertSeverity = s.first,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                FilledButton(
                                  onPressed: _saving ? null : _save,
                                  child: _saving
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'حفظ ونشر',
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Card(
                        color: AppColors.background,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'معاينة التطبيق',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (preview.maintenanceMode)
                                _PreviewBanner(
                                  settings: preview,
                                  maintenance: true,
                                ),
                              if (preview.hasActiveAlertBanner) ...[
                                if (preview.maintenanceMode)
                                  const SizedBox(height: 10),
                                _PreviewBanner(
                                  settings: preview,
                                  maintenance: false,
                                ),
                              ],
                              if (!preview.maintenanceMode &&
                                  !preview.hasActiveAlertBanner)
                                Text(
                                  'لا يوجد بانر نشط حالياً.',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({
    required this.settings,
    required this.maintenance,
  });

  final AppSettings settings;
  final bool maintenance;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = maintenance
        ? (AppColors.error.withValues(alpha: 0.12), AppColors.error,
            Icons.build_circle_outlined)
        : switch (settings.alertBannerSeverity) {
            AppBannerSeverity.error => (
                AppColors.error.withValues(alpha: 0.12),
                AppColors.error,
                Icons.error_outline,
              ),
            AppBannerSeverity.info => (
                AppColors.navy.withValues(alpha: 0.08),
                AppColors.navy,
                Icons.info_outline,
              ),
            AppBannerSeverity.warning => (
                AppColors.warning.withValues(alpha: 0.12),
                AppColors.warning,
                Icons.campaign_outlined,
              ),
          };

    final title = maintenance
        ? settings.effectiveMaintenanceTitle
        : settings.alertBannerTitle.trim();
    final body = maintenance
        ? settings.effectiveMaintenanceMessage
        : settings.alertBannerMessage.trim();

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: fg,
                      ),
                    ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
