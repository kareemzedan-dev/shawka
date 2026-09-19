import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/screens/admin_category_form_screen.dart';
import 'package:matlobgo/admin/screens/admin_store_form_screen.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/repositories/store_category_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';

class AdminCategoriesPanel extends StatefulWidget {
  const AdminCategoriesPanel({
    super.key,
    required this.governorate,
    required this.onPushPage,
    this.onOpenStores,
  });

  final Governorate governorate;
  final void Function(Widget page) onPushPage;
  final void Function(StoreCategoryDef category)? onOpenStores;

  @override
  State<AdminCategoriesPanel> createState() => _AdminCategoriesPanelState();
}

class _AdminCategoriesPanelState extends State<AdminCategoriesPanel> {
  final _repo = StoreCategoryRepository();
  final _storeRepo = StoreRepository();
  final _expanded = <String>{};

  Future<void> _confirmDelete(
    BuildContext context,
    StoreCategoryDef cat,
    List<StoreCategoryDef> all,
  ) async {
    final kids = StoreCatalogUtils.childrenOf(all, cat.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف التصنيف؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          kids.isEmpty
              ? 'سيتم حذف «${cat.name}». المتاجر المرتبطة لن تُحذف.'
              : '«${cat.name}» يحتوي ${kids.length} تصنيف فرعي.\n'
                  'احذف الفروع أولاً أو انقلها لتصنيف آخر.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          if (kids.isEmpty)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف', style: GoogleFonts.cairo()),
            ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(cat.id);
    await AdminAuditRecord.firestoreEntity(
      action: AuditAction.delete,
      entityType: 'category',
      entityId: cat.id,
      summary: 'حذف تصنيف ${cat.name}',
      beforeFirestore: cat.toFirestore(),
    );
  }

  void _openForm({StoreCategoryDef? category, StoreCategoryDef? parent}) {
    widget.onPushPage(
      AdminCategoryFormScreen(
        governorate: widget.governorate,
        category: category,
        parent: parent,
        onFinished: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'التصنيفات الشجرية',
          subtitle:
              '${widget.governorate.name} — رئيسية ← فرعية ← فرعية… مع صورة لكل مستوى',
          trailing: FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'تصنيف رئيسي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<StoreCategoryDef>>(
            stream: _repo.watchByGovernorate(widget.governorate.name),
            builder: (context, catSnap) {
              return StreamBuilder<List<Store>>(
                stream: _storeRepo.watchStoresByGovernorate(
                  governorate: widget.governorate.name,
                ),
                builder: (context, storeSnap) {
                  if (catSnap.connectionState == ConnectionState.waiting &&
                      !catSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (catSnap.hasError) {
                    return Center(
                      child: Text(
                        FirestoreErrorMessage.from(catSnap.error!),
                        style: GoogleFonts.cairo(color: AppColors.error),
                      ),
                    );
                  }

                  final categories = catSnap.data ?? [];
                  final stores = storeSnap.data ?? [];
                  if (categories.isEmpty) {
                    return const AdminEmptyState(
                      icon: Icons.account_tree_outlined,
                      message:
                          'لا توجد تصنيفات بعد.\nأضف تصنيفاً رئيسياً ثم أضف فروعاً بداخله.',
                    );
                  }

                  final roots = StoreCatalogUtils.roots(categories);
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: roots.length,
                    itemBuilder: (context, i) {
                      return _CategoryTreeNode(
                        node: roots[i],
                        all: categories,
                        stores: stores,
                        depth: 0,
                        expanded: _expanded,
                        onToggle: (id) => setState(() {
                          if (_expanded.contains(id)) {
                            _expanded.remove(id);
                          } else {
                            _expanded.add(id);
                          }
                        }),
                        onEdit: (c) => _openForm(category: c),
                        onAddChild: (c) {
                          setState(() => _expanded.add(c.id));
                          _openForm(parent: c);
                        },
                        onDelete: (c) =>
                            _confirmDelete(context, c, categories),
                        onOpenStores: widget.onOpenStores,
                        onAddStore: (c) => widget.onPushPage(
                          AdminStoreFormScreen(
                            governorate: widget.governorate,
                            initialCategoryId: c.id,
                            onFinished: () => Navigator.of(context).pop(),
                          ),
                        ),
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
}

class _CategoryTreeNode extends StatelessWidget {
  const _CategoryTreeNode({
    required this.node,
    required this.all,
    required this.stores,
    required this.depth,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onAddChild,
    required this.onDelete,
    required this.onAddStore,
    this.onOpenStores,
  });

  final StoreCategoryDef node;
  final List<StoreCategoryDef> all;
  final List<Store> stores;
  final int depth;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<StoreCategoryDef> onEdit;
  final ValueChanged<StoreCategoryDef> onAddChild;
  final ValueChanged<StoreCategoryDef> onDelete;
  final ValueChanged<StoreCategoryDef> onAddStore;
  final void Function(StoreCategoryDef category)? onOpenStores;

  @override
  Widget build(BuildContext context) {
    final kids = StoreCatalogUtils.childrenOf(all, node.id);
    final isOpen = expanded.contains(node.id);
    final storeCount =
        stores.where((s) => StoreCatalogUtils.matchesCategory(s, node.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.fromLTRB(depth * 14.0, 4, 0, 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kids.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onToggle(node.id),
                    icon: Icon(
                      isOpen
                          ? Icons.expand_more_rounded
                          : Icons.chevron_left_rounded,
                    ),
                  )
                else
                  const SizedBox(width: 40),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CatalogNetworkImage(
                      imageUrl: node.imageUrl,
                      thumbnailUrl: node.imageThumbUrl,
                      fit: BoxFit.cover,
                      fallback: ColoredBox(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(node.icon, color: AppColors.primaryDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              node.name,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              [
                node.isRoot ? 'رئيسي' : 'فرعي · مستوى ${node.depth}',
                if (kids.isNotEmpty) '${kids.length} فرع',
                '$storeCount متجر',
                if (!node.isActive) 'مخفي',
              ].join(' · '),
              style: GoogleFonts.cairo(fontSize: 11.5),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit(node);
                  case 'child':
                    onAddChild(node);
                  case 'store':
                    onAddStore(node);
                  case 'stores':
                    onOpenStores?.call(node);
                  case 'toggle':
                    StoreCategoryRepository().setActive(node.id, !node.isActive);
                  case 'delete':
                    onDelete(node);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل', style: GoogleFonts.cairo()),
                ),
                PopupMenuItem(
                  value: 'child',
                  child: Text('إضافة فرع', style: GoogleFonts.cairo()),
                ),
                PopupMenuItem(
                  value: 'store',
                  child: Text('إضافة متجر هنا', style: GoogleFonts.cairo()),
                ),
                if (onOpenStores != null)
                  PopupMenuItem(
                    value: 'stores',
                    child: Text('عرض المتاجر', style: GoogleFonts.cairo()),
                  ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    node.isActive ? 'إخفاء' : 'إظهار',
                    style: GoogleFonts.cairo(),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'حذف',
                    style: GoogleFonts.cairo(color: AppColors.error),
                  ),
                ),
              ],
            ),
            onTap: kids.isNotEmpty ? () => onToggle(node.id) : () => onEdit(node),
          ),
        ),
        if (isOpen)
          for (final child in kids)
            _CategoryTreeNode(
              node: child,
              all: all,
              stores: stores,
              depth: depth + 1,
              expanded: expanded,
              onToggle: onToggle,
              onEdit: onEdit,
              onAddChild: onAddChild,
              onDelete: onDelete,
              onAddStore: onAddStore,
              onOpenStores: onOpenStores,
            ),
      ],
    );
  }
}
