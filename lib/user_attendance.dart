import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserAttendance extends StatelessWidget {
  final GoogleSignInAccount currentUser;
  final VoidCallback onSignOut;

  const UserAttendance({Key? key, required this.currentUser, required this.onSignOut}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${currentUser.displayName ?? currentUser.email}\nUser attendance features coming soon.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
