import 'package:bookhaven/app.dart';
import 'package:bookhaven/core/constants/supabase_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
    );
  } catch (e) {
    debugPrint("Supabase init failed: $e");
  }

  runApp(const ProviderScope(child: BookHavenApp()));
}
