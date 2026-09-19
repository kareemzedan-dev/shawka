import 'package:matlobgo/models/review.dart';
import 'package:matlobgo/repositories/review_repository.dart';

class ReviewService {
  ReviewService({ReviewRepository? repository})
    : _repository = repository ?? ReviewRepository();

  static final ReviewService instance = ReviewService();

  final ReviewRepository _repository;

  Stream<List<Review>> watchByStore(String storeId) =>
      _repository.watchByStore(storeId);

  Stream<List<Review>> watchByProduct(String productId) =>
      _repository.watchByProduct(productId);

  Future<String> createReview(Review review) =>
      _repository.createReview(review);

  Future<bool> toggleHelpful(String reviewId) =>
      _repository.toggleHelpful(reviewId);
}
