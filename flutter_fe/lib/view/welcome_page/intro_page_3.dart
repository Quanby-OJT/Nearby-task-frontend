import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class IntroPage3 extends StatelessWidget {
  const IntroPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/welcomeScreen2.json',
              width: 300, height: 300, fit: BoxFit.fitWidth),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              textAlign: TextAlign.center,
              'Tesda graduate? Now you can look for available jobs and showcase your skills in your profile. Sign up using service account now!',
              style: GoogleFonts.poppins(
                  color: Colors.black, fontWeight: FontWeight.w300),
            ),
          ),
        ],
      ),
    );
  }
}
