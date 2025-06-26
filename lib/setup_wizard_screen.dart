import 'package:flutter/material.dart';
import 'google_sheets_service.dart';

class SetupWizardScreen extends StatefulWidget {
  final GoogleSheetsService sheetsService;
  final String spreadsheetId; // will be empty on first setup
  final String adminEmail;

  const SetupWizardScreen({
    super.key,
    required this.sheetsService,
    required this.spreadsheetId,
    required this.adminEmail,
  });

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _businessNameController = TextEditingController();

  bool requirePhoto = false;
  bool requireLocation = false;
  bool enableTaskEntry = false;

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    final businessName = _businessNameController.text.trim();

    if (businessName.isEmpty) {
      setState(() {
        _error = 'Please enter a business name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // If spreadsheetId empty, create sheet now
      final spreadsheetId = widget.spreadsheetId.isEmpty
          ? await widget.sheetsService.createAttendanceSheet(businessName)
          : widget.spreadsheetId;

      // Initialize sheet with admin and config
      await widget.sheetsService.initializeSheet(
        spreadsheetId,
        [], // employees empty initially, add later
        widget.adminEmail,
        {
          'requirePhoto': requirePhoto,
          'requireLocation': requireLocation,
          'enableTaskEntry': enableTaskEntry,
        },
      );

      // Return spreadsheetId and businessName to HomeScreen
      Navigator.pop(context, {
        'spreadsheetId': spreadsheetId,
        'businessName': businessName,
      });
    } catch (e) {
      setState(() {
        _error = 'Error during setup: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Wizard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Require Photo for Attendance'),
              value: requirePhoto,
              onChanged: _isLoading ? null : (val) => setState(() => requirePhoto = val),
            ),
            SwitchListTile(
              title: const Text('Require Location for Attendance'),
              value: requireLocation,
              onChanged: _isLoading ? null : (val) => setState(() => requireLocation = val),
            ),
            SwitchListTile(
              title: const Text('Enable Task Entry'),
              value: enableTaskEntry,
              onChanged: _isLoading ? null : (val) => setState(() => enableTaskEntry = val),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _finishSetup,
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
