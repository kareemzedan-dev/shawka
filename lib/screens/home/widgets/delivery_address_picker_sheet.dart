import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matlobgo/core/services/location_service.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/delivery_address.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/saved_address_repository.dart';
import 'package:matlobgo/repositories/store_repository.dart';
import 'package:matlobgo/screens/home/addresses/map_address_picker_screen.dart';
import 'package:matlobgo/screens/home/widgets/places_search_field.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:matlobgo/services/cart_service.dart';
import 'package:matlobgo/services/delivery_pricing_service.dart';
import 'package:uuid/uuid.dart';

/// اختيار عنوان توصيل احترافي — Places + GPS + عناوين محفوظة.
Future<DeliveryAddress?> showDeliveryAddressPicker(
  BuildContext context, {
  required Governorate governorate,
  required CartService cartService,
  DeliveryAddress? initial,
  AppUser? user,
}) {
  return showModalBottomSheet<DeliveryAddress>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DeliveryAddressPickerSheet(
      governorate: governorate,
      cartService: cartService,
      initial: initial,
      user: user,
    ),
  );
}

class _DeliveryAddressPickerSheet extends StatefulWidget {
  const _DeliveryAddressPickerSheet({
    required this.governorate,
    required this.cartService,
    this.initial,
    this.user,
  });

  final Governorate governorate;
  final CartService cartService;
  final DeliveryAddress? initial;
  final AppUser? user;

  @override
  State<_DeliveryAddressPickerSheet> createState() =>
      _DeliveryAddressPickerSheetState();
}

class _DeliveryAddressPickerSheetState extends State<_DeliveryAddressPickerSheet> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _maps = GoogleMapsApiService();
  final _location = LocationService.instance;
  final _pricing = DeliveryPricingService();
  final _savedRepo = SavedAddressRepository();
  final _storeRepo = StoreRepository();
  final _sessionToken = const Uuid().v4();

  DeliveryAddress? _selected;
  List<SavedAddress> _saved = const [];
  bool _locating = false;
  bool _quoteLoading = false;
  bool _saving = false;
  String? _error;
  double? _previewDistanceKm;
  int? _previewEta;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    if (_selected != null) {
      _searchController.text = _selected!.displayLine;
    }
    _notesController.text = widget.initial?.buildingNotes ?? '';
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final uid = widget.user?.uid ?? '';
    if (uid.isEmpty) return;
    final list = await _savedRepo.fetch(uid);
    if (mounted) setState(() => _saved = list);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _error = null;
      _searchController.text = suggestion.fullDescription;
    });
    try {
      final details = await _maps.placeDetails(
        placeId: suggestion.placeId,
        sessionToken: _sessionToken,
      );
      await _applyDetails(details);
    } on GoogleMapsApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _applyDetails(PlaceDetails d) async {
    final addr = DeliveryAddress.fromPlaceDetails(
      latitude: d.latitude,
      longitude: d.longitude,
      formattedAddress: d.formattedAddress,
      area: d.area.isNotEmpty ? d.area : widget.governorate.name,
      street: d.street,
      placeId: d.placeId,
      governorate: d.governorate.isNotEmpty
          ? d.governorate
          : widget.governorate.name,
      buildingNotes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _selected = addr;
      _error = null;
      _quoteLoading = true;
      _previewDistanceKm = null;
      _previewEta = null;
    });
    unawaited(_refreshQuoteInBackground(addr));
  }

  Future<LatLng> _requireCurrentCoordinates() async {
    final pos = await _location.getCurrentPositionFast(
      timeout: const Duration(seconds: 12),
    );
    final candidate = LatLng(pos.latitude, pos.longitude);
    if (!_isInEgypt(candidate)) {
      throw const LocationServiceException(
        LocationErrorKind.unknown,
        'الموقع خارج نطاق الخدمة — اختر عنواناً من الخريطة أو البحث',
      );
    }
    return candidate;
  }

  bool _isInEgypt(LatLng point) =>
      point.latitude >= 22 &&
      point.latitude <= 31.8 &&
      point.longitude >= 24 &&
      point.longitude <= 37;

  Future<void> _openMapPicker() async {
    final picked = await openMapAddressPicker(
      context,
      governorate: widget.governorate,
      initial: _selected,
      title: 'تحديد عنوان التوصيل',
    );
    if (picked == null || !mounted) return;
    _searchController.text = picked.displayLine;
    if (picked.buildingNotes.isNotEmpty) {
      _notesController.text = picked.buildingNotes;
    }
    setState(() {
      _selected = picked;
      _error = null;
      _quoteLoading = true;
      _previewDistanceKm = null;
      _previewEta = null;
    });
    unawaited(_refreshQuoteInBackground(picked));
    HapticFeedback.selectionClick();
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final coords = await _requireCurrentCoordinates();
      PlaceDetails details;
      try {
        details = await _maps
            .reverseGeocode(coords)
            .timeout(const Duration(seconds: 12));
      } on GoogleMapsApiException {
        details = PlaceDetails(
          placeId: '',
          latitude: coords.latitude,
          longitude: coords.longitude,
          formattedAddress: '${widget.governorate.name}، مصر',
          area: widget.governorate.name,
          governorate: widget.governorate.name,
        );
      }
      if (!mounted) return;
      _searchController.text = details.formattedAddress;
      setState(() => _locating = false);
      await _applyDetails(details);
      HapticFeedback.mediumImpact();
    } on LocationServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'انتهت مهلة تحديد العنوان — حاول مرة أخرى');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر تحديد موقعك');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _refreshQuoteInBackground(DeliveryAddress addr) async {
    if (!addr.isValid) return;
    if (_quoteLoading && _previewDistanceKm != null) return;
    setState(() => _quoteLoading = true);
    try {
      final storeIds = widget.cartService.items.map((e) => e.storeId).toSet();
      final stores = <Store>[];
      for (final id in storeIds) {
        final s = await _storeRepo.getStore(id);
        if (s != null) stores.add(s);
      }
      final quote = await _pricing
          .quote(
            customer: addr,
            stores: stores.isNotEmpty
                ? stores
                : [
                    Store(
                      id: '_preview',
                      name: widget.governorate.name,
                      categoryId: '',
                      rating: 0,
                      deliveryMinutes: 30,
                      deliveryFee: 0,
                      fallbackOpen: true,
                      tags: const [],
                      governorate: widget.governorate.name,
                      latitude: AppConfigService.instance.settings.deliveryZoneLat,
                      longitude: AppConfigService.instance.settings.deliveryZoneLng,
                    ),
                  ],
            settings: AppConfigService.instance.settings,
            cartSubtotal: widget.cartService.subtotal,
            logAnalytics: false,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (!quote.isInZone) {
        setState(() {
          _selected = addr.copyWith(outOfZone: true);
          _previewDistanceKm =
              quote.distanceKm > 0 ? quote.distanceKm : null;
          _previewEta = null;
          _error = quote.outOfZoneMessage.isNotEmpty
              ? quote.outOfZoneMessage
              : DeliveryQuote.outOfZoneMessageDefault;
        });
      } else {
        setState(() {
          _selected = addr.copyWith(outOfZone: false);
          _previewDistanceKm = quote.distanceKm;
          _previewEta = quote.etaMinutes;
          _error = null;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'انتهت مهلة حساب المسافة — حاول مرة أخرى');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر حساب مسافة التوصيل');
      }
    } finally {
      if (mounted) setState(() => _quoteLoading = false);
    }
  }

  Future<void> _selectSaved(SavedAddress saved) async {
    HapticFeedback.selectionClick();
    final addr = saved.address.copyWith(
      buildingNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : saved.address.buildingNotes,
    );
    _searchController.text = addr.displayLine;
    setState(() {
      _selected = addr;
      _quoteLoading = true;
      _previewDistanceKm = null;
      _previewEta = null;
    });
    unawaited(_refreshQuoteInBackground(addr));
  }

  Future<void> _saveToAccount(SavedAddressLabel label) async {
    final uid = widget.user?.uid ?? '';
    if (uid.isEmpty || _selected == null || !_selected!.hasCoordinates) {
      setState(() => _error = 'سجّل الدخول لحفظ العنوان');
      return;
    }
    setState(() => _saving = true);
    try {
      await _savedRepo.save(
        userId: uid,
        label: label,
        address: _selected!.copyWith(label: label.displayName),
        setDefault: label == SavedAddressLabel.home || _saved.isEmpty,
      );
      await _loadSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ ${label.displayName}',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirm() {
    final addr = _selected;
    if (addr == null || !addr.hasCoordinates) {
      setState(() => _error = 'اختر عنواناً صالحاً من الخريطة أو البحث');
      return;
    }
    if (addr.outOfZone) {
      setState(() => _error = DeliveryQuote.outOfZoneMessageDefault);
      return;
    }
    final withNotes = addr.copyWith(buildingNotes: _notesController.text.trim());
    Navigator.pop(context, withNotes);
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
          child: Column(
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
                'عنوان التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ابحث كما في Google Maps — شارع، مول، مستشفى، جامعة…',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              PlacesSearchField(
                controller: _searchController,
                onSuggestionSelected: _onSuggestion,
                maps: _maps,
                autofocus: false,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(
                        'موقعي',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: Text(
                        'الخريطة',
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
              if (_selected?.hasCoordinates == true) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(
                          child: GoogleMap(
                            key: ValueKey(
                              '${_selected!.latitude}_${_selected!.longitude}',
                            ),
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _selected!.latitude,
                                _selected!.longitude,
                              ),
                              zoom: 15.8,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('picked'),
                                position: LatLng(
                                  _selected!.latitude,
                                  _selected!.longitude,
                                ),
                              ),
                            },
                            liteModeEnabled: true,
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: _openMapPicker,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'اضغط لضبط النقطة على الخريطة',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_saved.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'عناوينك المحفوظة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._saved.map((s) {
                  final selected = _selected?.latitude == s.address.latitude &&
                      _selected?.longitude == s.address.longitude;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _selectSaved(s),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Text(s.label.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${s.label.displayName}${s.isDefault ? ' · افتراضي' : ''}',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      s.address.displayLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
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
              if (_quoteLoading || _previewDistanceKm != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (_quoteLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.route_rounded, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _quoteLoading
                              ? 'جاري حساب مسافة الطريق…'
                              : 'مسافة الطريق: ${_previewDistanceKm!.toStringAsFixed(1)} كم · '
                                  'الوصول ~ $_previewEta د',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              if (widget.user != null && _selected?.hasCoordinates == true) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving
                            ? null
                            : () => _saveToAccount(SavedAddressLabel.home),
                        child: Text('حفظ كالمنزل', style: GoogleFonts.cairo()),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _saving
                            ? null
                            : () => _saveToAccount(SavedAddressLabel.work),
                        child: Text('حفظ كالعمل', style: GoogleFonts.cairo()),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'تأكيد العنوان',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
