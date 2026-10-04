class Book {
  const Book({
    required this.id,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.genreId,
    required this.genreName,
    required this.description,
    required this.coverUrl,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.ratingAvg,
    required this.ratingCount,
    required this.salesCount,
    required this.isFeatured,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String authorId;
  final String authorName;
  final String genreId;
  final String genreName;
  final String description;
  final String? coverUrl;
  final double price;
  final double? originalPrice;
  final int stock;
  final double ratingAvg;
  final int ratingCount;
  final int salesCount;
  final bool isFeatured;
  final DateTime publishedAt;

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  int get discountPercent => hasDiscount
      ? (((originalPrice! - price) / originalPrice!) * 100).round()
      : 0;
  bool get inStock => stock > 0;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    title: json['title'] as String,
    authorId: json['author_id'] as String,
    authorName: (json['authors'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown author',
    genreId: json['genre_id'] as String,
    genreName: (json['genres'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    coverUrl: json['cover_url'] as String?,
    price: (json['price'] as num).toDouble(),
    originalPrice: (json['original_price'] as num?)?.toDouble(),
    stock: json['stock'] as int? ?? 0,
    ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
    ratingCount: json['rating_count'] as int? ?? 0,
    salesCount: json['sales_count'] as int? ?? 0,
    isFeatured: json['is_featured'] as bool? ?? false,
    publishedAt: DateTime.parse(json['published_at'] as String),
  );
}
