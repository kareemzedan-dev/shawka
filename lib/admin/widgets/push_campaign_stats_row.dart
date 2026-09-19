import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/push_campaign.dart';

class PushCampaignStatsRow extends StatelessWidget {
  const PushCampaignStatsRow({super.key, required this.campaign});

  final PushCampaign campaign;

  @override
  Widget build(BuildContext context) {
    if (!campaign.hasDeliveryStats && campaign.deliveryNote.isEmpty) {
      if (campaign.status == PushCampaignStatus.scheduled) {
        return Text(
          'في انتظار الإرسال',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (campaign.deliveryNote == 'no_tokens') {
      return Text(
        '⚠️ لا توجد أجهزة مسجّلة (FCM)',
        style: GoogleFonts.cairo(
          fontSize: 11,
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final rate = (campaign.deliverySuccessRate * 100).toStringAsFixed(0);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _chip(
          Icons.check_circle_outline,
          'نجاح ${campaign.deliverySuccess}',
          AppColors.success,
        ),
        if (campaign.deliveryFailure > 0)
          _chip(
            Icons.error_outline,
            'فشل ${campaign.deliveryFailure}',
            AppColors.error,
          ),
        if (campaign.tokensTargeted > 0)
          _chip(
            Icons.devices_rounded,
            'مستهدف ${campaign.tokensTargeted}',
            AppColors.primary,
          ),
        _chip(Icons.percent_rounded, '$rate%', AppColors.navy),
        if (campaign.sentAt != null)
          Text(
            'أُرسل ${AdminFormat.relative(campaign.sentAt!)}',
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: AppColors.textHint,
            ),
          ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
