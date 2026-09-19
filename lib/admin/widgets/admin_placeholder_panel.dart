import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/models/admin_section.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

class AdminPlaceholderPanel extends StatelessWidget {
  const AdminPlaceholderPanel({super.key, required this.section});

  final AdminSection section;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(section.icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              section.title,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هذا القسم قيد التطوير — سيُضاف التحكم الكامل قريباً.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
