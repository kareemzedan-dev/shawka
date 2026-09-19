import 'package:matlobgo/models/store.dart';
import 'package:matlobgo/repositories/promo_banner_repository.dart';

/// بانرات حية من Firestore فقط — بدون Mock fallback.
class WebPromoService {
  WebPromoService({PromoBannerRepository? repo})
      : _repo = repo ?? PromoBannerRepository();

  final PromoBannerRepository _repo;

  Stream<List<PromoBanner>> watch(String governorate) {
    return _repo.watchByGovernorate(governorate).map((records) {
      return records
          .where((r) => r.isActive)
          .map((r) => r.toDisplayBanner())
          .toList();
    });
  }
}
