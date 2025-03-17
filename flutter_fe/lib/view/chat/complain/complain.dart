import 'package:flutter/material.dart';

class ComplainScreen extends StatelessWidget {
  const ComplainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File a Complaint'),
      ),
      body: const Center(
        child: Text('Complain Screen - Add your content here'),
      ),
    );
  }
}
