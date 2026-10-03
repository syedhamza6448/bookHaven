import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/core/utils/formatters.dart';
import 'package:bookhaven/features/catalog/data/book_sort.dart';
import 'package:bookhaven/features/catalog/presentation/providers/category_providers.dart';
import 'package:bookhaven/features/search/data/search_filters.dart';
import 'package:bookhaven/features/search/presentation/providers/book_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<SearchFilters?> showSearchFilterSheet(
  BuildContext context,
  SearchFilters current,
) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});
  final SearchFilters initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late BookSort _sort = widget.initial.sort;
  late Set<String> _genres = {...widget.initial.genreIds};
  late double? _min = widget.initial.minPrice;
  late double? _max = widget.initial.maxPrice;
  late double? _rating = widget.initial.minRating;
  late bool _inStock = widget.initial.inStockOnly;

  void _reset() => setState(() {
    _sort = BookSort.popular;
    _genres = {};
    _min = null;
    _max = null;
    _rating = null;
    _inStock = false;
  });

  void _apply(double maxPrice) {
    final minV = (_min ?? 0) <= 0 ? null : _min;
    final maxV = (_max == null || _max! >= maxPrice) ? null : _max;
    Navigator.of(context).pop(
      SearchFilters(
        genreIds: _genres,
        minPrice: minV,
        maxPrice: maxV,
        minRating: _rating,
        inStockOnly: _inStock,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final genres = ref.watch(categoryGenresProvider);
    final maxPrice = ref.watch(searchMaxPriceProvider).value ?? 100.0;

    final range = RangeValues(
      (_min ?? 0).clamp(0, maxPrice).toDouble(),
      (_max ?? maxPrice).clamp(0, maxPrice).toDouble(),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDimens.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              AppDimens.lg,
              AppDimens.pagePadding,
              AppDimens.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Filter & sort',
                  style: t.headlineSmall?.copyWith(color: c.textPrimary),
                ),
                const Spacer(),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(context, 'SORT BY'),
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      for (final s in BookSort.values)
                        _pill(
                          context,
                          s.label,
                          _sort == s,
                          () => setState(() => _sort = s),
                        ),
                    ],
                  ),
                  _label(context, 'GENRE'),
                  genres.when(
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (_, __) => Text(
                      'Could not load genres.',
                      style: TextStyle(color: c.textSecondary),
                    ),
                    data: (list) => Wrap(
                      spacing: AppDimens.sm,
                      runSpacing: AppDimens.sm,
                      children: [
                        for (final g in list)
                          _pill(context, g.name, _genres.contains(g.id), () {
                            setState(() {
                              _genres.contains(g.id)
                                  ? _genres.remove(g.id)
                                  : _genres.add(g.id);
                            });
                          }),
                      ],
                    ),
                  ),
                  _label(context, 'PRICE'),
                  Text(
                    '${formatPrice(range.start)}  -  ${formatPrice(range.end)}',
                    style: t.titleMedium?.copyWith(color: c.primary),
                  ),
                  RangeSlider(
                    values: range,
                    min: 0,
                    max: maxPrice,
                    divisions: maxPrice.round().clamp(1, 200),
                    activeColor: c.primary,
                    inactiveColor: c.border,
                    onChanged: (v) => setState(() {
                      _min = v.start;
                      _max = v.end;
                    }),
                  ),
                  _label(context, 'MINIMUM RATING'),
                  Wrap(
                    spacing: AppDimens.sm,
                    children: [
                      _pill(
                        context,
                        'Any',
                        _rating == null,
                        () => setState(() => _rating = null),
                      ),
                      for (final r in [3.0, 4.0, 4.5])
                        _pill(
                          context,
                          '$r+',
                          _rating == r,
                          () => setState(() => _rating = r),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'In stock only',
                      style: t.bodyLarge?.copyWith(color: c.textPrimary),
                    ),
                    value: _inStock,
                    activeThumbColor: c.primary,
                    onChanged: (v) => setState(() => _inStock = v),
                  ),
                  const SizedBox(height: AppDimens.lg),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              AppDimens.sm,
              AppDimens.pagePadding,
              AppDimens.lg,
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: FilledButton(
                onPressed: () => _apply(maxPrice),
                child: const Text('Show results'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.xl, bottom: AppDimens.md),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: c.accent),
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    String text,
    bool selected,
    VoidCallback onTap,
  ) {
    final c = context.palette;
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: c.primary,
      backgroundColor: c.surface,
      side: BorderSide(color: selected ? c.primary : c.border),
      labelStyle: TextStyle(color: selected ? Colors.white : c.textPrimary),
    );
  }
}
