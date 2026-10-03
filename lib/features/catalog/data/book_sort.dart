enum BookSort {
  popular('Most popular', 'sales_count', false),
  newest('Newest first', 'published_at', false),
  rating('Top rated', 'rating_avg', false),
  priceLow('Price: low to high', 'price', true),
  priceHigh('Price: high to low', 'price', false);

  const BookSort(this.label, this.column, this.ascending);

  final String label;
  final String column;
  final bool ascending;

  static BookSort fromName(String? name) => BookSort.values.firstWhere(
    (s) => s.name == name,
    orElse: () => BookSort.popular,
  );
}
