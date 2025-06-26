// app_utils.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_sheets_service.dart';
import 'home_screen.dart';

class AppUtils {
  /// Universal logout: sign-out Google, clear prefs, navigate to HomeScreen.
  /// [service] can be null on HomeScreen where we only have GoogleSignIn.
  static Future<void> logout(
      BuildContext context, {
        GoogleSheetsService? service,
        Future<void> Function()? googleOnlySignOut,
      }) async {
    if (service != null) {
      await service.signOut();
    } else if (googleOnlySignOut != null) {
      await googleOnlySignOut();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
      );
    }
  }
}
