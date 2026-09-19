import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/admin/widgets/admin_empty_state.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/matlob_google_map.dart';
import 'package:matlobgo/models/app_user.dart';

class AdminDriverMapPanel extends StatelessWidget {
  const AdminDriverMapPanel({
    super.key,
    required this.drivers,
  });

  final List<AppUser> drivers;

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AdminEmptyState(
            icon: Icons.delivery_dining_outlined,
            message: 'لا يوجد مندوبون متصلون بموقع GPS حالياً',
          ),
        ),
      );
    }

    final initial = LatLng(drivers.first.latitude!, drivers.first.longitude!);
    final markers = <Marker>{};
    for (final d in drivers) {
      if (d.latitude == null || d.longitude == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId(d.uid),
          position: LatLng(d.latitude!, d.longitude!),
          infoWindow: InfoWindow(
            title: d.name.isEmpty ? 'مندوب' : d.name,
            snippet: d.avgDriverRating > 0
                ? '⭐ ${d.avgDriverRating.toStringAsFixed(1)}'
                : 'متصل الآن',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 280,
        child: MatlobGoogleMap(
          initialTarget: initial,
          initialZoom: 12,
          markers: markers,
          palette: AppPalette.light,
        ),
      ),
    );
  }
}
