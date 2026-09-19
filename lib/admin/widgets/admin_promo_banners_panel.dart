import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/screens/admin_promo_banner_form_screen.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/admin/widgets/admin_reorderable_list.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/promo_banner_record.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/promo_banner_repository.dart';

class AdminPromoBannersPanel extends StatefulWidget {
  const AdminPromoBannersPanel({
    super.key,
    required this.governorate,
    required this.onPushPage,
  });

  final Governorate governorate;
  final void Function(Widget page) onPushPage;

  @override
  State<AdminPromoBannersPanel> createState() => _AdminPromoBannersPanelState();
}

class _AdminPromoBannersPanelState extends State<AdminPromoBannersPanel> {
  final _repo = PromoBannerRepository();
  List<PromoBannerRecord>? _ordered;
  bool _reordering = false;

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final list = _ordered;
    if (list == null) return;
    setState(() {
      _reordering = true;
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
    });
    try {
      await _repo.batchUpdateSortOrder(list);
      await AdminAuditRecord.firestoreEntity(
        action: AuditAction.update,
        entityType: 'promo_banners',
        entityId: widget.governorate.name,
        summary: 'إعادة ترتيب بانرات ${widget.governorate.name}',
        extraMetadata: {'count': list.length},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'بانرات العروض',
          subtitle:
              '${widget.governorate.name} — إدارة العروض الترويجية في الصفحة الرئيسية',
          trailing: FilledButton.icon(
            onPressed: () => widget.onPushPage(
              AdminPromoBannerFormScreen(
                governorate: widget.governorate,
                onFinished: () => Navigator.of(context).pop(),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'بانر جديد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<PromoBannerRecord>>(
            stream: _repo.watchByGovernorate(widget.governorate.name),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _ordered == null) {
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
              if (!_reordering && snapshot.hasData) {
                _ordered = List<PromoBannerRecord>.from(snapshot.data!);
              }
              final banners = _ordered ?? [];
              PromoBannerDebug.log(
                'Admin.list Saved Governorate: "${widget.governorate.name}" '
                'count=${banners.length}',
              );
              for (final b in banners) {
                PromoBannerDebug.dumpLiveStatus(
                  record: b,
                  requestedGovernorate: widget.governorate.name,
                  now: DateTime.now(),
                );
              }
              if (banners.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.campaign_outlined,
                  message:
                      'لا توجد بانرات لهذه المحافظة.\nأضف أول بانر عرض ترويجي.',
                );
              }
              return AdminReorderableList(
                itemCount: banners.length,
                onReorder: _onReorder,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BannerCard(
                    banner: banners[i],
                    governorate: widget.governorate,
                    repo: _repo,
                    sortIndex: i,
                    onEdit: () => widget.onPushPage(
                      AdminPromoBannerFormScreen(
                        governorate: widget.governorate,
                        banner: banners[i],
                        onFinished: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.governorate,
    required this.repo,
    required this.onEdit,
    this.sortIndex,
  });

  final PromoBannerRecord banner;
  final Governorate governorate;
  final PromoBannerRepository repo;
  final VoidCallback onEdit;
  final int? sortIndex;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (banner.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 5,
              child: CatalogNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                fallback: Container(
                  color: AppColors.background,
                  child: const Icon(Icons.image_outlined, size: 40),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              banner.title,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _ActiveTag(active: banner.isActive),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'زر: ${banner.cta} · ترتيب ${banner.sortOrder}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      onEdit();
                    } else if (v == 'toggle') {
                      await repo.setActive(banner.id, !banner.isActive);
                      await AdminAuditRecord.fields(
                        action: AuditAction.statusChange,
                        entityType: 'promo_banner',
                        entityId: banner.id,
                        summary:
                            '${banner.isActive ? 'إيقاف' : 'تفعيل'} بانر ${banner.title}',
                        before: {'isActive': banner.isActive.toString()},
                        after: {'isActive': (!banner.isActive).toString()},
                      );
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('حذف البانر؟',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
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
                      if (ok == true) {
                        await repo.delete(banner.id);
                        await AdminAuditRecord.firestoreEntity(
                          action: AuditAction.delete,
                          entityType: 'promo_banner',
                          entityId: banner.id,
                          summary: 'حذف بانر ${banner.title}',
                          beforeFirestore: banner.toFirestore(),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(banner.isActive ? 'إيقاف' : 'تفعيل'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTag extends StatelessWidget {
  const _ActiveTag({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (active ? AppColors.success : AppColors.textHint)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'نشط' : 'متوقف',
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.success : AppColors.textHint,
        ),
      ),
    );
  }
}
