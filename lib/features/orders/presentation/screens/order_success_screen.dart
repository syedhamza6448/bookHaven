import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    this.orderNumber,
  });
  final String orderId;
  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 72, color: c.primary),
                const SizedBox(height: AppDimens.lg),
                Text(
                  'Order placed',
                  style: text.headlineMedium?.copyWith(color: c.textPrimary),
                ),
                if (orderNumber != null) ...[
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    orderNumber!,
                    style: text.titleMedium?.copyWith(color: c.accent),
                  ),
                ],
                const SizedBox(height: AppDimens.xl),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Continue shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
