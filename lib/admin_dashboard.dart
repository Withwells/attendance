import 'package:flutter/material.dart';
import 'google_sheets_service.dart';

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
  List<Map<String, dynamic>> _attendanceData = [];

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _loading = true;
    });

    try {
      // TODO: Replace with actual method to get today's attendance from Google Sheets
      final data = [
        {'name': 'John Doe', 'status': 'Present', 'location': 'Office', 'task': 'Task A'},
        {'name': 'Jane Smith', 'status': 'Absent', 'location': '', 'task': ''},
      ];

      setState(() {
        _attendanceData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance: $e')),
      );
    }
  }

  void _signOut() async {
    await widget.sheetsService.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceData.isEmpty
          ? const Center(child: Text('No attendance data available for today.'))
          : ListView.builder(
        itemCount: _attendanceData.length,
        itemBuilder: (context, index) {
          final item = _attendanceData[index];
          return ListTile(
            leading: CircleAvatar(child: Text(item['name'][0])),
            title: Text(item['name']),
            subtitle: Text(
              'Status: ${item['status']}\nLocation: ${item['location']}\nTask: ${item['task']}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Open attendance edit screen
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add functionality to add/edit attendance or add employee
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Attendance',
      ),
    );
  }
}
