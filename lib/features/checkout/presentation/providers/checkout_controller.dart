import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookhaven/features/cart/presentation/providers/cart_controller.dart';
import 'package:bookhaven/features/checkout/data/checkout_repository.dart';

enum PaymentMethod { cod, card }

class CheckoutState {
  const CheckoutState({
    this.addressId,
    this.payment = PaymentMethod.cod,
    this.placing = false,
    this.done = false,
    this.error,
  });

  final String?
  addressId; // null = user hasn't picked, screen falls back to default
  final PaymentMethod payment;
  final bool placing;
  final bool done;
  final String? error;

  CheckoutState copyWith({
    String? addressId,
    PaymentMethod? payment,
    bool? placing,
    bool? done,
    String? error,
    bool clearError = false,
  }) => CheckoutState(
    addressId: addressId ?? this.addressId,
    payment: payment ?? this.payment,
    placing: placing ?? this.placing,
    done: done ?? this.done,
    error: clearError ? null : (error ?? this.error),
  );
}

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void selectAddress(String id) =>
      state = state.copyWith(addressId: id, clearError: true);
  void selectPayment(PaymentMethod m) =>
      state = state.copyWith(payment: m, clearError: true);
  void setError(String message) => state = state.copyWith(error: message);

  Future<PlacedOrder?> placeOrder({
    required String addressId,
    String? cardLast4,
  }) async {
    if (state.placing) return null;
    state = state.copyWith(placing: true, clearError: true);
    try {
      final order = await ref
          .read(checkoutRepositoryProvider)
          .placeOrder(
            addressId: addressId,
            paymentMethod: state.payment == PaymentMethod.card ? 'card' : 'cod',
            cardLast4: cardLast4,
          );
      state = state.copyWith(placing: false, done: true);
      ref.invalidate(cartControllerProvider); // cart is now empty on the server
      return order;
    } on CheckoutException catch (e) {
      state = state.copyWith(placing: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        placing: false,
        error:
            'Could not place your order. Check your connection and try again.',
      );
    }
    return null;
  }
}

final checkoutControllerProvider =
    NotifierProvider.autoDispose<CheckoutController, CheckoutState>(
      CheckoutController.new,
    );
