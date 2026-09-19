import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/admin/screens/admin_zone_map_picker_screen.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/zone.dart';
import 'package:matlobgo/repositories/zone_repository.dart';
import 'package:uuid/uuid.dart';

class AdminZoneFormDialog extends StatefulWidget {
  const AdminZoneFormDialog({
    super.key,
    required this.governorateId,
    this.zone,
  });

  final String governorateId;
  final ServiceZone? zone;

  @override
  State<AdminZoneFormDialog> createState() => _AdminZoneFormDialogState();
}

class _AdminZoneFormDialogState extends State<AdminZoneFormDialog> {
  late final TextEditingController _nameCtrl;
  List<LatLng>? _polygon;
  bool _saving = false;

  bool get _isEditing => widget.zone != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.zone?.name ?? '');
    if (widget.zone != null && widget.zone!.polygon.isNotEmpty) {
      _polygon = List.of(widget.zone!.polygon);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPolygon() async {
    final result = await Navigator.push<List<LatLng>>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminZoneMapPickerScreen(
          governorateId: widget.governorateId,
          initialPolygon: _polygon,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _polygon = result);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _polygon == null || _polygon!.length < 3) return;

    setState(() => _saving = true);
    try {
      final zone = ServiceZone(
        id: widget.zone?.id ?? const Uuid().v4(),
        governorateId: widget.governorateId,
        name: name,
        polygon: _polygon!,
        isActive: widget.zone?.isActive ?? true,
        sortOrder: widget.zone?.sortOrder ?? 0,
      );
      await ZoneRepository().upsert(zone);
      if (mounted) Navigator.pop(context, zone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final polygonSet = _polygon != null && _polygon!.length >= 3;

    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل المنطقة' : 'منطقة جديدة',
        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumInputField(
              controller: _nameCtrl,
              label: 'اسم المنطقة (عربي)',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickPolygon,
              icon: const Icon(Icons.map_outlined),
              label: Text(
                'تحديد على الخريطة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              polygonSet
                  ? 'تم تحديد ${_polygon!.length} نقاط ✓'
                  : 'لم يتم التحديد بعد',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: polygonSet ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEditing ? 'حفظ' : 'إنشاء',
                  style: GoogleFonts.cairo(),
                ),
        ),
      ],
    );
  }
}
