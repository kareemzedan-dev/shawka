import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/widgets/premium_background.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/saved_address_repository.dart';
import 'package:matlobgo/screens/home/addresses/map_address_picker_screen.dart';
import 'package:matlobgo/services/delivery_address_session.dart';

/// شاشة عناوين العميل — عرض / إضافة / تعديل / حذف / افتراضي.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({
    super.key,
    required this.user,
    required this.governorate,
    this.selectionMode = false,
  });

  final AppUser user;
  final Governorate governorate;

  /// عند التفعيل: الضغط على عنوان يرجّعه للاختيار (إتمام الطلب).
  final bool selectionMode;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _repo = SavedAddressRepository();
  StreamSubscription<List<SavedAddress>>? _sub;
  List<SavedAddress> _addresses = const [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _sub = _repo.watch(widget.user.uid).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _addresses = list;
          _loading = false;
          _error = null;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'تعذّر تحميل العناوين';
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _addOrEdit({SavedAddress? existing}) async {
    final picked = await openMapAddressPicker(
      context,
      governorate: widget.governorate,
      initial: existing?.address,
      title: existing == null ? 'إضافة عنوان' : 'تعديل العنوان',
    );
    if (picked == null || !mounted) return;

    final label = await _pickLabel(
      initial: existing?.label ?? SavedAddressLabel.home,
      setAsDefault: existing?.isDefault ?? _addresses.isEmpty,
    );
    if (label == null || !mounted) return;

    try {
      await _repo.save(
        userId: widget.user.uid,
        label: label.label,
        address: picked.copyWith(label: label.label.displayName),
        addressId: existing?.id,
        setDefault: label.setDefault,
      );
      DeliveryAddressSession.instance.setAddress(picked);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'تم حفظ العنوان' : 'تم تحديث العنوان',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.selectionMode && existing == null) {
        Navigator.of(context).pop(picked);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر حفظ العنوان',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<({SavedAddressLabel label, bool setDefault})?> _pickLabel({
    required SavedAddressLabel initial,
    required bool setAsDefault,
  }) async {
    var selected = initial;
    var asDefault = setAsDefault;
    return showModalBottomSheet<({SavedAddressLabel label, bool setDefault})>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette =
            Theme.of(ctx).extension<AppPalette>() ?? AppPalette.light;
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تسمية العنوان',
                    style: CartTypography.style(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SavedAddressLabel.values.map((l) {
                      final on = selected == l;
                      return ChoiceChip(
                        selected: on,
                        label: Text(
                          '${l.icon} ${l.displayName}',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                        onSelected: (_) => setModal(() => selected = l),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'تعيين كعنوان افتراضي',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    value: asDefault,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setModal(() => asDefault = v),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      (label: selected, setDefault: asDefault),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'حفظ',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
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

  Future<void> _setDefault(SavedAddress saved) async {
    setState(() => _busyId = saved.id);
    try {
      await _repo.setDefault(widget.user.uid, saved.id);
      DeliveryAddressSession.instance.setAddress(saved.address);
      HapticFeedback.selectionClick();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(SavedAddress saved) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف العنوان؟', style: GoogleFonts.cairo()),
        content: Text(
          'سيتم حذف «${saved.label.displayName}» نهائياً.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyId = saved.id);
    try {
      await _repo.delete(widget.user.uid, saved.id);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _select(SavedAddress saved) {
    DeliveryAddressSession.instance.setAddress(saved.address);
    if (widget.selectionMode) {
      Navigator.of(context).pop(saved.address);
      return;
    }
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم اختيار ${saved.label.displayName} للتوصيل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

    return Scaffold(
      backgroundColor: PremiumBackground.scaffoldColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          widget.selectionMode ? 'اختر عنوان التوصيل' : 'عناويني',
          style: CartTypography.style(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'إضافة عنوان',
            onPressed: () => _addOrEdit(),
            icon: const Icon(Icons.add_location_alt_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'إضافة عنوان',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: CartTypography.style(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : _addresses.isEmpty
                  ? _EmptyAddresses(onAdd: () => _addOrEdit())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _addresses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _addresses[index];
                        final busy = _busyId == item.id;
                        return _AddressCard(
                          palette: palette,
                          saved: item,
                          busy: busy,
                          selectionMode: widget.selectionMode,
                          onTap: () => _select(item),
                          onEdit: () => _addOrEdit(existing: item),
                          onDefault: () => _setDefault(item),
                          onDelete: () => _delete(item),
                        );
                      },
                    ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد عناوين محفوظة',
              style: CartTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف عنوانك على الخريطة مرة واحدة واستخدمه في كل طلب',
              textAlign: TextAlign.center,
              style: CartTypography.style(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text(
                'إضافة عنوان على الخريطة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.palette,
    required this.saved,
    required this.busy,
    required this.selectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onDefault,
    required this.onDelete,
  });

  final AppPalette palette;
  final SavedAddress saved;
  final bool busy;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.card,
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      saved.label.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                saved.label.displayName,
                                style: CartTypography.style(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            if (saved.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'افتراضي',
                                  style: CartTypography.style(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          saved.address.displayLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CartTypography.style(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                        if (saved.address.buildingNotes.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            saved.address.buildingNotes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (selectionMode)
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.navy,
                    ),
                ],
              ),
              if (!selectionMode) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: busy ? null : onEdit,
                      child: Text(
                        'تعديل',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!saved.isDefault)
                      TextButton(
                        onPressed: busy ? null : onDefault,
                        child: Text(
                          'افتراضي',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: busy ? null : onDelete,
                      tooltip: 'حذف',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
