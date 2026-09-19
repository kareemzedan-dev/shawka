import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:matlobgo/core/constants/firestore_paths.dart';
import 'package:matlobgo/models/review.dart';

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _db = firestore ?? FirebaseFirestore.instance,
      _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection(FirestorePaths.reviews);

  Stream<List<Review>> watchByStore(String storeId) => _watch(
    _reviews
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: ReviewStatus.approved.name)
        .orderBy('createdAt', descending: true),
  );

  Stream<List<Review>> watchByProduct(String productId) => _watch(
    _reviews
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: ReviewStatus.approved.name)
        .orderBy('createdAt', descending: true),
  );

  /// Admin moderation — latest reviews regardless of status.
  Stream<List<Review>> watchRecent({int limit = 100}) =>
      _watch(_reviews.orderBy('createdAt', descending: true).limit(limit));

  Stream<List<Review>> _watch(Query<Map<String, dynamic>> query) => query
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Review.fromFirestore).toList());

  Future<void> setStatus(String reviewId, ReviewStatus status) =>
      _reviews.doc(reviewId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setOwnerReply(String reviewId, String reply) =>
      _reviews.doc(reviewId).update({
        'ownerReply': reply,
        'ownerRepliedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteReview(String reviewId) =>
      _reviews.doc(reviewId).delete();

  Future<String> createReview(Review review) async {
    if (review.rating < 1 || review.rating > 5) {
      throw ArgumentError.value(review.rating, 'rating', 'must be from 1 to 5');
    }
    if (review.userId.trim().isEmpty || review.storeId.trim().isEmpty) {
      throw ArgumentError('userId and storeId are required');
    }
    final document = await _reviews.add(review.toCreateFirestore());
    return document.id;
  }

  Future<bool> toggleHelpful(String reviewId) async {
    final result = await _functions.httpsCallable('toggleReviewHelpful').call(
      <String, dynamic>{'reviewId': reviewId},
    );
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['helpful'] == true;
  }
}
