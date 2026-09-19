import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/admin/utils/admin_audit_record.dart';
import 'package:matlobgo/admin/widgets/admin_activity_type_multi_select.dart';
import 'package:matlobgo/admin/widgets/admin_image_picker.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/utils/firestore_error_message.dart';
import 'package:matlobgo/core/utils/image_compressor.dart';
import 'package:matlobgo/core/utils/promo_banner_debug.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/audit_log.dart';
import 'package:matlobgo/models/promo_banner_record.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/promo_banner_repository.dart';
import 'package:matlobgo/services/image_upload_service.dart';

class AdminPromoBannerFormScreen extends StatefulWidget {
  const AdminPromoBannerFormScreen({
    super.key,
    required this.governorate,
    this.banner,
    this.onFinished,
  });

  final Governorate governorate;
  final PromoBannerRecord? banner;
  final VoidCallback? onFinished;

  @override
  State<AdminPromoBannerFormScreen> createState() =>
      _AdminPromoBannerFormScreenState();
}

class _AdminPromoBannerFormScreenState
    extends State<AdminPromoBannerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PromoBannerRepository();
  final _uploads = ImageUploadService();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _description;
  late final TextEditingController _cta;
  late final TextEditingController _sortOrder;
  late final TextEditingController _deepLinkId;
  late final TextEditingController _ctaColor;
  late final TextEditingController _targetCategoryIds;
  final Set<String> _selectedActivityTypeIds = {};
  late bool _isActive;
  late String _deepLinkRoute;
  DateTime? _startsAt;
  DateTime? _endsAt;
  String? _imageUrl;

  /// Parent-owned pending image — survives picker recreate.
  Uint8List? _pendingImageBytes;
  bool _imageCleared = false;
  bool _saving = false;
  int _buildCount = 0;

  bool get _isEdit => widget.banner != null;

  void _logForm(String event, {bool withStack = false}) {
    if (!kDebugMode) return;
    debugPrint(
      '[PromoBannerForm] $event | state.hash=$hashCode '
      'widget.hash=${widget.hashCode} '
      'pendingBytes=${_pendingImageBytes?.length ?? 0} '
      'cleared=$_imageCleared buildCount=$_buildCount',
    );
    if (withStack) {
      debugPrint('[PromoBannerForm] STACK:\n${StackTrace.current}');
    }
  }

  /// Only mutation path for pending bytes — logs + stack on every change.
  void _setPendingImageBytes(
    Uint8List? next, {
    required String reason,
    bool cleared = false,
  }) {
    final prevLen = _pendingImageBytes?.length ?? 0;
    final nextLen = next?.length ?? 0;
    if (!identical(_pendingImageBytes, next) || _imageCleared != cleared) {
      if (kDebugMode) {
        debugPrint(
          '[PromoBannerForm] _pendingImageBytes CHANGE '
          'reason=$reason prevLen=$prevLen nextLen=$nextLen '
          'cleared=$cleared state.hash=$hashCode',
        );
        debugPrint('[PromoBannerForm] STACK:\n${StackTrace.current}');
      }
    }
    _pendingImageBytes = next;
    _imageCleared = cleared;
    if (cleared) {
      _imageUrl = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _logForm('initState', withStack: true);
    final b = widget.banner;
    _title = TextEditingController(text: b?.title ?? '');
    _subtitle = TextEditingController(text: b?.subtitle ?? '');
    _description = TextEditingController(text: b?.description ?? '');
    _cta = TextEditingController(text: b?.cta ?? 'اطلب الآن');
    _sortOrder = TextEditingController(text: '${b?.sortOrder ?? 0}');
    _deepLinkId = TextEditingController(text: b?.deepLinkId ?? '');
    _ctaColor = TextEditingController(
      text: b?.ctaColorArgb == null
          ? ''
          : '0x${b!.ctaColorArgb!.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    );
    _targetCategoryIds = TextEditingController(
      text: b?.targetCategoryIds.join(', ') ?? '',
    );
    if (b != null) {
      _selectedActivityTypeIds.addAll(b.activityTypeIds);
    }
    _deepLinkRoute = b?.deepLinkRoute ?? 'home';
    _startsAt = b?.startsAt;
    _endsAt = b?.endsAt;
    _isActive = b?.isActive ?? true;
    _imageUrl = b?.imageUrl;
  }

  @override
  void dispose() {
    _logForm('dispose', withStack: true);
    _title.dispose();
    _subtitle.dispose();
    _description.dispose();
    _cta.dispose();
    _sortOrder.dispose();
    _deepLinkId.dispose();
    _ctaColor.dispose();
    _targetCategoryIds.dispose();
    super.dispose();
  }

  void _onImageChanged(Uint8List? bytes, {bool cleared = false}) {
    setState(() {
      _setPendingImageBytes(
        bytes,
        reason: cleared ? 'onImageChanged(cleared)' : 'onImageChanged(picked)',
        cleared: cleared,
      );
    });
    _logForm('after onImageChanged');
  }

  int? _parseColor(String value) {
    var normalized = value.trim().replaceFirst('#', '');
    normalized = normalized.replaceFirst(
      RegExp(r'^0x', caseSensitive: false),
      '',
    );
    if (normalized.isEmpty) return null;
    if (normalized.length == 6) normalized = 'FF$normalized';
    return int.tryParse(normalized, radix: 16);
  }

  /// DatePicker returns midnight — end date must cover the full calendar day.
  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  PromoBannerRecord _buildBanner({
    required String id,
    String? imageUrl,
    String? imageThumbUrl,
  }) {
    return PromoBannerRecord(
      id: id,
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim(),
      description: _description.text.trim(),
      cta: _cta.text.trim(),
      imageUrl: imageUrl,
      imageThumbUrl: imageThumbUrl,
      imageAsset: widget.banner?.imageAsset,
      accentColorArgb: widget.banner?.accentColorArgb,
      ctaColorArgb: _parseColor(_ctaColor.text),
      governorate: widget.governorate.name,
      isActive: _isActive,
      sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
      startsAt: _startsAt == null ? null : _startOfDay(_startsAt!),
      endsAt: _endsAt == null ? null : _endOfDay(_endsAt!),
      deepLinkRoute: _deepLinkRoute,
      deepLinkId: _deepLinkId.text.trim(),
      targetCategoryIds: _targetCategoryIds.text
          .split(RegExp(r'[,،]'))
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(),
      activityTypeIds: _selectedActivityTypeIds.toList(),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _startsAt : _endsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (start) {
          _startsAt = _startOfDay(picked);
        } else {
          _endsAt = _endOfDay(picked);
        }
      });
      PromoBannerDebug.log(
        start
            ? 'Admin date startsAt → ${_startsAt!.toIso8601String()}'
            : 'Admin date endsAt → ${_endsAt!.toIso8601String()} (end of day)',
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final beforeFirestore = _isEdit && widget.banner != null
        ? widget.banner!.toFirestore()
        : null;

    try {
      var imageUrl = _imageCleared ? null : _imageUrl;
      var imageThumbUrl =
          _imageCleared ? null : widget.banner?.imageThumbUrl;
      final pendingBytes = _pendingImageBytes;

      PromoBannerDebug.log(
        'Admin.save mode=${_isEdit ? "edit" : "create"} '
        'govId=${widget.governorate.id} '
        'Saved Governorate: "${widget.governorate.name}" '
        'isActive=$_isActive startsAt=$_startsAt endsAt=$_endsAt '
        'pendingImageBytes=${pendingBytes?.length ?? 0} '
        'imageUrl=${PromoBannerDebug.describeUrl(imageUrl)}',
      );

      late String bannerId;
      if (_isEdit) {
        bannerId = widget.banner!.id;
        await _repo.update(
          _buildBanner(
            id: bannerId,
            imageUrl: imageUrl,
            imageThumbUrl: imageThumbUrl,
          ),
        );
      } else {
        bannerId = await _repo.create(
          _buildBanner(
            id: '',
            imageUrl: imageUrl,
            imageThumbUrl: imageThumbUrl,
          ),
        );
      }

      if (pendingBytes != null) {
        PromoBannerDebug.log(
          'Admin.upload Storage promo_banners/$bannerId/image.jpg '
          'bytes=${pendingBytes.length}',
        );
        if (_isEdit) {
          await ImageUploadService.archiveBeforeReplace(
            entityType: 'promo_banner',
            entityId: bannerId,
            field: 'image',
            imageUrl: widget.banner?.imageUrl,
            thumbUrl: widget.banner?.imageThumbUrl,
          );
        }
        final uploaded = await _uploads.uploadPromoBannerImage(
          bannerId: bannerId,
          bytes: pendingBytes,
        );
        imageUrl = uploaded.fullUrl;
        imageThumbUrl = uploaded.thumbUrl;
        PromoBannerDebug.log(
          'Admin.upload OK fullUrl=${uploaded.fullUrl} '
          'thumbUrl=${uploaded.thumbUrl}',
        );
        await _repo.update(
          _buildBanner(
            id: bannerId,
            imageUrl: uploaded.fullUrl,
            imageThumbUrl: uploaded.thumbUrl,
          ),
        );
      } else {
        PromoBannerDebug.log(
          'Admin.upload SKIPPED — no pending image bytes',
        );
        if (imageUrl == null || imageUrl.trim().isEmpty) {
          PromoBannerDebug.imageIssue(
            bannerId: bannerId,
            reason: 'imageUrl empty/null on save (no upload, no existing url)',
            url: imageUrl,
          );
        }
      }

      final afterBanner = _buildBanner(
        id: bannerId,
        imageUrl: imageUrl,
        imageThumbUrl: imageThumbUrl,
      );
      PromoBannerDebug.dumpLiveStatus(
        record: afterBanner,
        requestedGovernorate: widget.governorate.name,
        now: DateTime.now(),
      );
      await AdminAuditRecord.firestoreEntity(
        action: _isEdit ? AuditAction.update : AuditAction.create,
        entityType: 'promo_banner',
        entityId: bannerId,
        summary:
            '${_isEdit ? 'تعديل' : 'إنشاء'} بانر ${_title.text.trim()} — ${widget.governorate.name}',
        beforeFirestore: beforeFirestore,
        afterFirestore: afterBanner.toFirestore(),
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
    } catch (e, st) {
      PromoBannerDebug.exception(e, st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(FirestoreErrorMessage.from(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    _logForm('build');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'تعديل بانر' : 'بانر جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AdminImagePicker(
              label: 'صورة البانر (1200×560 — تظهر كاملة في التطبيق)',
              uploadKind: ImageUploadKind.promoBanner,
              existingUrl: _imageCleared ? null : _imageUrl,
              pendingBytes: _pendingImageBytes,
              aspectRatio: 1200 / 560,
              onImageChanged: _onImageChanged,
            ),
            const SizedBox(height: 8),
            Text(
              'صمّم البانر بالكامل (نص + صورة) — التطبيق يعرض الصورة كما هي بدون طبقة إضافية.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            PremiumInputField(controller: _title, label: 'العنوان'),
            const SizedBox(height: 12),
            PremiumInputField(controller: _subtitle, label: 'العنوان الفرعي'),
            const SizedBox(height: 12),
            PremiumInputField(controller: _description, label: 'الوصف'),
            const SizedBox(height: 12),
            PremiumInputField(controller: _cta, label: 'نص الزر'),
            const SizedBox(height: 12),
            PremiumInputField(
              controller: _sortOrder,
              label: 'ترتيب العرض',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _deepLinkRoute,
              decoration: const InputDecoration(labelText: 'وجهة الرابط'),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('الرئيسية')),
                DropdownMenuItem(value: 'store', child: Text('متجر')),
                DropdownMenuItem(value: 'category', child: Text('تصنيف')),
                DropdownMenuItem(value: 'product', child: Text('منتج')),
                DropdownMenuItem(value: 'offer', child: Text('عرض')),
                DropdownMenuItem(value: 'search', child: Text('بحث')),
              ],
              onChanged: (value) =>
                  setState(() => _deepLinkRoute = value ?? 'home'),
            ),
            const SizedBox(height: 12),
            PremiumInputField(
              controller: _deepLinkId,
              label: 'معرّف وجهة الرابط',
            ),
            const SizedBox(height: 12),
            PremiumInputField(
              controller: _ctaColor,
              label: 'لون الزر ARGB (اختياري، مثال FFEC6B2D)',
            ),
            const SizedBox(height: 12),
            PremiumInputField(
              controller: _targetCategoryIds,
              label: 'معرّفات التصنيفات المستهدفة (بفاصلة)',
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
            const SizedBox(height: 12),
            _DateTile(
              label: 'تاريخ بدء العرض',
              value: _startsAt,
              onPick: () => _pickDate(start: true),
              onClear: () => setState(() => _startsAt = null),
            ),
            _DateTile(
              label: 'تاريخ انتهاء العرض',
              value: _endsAt,
              onPick: () => _pickDate(start: false),
              onClear: () => setState(() => _endsAt = null),
            ),
            SwitchListTile(
              title: Text('نشط', style: GoogleFonts.cairo()),
              subtitle: Text(
                'يجب أن يكون مفعّلاً ليظهر في التطبيق',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
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

class _DateTile extends StatelessWidget {
  const _DateTile({
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
