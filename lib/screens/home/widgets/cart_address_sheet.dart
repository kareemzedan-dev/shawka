import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/models/store.dart';

/// Bottom sheet لإدخال/تعديل عنوان التوصيل.
Future<({String area, String street})?> showCartAddressSheet(
  BuildContext context, {
  required Governorate governorate,
  String areaLine = '',
  String streetLine = '',
}) {
  return showModalBottomSheet<({String area, String street})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CartAddressSheetBody(
      governorate: governorate,
      initialArea: areaLine,
      initialStreet: streetLine,
    ),
  );
}

class _CartAddressSheetBody extends StatefulWidget {
  const _CartAddressSheetBody({
    required this.governorate,
    required this.initialArea,
    required this.initialStreet,
  });

  final Governorate governorate;
  final String initialArea;
  final String initialStreet;

  @override
  State<_CartAddressSheetBody> createState() => _CartAddressSheetBodyState();
}

class _CartAddressSheetBodyState extends State<_CartAddressSheetBody> {
  late final TextEditingController _areaController;
  late final TextEditingController _streetController;

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(
      text: widget.initialArea.isNotEmpty
          ? widget.initialArea
          : widget.governorate.name,
    );
    _streetController = TextEditingController(text: widget.initialStreet);
  }

  @override
  void dispose() {
    _areaController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _save() {
    final street = _streetController.text.trim();
    if (street.isEmpty) return;
    Navigator.pop(
      context,
      (area: _areaController.text.trim(), street: street),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'عنوان التوصيل',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _areaController,
              style: GoogleFonts.cairo(color: palette.textPrimary),
              decoration: InputDecoration(
                labelText: 'المنطقة',
                hintText: 'مثال: القاهرة - مدينة نصر',
                labelStyle: GoogleFonts.cairo(),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _streetController,
              maxLines: 2,
              style: GoogleFonts.cairo(color: palette.textPrimary),
              decoration: InputDecoration(
                labelText: 'الشارع والتفاصيل',
                hintText: 'مثال: شارع عباس العقاد، مبنى 12',
                labelStyle: GoogleFonts.cairo(),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'حفظ العنوان',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
