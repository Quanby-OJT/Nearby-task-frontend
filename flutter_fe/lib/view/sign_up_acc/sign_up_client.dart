import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpClientAcc extends StatefulWidget {
  final String role;
  const SignUpClientAcc({super.key, required this.role});

  @override
  State<SignUpClientAcc> createState() => _SignUpClientAccState();
}

class _SignUpClientAccState extends State<SignUpClientAcc> {
  final ProfileController _controller = ProfileController();
  String _status = "Please fill out the form to register";

  bool _isVerified = false;
  bool _isLoading = false;
  bool _obsecureTextPassword = true;
  bool _obsecureTextConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();
  StreamSubscription<Uri>? _linkSubscription;

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

        if (mounted) {}
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF0272B1)),
          onPressed: () => Navigator.of(context).pop(),
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
                ' Client Account',
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
                  "With ONE SWIPE\n You can Find a New Tasker in a MATTER OF SECONDS.	",
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

                                    await _controller.registerUser(context);

                                    setState(() {
                                      _isLoading = false;
                                      _status =
                                          "First login will verify your account";
                                    });
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
