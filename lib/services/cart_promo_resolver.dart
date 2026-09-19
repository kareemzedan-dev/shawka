import 'package:matlobgo/screens/home/widgets/cart_premium_widgets.dart';
import 'package:matlobgo/services/promotion_service.dart';

/// يحل أكواد العروض من Firestore فقط. التحقق المالي النهائي يتم خادميًا.
abstract final class CartPromoResolver {
  static CartPromoOffer? resolve(String raw, {Set<String>? storeIdsInCart}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final remote = PromotionService.instance.resolveCode(
      trimmed,
      storeIdsInCart: storeIdsInCart,
    );
    if (remote != null) {
      return CartPromoOffer.fromPromotion(remote);
    }
    return null;
  }
}
