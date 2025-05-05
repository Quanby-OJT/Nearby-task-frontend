import 'package:flutter/material.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:flutter_fe/view/welcome_page/intro_page_1.dart';
import 'package:flutter_fe/view/welcome_page/intro_page_2.dart';
import 'package:flutter_fe/view/welcome_page/intro_page_3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomePageViewMain extends StatefulWidget {
  const WelcomePageViewMain({super.key});

  @override
  State<WelcomePageViewMain> createState() => _WelcomePageViewMainState();
}

class _WelcomePageViewMainState extends State<WelcomePageViewMain> {
  final PageController _controller = PageController();
  bool onLastPage = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 2);
              });
            },
            children: const [
              IntroPage1(),
              IntroPage2(),
              IntroPage3(),
            ],
          ),
          Positioned.fill(
            child: Align(
                alignment: Alignment(0, 0.75),
                child: Column(
                  spacing: 25,
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmoothPageIndicator(
                      controller: _controller,
                      count: 3,
                      effect: SwapEffect(
                          activeDotColor: Color(0xFFB71A4A),
                          dotColor: Colors.grey),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return SignIn();
                          }));
                        },
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size(250, 50),
                            backgroundColor: Color(0xFFB71A4A),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26))),
                        child: Text(
                          "Get Started",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14),
                        ))
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
