import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class CustomScaffold extends StatelessWidget {
  final String message;
  final Color color;
  const CustomScaffold({super.key, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(  
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
    return Container();
  }
}