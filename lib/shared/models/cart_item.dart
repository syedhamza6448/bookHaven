import 'package:bookhaven/shared/models/book.dart';

class CartItem {
  const CartItem({required this.book, required this.quantity});

  final Book book;
  final int quantity;

  double get lineTotal => book.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(book: book, quantity: quantity ?? this.quantity);
}

class CartTotals {
  const CartTotals(this.items);

  static const double freeDeliveryThreshold = 30;
  static const double deliveryFee = 3.99;

  final List<CartItem> items;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => items.fold(0.0, (s, i) => s + i.lineTotal);
  double get delivery =>
      items.isEmpty || subtotal >= freeDeliveryThreshold ? 0 : deliveryFee;
  double get total => subtotal + delivery;
  double get amountToFreeDelivery =>
      (freeDeliveryThreshold - subtotal).clamp(0, freeDeliveryThreshold);
}
