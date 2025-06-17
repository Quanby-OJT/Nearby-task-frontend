import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_fe/view/profile/legal_terms_and_conditions.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_fe/widgets/privacy_policy_popup.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpClientAcc extends StatefulWidget {
  final String role;
  const SignUpClientAcc({super.key, required this.role});

  @override
  State<SignUpClientAcc> createState() => _SignUpClientAccState();
}

class _SignUpClientAccState extends State<SignUpClientAcc> {
  final ProfileController _controller = ProfileController();
  String _status = "Please fill out the form to register";
  late SignatureController _signatureController;
  bool _isVerified = false;
  bool _isLoading = false;
  bool _obsecureTextPassword = true;
  bool _obsecureTextConfirmPassword = true;
  bool _agreeToTerms = false;
  final _formKey = GlobalKey<FormState>();
  StreamSubscription<Uri>? _linkSubscription;
  File? _signatureImage;
  final ImagePicker _picker = ImagePicker();

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
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Show privacy policy popup after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PrivacyPolicyPopup();
        },
      );
    });
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

  Future<void> _pickSignatureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _signatureImage = File(image.path);
          // Clear the signature pad if an image is uploaded
          _signatureController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? signatureData;
      final email = _controller.emailController.text.toLowerCase();

      if (email.isEmpty) {
        debugPrint('Cannot save signature: Email is empty');
        return;
      }

      if (_signatureImage != null) {
        final bytes = await _signatureImage!.readAsBytes();
        signatureData = base64Encode(bytes);
      } else if (!_signatureController.isEmpty) {
        final bytes = await _signatureController.toPngBytes();
        if (bytes != null) {
          signatureData = base64Encode(bytes);
        }
      }

      if (signatureData != null) {
        await prefs.setString('user_signature_$email', signatureData);
        debugPrint('Signature saved successfully for: $email');
      } else {
        debugPrint('No signature data to save for: $email');
      }
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        } else {
                          return null;
                        }
                      },
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        } else {
                          return null;
                        }
                      },
                      decoration: _getInputDecoration('Last Name'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.emailController,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                .hasMatch(value)) {
                          return 'Please enter your valid email';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: _getInputDecoration('Email Address'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      cursorColor: Color(0xFFB71A4A),
                      controller: _controller.passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty.';
                        } else {
                          return null;
                        }
                      },
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        } else if (value !=
                            _controller.passwordController.text) {
                          return "Passwords do not match.";
                        } else {
                          return null;
                        }
                      },
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: _pickSignatureImage,
                                icon: Icon(Icons.upload_file,
                                    color: Color(0xFFB71A4A)),
                                label: Text(
                                  'Upload Signature',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFB71A4A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_signatureImage != null)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _signatureImage = null;
                                    });
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  label: Text(
                                    'Remove',
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _signatureImage != null
                                  ? Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                      ),
                                      child: Image.file(
                                        _signatureImage!,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Signature(
                                      controller: _signatureController,
                                      backgroundColor: Colors.white,
                                    ),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (_signatureImage == null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _signatureController.clear();
                                  },
                                  child: Text(
                                    'Clear',
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFFB71A4A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    //Privacy Policy and Terms of Service
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFFB71A4A),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                              ),
                              children: [
                                const TextSpan(text: 'By signing up, you agree to our '),

                                TextSpan(
                                  text: 'Terms of Service.',
                                  style: const TextStyle(color: Color(0xFFB71A4A), decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LegalTermsAndConditionsScreen())
                                  ),
                                ),
                                // const TextSpan(text: ' and '),
                                // TextSpan(
                                //   text: 'Privacy Policy',
                                //   style: const TextStyle(color: Color(0xFFB71A4A), decoration: TextDecoration.underline),
                                //   // recognizer: TapGestureRecognizer()..onTap = () => _launchURL('YOUR_PRIVACY_POLICY_URL'),
                                // ),
                              ],
                            ),
                          )
                        )
                      ]
                    ),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _isLoading || !_agreeToTerms
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                      _status = "Creating your account...";
                                    });

                                    // Save signature before registering
                                    await _saveSignature();

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
