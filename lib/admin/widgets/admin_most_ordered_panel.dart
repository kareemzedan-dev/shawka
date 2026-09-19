import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/admin/widgets/admin_panel_header.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/product_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';

/// اختيار المنتجات التي تظهر في قسم «الأكثر طلباً» بالصفحة الرئيسية.
class AdminMostOrderedPanel extends StatefulWidget {
  const AdminMostOrderedPanel({super.key, required this.governorate});

  final Governorate governorate;

  @override
  State<AdminMostOrderedPanel> createState() => _AdminMostOrderedPanelState();
}

class _AdminMostOrderedPanelState extends State<AdminMostOrderedPanel> {
  final _storeRepo = StoreRepository();
  final _productRepo = ProductRepository();
  final _search = TextEditingController();
  String? _busyKey;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(Product product, bool value) async {
    final key = '${product.storeId}/${product.id}';
    setState(() => _busyKey = key);
    try {
      await _productRepo.updateProduct(product.copyWith(bestSeller: value));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanelHeader(
          title: 'الأكثر طلباً',
          subtitle:
              '${widget.governorate.name} — فعّل المنتجات لتظهر في قسم الأكثر طلباً بالرئيسية',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.cairo(),
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج أو مورد…',
              hintStyle: GoogleFonts.cairo(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Store>>(
            stream: _storeRepo.watchStoresByGovernorate(
              governorate: widget.governorate.name,
            ),
            builder: (context, storeSnap) {
              if (storeSnap.connectionState == ConnectionState.waiting &&
                  !storeSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (storeSnap.hasError) {
                return Center(
                  child: Text(
                    FirestoreErrorMessage.from(storeSnap.error!),
                    style: GoogleFonts.cairo(color: AppColors.error),
                  ),
                );
              }
              final stores = (storeSnap.data ?? [])
                  .where((s) => s.isActive)
                  .toList();
              if (stores.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.local_fire_department_outlined,
                  message:
                      'لا توجد موردين في هذه المحافظة.\nأضف متاجر أولاً من قسم المتاجر.',
                );
              }
              return _ProductsAcrossStores(
                stores: stores,
                productRepo: _productRepo,
                query: _search.text.trim(),
                busyKey: _busyKey,
                onToggle: _toggle,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductsAcrossStores extends StatelessWidget {
  const _ProductsAcrossStores({
    required this.stores,
    required this.productRepo,
    required this.query,
    required this.busyKey,
    required this.onToggle,
  });

  final List<Store> stores;
  final ProductRepository productRepo;
  final String query;
  final String? busyKey;
  final Future<void> Function(Product product, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return StreamBuilder<List<Product>>(
          stream: productRepo.watchProducts(store.id, activeOnly: true),
          builder: (context, snap) {
            final products = (snap.data ?? []).where((p) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  store.name.toLowerCase().contains(q);
            }).toList()
              ..sort((a, b) {
                final pinned = (b.bestSeller ? 1 : 0).compareTo(
                  a.bestSeller ? 1 : 0,
                );
                if (pinned != 0) return pinned;
                return a.sortOrder.compareTo(b.sortOrder);
              });

            if (products.isEmpty && query.isNotEmpty) {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                initiallyExpanded: index < 3,
                title: Text(
                  store.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  products.isEmpty
                      ? 'لا توجد منتجات'
                      : '${products.where((p) => p.bestSeller).length} مفعّل · ${products.length} منتج',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                children: [
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'أضف منتجات لهذا المورد أولاً',
                        style: GoogleFonts.cairo(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...products.map(
                      (product) => _ProductMostOrderedTile(
                        store: store,
                        product: product,
                        busy: busyKey == '${product.storeId}/${product.id}',
                        onChanged: (v) => onToggle(product, v),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductMostOrderedTile extends StatelessWidget {
  const _ProductMostOrderedTile({
    required this.store,
    required this.product,
    required this.busy,
    required this.onChanged,
  });

  final Store store;
  final Product product;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: CatalogNetworkImage(
            imageUrl: product.imageUrl,
            thumbnailUrl: product.imageThumbUrl,
            fit: BoxFit.cover,
            fallback: const ColoredBox(
              color: Color(0xFFF3F3F3),
              child: Icon(Icons.inventory_2_outlined),
            ),
          ),
        ),
      ),
      title: Text(
        product.name,
        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${product.price.toStringAsFixed(0)} ج.م',
        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: product.bestSeller,
              onChanged: onChanged,
            ),
    );
  }
}
