import 'package:flutter/material.dart';

class MarkAttendanceScreen extends StatelessWidget {
  const MarkAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Text('This screen will show today’s employees.'),
            SizedBox(height: 12),
            Text('Fields based on setup: Task, Location, Photo'),
          ],
        ),
      ),
    );
  }
}
