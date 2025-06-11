import 'package:flutter_fe/view/fill_up/nearby_task_rules.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;

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
  bool _isVerified = false;
  StreamSubscription<Uri>? _linkSubscription;
  final _signaturePadKey = GlobalKey<SfSignaturePadState>();
  String? _signaturePath;

  bool _obsecureTextPassword = true;
  bool _obsecureTextConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QTaskRules(userId: userId),
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
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset(
                'assets/images/icons8-checklist-100-colored.png',
                height: 150,
                width: 150,
              ),
              SizedBox(height: 20),
              Text(
                'Tasker Account',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB71A4A),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  textAlign: TextAlign.center,
                  "With ONE SWIPE \nYou can Find a New Task in a Matter of Seconds.",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ),
              if (_status.isNotEmpty)
                SizedBox(
                  height: 10,
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _status,
                  style: GoogleFonts.poppins(
                    color: _isVerified ? Colors.green : const Color(0xFFB71A4A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.firstNameController,
                      validator: (value) =>
                          _controller.validateName(value, "first name"),
                      decoration: _getInputDecoration('First Name'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.middleNameController,
                      decoration: _getInputDecoration('Middle Name (Optional)'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.lastNameController,
                      validator: (value) =>
                          _controller.validateName(value, "last name"),
                      decoration: _getInputDecoration('Last Name'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.emailController,
                      validator: _controller.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _getInputDecoration('Email Address'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.passwordController,
                      validator: _controller.validatePassword,
                      obscureText: _obsecureTextPassword,
                      decoration: _getInputDecoration('Password').copyWith(
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: IconButton(
                            icon: Icon(
                              _obsecureTextPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black87,
                            ),
                            onPressed: _toggleObscureTextPassword,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password must contain:',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '• At least 8 characters',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '• At least one uppercase letter',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '• At least one lowercase letter',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '• At least one number',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '• At least one special character (!@#\$%^&*(),.?":{}|<>)',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.confirmPasswordController,
                      validator: _controller.validateConfirmPassword,
                      obscureText: _obsecureTextConfirmPassword,
                      decoration:
                          _getInputDecoration('Confirm Password').copyWith(
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: IconButton(
                            icon: Icon(
                              _obsecureTextConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black87,
                            ),
                            onPressed: _toggleObscureTextConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFB71A4A)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signature',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB71A4A),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SfSignaturePad(
                              key: _signaturePadKey,
                              backgroundColor: Colors.white,
                              strokeColor: Colors.black,
                              minimumStrokeWidth: 1.0,
                              maximumStrokeWidth: 3.0,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _signaturePadKey.currentState?.clear();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Clear',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                      _status = "Creating your account...";
                                    });

                                    // Save signature first
                                    if (_signaturePadKey.currentState != null) {
                                      final image = await _signaturePadKey
                                          .currentState!
                                          .toImage();
                                      final bytes = await image.toByteData(
                                          format: ui.ImageByteFormat.png);
                                      if (bytes != null) {
                                        try {
                                          final directory =
                                              Directory('lib/signatures');
                                          if (!await directory.exists()) {
                                            await directory.create(
                                                recursive: true);
                                          }

                                          final timestamp = DateTime.now()
                                              .millisecondsSinceEpoch;
                                          //Store signature with the first name inputed by the user
                                          // Start
                                          String firstName = _controller
                                              .firstNameController.text
                                              .trim();
                                          if (firstName.isEmpty) {
                                            setState(() {
                                              _isLoading = false;
                                              _status =
                                                  "First name is required for signature filename";
                                            });
                                            return;
                                          }
                                          firstName = firstName.replaceAll(
                                              RegExp(r'[^\w]'), '_');
                                          final file = File(
                                              '${directory.path}/${firstName}.png');
                                          // '${directory.path}/${firstName}_$timestamp.png'); //If You Want With Timestamp
                                          // End
                                          await file.writeAsBytes(
                                              bytes.buffer.asUint8List());

                                          setState(() {
                                            _signaturePath = file.path;
                                          });

                                          // After signature is saved, proceed with registration
                                          await _controller
                                              .registerUser(context);

                                          setState(() {
                                            _isLoading = false;
                                            _status =
                                                "First login will verify your account";
                                          });
                                        } catch (e) {
                                          setState(() {
                                            _isLoading = false;
                                            _status =
                                                "Error saving signature: $e";
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          _isLoading = false;
                                          _status =
                                              "Please provide a signature";
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        _isLoading = false;
                                        _status = "Please provide a signature";
                                      });
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFB71A4A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          )),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignIn(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF03045E),
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Sign In',
                            style: GoogleFonts.poppins(
                              color: Color(0xFFB71A4A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
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
        borderSide: BorderSide(color: Color(0xFFB71A4A), width: 2),
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
