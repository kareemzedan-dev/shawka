import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/screens/admin_product_form_screen.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_reorderable_list.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/product_repository.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({
    super.key,
    required this.store,
    required this.onPushPage,
  });

  final Store store;
  final void Function(Widget page) onPushPage;

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _repo = ProductRepository();
  List<Product>? _ordered;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AdminSession.instance.canManageStore(widget.store.id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ليس لديك صلاحية على هذا المتجر',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
        Navigator.of(context).maybePop();
      }
    });
    unawaited(_repo.syncStoreProductActivities(widget.store.id));
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final list = _ordered;
    if (list == null) return;
    setState(() {
      _reordering = true;
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
    });
    try {
      await _repo.batchUpdateSortOrder(
        storeId: widget.store.id,
        ordered: list,
      );
      await AdminAuditRecord.firestoreEntity(
        action: AuditAction.update,
        entityType: 'products',
        entityId: widget.store.id,
        summary: 'إعادة ترتيب منتجات ${widget.store.name}',
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
    return Scaffold(
      backgroundColor: AdminTheme.contentBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'منتجات — ${widget.store.name}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onPushPage(
          AdminProductFormScreen(
            store: widget.store,
            onFinished: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add),
        label: Text(
          'منتج جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _repo.watchProducts(widget.store.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _ordered == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_reordering && snapshot.hasData) {
            _ordered = List<Product>.from(snapshot.data!);
          }
          final products = _ordered ?? [];
          if (products.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'لا توجد منتجات.\nأضف أول منتج لهذا المتجر.',
            );
          }

          return AdminReorderableList(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 88),
            itemCount: products.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CatalogNetworkImage(
                        imageUrl: product.imageUrl,
                        fallback: Container(
                          color: AppColors.background,
                          child: const Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${product.price.toStringAsFixed(0)} ج.م · '
                    '${product.isAvailable ? "متاح" : "غير متاح"} · #${index + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => widget.onPushPage(
                          AdminProductFormScreen(
                            store: widget.store,
                            product: product,
                            onFinished: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          await _repo.deleteProduct(
                            storeId: widget.store.id,
                            productId: product.id,
                          );
                          await AdminAuditRecord.firestoreEntity(
                            action: AuditAction.delete,
                            entityType: 'product',
                            entityId: product.id,
                            summary:
                                'حذف منتج ${product.name} — ${widget.store.name}',
                            beforeFirestore: product.toFirestore(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
