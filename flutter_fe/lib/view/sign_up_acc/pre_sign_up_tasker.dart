import 'package:flutter/material.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_client.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_solo_tasker.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_group_tasker.dart';
import 'package:google_fonts/google_fonts.dart';

class PreSignUpTasker extends StatefulWidget {
  const PreSignUpTasker({super.key});

  @override
  State<PreSignUpTasker> createState() => _PreSignUpTaskerState();
}

class _PreSignUpTaskerState extends State<PreSignUpTasker> {
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
                'Select Your Classification',
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontSize: screenWidth * 0.08, // Responsive font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              // SOLO TASKER BUTTON
              SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.22,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SignUpSoloTaskerAcc(
                        role: "Tasker",
                        taskerGroup: "Solo Tasker",
                      );
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
                        'I AM ONLY ONE TASKER',
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

              // GROUP TASKER BUTTON
              SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.22,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) {
                    //   return SignUpGroupTaskerAcc(role: "Tasker", taskerGroup: "Group Tasker");
                    // }));
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
                        'I AM AN AGENCY WITH MANY TASKERS',
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
