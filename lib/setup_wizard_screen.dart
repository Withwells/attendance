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
  final _businessC  = TextEditingController();
  final _adminNameC = TextEditingController();
  late final TextEditingController _adminEmailC;

  bool _requirePhoto    = false;
  bool _requireLocation = false;
  bool _enableTaskEntry = false;

  bool   _busy  = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _adminEmailC = TextEditingController(text: widget.adminEmail);
  }

  @override
  void dispose() {
    _businessC.dispose();
    _adminNameC.dispose();
    _adminEmailC.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final biz   = _businessC.text.trim();
    final admin = _adminNameC.text.trim();
    final mail  = _adminEmailC.text.trim();

    if ([biz, admin, mail].any((e) => e.isEmpty)) {
      setState(() => _err = 'Please fill all fields');
      return;
    }

    setState(() { _busy = true; _err = null; });
    try {
      final ids = await widget.sheetsService.createFolderAndSheet(biz, admin);

      await widget.sheetsService.initializeSheet(
        ids['spreadsheetId']!,
        mail,
        admin,
        {
          'requirePhoto'    : _requirePhoto,
          'requireLocation' : _requireLocation,
          'enableTaskEntry' : _enableTaskEntry,
        },
      );

      if (context.mounted) {
        Navigator.pop(context, <String, String>{
          'spreadsheetId': ids['spreadsheetId']!,
          'businessName' : biz,
        });
      }
    } catch (e) {
      setState(() {
        _err  = 'Setup error: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Wizard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            _field(_businessC, 'Business Name'),
            _gap,
            _field(_adminNameC, 'Admin Name'),
            _gap,
            _field(_adminEmailC, 'Admin Email',
                keyboard: TextInputType.emailAddress),
            _gap,
            _toggle('Require Photo',    _requirePhoto,    (v) => setState(() => _requirePhoto    = v)),
            _toggle('Require Location', _requireLocation, (v) => setState(() => _requireLocation = v)),
            _toggle('Enable Task Entry',_enableTaskEntry, (v) => setState(() => _enableTaskEntry = v)),
            const SizedBox(height: 20),
            if (_err != null) ...[
              Text(_err!, style: const TextStyle(color: Colors.red)),
              _gap,
            ],
            ElevatedButton(
              onPressed: _busy ? null : _finish,
              child: _busy
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }

  /* -- helpers -- */
  final _gap = const SizedBox(height: 16);

  Widget _field(TextEditingController c, String label, {TextInputType? keyboard}) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        enabled: !_busy,
      );

  Widget _toggle(String t, bool v, ValueChanged<bool> onChanged) =>
      SwitchListTile(title: Text(t), value: v, onChanged: _busy ? null : onChanged);
}
