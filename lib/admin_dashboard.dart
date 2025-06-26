import 'package:flutter/material.dart';
import 'app_utils.dart';
import 'google_sheets_service.dart';

// TODO: create these screens
import 'add_user_screen.dart';
import 'mark_attendance_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  final GoogleSheetsService sheetsService;
  final String spreadsheetId;

  const AdminDashboard({
    super.key,
    required this.sheetsService,
    required this.spreadsheetId,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  List<Map<String, dynamic>> _today = [];

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() => _loading = true);

    try {
      // TODO: replace with actual Google Sheets fetch
      _today = [
        {'name': 'John Doe',  'status': 'Present', 'task': 'Task A', 'location': 'Office'},
        {'name': 'Jane Roe',  'status': 'Absent',  'task': '',       'location': ''},
      ];
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signOut() async {
    await widget.sheetsService.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  /* ───────────────────────── UI ───────────────────────── */

  Widget _actionButton(
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
      ),
      icon: Icon(icon),
      label: Text(title),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => AppUtils.logout(
              context,
              service: widget.sheetsService,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _actionButton(
              'Add Users',
              Icons.person_add,
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddUserScreen(
                    sheetsService : widget.sheetsService,
                    spreadsheetId : widget.spreadsheetId,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _actionButton(
              'Mark Attendance',
              Icons.edit_calendar,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _actionButton(
              'View Reports',
              Icons.bar_chart,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _actionButton(
              _loading ? 'Refreshing…' : 'Refresh Sheet',
              Icons.refresh,
              _loading ? () {} : _loadTodayAttendance,
            ),
            const Divider(height: 40),
            const Text(
              'Today\'s Attendance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _today.isEmpty
                ? const Text('No data for today.')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _today.length,
              itemBuilder: (_, i) {
                final row = _today[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(row['name'][0])),
                    title: Text(row['name']),
                    subtitle: Text(
                      'Status: ${row['status']}\n'
                          'Task: ${row['task']}\n'
                          'Location: ${row['location']}',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
