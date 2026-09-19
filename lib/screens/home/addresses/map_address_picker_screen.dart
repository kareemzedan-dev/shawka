import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';
import 'package:matlobgo/core/services/location_service.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/core/theme/cart_typography.dart';
import 'package:matlobgo/core/widgets/matlob_google_map.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/screens/home/widgets/places_search_field.dart';
import 'package:uuid/uuid.dart';

/// شاشة تحديد النقطة على الخريطة — بحث Places + سحب الخريطة + GPS.
Future<DeliveryAddress?> openMapAddressPicker(
  BuildContext context, {
  required Governorate governorate,
  DeliveryAddress? initial,
  String title = 'تحديد الموقع',
}) {
  return Navigator.of(context).push<DeliveryAddress>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MapAddressPickerScreen(
        governorate: governorate,
        initial: initial,
        title: title,
      ),
    ),
  );
}

class MapAddressPickerScreen extends StatefulWidget {
  const MapAddressPickerScreen({
    super.key,
    required this.governorate,
    this.initial,
    this.title = 'تحديد الموقع',
  });

  final Governorate governorate;
  final DeliveryAddress? initial;
  final String title;

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _maps = GoogleMapsApiService();
  final _location = LocationService.instance;
  final _sessionToken = const Uuid().v4();

  GoogleMapController? _mapController;
  late LatLng _cameraTarget;
  PlaceDetails? _place;
  bool _geocoding = false;
  bool _locating = false;
  bool _movingProgrammatically = false;
  String? _error;
  Timer? _idleDebounce;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null && initial.latitude != 0 && initial.longitude != 0) {
      _cameraTarget = LatLng(initial.latitude, initial.longitude);
      _searchController.text = initial.displayLine;
      _notesController.text = initial.buildingNotes;
      _place = PlaceDetails(
        placeId: initial.placeId,
        latitude: initial.latitude,
        longitude: initial.longitude,
        formattedAddress: initial.formattedAddress.isNotEmpty
            ? initial.formattedAddress
            : initial.displayLine,
        area: initial.area,
        street: initial.street,
        governorate: initial.governorate,
      );
    } else {
      final center = EgyptGovernorates.centerOfGovernorate(widget.governorate);
      _cameraTarget = LatLng(center.lat, center.lng);
    }
    unawaited(_bootstrapGps());
  }

  Future<void> _bootstrapGps() async {
    if (widget.initial != null) return;
    try {
      final pos = await _location.getCurrentPositionFast(
        timeout: const Duration(seconds: 8),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      if (!_isInEgypt(target) || !mounted) return;
      await _moveCamera(target, zoom: 16.5);
      await _reverseGeocode(target);
    } catch (_) {
      // نبقى على مركز المحافظة.
    }
  }

  @override
  void dispose() {
    _idleDebounce?.cancel();
    _searchController.dispose();
    _notesController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  bool _isInEgypt(LatLng point) =>
      point.latitude >= 22 &&
      point.latitude <= 31.8 &&
      point.longitude >= 24 &&
      point.longitude <= 37;

  Future<void> _moveCamera(LatLng target, {double zoom = 16}) async {
    _movingProgrammatically = true;
    _cameraTarget = target;
    final c = _mapController;
    if (c != null) {
      await c.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ));
    }
    await Future<void>.delayed(const Duration(milliseconds: 280));
    _movingProgrammatically = false;
  }

  Future<void> _onSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _error = null;
      _searchController.text = suggestion.fullDescription;
      _geocoding = true;
    });
    try {
      final details = await _maps.placeDetails(
        placeId: suggestion.placeId,
        sessionToken: _sessionToken,
      );
      if (!mounted) return;
      setState(() {
        _place = details;
        _geocoding = false;
      });
      await _moveCamera(LatLng(details.latitude, details.longitude), zoom: 17);
      HapticFeedback.selectionClick();
    } on GoogleMapsApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _geocoding = false;
        });
      }
    }
  }

  Future<void> _reverseGeocode(LatLng target) async {
    if (!mounted) return;
    setState(() {
      _geocoding = true;
      _error = null;
    });
    try {
      final details = await _maps
          .reverseGeocode(target)
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _place = details;
        _searchController.text = details.formattedAddress;
        _geocoding = false;
      });
    } on GoogleMapsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _place = PlaceDetails(
          placeId: '',
          latitude: target.latitude,
          longitude: target.longitude,
          formattedAddress: '${widget.governorate.name}، مصر',
          area: widget.governorate.name,
          governorate: widget.governorate.name,
        );
        _searchController.text = _place!.formattedAddress;
        _error = e.message;
        _geocoding = false;
      });
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'انتهت مهلة تحديد العنوان';
          _geocoding = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تحديد العنوان من الخريطة';
          _geocoding = false;
        });
      }
    }
  }

  void _onCameraIdle() {
    if (_movingProgrammatically) return;
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 420), () async {
      final c = _mapController;
      if (c == null || !mounted) return;
      final bounds = await c.getVisibleRegion();
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      _cameraTarget = center;
      if (!_isInEgypt(center)) {
        setState(() => _error = 'الموقع خارج نطاق الخدمة في مصر');
        return;
      }
      await _reverseGeocode(center);
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final pos = await _location.getCurrentPositionFast(
        timeout: const Duration(seconds: 12),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      if (!_isInEgypt(target)) {
        throw const LocationServiceException(
          LocationErrorKind.unknown,
          'الموقع خارج نطاق الخدمة',
        );
      }
      await _moveCamera(target, zoom: 17);
      await _reverseGeocode(target);
      HapticFeedback.mediumImpact();
    } on LocationServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر تحديد موقعك الحالي');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    final place = _place;
    if (place == null || place.latitude == 0 || place.longitude == 0) {
      setState(() => _error = 'حرّك الخريطة أو ابحث لتحديد النقطة بدقة');
      return;
    }
    if (!_isInEgypt(LatLng(place.latitude, place.longitude))) {
      setState(() => _error = 'الموقع خارج نطاق الخدمة');
      return;
    }
    final addr = DeliveryAddress.fromPlaceDetails(
      latitude: place.latitude,
      longitude: place.longitude,
      formattedAddress: place.formattedAddress,
      area: place.area.isNotEmpty ? place.area : widget.governorate.name,
      street: place.street,
      placeId: place.placeId,
      governorate: place.governorate.isNotEmpty
          ? place.governorate
          : widget.governorate.name,
      buildingNotes: _notesController.text.trim(),
    );
    Navigator.of(context).pop(addr);
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: palette.surface,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: MatlobGoogleMap(
              initialTarget: _cameraTarget,
              initialZoom: 15.5,
              myLocationEnabled: true,
              palette: palette,
              onMapCreated: (c) => _mapController = c,
              onCameraIdle: _onCameraIdle,
            ),
          ),
          // دبوس ثابت في منتصف الخريطة
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on_rounded,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 2,
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
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: PlacesSearchField(
                              controller: _searchController,
                              onSuggestionSelected: _onSuggestion,
                              maps: _maps,
                              autofocus: false,
                              hint: 'ابحث عن عنوانك…',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      child: IconButton(
                        onPressed: _locating ? null : _useCurrentLocation,
                        tooltip: 'موقعي الحالي',
                        icon: _locating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: palette.card,
              elevation: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: CartTypography.style(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حرّك الخريطة لضبط الدبوس على باب البيت بالظبط',
                      style: CartTypography.style(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
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
                          if (_geocoding)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(
                              Icons.place_rounded,
                              color: AppColors.primary,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _geocoding
                                  ? 'جاري تحديد العنوان…'
                                  : (_place?.formattedAddress.isNotEmpty == true
                                      ? _place!.formattedAddress
                                      : 'حرّك الخريطة أو ابحث'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: GoogleFonts.cairo(color: palette.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'تفاصيل إضافية (عمارة، دور، شقة)',
                        labelStyle: GoogleFonts.cairo(),
                        filled: true,
                        fillColor: palette.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.cairo(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _geocoding ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'تأكيد الموقع',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
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
