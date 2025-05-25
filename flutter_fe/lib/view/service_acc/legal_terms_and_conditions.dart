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
          title: Text("QTask Terms and Conditions",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          backgroundColor: Color(0XFF170A66),
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
                    ]))));
  }
}
