import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/catalog/presentation/providers/category_providers.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/author_tile.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/genre_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key, this.initialTab = 0});

  /// 0 = Genres, 1 = Authors
  final int initialTab;

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late int _tab = widget.initialTab;
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePadding,
                AppDimens.md,
                AppDimens.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (context.canPop())
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: c.textPrimary,
                      ),
                    ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    'BROWSE',
                    style: t.labelMedium?.copyWith(color: c.accent),
                  ),
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    'Find your shelf.',
                    style: t.headlineMedium?.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  _TabSwitch(
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _tab == 0
                    ? _GenresTab(key: const ValueKey('genres'))
                    : _AuthorsTab(
                        key: const ValueKey('authors'),
                        controller: _search,
                        query: _query,
                        onQuery: (v) => setState(() => _query = v),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = Theme.of(context).textTheme;
    const labels = ['GENRES', 'AUTHORS'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusInput),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: List.generate(2, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppDimens.radiusInput - 3,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: t.labelMedium?.copyWith(
                    color: selected ? Colors.white : c.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GenresTab extends ConsumerWidget {
  const _GenresTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(categoryGenresProvider);

    return genres.when(
      loading: () => const _GridSkeleton(),
      error: (e, _) => _ErrorState(
        message: 'Could not load genres.',
        onRetry: () => ref.invalidate(categoryGenresProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyState(message: 'No genres on the shelves yet.');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(categoryGenresProvider.future),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              0,
              AppDimens.pagePadding,
              AppDimens.xxl,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppDimens.lg,
              crossAxisSpacing: AppDimens.lg,
              childAspectRatio: 1.05,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final g = list[i];
              return GenreTile(
                    genre: g,
                    onTap: () => context.push(
                      AppRoutes.bookListPath(title: g.name, genreId: g.id),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (50 * i).ms, duration: 350.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
            },
          ),
        );
      },
    );
  }
}

class _AuthorsTab extends ConsumerWidget {
  const _AuthorsTab({
    super.key,
    required this.controller,
    required this.query,
    required this.onQuery,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final authors = ref.watch(categoryAuthorsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.pagePadding,
          ),
          child: TextField(
            controller: controller,
            onChanged: onQuery,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search authors',
              prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, color: c.textSecondary),
                      onPressed: () {
                        controller.clear();
                        onQuery('');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Expanded(
          child: authors.when(
            loading: () => const _ListSkeleton(),
            error: (e, _) => _ErrorState(
              message: 'Could not load authors.',
              onRetry: () => ref.invalidate(categoryAuthorsProvider),
            ),
            data: (all) {
              final q = query.trim().toLowerCase();
              final list = q.isEmpty
                  ? all
                  : all.where((a) => a.name.toLowerCase().contains(q)).toList();
              if (list.isEmpty) {
                return _EmptyState(
                  message: q.isEmpty
                      ? 'No authors yet.'
                      : 'No authors match "$query".',
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(categoryAuthorsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadding,
                    0,
                    AppDimens.pagePadding,
                    AppDimens.xxl,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.6,
                    color: c.accent.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return AuthorTile(
                      author: a,
                      onTap: () => context.push(
                        AppRoutes.bookListPath(title: a.name, authorId: a.id),
                      ),
                    ).animate().fadeIn(
                      delay: (30 * (i > 12 ? 12 : i)).ms,
                      duration: 300.ms,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppDimens.lg,
          crossAxisSpacing: AppDimens.lg,
          childAspectRatio: 1.05,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.border,
      highlightColor: c.surface,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
        itemCount: 7,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.border,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, color: c.border),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 70, color: c.border),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 40, color: c.textSecondary),
          const SizedBox(height: AppDimens.md),
          Text(message, style: TextStyle(color: c.textPrimary)),
          const SizedBox(height: AppDimens.sm),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Center(
      child: Text(message, style: TextStyle(color: c.textSecondary)),
    );
  }
}
