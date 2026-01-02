import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Contact Us', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Email: support@buyme.local'),
            SizedBox(height: 8),
            Text('Phone: +1 555 123 4567'),
            SizedBox(height: 16),
            Text('For more help, open a ticket on the backend project.'),
          ],
        ),
      ),
    );
  }
}
