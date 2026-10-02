import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/constants/app_strings.dart';
import 'package:bookhaven/core/router/app_router.dart';
import 'package:bookhaven/core/theme/app_theme.dart';
import 'package:bookhaven/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookHavenApp extends ConsumerWidget {
  const BookHavenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

