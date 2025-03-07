import 'package:flutter/material.dart';

// ignore: camel_case_types
class taskDetails extends StatelessWidget {
  const taskDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text('Task Details'),
          Text('Task Name: Task 1'),
          Text(
              'Task Description: Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
        ],
      ),
    );
  }
}
