import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/utils/admin_format.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/cms_text_entry.dart';
import 'package:matlobgo/repositories/cms_text_repository.dart';

/// إدارة محتوى شاشة البحث فقط — بدون قيم افتراضية في التطبيق.
class AdminSearchPagePanel extends StatefulWidget {
  const AdminSearchPagePanel({super.key});

  @override
  State<AdminSearchPagePanel> createState() => _AdminSearchPagePanelState();
}

class _AdminSearchPagePanelState extends State<AdminSearchPagePanel> {
  final _repo = CmsTextRepository();
  final _controllers = <String, TextEditingController>{};
  final _savingKeys = <String>{};

  static const _searchKeys = <String>{
    CmsKeys.searchPageTitle,
    CmsKeys.searchPlaceholder,
    CmsKeys.searchFilterAll,
    CmsKeys.searchTrending,
    CmsKeys.searchPopularTitle,
    CmsKeys.searchSuggestions,
    CmsKeys.searchRecentTitle,
    CmsKeys.searchRecentClear,
    CmsKeys.searchSuggestedStoresTitle,
    CmsKeys.searchSuggestedStoresSubtitle,
    CmsKeys.searchBlacklist,
  };

  static const _hints = <String, String>{
    CmsKeys.searchPageTitle: 'مثال: البحث',
    CmsKeys.searchPlaceholder: 'مثال: ابحث عن مطعم أو وجبة',
    CmsKeys.searchFilterAll: 'مثال: الكل',
    CmsKeys.searchTrending: 'افصل بـ | مثل: بيتزا|برجر|سوشي',
    CmsKeys.searchPopularTitle: 'مثال: الأكثر بحثاً',
    CmsKeys.searchSuggestions: 'اختياري — كلمات سريعة مفصولة بـ |',
    CmsKeys.searchRecentTitle: 'مثال: عمليات البحث الأخيرة',
    CmsKeys.searchRecentClear: 'مثال: مسح الكل',
    CmsKeys.searchSuggestedStoresTitle: 'مثال: موردون مقترحون',
    CmsKeys.searchSuggestedStoresSubtitle: 'مثال: توصيل سريع لمنطقتك الآن',
    CmsKeys.searchBlacklist: 'كلمات ممنوعة مفصولة بـ |',
  };

  @override
  void initState() {
    super.initState();
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
        summary: 'تعديل محتوى البحث: ${entry.label}',
        beforeFirestore: {
          'key': entry.key,
          'value': entry.value,
        },
        afterFirestore: {
          'key': entry.key,
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
          title: 'صفحة البحث',
          subtitle:
              'كل نصوص وكلمات شاشة البحث — اترك الحقل فارغاً لإخفاء العنصر من التطبيق · القوائم افصلها بـ |',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            'تصنيفات الدوّارة والشرائح تأتي من قسم «التصنيفات» لكل محافظة (الاسم + الصورة).',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CmsTextEntry>>(
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

              final byKey = {
                for (final e in snapshot.data ?? const <CmsTextEntry>[])
                  e.key: e,
              };

              final defaultLabels = {
                for (final e in CmsTextDefaults.entries) e.$1: e.$2,
              };

              final ordered = <CmsTextEntry>[];
              for (final key in _searchKeys) {
                final existing = byKey[key];
                if (existing != null) {
                  ordered.add(existing);
                  continue;
                }
                ordered.add(
                  CmsTextEntry(
                    id: key,
                    key: key,
                    label: defaultLabels[key] ?? key,
                    value: '',
                    updatedAt: DateTime.now(),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: ordered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final entry = ordered[i];
                  final controller = _controllerFor(entry);
                  final saving = _savingKeys.contains(entry.key);
                  final dirty = controller.text.trim() != entry.value.trim();
                  final hint = _hints[entry.key];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'آخر تحديث ${AdminFormat.relative(entry.updatedAt)}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (hint != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              hint,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: controller,
                            maxLines: entry.key.contains('trending') ||
                                    entry.key.contains('suggestions') ||
                                    entry.key.contains('blacklist')
                                ? 3
                                : 2,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'اتركه فارغاً للإخفاء',
                              hintStyle: GoogleFonts.cairo(
                                color: AppColors.textHint,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: GoogleFonts.cairo(),
                          ),
                          if (dirty || saving) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: FilledButton.icon(
                                onPressed: saving ? null : () => _save(entry),
                                icon: saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined, size: 18),
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
