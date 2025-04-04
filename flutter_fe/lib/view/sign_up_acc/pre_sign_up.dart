import 'package:flutter/material.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_solo_tasker.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PreSignUp extends StatefulWidget {
  const PreSignUp({super.key});

  @override
  State<PreSignUp> createState() => _PreSignUpState();
}

class _PreSignUpState extends State<PreSignUp> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.05), // 5% of screen height
              SvgPicture.asset(
                'assets/svg/logo.svg',
                width: 150,
                height: 150,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  'Create a Tasker Account to earn money by completing tasks, or a Client Account to hire experts for your needs',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: screenWidth * 0.025, // Responsive text
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  'Choose your account to get started!',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: screenWidth * 0.025, // Responsive text
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // TASKER BUTTON
              SizedBox(
                width: screenWidth * 0.8,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SignUpSoloTaskerAcc(
                          role: "Tasker", taskerGroup: "Solo Tasker");
                    }));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03045E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.white),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/icons8-worker-100.png',
                          height: screenWidth * 0.2, // Responsive image
                          width: screenWidth * 0.2,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'TASKER ACCOUNT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),
              // CLIENT BUTTON
              SizedBox(
                width: screenWidth * 0.8,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SignUpClientAcc(role: "Client");
                    }));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03045E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.white),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/icons8-checklist-100.png',
                          height: screenWidth * 0.2,
                          width: screenWidth * 0.2,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'CLIENT ACCOUNT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
