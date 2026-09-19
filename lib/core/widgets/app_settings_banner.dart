import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';

/// بانر صيانة أو تنبيه CMS من app_settings.
class AppSettingsBanner extends StatelessWidget {
  const AppSettingsBanner({
    super.key,
    required this.settings,
    required this.maintenance,
  });

  final AppSettings settings;
  final bool maintenance;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = maintenance
        ? (AppColors.error.withValues(alpha: 0.1), AppColors.error,
            Icons.build_circle_outlined)
        : switch (settings.alertBannerSeverity) {
            AppBannerSeverity.error => (
                AppColors.error.withValues(alpha: 0.1),
                AppColors.error,
                Icons.error_outline,
              ),
            AppBannerSeverity.info => (
                AppColors.navy.withValues(alpha: 0.08),
                AppColors.navy,
                Icons.info_outline,
              ),
            AppBannerSeverity.warning => (
                AppColors.warning.withValues(alpha: 0.1),
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
    final actionUrl = maintenance ? '' : settings.alertBannerActionUrl.trim();

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: actionUrl.isNotEmpty
            ? () => launchUrl(Uri.parse(actionUrl),
                mode: LaunchMode.externalApplication)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: fg),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: fg,
                        ),
                      ),
                  ],
                ),
              ),
              if (actionUrl.isNotEmpty)
                Icon(Icons.open_in_new_rounded, size: 18, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
