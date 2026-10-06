import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/profile/data/saved_card_repository.dart';
import 'package:bookhaven/features/profile/presentation/providers/saved_card_providers.dart';
import 'package:bookhaven/features/profile/presentation/widgets/saved_card_editor_sheet.dart';
import 'package:bookhaven/features/profile/presentation/widgets/saved_card_tile.dart';
import 'package:bookhaven/shared/models/saved_card.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  String? _busyId;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorText(Object e) =>
      kDebugMode ? '$e' : 'Something went wrong. Please try again.';

  Future<void> _refresh() async {
    ref.invalidate(savedCardsProvider);
    try {
      await ref.read(savedCardsProvider.future);
    } catch (_) {}
  }

  Future<void> _add(List<SavedCard> current) async {
    final saved = await showSavedCardEditorSheet(
      context,
      isFirst: current.isEmpty,
    );
    if (saved == true) _snack('Card saved');
  }

  Future<void> _setDefault(SavedCard card) async {
    setState(() => _busyId = card.id);
    try {
      await ref.read(savedCardRepositoryProvider).setDefault(card.id);
      ref.invalidate(savedCardsProvider);
      _snack('Default card updated');
    } catch (e) {
      _snack(_errorText(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(SavedCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this card?'),
        content: Text(
          '${card.brand.label} ending in ${card.last4} will be removed from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busyId = card.id);
    try {
      await ref.read(savedCardRepositoryProvider).delete(card.id);
      ref.invalidate(savedCardsProvider);
      _snack('Card removed');
    } catch (e) {
      _snack(_errorText(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final cardsAsync = ref.watch(savedCardsProvider);
    final cards = cardsAsync.value ?? const <SavedCard>[];

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: cardsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const _Skeleton(),
                error: (e, _) => _ErrorView(onRetry: _refresh),
                data: (list) => list.isEmpty
                    ? const _EmptyView()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.pagePadding,
                          AppDimens.xl,
                          AppDimens.pagePadding,
                          AppDimens.xl,
                        ),
                        itemCount: list.length + 1,
                        itemBuilder: (context, i) {
                          if (i == list.length) return const _CodNote();
                          final card = list[i];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppDimens.lg,
                            ),
                            child:
                                SavedCardTile(
                                      card: card,
                                      busy: _busyId == card.id,
                                      onSetDefault: () => _setDefault(card),
                                      onDelete: () => _delete(card),
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: (60 * i).ms,
                                      duration: 350.ms,
                                    )
                                    .slideY(begin: 0.06, end: 0),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.pagePadding,
            AppDimens.sm,
            AppDimens.pagePadding,
            AppDimens.lg,
          ),
          child: SizedBox(
            height: AppDimens.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: cardsAsync.hasError ? null : () => _add(cards),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add new card'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.sm,
        MediaQuery.paddingOf(context).top + AppDimens.sm,
        AppDimens.pagePadding,
        AppDimens.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightPrimary, Color(0xFF14282A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.onPrimary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppDimens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR WALLET',
                  style: t.labelMedium?.copyWith(color: AppColors.darkAccent),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment methods',
                  style: t.headlineMedium?.copyWith(color: AppColors.onPrimary),
                ),
                const SizedBox(height: AppDimens.md),
                Container(width: 44, height: 1.5, color: AppColors.darkAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodNote extends StatelessWidget {
  const _CodNote();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: c.accent),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(
              'Cash on Delivery is always available at checkout. There is nothing to save for it.',
              style: t.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.pagePadding),
      children: [
        const SizedBox(height: AppDimens.xxl),
        Icon(Icons.credit_card_off_outlined, size: 56, color: c.accent),
        const SizedBox(height: AppDimens.lg),
        Text(
          'No cards saved yet',
          textAlign: TextAlign.center,
          style: t.headlineSmall,
        ),
        const SizedBox(height: AppDimens.sm),
        Text(
          'Add a card to check out faster next time.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppDimens.xl),
        const _CodNote(),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.pagePadding),
      children: [
        const SizedBox(height: AppDimens.xxl),
        Icon(Icons.error_outline_rounded, size: 48, color: c.error),
        const SizedBox(height: AppDimens.lg),
        Text(
          'Could not load your cards',
          textAlign: TextAlign.center,
          style: t.titleMedium,
        ),
        const SizedBox(height: AppDimens.md),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        children: List.generate(
          2,
          (_) => Container(
            height: 176,
            margin: const EdgeInsets.only(bottom: AppDimens.xl),
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            ),
          ),
        ),
      ),
    );
  }
}
