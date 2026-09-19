import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:matlobgo/web/config/web_constants.dart';
import 'package:matlobgo/web/services/web_analytics_service.dart';
import 'package:matlobgo/web/services/web_cart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WebConversionBannerKind {
  none,
  appBenefits,
  firstOrderDiscount,
}

enum WebConversionPopupKind {
  none,
  favorites,
}

/// نظام التحويل الذكي — بانرات ونوافذ حسب سلوك المستخدم.
class WebConversionService extends ChangeNotifier {
  WebConversionService._();
  static final WebConversionService instance = WebConversionService._();

  static const _storesVisitedKey = 'web_stores_visited';
  static const _popupShownKey = 'web_favorites_popup_shown';

  final Set<String> _visitedStoreIds = {};
  WebConversionBannerKind _banner = WebConversionBannerKind.none;
  WebConversionPopupKind _pendingPopup = WebConversionPopupKind.none;
  bool _favoritesPopupShown = false;

  WebConversionBannerKind get bannerKind => _banner;
  WebConversionPopupKind get pendingPopup => _pendingPopup;
  int get storesVisitedCount => _visitedStoreIds.length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritesPopupShown = prefs.getBool(_popupShownKey) ?? false;
    final saved = prefs.getStringList(_storesVisitedKey) ?? [];
    _visitedStoreIds.addAll(saved);
    _recomputeBanner();
    notifyListeners();
  }

  void onCartChanged() => _recomputeBanner();

  Future<void> recordStoreVisit(String storeId) async {
    if (storeId.isEmpty) return;
    final added = _visitedStoreIds.add(storeId);
    if (!added) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storesVisitedKey, _visitedStoreIds.toList());

    if (!_favoritesPopupShown &&
        _visitedStoreIds.length >= WebConstants.storesVisitedPopupThreshold) {
      _pendingPopup = WebConversionPopupKind.favorites;
      unawaited(
        WebAnalyticsService.instance.conversionPopupShown(
          variant: 'favorites_after_${_visitedStoreIds.length}_stores',
        ),
      );
    }
    notifyListeners();
  }

  void _recomputeBanner() {
    final cart = WebCartService.instance;
    WebConversionBannerKind next;
    if (cart.isEmpty) {
      next = WebConversionBannerKind.none;
    } else if (cart.subtotal >= WebConstants.cartDiscountThreshold) {
      next = WebConversionBannerKind.firstOrderDiscount;
    } else {
      next = WebConversionBannerKind.appBenefits;
    }
    if (next != _banner && next != WebConversionBannerKind.none) {
      unawaited(
        WebAnalyticsService.instance.conversionBannerShown(
          variant: next.name,
        ),
      );
    }
    _banner = next;
    notifyListeners();
  }

  Future<void> dismissPopup() async {
    if (_pendingPopup == WebConversionPopupKind.favorites) {
      _favoritesPopupShown = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_popupShownKey, true);
    }
    _pendingPopup = WebConversionPopupKind.none;
    notifyListeners();
  }

  void clearPendingPopup() {
    _pendingPopup = WebConversionPopupKind.none;
    notifyListeners();
  }
}
