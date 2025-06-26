import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_sheets_service.dart';
import 'setup_wizard_screen.dart';
import 'admin_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

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

  String _status = 'Not signed in';
  bool _isSigningIn = false;

  Future<void> _handleSignIn() async {
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

      // Check if spreadsheet ID is stored locally
      String? storedId = await GoogleSheetsService.getStoredSpreadsheetId();
      String spreadsheetId;

      if (storedId == null) {
        // No stored sheet, create new one
        spreadsheetId = await sheetsService.createAttendanceSheet('MyBusiness');

        // Initialize with default settings and empty employees list
        await sheetsService.initializeSheet(
          spreadsheetId,
          [],
          user.email,
          {
            'requirePhoto': false,
            'requireLocation': false,
            'enableTaskEntry': false,
          },
        );

        // Store spreadsheet ID for future use
        await GoogleSheetsService.storeSpreadsheetId(spreadsheetId);
      } else {
        spreadsheetId = storedId;
      }

      setState(() {
        _status = 'Signed in as ${user.email}';
        _isSigningIn = false;
      });

      // Navigate to Setup Wizard if first time (no setup done)
      bool setupExists = await sheetsService.checkIfSetupExists(spreadsheetId, user.email);
      if (!setupExists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SetupWizardScreen(
              sheetsService: sheetsService,
              spreadsheetId: spreadsheetId,
              adminEmail: user.email,
            ),
          ),
        );
      } else {
        // Setup done, navigate to Admin Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(
              sheetsService: sheetsService,
              spreadsheetId: spreadsheetId,
            ),
          ),
        );
      }
    } catch (error) {
      setState(() {
        _status = 'Error signing in: $error';
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance App')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_status),
              const SizedBox(height: 20),
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
