import 'package:bookhaven/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/home/presentation/providers/home_providers.dart';
import 'package:bookhaven/features/home/presentation/widgets/book_shelf.dart';
import 'package:bookhaven/features/home/presentation/widgets/featured_banner.dart';
import 'package:bookhaven/features/home/presentation/widgets/genre_chips.dart';
import 'package:bookhaven/features/home/presentation/widgets/home_header.dart';
import 'package:bookhaven/features/home/presentation/widgets/home_search_bar.dart';
import 'package:bookhaven/shared/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Temporary until Book Details and Search are built
  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$what is coming in the next step.')),
      );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(featuredBookProvider)
      ..invalidate(genresProvider)
      ..invalidate(bestsellersProvider)
      ..invalidate(newArrivalsProvider);
    try {
      await ref.read(bestsellersProvider.future);
    } catch (_) {}
  }

  Widget _stagger(Widget child, int index) => child
      .animate()
      .fadeIn(duration: 500.ms, delay: (index * 90).ms)
      .slideY(begin: 0.04, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userFirstNameProvider);
    final featured = ref.watch(featuredBookProvider);
    final genres = ref.watch(genresProvider);
    final bestsellers = ref.watch(bestsellersProvider);
    final arrivals = ref.watch(newArrivalsProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.primary,
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppDimens.xxl),
            children: [
              _stagger(HomeHeader(name: name), 0),
              _stagger(
                HomeSearchBar(
                  onTap: () =>
                      context.push(AppRoutes.bookListPath(title: 'All Books')),
                ),
                1,
              ),
              _stagger(
                featured.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.pagePadding,
                      AppDimens.xl,
                      AppDimens.pagePadding,
                      0,
                    ),
                    child: Shimmer.fromColors(
                      baseColor: context.border,
                      highlightColor: context.surface,
                      child: Container(
                        height: 178,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusCard,
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (book) => book == null
                      ? const SizedBox.shrink()
                      : FeaturedBanner(
                          book: book,
                          onTap: () => context.push(
                            AppRoutes.bookDetailsPath('${book.id}'),
                          ),
                        ),
                ),
                2,
              ),
              _stagger(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Browse by genre'),
                    genres.when(
                      loading: () => const GenreChipsShimmer(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) => GenreChips(
                        genres: list,
                        onTap: (genre) => context.push(
                          AppRoutes.bookListPath(
                            title: genre.name,
                            genreId: genre.id.toString(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                3,
              ),
              _stagger(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Bestsellers',
                      onSeeAll: () => context.push(
                        AppRoutes.bookListPath(
                          title: 'Bestsellers',
                          sort: 'popular',
                        ),
                      ),
                    ),
                    BookShelf(
                      books: bestsellers,
                      heroPrefix: 'bestseller',
                      onBookTap: (book) => context.push(
                        AppRoutes.bookDetailsPath(
                          '${book.id}',
                          heroTag: 'bestseller-${book.id}',
                        ),
                      ),
                      onRetry: () => ref.invalidate(bestsellersProvider),
                    ),
                  ],
                ),
                4,
              ),
              _stagger(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'New arrivals',
                      onSeeAll: () => context.push(
                        AppRoutes.bookListPath(
                          title: 'New Arrivals',
                          sort: 'newest',
                        ),
                      ),
                    ),
                    BookShelf(
                      books: arrivals,
                      heroPrefix: 'arrival',
                      onBookTap: (book) => context.push(
                        AppRoutes.bookDetailsPath(
                          '${book.id}',
                          heroTag: 'arrival-${book.id}',
                        ),
                      ),
                      onRetry: () => ref.invalidate(newArrivalsProvider),
                    ),
                  ],
                ),
                5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
