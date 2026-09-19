import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/admin_funnel_calculator.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

/// مخطط Sankey مبسّط — تدفق رحلة المستخدم بين المراحل.
class AdminJourneySankey extends StatelessWidget {
  const AdminJourneySankey({super.key, required this.flows});

  final List<AdminJourneyFlow> flows;

  @override
  Widget build(BuildContext context) {
    if (flows.isEmpty) {
      return Text(
        'لا توجد تدفقات كافية',
        style: GoogleFonts.cairo(color: AppColors.textSecondary),
      );
    }

    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _SankeyPainter(flows: flows),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sankey — تدفق التحويل',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: flows
                    .map(
                      (f) => Text(
                        '${f.fromLabel} → ${f.toLabel}: ${f.count}',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SankeyPainter extends CustomPainter {
  _SankeyPainter({required this.flows});

  final List<AdminJourneyFlow> flows;
  static const _colors = [
    AppColors.info,
    AppColors.primaryDark,
    AppColors.warning,
    AppColors.success,
    AppColors.error,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (flows.isEmpty) return;

    final nodeCount = flows.length + 1;
    final nodeWidth = 14.0;
    final gap = (size.width - nodeCount * nodeWidth) / (nodeCount - 1);

    for (var i = 0; i < flows.length; i++) {
      final flow = flows[i];
      final x1 = i * (nodeWidth + gap);
      final x2 = (i + 1) * (nodeWidth + gap) + nodeWidth;
      final midY = size.height * 0.45;
      final thickness = 8.0 + flow.widthFactor * 28;

      final path = Path()
        ..moveTo(x1 + nodeWidth, midY - thickness / 2)
        ..cubicTo(
          x1 + nodeWidth + gap * 0.4,
          midY - thickness / 2,
          x2 - gap * 0.4,
          midY - thickness / 2,
          x2,
          midY - thickness / 2,
        )
        ..lineTo(x2, midY + thickness / 2)
        ..cubicTo(
          x2 - gap * 0.4,
          midY + thickness / 2,
          x1 + nodeWidth + gap * 0.4,
          midY + thickness / 2,
          x1 + nodeWidth,
          midY + thickness / 2,
        )
        ..close();

      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    for (var i = 0; i < nodeCount; i++) {
      final x = i * (nodeWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height * 0.35, nodeWidth, size.height * 0.2),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = AppColors.navy.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SankeyPainter oldDelegate) =>
      oldDelegate.flows != flows;
}
