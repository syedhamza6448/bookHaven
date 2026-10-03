import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/catalog/presentation/providers/category_providers.dart';
import 'package:bookhaven/features/search/data/search_filters.dart';
import 'package:bookhaven/features/search/presentation/providers/book_search_controller.dart';
import 'package:bookhaven/features/search/presentation/widgets/search_filter_sheet.dart';
import 'package:bookhaven/features/search/presentation/widgets/search_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery, this.initialGenreId});

  final String? initialQuery;
  final String? initialGenreId;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialQuery ?? '',
  );
  final _focus = FocusNode();
  final _scroll = ScrollController();

  bool get _hasInitial =>
      (widget.initialQuery?.isNotEmpty ?? false) ||
      (widget.initialGenreId?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
        ref.read(bookSearchControllerProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bookSearchControllerProvider.notifier)
          .init(query: widget.initialQuery, genreId: widget.initialGenreId);
      if (!_hasInitial) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final ctrl = ref.read(bookSearchControllerProvider.notifier);
    final current = ref.read(bookSearchControllerProvider).filters;
    final result = await showSearchFilterSheet(context, current);
    if (result != null) ctrl.applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final s = ref.watch(bookSearchControllerProvider);
    final ctrl = ref.read(bookSearchControllerProvider.notifier);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.sm,
                AppDimens.sm,
                AppDimens.pagePadding,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop() ? context.pop() : null,
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: c.textPrimary),
                      onChanged: (v) {
                        ctrl.onQueryChanged(v);
                        setState(() {});
                      },
                      onSubmitted: ctrl.submit,
                      decoration: InputDecoration(
                        hintText: 'Title, author or genre',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: c.textSecondary,
                        ),
                        suffixIcon: _text.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: c.textSecondary,
                                ),
                                onPressed: () {
                                  _text.clear();
                                  ctrl.onQueryChanged('');
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  _FilterButton(
                    count: s.filters.activeCount,
                    onTap: _openFilters,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Expanded(child: _buildBody(context, s, ctrl, c, t)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookSearchState s,
    BookSearchController ctrl,
    BuildContext c,
    TextTheme t,
  ) {
    if (!s.hasCriteria) {
      return _DiscoverView(
        recent: s.recent,
        onRecentTap: (q) {
          _text.text = q;
          _text.selection = TextSelection.collapsed(offset: q.length);
          ctrl.submit(q);
          _focus.unfocus();
          setState(() {});
        },
        onRecentRemove: ctrl.removeRecent,
        onClearRecent: ctrl.clearRecent,
        onGenreTap: (id) {
          _focus.unfocus();
          ctrl.applyFilters(s.filters.copyWith(genreIds: {id}));
        },
      );
    }

    if (s.isLoading && s.books.isEmpty) return const _ResultsSkeleton();

    if (s.error != null && s.books.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: s.error!,
        action: 'Try again',
        onAction: ctrl.retry,
      );
    }

    if (s.books.isEmpty) {
      return _Message(
        icon: Icons.search_off_rounded,
        title: 'No books found',
        subtitle: 'Try a different word, or loosen your filters.',
        action: s.filters.activeCount > 0 ? 'Clear filters' : null,
        onAction: ctrl.clearFilters,
      );
    }

    final sortLabel = s.filters.sort.label;
    return ListView.separated(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.sm,
        AppDimens.pagePadding,
        AppDimens.xxl,
      ),
      itemCount: s.books.length + 2,
      separatorBuilder: (_, i) => i == 0 || i >= s.books.length
          ? const SizedBox.shrink()
          : Divider(
              height: 1,
              thickness: 0.6,
              color: c.accent.withValues(alpha: 0.35),
            ),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: Row(
              children: [
                Text(
                  s.total == 1 ? '1 RESULT' : '${s.total} RESULTS',
                  style: t.labelMedium?.copyWith(color: c.accent),
                ),
                const Spacer(),
                Text(
                  'Sorted by $sortLabel',
                  style: t.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          );
        }
        final index = i - 1;
        if (index >= s.books.length) {
          if (s.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(AppDimens.xl),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (!s.hasMore) {
            return Padding(
              padding: const EdgeInsets.all(AppDimens.xl),
              child: Center(
                child: Text(
                  'END OF THE SHELF',
                  style: t.labelMedium?.copyWith(color: c.textSecondary),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final book = s.books[index];
        final tag = 'search-${book.id}';
        return SearchResultTile(
          book: book,
          heroTag: tag,
          onTap: () {
            ctrl.rememberCurrentQuery();
            context.push(
              AppRoutes.bookDetailsPath(book.id.toString(), heroTag: tag),
            );
          },
        ).animate().fadeIn(delay: (30 * (index % 12)).ms, duration: 300.ms);
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: count > 0 ? c.primary : c.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusInput),
              border: Border.all(color: count > 0 ? c.primary : c.border),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: count > 0 ? Colors.white : c.textPrimary,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscoverView extends ConsumerWidget {
  const _DiscoverView({
    required this.recent,
    required this.onRecentTap,
    required this.onRecentRemove,
    required this.onClearRecent,
    required this.onGenreTap,
  });

  final List<String> recent;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRecentRemove;
  final VoidCallback onClearRecent;
  final ValueChanged<String> onGenreTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    final genres = ref.watch(categoryGenresProvider);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppDimens.pagePadding),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'RECENT SEARCHES',
                style: t.labelMedium?.copyWith(color: c.accent),
              ),
              const Spacer(),
              TextButton(onPressed: onClearRecent, child: const Text('Clear')),
            ],
          ),
          for (final q in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.history_rounded, color: c.textSecondary),
              title: Text(q, style: TextStyle(color: c.textPrimary)),
              trailing: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: c.textSecondary,
                ),
                onPressed: () => onRecentRemove(q),
              ),
              onTap: () => onRecentTap(q),
            ),
          const SizedBox(height: AppDimens.xl),
        ],
        Text(
          'BROWSE BY GENRE',
          style: t.labelMedium?.copyWith(color: c.accent),
        ),
        const SizedBox(height: AppDimens.md),
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
                ActionChip(
                  label: Text(g.name),
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.border),
                  labelStyle: TextStyle(color: c.textPrimary),
                  onPressed: () => onGenreTap(g.id),
                ),
            ],
          ),
        ),
      ].animate(interval: 40.ms).fadeIn(duration: 300.ms),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: AppDimens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10, width: 60, color: c.border),
                    const SizedBox(height: 10),
                    Container(height: 14, width: 180, color: c.border),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 110, color: c.border),
                    const SizedBox(height: 14),
                    Container(height: 12, width: 70, color: c.border),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: c.textSecondary),
            const SizedBox(height: AppDimens.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(color: c.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimens.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: c.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDimens.md),
              TextButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
