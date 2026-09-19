import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/cms_text_entry.dart';
import 'package:matlobgo/repositories/cms_text_repository.dart';

class AdminCmsTextsPanel extends StatefulWidget {
  const AdminCmsTextsPanel({super.key});

  @override
  State<AdminCmsTextsPanel> createState() => _AdminCmsTextsPanelState();
}

class _AdminCmsTextsPanelState extends State<AdminCmsTextsPanel> {
  final _repo = CmsTextRepository();
  final _controllers = <String, TextEditingController>{};
  final _savingKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _repo.seedDefaultsIfEmpty();
    _repo.ensureDefaultKeys();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(CmsTextEntry entry) {
    return _controllers.putIfAbsent(
      entry.key,
      () => TextEditingController(text: entry.value),
    );
  }

  Future<void> _save(CmsTextEntry entry) async {
    final controller = _controllerFor(entry);
    final value = controller.text.trim();
    if (value == entry.value.trim()) return;

    setState(() => _savingKeys.add(entry.key));
    try {
      final updated = CmsTextEntry(
        id: entry.id,
        key: entry.key,
        label: entry.label,
        value: value,
        updatedAt: DateTime.now(),
      );
      await _repo.upsert(updated);
      await AdminAuditRecord.firestoreEntity(
        action: AuditAction.update,
        entityType: 'cms_text',
        entityId: entry.key,
        summary: 'تعديل نص CMS: ${entry.label}',
        beforeFirestore: {
          'key': entry.key,
          'label': entry.label,
          'value': entry.value,
        },
        afterFirestore: {
          'key': entry.key,
          'label': entry.label,
          'value': value,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم الحفظ — يظهر فوراً في التطبيق',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingKeys.remove(entry.key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminPanelHeader(
          title: 'نصوص التطبيق',
          subtitle:
              'CMS — التعديل يظهر فوراً في التطبيق · تلميح البحث: افصل بـ |',
        ),
        Expanded(
          child: StreamBuilder<List<CmsTextEntry>>(
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
              final entries = snapshot.data ?? [];
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  final controller = _controllerFor(entry);
                  final saving = _savingKeys.contains(entry.key);
                  final dirty =
                      controller.text.trim() != entry.value.trim();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.label,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                entry.key,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'آخر تحديث ${AdminFormat.relative(entry.updatedAt)}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: controller,
                            maxLines: 2,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (dirty || saving) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: FilledButton.icon(
                                onPressed:
                                    saving ? null : () => _save(entry),
                                icon: saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined,
                                        size: 18),
                                label: Text(
                                  'حفظ',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
