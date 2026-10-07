enum OrderFilter {
  all('All', null),
  active('Active', ['placed', 'processing', 'shipped', 'out_for_delivery']),
  delivered('Delivered', ['delivered']),
  cancelled('Cancelled', ['cancelled']);

  const OrderFilter(this.label, this.statuses);

  final String label;

  /// null = no status filter.
  final List<String>? statuses;
}
