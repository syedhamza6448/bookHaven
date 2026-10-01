import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:bookhaven/core/constants/app_strings.dart';
import 'package:bookhaven/core/theme/app_theme.dart';
import 'package:bookhaven/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookHavenApp extends ConsumerWidget {
  const BookHavenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const _ThemePreviewScreen(),
    );
  }
}

class _ThemePreviewScreen extends ConsumerWidget {
  const _ThemePreviewScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimens.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.newArrivals, style: text.labelMedium),
            const SizedBox(height: AppDimens.sm),
            Text(AppStrings.tagline, style: text.displaySmall),
            const SizedBox(height: AppDimens.md),
            Text(
              'Body text in DM Sans looks like this, clean and easy to read.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: AppDimens.xl),
            const TextField(
              decoration: InputDecoration(labelText: AppStrings.email),
            ),
            const SizedBox(height: AppDimens.lg),
            ElevatedButton(
              onPressed: () {},
              child: const Text(AppStrings.login),
            ),
            const SizedBox(height: AppDimens.md),
            OutlinedButton(
              onPressed: () {},
              child: const Text(AppStrings.register),
            ),
          ],
        ),
      ),
    );
  }
}
