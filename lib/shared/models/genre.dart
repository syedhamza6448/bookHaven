class Genre {
  const Genre({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
  );
}
