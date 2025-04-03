import 'package:flutter/material.dart';
import 'package:flutter_fe/view/sign_up_acc/pre_sign_up.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthenticationController _controller = AuthenticationController();

  bool _obsecureText = true;

  void _toggleObscureText() {
    setState(() {
      _obsecureText = !_obsecureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/svg/logo.svg',
                width: 150,
                height: 150,
              ),
              Text(
                textAlign: TextAlign.center,
                'Find Tasks Near You with NearbyTask!',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w300),
              ),
              SizedBox(height: 20),
              Text(
                'Login',
                style: GoogleFonts.montserrat(
                    color: const Color(0xFF03045E),
                    fontSize: 30,
                    fontWeight: FontWeight.w800),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                child: TextField(
                  controller: _controller.emailController,
                  cursorColor: Color(0xFF0272B1),
                  decoration: _getInputDecoration('Email'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 40, top: 20),
                child: TextField(
                  obscureText: _obsecureText,
                  controller: _controller.passwordController,
                  cursorColor: Color(0xFF0272B1),
                  decoration: _getInputDecoration('Password').copyWith(
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: IconButton(
                        icon: Icon(
                          _obsecureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Color(0xFF0272B1),
                        ),
                        onPressed: _toggleObscureText,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                  child: TextButton(
                      onPressed: () {},
                      child: Text(
                        textAlign: TextAlign.right,
                        'Forgot your password?',
                        style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontWeight: FontWeight.w100,
                            fontSize: 10),
                      )),
                ),
              ),
              Container(
                height: 50,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                    onPressed: () {
                      _controller.loginAuth(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF03045E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    )),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Don't you have an account? ",
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PreSignUp()),
                        );
                      },
                      child: Text(
                        "Sign up",
                        style: GoogleFonts.montserrat(
                          color: Color(0xFF03045E),
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
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
