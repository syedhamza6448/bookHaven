import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please verify your email first. Check your inbox.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Too many attempts, Please wait a moment and try again.';
    }
    return e.message;
  }
  if (e is SocketException) {
    return 'No internet connection. Please check your network.'; 
  }
  return 'Something went wrong. Please try again.';
}
