import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/services/ops_incident_repository.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

class AdminIncidentsPanel extends StatelessWidget {
  AdminIncidentsPanel({super.key});

  final _repo = OpsIncidentRepository();

  Color _severityColor(String s) => switch (s) {
        'critical' => AppColors.error,
        'error' => AppColors.error,
        'warning' => AppColors.warning,
        _ => AppColors.navy,
      };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OpsIncident>>(
      stream: _repo.watchRecent(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPanelHeader(
                title: 'مركز الأعطال',
                subtitle: 'Assignment · GPS · Cloud Functions · FCM',
              ),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                const AdminEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  message: 'لا توجد أعطال مفتوحة حالياً',
                )
              else
                ...items.map((inc) {
                  final color = _severityColor(inc.severity);
                  final open = inc.resolutionStatus == 'open';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(Icons.report_problem_rounded, color: color),
                      title: Text(
                        inc.message,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${inc.type} · ${inc.createdAt ?? ''}${inc.orderId != null ? ' · #${inc.orderId!.substring(0, 8)}' : ''}',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      trailing: open
                          ? TextButton(
                              onPressed: () => _repo.markResolved(inc.id),
                              child: Text(
                                'تم الحل',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : Text(
                              'محلول',
                              style: GoogleFonts.cairo(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
