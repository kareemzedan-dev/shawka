import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:matlobgo/core/data/egypt_governorates.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/app_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// محافظة الويب — Firestore حي + تخزين محلي.
class WebGovernorateService extends ChangeNotifier {
  WebGovernorateService._();
  static final WebGovernorateService instance = WebGovernorateService._();

  static const _prefKey = 'web_governorate_id';

  Governorate _governorate = EgyptGovernorates.defaultGovernorate;
  List<Governorate> _available = EgyptGovernorates.available;
  StreamSubscription<List<Governorate>>? _govSub;
  bool _ready = false;

  Governorate get governorate => _governorate;
  String get governorateName => _governorate.name;
  String get governorateId => _governorate.id;
  List<Governorate> get available => _available;
  bool get isReady => _ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    _govSub?.cancel();
    _govSub = AppConfigService.instance.watchAvailableGovernorates().listen(
      (list) {
        if (list.isNotEmpty) _available = list;
        notifyListeners();
      },
      onError: (_) {},
    );

    if (saved != null) {
      final gov = _resolveById(saved);
      if (gov != null) _governorate = gov;
    }

    _ready = true;
    notifyListeners();
  }

  Governorate? _resolveById(String id) {
    for (final g in _available) {
      if (g.id == id) return g;
    }
    return EgyptGovernorates.byId(id);
  }

  Future<void> setGovernorate(Governorate gov) async {
    if (!gov.isAvailable) return;
    _governorate = gov;
    // Avoid notifyListeners during an ancestor build (ListenableBuilder).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, gov.id);
  }

  Future<void> setGovernorateById(String id) async {
    final gov = _resolveById(id);
    if (gov != null && gov.isAvailable) {
      await setGovernorate(gov);
    }
  }

  @override
  void dispose() {
    _govSub?.cancel();
    super.dispose();
  }
}
