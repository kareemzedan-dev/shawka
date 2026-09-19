import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/maps/google_maps_web_loader.dart';
import 'package:matlobgo/core/maps/map_styles.dart';
import 'package:matlobgo/core/maps/maps_api_key.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';

/// Google Map موحّد — أنماط فاتح/داكن وتقليل إعادة البناء.
class MatlobGoogleMap extends StatefulWidget {
  const MatlobGoogleMap({
    super.key,
    required this.initialTarget,
    this.initialZoom = 14,
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.onMapCreated,
    this.onCameraIdle,
    this.myLocationEnabled = false,
    this.padding = EdgeInsets.zero,
    this.interactive = true,
    this.palette,
    this.onTap,
  });

  final LatLng initialTarget;
  final double initialZoom;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final void Function(GoogleMapController controller)? onMapCreated;
  final VoidCallback? onCameraIdle;
  final bool myLocationEnabled;
  final EdgeInsets padding;
  final bool interactive;
  final AppPalette? palette;
  final void Function(LatLng position)? onTap;

  @override
  State<MatlobGoogleMap> createState() => _MatlobGoogleMapState();
}

class _MatlobGoogleMapState extends State<MatlobGoogleMap> {
  bool _webReady = !kIsWeb;
  bool _webFailed = false;

  bool get _isDark =>
      widget.palette?.isDark ?? Theme.of(context).brightness == Brightness.dark;

  String get _mapStyle => _isDark ? MapStyles.dark : MapStyles.light;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      unawaited(_prepareWeb());
    }
  }

  Future<void> _prepareWeb() async {
    try {
      final key = await MapsApiKey.resolve();
      final ok = await ensureGoogleMapsJsLoaded(key);
      if (!mounted) return;
      setState(() {
        _webReady = ok;
        _webFailed = !ok;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _webReady = false;
        _webFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !_webReady) {
      return ColoredBox(
        color: const Color(0xFFE8EEF4),
        child: Center(
          child: _webFailed
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'تعذّر تحميل الخريطة على الويب.\nفعّل Maps JavaScript API واسمح بـ localhost للمفتاح.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : const CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }

    return RepaintBoundary(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialTarget,
          zoom: widget.initialZoom,
        ),
        markers: widget.markers,
        polylines: widget.polylines,
        polygons: widget.polygons,
        style: _mapStyle,
        padding: widget.padding,
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        liteModeEnabled: false,
        scrollGesturesEnabled: widget.interactive,
        zoomGesturesEnabled: widget.interactive,
        rotateGesturesEnabled: widget.interactive,
        tiltGesturesEnabled: widget.interactive,
        onCameraIdle: widget.onCameraIdle,
        onTap: widget.onTap,
        onMapCreated: widget.onMapCreated,
      ),
    );
  }
}
