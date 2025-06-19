import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:flutter_fe/view/welcome_page/intro_page_1.dart';
import 'package:flutter_fe/view/welcome_page/intro_page_2.dart';
import 'package:flutter_fe/view/welcome_page/intro_page_3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../sign_in/reset_password.dart';

class WelcomePageViewMain extends StatefulWidget {
  final Uri? uri;
  const WelcomePageViewMain({super.key, this.uri});

  @override
  State<WelcomePageViewMain> createState() => _WelcomePageViewMainState();
}

class _WelcomePageViewMainState extends State<WelcomePageViewMain> {
  final PageController _controller = PageController();
  final AuthenticationController _authController = AuthenticationController();
  bool onLastPage = false;
  bool _isVerified = false;
  StreamSubscription<Uri>? _linkSubscription;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _handleDeepLink(widget.uri);
  }

  Future<void> _handleDeepLink(Uri? uri) async {
    final token = uri?.queryParameters['token'];
    final email = uri?.queryParameters['email'];

    if (token != null && email != null) {
      final int userId =
          await _authController.verifyEmail(context, token, email);

      if (userId != 0) {
        debugPrint("User ID: $userId");
        setState(() {
          _isVerified = true;
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPassword(email: email),
            ),
          );
        }
      } else {
        debugPrint("Email verification failed/");
      }
    } else {
      debugPrint("Invalid verification link. Please Try Again.");
    }
  }

  void _nextPage() {
    if (currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignIn()),
      );
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Responsive dimensions
    final skipButtonPadding = EdgeInsets.all(isTablet ? 30.0 : 20.0);
    final bottomContainerPadding = EdgeInsets.only(
      left: isTablet ? 40.0 : 30.0,
      right: isTablet ? 40.0 : 30.0,
      top: isTablet ? 20.0 : 20.0,
      bottom: isTablet ? 40.0 : 30.0 + bottomPadding,
    );
    final buttonMinWidth = isTablet ? 200.0 : 160.0;
    final buttonHeight = isTablet ? 60.0 : 50.0;
    final iconButtonSize = isTablet ? 56.0 : 48.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Skip button - responsive positioning
                Padding(
                  padding: skipButtonPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignIn()),
                          );
                        },
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView content - flexible height
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 800 : double.infinity,
                    ),
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index;
                          onLastPage = (index == 2);
                        });
                      },
                      children: const [
                        IntroPage1(),
                        IntroPage2(),
                        IntroPage3(),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation section - responsive layout
                Container(
                  padding: bottomContainerPadding,
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicator - responsive sizing
                      SmoothPageIndicator(
                        controller: _controller,
                        count: 3,
                        effect: WormEffect(
                          activeDotColor: const Color(0xFFB71A4A),
                          dotColor: Colors.grey[300]!,
                          dotHeight: isTablet ? 12 : 8,
                          dotWidth: isTablet ? 12 : 8,
                          spacing: isTablet ? 20 : 16,
                        ),
                      ),

                      SizedBox(height: isTablet ? 50 : 40),

                      // Navigation buttons - responsive layout
                      isLandscape && !isTablet
                          ? _buildCompactNavigation(
                              buttonHeight, iconButtonSize)
                          : _buildStandardNavigation(
                              buttonMinWidth, buttonHeight, iconButtonSize),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStandardNavigation(
      double buttonMinWidth, double buttonHeight, double iconButtonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        currentPage > 0
            ? Container(
                width: iconButtonSize,
                height: iconButtonSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(iconButtonSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFFB71A4A),
                  ),
                  iconSize: iconButtonSize * 0.4,
                ),
              )
            : SizedBox(width: iconButtonSize),

        // Get Started / Next button
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB71A4A), Color(0xFFE91E63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(buttonHeight / 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB71A4A).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: Size(buttonMinWidth, buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonHeight / 2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  onLastPage ? "Get Started" : "Next",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: buttonHeight * 0.32,
                  ),
                ),
                SizedBox(width: buttonHeight * 0.16),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: buttonHeight * 0.32,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNavigation(double buttonHeight, double iconButtonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button - compact
        if (currentPage > 0) ...[
          Container(
            width: iconButtonSize * 0.8,
            height: iconButtonSize * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(iconButtonSize * 0.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _previousPage,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFFB71A4A),
              ),
              iconSize: iconButtonSize * 0.3,
            ),
          ),
          const SizedBox(width: 16),
        ],

        // Get Started / Next button - compact
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB71A4A), Color(0xFFE91E63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(buttonHeight * 0.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB71A4A).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: Size(buttonHeight * 3.2, buttonHeight * 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonHeight * 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  onLastPage ? "Get Started" : "Next",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: buttonHeight * 0.28,
                  ),
                ),
                SizedBox(width: buttonHeight * 0.12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: buttonHeight * 0.28,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
