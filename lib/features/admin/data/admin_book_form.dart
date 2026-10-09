class GenreOption {
  const GenreOption({required this.id, required this.name});
  final String id;
  final String name;
}

class BookFormData {
  const BookFormData({
    required this.id,
    required this.title,
    required this.authorName,
    required this.genreId,
    required this.description,
    required this.coverUrl,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.isFeatured,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String authorName;
  final String? genreId;
  final String description;
  final String? coverUrl;
  final double price;
  final double? originalPrice;
  final int stock;
  final bool isFeatured;
  final DateTime? publishedAt;

  factory BookFormData.fromJson(Map<String, dynamic> j) {
    final author = j['authors'];
    return BookFormData(
      id: j['id'] as String,
      title: (j['title'] as String?) ?? '',
      authorName: author is Map ? ((author['name'] as String?) ?? '') : '',
      genreId: j['genre_id']?.toString(),
      description: (j['description'] as String?) ?? '',
      coverUrl: j['cover_url'] as String?,
      price: (j['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (j['original_price'] as num?)?.toDouble(),
      stock: (j['stock'] as num?)?.toInt() ?? 0,
      isFeatured: (j['is_featured'] as bool?) ?? false,
      publishedAt: j['published_at'] == null
          ? null
          : DateTime.tryParse(j['published_at'].toString()),
    );
  }
}
