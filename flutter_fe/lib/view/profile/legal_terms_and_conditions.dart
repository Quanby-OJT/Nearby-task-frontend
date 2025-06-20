import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
        centerTitle: true,
        title: Text(
          'Terms and Conditions',
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
          onPressed: () => Navigator.pop(context),
        ),
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
                  text: 'QTask. ',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                descTextSpan('These Terms of Service ("Terms") '),
                descTextSpan('govern your access and use of our platform, including our website, app, and related services (collectively, the "Service")'),
              ]),
              SizedBox(height: 8),
              description([
                TextSpan(text: 'By accessing or using the Service, you agree to be bound by these Terms. If you do not agree, do not use the Service.'),
              ]),
              SizedBox(height: 16),
              headingText("1. Use of Service"),
              SizedBox(height: 8),
              singleLineText('You must be at least 18 years old and legally capable of entering into a binding agreement. By registering, you represent and warrant that all information provided is accurate and complete.'),
              SizedBox(height: 16),
              headingText("2. User Roles"),
              SizedBox(height: 8),
              singleLineText("We provide a platform where two types of users interact: "),
              SizedBox(height: 8),
              description([
                listText("Client: ", bold: true),
                TextSpan(text: "Users who post tasks or services they need completed."),
                listText('Tasker: ', bold: true),
                descTextSpan("Users who offer services and complete tasks for Clients."),
                descTextSpan("\n\n"),
                descTextSpan("We are not a party to any agreement made between Clients and Taskers. We merely facilitate the connection.")
              ]),
              SizedBox(height: 16),
              headingText("3. Account Registration"),
              SizedBox(height: 8),
              singleLineText("You agree to provide true, current, and complete information during registration. You are responsible for safeguarding your account credentials. You must notify us immediately if you suspect unauthorized access."),
              SizedBox(height: 16),
              headingText("4. Verification and Data Collection"),
              SizedBox(height: 8),
              description([
                descTextSpan('We collect the following data for the purposes of registration, identity verification, transaction processing, and platform integrity: '),
                listText("E-Signatures: ", bold: true), descTextSpan("For transaction validation."),
                listText("Personal and Financial Data: ", bold: true), descTextSpan("For logging and displaying deposits/withdrawals."),
                listText("Email, Password, OTP: ", bold: true), descTextSpan("For secure login and authentication."),
                listText("Dispute Information: ", bold: true), descTextSpan("For internal moderation of disagreements."),
                listText("Location Data: ", bold: true), descTextSpan("To assist with task filtering and real-time user location."),
                listText("Messaging Data: ", bold: true), descTextSpan("To allow communication between users."),
                listText("Image & Document Data: ", bold: true), descTextSpan("To verify Tasker qualifications (e.g. certificates)."),
                listText("Identification and Selfie: ", bold: true), descTextSpan("To confirm the user is a real, unique individual."),
                TextSpan(text: '\n\n We do not sell your personal information. Please review our '),
                TextSpan(
                  text: 'Privacy Policy ',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                descTextSpan('for further details on how your data is managed.'),
              ]),
              SizedBox(height: 16),
              headingText("5. User Responsibilities"),
              description([
                descTextSpan("You agree not to use the Service:\n"),
                listText("For any illegal or unauthorized purpose."),
                listText("To impersonate another person or misrepresent your affiliation."),
                listText("To upload false or fraudulent information."),
                listText("To harass, threaten, or harm other users."),
                listText("To bypass verification systems or upload fake documents. \n\n"),
                descTextSpan("We reserve the right to suspend or terminate accounts involved in misuse or fraud, without notice or refund.")
              ]),
              SizedBox(height: 16),
              headingText("6. Platform Fees and Payments"),
              singleLineText("We may charge service fees for deposits, withdrawals, or task-related transactions. All payments are processed securely through integrated payment providers. We are not responsible for delays or issues related to third-party payment systems."),
              SizedBox(height: 16),
              headingText("7. Dispute Resolution"),
              singleLineText("Users are encouraged to resolve disputes between themselves. If unresolved, you may request platform moderation. We do not guarantee resolution and are not liable for any loss arising from disputes."),
              SizedBox(height: 16),
              headingText("8. Content Ownership"),
              singleLineText("You retain ownership of content you upload, but grant us a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content for platform functionality and promotional purposes."),
              SizedBox(height: 16),
              headingText("9. Account Termination"),
              description([
                descTextSpan("We may suspend or terminate your account at any time, with or without notice, if we believe:\n"),
                listText("You violated these Terms."),
                listText("Your actions harm or threaten the platform or its users."),
                listText("You attempted fraud or account manipulation.\n\n"),
                descTextSpan("We reserve the right to report unlawful activity to the authorities.")
              ]),
              SizedBox(height: 16),
              headingText("10. Limitation of Liability"),
              description([
                descTextSpan("To the fullest extent permitted by law:\n"),
                listText("We are not liable for indirect, incidental, or consequential damages."),
                listText("We are not liable for user behavior or any transaction made between users."),
                listText('Our platform is provided "as is" and "as available," without warranties of any kind.\n'),
              ]),
              SizedBox(height: 16),
              headingText("11. Indemnification"),
              description([
                descTextSpan("You agree to indemnify and hold us harmless from any claims, damages, or losses resulting from:\n"),
                listText("Your use or misuse of the Service."),
                listText("Your violation of these Terms."),
                listText('Any claim arising from your uploaded content, transactions, or behavior on the platform.\n'),
              ]),
              SizedBox(height: 16),
              headingText("12. Modifications to the Terms"),
              singleLineText("We reserve the right to modify these Terms at any time. Continued use of the Service after updates constitutes acceptance of the revised Terms."),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  svgAssets("assets/svg/logo.svg"),
                  svgAssets("assets/svg/company-logo.svg"),
                ],
              ),
              description([
                listTextLine("Date Created: ", bold: true), descTextSpan("June 16, 2025"), //DO NOT EDIT THIS LINE.
                listTextLine("Last Updated at: ", bold: true), descTextSpan("June 17, 2025") //Please change the date to today each time you edit the file.
              ])
            ]
          )
        )
      ),
      // bottomSheet: BottomAppBar(
      //   color: Color(0xFFB71A4A),
      //   child: Padding(
      //     padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Added horizontal padding
      //     child: FittedBox( // Added FittedBox to allow text to shrink if needed
      //       fit: BoxFit.scaleDown, // Ensures text scales down instead of overflowing
      //       child: Text(
      //         "QTask © 2024. All Rights Reserved.",
      //         textAlign: TextAlign.center,
      //         style: GoogleFonts.poppins(
      //           color: Colors.white,
      //           fontSize: 12,
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
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
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black), // Default text color
        children: textSpans,
      ),
    );
  }

  Widget singleLineText(String text){
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black,
      ),
      textAlign: TextAlign.justify,
    );
  }

  TextSpan listText(String text, {bool bold = false}){
    return TextSpan(
      text: "\n \u2022 $text",
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal
      )
    );
  }

  TextSpan listTextLine(String text, {bool bold = false}){
      return TextSpan(
        text: "\n $text",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal
        )
      );
    }

  TextSpan descTextSpan(String text){
    return TextSpan(
      text: text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black,
      ),
    );
  }

  Widget listTextBold(String text){
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black,
        fontWeight: FontWeight.bold
      )
    );
  }

  Widget svgAssets(String image){
    return SvgPicture.asset(
      image,
      width: 120,
      height: 120,
    );
  }
}
