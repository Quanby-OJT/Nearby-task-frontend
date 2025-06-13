import 'package:flutter_fe/view/fill_up/nearby_task_rules.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';

class SignUpGroupTaskerAcc extends StatefulWidget {
  final String role;
  final String taskerGroup;
  const SignUpGroupTaskerAcc(
      {super.key, required this.role, required this.taskerGroup});

  @override
  State<SignUpGroupTaskerAcc> createState() => _SignUpGroupTaskerAccState();
}

class _SignUpGroupTaskerAccState extends State<SignUpGroupTaskerAcc> {
  final ProfileController _controller = ProfileController();
  String _status = "Please fill out the form to register";
  bool _isVerified = false; // Track verification status
  StreamSubscription<Uri>? _linkSubscription;

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
            SizedBox(height: 20),
            Text(
              'Create a New Tasker Account',
              style: TextStyle(
                color: const Color(0xFF0272B1),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                textAlign: TextAlign.center,
                "With ONE SWIPE, You can Find Multiple Tasks in a Matter of Seconds.",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
              ),
            ),
            if (!_isVerified) ...[
              SizedBox(
                height: 450,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: Color(0xFF0272B1)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.companyNameController,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) => value!.isEmpty
                              ? "Please Input Your Agency/Organization Name"
                              : null,
                          decoration:
                              _inputDecoration('Agency/Organization Name'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.emailController,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) => value!.isEmpty
                              ? "Please Input Your Valid Email"
                              : null,
                          decoration: _inputDecoration('Your Valid Email'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.passwordController,
                          obscureText: true,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password Cannot be Empty.';
                            } else {
                              return null;
                            }
                          },
                          decoration: _inputDecoration('Your Password'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password must contain:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• At least 8 characters',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• At least one uppercase letter',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• At least one lowercase letter',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• At least one number',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• At least one special character (!@#\$%^&*(),.?":{}|<>)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: TextFormField(
                          controller: _controller.confirmPasswordController,
                          obscureText: true,
                          cursorColor: Color(0xFF0272B1),
                          validator: (value) =>
                              value != _controller.passwordController.text
                                  ? "Passwords do not match"
                                  : null,
                          decoration: _inputDecoration('Confirmed Password'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0272B1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(horizontal: 30),
                          ),
                          onPressed: () async {
                            if (_controller.emailController.text.isNotEmpty &&
                                _controller
                                    .passwordController.text.isNotEmpty &&
                                _controller.confirmPasswordController.text
                                    .isNotEmpty &&
                                _controller
                                    .companyNameController.text.isNotEmpty) {
                              if (_controller.passwordController.text !=
                                  _controller.confirmPasswordController.text) {
                                setState(() {
                                  _status = "Passwords do not match";
                                });
                                return;
                              }

                              // String? passwordError =
                              //     _controller.validatePassword(
                              //         _controller.passwordController.text);
                              // if (passwordError != null) {
                              //   setState(() {
                              //     _status = passwordError;
                              //   });
                              //   return;
                              // }

                              setState(() {
                                _status = "Creating your account...";
                              });

                              // Set the tasker group to true for group taskers
                              _controller.taskerGroupController.text = "true";

                              // Store the company name
                              _controller.firstNameController.text =
                                  _controller.companyNameController.text;
                              // Set a default last name for group taskers
                              _controller.lastNameController.text =
                                  "Organization";

                              await _controller.registerUser(context);

                              setState(() {
                                _status =
                                    "First login will verify your account";
                              });
                            } else {
                              setState(() {
                                _status = "Please fill all required fields";
                              });
                            }
                          },
                          child: Text(
                            'Create a New Tasker Account',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SignIn()));
                },
                child: Text(
                  'Already have an account?',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _status,
                  style: TextStyle(fontSize: 18, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: Color(0xFFF1F4FF),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent, width: 0),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF0272B1), width: 2),
      ),
    );
  }
}
