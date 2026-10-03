import 'package:bookhaven/core/theme/app_palette.dart';
import 'package:bookhaven/features/catalog/data/book_sort.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<BookSort?> showSortSheet(BuildContext context, BookSort current) {
  return showModalBottomSheet<BookSort>(
    context: context,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'SORT BY',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
                color: ctx.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            for (final sort in BookSort.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  sort.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: sort == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: sort == current ? ctx.primary : ctx.textPrimary,
                  ),
                ),
                trailing: sort == current
                    ? Icon(Icons.check_rounded, color: ctx.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(sort),
              ),
          ],
        ),
      ),
    ),
  );
}
