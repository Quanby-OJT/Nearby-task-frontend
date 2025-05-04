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
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Color(0xFFB71A4A),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    "Enter the one-type-password we've sent to your email.",
                    style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w300),
                  ),
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
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
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
                        backgroundColor: Color(0xFFB71A4A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text(
                      'Verify',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't get it?",
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12)),
                    TextButton(
                        onPressed: () {
                          _controller.resetOTP(context);
                        },
                        child: Text(
                          'Resend',
                          style: GoogleFonts.poppins(
                              color: Color(0xFFB71A4A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
