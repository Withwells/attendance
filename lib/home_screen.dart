import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_sheets_service.dart';
import 'setup_wizard_screen.dart';
import 'admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  bool   _busy   = false;
  String _status = '';
  String? _spreadsheetId;
  String? _businessName;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _spreadsheetId = prefs.getString('spreadsheetId');
      _businessName  = prefs.getString('businessName');
    });
  }

  /* ─────────── Sign-In ─────────── */
  Future<void> _handleSignIn() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final user = await _googleSignIn.signIn();
      if (user == null) { _reset('Sign-in cancelled'); return; }

      final svc   = await GoogleSheetsService.fromGoogleSignIn(user);
      final found = await svc.findExistingAttendanceFolder();

      if (found == null) { _reset('No business found. Run setup first.'); return; }

      _spreadsheetId = found['spreadsheetId'];
      _businessName  = found['businessName'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('spreadsheetId', _spreadsheetId!);
      await prefs.setString('businessName',  _businessName!);

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(
            sheetsService : svc,
            spreadsheetId : _spreadsheetId!,
          ),
        ),
      );
    } catch (e) {
      _reset('Error: $e');
    }
  }

  /* ─────────── Setup ─────────── */
  Future<void> _startSetup() async {
    setState(() => _busy = true);

    try {
      final user = await _googleSignIn.signIn();
      if (user == null) { _reset('Setup cancelled'); return; }

      final svc = await GoogleSheetsService.fromGoogleSignIn(user);
      final exists = await svc.findExistingAttendanceFolder();
      if (exists != null) { _reset('Business already set up.'); return; }

      if (!context.mounted) return;

      final Map<String, dynamic>? result =
      await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => SetupWizardScreen(
            sheetsService: svc,
            adminEmail: user.email,
          ),
        ),
      );

      setState(() {
        _status = '';
        _busy   = false;
      });

      if (result != null && result['spreadsheetId'] != null) {
        // 🎉 Show success SnackBar with icon
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Setup complete! Redirecting to sign-in…'),
                ),
              ],
            ),
          ),
        );

        // ⏳ After 3 seconds, auto-trigger sign-in
        Future.delayed(const Duration(seconds: 3), _handleSignIn);
      }
    } catch (e) {
      _reset('Setup error: $e');
    }
  }

  /* ─────────── Logout ─────────── */
  Future<void> _handleLogout() async {
    await _googleSignIn.signOut();
    setState(() {
      _status        = '';
      _businessName  = null;
      _spreadsheetId = null;
    });
  }

  /* ─────────── Helpers ─────────── */
  void _reset(String msg) => setState(() { _status = msg; _busy = false; });

  /* ─────────── UI ─────────── */
  @override
  Widget build(BuildContext context) {
    const appTitle = 'Business Attendance';

    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle),
        actions: [
          TextButton(
            onPressed: _handleLogout,
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_status.isNotEmpty) Text(_status),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _handleSignIn,
                child: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : _startSetup,
                child: const Text('New business? Set up now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
