// lib/models/review.dart
import 'dart:convert';

class ReviewReply {
  final int id;
  final int reviewId;
  final int? adminId;
  final String reply;
  final DateTime? createdAt;

  ReviewReply({
    required this.id,
    required this.reviewId,
    this.adminId,
    required this.reply,
    this.createdAt,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return null;
    }

    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k];
      }
      return null;
    }

    return ReviewReply(
      id: _toInt(pick(['id', 'reply_id'])),
      reviewId: _toInt(pick(['review_id', 'reviewId'])),
      adminId: _toInt(pick(['admin_id', 'adminId'])),
      reply: (pick(['reply', 'content']) ?? '').toString(),
      createdAt: _toDate(pick(['created_at', 'createdAt'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'review_id': reviewId,
    'admin_id': adminId,
    'reply': reply,
    'created_at': createdAt?.toIso8601String(),
  };
}

class Review {
  final int id;
  final int? userId;
  final int? bookingId;
  final int rating; // 1..5
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Danh sách phản hồi (từ BE: replies: [])
  final List<ReviewReply> replies;

  Review({
    required this.id,
    this.userId,
    this.bookingId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
    this.replies = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) {
        final i = int.tryParse(v);
        if (i != null) return i;
        final d = double.tryParse(v);
        if (d != null) return d.round();
      }
      return 0;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return null;
    }

    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k];
      }
      return null;
    }

    final rawRating = pick(['rating', 'score', 'stars']);

    // Parse replies (ưu tiên mảng replies; fallback: trường reply đơn lẻ)
    List<ReviewReply> _parseReplies() {
      final v = pick(['replies']);
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => ReviewReply.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      final single = pick(['reply']); // đôi khi API cũ trả 'reply': '...'
      if (single != null && single.toString().trim().isNotEmpty) {
        return [
          ReviewReply(
            id: 0,
            reviewId: _toInt(pick(['id', 'review_id'])),
            adminId: null,
            reply: single.toString(),
            createdAt: _toDate(pick(['updatedAt', 'updated_at', 'created_at'])),
          )
        ];
      }
      return const [];
    }

    return Review(
      id: _toInt(pick(['id', 'reviewId', 'review_id'])),
      userId: _toInt(pick(['userId', 'user_id'])),
      bookingId: _toInt(pick(['bookingId', 'booking_id'])),
      rating: (_toInt(rawRating)).clamp(1, 5),
      comment: pick(['comment', 'content', 'message', 'review'])?.toString(),
      createdAt: _toDate(pick(['createdAt', 'created_at', 'created'])),
      updatedAt: _toDate(pick(['updatedAt', 'updated_at', 'modified'])),
      replies: _parseReplies(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'bookingId': bookingId,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'replies': replies.map((e) => e.toJson()).toList(),
  };

  @override
  String toString() => jsonEncode(toJson());

  /// Reply mới nhất (nếu muốn hiển thị ngắn gọn)
  ReviewReply? get latestReply {
    if (replies.isEmpty) return null;
    replies.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });
    return replies.first;
  }
}
