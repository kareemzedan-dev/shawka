import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_stat_card.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/job_queue_entry.dart';
import 'package:matlobgo/services/job_queue_service.dart';

String _jobStatusLabel(JobStatus s) => switch (s) {
      JobStatus.pending => 'انتظار',
      JobStatus.processing => 'معالجة',
      JobStatus.completed => 'مكتمل',
      JobStatus.failed => 'فشل',
    };

class AdminJobQueuePanel extends StatefulWidget {
  const AdminJobQueuePanel({super.key});

  @override
  State<AdminJobQueuePanel> createState() => _AdminJobQueuePanelState();
}

class _AdminJobQueuePanelState extends State<AdminJobQueuePanel> {
  JobStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminPanelHeader(
          title: 'طابور المهام',
          subtitle:
              'مراقبة المهام الخلفية — تُعالَج كل دقيقة عبر Cloud Functions',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              ...JobStatus.values.map(
                (s) => _FilterChip(
                  label: _jobStatusLabel(s),
                  selected: _filter == s,
                  onTap: () => setState(() => _filter = s),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<JobQueueEntry>>(
            stream: JobQueueService.instance.watchRecent(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
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

              final all = snapshot.data ?? [];
              final filtered = _filter == null
                  ? all
                  : all.where((j) => j.status == _filter).toList();

              final pending =
                  all.where((j) => j.status == JobStatus.pending).length;
              final processing =
                  all.where((j) => j.status == JobStatus.processing).length;
              final failed =
                  all.where((j) => j.status == JobStatus.failed).length;
              final completed =
                  all.where((j) => j.status == JobStatus.completed).length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminStatCard(
                          label: 'قيد الانتظار',
                          value: '$pending',
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminStatCard(
                          label: 'قيد المعالجة',
                          value: '$processing',
                          icon: Icons.sync_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminStatCard(
                          label: 'فشل',
                          value: '$failed',
                          icon: Icons.error_outline_rounded,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminStatCard(
                          label: 'مكتمل',
                          value: '$completed',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (filtered.isEmpty)
                    AdminEmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'لا توجد مهام في هذا الفلتر',
                    )
                  else
                    ...filtered.map((job) => _JobTile(job: job)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final JobQueueEntry job;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (job.status) {
      JobStatus.pending => AppColors.warning,
      JobStatus.processing => AppColors.primary,
      JobStatus.completed => AppColors.success,
      JobStatus.failed => AppColors.error,
    };

    final typeLabel = switch (job.type) {
      JobType.analyticsBatch => 'دفعة تحليلات',
      JobType.catalogWarmup => 'تسخين كتالوج',
      JobType.pushRetry => 'إعادة Push',
      JobType.reportExport => 'تصدير تقرير',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _jobStatusLabel(job.status),
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '#${job.id.length > 8 ? job.id.substring(0, 8) : job.id}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'أولوية: ${job.priority.name} · محاولات: ${job.attempts}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'أُنشئ ${AdminFormat.relative(job.createdAt)}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            if (job.completedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'اكتمل ${AdminFormat.relative(job.completedAt!)}',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
            if (job.error != null && job.error!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                job.error!.trim(),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.error,
                  height: 1.35,
                ),
              ),
            ],
            if (job.payload.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                job.payload.entries
                    .take(4)
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' · '),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
