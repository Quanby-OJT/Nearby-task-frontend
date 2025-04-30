import 'package:flutter/material.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/view/sign_up_acc/sign_up_solo_tasker.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PreSignUp extends StatefulWidget {
  const PreSignUp({super.key});

  @override
  State<PreSignUp> createState() => _PreSignUpState();
}

class _PreSignUpState extends State<PreSignUp> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fadeAnimation2;
  late Animation<Offset> _topSlideAnimation;
  late Animation<Offset> _bottomSlideAnimation1;
  late Animation<Offset> _bottomSlideAnimation2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

//downward
    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

//upward
    _bottomSlideAnimation1 = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _bottomSlideAnimation2 = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        backgroundColor: const Color(0xFFF1F4FF),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F4FF),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Text(
                    'Create a Tasker Account to earn money by completing tasks, or a Client Account to hire experts for your needs',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Text(
                    'Choose your account to get started!',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                SlideTransition(
                  position: _bottomSlideAnimation1,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: screenWidth * 0.8,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpSoloTaskerAcc(
                                role: "Tasker",
                                taskerGroup: "Solo Tasker",
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03045E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.white),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black26,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/icons8-worker-100.png',
                                height: screenWidth * 0.2,
                                width: screenWidth * 0.2,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'TASKER ACCOUNT',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                SlideTransition(
                  position: _bottomSlideAnimation2,
                  child: FadeTransition(
                    opacity: _fadeAnimation2,
                    child: SizedBox(
                      width: screenWidth * 0.8,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return SignUpClientAcc(role: "Client");
                          }));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03045E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.white),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/icons8-checklist-100.png',
                                height: screenWidth * 0.2,
                                width: screenWidth * 0.2,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'CLIENT ACCOUNT',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
