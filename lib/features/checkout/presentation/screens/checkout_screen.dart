import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/constants/shop_rules.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/cart/presentation/providers/cart_controller.dart';
import 'package:bookhaven/features/checkout/presentation/providers/checkout_controller.dart';
import 'package:bookhaven/features/checkout/presentation/widgets/address_form_sheet.dart';
import 'package:bookhaven/features/checkout/presentation/widgets/address_tile.dart';
import 'package:bookhaven/features/checkout/presentation/widgets/checkout_section.dart';
import 'package:bookhaven/features/checkout/presentation/widgets/checkout_summary.dart';
import 'package:bookhaven/features/checkout/presentation/widgets/payment_section.dart';
import 'package:bookhaven/features/profile/presentation/providers/address_providers.dart';
import 'package:bookhaven/shared/models/address.dart';
import 'package:bookhaven/shared/models/cart_item.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _cardFormKey = GlobalKey<FormState>();
  final _cardName = TextEditingController();
  final _cardNumber = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();

  @override
  void dispose() {
    _cardName.dispose();
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    super.dispose();
  }

  String? _effectiveAddressId(List<Address> addresses, CheckoutState state) {
    if (addresses.isEmpty) return null;
    if (state.addressId != null &&
        addresses.any((a) => a.id == state.addressId)) {
      return state.addressId;
    }
    return addresses
        .firstWhere((a) => a.isDefault, orElse: () => addresses.first)
        .id;
  }

  Future<void> _addAddress({required bool isFirst}) async {
    final saved = await showAddressFormSheet(context, isFirst: isFirst);
    if (saved == null) return;
    ref.read(checkoutControllerProvider.notifier).selectAddress(saved.id);
    ref.invalidate(addressesProvider);
  }

  Future<void> _placeOrder(List<Address> addresses) async {
    final ctrl = ref.read(checkoutControllerProvider.notifier);
    final state = ref.read(checkoutControllerProvider);

    final addressId = _effectiveAddressId(addresses, state);
    if (addressId == null) {
      ctrl.setError('Choose or add a delivery address first.');
      return;
    }

    String? last4;
    if (state.payment == PaymentMethod.card) {
      if (!(_cardFormKey.currentState?.validate() ?? false)) return;
      final digits = _cardNumber.text.replaceAll(RegExp(r'\D'), '');
      last4 = digits.substring(digits.length - 4);
    }

    FocusScope.of(context).unfocus();
    final order = await ctrl.placeOrder(addressId: addressId, cardLast4: last4);
    if (order != null && mounted) {
      context.go(
        AppRoutes.orderSuccessPath(order.id, number: order.orderNumber),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final cartAsync = ref.watch(cartControllerProvider);
    final state = ref.watch(checkoutControllerProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final addresses = addressesAsync.value ?? const <Address>[];

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Checkout')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your cart.'),
              TextButton(
                onPressed: () => ref.invalidate(cartControllerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty && !state.done) return _emptyCart(context);
          return _content(context, items, addressesAsync, state);
        },
      ),
      bottomNavigationBar: cartAsync.value == null || cartAsync.value!.isEmpty
          ? null
          : _bottomBar(context, cartAsync.value!, addresses, state),
    );
  }

  Widget _emptyCart(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56, color: c.textSecondary),
            const SizedBox(height: AppDimens.lg),
            Text(
              'Your cart is empty',
              style: text.headlineSmall?.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppDimens.lg),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Browse books'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<CartItem> items,
    AsyncValue<List<Address>> addressesAsync,
    CheckoutState state,
  ) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final addresses = addressesAsync.value ?? const <Address>[];
    final selectedId = _effectiveAddressId(addresses, state);

    return ListView(
      padding: const EdgeInsets.all(AppDimens.pagePadding),
      children: [
        CheckoutSection(
          number: 1,
          title: 'Delivery address',
          child: addressesAsync.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Row(
              children: [
                const Expanded(child: Text('Could not load addresses.')),
                TextButton(
                  onPressed: () => ref.invalidate(addressesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (list) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in list)
                  AddressTile(
                    address: a,
                    selected: a.id == selectedId,
                    onTap: () => ref
                        .read(checkoutControllerProvider.notifier)
                        .selectAddress(a.id),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: () => _addAddress(isFirst: list.isEmpty),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(
                      list.isEmpty
                          ? 'Add delivery address'
                          : 'Add a new address',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.xxl),
        CheckoutSection(
          number: 2,
          title: 'Payment',
          child: PaymentSection(
            method: state.payment,
            onChanged: (m) =>
                ref.read(checkoutControllerProvider.notifier).selectPayment(m),
            formKey: _cardFormKey,
            nameCtrl: _cardName,
            numberCtrl: _cardNumber,
            expiryCtrl: _cardExpiry,
            cvvCtrl: _cardCvv,
          ),
        ),
        const SizedBox(height: AppDimens.xxl),
        CheckoutSection(
          number: 3,
          title: 'Order summary',
          child: CheckoutSummary(items: items),
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppDimens.lg),
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: c.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusInput),
              border: Border.all(color: c.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: c.error, size: 20),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    state.error!,
                    style: text.bodyMedium?.copyWith(color: c.error),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppDimens.lg),
      ],
    );
  }

  Widget _bottomBar(
    BuildContext context,
    List<CartItem> items,
    List<Address> addresses,
    CheckoutState state,
  ) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    final subtotal = cartSubtotal(items);
    final total = subtotal + ShopRules.deliveryFor(subtotal);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.md,
        AppDimens.pagePadding,
        AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL',
                  style: text.labelMedium?.copyWith(color: c.textSecondary),
                ),
                Text(
                  formatPrice(total),
                  style: text.titleLarge?.copyWith(color: c.primary),
                ),
              ],
            ),
            const SizedBox(width: AppDimens.xl),
            Expanded(
              child: SizedBox(
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: state.placing
                      ? null
                      : () => _placeOrder(addresses),
                  child: state.placing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Place order'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
