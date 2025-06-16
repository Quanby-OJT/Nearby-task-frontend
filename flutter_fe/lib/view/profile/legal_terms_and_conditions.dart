import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LegalTermsAndConditionsScreen extends StatefulWidget {
  const LegalTermsAndConditionsScreen({super.key});

  @override
  State<LegalTermsAndConditionsScreen> createState() =>
      _LegalTermsAndConditionsScreenState();
}

class _LegalTermsAndConditionsScreenState
    extends State<LegalTermsAndConditionsScreen> {
  //Main Application
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NearByTask Terms and Conditions",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )
        ),
        backgroundColor: Color(0xFFB71A4A),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///NOTE: The Legal Terms and Conditions must be crafted with the consultation with a Business Lawyer in relation to using this application.
              ///
              /// -Ces
              description([
                TextSpan(text: 'Welcome to '),
                TextSpan(
                  text: 'NearbyTask. ',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: 'These Terms of Service ("Terms") '),
                TextSpan(text: 'govern your access and use of our platform, including our website, app, and related services (collectively, the "Service")'),
              ]),
              SizedBox(height: 8),
              description([
                TextSpan(text: 'By accessing or using the Service, you agree to be bound by these Terms. If you do not agree, do not use the Service.'),
              ]),
              SizedBox(height: 16),
              headingText("1. Use of Service"),
              SizedBox(height: 8),
              description([
                TextSpan(text: 'You must be at least 18 years old and legally capable of entering into a binding agreement. By registering, you represent and warrant that all information provided is accurate and complete.')
              ]),
              SizedBox(height: 16),
              headingText("2. User Roles"),
              SizedBox(height: 8),
              description([
                TextSpan(text: 'We provide a platform where two types of users interact:')
              ]),
            ]
          )
        )
      )
    );
  }


  Widget headingText(String title){
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      )
    );
  }

  Widget description(List<TextSpan> textSpans) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black), // Default text color
        children: textSpans,
      ),
    );
  }
}
