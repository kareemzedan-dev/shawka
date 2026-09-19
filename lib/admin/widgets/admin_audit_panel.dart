import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_csv_export.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/utils/audit_diff.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/repositories/audit_log_repository.dart';

class AdminAuditPanel extends StatefulWidget {
  const AdminAuditPanel({super.key});

  @override
  State<AdminAuditPanel> createState() => _AdminAuditPanelState();
}

class _AdminAuditPanelState extends State<AdminAuditPanel> {
  final _repo = AuditLogRepository();
  final _search = TextEditingController();
  AuditAction? _actionFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AuditLog> _filter(List<AuditLog> logs) {
    final q = _search.text.trim().toLowerCase();
    return logs.where((log) {
      if (_actionFilter != null && log.action != _actionFilter) return false;
      if (q.isEmpty) return true;
      final hay = [
        log.summary,
        log.actorName,
        log.entityType,
        log.entityId,
        log.action.label,
        ...AuditDiff.fromMetadata(log.metadata).map((c) => '${c.field} ${c.before} ${c.after}'),
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _exportCsv(List<AuditLog> logs) async {
    final csv = AdminCsvExport.build(
      headers: [
        'id',
        'createdAt',
        'action',
        'entityType',
        'entityId',
        'actorName',
        'summary',
        'changesCount',
      ],
      rows: logs.map((l) {
        final changes = AuditDiff.fromMetadata(l.metadata);
        return [
          l.id,
          AdminFormat.dateTime(l.createdAt),
          l.action.label,
          l.entityType,
          l.entityId,
          l.actorName,
          l.summary,
          changes.length.toString(),
        ];
      }).toList(),
    );
    await AdminCsvExport.share(
      context,
      filename: 'audit_logs.csv',
      csv: csv,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'سجل العمليات',
          subtitle: 'Audit — بحث، فلترة، ومقارنة قبل/بعد لكل تعديل',
          trailing: StreamBuilder<List<AuditLog>>(
            stream: _repo.watchRecent(limit: 300),
            builder: (context, snap) {
              final logs = _filter(snap.data ?? []);
              return OutlinedButton.icon(
                onPressed: logs.isEmpty ? null : () => _exportCsv(logs),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('CSV', style: GoogleFonts.cairo()),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'بحث: ملخص، مستخدم، كيان، حقل…',
                    hintStyle: GoogleFonts.cairo(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<AuditAction?>(
                value: _actionFilter,
                hint: Text('الإجراء', style: GoogleFonts.cairo(fontSize: 13)),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('الكل', style: GoogleFonts.cairo()),
                  ),
                  ...AuditAction.values.map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a.label, style: GoogleFonts.cairo()),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _actionFilter = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AuditLog>>(
            stream: _repo.watchRecent(limit: 300),
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
              final logs = _filter(snapshot.data ?? []);
              if (logs.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.history_rounded,
                  message: _search.text.isNotEmpty || _actionFilter != null
                      ? 'لا توجد نتائج للبحث الحالي.'
                      : 'لا توجد عمليات مسجّلة بعد.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: logs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _AuditLogTile(log: logs[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final changes = AuditDiff.fromMetadata(log.metadata);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.navy.withValues(alpha: 0.08),
          child: Icon(_iconFor(log.action), color: AppColors.navy, size: 18),
        ),
        title: Text(
          log.summary,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          '${log.action.label} · ${log.entityType}/${log.entityId}\n'
          '${log.actorName} · ${AdminFormat.dateTime(log.createdAt)}',
          style: GoogleFonts.cairo(
            fontSize: 11.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        children: [
          if (changes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'لا توجد تفاصيل diff — عملية قديمة أو بدون حقول متغيّرة.',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    children: [
                      _cell('الحقل', header: true),
                      _cell('قبل', header: true),
                      _cell('بعد', header: true),
                    ],
                  ),
                  ...changes.map(
                    (c) => TableRow(
                      children: [
                        _cell(c.field),
                        _cell(c.before.isEmpty ? '—' : c.before),
                        _cell(c.after.isEmpty ? '—' : c.after,
                            highlight: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool header = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SelectableText(
        text,
        style: GoogleFonts.cairo(
          fontSize: header ? 11 : 12,
          fontWeight: header ? FontWeight.w800 : FontWeight.w600,
          color: highlight ? AppColors.navy : AppColors.textPrimary,
        ),
      ),
    );
  }

  IconData _iconFor(AuditAction action) => switch (action) {
        AuditAction.create => Icons.add_circle_outline_rounded,
        AuditAction.update => Icons.edit_outlined,
        AuditAction.delete => Icons.delete_outline_rounded,
        AuditAction.statusChange => Icons.sync_alt_rounded,
        AuditAction.login => Icons.login_rounded,
        AuditAction.roleChange => Icons.admin_panel_settings_outlined,
      };
}
