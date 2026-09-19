import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/app_config_service.dart';

/// إحصائيات حية من Firestore — بدون Mock.
class WebLiveStats extends ChangeNotifier {
  WebLiveStats._();
  static final WebLiveStats instance = WebLiveStats._();

  int storeCount = 0;
  int openStoreCount = 0;
  int productCount = 0;
  int? completedOrders;
  bool loadingProducts = false;
  String? _governorate;
  List<Store> _lastStores = const [];

  void bindGovernorate(String governorate) {
    if (_governorate == governorate) return;
    _governorate = governorate;
    _refreshProductCount();
  }

  void onStoresUpdated(List<Store> stores) {
    _lastStores = stores;
    openStoreCount = stores.where((s) => s.isOpen).length;
    storeCount = stores.length;
    notifyListeners();
    _refreshProductCount();
  }

  void onSettingsUpdated() {
    final settings = AppConfigService.instance.settings;
    if (settings.platformCompletedOrders > 0) {
      completedOrders = settings.platformCompletedOrders;
      notifyListeners();
    }
    if (settings.platformProductCount > 0) {
      productCount = settings.platformProductCount;
      notifyListeners();
    }
  }

  Future<void> _refreshProductCount() async {
    if (_governorate == null || _lastStores.isEmpty) return;
    loadingProducts = true;
    notifyListeners();

    try {
      final settings = AppConfigService.instance.settings;
      if (settings.platformProductCount > 0) {
        productCount = settings.platformProductCount;
      } else {
        productCount = await _countProductsForStores(_lastStores);
      }
    } catch (_) {
      productCount = 0;
    } finally {
      loadingProducts = false;
      notifyListeners();
    }
  }

  Future<int> _countProductsForStores(List<Store> stores) async {
    final firestore = FirebaseFirestore.instance;
    var total = 0;
    final open = stores.where((s) => s.isOpen).take(40);
    for (final store in open) {
      final snap = await firestore
          .collection(FirestorePaths.stores)
          .doc(store.id)
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .count()
          .get();
      total += snap.count ?? 0;
    }
    return total;
  }
}
