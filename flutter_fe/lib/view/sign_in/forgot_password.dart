import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:flutter_fe/view/sign_in/otp_screen.dart';
import 'package:flutter_fe/view/sign_in/reset_password.dart';
import 'package:flutter_fe/view/sign_up_acc/pre_sign_up.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> with SingleTickerProviderStateMixin {
  final AuthenticationController _controller = AuthenticationController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;
  bool _obsecureText = true;
  bool _isLoading = false;
  StreamSubscription<Uri>? _linkSubscription;
  String _status = "In order to reset your password, please enter your email.";
  bool _isVerified = false;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initDeepLinkListener();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _bottomSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];

    if (token != null && email != null) {
      setState(() => _status = "Verifying your email...");
      final int userId = await _controller.verifyEmail(context, token, email);

      if (userId != 0) {
        debugPrint("User ID: $userId");
        setState(() {
          _isVerified = true;
          _status = "Email verified! You can now reset your password.";
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPassword(email: email),
            ),
          );
        }
      } else {
        setState(() => _status = "Email verification failed");
      }
    } else {
      setState(() => _status = "Invalid verification link");
    }
  }

  Future<void> _initDeepLinkListener() async {
    final appLinks = AppLinks();
    debugPrint("Handling Forgot Password Deeplink...");
    try {
      final Uri? initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      setState(() => _status = "An error occurred");
    }

    _linkSubscription = appLinks.uriLinkStream.listen(
          (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        setState(() => _status = "Error: $err");
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void handlePasswordReset() async {
    setState(() => _isLoading = true);
    await _controller.forgotPassword(context);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F4FF),
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SlideTransition(
                      position: _topSlideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/logo.svg',
                              width: 150,
                              height: 150,
                            ),
                            Text(
                              "Forgot Password",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              textAlign: TextAlign.center,
                              'Have you forgot your password? Don\'t Worry! We have you covered. To start, please enter your email you used to sign in to this application.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _bottomSlideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.only(left: 40, right: 40),
                              child: TextField(
                                controller: _controller.emailController,
                                cursorColor: const Color(0xFFB71A4A),
                                decoration: _getInputDecoration('Email'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 50,
                              width: double.infinity,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 40),
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : handlePasswordReset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFB71A4A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.black26,
                                ),
                                child: Text(
                                  'Send Verification Link',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
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
          ),
          if (_isLoading) const CustomLoading(),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF1F4FF),
      labelText: label,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB71A4A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}