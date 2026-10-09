import 'package:bookhaven/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/admin/data/admin_book.dart';
import 'package:bookhaven/features/admin/data/admin_books_repository.dart';
import 'package:bookhaven/features/admin/presentation/providers/admin_books_controller.dart';
import 'package:bookhaven/features/admin/presentation/widgets/admin_book_tile.dart';

class ManageBooksScreen extends ConsumerStatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  ConsumerState<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends ConsumerState<ManageBooksScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(adminBooksControllerProvider.notifier).loadMore();
    }
  }

  void _soon(String page) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$page is the next page we build')),
      );
  }

  Future<void> _confirmDelete(AdminBook book) async {
    final c = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          'Delete this book?',
          style: TextStyle(color: c.textPrimary),
        ),
        content: Text(
          '"${book.title}" will be removed from the catalog, and from all carts, '
          'wishlists and reviews. Past orders keep their details.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminBooksControllerProvider.notifier).deleteBook(book);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('"${book.title}" deleted')));
    } on AdminActionException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not delete the book')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final state = ref.watch(adminBooksControllerProvider);
    final controller = ref.read(adminBooksControllerProvider.notifier);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminBookAdd),
        backgroundColor: c.primary,
        foregroundColor: onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add book'),
      ),
      body: Column(
        children: [
          _Header(onPrimary: onPrimary),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              AppDimens.lg,
              AppDimens.pagePadding,
              AppDimens.sm,
            ),
            child: TextField(
              controller: _search,
              onChanged: (v) {
                setState(() {});
                controller.setQuery(v);
              },
              textInputAction: TextInputAction.search,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by title or author',
                hintStyle: TextStyle(color: c.textSecondary),
                prefixIcon: Icon(Icons.search, color: c.textSecondary),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, color: c.textSecondary),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                          controller.setQuery('');
                        },
                      ),
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                  borderSide: BorderSide(color: c.primary, width: 1.4),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.pagePadding,
              ),
              children: [
                for (final f in AdminBookFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppDimens.sm),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: state.filter == f,
                      showCheckmark: false,
                      selectedColor: c.primary,
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.border),
                      labelStyle: TextStyle(
                        color: state.filter == f ? onPrimary : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => controller.setFilter(f),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePadding,
              AppDimens.sm,
              AppDimens.pagePadding,
              AppDimens.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.loading
                    ? 'LOADING…'
                    : '${state.total} ${state.total == 1 ? 'BOOK' : 'BOOKS'}',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: c.textSecondary),
              ),
            ),
          ),
          Expanded(child: _body(context, state, controller)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AdminBooksState state,
    AdminBooksController controller,
  ) {
    final c = context.palette;

    if (state.loading && state.items.isEmpty) {
      return Center(child: CircularProgressIndicator(color: c.accent));
    }

    if (state.error != null && state.items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: state.error!,
        actionLabel: 'Retry',
        onAction: controller.refresh,
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.refresh(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 60),
            _Message(
              icon: Icons.search_off,
              title: 'No books match your search',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: c.primary,
      onRefresh: () => controller.refresh(silent: true),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.pagePadding,
          0,
          AppDimens.pagePadding,
          100,
        ),
        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.md),
        itemBuilder: (context, i) {
          if (i >= state.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
              child: Center(child: CircularProgressIndicator(color: c.accent)),
            );
          }
          final book = state.items[i];
          return AdminBookTile(
            key: ValueKey(book.id),
            book: book,
            onEdit: () => context.push(AppRoutes.adminBookEditPath(book.id)),
            onDelete: () => _confirmDelete(book),
          ).animate().fadeIn(duration: 220.ms);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPrimary});
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primary, Colors.black, 0.3)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.sm,
            AppDimens.sm,
            AppDimens.pagePadding,
            AppDimens.xl,
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: onPrimary),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: AppDimens.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN',
                      style: text.labelMedium?.copyWith(color: c.accent),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage books',
                      style: text.headlineMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
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
              style: TextStyle(color: c.textSecondary, fontSize: 15),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppDimens.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
