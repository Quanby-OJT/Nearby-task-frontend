import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class IntroPage2 extends StatelessWidget {
  const IntroPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Text(
              textAlign: TextAlign.center,
              'Do you need a professional for a specific task or a trusted expert for a project? We connect you with qualified workers ready to get the job done!',
              style: GoogleFonts.openSans(
                  color: Colors.white, fontWeight: FontWeight.w400),
            ),
          ),
          Lottie.asset('assets/lottie/welcomeScreen3.json',
              width: 300, height: 300, fit: BoxFit.fitWidth),
        ],
      ),
    );
  }
}
