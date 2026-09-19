import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:matlobgo/core/maps/directions_route.dart';
import 'package:matlobgo/core/maps/google_maps_api_service.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/theme/app_palette.dart';
import 'package:uuid/uuid.dart';

class PlacesSearchField extends StatefulWidget {
  PlacesSearchField({
    super.key,
    required this.controller,
    required this.onSuggestionSelected,
    this.hint = 'ابحث عن شارع، مول، مستشفى، جامعة…',
    this.autofocus = true,
    this.compactOverlay = false,
    GoogleMapsApiService? maps,
  }) : maps = maps ?? GoogleMapsApiService();

  final TextEditingController controller;
  final Future<void> Function(PlaceSuggestion suggestion) onSuggestionSelected;
  final String hint;
  final bool autofocus;
  final GoogleMapsApiService maps;

  /// عند true تُعرض الاقتراحات كقائمة مقيّدة الارتفاع فوق الخريطة.
  final bool compactOverlay;

  @override
  State<PlacesSearchField> createState() => _PlacesSearchFieldState();
}

class _PlacesSearchFieldState extends State<PlacesSearchField> {
  final _sessionToken = const Uuid().v4();
  final _focus = FocusNode();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _error;
  bool _focused = false;

  bool get _showPanel =>
      _focused &&
      (widget.controller.text.trim().length >= 2) &&
      (_loading || _error != null || _suggestions.isNotEmpty);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    if (!_focus.hasFocus) {
      if (mounted) {
        setState(() {
          _suggestions = const [];
          _error = null;
          _loading = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), _fetchSuggestions);
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    setState(() {
      _suggestions = const [];
      _error = null;
      _loading = false;
    });
  }

  Future<void> _fetchSuggestions() async {
    final q = widget.controller.text.trim();
    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = const [];
          _loading = false;
          _error = null;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var list = await widget.maps.autocomplete(
        input: q,
        sessionToken: _sessionToken,
      );

      // على الويب غالباً Google Places يفشل — نستخدم Nominatim.
      if (list.isEmpty && kIsWeb) {
        list = await _nominatimSearch(q);
      }

      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
        _error = list.isEmpty ? 'لا توجد نتائج — حرّك الخريطة يدوياً' : null;
      });
    } on GoogleMapsApiException catch (e) {
      if (kIsWeb) {
        try {
          final list = await _nominatimSearch(q);
          if (!mounted) return;
          setState(() {
            _suggestions = list;
            _loading = false;
            _error = list.isEmpty ? 'لا توجد نتائج' : null;
          });
          return;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (kIsWeb) {
        try {
          final list = await _nominatimSearch(q);
          if (!mounted) return;
          setState(() {
            _suggestions = list;
            _loading = false;
            _error = list.isEmpty ? 'لا توجد نتائج' : null;
          });
          return;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _loading = false;
        _error = 'تعذّر جلب الاقتراحات';
      });
    }
  }

  Future<List<PlaceSuggestion>> _nominatimSearch(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '6',
      'countrycodes': 'eg',
      'accept-language': 'ar',
    });
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'Shawka-Admin/1.0 (store-location-picker)',
      },
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];

    final raw = jsonDecode(response.body);
    if (raw is! List) return const [];

    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      final lat = map['lat']?.toString() ?? '';
      final lon = map['lon']?.toString() ?? '';
      final display = map['display_name']?.toString() ?? '';
      final parts = display.split(',');
      return PlaceSuggestion(
        // ترميز خاص: osm|lat|lng
        placeId: 'osm|$lat|$lon',
        mainText: parts.isNotEmpty ? parts.first.trim() : display,
        secondaryText: parts.length > 1
            ? parts.skip(1).join(',').trim()
            : '',
        fullDescription: display,
      );
    }).where((s) => s.placeId.startsWith('osm|')).toList();
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    _focus.unfocus();
    setState(() {
      _suggestions = const [];
      _error = null;
    });
    await widget.onSuggestionSelected(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          style: GoogleFonts.cairo(
            color: palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.cairo(color: palette.textSecondary),
            isDense: true,
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      )
                    : null,
            filled: true,
            fillColor: palette.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        if (_showPanel) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 4,
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.compactOverlay ? 220 : 280,
              ),
              child: _loading && _suggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _suggestions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _error ?? 'لا توجد نتائج',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length.clamp(0, 6),
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: palette.border),
                          itemBuilder: (context, index) {
                            final s = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.place_outlined,
                                color: AppColors.primary.withValues(alpha: 0.85),
                              ),
                              title: Text(
                                s.mainText,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: palette.textPrimary,
                                ),
                              ),
                              subtitle: s.secondaryText.isNotEmpty
                                  ? Text(
                                      s.secondaryText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: palette.textSecondary,
                                      ),
                                    )
                                  : null,
                              onTap: () => _select(s),
                            );
                          },
                        ),
            ),
          ),
        ],
      ],
    );
  }
}
