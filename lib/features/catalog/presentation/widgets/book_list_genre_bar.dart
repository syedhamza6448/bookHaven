import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/home/presentation/providers/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BookListGenreBar extends ConsumerWidget {
  const BookListGenreBar({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(genresProvider);

    return genres.when(
      loading: () => const SizedBox(height: 44),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
          itemCount: list.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final genre = i == 0 ? null : list[i - 1];
            final id = genre?.id.toString();
            final selected = i == 0 ? selectedId == null : selectedId == id;
            return _Pill(
              label: genre?.name ?? 'All',
              selected: selected,
              onTap: () => onSelected(id),
            );
          },
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.primary : context.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? context.primary : context.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.onPrimary : context.textPrimary,
          ),
        ),
      ),
    );
  }
}