import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewStatus { pending, approved, rejected }

class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.storeId,
    required this.rating,
    required this.comment,
    this.productId = '',
    this.imageUrls = const [],
    this.helpfulCount = 0,
    this.status = ReviewStatus.approved,
    this.ownerReply,
    this.ownerRepliedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String storeId;
  final String productId;
  final int rating;
  final String comment;
  final List<String> imageUrls;
  final int helpfulCount;
  final ReviewStatus status;
  final String? ownerReply;
  final DateTime? ownerRepliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Review.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return Review(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      storeId: data['storeId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? const []),
      helpfulCount: (data['helpfulCount'] as num?)?.toInt() ?? 0,
      status: ReviewStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ReviewStatus.approved,
      ),
      ownerReply: data['ownerReply'] as String?,
      ownerRepliedAt: (data['ownerRepliedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateFirestore() => {
    'userId': userId,
    'userName': userName,
    'storeId': storeId,
    'productId': productId,
    'rating': rating,
    'comment': comment,
    'imageUrls': imageUrls,
    'helpfulCount': 0,
    'status': ReviewStatus.approved.name,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
