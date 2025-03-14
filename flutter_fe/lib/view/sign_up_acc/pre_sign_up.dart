import 'package:flutter/material.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_client.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_tasker.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFF0272B1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.05), // 5% of screen height
              Text(
                'NearByTask',
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontSize: screenWidth * 0.08, // Responsive font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  'Be PAID for Tasks Done through a TASKER ACCOUNT or Find an expert to have your task completed with a CLIENT ACCOUNT. \n\n To Begin, please select one of the two accounts you want to create:',
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: screenWidth * 0.035, // Responsive text
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // TASKER BUTTON
              SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.22,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SignUpTaskerAcc(role: "Tasker");
                    }));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0272B1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.white),
                    ),
                  ),
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

              SizedBox(height: screenHeight * 0.02),

              // CLIENT BUTTON
              SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.22,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SignUpClientAcc(role: "Client");
                    }));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0272B1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.white),
                    ),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
