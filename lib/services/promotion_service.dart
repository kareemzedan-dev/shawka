import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/models/promotion.dart';
import 'package:matlobgo/repositories/promotion_repository.dart';

/// عروض وخصومات حية من Firestore — تظهر فوراً في التطبيق.
class PromotionService extends ChangeNotifier {
  PromotionService._();

  static final PromotionService instance = PromotionService._();

  final _repo = PromotionRepository();
  StreamSubscription<List<Promotion>>? _subscription;
  String _governorate = '';
  List<Promotion> _promotions = [];

  List<Promotion> get promotions => List.unmodifiable(_promotions);

  void bindGovernorate(String governorate) {
    if (_governorate == governorate && _subscription != null) return;
    _governorate = governorate;
    _subscription?.cancel();
    _subscription = _repo.watchActiveByGovernorate(governorate).listen(
      (list) {
        _promotions = list;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Promotion? resolveCode(String rawCode, {Set<String>? storeIdsInCart}) {
    return _repo.findByCode(
      _promotions,
      rawCode,
      storeIdsInCart: storeIdsInCart,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
