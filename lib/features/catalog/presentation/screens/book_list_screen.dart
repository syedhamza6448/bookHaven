import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/router/app_routes.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/catalog/data/book_list_repository.dart';
import 'package:bookhaven/features/catalog/presentation/providers/book_list_controller.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/book_grid_card.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/book_list_genre_bar.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/book_list_skeleton.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/book_list_tile.dart';
import 'package:bookhaven/features/catalog/presentation/widgets/sort_sheet.dart';
import 'package:bookhaven/shared/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key, required this.args});

  final BookListArgs args;

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) {
      final s = ref.read(bookListControllerProvider(widget.args));
      if (!s.loadMoreFailed) {
        ref.read(bookListControllerProvider(widget.args).notifier).loadMore();
      }
    }
  }

  void _openBook(Book book) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Details for "${book.title}" are coming up next.'),
        ),
      );
  }

  Future<void> _pickSort(
    BookListState state,
    BookListController controller,
  ) async {
    final picked = await showSortSheet(context, state.sort);
    if (picked != null) {
      await controller.setSort(picked);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = bookListControllerProvider(widget.args);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final pad = AppDimens.pagePadding;

    return Scaffold(
      backgroundColor: context.bg,
      body: RefreshIndicator(
        color: context.primary,
        backgroundColor: context.surface,
        onRefresh: controller.refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: context.bg,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: context.textPrimary,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
              title: Text(
                widget.args.title,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: state.isGrid ? 'List view' : 'Grid view',
                  icon: Icon(
                    state.isGrid
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_rounded,
                    color: context.textPrimary,
                  ),
                  onPressed: controller.toggleView,
                ),
                IconButton(
                  tooltip: 'Sort',
                  icon: Icon(Icons.tune_rounded, color: context.textPrimary),
                  onPressed: () => _pickSort(state, controller),
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(
              child: BookListGenreBar(
                selectedId: state.genreId,
                onSelected: (id) async {
                  await controller.setGenre(id);
                  if (_scroll.hasClients) _scroll.jumpTo(0);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _pickSort(state, controller),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Text(
                                state.sort.label.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                  color: context.textSecondary,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: context.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (!state.isLoading && state.error == null)
                          Text(
                            '${state.books.length}${state.hasMore ? '+' : ''} titles',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      color: context.accent.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            _buildBody(context, state, controller),
            SliverToBoxAdapter(child: _buildFooter(context, state, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookListState state,
    BookListController controller,
  ) {
    if (state.isLoading) return BookListSkeleton(isGrid: state.isGrid);

    if (state.error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageView(
          icon: Icons.wifi_off_rounded,
          title: 'Something went wrong',
          message: state.error!,
          actionLabel: 'Try again',
          onAction: controller.refresh,
        ),
      );
    }

    if (state.books.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _MessageView(
          icon: Icons.menu_book_outlined,
          title: 'No books on this shelf yet',
          message: 'Try another genre or change the sort order.',
          actionLabel: state.genreId != null ? 'Show all genres' : null,
          onAction: () => controller.setGenre(null),
        ),
      );
    }

    return state.isGrid ? _buildGrid(state) : _buildList(state);
  }

  Widget _buildGrid(BookListState state) {
    const spacing = 14.0;
    final pad = AppDimens.pagePadding;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final w = (constraints.crossAxisExtent - spacing) / 2;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: spacing,
              mainAxisSpacing: 22,
              mainAxisExtent: w * 1.5 + 104,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final book = state.books[i];
              return BookGridCard(
                    book: book,
                    heroTag: 'list-${book.id}',
                    onTap: () => _openBook(book),
                  )
                  .animate(key: ValueKey('g-${book.id}'))
                  .fadeIn(
                    duration: 350.ms,
                    delay: ((i % BookListRepository.pageSize) * 45).ms,
                  )
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
            }, childCount: state.books.length),
          );
        },
      ),
    );
  }

  Widget _buildList(BookListState state) {
    final pad = AppDimens.pagePadding;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(pad, 4, pad, 8),
      sliver: SliverList.separated(
        itemCount: state.books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final book = state.books[i];
          return BookListTile(
                book: book,
                heroTag: 'list-${book.id}',
                onTap: () => _openBook(book),
              )
              .animate(key: ValueKey('l-${book.id}'))
              .fadeIn(
                duration: 350.ms,
                delay: ((i % BookListRepository.pageSize) * 40).ms,
              )
              .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    BookListState state,
    BookListController controller,
  ) {
    if (state.isLoading || state.error != null || state.books.isEmpty) {
      return const SizedBox(height: 32);
    }

    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: context.primary,
            ),
          ),
        ),
      );
    }

    if (state.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: TextButton.icon(
            onPressed: controller.loadMore,
            icon: Icon(Icons.refresh_rounded, color: context.primary),
            label: Text(
              "Couldn't load more. Tap to retry",
              style: GoogleFonts.dmSans(color: context.primary),
            ),
          ),
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.pagePadding + 60,
          28,
          AppDimens.pagePadding + 60,
          40,
        ),
        child: Column(
          children: [
            Container(height: 1, color: context.accent.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'END OF THE SHELF',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 32);
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: context.accent),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.4,
              color: context.textSecondary,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
