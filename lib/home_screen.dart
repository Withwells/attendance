import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add shared_preferences in pubspec.yaml

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

  bool _isSigningIn = false;
  String _status = 'Not signed in';

  String? _spreadsheetId;
  String? _businessName;

  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  Future<void> _loadSetupData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _spreadsheetId = prefs.getString('spreadsheetId');
      _businessName = prefs.getString('businessName');
    });
  }

  Future<void> _startSetup() async {
    if (_spreadsheetId != null) {
      // Setup already done
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business already set up.')),
      );
      return;
    }

    // Start Google Sign-In inside setup wizard flow
    setState(() => _isSigningIn = true);

    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        setState(() {
          _status = 'Sign-in cancelled';
          _isSigningIn = false;
        });
        return;
      }

      final sheetsService = await GoogleSheetsService.fromGoogleSignIn(user);

      // Go to SetupWizardScreen, no spreadsheetId yet (setup will create)
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => SetupWizardScreen(
            sheetsService: sheetsService,
            spreadsheetId: '', // empty because setup creates new
            adminEmail: user.email,
          ),
        ),
      );

      // SetupWizardScreen should return spreadsheetId and businessName on success
      if (result != null && result['spreadsheetId'] != null && result['businessName'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spreadsheetId', result['spreadsheetId']);
        await prefs.setString('businessName', result['businessName']);

        setState(() {
          _spreadsheetId = result['spreadsheetId'];
          _businessName = result['businessName'];
          _status = 'Setup complete. Please sign in.';
          _isSigningIn = false;
        });
      } else {
        setState(() {
          _status = 'Setup cancelled or failed.';
          _isSigningIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error during setup: $e';
        _isSigningIn = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    if (_spreadsheetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete business setup first.')),
      );
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        setState(() {
          _status = 'Sign-in cancelled';
          _isSigningIn = false;
        });
        return;
      }

      final sheetsService = await GoogleSheetsService.fromGoogleSignIn(user);

      // Proceed to admin dashboard directly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboard(
            sheetsService: sheetsService,
            spreadsheetId: _spreadsheetId!,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error signing in: $e';
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_businessName == null || _businessName!.isEmpty)
        ? 'Attendance App'
        : '$_businessName - Attendance';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_status),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSigningIn ? null : _startSetup,
                child: const Text('Setup Business'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSigningIn ? null : _handleSignIn,
                child: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
