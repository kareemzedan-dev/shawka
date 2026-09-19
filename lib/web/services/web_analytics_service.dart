import 'package:matlobgo/models/analytics_event.dart';
import 'package:matlobgo/models/cart_item.dart';
import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/services/analytics_service.dart';

/// Funnel تحويل الويب → التطبيق.
class WebAnalyticsService {
  WebAnalyticsService._();
  static final WebAnalyticsService instance = WebAnalyticsService._();

  final _remote = AnalyticsService.instance;

  Future<void> webSessionStart() => _track(
        type: AnalyticsEventType.sessionStart,
        screen: 'web',
        label: 'جلسة ويب',
        metadata: {'channel': 'web', 'funnel': 'web_to_app'},
      );

  Future<void> storeOpen(Store store) => _track(
        type: AnalyticsEventType.storeView,
        screen: 'web_store',
        label: 'فتح متجر (ويب)',
        storeId: store.id,
        storeName: store.name,
        metadata: {'channel': 'web'},
      );

  Future<void> productOpen({
    required Store store,
    required Product product,
  }) =>
      _track(
        type: AnalyticsEventType.productView,
        screen: 'web_product',
        label: 'فتح منتج (ويب)',
        storeId: store.id,
        storeName: store.name,
        productId: product.id,
        productName: product.name,
        metadata: {'channel': 'web'},
      );

  Future<void> addToCart({
    required Store store,
    required Product product,
    required int quantity,
  }) =>
      _track(
        type: AnalyticsEventType.addToCart,
        screen: 'web_cart',
        label: 'إضافة للسلة (ويب)',
        storeId: store.id,
        storeName: store.name,
        productId: product.id,
        productName: product.name,
        metadata: {'channel': 'web', 'quantity': quantity},
      );

  Future<void> removeFromCart({required CartItem item}) => _track(
        type: AnalyticsEventType.removeFromCart,
        screen: 'web_cart',
        label: 'حذف من السلة (ويب)',
        storeId: item.storeId,
        storeName: item.storeName,
        productId: item.productId,
        productName: item.productName,
        metadata: {'channel': 'web', 'quantity': item.quantity},
      );

  Future<void> checkoutGateReached({required double cartTotal}) => _track(
        type: AnalyticsEventType.checkoutStart,
        screen: 'web_checkout_gate',
        label: 'بوابة إتمام الطلب (ويب)',
        metadata: {
          'channel': 'web',
          'funnel': 'checkout_gate',
          'cartTotal': cartTotal,
        },
      );

  Future<void> appDownloadClick({required String platform}) => _track(
        type: AnalyticsEventType.screenView,
        screen: 'web_app_download',
        label: 'تحميل التطبيق ($platform)',
        metadata: {
          'channel': 'web',
          'funnel': 'app_download',
          'platform': platform,
        },
      );

  Future<void> shareLinkClick({required String channel}) => _track(
        type: AnalyticsEventType.screenView,
        screen: 'web_share_link',
        label: 'مشاركة رابط التحميل ($channel)',
        metadata: {
          'channel': 'web',
          'funnel': 'share_download',
          'shareChannel': channel,
        },
      );

  Future<void> conversionBannerShown({required String variant}) => _track(
        type: AnalyticsEventType.screenView,
        screen: 'web_conversion_banner',
        label: 'بانر تحويل ($variant)',
        metadata: {'channel': 'web', 'variant': variant},
      );

  Future<void> conversionPopupShown({required String variant}) => _track(
        type: AnalyticsEventType.screenView,
        screen: 'web_conversion_popup',
        label: 'نافذة تحويل ($variant)',
        metadata: {'channel': 'web', 'variant': variant},
      );

  Future<void> _track({
    required AnalyticsEventType type,
    required String screen,
    required String label,
    String storeId = '',
    String storeName = '',
    String productId = '',
    String productName = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    await _remote.track(
      type: type,
      screen: screen,
      label: label,
      storeId: storeId,
      storeName: storeName,
      productId: productId,
      productName: productName,
      metadata: metadata,
    );
  }
}
