import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_sheets_service.dart';
import 'setup_wizard_screen.dart';
import 'admin_dashboard.dart';
import 'app_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSignIn _google = GoogleSignIn(scopes: [
    'email',
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file',
  ]);

  bool   _busy = false;
  String _msg  = '';

  /* ───────── prefs ───────── */
  Future<String?> _prefSheet() async =>
      (await SharedPreferences.getInstance()).getString('spreadsheetId');

  Future<void> _savePrefs(String id, String biz) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('spreadsheetId', id);
    await p.setString('businessName',  biz);
  }

  /* ───────── sign-in ───────── */
  Future<void> _signIn() async {
    if (_busy) return;
    setState(() { _busy = true; _msg = ''; });

    try {
      final user = await _google.signIn();
      if (user == null) return _reset('Sign-in cancelled');

      final svc = await GoogleSheetsService.fromGoogleSignIn(user);

      /* 1) prefer stored ID */
      final storedId = await _prefSheet();
      if (storedId != null) {
        _openDashboard(svc, storedId); return;
      }

      /* 2) else search Drive */
      final found = await svc.findExistingAttendanceFolder();
      if (found == null) return _reset('No business found. Run setup.');

      await _savePrefs(found['spreadsheetId']!, found['businessName']!);
      _openDashboard(svc, found['spreadsheetId']!);
    } catch (e) {
      _reset('Error: $e');
    }
  }

  void _openDashboard(GoogleSheetsService svc, String id) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDashboard(
          sheetsService: svc,
          spreadsheetId: id,
        ),
      ),
    );
  }

  /* ───────── setup ───────── */
  Future<void> _setup() async {
    if (_busy) return;
    setState(() { _busy = true; _msg = ''; });

    try {
      final user = await _google.signIn();
      if (user == null) return _reset('Setup cancelled');

      final svc = await GoogleSheetsService.fromGoogleSignIn(user);

      final exists = await svc.findExistingAttendanceFolder();
      if (exists != null) return _reset('Business already set up.');

      if (!context.mounted) return;

      final Map<String, String>? res =
      await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (_) => SetupWizardScreen(
            sheetsService: svc,
            adminEmail: user.email,
          ),
        ),
      );

      if (res != null) {
        await _savePrefs(res['spreadsheetId']!, res['businessName']!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Setup complete! Redirecting to sign-in…'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _busy = false);
        Future.delayed(const Duration(seconds: 3), _signIn);
      } else {
        _reset('Setup cancelled');
      }
    } catch (e) {
      _reset('Setup error: $e');
    }
  }

  /* ───────── logout ───────── */
  Future<void> _logout() async =>
      AppUtils.logout(context, googleOnlySignOut: _google.signOut);

  /* ───────── helpers ───────── */
  void _reset(String m) => setState(() { _msg = m; _busy = false; });

  /* ───────── UI ───────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Attendance')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_msg.isNotEmpty) Text(_msg),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _signIn,
                child: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _logout,
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : _setup,
                child: const Text('New business? Set up now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
