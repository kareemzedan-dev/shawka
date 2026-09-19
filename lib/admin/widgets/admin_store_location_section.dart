import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/admin/screens/admin_store_map_picker_screen.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/matlob_google_map.dart';
import 'package:matlobgo/core/widgets/matlob_osm_map.dart';
import 'package:matlobgo/core/widgets/premium_input_field.dart';
import 'package:matlobgo/models/store.dart';

class AdminStoreLocationSection extends StatelessWidget {
  const AdminStoreLocationSection({
    super.key,
    required this.areaController,
    required this.governorate,
    required this.latitude,
    required this.longitude,
    required this.onLocationChanged,
    this.storeName = 'المتجر',
  });

  final TextEditingController areaController;
  final Governorate governorate;
  final double? latitude;
  final double? longitude;
  final void Function(double? lat, double? lng) onLocationChanged;
  final String storeName;

  bool get _hasGps => latitude != null && longitude != null;

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await openAdminStoreMapPicker(
      context,
      governorate: governorate,
      initialLat: latitude,
      initialLng: longitude,
      storeName: storeName,
    );
    if (result == null) return;
    final fixed = normalizeStoreCoords(result.latitude, result.longitude);
    onLocationChanged(fixed.$1, fixed.$2);
    if (areaController.text.trim().isEmpty &&
        result.formattedAddress.trim().isNotEmpty) {
      areaController.text = result.formattedAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = EgyptGovernorates.centerOfGovernorate(governorate);
    final previewTarget = _hasGps
        ? LatLng(latitude!, longitude!)
        : LatLng(center.lat, center.lng);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'موقع المتجر على الخريطة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                  ),
                ),
                if (_hasGps)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'محدَّد',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'هذه النقطة تُستخدم لحساب تكلفة التوصيل وعرض موقع المتجر للعميل.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            PremiumInputField(
              controller: areaController,
              label: 'المنطقة / الحي',
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(
                      child: kIsWeb
                          ? MatlobOsmMap(
                              key: ValueKey(
                                _hasGps
                                    ? 'osm_${latitude}_$longitude'
                                    : 'osm_preview_${governorate.id}',
                              ),
                              initialLat: previewTarget.latitude,
                              initialLng: previewTarget.longitude,
                              initialZoom: _hasGps ? 15.5 : 12.5,
                              interactive: false,
                              markerLat: _hasGps ? latitude : null,
                              markerLng: _hasGps ? longitude : null,
                            )
                          : MatlobGoogleMap(
                              key: ValueKey(
                                _hasGps
                                    ? '${latitude}_$longitude'
                                    : 'preview_${governorate.id}',
                              ),
                              initialTarget: previewTarget,
                              initialZoom: _hasGps ? 15.5 : 12.5,
                              palette: AppPalette.light,
                              interactive: false,
                              markers: _hasGps
                                  ? {
                                      Marker(
                                        markerId: const MarkerId('store'),
                                        position:
                                            LatLng(latitude!, longitude!),
                                        icon: BitmapDescriptor
                                            .defaultMarkerWithHue(
                                          BitmapDescriptor.hueYellow,
                                        ),
                                      ),
                                    }
                                  : const {},
                            ),
                    ),
                    if (!_hasGps)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.28),
                        child: Center(
                          child: Text(
                            'لم يُحدد موقع GPS بعد',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: FilledButton.icon(
                        onPressed: () => _openMapPicker(context),
                        icon: Icon(
                          _hasGps
                              ? Icons.edit_location_alt_rounded
                              : Icons.add_location_alt_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _hasGps
                              ? 'تعديل النقطة على الخريطة'
                              : 'تحديد النقطة على الخريطة',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_hasGps) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'GPS: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onLocationChanged(null, null),
                    child: Text(
                      'مسح',
                      style: GoogleFonts.cairo(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
