import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/data/egypt_places_catalog.dart';
import 'package:matlobgo/core/maps/egypt_geocode_service.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/widgets/matlob_osm_map.dart';
import 'package:matlobgo/models/store.dart';

/// نتيجة تحديد موقع المتجر من لوحة التحكم.
class AdminStoreMapPickResult {
  const AdminStoreMapPickResult({
    required this.latitude,
    required this.longitude,
    this.formattedAddress = '',
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
}

/// شاشة كاملة — تحديد نقطة المتجر (OSM + بحث جغرافي).
Future<AdminStoreMapPickResult?> openAdminStoreMapPicker(
  BuildContext context, {
  required Governorate governorate,
  double? initialLat,
  double? initialLng,
  String storeName = 'المتجر',
}) {
  return Navigator.of(context, rootNavigator: true).push<AdminStoreMapPickResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AdminStoreMapPickerScreen(
        governorate: governorate,
        initialLat: initialLat,
        initialLng: initialLng,
        storeName: storeName,
      ),
    ),
  );
}

class AdminStoreMapPickerScreen extends StatefulWidget {
  const AdminStoreMapPickerScreen({
    super.key,
    required this.governorate,
    this.initialLat,
    this.initialLng,
    this.storeName = 'المتجر',
  });

  final Governorate governorate;
  final double? initialLat;
  final double? initialLng;
  final String storeName;

  @override
  State<AdminStoreMapPickerScreen> createState() =>
      _AdminStoreMapPickerScreenState();
}

class _AdminStoreMapPickerScreenState extends State<AdminStoreMapPickerScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _osmController = MapController();
  final _geocoder = EgyptGeocodeService();

  late double _lat;
  late double _lng;
  String _addressLabel = '';
  bool _movingProgrammatically = false;
  bool _searching = false;
  List<EgyptGeocodeHit> _hits = const [];
  String? _searchError;
  Timer? _moveDebounce;
  Timer? _searchDebounce;
  int _searchSeq = 0;

  List<EgyptPlaceHit> get _quickPlaces {
    final ids = <String>{
      widget.governorate.id,
      'cairo',
      'giza',
      'alex',
      'beni_suef',
      'fayoum',
      'minya',
      'asyut',
    };
    return [
      for (final id in ids)
        if (EgyptGovernorates.byId(id) != null)
          EgyptPlaceHit(
            name: EgyptGovernorates.byId(id)!.name,
            lat: EgyptGovernorates.centerOf(id).lat,
            lng: EgyptGovernorates.centerOf(id).lng,
            subtitle: 'محافظة',
          ),
    ];
  }

  bool get _showHitsPanel =>
      _searchController.text.trim().length >= 2 &&
      (_searching || _hits.isNotEmpty || _searchError != null);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      final n = normalizeStoreCoords(widget.initialLat!, widget.initialLng!);
      _lat = n.$1;
      _lng = n.$2;
    } else {
      final c = EgyptGovernorates.centerOfGovernorate(widget.governorate);
      _lat = c.lat;
      _lng = c.lng;
    }
    _addressLabel = '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}';
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _osmController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _searchDebounce?.cancel();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _hits = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }

    // نتائج محلية فورية أثناء الكتابة
    final local = EgyptPlacesCatalog.search(q, limit: 8)
        .map(
          (p) => EgyptGeocodeHit(
            lat: p.lat,
            lng: p.lng,
            title: p.name,
            subtitle: p.subtitle.isEmpty ? 'مصر' : p.subtitle,
            source: 'local',
          ),
        )
        .toList();
    setState(() {
      _hits = local;
      _searching = true;
      _searchError = null;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_runRemoteSearch(q));
    });
  }

  Future<void> _runRemoteSearch(String query) async {
    final seq = ++_searchSeq;
    try {
      final hits = await _geocoder.search(
        query,
        biasLat: _lat,
        biasLng: _lng,
        limit: 12,
      );
      if (!mounted || seq != _searchSeq) return;
      if (_searchController.text.trim() != query) return;
      setState(() {
        _hits = hits;
        _searching = false;
        _searchError = hits.isEmpty
            ? 'لا توجد نتائج — جرّب اسم أوضح أو حرّك الخريطة'
            : null;
      });
    } catch (e) {
      debugPrint('Admin geocode failed: $e');
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searching = false;
        if (_hits.isEmpty) {
          _searchError = 'تعذّر البحث — جرّب زر محافظة سريعة';
        }
      });
    }
  }

  Future<void> _goTo(double lat, double lng, String label, {double zoom = 15}) async {
    _searchFocus.unfocus();
    setState(() {
      _hits = const [];
      _searchError = null;
      _searching = false;
      _searchController.text = label;
      _addressLabel = label;
    });
    await _moveCamera(lat, lng, zoom: zoom);
    HapticFeedback.selectionClick();
  }

  Future<void> _selectHit(EgyptGeocodeHit hit) async {
    final label =
        hit.subtitle.isEmpty ? hit.title : '${hit.title} — ${hit.subtitle}';
    // زووم أقرب للشوارع، وأوسع للمحافظات
    final zoom = hit.source == 'local' && hit.subtitle == 'محافظة' ? 13.5 : 16.5;
    await _goTo(hit.lat, hit.lng, label, zoom: zoom);
  }

  Future<void> _moveCamera(double lat, double lng, {double zoom = 16.5}) async {
    _movingProgrammatically = true;
    setState(() {
      _lat = lat;
      _lng = lng;
    });
    moveOsmMap(_osmController, lat: lat, lng: lng, zoom: zoom);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    _movingProgrammatically = false;
  }

  void _onPositionChanged(double lat, double lng) {
    if (_movingProgrammatically) return;
    final n = normalizeStoreCoords(lat, lng);
    _lat = n.$1;
    _lng = n.$2;
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _addressLabel =
            '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}';
      });
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _hits = const [];
      _searching = false;
      _searchError = null;
    });
  }

  void _confirm() {
    final n = normalizeStoreCoords(_lat, _lng);
    Navigator.of(context).pop(
      AdminStoreMapPickResult(
        latitude: n.$1,
        longitude: n.$2,
        formattedAddress: _addressLabel,
      ),
    );
  }

  Future<void> _submitFirstHit() async {
    if (_hits.isNotEmpty) {
      await _selectHit(_hits.first);
      return;
    }
    final q = _searchController.text.trim();
    if (q.length < 2) return;
    setState(() => _searching = true);
    await _runRemoteSearch(q);
    if (_hits.isNotEmpty) await _selectHit(_hits.first);
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: palette.surface,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: MatlobOsmMap(
              initialLat: _lat,
              initialLng: _lng,
              initialZoom: 15.5,
              showCenterPin: true,
              mapController: _osmController,
              onPositionChanged: _onPositionChanged,
            ),
          ),

          Positioned(
            top: topPad + 8,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 3,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 3,
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onChanged: _onSearchChanged,
                            onSubmitted: (_) => unawaited(_submitFirstHit()),
                            textInputAction: TextInputAction.search,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن أي مكان: شارع، مول، مدينة…',
                              hintStyle: GoogleFonts.cairo(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : (_searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded),
                                          onPressed: _clearSearch,
                                        )
                                      : null),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickPlaces.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final p = _quickPlaces[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => unawaited(
                            _goTo(p.lat, p.lng, p.name, zoom: 13.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text(
                              p.name,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_showHitsPanel) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.white,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: _searching && _hits.isEmpty
                          ? const SizedBox(
                              height: 56,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : _hits.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    _searchError ?? 'لا توجد نتائج',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _hits.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final hit = _hits[i];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.place_outlined,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(
                                        hit.title,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: hit.subtitle.isEmpty
                                          ? null
                                          : Text(
                                              hit.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                      onTap: () => unawaited(_selectHit(hit)),
                                    );
                                  },
                                ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: palette.card,
              elevation: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تحديد موقع «${widget.storeName}»',
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ابحث عن المكان ثم اضغط النتيجة — الخريطة تنتقل إليه مباشرة',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _addressLabel.isEmpty
                                  ? 'حرّك الخريطة أو ابحث'
                                  : _addressLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 8),
                      Text(
                        'اكتب اسم المكان واضغط النتيجة أو Enter للانتقال إليه',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        'حفظ موقع المتجر',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

/// تصحيح إحداثيات مصر المقلوبة (شائع في البيانات القديمة).
(double, double) normalizeStoreCoords(double lat, double lng) {
  bool inEg(double a, double b) =>
      a >= 21.5 && a <= 31.8 && b >= 24.5 && b <= 37.0;

  if (lat >= 31.15 && lat <= 31.40 && lng >= 29.98 && lng <= 30.25) {
    return (lng, lat);
  }

  final ab = inEg(lat, lng);
  final ba = inEg(lng, lat);
  if (ab && ba) {
    final looksLikeAlex =
        lat >= 30.9 && lat <= 31.4 && lng >= 29.6 && lng <= 30.1;
    if (!looksLikeAlex && lat > lng) return (lng, lat);
    return (lat, lng);
  }
  if (ab) return (lat, lng);
  if (ba) return (lng, lat);
  return (lat, lng);
}
