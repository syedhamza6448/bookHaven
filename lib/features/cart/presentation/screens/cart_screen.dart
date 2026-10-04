import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/cart/presentation/providers/cart_controller.dart';
import 'package:bookhaven/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:bookhaven/features/cart/presentation/widgets/cart_summary.dart';
import 'package:bookhaven/shared/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final cart = ref.watch(cartControllerProvider);
    final hasItems = (cart.value ?? const <CartItem>[]).isNotEmpty;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Your cart'),
        centerTitle: false,
        actions: [
          if (hasItems)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text('Clear', style: TextStyle(color: c.error)),
            ),
        ],
      ),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          onRetry: () => ref.read(cartControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyCart();
          final controller = ref.read(cartControllerProvider.notifier);
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimens.pagePadding),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimens.md),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final id = item.book.id;
                      return Dismissible(
                        key: ValueKey('cart-$id'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: c.error,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusCard,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => _remove(context, ref, id),
                        child: CartItemTile(
                          item: item,
                          onTap: () =>
                              context.push(AppRoutes.bookDetailsPath(id)),
                          onIncrement: () =>
                              controller.setQuantity(id, item.quantity + 1),
                          onDecrement: () =>
                              controller.setQuantity(id, item.quantity - 1),
                          onRemove: () => _remove(context, ref, id),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (40 * i).ms);
                    },
                  ),
                ),
              ),
              CartSummary(
                totals: CartTotals(items),
                onCheckout: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checkout is coming up next')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _remove(BuildContext context, WidgetRef ref, String id) {
    final controller = ref.read(cartControllerProvider.notifier);
    controller.remove(id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Removed from cart'),
        action: SnackBarAction(label: 'UNDO', onPressed: controller.undoRemove),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('All books will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(cartControllerProvider.notifier).clear();
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: c.accent),
            const SizedBox(height: AppDimens.lg),
            Text('Your cart is empty', style: text.headlineSmall),
            const SizedBox(height: AppDimens.sm),
            Text(
              'Find your next favourite read and it will wait for you here.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppDimens.xl),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Browse books'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load your cart'),
          const SizedBox(height: AppDimens.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
