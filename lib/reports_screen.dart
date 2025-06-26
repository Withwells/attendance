import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Text('This screen will display past 10 days\' attendance.'),
            SizedBox(height: 12),
            Text('Phase 2: Export, Search, Filter'),
          ],
        ),
      ),
    );
  }
}
