import 'dart:async';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_fe/view/fill_up/nearby_task_rules.dart';


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
  final _formKey = GlobalKey<FormState>();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
    _controller.roleController.text = widget.role;
  }

  Future<void> _initDeepLinkListener() async {
    final _appLinks = AppLinks();

    // Handle initial link (app opened via deep link)
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      setState(() => _status = "An error occurred");
    }

    // Listen for links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
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
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => NearbyTaskRules(userId: userId),
          //   ),
          // );
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
                'Create a New Client Account',
                style: TextStyle(
                    color: const Color(0xFF0272B1),
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  "With ONE SWIPE, You can Find a New Tasker in a MATTER OF SECONDS.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
              if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _isVerified ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _controller.firstNameController,
                      validator: (value) =>
                          _controller.validateName(value, "first name"),
                      decoration: _getInputDecoration('First Name'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _controller.middleNameController,
                      decoration: _getInputDecoration('Middle Name (Optional)'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _controller.lastNameController,
                      validator: (value) =>
                          _controller.validateName(value, "last name"),
                      decoration: _getInputDecoration('Last Name'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _controller.emailController,
                      validator: _controller.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _getInputDecoration('Email Address'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _controller.passwordController,
                      validator: _controller.validatePassword,
                      obscureText: true,
                      decoration: _getInputDecoration('Password'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _controller.confirmPasswordController,
                      validator: _controller.validateConfirmPassword,
                      obscureText: true,
                      decoration: _getInputDecoration('Confirm Password'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0272B1),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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
                                      "Please check your email to verify your account";
                                });
                              }
                            },
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Create New Client Account',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/signin'),
                      child: Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          color: Color(0xFF0272B1),
                          fontWeight: FontWeight.bold,
                        ),
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
