import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/theme/app_palette.dart';

class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.url, required this.title});

  final String? url;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback(context);
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (_, __) => ColoredBox(color: context.border),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        color: context.primary,
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
      );
}