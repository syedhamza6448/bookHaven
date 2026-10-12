import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main.dart with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return saved == 'light'
        ? ThemeMode.light
        : ThemeMode.dark; // dark = default
  }

  void setMode(ThemeMode mode) {
    state = mode;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
  }

  void toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
