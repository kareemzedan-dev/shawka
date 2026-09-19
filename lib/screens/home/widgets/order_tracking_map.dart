import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/config/google_maps_config.dart';
import 'package:matlobgo/core/maps/maps_api_key.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/matlob_google_map.dart';
import 'package:matlobgo/screens/home/order_tracking_ui_data.dart';
import 'package:matlobgo/screens/home/tracking/tracking_map_markers.dart';

/// Hero map — أوضاع متجر/توصيل + موتوسيكل المندوب بعد الاستلام.
class OrderTrackingMap extends StatefulWidget {
  const OrderTrackingMap({
    super.key,
    required this.snapshot,
    required this.palette,
    this.storeName = 'المتجر',
    this.onMapReady,
    this.followDriver = false,
  });

  final OrderTrackingSnapshot snapshot;
  final AppPalette palette;
  final String storeName;
  final VoidCallback? onMapReady;
  final bool followDriver;

  @override
  State<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<OrderTrackingMap>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  Timer? _fitDebounce;
  bool _userMovedCamera = false;
  bool _iconsReady = false;
  LatLng? _lastDriverPos;
  double _driverBearing = 0;
  TrackingMapMode? _lastMode;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    unawaited(_loadIcons());
  }

  Future<void> _loadIcons() async {
    await TrackingMapMarkers.ensureLoaded();
    if (!mounted) return;
    setState(() => _iconsReady = true);
  }

  @override
  void didUpdateWidget(OrderTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final s = widget.snapshot;
    if (s.showDriver) {
      final prev = _lastDriverPos;
      if (prev != null && prev != s.driver) {
        _driverBearing = TrackingMapMarkers.bearingDegrees(prev, s.driver);
      }
      _lastDriverPos = s.driver;
    }

    if (_lastMode != s.mapMode) {
      _lastMode = s.mapMode;
      _userMovedCamera = false;
      _scheduleFitBounds();
    }

    if (widget.followDriver &&
        oldWidget.snapshot.driver != s.driver &&
        s.isLiveDeliveryMode) {
      _animateToDriver();
      return;
    }
    if (oldWidget.snapshot.routePoints.length != s.routePoints.length ||
        oldWidget.snapshot.driver != s.driver ||
        oldWidget.snapshot.showDriver != s.showDriver) {
      if (!_userMovedCamera) _scheduleFitBounds();
    }
  }

  @override
  void dispose() {
    _fitDebounce?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _scheduleFitBounds() {
    _fitDebounce?.cancel();
    _fitDebounce = Timer(const Duration(milliseconds: 420), () {
      if (mounted && !_userMovedCamera) _fitBounds();
    });
  }

  void _animateToDriver() {
    final c = _controller;
    if (c == null || !widget.snapshot.showDriver) return;
    c.animateCamera(
      CameraUpdate.newLatLngZoom(widget.snapshot.driver, 15.8),
    );
  }

  void _fitBounds({bool animated = true}) {
    final c = _controller;
    if (c == null) return;
    final s = widget.snapshot;
    final points = <LatLng>[
      s.customer,
      if (!s.isLiveDeliveryMode) s.store,
      if (s.showDriver) s.driver,
      ...s.routePoints,
      if (!s.isLiveDeliveryMode) ...s.secondaryRoutePoints,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      c.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final update = CameraUpdate.newLatLngBounds(bounds, 64);
    if (animated) {
      c.animateCamera(update);
    } else {
      c.moveCamera(update);
    }
  }

  void _zoomBy(double delta) {
    _controller?.animateCamera(CameraUpdate.zoomBy(delta));
  }

  Set<Marker> _markers() {
    final s = widget.snapshot;
    final storeName =
        s.storeLabel.trim().isNotEmpty ? s.storeLabel : widget.storeName;

    if (s.isLiveDeliveryMode) {
      return {
        Marker(
          markerId: const MarkerId('customer'),
          position: s.customer,
          icon: TrackingMapMarkers.customer,
          infoWindow: const InfoWindow(title: 'نقطة التوصيل', snippet: 'موقعك'),
          zIndexInt: 1,
        ),
        if (s.showDriver)
          Marker(
            markerId: const MarkerId('driver'),
            position: s.driver,
            icon: _pulse.value > 0.55
                ? TrackingMapMarkers.motorcyclePulse
                : TrackingMapMarkers.motorcycle,
            rotation: _driverBearing,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            infoWindow: const InfoWindow(
              title: 'المندوب',
              snippet: 'تتبع مباشر',
            ),
            zIndexInt: 3,
          ),
      };
    }

    return {
      Marker(
        markerId: const MarkerId('store'),
        position: s.store,
        icon: TrackingMapMarkers.store,
        infoWindow: InfoWindow(title: 'المتجر', snippet: storeName),
        zIndexInt: 1,
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: s.customer,
        icon: TrackingMapMarkers.customer,
        infoWindow: const InfoWindow(title: 'التوصيل', snippet: 'موقعك'),
        zIndexInt: 2,
      ),
    };
  }

  Set<Polyline> _polylines() {
    final s = widget.snapshot;
    final set = <Polyline>{};

    if (!s.isLiveDeliveryMode) {
      // خط تقريبي متجر → توصيل قبل الاستلام
      set.add(
        Polyline(
          polylineId: const PolylineId('preview_store_customer'),
          points: [s.store, s.customer],
          color: AppColors.navy.withValues(alpha: 0.28),
          width: 3,
          patterns: [PatternItem.dash(16), PatternItem.gap(10)],
          geodesic: true,
        ),
      );
    }

    if (s.secondaryRoutePoints.length >= 2 && !s.isLiveDeliveryMode) {
      set.add(
        Polyline(
          polylineId: const PolylineId('route_store_driver'),
          points: s.secondaryRoutePoints,
          color: AppColors.navy.withValues(alpha: 0.45),
          width: 4,
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          geodesic: false,
        ),
      );
    }
    if (s.routePoints.length >= 2) {
      set.add(
        Polyline(
          polylineId: const PolylineId('route_primary'),
          points: s.routePoints,
          color: AppColors.primary,
          width: 5,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
          jointType: JointType.round,
          geodesic: false,
        ),
      );
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            MatlobGoogleMap(
              initialTarget: s.isLiveDeliveryMode ? s.customer : s.store,
              initialZoom: 13.4,
              markers: _iconsReady ? _markers() : const {},
              polylines: _polylines(),
              palette: widget.palette,
              onMapCreated: (controller) {
                _controller = controller;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitBounds(animated: false);
                  widget.onMapReady?.call();
                });
              },
              onCameraIdle: () => _userMovedCamera = true,
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _MapLegend(live: s.isLiveDeliveryMode),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapControlButton(
                    icon: Icons.add_rounded,
                    onTap: () => _zoomBy(0.8),
                  ),
                  const SizedBox(height: 6),
                  _MapControlButton(
                    icon: Icons.remove_rounded,
                    onTap: () => _zoomBy(-0.8),
                  ),
                  const SizedBox(height: 6),
                  _MapControlButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      setState(() => _userMovedCamera = false);
                      if (widget.followDriver && s.isLiveDeliveryMode) {
                        _animateToDriver();
                      } else {
                        _fitBounds();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              live ? 'التتبع المباشر' : 'نقاط الطلب',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            if (live) ...[
              const _LegendRow(
                color: AppColors.primary,
                icon: Icons.two_wheeler_rounded,
                label: 'المندوب',
              ),
              const SizedBox(height: 6),
              const _LegendRow(
                color: AppColors.navy,
                icon: Icons.home_rounded,
                label: 'نقطة التوصيل',
              ),
            ] else ...[
              const _LegendRow(
                color: AppColors.primary,
                icon: Icons.storefront_rounded,
                label: 'المتجر',
              ),
              const SizedBox(height: 6),
              const _LegendRow(
                color: AppColors.navy,
                icon: Icons.home_rounded,
                label: 'نقطة التوصيل',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: AppColors.navy),
        ),
      ),
    );
  }
}

/// Fallback when Maps API key is not configured.
class OrderTrackingMapPlaceholder extends StatelessWidget {
  const OrderTrackingMapPlaceholder({
    super.key,
    required this.snapshot,
    required this.palette,
  });

  final OrderTrackingSnapshot snapshot;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _MapPlaceholder(
      snapshot: snapshot,
      palette: palette,
      showSetupHint: !GoogleMapsConfig.isConfigured && !MapsApiKey.isReady,
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.snapshot,
    required this.palette,
    required this.showSetupHint,
  });

  final OrderTrackingSnapshot snapshot;
  final AppPalette palette;
  final bool showSetupHint;

  @override
  Widget build(BuildContext context) {
    final live = snapshot.isLiveDeliveryMode;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: palette.isDark
              ? [const Color(0xFF111827), const Color(0xFF0B1220)]
              : [const Color(0xFFE8EDF5), const Color(0xFFF8F9FC)],
        ),
      ),
      child: Stack(
        children: [
          if (!live)
            Positioned(
              left: 28,
              top: 56,
              child: _Pin(
                label: '🏪',
                caption: 'المتجر',
                palette: palette,
                color: AppColors.primary,
              ),
            ),
          Positioned(
            right: 28,
            bottom: 64,
            child: _Pin(
              label: '🏠',
              caption: 'التوصيل',
              palette: palette,
              color: AppColors.navy,
            ),
          ),
          if (live && snapshot.showDriver)
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.42,
              top: MediaQuery.sizeOf(context).height * 0.22,
              child: _Pin(
                label: '🛵',
                caption: 'المندوب',
                palette: palette,
                color: AppColors.primary,
                accent: true,
              ),
            ),
          if (showSetupHint)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.card.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'شغّل configure-google-maps.ps1 وفعّل Places/Directions API',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.label,
    required this.caption,
    required this.palette,
    required this.color,
    this.accent = false,
  });

  final String label;
  final String caption;
  final AppPalette palette;
  final Color color;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(label, style: TextStyle(fontSize: accent ? 22 : 18)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            caption,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }
}
