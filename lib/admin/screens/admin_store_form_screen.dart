import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/utils/admin_save_helpers.dart';
import 'package:matlobgo/admin/services/admin_session.dart';
import 'package:matlobgo/admin/theme/admin_theme.dart';
import 'package:matlobgo/admin/widgets/admin_activity_type_multi_select.dart';
import 'package:matlobgo/admin/widgets/admin_image_picker.dart';
import 'package:matlobgo/admin/widgets/admin_operating_hours_editor.dart';
import 'package:matlobgo/admin/widgets/admin_store_location_section.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/utils/image_compressor.dart';
import 'package:matlobgo/core/utils/store_catalog_utils.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/delivery_pricing_tier.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/models/store_category_def.dart';
import 'package:matlobgo/models/store_operating_hours.dart';
import 'package:matlobgo/repositories/store_category_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/repositories/zone_repository.dart';
import 'package:matlobgo/models/zone.dart';
import 'package:matlobgo/services/image_upload_service.dart';

class AdminStoreFormScreen extends StatefulWidget {
  const AdminStoreFormScreen({
    super.key,
    required this.governorate,
    this.store,
    this.initialCategoryId,
    this.onFinished,
  });

  final Governorate governorate;
  final Store? store;
  final String? initialCategoryId;
  final VoidCallback? onFinished;

  @override
  State<AdminStoreFormScreen> createState() => _AdminStoreFormScreenState();
}

class _AdminStoreFormScreenState extends State<AdminStoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _logoPickerKey = GlobalKey<AdminImagePickerState>();
  final _coverPickerKey = GlobalKey<AdminImagePickerState>();
  final _repo = StoreRepository();
  final _categoryRepo = StoreCategoryRepository();
  final _zoneRepo = ZoneRepository();
  final _uploads = ImageUploadService();
  List<ServiceZone> _zones = [];
  String? _selectedZoneId;
  String? _selectedZoneName;
  late final TextEditingController _name;
  late final TextEditingController _tags;
  late final TextEditingController _rating;
  late final TextEditingController _deliveryMinutes;
  late final TextEditingController _deliveryFee;
  late final TextEditingController _storeFreeThreshold;
  late final TextEditingController _discountLabel;
  late final TextEditingController _description;
  late final TextEditingController _minOrderAmount;
  late final TextEditingController _area;
  late final TextEditingController _featuredPriority;
  late final TextEditingController _reviewCount;
  final Set<String> _selectedCategoryIds = {};
  final Set<String> _selectedActivityTypeIds = {};
  late bool _fallbackOpen;
  late bool _forceClosed;
  late bool _isFeatured;
  late bool _isActive;
  late bool _isVerified;
  late bool _supportsCash;
  late bool _supportsCard;
  late bool _supportsInstapay;
  late bool _supportsVodafoneCash;
  late bool _supportsOnlinePayment;
  DateTime? _featuredStartsAt;
  DateTime? _featuredEndsAt;
  late bool _useGlobalDeliveryPricing;
  late StoreOperatingHours _operatingHours;
  final _customTierRows = <_StoreTierControllers>[];
  double? _latitude;
  double? _longitude;
  bool _saving = false;

  bool get _isEdit => widget.store != null;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _name = TextEditingController(text: s?.name ?? '');
    _tags = TextEditingController(text: s?.tags.join('، ') ?? '');
    _rating = TextEditingController(text: (s?.rating ?? 0).toString());
    _deliveryMinutes = TextEditingController(
      text: (s?.deliveryMinutes ?? 30).toString(),
    );
    _deliveryFee = TextEditingController(
      text: (s?.deliveryFee ?? 15).toString(),
    );
    _storeFreeThreshold = TextEditingController(
      text: (s?.freeDeliveryThreshold ?? 0) > 0
          ? s!.freeDeliveryThreshold.toString()
          : '',
    );
    _discountLabel = TextEditingController(text: s?.discountLabel ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _minOrderAmount = TextEditingController(
      text: (s?.minOrderAmount ?? 0).toString(),
    );
    _area = TextEditingController(text: s?.area ?? '');
    _featuredPriority = TextEditingController(
      text: (s?.featuredPriority ?? 0).toString(),
    );
    _reviewCount = TextEditingController(
      text: (s?.reviewCount ?? 0).toString(),
    );
    final initialIds = <String>{};
    if (s != null) {
      initialIds.addAll(s.categoryIds);
      if (s.categoryId.isNotEmpty) initialIds.add(s.categoryId);
    }
    final seed = widget.initialCategoryId?.trim() ?? '';
    if (seed.isNotEmpty) initialIds.add(seed);
    _selectedCategoryIds.addAll(initialIds);
    if (s != null) {
      _selectedActivityTypeIds.addAll(s.activityTypeIds);
    }
    _fallbackOpen = s?.fallbackOpen ?? true;
    _forceClosed = s?.forceClosed ?? false;
    _isFeatured = s?.isFeatured ?? false;
    _isActive = s?.isActive ?? true;
    _isVerified = s?.isVerified ?? false;
    _supportsCash = s?.supportsCash ?? true;
    _supportsCard = s?.supportsCard ?? false;
    _supportsInstapay = s?.supportsInstapay ?? false;
    _supportsVodafoneCash = s?.supportsVodafoneCash ?? false;
    _supportsOnlinePayment = s?.supportsOnlinePayment ?? false;
    _featuredStartsAt = s?.featuredStartsAt;
    _featuredEndsAt = s?.featuredEndsAt;
    _useGlobalDeliveryPricing = s?.useGlobalDeliveryPricing ?? true;
    final hours = s?.operatingHours;
    _operatingHours = (hours == null || hours.days.isEmpty)
        ? StoreOperatingHours.defaultSchedule()
        : hours;
    _latitude = s?.latitude;
    _longitude = s?.longitude;
    _selectedZoneId = s?.zoneId.isNotEmpty == true ? s!.zoneId : null;
    _selectedZoneName = s?.zoneName.isNotEmpty == true ? s!.zoneName : null;
    _loadZones();
    final tiers =
        (s != null &&
            !s.useGlobalDeliveryPricing &&
            s.deliveryPricingTiers.isNotEmpty)
        ? s.deliveryPricingTiers
        : DeliveryPricingTier.defaults;
    for (final tier in tiers) {
      _customTierRows.add(_StoreTierControllers.fromTier(tier));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = AdminSession.instance;
      if (widget.store == null && !session.canCreateStores) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
        return;
      }
      final id = widget.store?.id;
      if (id != null && !session.canManageStore(id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ليس لديك صلاحية تعديل هذا المتجر',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _tags.dispose();
    _rating.dispose();
    _deliveryMinutes.dispose();
    _deliveryFee.dispose();
    _storeFreeThreshold.dispose();
    _discountLabel.dispose();
    _description.dispose();
    _minOrderAmount.dispose();
    _area.dispose();
    _featuredPriority.dispose();
    _reviewCount.dispose();
    for (final row in _customTierRows) {
      row.dispose();
    }
    super.dispose();
  }

  String _primaryCategoryId(List<StoreCategoryDef> all) {
    if (_selectedCategoryIds.isEmpty) return '';
    StoreCategoryDef? deepest;
    for (final id in _selectedCategoryIds) {
      final c = StoreCatalogUtils.byId(all, id);
      if (c == null) continue;
      if (deepest == null || c.depth > deepest.depth) deepest = c;
    }
    return deepest?.id ?? _selectedCategoryIds.first;
  }

  Store _buildStore({
    String? id,
    String? logoUrl,
    String? logoThumbUrl,
    String? coverUrl,
    String? coverThumbUrl,
    bool clearLogo = false,
    bool clearCover = false,
    List<StoreCategoryDef> categories = const [],
  }) {
    final s = widget.store;
    final ids = _selectedCategoryIds.toList();
    final primary = _primaryCategoryId(categories);
    return Store(
      id: id ?? s?.id ?? '',
      name: _name.text.trim(),
      categoryId: primary.isNotEmpty ? primary : (ids.isNotEmpty ? ids.first : ''),
      categoryIds: ids,
      activityTypeIds: _selectedActivityTypeIds.toList(),
      productActivityTypeIds: s?.productActivityTypeIds ?? const [],
      rating: double.tryParse(_rating.text.trim()) ?? 0,
      deliveryMinutes: int.tryParse(_deliveryMinutes.text.trim()) ?? 30,
      deliveryFee: double.tryParse(_deliveryFee.text.trim()) ?? 0,
      fallbackOpen: _fallbackOpen,
      tags: _tags.text
          .split(RegExp(r'[,،]'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      governorate: widget.governorate.name,
      zoneId: _selectedZoneId ?? '',
      zoneName: _selectedZoneName ?? '',
      isFeatured: _isFeatured,
      discountLabel: _discountLabel.text.trim().isEmpty
          ? null
          : _discountLabel.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      isActive: _isActive,
      minOrderAmount: double.tryParse(_minOrderAmount.text.trim()) ?? 0,
      area: _area.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      operatingHours: _operatingHours.days.isEmpty
          ? StoreOperatingHours.defaultSchedule()
          : _operatingHours,
      forceClosed: _forceClosed,
      logoUrl: clearLogo ? null : (logoUrl ?? s?.logoUrl),
      logoThumbUrl: clearLogo ? null : (logoThumbUrl ?? s?.logoThumbUrl),
      coverUrl: clearCover ? null : (coverUrl ?? s?.coverUrl ?? s?.imageUrl),
      coverThumbUrl: clearCover
          ? null
          : (coverThumbUrl ?? s?.coverThumbUrl ?? s?.imageThumbUrl),
      imageUrl: clearCover ? null : (coverUrl ?? s?.coverUrl ?? s?.imageUrl),
      imageThumbUrl: clearCover
          ? null
          : (coverThumbUrl ?? s?.coverThumbUrl ?? s?.imageThumbUrl),
      useGlobalDeliveryPricing: _useGlobalDeliveryPricing,
      deliveryPricingTiers: _useGlobalDeliveryPricing
          ? const []
          : _customTierRows.map((r) => r.toTier()).toList(),
      freeDeliveryThreshold:
          double.tryParse(_storeFreeThreshold.text.trim()) ?? 0,
      isVerified: _isVerified,
      featuredPriority: int.tryParse(_featuredPriority.text.trim()) ?? 0,
      featuredStartsAt: _featuredStartsAt,
      featuredEndsAt: _featuredEndsAt,
      reviewCount: int.tryParse(_reviewCount.text.trim()) ?? 0,
      totalOrders: s?.totalOrders ?? 0,
      totalFavorites: s?.totalFavorites ?? 0,
      totalViews: s?.totalViews ?? 0,
      supportsCash: _supportsCash,
      supportsCard: _supportsCard,
      supportsInstapay: _supportsInstapay,
      supportsVodafoneCash: _supportsVodafoneCash,
      supportsOnlinePayment: _supportsOnlinePayment,
    );
  }

  Future<void> _loadZones() async {
    final zones = await _zoneRepo
        .watchAll(widget.governorate.id)
        .first;
    if (mounted) {
      setState(() => _zones = zones);
    }
  }

  Future<void> _pickFeaturedDate({required bool start}) async {
    final current = start ? _featuredStartsAt : _featuredEndsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (start) {
          _featuredStartsAt = picked;
        } else {
          _featuredEndsAt = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اختر تصنيفاً واحداً على الأقل',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final cats = await _categoryRepo
        .watchByGovernorate(widget.governorate.name)
        .first;

    final logoPicker = _logoPickerKey.currentState;
    final coverPicker = _coverPickerKey.currentState;
    final logoPending = logoPicker?.pendingBytes;
    final coverPending = coverPicker?.pendingBytes;
    final logoCleared = logoPicker?.wasCleared ?? false;
    final coverCleared = coverPicker?.wasCleared ?? false;

    var logoUrl = logoCleared ? null : widget.store?.logoUrl;
    var logoThumbUrl = logoCleared ? null : widget.store?.logoThumbUrl;
    var coverUrl = coverCleared
        ? null
        : (widget.store?.coverUrl ?? widget.store?.imageUrl);
    var coverThumbUrl = coverCleared
        ? null
        : (widget.store?.coverThumbUrl ?? widget.store?.imageThumbUrl);

    final beforeFirestore = _isEdit && widget.store != null
        ? widget.store!.toFirestore()
        : null;

    try {
      late String storeId;
      if (_isEdit) {
        storeId = widget.store!.id;
        await _repo.updateStore(
          _buildStore(
            id: storeId,
            logoUrl: logoUrl,
            logoThumbUrl: logoThumbUrl,
            coverUrl: coverUrl,
            coverThumbUrl: coverThumbUrl,
            clearLogo: logoCleared,
            clearCover: coverCleared,
            categories: cats,
          ),
        );
      } else {
        storeId = await _repo.createStore(
          _buildStore(
            logoUrl: logoUrl,
            logoThumbUrl: logoThumbUrl,
            coverUrl: coverUrl,
            coverThumbUrl: coverThumbUrl,
            categories: cats,
          ),
        );
      }

      final uploadWarnings = <String>[];

      if (logoPending != null) {
        final warning = await AdminSaveHelpers.tryUpload(() async {
          if (_isEdit) {
            await ImageUploadService.archiveBeforeReplace(
              entityType: 'store',
              entityId: storeId,
              field: 'logo',
              imageUrl: widget.store?.logoUrl,
              thumbUrl: widget.store?.logoThumbUrl,
            );
          }
          final uploaded = await _uploads.uploadStoreLogo(
            storeId: storeId,
            bytes: logoPending,
          );
          logoUrl = uploaded.fullUrl;
          logoThumbUrl = uploaded.thumbUrl;
          await _repo.updateStore(
            _buildStore(
              id: storeId,
              logoUrl: logoUrl,
              logoThumbUrl: logoThumbUrl,
              coverUrl: coverUrl,
              coverThumbUrl: coverThumbUrl,
              categories: cats,
            ),
          );
        }, label: 'الشعار');
        if (warning != null) uploadWarnings.add(warning);
      } else if (_isEdit && logoCleared) {
        await _repo.updateStore(
          _buildStore(
            id: storeId,
            clearLogo: true,
            coverUrl: coverUrl,
            coverThumbUrl: coverThumbUrl,
            categories: cats,
          ),
        );
      }

      if (coverPending != null) {
        final warning = await AdminSaveHelpers.tryUpload(() async {
          if (_isEdit) {
            await ImageUploadService.archiveBeforeReplace(
              entityType: 'store',
              entityId: storeId,
              field: 'cover',
              imageUrl: widget.store?.coverUrl,
              thumbUrl: widget.store?.coverThumbUrl,
            );
          }
          final uploaded = await _uploads.uploadStoreCover(
            storeId: storeId,
            bytes: coverPending,
          );
          coverUrl = uploaded.fullUrl;
          coverThumbUrl = uploaded.thumbUrl;
          await _repo.updateStore(
            _buildStore(
              id: storeId,
              logoUrl: logoUrl,
              logoThumbUrl: logoThumbUrl,
              coverUrl: coverUrl,
              coverThumbUrl: coverThumbUrl,
              categories: cats,
            ),
          );
        }, label: 'الغلاف');
        if (warning != null) uploadWarnings.add(warning);
      } else if (_isEdit && coverCleared) {
        await _repo.updateStore(
          _buildStore(
            id: storeId,
            clearCover: true,
            logoUrl: logoUrl,
            logoThumbUrl: logoThumbUrl,
            categories: cats,
          ),
        );
      }

      final afterStore = _buildStore(
        id: storeId,
        logoUrl: logoUrl,
        logoThumbUrl: logoThumbUrl,
        coverUrl: coverUrl,
        coverThumbUrl: coverThumbUrl,
        categories: cats,
      );
      await AdminAuditRecord.firestoreEntity(
        action: _isEdit ? AuditAction.update : AuditAction.create,
        entityType: 'store',
        entityId: storeId,
        summary: '${_isEdit ? 'تعديل' : 'إنشاء'} متجر ${_name.text.trim()}',
        beforeFirestore: beforeFirestore,
        afterFirestore: afterStore.toFirestore(),
      );
      if (mounted) {
        if (uploadWarnings.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AdminSaveHelpers.partialSaveMessage(uploadWarnings),
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 8),
            ),
          );
        }
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

  void _pop() {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Scaffold(
      backgroundColor: AdminTheme.contentBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _pop,
        ),
        title: Text(
          _isEdit ? 'تعديل متجر' : 'متجر جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminImagePicker(
                    key: _logoPickerKey,
                    label: 'شعار المتجر',
                    uploadKind: ImageUploadKind.storeLogo,
                    existingUrl: s?.displayLogoUrl ?? s?.logoUrl,
                    aspectRatio: 1,
                  ),
                  const SizedBox(height: 16),
                  AdminImagePicker(
                    key: _coverPickerKey,
                    label: 'غلاف المتجر',
                    uploadKind: ImageUploadKind.storeCover,
                    existingUrl:
                        s?.displayCoverUrl ?? s?.coverUrl ?? s?.imageUrl,
                  ),
                  const SizedBox(height: 16),
                  PremiumInputField(
                    controller: _name,
                    label: 'اسم المتجر',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<StoreCategoryDef>>(
                    stream: _categoryRepo.watchByGovernorate(
                      widget.governorate.name,
                    ),
                    builder: (context, snap) {
                      final cats = snap.data ?? [];
                      final flat = StoreCatalogUtils.flattenTree(cats);
                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'التصنيفات (رئيسي / فرعي)',
                          labelStyle: GoogleFonts.cairo(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText:
                              'اختر كل المستويات التي يظهر فيها المتجر',
                          helperStyle: GoogleFonts.cairo(fontSize: 11),
                          errorText: _selectedCategoryIds.isEmpty &&
                                  (snap.hasData)
                              ? 'مطلوب تصنيف واحد على الأقل'
                              : null,
                        ),
                        child: cats.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'أضف تصنيفات من لوحة التصنيفات أولاً',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final c in flat)
                                    CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      value: _selectedCategoryIds.contains(c.id),
                                      title: Text(
                                        StoreCatalogUtils.indentedLabel(c),
                                        style: GoogleFonts.cairo(
                                          fontWeight: c.isRoot
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      subtitle: c.isRoot
                                          ? Text(
                                              'رئيسي',
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            )
                                          : Text(
                                              'فرعي · مستوى ${c.depth}',
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selectedCategoryIds.add(c.id);
                                          } else {
                                            _selectedCategoryIds.remove(c.id);
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AdminActivityTypeMultiSelect(
                    selectedIds: _selectedActivityTypeIds,
                    helperText:
                        'الأنشطة الافتراضية للمتجر. المنتجات تقدر تظهر في أنشطة إضافية من صفحة المنتج.',
                    onChanged: (ids) =>
                        setState(() {
                          _selectedActivityTypeIds
                            ..clear()
                            ..addAll(ids);
                        }),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'المحافظة',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          widget.governorate.name,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          'من شريط المحافظة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedZoneId,
                    decoration: InputDecoration(
                      labelText: 'المنطقة',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('بدون منطقة', style: GoogleFonts.cairo()),
                      ),
                      ..._zones.map(
                        (z) => DropdownMenuItem<String>(
                          value: z.id,
                          child: Text(z.name, style: GoogleFonts.cairo()),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedZoneId = v;
                        _selectedZoneName = v == null
                            ? null
                            : _zones.firstWhere((z) => z.id == v).name;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _tags,
                    label: 'الوسوم (مفصولة بفاصلة)',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumInputField(
                          controller: _rating,
                          label: 'التقييم',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PremiumInputField(
                          controller: _deliveryMinutes,
                          label: 'مدة التوصيل (دقيقة)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _deliveryFee,
                    label: 'رسوم العرض في البطاقة (تقريبي)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'استخدام تسعير التوصيل العام',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'عطّله لتحديد شرائح مسافة خاصة بهذا المتجر',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _useGlobalDeliveryPricing,
                    onChanged: (v) =>
                        setState(() => _useGlobalDeliveryPricing = v),
                  ),
                  if (!_useGlobalDeliveryPricing) ...[
                    const SizedBox(height: 8),
                    for (final row in _customTierRows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: PremiumInputField(
                                controller: row.minKm,
                                label: 'من كم',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PremiumInputField(
                                controller: row.maxKm,
                                label: 'إلى كم',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PremiumInputField(
                                controller: row.fee,
                                label: 'ج',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _storeFreeThreshold,
                    label: 'توصيل مجاني فوق (ج.م) — 0 = عام',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _minOrderAmount,
                    label: 'الحد الأدنى للطلب (ج.م)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _discountLabel,
                    label: 'نص الخصم (اختياري)',
                  ),
                  const SizedBox(height: 12),
                  PremiumInputField(
                    controller: _description,
                    label: 'وصف (اختياري)',
                  ),
                  const SizedBox(height: 16),
                  AdminStoreLocationSection(
                    areaController: _area,
                    governorate: widget.governorate,
                    storeName: _name.text.trim().isNotEmpty
                        ? _name.text.trim()
                        : (widget.store?.name ?? 'المتجر'),
                    latitude: _latitude,
                    longitude: _longitude,
                    onLocationChanged: (lat, lng) {
                      setState(() {
                        _latitude = lat;
                        _longitude = lng;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AdminOperatingHoursEditor(
                    hours: _operatingHours,
                    onChanged: (h) => setState(() => _operatingHours = h),
                  ),
                  const SizedBox(height: 8),
                  _CairoOpenStatusBanner(
                    hours: _operatingHours,
                    forceClosed: _forceClosed,
                    fallbackOpen: _fallbackOpen,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(
                      'مفتوح افتراضياً (بدون جدول ساعات)',
                      style: GoogleFonts.cairo(),
                    ),
                    subtitle: Text(
                      'يُستخدم فقط إذا لم تُعرّف ساعات عمل أسبوعية',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _fallbackOpen,
                    onChanged: _forceClosed
                        ? null
                        : (v) => setState(() => _fallbackOpen = v),
                  ),
                  SwitchListTile(
                    title: Text(
                      'إغلاق إجباري',
                      style: GoogleFonts.cairo(color: AppColors.error),
                    ),
                    subtitle: Text(
                      'المتجر يظهر مغلقاً دائماً بغض النظر عن الساعات',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _forceClosed,
                    onChanged: (v) => setState(() {
                      _forceClosed = v;
                      if (v) _fallbackOpen = false;
                    }),
                  ),
                  SwitchListTile(
                    title: Text('مميز', style: GoogleFonts.cairo()),
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                  ),
                  SwitchListTile(
                    title: Text('موثّق', style: GoogleFonts.cairo()),
                    value: _isVerified,
                    onChanged: (v) => setState(() => _isVerified = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumInputField(
                          controller: _featuredPriority,
                          label: 'أولوية الظهور المميز',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PremiumInputField(
                          controller: _reviewCount,
                          label: 'عدد التقييمات',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _StoreDateTile(
                    label: 'بداية الظهور المميز',
                    value: _featuredStartsAt,
                    onPick: () => _pickFeaturedDate(start: true),
                    onClear: () => setState(() => _featuredStartsAt = null),
                  ),
                  _StoreDateTile(
                    label: 'نهاية الظهور المميز',
                    value: _featuredEndsAt,
                    onPick: () => _pickFeaturedDate(start: false),
                    onClear: () => setState(() => _featuredEndsAt = null),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'طرق الدفع',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                  SwitchListTile(
                    title: Text('نقداً', style: GoogleFonts.cairo()),
                    value: _supportsCash,
                    onChanged: (v) => setState(() => _supportsCash = v),
                  ),
                  SwitchListTile(
                    title: Text('بطاقة', style: GoogleFonts.cairo()),
                    value: _supportsCard,
                    onChanged: (v) => setState(() => _supportsCard = v),
                  ),
                  SwitchListTile(
                    title: Text('إنستاباي', style: GoogleFonts.cairo()),
                    value: _supportsInstapay,
                    onChanged: (v) => setState(() => _supportsInstapay = v),
                  ),
                  SwitchListTile(
                    title: Text('فودافون كاش', style: GoogleFonts.cairo()),
                    value: _supportsVodafoneCash,
                    onChanged: (v) => setState(() => _supportsVodafoneCash = v),
                  ),
                  SwitchListTile(
                    title: Text('دفع إلكتروني', style: GoogleFonts.cairo()),
                    value: _supportsOnlinePayment,
                    onChanged: (v) =>
                        setState(() => _supportsOnlinePayment = v),
                  ),
                  SwitchListTile(
                    title: Text(
                      'نشط (يظهر للعملاء)',
                      style: GoogleFonts.cairo(),
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : Text(
                            _isEdit ? 'حفظ التعديلات' : 'إنشاء المتجر',
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

class _StoreDateTile extends StatelessWidget {
  const _StoreDateTile({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.cairo()),
      subtitle: Text(
        value == null
            ? 'غير محدد'
            : '${value!.year}/${value!.month}/${value!.day}',
        style: GoogleFonts.cairo(),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
          IconButton(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }
}

class _CairoOpenStatusBanner extends StatelessWidget {
  const _CairoOpenStatusBanner({
    required this.hours,
    required this.forceClosed,
    required this.fallbackOpen,
  });

  final StoreOperatingHours hours;
  final bool forceClosed;
  final bool fallbackOpen;

  @override
  Widget build(BuildContext context) {
    final cairoNow = StoreOperatingHours.nowInCairo();
    final open = forceClosed
        ? false
        : hours.hasSchedule
            ? hours.isOpenAt(cairoNow)
            : fallbackOpen;
    final dayName =
        StoreOperatingHours.dayLabels[cairoNow.weekday] ?? '${cairoNow.weekday}';
    final timeLabel =
        '${cairoNow.hour.toString().padLeft(2, '0')}:${cairoNow.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: open
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: open
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            open ? Icons.storefront_rounded : Icons.store_mall_directory_outlined,
            color: open ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forceClosed
                      ? 'مغلق إجبارياً الآن'
                      : open
                          ? 'مفتوح الآن في التطبيق'
                          : 'مغلق الآن في التطبيق',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    color: open ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  'توقيت القاهرة: $dayName $timeLabel'
                  '${forceClosed ? '' : open ? '' : ' — راجع ساعات اليوم الحالي'}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreTierControllers {
  _StoreTierControllers({
    required this.minKm,
    required this.maxKm,
    required this.fee,
  });

  factory _StoreTierControllers.fromTier(DeliveryPricingTier tier) {
    return _StoreTierControllers(
      minKm: TextEditingController(text: tier.minKm.toString()),
      maxKm: TextEditingController(text: tier.maxKm.toString()),
      fee: TextEditingController(text: tier.fee.toString()),
    );
  }

  final TextEditingController minKm;
  final TextEditingController maxKm;
  final TextEditingController fee;

  DeliveryPricingTier toTier() => DeliveryPricingTier(
    minKm: double.tryParse(minKm.text.trim()) ?? 0,
    maxKm: double.tryParse(maxKm.text.trim()) ?? 0,
    fee: double.tryParse(fee.text.trim()) ?? 0,
  );

  void dispose() {
    minKm.dispose();
    maxKm.dispose();
    fee.dispose();
  }
}
