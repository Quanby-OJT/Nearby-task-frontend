import 'package:flutter_fe/view/fill_up/nearby_task_rules.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpSoloTaskerAcc extends StatefulWidget {
  final String role;
  final String taskerGroup;
  const SignUpSoloTaskerAcc(
      {super.key, required this.role, required this.taskerGroup});

  @override
  State<SignUpSoloTaskerAcc> createState() => _SignUpSoloTaskerAccState();
}

class _SignUpSoloTaskerAccState extends State<SignUpSoloTaskerAcc> {
  final ProfileController _controller = ProfileController();
  String _status = "Please fill out the form to register";
  bool _isVerified = false; // Track verification status
  StreamSubscription<Uri>? _linkSubscription;

  bool _obsecureTextPassword = true;
  bool _obsecureTextConfirmPassword = true;

  void _toggleObscureTextPassword() {
    setState(() {
      _obsecureTextPassword = !_obsecureTextPassword;
    });
  }

  void _toggleObscureTextConfirmPassword() {
    setState(() {
      _obsecureTextConfirmPassword = !_obsecureTextConfirmPassword;
    });
  }

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
    _controller.roleController.text = widget.role;
  }

  Future<void> _initDeepLinkListener() async {
    final appLinks = AppLinks();

    // Handle initial link (app opened via deep link)
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

    // Listen for links while app is running
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
          _status = "Email verified! Welcome, $email";
        });

        // Redirect to rules page
        if (mounted) {
          // Check if widget is still mounted before navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NearbyTaskRules(userId: userId),
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

  @override
  void dispose() {
    _linkSubscription?.cancel(); // Clean up the subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/images/icons8-worker-100-colored.png',
              height: 150,
              width: 150,
            ),
            SizedBox(height: 10),
            Text(
              'Tasker Account',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF03045E),
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                textAlign: TextAlign.center,
                "With ONE SWIPE \nYou can Find a New Task in a Matter of Seconds.",
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _status,
                  style: GoogleFonts.montserrat(
                    color: _isVerified ? Colors.green : const Color(0xff03045E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Container(
              child: SizedBox(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: Color(0xFF0272B1)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.firstNameController,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) => value!.isEmpty
                              ? "Please Input Your First Name"
                              : null,
                          decoration: _inputDecoration('First Name'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.middleNameController,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) => value!.isEmpty
                              ? "Please Input Your Middle Name"
                              : null,
                          decoration:
                              _inputDecoration('Middle Name (Optional)  '),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.lastNameController,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) => value!.isEmpty
                              ? "Please Input Your Last Name"
                              : null,
                          decoration: _inputDecoration('Last Name'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.emailController,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) => value!.isEmpty
                              ? "Please Input Your Valid Email"
                              : null,
                          decoration: _inputDecoration('Email Address'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.passwordController,
                          obscureText: _obsecureTextPassword,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) => value!.length < 6
                              ? "Password must be at least 6 characters"
                              : null,
                          decoration: _inputDecoration('Password').copyWith(
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: IconButton(
                                icon: Icon(
                                  _obsecureTextPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Color(0xFF0272B1),
                                ),
                                onPressed: _toggleObscureTextPassword,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.confirmPasswordController,
                          obscureText: _obsecureTextConfirmPassword,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) =>
                              value != _controller.passwordController.text
                                  ? "Passwords do not match"
                                  : null,
                          decoration:
                              _inputDecoration('Confirmed Password').copyWith(
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: IconButton(
                                icon: Icon(
                                  _obsecureTextConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Color(0xFF0272B1),
                                ),
                                onPressed: _toggleObscureTextConfirmPassword,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 50,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                            onPressed: () {
                              _controller.registerUser(context).then((_) {
                                setState(() => _status =
                                    "Please check your email to verify your account");
                              });
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF03045E),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              child: TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SignIn()));
                },
                child: Text(
                  'Already have an account?',
                  style: GoogleFonts.montserrat(
                    color: Color(0xFF03045E),
                    fontWeight: FontWeight.w300,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Color(0xFFF1F4FF),
      labelText: label,
      hintStyle: TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF0272B1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
