class Review {
  const Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.likeCount,
    required this.likedByMe,
    this.avatarUrl,
  });

  final String id;
  final String userName;
  final String? avatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  factory Review.fromJson(
    Map<String, dynamic> json, {
    required bool likedByMe,
  }) {
    var count = 0;
    final likes = json['review_likes'];
    if (likes is List && likes.isNotEmpty) {
      count = (likes.first['count'] as num?)?.toInt() ?? 0;
    }

    final avatar = (json['user_avatar_url'] as String?)?.trim();

    return Review(
      id: json['id'].toString(),
      userName: (json['user_name'] as String?) ?? 'Reader',
      avatarUrl: (avatar == null || avatar.isEmpty) ? null : avatar,
      rating: (json['rating'] as num).toInt(),
      comment: (json['comment'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      likeCount: count,
      likedByMe: likedByMe,
    );
  }
}
