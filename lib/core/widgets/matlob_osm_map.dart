import 'package:flutter/material.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

/// خريطة OpenStreetMap — تعمل على الويب بدون تفعيل Maps JavaScript API.
class MatlobOsmMap extends StatefulWidget {
  const MatlobOsmMap({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.initialZoom = 14,
    this.interactive = true,
    this.showCenterPin = false,
    this.markerLat,
    this.markerLng,
    this.mapController,
    this.onPositionChanged,
  });

  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final bool interactive;
  final bool showCenterPin;
  final double? markerLat;
  final double? markerLng;
  final MapController? mapController;
  final void Function(double lat, double lng)? onPositionChanged;

  @override
  State<MatlobOsmMap> createState() => _MatlobOsmMapState();
}

class _MatlobOsmMapState extends State<MatlobOsmMap> {
  late final MapController _controller =
      widget.mapController ?? MapController();
  bool _ownsController = false;
  bool _programmaticMove = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.mapController == null;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = ll.LatLng(widget.initialLat, widget.initialLng);
    final markerLat = widget.markerLat;
    final markerLng = widget.markerLng;

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: widget.initialZoom,
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
            onMapEvent: (event) {
              if (!widget.interactive) return;
              if (event is MapEventMoveEnd ||
                  event is MapEventFlingAnimationEnd) {
                if (_programmaticMove) {
                  _programmaticMove = false;
                  return;
                }
                final c = _controller.camera.center;
                widget.onPositionChanged?.call(c.latitude, c.longitude);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.xyronix.shawka',
              maxNativeZoom: 19,
            ),
            if (markerLat != null && markerLng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: ll.LatLng(markerLat, markerLng),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (widget.showCenterPin)
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 48,
                  color: AppColors.primary,
                  shadows: [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// تحريك كاميرا OSM.
void moveOsmMap(
  MapController controller, {
  required double lat,
  required double lng,
  double? zoom,
}) {
  controller.move(ll.LatLng(lat, lng), zoom ?? controller.camera.zoom);
}
