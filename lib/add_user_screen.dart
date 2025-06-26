import 'package:flutter/material.dart';
import 'app_utils.dart';
import 'google_sheets_service.dart';
import 'package:googleapis/sheets/v4.dart' as gs;

class AddUserScreen extends StatefulWidget {
  final GoogleSheetsService sheetsService;
  final String spreadsheetId;

  const AddUserScreen({
    super.key,
    required this.sheetsService,
    required this.spreadsheetId,
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameC     = TextEditingController();
  final _emailC    = TextEditingController();
  String _role     = 'User';
  bool   _saving   = false;

  /* ───────────────────────── helpers ───────────────────────── */

  Future<bool> _emailExists(String email) async {
    final res = await widget.sheetsService.sheetsApi.spreadsheets.values.get(
      widget.spreadsheetId,
      'Roles!A2:A',
    );
    final emails = res.values?.expand((r) => r).cast<String>() ?? [];
    return emails.contains(email);
  }

  Future<List<String>> _adminHeader() async {
    // Admin name is in Roles row 2, column B
    final rolesRow = await widget.sheetsService.sheetsApi.spreadsheets.values.get(
      widget.spreadsheetId,
      'Roles!B2',
    );
    final adminName = rolesRow.values?[0][0] ?? 'Admin';

    final headerRes = await widget.sheetsService.sheetsApi.spreadsheets.values.get(
      widget.spreadsheetId,
      '$adminName!1:1',
    );
    return headerRes.values?[0].cast<String>() ?? ['Date', 'Attendance'];
  }

  Future<void> _createUserSheet(String sheetName, List<String> header) async {
    final requests = [
      gs.Request(
        addSheet: gs.AddSheetRequest(
          properties: gs.SheetProperties(title: sheetName),
        ),
      ),
    ];
    await widget.sheetsService.sheetsApi.spreadsheets.batchUpdate(
      gs.BatchUpdateSpreadsheetRequest(requests: requests),
      widget.spreadsheetId,
    );

    // Write header row
    await widget.sheetsService.sheetsApi.spreadsheets.values.update(
      gs.ValueRange(values: [header]),
      widget.spreadsheetId,
      '$sheetName!A1:${_colLetter(header.length)}1',
      valueInputOption: 'RAW',
    );
  }

  // Convert length to column letter (e.g., 4 -> D)
  String _colLetter(int len) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (len <= 0) return 'A';
    return letters[(len - 1).clamp(0, letters.length - 1)];
  }

  /* ───────────────────────── save user ───────────────────────── */

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final email = _emailC.text.trim();
    final name  = _nameC.text.trim();

    try {
      if (await _emailExists(email)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User already exists.')),
          );
        }
      } else {
        // Append to Roles
        await widget.sheetsService.sheetsApi.spreadsheets.values.append(
          gs.ValueRange(values: [
            [email, name, _role]
          ]),
          widget.spreadsheetId,
          'Roles!A:C',
          valueInputOption: 'RAW',
        );

        // Create user sheet with correct header
        final header = await _adminHeader();
        await _createUserSheet(name, header);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User added successfully')),
          );
          Navigator.pop(context); // return to dashboard
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    AppUtils.logout(context, service: widget.sheetsService);
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  /* ───────────────────────── UI ───────────────────────── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailC,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                v == null || !v.contains('@') ? 'Valid email required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'User',  child: Text('User')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _role = v ?? 'User'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _saveUser,
                child: _saving
                    ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
