import 'package:flutter/material.dart';
import 'google_sheets_service.dart';

class SetupWizardScreen extends StatefulWidget {
  final GoogleSheetsService sheetsService;
  final String adminEmail;

  const SetupWizardScreen({
    super.key,
    required this.sheetsService,
    required this.adminEmail,
  });

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _businessNameC = TextEditingController();
  final _adminNameC    = TextEditingController();
  late final TextEditingController _adminEmailC;

  bool _requirePhoto    = false;
  bool _requireLocation = false;
  bool _enableTaskEntry = false;

  bool   _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminEmailC = TextEditingController(text: widget.adminEmail);
  }

  @override
  void dispose() {
    _businessNameC.dispose();
    _adminNameC.dispose();
    _adminEmailC.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    final biz   = _businessNameC.text.trim();
    final admin = _adminNameC.text.trim();
    final email = _adminEmailC.text.trim();

    if (biz.isEmpty || admin.isEmpty || email.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final ids = await widget.sheetsService.createFolderAndSheet(
        biz, admin,
      );

      await widget.sheetsService.initializeSheet(
        ids['spreadsheetId']!,
        email,
        admin,
        {
          'requirePhoto'    : _requirePhoto,
          'requireLocation' : _requireLocation,
          'enableTaskEntry' : _enableTaskEntry,
        },
      );

      if (context.mounted) {
        Navigator.pop(context, {
          'spreadsheetId': ids['spreadsheetId'],
          'businessName' : biz,
        });
      }
    } catch (e) {
      setState(() {
        _error     = 'Setup error: $e';
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
              controller: _businessNameC,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adminNameC,
              decoration: const InputDecoration(
                labelText: 'Admin Name',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adminEmailC,
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Require Photo'),
              value: _requirePhoto,
              onChanged: _isLoading ? null : (v) => setState(() => _requirePhoto = v),
            ),
            SwitchListTile(
              title: const Text('Require Location'),
              value: _requireLocation,
              onChanged: _isLoading ? null : (v) => setState(() => _requireLocation = v),
            ),
            SwitchListTile(
              title: const Text('Enable Task Entry'),
              value: _enableTaskEntry,
              onChanged: _isLoading ? null : (v) => setState(() => _enableTaskEntry = v),
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
                width: 24, height: 24,
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
