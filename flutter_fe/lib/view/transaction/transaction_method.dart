import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionMethodScreen extends StatefulWidget {
  const TransactionMethodScreen({super.key});

  @override
  State<TransactionMethodScreen> createState() => _TransactionMethodState();
}

class _TransactionMethodState extends State<TransactionMethodScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('Transaction Method'),
      ),
    );
  }
}
