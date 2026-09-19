import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_zone_form_dialog.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/zone.dart';
import 'package:matlobgo/repositories/governorate_repository.dart';
import 'package:matlobgo/repositories/service_area_analytics_repository.dart';
import 'package:matlobgo/repositories/service_area_waitlist_repository.dart';
import 'package:matlobgo/repositories/zone_repository.dart';

class AdminGovernoratesPanel extends StatefulWidget {
  const AdminGovernoratesPanel({super.key});

  @override
  State<AdminGovernoratesPanel> createState() => _AdminGovernoratesPanelState();
}

class _AdminGovernoratesPanelState extends State<AdminGovernoratesPanel> {
  final _repo = GovernorateRepository();
  final _areaAnalytics = ServiceAreaAnalyticsRepository();
  final _waitlistRepo = ServiceAreaWaitlistRepository();
  bool _seeding = false;

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await _repo.seedFromStaticIfEmpty();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت مزامنة المحافظات بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _addGovernorate() async {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final sortCtrl = TextEditingController(text: '10');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'محافظة جديدة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumInputField(
                controller: nameCtrl,
                label: 'اسم المحافظة (عربي)',
              ),
              const SizedBox(height: 12),
              PremiumInputField(
                controller: idCtrl,
                label: 'المعرّف (إنجليزي، مثل: luxor)',
              ),
              const SizedBox(height: 12),
              PremiumInputField(
                controller: sortCtrl,
                label: 'ترتيب العرض',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('إنشاء', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (ok != true) {
      idCtrl.dispose();
      nameCtrl.dispose();
      sortCtrl.dispose();
      return;
    }

    try {
      final gov = Governorate(
        id: idCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
        name: nameCtrl.text.trim(),
        isAvailable: true,
        sortOrder: int.tryParse(sortCtrl.text.trim()) ?? 10,
      );
      await _repo.createWithDefaults(gov);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء ${gov.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    }

    idCtrl.dispose();
    nameCtrl.dispose();
    sortCtrl.dispose();
  }

  Future<void> _editGovernorate(Governorate governorate) async {
    final nameCtrl = TextEditingController(text: governorate.name);
    final sortCtrl = TextEditingController(text: '${governorate.sortOrder}');
    var isAvailable = governorate.isAvailable;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            'تعديل المحافظة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'المعرّف: ${governorate.id}',
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PremiumInputField(
                  controller: nameCtrl,
                  label: 'اسم المحافظة (عربي)',
                ),
                const SizedBox(height: 12),
                PremiumInputField(
                  controller: sortCtrl,
                  label: 'ترتيب العرض',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('مفعّلة في التطبيق', style: GoogleFonts.cairo()),
                  value: isAvailable,
                  onChanged: (v) => setLocal(() => isAvailable = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حفظ', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      nameCtrl.dispose();
      sortCtrl.dispose();
      return;
    }

    final name = nameCtrl.text.trim();
    final sortOrder = int.tryParse(sortCtrl.text.trim()) ?? governorate.sortOrder;
    nameCtrl.dispose();
    sortCtrl.dispose();

    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اسم المحافظة مطلوب')),
        );
      }
      return;
    }

    try {
      await _repo.upsert(
        Governorate(
          id: governorate.id,
          name: name,
          isAvailable: isAvailable,
          sortOrder: sortOrder,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحديث $name')),
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

  Future<void> _deleteGovernorate(Governorate governorate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف المحافظة؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيتم حذف «${governorate.name}» من مناطق الخدمة. '
          'المتاجر والتصنيفات المرتبطة لن تُحذف تلقائياً.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.delete(governorate.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف ${governorate.name}')),
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

  Future<void> _addZone(Governorate? gov) async {
    String? governorateId = gov?.id;
    if (governorateId == null) {
      final govs = await _repo.watchAll().first;
      if (!mounted || govs.isEmpty) return;
      final selected = await showDialog<Governorate>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text('اختر المحافظة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          children: govs
              .map((g) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, g),
                    child: Text(g.name, style: GoogleFonts.cairo()),
                  ))
              .toList(),
        ),
      );
      if (selected == null) return;
      governorateId = selected.id;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AdminZoneFormDialog(governorateId: governorateId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'مناطق الخدمة',
          subtitle:
              'أضف أو عدّل أو احذف المحافظات والمناطق — التغيير يظهر فوراً في التطبيق',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _seeding ? null : _seed,
                icon: _seeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_sync_outlined, size: 18),
                label: Text(
                  'مزامنة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addGovernorate,
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'محافظة جديدة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _addZone(null),
                icon: const Icon(Icons.map_outlined, size: 20),
                label: Text(
                  'منطقة جديدة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ServiceAreaStatsCard(
          analytics: _areaAnalytics,
          waitlistRepo: _waitlistRepo,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Governorate>>(
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
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.location_city_outlined,
                  message:
                      'لا توجد محافظات.\nاضغط «محافظة جديدة» أو «مزامنة».',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _GovCard(
                  governorate: list[i],
                  repo: _repo,
                  onEdit: () => _editGovernorate(list[i]),
                  onDelete: () => _deleteGovernorate(list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceAreaStatsCard extends StatelessWidget {
  const _ServiceAreaStatsCard({
    required this.analytics,
    required this.waitlistRepo,
  });

  final ServiceAreaAnalyticsRepository analytics;
  final ServiceAreaWaitlistRepository waitlistRepo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<ServiceAreaStats>(
            stream: analytics.watchStats(),
            builder: (context, statsSnap) {
              final stats = statsSnap.data;
              return StreamBuilder<Map<String, int>>(
                stream: waitlistRepo.watchCountsByGovernorate(),
                builder: (context, waitSnap) {
                  final waitCounts = waitSnap.data ?? {};
                  final waitTotal =
                      waitCounts.values.fold<int>(0, (a, b) => a + b);
                  final topWait = waitCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'إحصائيات نطاق الخدمة',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatChip(
                            label: 'داخل النطاق',
                            value: '${stats?.supportedDetections ?? 0}',
                            color: AppColors.success,
                          ),
                          _StatChip(
                            label: 'خارج النطاق',
                            value: '${stats?.unsupportedDetections ?? 0}',
                            color: AppColors.error,
                          ),
                          _StatChip(
                            label: 'قائمة الانتظار',
                            value: '$waitTotal',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      if ((stats?.topRequestedGovernorates.isNotEmpty ??
                              false) ||
                          topWait.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'أكثر المحافظات طلباً',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTopDemand(
                            stats?.topRequestedGovernorates ?? [],
                            topWait,
                          ),
                          style: GoogleFonts.cairo(fontSize: 13),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTopDemand(
    List<MapEntry<String, int>> detections,
    List<MapEntry<String, int>> waitlist,
  ) {
    final merged = <String, int>{};
    for (final e in detections) {
      merged[e.key] = (merged[e.key] ?? 0) + e.value;
    }
    for (final e in waitlist) {
      merged[e.key] = (merged[e.key] ?? 0) + e.value;
    }
    if (merged.isEmpty) return '—';
    final sorted = merged.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => '${e.key} (${e.value})')
        .join(' · ');
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GovCard extends StatelessWidget {
  const _GovCard({
    required this.governorate,
    required this.repo,
    required this.onEdit,
    required this.onDelete,
  });

  final Governorate governorate;
  final GovernorateRepository repo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<void> _deleteZone(BuildContext context, ServiceZone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف المنطقة؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيتم حذف «${zone.name}» نهائياً.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ZoneRepository().delete(zone.governorateId, zone.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف ${zone.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: governorate.isAvailable
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.textHint.withValues(alpha: 0.12),
          child: Icon(
            Icons.location_on_rounded,
            color: governorate.isAvailable
                ? AppColors.success
                : AppColors.textHint,
          ),
        ),
        title: Text(
          governorate.name,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'معرّف: ${governorate.id} · ترتيب ${governorate.sortOrder}',
          style: GoogleFonts.cairo(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'تعديل',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'حذف',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            Switch(
              value: governorate.isAvailable,
              onChanged: (v) => repo.setAvailability(governorate.id, v),
            ),
          ],
        ),
        children: [
          StreamBuilder<List<ServiceZone>>(
            stream: ZoneRepository().watchAll(governorate.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final zones = snapshot.data ?? [];
              return Column(
                children: [
                  const Divider(height: 1),
                  if (zones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا توجد مناطق بعد',
                        style: GoogleFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...zones.map((zone) => ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.map_outlined,
                            size: 20,
                            color: zone.isActive
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                          title: Text(
                            zone.name,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${zone.polygon.length} نقطة',
                            style: GoogleFonts.cairo(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'تعديل المنطقة',
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => AdminZoneFormDialog(
                                    governorateId: governorate.id,
                                    zone: zone,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'حذف المنطقة',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteZone(context, zone),
                              ),
                              Switch(
                                value: zone.isActive,
                                onChanged: (v) => ZoneRepository().setActive(
                                  zone.governorateId,
                                  zone.id,
                                  v,
                                ),
                              ),
                            ],
                          ),
                        )),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => AdminZoneFormDialog(
                            governorateId: governorate.id,
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'إضافة منطقة',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
