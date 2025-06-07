import 'package:flutter/material.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:flutter_fe/view/sign_in/forgot_password.dart';
import 'package:flutter_fe/view/sign_up_acc/pre_sign_up.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> with SingleTickerProviderStateMixin {
  final AuthenticationController _controller = AuthenticationController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation;
  bool _obsecureText = true;
  bool _isLoading = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

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

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer(int seconds) {
    setState(() {
      _remainingSeconds = seconds;
      _isLocked = true;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isLocked = false;
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleObscureText() {
    setState(() {
      _obsecureText = !_obsecureText;
    });
  }

  void _handleLogin() async {
    if (_isLocked) return;

    setState(() => _isLoading = true);
    final response = await _controller.loginAuth(context);

    if (response.containsKey('isThrottled') && response['isThrottled']) {
      int remainingTime = response['remainingTime'] ?? 300;
      _startCountdownTimer(remainingTime);
    }

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
                              textAlign: TextAlign.center,
                              'Find Tasks Near You with QTask!',
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
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 40, right: 40, top: 20),
                              child: TextField(
                                obscureText: _obsecureText,
                                controller: _controller.passwordController,
                                cursorColor: const Color(0xFFB71A4A),
                                decoration:
                                    _getInputDecoration('Password').copyWith(
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: IconButton(
                                      icon: Icon(
                                        _obsecureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.black87,
                                      ),
                                      onPressed: _toggleObscureText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_isLocked)
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer,
                                        color: Colors.red.shade400),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Try again in ${_formatTime(_remainingSeconds)}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!_isLocked)
                              Container(
                                height: 50,
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: ElevatedButton(
                                  onPressed: (_isLoading || _isLocked)
                                      ? null
                                      : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB71A4A),
                                    disabledBackgroundColor: Colors.grey,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 5,
                                    shadowColor: Colors.black26,
                                  ),
                                  child: Text(
                                    _isLocked ? 'Login Locked' : 'Sign in',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 40),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPassword(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot your password?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PreSignUp(),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Don\'t have an account?',
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF03045E),
                                        fontWeight: FontWeight.w300,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Sign Up',
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFFB71A4A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
