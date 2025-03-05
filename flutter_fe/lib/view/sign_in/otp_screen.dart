import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpScreen extends StatefulWidget {
  final int userId;

  const OtpScreen({super.key, required this.userId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final AuthenticationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthenticationController(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Color(0xFF0272B1)),
        title: Text(
          'Verification',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: Color(0xFF0272B1), fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Image.asset(
                  'assets/images/verificationImage.jpg',
                  width: 200,
                ),
              ),
              Text(
                'Email Verification',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                    fontSize: 30, color: Color(0xFF0272B1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  textAlign: TextAlign.center,
                  "Enter the one-type-password we've sent to your email.",
                  style: GoogleFonts.openSans(color: Colors.black),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 40, right: 40, top: 20, bottom: 20),
                child: TextField(
                  controller: _controller.otpController,
                  cursorColor: Color(0xFF0272B1),
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Enter OTP...',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.transparent, width: 0),
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Color(0xFF0272B1), width: 2))),
                ),
              ),
              Container(
                height: 50,
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 40,
                  right: 40,
                ),
                child: ElevatedButton(
                    onPressed: () {
                      _controller.otpAuth(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0272B1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text(
                      'Verify OTP',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Didn't get it?",
                        style: GoogleFonts.openSans(
                          color: Colors.black,
                        )),
                    TextButton(
                        onPressed: () {
                          _controller.resetOTP(context);
                        },
                        child: Text(
                          'Resend',
                          style: GoogleFonts.openSans(
                              color: Color(0xFF0272B1),
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
