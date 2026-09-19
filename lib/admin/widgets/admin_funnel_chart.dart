import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_funnel_calculator.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

class AdminFunnelChart extends StatelessWidget {
  const AdminFunnelChart({super.key, required this.steps});

  final List<AdminFunnelStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return Text(
        'لا توجد بيانات كافية لبناء القمع',
        style: GoogleFonts.cairo(color: AppColors.textSecondary),
      );
    }

    final maxUsers =
        steps.map((s) => s.uniqueUsers).fold(1, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _FunnelBar(step: steps[i], maxUsers: maxUsers),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'انقطاع ${(steps[i + 1].dropOffRate * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _FunnelBar extends StatelessWidget {
  const _FunnelBar({required this.step, required this.maxUsers});

  final AdminFunnelStep step;
  final int maxUsers;

  @override
  Widget build(BuildContext context) {
    final widthFactor = step.uniqueUsers / maxUsers;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            step.label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * widthFactor.clamp(0.08, 1.0);
              return Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: barWidth,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${step.uniqueUsers}',
                      style: GoogleFonts.cairo(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${step.count}',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
