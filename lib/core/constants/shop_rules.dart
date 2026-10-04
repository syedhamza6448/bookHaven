class ShopRules {
  static const double freeDeliveryOver = 30;
  static const double deliveryFee = 3.99;

  static double deliveryFor(double subtotal) =>
      subtotal > freeDeliveryOver ? 0 : deliveryFee;
}
