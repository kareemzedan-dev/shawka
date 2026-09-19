import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/widgets/admin_activity_type_multi_select.dart';
import 'package:matlobgo/admin/widgets/admin_image_archive_sheet.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/admin/widgets/admin_image_picker.dart';
import 'package:matlobgo/admin/widgets/admin_product_extras_editor.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/utils/image_compressor.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/product.dart';
import 'package:matlobgo/models/product_addon.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/product_repository.dart';
import 'package:matlobgo/services/image_upload_service.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({
    super.key,
    required this.store,
    this.product,
    this.onFinished,
  });

  final Store store;
  final Product? product;
  final VoidCallback? onFinished;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  static const _categoryPresets = [
    'فطار',
    'ساندوتشات',
    'وجبات',
    'مشروبات',
    'حلويات',
  ];

  final _formKey = GlobalKey<FormState>();
  final _imagePickerKey = GlobalKey<AdminImagePickerState>();
  final _repo = ProductRepository();
  final _uploads = ImageUploadService();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _sortOrder;
  late final TextEditingController _stockQuantity;
  late final TextEditingController _maxPerCustomer;
  late final TextEditingController _category;
  late final TextEditingController _oldPrice;
  late final TextEditingController _discountPercent;
  late final TextEditingController _tags;
  late final TextEditingController _preparationTime;
  late bool _isAvailable;
  late bool _trackStock;
  late bool _bestSeller;
  late bool _isNew;
  late bool _isFeatured;
  late List<String> _ingredients;
  late List<ProductAddon> _addons;
  final Set<String> _selectedActivityTypeIds = {};
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: (p?.price ?? 0).toString());
    _description = TextEditingController(text: p?.description ?? '');
    _sortOrder = TextEditingController(text: (p?.sortOrder ?? 0).toString());
    _stockQuantity = TextEditingController(
      text: (p?.stockQuantity ?? 0).toString(),
    );
    _maxPerCustomer = TextEditingController(
      text: (p?.maxPerCustomer ?? 0).toString(),
    );
    _category = TextEditingController(text: p?.category ?? '');
    _oldPrice = TextEditingController(
      text: p == null || p.oldPrice <= 0 ? '' : p.oldPrice.toString(),
    );
    _discountPercent = TextEditingController(
      text: (p?.discountPercent ?? 0).toString(),
    );
    _tags = TextEditingController(text: p?.tags.join('، ') ?? '');
    _preparationTime = TextEditingController(
      text: (p?.preparationTime ?? 0).toString(),
    );
    _isAvailable = p?.isAvailable ?? true;
    _trackStock = p?.trackStock ?? false;
    _bestSeller = p?.bestSeller ?? false;
    _isNew = p?.isNew ?? false;
    _isFeatured = p?.isFeatured ?? false;
    _ingredients = List<String>.from(p?.ingredients ?? []);
    _addons = List<ProductAddon>.from(p?.addons ?? []);
    if (p != null) {
      _selectedActivityTypeIds.addAll(p.activityTypeIds);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _sortOrder.dispose();
    _stockQuantity.dispose();
    _maxPerCustomer.dispose();
    _category.dispose();
    _oldPrice.dispose();
    _discountPercent.dispose();
    _tags.dispose();
    _preparationTime.dispose();
    super.dispose();
  }

  Product _buildProduct({
    String? id,
    String? imageUrl,
    String? imageThumbUrl,
    bool clearImage = false,
  }) {
    return Product(
      id: id ?? widget.product?.id ?? '',
      storeId: widget.store.id,
      name: _name.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      isAvailable: _isAvailable,
      sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
      imageUrl: clearImage ? null : imageUrl,
      imageThumbUrl: clearImage ? null : imageThumbUrl,
      ingredients: _ingredients,
      addons: _addons,
      trackStock: _trackStock,
      stockQuantity: int.tryParse(_stockQuantity.text.trim()) ?? 0,
      maxPerCustomer: int.tryParse(_maxPerCustomer.text.trim()) ?? 0,
      category: _category.text.trim(),
      bestSeller: _bestSeller,
      isNew: _isNew,
      isFeatured: _isFeatured,
      oldPrice: double.tryParse(_oldPrice.text.trim()) ?? 0,
      discountPercent: double.tryParse(_discountPercent.text.trim()) ?? 0,
      tags: _tags.text
          .split(RegExp(r'[,،]'))
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      preparationTime: int.tryParse(_preparationTime.text.trim()) ?? 0,
      reviewCount: widget.product?.reviewCount ?? 0,
      rating: widget.product?.rating ?? 0,
      viewsCount: widget.product?.viewsCount ?? 0,
      ordersCount: widget.product?.ordersCount ?? 0,
      activityTypeIds: _selectedActivityTypeIds.toList(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final picker = _imagePickerKey.currentState;
    final pendingBytes = picker?.pendingBytes;
    final imageCleared = picker?.wasCleared ?? false;
    var imageUrl = imageCleared ? null : widget.product?.imageUrl;
    var imageThumbUrl = imageCleared ? null : widget.product?.imageThumbUrl;

    final beforeFirestore = _isEdit && widget.product != null
        ? widget.product!.toFirestore()
        : null;

    try {
      late String productId;
      if (_isEdit) {
        productId = widget.product!.id;
        await _repo.updateProduct(
          _buildProduct(
            id: productId,
            imageUrl: imageUrl,
            imageThumbUrl: imageThumbUrl,
            clearImage: imageCleared,
          ),
        );
      } else {
        productId = await _repo.createProduct(
          _buildProduct(imageUrl: imageUrl),
        );
      }

      if (pendingBytes != null) {
        if (_isEdit) {
          await ImageUploadService.archiveBeforeReplace(
            entityType: 'product',
            entityId: productId,
            field: 'image',
            imageUrl: widget.product?.imageUrl,
            thumbUrl: widget.product?.imageThumbUrl,
          );
        }
        final uploaded = await _uploads.uploadProductImage(
          storeId: widget.store.id,
          productId: productId,
          bytes: pendingBytes,
        );
        await _repo.updateProduct(
          _buildProduct(
            id: productId,
            imageUrl: uploaded.fullUrl,
            imageThumbUrl: uploaded.thumbUrl,
          ),
        );
      } else if (_isEdit && imageCleared) {
        await _repo.updateProduct(
          _buildProduct(id: productId, clearImage: true),
        );
      }

      final afterProduct = _buildProduct(
        id: productId,
        imageUrl: imageUrl,
        imageThumbUrl: imageThumbUrl,
      );
      await AdminAuditRecord.firestoreEntity(
        action: _isEdit ? AuditAction.update : AuditAction.create,
        entityType: 'product',
        entityId: productId,
        summary:
            '${_isEdit ? 'تعديل' : 'إضافة'} منتج ${_name.text.trim()} — ${widget.store.name}',
        beforeFirestore: beforeFirestore,
        afterFirestore: afterProduct.toFirestore(),
      );

      if (mounted) {
        if (widget.onFinished != null) {
          widget.onFinished!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل الحفظ: ${FirestoreErrorMessage.from(e)}',
              style: GoogleFonts.cairo(),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.contentBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            if (widget.onFinished != null) {
              widget.onFinished!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isEdit ? 'تعديل منتج' : 'منتج جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'أرشيف الصور',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => AdminImageArchiveSheet.show(
                context,
                entityType: 'product',
                entityId: widget.product!.id,
                title: widget.product!.name,
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.store.name,
                    style: GoogleFonts.cairo(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminImagePicker(
                    key: _imagePickerKey,
                    label: 'صورة المنتج (تظهر في أعلى صفحة التفاصيل)',
                    uploadKind: ImageUploadKind.product,
                    existingUrl: widget.product?.imageUrl,
                    aspectRatio: 1,
                  ),
                  const SizedBox(height: 16),
                  PremiumInputField(
                    controller: _name,
                    label: 'اسم المنتج',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _price,
                    label: 'السعر الأساسي (ج.م)',
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v?.trim() ?? '') == null
                        ? 'سعر غير صالح'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumInputField(
                          controller: _oldPrice,
                          label: 'السعر قبل الخصم',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PremiumInputField(
                          controller: _discountPercent,
                          label: 'نسبة الخصم %',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تصنيف المنتج',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in _categoryPresets)
                        ActionChip(
                          label: Text(preset, style: GoogleFonts.cairo()),
                          backgroundColor: _category.text.trim() == preset
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : null,
                          side: BorderSide(
                            color: _category.text.trim() == preset
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                          onPressed: () => setState(() {
                            _category.text = preset;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PremiumInputField(
                    controller: _category,
                    label: 'تصنيف مخصص (يظهر كفلتر في تطبيق العميل)',
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _description,
                    label: 'وصف المنتج (قسم «عن المنتج»)',
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _tags,
                    label: 'الوسوم (مفصولة بفاصلة)',
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _preparationTime,
                    label: 'وقت التحضير (دقيقة)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _sortOrder,
                    label: 'ترتيب العرض / شارة الأكثر طلباً',
                    keyboardType: TextInputType.number,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(
                      'الترتيب 0–2 يضيف شارة «الأكثر طلباً» في صفحة تفاصيل المنتج وقسم المتجر.',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminProductExtrasEditor(
                    ingredients: _ingredients,
                    addons: _addons,
                    onIngredientsChanged: (list) =>
                        setState(() => _ingredients = list),
                    onAddonsChanged: (list) => setState(() => _addons = list),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(
                      'الأكثر طلباً (الصفحة الرئيسية)',
                      style: GoogleFonts.cairo(),
                    ),
                    subtitle: Text(
                      'يظهر المنتج في قسم «الأكثر طلباً» بالتطبيق',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _bestSeller,
                    onChanged: (v) => setState(() => _bestSeller = v),
                  ),
                  SwitchListTile(
                    title: Text('جديد', style: GoogleFonts.cairo()),
                    value: _isNew,
                    onChanged: (v) => setState(() => _isNew = v),
                  ),
                  SwitchListTile(
                    title: Text('مميز', style: GoogleFonts.cairo()),
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                  ),
                  SwitchListTile(
                    title: Text('تتبع المخزون', style: GoogleFonts.cairo()),
                    value: _trackStock,
                    onChanged: (v) => setState(() => _trackStock = v),
                  ),
                  if (_trackStock) ...[
                    const SizedBox(height: 4),
                    PremiumInputField(
                      controller: _stockQuantity,
                      label: 'كمية المخزون المتاحة',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final qty = int.tryParse(v?.trim() ?? '');
                        if (qty == null) return 'أدخل كمية صحيحة';
                        if (qty < 0) return 'الكمية يجب أن تكون 0 أو أكثر';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  PremiumInputField(
                    controller: _maxPerCustomer,
                    label: 'الحد الأقصى للعميل (0 = بلا حد)',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final qty = int.tryParse(v?.trim() ?? '');
                      if (qty == null) return 'أدخل عدداً صحيحاً';
                      if (qty < 0) return 'القيمة يجب أن تكون 0 أو أكثر';
                      if (qty > 99) return 'الحد الأقصى 99';
                      return null;
                    },
                  ),
                  SwitchListTile(
                    title: Text('متاح للطلب', style: GoogleFonts.cairo()),
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                  const SizedBox(height: 12),
                  AdminActivityTypeMultiSelect(
                    selectedIds: _selectedActivityTypeIds,
                    helperText:
                        'فارغ = يتبع أنشطة المتجر. لو اخترت أنشطة هنا المنتج يظهر فيها حتى لو المتجر مش مربوط بيها.',
                    onChanged: (ids) => setState(() {
                      _selectedActivityTypeIds
                        ..clear()
                        ..addAll(ids);
                    }),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'حفظ' : 'إضافة المنتج',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
