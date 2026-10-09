enum AdminBookFilter {
  all('all', 'All'),
  low('low', 'Low stock'),
  out('out', 'Out of stock'),
  featured('featured', 'Featured');

  const AdminBookFilter(this.value, this.label);
  final String value;
  final String label;
}

class AdminBook {
  const AdminBook({
    required this.id,
    required this.title,
    required this.authorName,
    required this.genreName,
    required this.coverUrl,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.isFeatured,
    required this.ratingAvg,
    required this.ratingCount,
    required this.salesCount,
  });

  final String id;
  final String title;
  final String authorName;
  final String genreName;
  final String? coverUrl;
  final double price;
  final double? originalPrice;
  final int stock;
  final bool isFeatured;
  final double ratingAvg;
  final int ratingCount;
  final int salesCount;

  bool get outOfStock => stock <= 0;
  bool get lowStock => stock > 0 && stock <= 5;
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  factory AdminBook.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    int i(dynamic v) => (v as num?)?.toInt() ?? 0;
    return AdminBook(
      id: j['id'] as String,
      title: (j['title'] as String?) ?? '',
      authorName: (j['author_name'] as String?) ?? 'Unknown author',
      genreName: (j['genre_name'] as String?) ?? '',
      coverUrl: j['cover_url'] as String?,
      price: d(j['price']),
      originalPrice: j['original_price'] == null
          ? null
          : d(j['original_price']),
      stock: i(j['stock']),
      isFeatured: (j['is_featured'] as bool?) ?? false,
      ratingAvg: d(j['rating_avg']),
      ratingCount: i(j['rating_count']),
      salesCount: i(j['sales_count']),
    );
  }
}
