int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
int _toInt(dynamic v) => _toIntOrNull(v) ?? 0;

class ReviewReply {
  final int id;
  final int reviewId;
  final int adminId;
  final String reply;
  final DateTime createdAt;

  ReviewReply({
    required this.id,
    required this.reviewId,
    required this.adminId,
    required this.reply,
    required this.createdAt,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> j) => ReviewReply(
    id: _toInt(j['id']),
    reviewId: _toInt(j['review_id']),
    adminId: _toInt(j['admin_id']),
    reply: (j['reply'] ?? '').toString(),
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class Review {
  final int id;
  final int bookingId;
  final int userId;
  final int rating;          // 1..5
  final String? comment;
  final DateTime createdAt;
  final List<ReviewReply> replies;

  Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.replies,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: _toInt(j['id']),
    bookingId: _toInt(j['booking_id']),
    userId: _toInt(j['user_id']),
    rating: _toInt(j['rating']),
    comment: j['comment'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    replies: (j['replies'] as List? ?? const [])
        .map((x) => ReviewReply.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList(),
  );
}
