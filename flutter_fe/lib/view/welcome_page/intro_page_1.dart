import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage1 extends StatelessWidget {
  const IntroPage1({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallScreen = screenSize.height < 600;

    // Responsive dimensions
    final horizontalPadding = isTablet ? 60.0 : 40.0;
    final illustrationHeight =
        isSmallScreen ? 200.0 : (isTablet ? 320.0 : 280.0);
    final titleFontSize = isTablet ? 32.0 : (isSmallScreen ? 24.0 : 28.0);
    final descriptionFontSize = isTablet ? 18.0 : 16.0;
    final spacingBetweenElements =
        isSmallScreen ? 40.0 : (isTablet ? 80.0 : 60.0);
    final spacingAfterTitle = isSmallScreen ? 16.0 : 20.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFE8F4FD),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: isTablet ? 800 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Custom illustration - responsive
                    SizedBox(
                      height: illustrationHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background decorative elements - responsive positioning
                          if (!isSmallScreen) ...[
                            Positioned(
                              top: illustrationHeight * 0.14,
                              left: isTablet ? 80 : 60,
                              child: Container(
                                width: isTablet ? 16 : 12,
                                height: isTablet ? 16 : 12,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: illustrationHeight * 0.29,
                              right: isTablet ? 60 : 40,
                              child: Container(
                                width: isTablet ? 12 : 8,
                                height: isTablet ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: illustrationHeight * 0.21,
                              left: isTablet ? 60 : 40,
                              child: Container(
                                width: isTablet ? 14 : 10,
                                height: isTablet ? 14 : 10,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],

                          // Main icon stack - responsive sizing
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top layer
                              Container(
                                width: isTablet
                                    ? 140
                                    : (isSmallScreen ? 100 : 120),
                                height:
                                    isTablet ? 50 : (isSmallScreen ? 35 : 40),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[100]!,
                                      Colors.blue[50]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: isTablet ? 12 : 10,
                                      offset: Offset(0, isTablet ? 5 : 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.task_alt,
                                  color: Colors.blue[300],
                                  size:
                                      isTablet ? 28 : (isSmallScreen ? 20 : 24),
                                ),
                              ),

                              SizedBox(height: isTablet ? 16 : 12),

                              // Middle layer
                              Container(
                                width: isTablet
                                    ? 160
                                    : (isSmallScreen ? 120 : 140),
                                height:
                                    isTablet ? 55 : (isSmallScreen ? 40 : 45),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[200]!,
                                      Colors.blue[100]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: isTablet ? 15 : 12,
                                      offset: Offset(0, isTablet ? 7 : 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.people_alt,
                                  color: Colors.blue[400],
                                  size:
                                      isTablet ? 32 : (isSmallScreen ? 24 : 28),
                                ),
                              ),

                              SizedBox(height: isTablet ? 16 : 12),

                              // Bottom layer
                              Container(
                                width: isTablet
                                    ? 180
                                    : (isSmallScreen ? 140 : 160),
                                height:
                                    isTablet ? 60 : (isSmallScreen ? 45 : 50),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB71A4A),
                                      Color(0xFF1565C0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB71A4A)
                                          .withOpacity(0.4),
                                      blurRadius: isTablet ? 18 : 15,
                                      offset: Offset(0, isTablet ? 10 : 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.handyman,
                                  color: Colors.white,
                                  size:
                                      isTablet ? 36 : (isSmallScreen ? 28 : 32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacingBetweenElements),

                    // Title - responsive
                    Text(
                      'Find Tasks Near You',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2C3E50),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),

                    SizedBox(height: spacingAfterTitle),

                    // Description - responsive
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: Text(
                        'Connect with skilled professionals in your area. Whether you need home repairs, cleaning services, or any task completed, QTask makes it easy to find the right person for the job.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: descriptionFontSize,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                    ),

                    // Add bottom padding for small screens
                    if (isSmallScreen) SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
