import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Modal extends StatelessWidget{
  final String? modalTitle;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  const Modal({
    super.key,
    this.modalTitle,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context){
    return AlertDialog(
      title: Text(
        modalTitle ?? "",
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB71A4A),
        ),
      ),
      content: Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        )
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB71A4A),
              )
            )
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            buttonText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB71A4A),
            ),
          )
        ),
      ]
    );
  }
}