import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/customer_activity_type.dart';
import 'package:matlobgo/repositories/customer_activity_type_repository.dart';

class AdminActivityTypesPanel extends StatefulWidget {
  const AdminActivityTypesPanel({super.key});

  @override
  State<AdminActivityTypesPanel> createState() =>
      _AdminActivityTypesPanelState();
}

class _AdminActivityTypesPanelState extends State<AdminActivityTypesPanel> {
  final _repo = CustomerActivityTypeRepository();
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await _repo.seedDefaultsIfNeeded();
    } catch (_) {
      // يظهر الخطأ عبر الـ stream إن فشل التحميل.
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _openEditor({CustomerActivityType? existing}) async {
    final result = await showDialog<_ActivityFormResult>(
      context: context,
      builder: (ctx) => _ActivityTypeDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    try {
      if (existing == null) {
        final id = await _repo.create(
          name: result.name,
          iconKey: result.iconKey,
          isActive: result.isActive,
        );
        await AdminAuditRecord.firestoreEntity(
          action: AuditAction.create,
          entityType: 'customer_activity_type',
          entityId: id,
          summary: 'إضافة نوع نشاط: ${result.name}',
          afterFirestore: {
            'name': result.name,
            'iconKey': result.iconKey,
            'isActive': result.isActive,
          },
        );
      } else {
        final updated = existing.copyWith(
          name: result.name,
          iconKey: result.iconKey,
          isActive: result.isActive,
        );
        await _repo.upsert(updated);
        await AdminAuditRecord.firestoreEntity(
          action: AuditAction.update,
          entityType: 'customer_activity_type',
          entityId: existing.id,
          summary: 'تعديل نوع نشاط: ${result.name}',
          beforeFirestore: existing.toFirestore(),
          afterFirestore: updated.toFirestore(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null ? 'تمت الإضافة' : 'تم الحفظ',
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
    }
  }

  Future<void> _confirmDelete(CustomerActivityType type) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف نوع النشاط؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'سيتم حذف «${type.name}» من خيارات التسجيل.\n'
          'العملاء المسجّلون سابقاً بهذا النوع لن يتأثروا.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repo.delete(type.id);
      await AdminAuditRecord.firestoreEntity(
        action: AuditAction.delete,
        entityType: 'customer_activity_type',
        entityId: type.id,
        summary: 'حذف نوع نشاط: ${type.name}',
        beforeFirestore: type.toFirestore(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'أنواع نشاط العملاء',
          subtitle:
              'تظهر في شاشة التسجيل — أضف / عدّل / أخفِ / احذف كما تشاء',
          trailing: FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'نشاط جديد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_seeding)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: StreamBuilder<List<CustomerActivityType>>(
            stream: _repo.watchAll(),
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

              final types = snapshot.data ?? [];
              if (types.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.business_center_outlined,
                  message:
                      'لا توجد أنواع نشاط.\nاضغط «نشاط جديد» أو انتظر زرع الافتراضيات.',
                );
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                itemCount: types.length,
                onReorder: (oldIndex, newIndex) async {
                  final ordered = List<CustomerActivityType>.from(types);
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = ordered.removeAt(oldIndex);
                  ordered.insert(newIndex, item);
                  try {
                    await _repo.batchUpdateSortOrder(ordered);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(FirestoreErrorMessage.from(e))),
                      );
                    }
                  }
                },
                itemBuilder: (context, index) {
                  final type = types[index];
                  return Card(
                    key: ValueKey(type.id),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(type.icon, color: AppColors.primaryDark),
                      ),
                      title: Text(
                        type.name,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        type.isActive ? 'ظاهر للعملاء' : 'مخفي',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: type.isActive
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: type.isActive,
                            onChanged: (v) async {
                              try {
                                await _repo.setActive(type.id, v);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(FirestoreErrorMessage.from(e)),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _openEditor(existing: type),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            onPressed: () => _confirmDelete(type),
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                          const Icon(Icons.drag_handle_rounded),
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

class _ActivityFormResult {
  const _ActivityFormResult({
    required this.name,
    required this.iconKey,
    required this.isActive,
  });

  final String name;
  final String iconKey;
  final bool isActive;
}

class _ActivityTypeDialog extends StatefulWidget {
  const _ActivityTypeDialog({this.existing});

  final CustomerActivityType? existing;

  @override
  State<_ActivityTypeDialog> createState() => _ActivityTypeDialogState();
}

class _ActivityTypeDialogState extends State<_ActivityTypeDialog> {
  late final TextEditingController _nameCtrl;
  late String _iconKey;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _iconKey = e?.iconKey ?? 'store';
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'نشاط جديد' : 'تعديل النشاط',
        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم النشاط',
                hintText: 'مثال: كافيه',
                labelStyle: GoogleFonts.cairo(),
                hintStyle: GoogleFonts.cairo(),
              ),
              style: GoogleFonts.cairo(),
            ),
            const SizedBox(height: 16),
            Text(
              'الأيقونة',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (key, label) in kActivityTypeIconOptions)
                  ChoiceChip(
                    avatar: Icon(activityTypeIcon(key), size: 18),
                    label: Text(label, style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _iconKey == key,
                    onSelected: (_) => setState(() => _iconKey = key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('ظاهر للعملاء', style: GoogleFonts.cairo()),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _ActivityFormResult(
                name: name,
                iconKey: _iconKey,
                isActive: _isActive,
              ),
            );
          },
          child: Text('حفظ', style: GoogleFonts.cairo()),
        ),
      ],
    );
  }
}
