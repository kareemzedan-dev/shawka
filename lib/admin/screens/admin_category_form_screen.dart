import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/widgets/admin_activity_type_multi_select.dart';
import 'package:matlobgo/admin/widgets/admin_image_picker.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/utils/image_compressor.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/repositories/store_category_repository.dart';
import 'package:matlobgo/services/image_upload_service.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  const AdminCategoryFormScreen({
    super.key,
    required this.governorate,
    this.category,
    this.parent,
    this.onFinished,
  });

  final Governorate governorate;
  final StoreCategoryDef? category;
  /// عند إضافة تصنيف فرعي جديد.
  final StoreCategoryDef? parent;
  final VoidCallback? onFinished;

  @override
  State<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageKey = GlobalKey<AdminImagePickerState>();
  final _repo = StoreCategoryRepository();
  final _uploads = ImageUploadService();
  late final TextEditingController _name;
  late final TextEditingController _sortOrder;
  late bool _isActive;
  String? _imageUrl;
  bool _saving = false;
  List<StoreCategoryDef> _all = const [];
  String? _parentId;
  final Set<String> _selectedActivityTypeIds = {};

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _sortOrder = TextEditingController(text: '${c?.sortOrder ?? 0}');
    _isActive = c?.isActive ?? true;
    _imageUrl = c?.imageUrl;
    _parentId = c?.parentId.isNotEmpty == true
        ? c!.parentId
        : widget.parent?.id;
    if (c != null) {
      _selectedActivityTypeIds.addAll(c.activityTypeIds);
    }
    _loadParents();
  }

  Future<void> _loadParents() async {
    await for (final list in _repo.watchByGovernorate(widget.governorate.name)) {
      if (!mounted) return;
      setState(() => _all = list);
      break;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  StoreCategoryDef? get _selectedParent {
    final id = _parentId;
    if (id == null || id.isEmpty) return null;
    return StoreCatalogUtils.byId(_all, id);
  }

  StoreCategoryDef _buildCategory({
    required String id,
    required String parentId,
    required String path,
    required int depth,
    String? imageUrl,
    String? imageThumbUrl,
  }) {
    return StoreCategoryDef(
      id: id,
      name: _name.text.trim(),
      governorate: widget.governorate.name,
      parentId: parentId,
      path: path,
      depth: depth,
      imageUrl: imageUrl ?? _imageUrl,
      imageThumbUrl: imageThumbUrl,
      imageAsset: widget.category?.imageAsset,
      sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
      isActive: _isActive,
      priority: widget.category?.priority ?? 0,
      colorArgb: widget.category?.colorArgb,
      activityTypeIds: _selectedActivityTypeIds.toList(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parent = _selectedParent;
    if (_isEdit &&
        parent != null &&
        !StoreCatalogUtils.canBeParent(
          all: _all,
          categoryId: widget.category!.id,
          candidateParentId: parent.id,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن اختيار هذا الأب — تجنّب الحلقات في الشجرة',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final beforeFirestore = _isEdit ? widget.category!.toFirestore() : null;
    var imageUrl = _imageUrl;
    var imageThumbUrl = widget.category?.imageThumbUrl;

    try {
      final pendingBytes = _imageKey.currentState?.pendingBytes;
      late String categoryId;

      if (_isEdit) {
        categoryId = widget.category!.id;
        final h = StoreCategoryDef.hierarchyFor(id: categoryId, parent: parent);
        final updated = _buildCategory(
          id: categoryId,
          parentId: h.parentId,
          path: h.path,
          depth: h.depth,
          imageUrl: _imageUrl,
          imageThumbUrl: widget.category!.imageThumbUrl,
        );
        await _repo.upsert(updated);
        if (widget.category!.effectivePath != updated.effectivePath) {
          await _repo.repathSubtree(
            moved: updated,
            all: _all,
            oldPath: widget.category!.effectivePath,
          );
        }
      } else {
        categoryId = await _repo.create(
          _buildCategory(
            id: '',
            parentId: parent?.id ?? '',
            path: parent?.effectivePath ?? '',
            depth: parent == null ? 0 : parent.depth + 1,
          ),
          parent: parent,
        );
      }

      if (pendingBytes != null) {
        if (_isEdit) {
          await ImageUploadService.archiveBeforeReplace(
            entityType: 'category',
            entityId: categoryId,
            field: 'image',
            imageUrl: widget.category?.imageUrl,
            thumbUrl: widget.category?.imageThumbUrl,
          );
        }
        final uploaded = await _uploads.uploadStoreCategoryImage(
          governorateKey: widget.governorate.id,
          categoryId: categoryId,
          bytes: pendingBytes,
        );
        imageUrl = uploaded.fullUrl;
        imageThumbUrl = uploaded.thumbUrl;
        final parentAfter = _selectedParent;
        final h = StoreCategoryDef.hierarchyFor(
          id: categoryId,
          parent: parentAfter,
        );
        await _repo.upsert(
          _buildCategory(
            id: categoryId,
            parentId: h.parentId,
            path: h.path,
            depth: h.depth,
            imageUrl: imageUrl,
            imageThumbUrl: imageThumbUrl,
          ),
        );
      }

      final parentAfter = _selectedParent;
      final h = StoreCategoryDef.hierarchyFor(id: categoryId, parent: parentAfter);
      await AdminAuditRecord.firestoreEntity(
        action: _isEdit ? AuditAction.update : AuditAction.create,
        entityType: 'category',
        entityId: categoryId,
        summary:
            '${_isEdit ? 'تعديل' : 'إنشاء'} تصنيف ${_name.text.trim()} — ${widget.governorate.name}',
        beforeFirestore: beforeFirestore,
        afterFirestore: _buildCategory(
          id: categoryId,
          parentId: h.parentId,
          path: h.path,
          depth: h.depth,
          imageUrl: imageUrl,
          imageThumbUrl: imageThumbUrl,
        ).toFirestore(),
      );

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.onFinished != null) {
          widget.onFinished!();
        } else {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FirestoreErrorMessage.from(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentOptions = _all.where((c) {
      if (_isEdit && c.id == widget.category!.id) return false;
      if (_isEdit &&
          !StoreCatalogUtils.canBeParent(
            all: _all,
            categoryId: widget.category!.id,
            candidateParentId: c.id,
          )) {
        return false;
      }
      return true;
    }).toList();
    final flatParents = StoreCatalogUtils.flattenTree(parentOptions);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'تعديل تصنيف'
              : (widget.parent != null ? 'تصنيف فرعي جديد' : 'تصنيف رئيسي جديد'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AdminImagePicker(
              key: _imageKey,
              label: 'صورة التصنيف (تظهر في التطبيق)',
              uploadKind: ImageUploadKind.storeCategory,
              existingUrl: _imageUrl,
              aspectRatio: 4 / 5,
            ),
            const SizedBox(height: 16),
            PremiumInputField(
              controller: _name,
              label: 'اسم التصنيف',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'التصنيف الأب',
                labelStyle: GoogleFonts.cairo(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'اتركه «رئيسي» ليظهر في الصفحة الرئيسية',
                helperStyle: GoogleFonts.cairo(fontSize: 11),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _parentId?.isEmpty == true ? null : _parentId,
                  hint: Text('تصنيف رئيسي (بدون أب)', style: GoogleFonts.cairo()),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        '— تصنيف رئيسي —',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                    for (final c in flatParents)
                      DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(
                          StoreCatalogUtils.indentedLabel(c),
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _parentId = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PremiumInputField(
              controller: _sortOrder,
              label: 'ترتيب العرض بين الإخوة',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('ظاهر للعملاء', style: GoogleFonts.cairo()),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 12),
            AdminActivityTypeMultiSelect(
              selectedIds: _selectedActivityTypeIds,
              onChanged: (ids) => setState(() {
                _selectedActivityTypeIds
                  ..clear()
                  ..addAll(ids);
              }),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'حفظ',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
