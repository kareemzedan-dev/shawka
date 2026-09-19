import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/screens/admin_products_screen.dart';
import 'package:matlobgo/admin/screens/admin_store_form_screen.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/repositories/store_category_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';

class AdminStoresPanel extends StatelessWidget {
  const AdminStoresPanel({
    super.key,
    required this.governorate,
    this.categoryFilter,
    required this.onPushPage,
    this.onClearCategoryFilter,
  });

  final Governorate governorate;
  final StoreCategoryDef? categoryFilter;
  final void Function(Widget page) onPushPage;
  final VoidCallback? onClearCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final repo = StoreRepository();
    final session = AdminSession.instance;
    final scoped = session.isStoreScoped;
    final title = scoped
        ? 'متجري'
        : (categoryFilter?.name ?? 'كل المتاجر');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scoped
                          ? '${governorate.name} — تعديل المتجر والمنتجات'
                          : '${governorate.name} — إضافة · تعديل · حذف',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!scoped && categoryFilter != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onClearCategoryFilter,
                        icon: const Icon(Icons.clear, size: 16),
                        label: Text(
                          'إلغاء فلتر «${categoryFilter!.name}»',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (session.canCreateStores)
                FilledButton.icon(
                  onPressed: () => onPushPage(
                    AdminStoreFormScreen(
                      governorate: governorate,
                      initialCategoryId: categoryFilter?.id,
                      onFinished: () => Navigator.of(context).pop(),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    categoryFilter == null
                        ? 'متجر جديد'
                        : 'إضافة لـ ${categoryFilter!.name}',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<StoreCategoryDef>>(
            stream: StoreCategoryRepository()
                .watchByGovernorate(governorate.name),
            builder: (context, catSnap) {
              final allCats = catSnap.data ?? const <StoreCategoryDef>[];
              return StreamBuilder<List<Store>>(
                stream: repo.watchStoresByGovernorate(
                  governorate: governorate.name,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          FirestoreErrorMessage.from(snapshot.error!),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(color: AppColors.error),
                        ),
                      ),
                    );
                  }

                  var stores = session.filterStores(
                    snapshot.data ?? const <Store>[],
                    idOf: (s) => s.id,
                  );
                  final filter = categoryFilter;
                  if (!scoped && filter != null) {
                    stores = stores
                        .where(
                          (s) => StoreCatalogUtils.matchesCategoryInSubtree(
                            s,
                            filter.id,
                            allCats,
                          ),
                        )
                        .toList();
                  }

                  if (stores.isEmpty) {
                    return AdminEmptyState(
                      icon: Icons.storefront_outlined,
                      message: scoped
                          ? 'لا يوجد متجر مرتبط بحسابك.\nتواصل مع الإدارة لربط متجرك.'
                          : 'لا توجد متاجر في ${governorate.name}.\nاضغط «إضافة» لإنشاء أول متجر.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: stores.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return _StoreRow(
                        store: store,
                        showDelete: session.canDeleteStores,
                        onEdit: () => onPushPage(
                          AdminStoreFormScreen(
                            governorate: governorate,
                            store: store,
                            onFinished: () => Navigator.of(context).pop(),
                          ),
                        ),
                        onProducts: () => onPushPage(
                          AdminProductsScreen(
                            store: store,
                            onPushPage: onPushPage,
                          ),
                        ),
                        onDelete: () => _confirmDelete(context, repo, store),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StoreRepository repo,
    Store store,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف المتجر؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'سيتم حذف «${store.name}» من قاعدة البيانات.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await repo.deleteStore(store.id);
      await AdminAuditRecord.firestoreEntity(
        action: AuditAction.delete,
        entityType: 'store',
        entityId: store.id,
        summary: 'حذف متجر ${store.name}',
        beforeFirestore: store.toFirestore(),
      );
    }
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.store,
    required this.onEdit,
    required this.onProducts,
    required this.onDelete,
    this.showDelete = true,
  });

  final Store store;
  final VoidCallback onEdit;
  final VoidCallback onProducts;
  final VoidCallback onDelete;
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CatalogNetworkImage(
                  imageUrl: store.displayCoverThumbUrl ?? store.displayCoverUrl,
                  fallback: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(store.categoryIcon, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${store.isOpenNow ? "مفتوح" : "مغلق"} · '
                    '${store.isActive ? "نشط" : "معطّل"} · '
                    '${store.minOrderAmount > 0 ? "حد أدنى ${store.minOrderAmount.toInt()} ج.م · " : ""}'
                    'تقييم ${store.rating}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onProducts,
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Text('المنتجات', style: GoogleFonts.cairo(fontSize: 13)),
            ),
            IconButton(
              tooltip: 'تعديل',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            if (showDelete)
              IconButton(
                tooltip: 'حذف',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}
