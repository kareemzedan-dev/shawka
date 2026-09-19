import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:latlong2/latlong.dart' as ll;
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/theme/app_colors.dart';

class AdminZoneMapPickerScreen extends StatefulWidget {
  const AdminZoneMapPickerScreen({
    super.key,
    required this.governorateId,
    this.initialPolygon,
  });

  final String governorateId;
  final List<LatLng>? initialPolygon;

  @override
  State<AdminZoneMapPickerScreen> createState() =>
      _AdminZoneMapPickerScreenState();
}

class _AdminZoneMapPickerScreenState extends State<AdminZoneMapPickerScreen> {
  final List<ll.LatLng> _points = [];
  final _mapController = MapController();

  static const _maxPoints = 4;

  static const List<Color> _pointColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPolygon != null) {
      for (final p in widget.initialPolygon!.take(_maxPoints)) {
        _points.add(ll.LatLng(p.latitude, p.longitude));
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  ll.LatLng get _initialCenter {
    final c = EgyptGovernorates.centerOf(widget.governorateId);
    return ll.LatLng(c.lat, c.lng);
  }

  void _onTap(_, ll.LatLng pos) {
    if (_points.length >= _maxPoints) return;
    HapticFeedback.selectionClick();
    setState(() => _points.add(pos));
  }

  void _clear() => setState(() => _points.clear());

  void _undoLast() {
    if (_points.isEmpty) return;
    setState(() => _points.removeLast());
  }

  void _confirm() {
    final result = _points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    Navigator.pop(context, result);
  }

  List<Marker> get _markers {
    return [
      for (int i = 0; i < _points.length; i++)
        Marker(
          point: _points[i],
          width: 36,
          height: 36,
          child: Container(
              decoration: BoxDecoration(
                color: _pointColors[i],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
    ];
  }

  List<Polygon> get _polygons {
    if (_points.length < 3) return [];
    return [
      Polygon(
        points: _points,
        color: AppColors.primary.withValues(alpha: 0.18),
        borderColor: AppColors.primary,
        borderStrokeWidth: 3,
      ),
    ];
  }

  List<Polyline> get _polylines {
    if (_points.length < 2) return [];
    return [
      Polyline(
        points: [..._points, if (_points.length >= 3) _points.first],
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تحديد نطاق المنطقة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'نقطة ${_points.length}/$_maxPoints',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'تراجع',
            onPressed: _points.isEmpty ? null : _undoLast,
            icon: const Icon(Icons.undo_rounded, size: 20),
          ),
          TextButton(
            onPressed: _points.isEmpty ? null : _clear,
            child: Text('مسح الكل', style: GoogleFonts.cairo()),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilledButton(
              onPressed: _points.length == _maxPoints ? _confirm : null,
              child: Text('تأكيد', style: GoogleFonts.cairo()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 11,
              onTap: _onTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.xyronix.shawka',
                maxNativeZoom: 19,
              ),
              if (_polygons.isNotEmpty)
                PolygonLayer(polygons: _polygons),
              if (_polylines.isNotEmpty)
                PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),
          if (_points.length < _maxPoints)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _points.isEmpty
                              ? 'اضغط على الخريطة لتحديد النقطة الأولى'
                              : 'اضغط لتحديد النقطة ${_points.length + 1} من $_maxPoints',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
