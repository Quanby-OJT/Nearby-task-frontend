import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage2 extends StatelessWidget {
  const IntroPage2({super.key});

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
    final barWidth = isTablet ? 55.0 : (isSmallScreen ? 35.0 : 45.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFE8F5E8),
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
                    // Custom illustration - Collaboration theme - responsive
                    SizedBox(
                      height: illustrationHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background decorative elements - responsive positioning
                          if (!isSmallScreen) ...[
                            Positioned(
                              top: illustrationHeight * 0.11,
                              right: isTablet ? 70 : 50,
                              child: Container(
                                width: isTablet ? 14 : 10,
                                height: isTablet ? 14 : 10,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: illustrationHeight * 0.36,
                              left: isTablet ? 50 : 30,
                              child: Container(
                                width: isTablet ? 12 : 8,
                                height: isTablet ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: illustrationHeight * 0.29,
                              right: isTablet ? 80 : 60,
                              child: Container(
                                width: isTablet ? 16 : 12,
                                height: isTablet ? 16 : 12,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],

                          // 3D Bar chart representation - responsive
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Bar 1
                              _buildResponsiveBar(
                                width: barWidth,
                                height:
                                    isTablet ? 120 : (isSmallScreen ? 80 : 100),
                                colors: [
                                  Colors.green[200]!,
                                  Colors.green[400]!
                                ],
                                icon: Icons.star,
                                iconSize:
                                    isTablet ? 24 : (isSmallScreen ? 16 : 20),
                                isTablet: isTablet,
                              ),

                              SizedBox(width: isTablet ? 12 : 8),

                              // Bar 2 (tallest)
                              _buildResponsiveBar(
                                width: barWidth,
                                height: isTablet
                                    ? 160
                                    : (isSmallScreen ? 110 : 140),
                                colors: [
                                  Colors.green[300]!,
                                  Colors.green[600]!
                                ],
                                icon: Icons.trending_up,
                                iconSize:
                                    isTablet ? 28 : (isSmallScreen ? 20 : 24),
                                isTablet: isTablet,
                              ),

                              SizedBox(width: isTablet ? 12 : 8),

                              // Bar 3
                              _buildResponsiveBar(
                                width: barWidth,
                                height: isTablet
                                    ? 140
                                    : (isSmallScreen ? 100 : 120),
                                colors: [
                                  Colors.green[200]!,
                                  Colors.green[500]!
                                ],
                                icon: Icons.groups,
                                iconSize:
                                    isTablet ? 26 : (isSmallScreen ? 18 : 22),
                                isTablet: isTablet,
                              ),

                              SizedBox(width: isTablet ? 12 : 8),

                              // Bar 4
                              _buildResponsiveBar(
                                width: barWidth,
                                height:
                                    isTablet ? 110 : (isSmallScreen ? 70 : 90),
                                colors: [
                                  Colors.green[100]!,
                                  Colors.green[400]!
                                ],
                                icon: Icons.handshake,
                                iconSize:
                                    isTablet ? 22 : (isSmallScreen ? 14 : 18),
                                isTablet: isTablet,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacingBetweenElements),

                    // Title - responsive
                    Text(
                      'Professional Collaboration',
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
                        'Work with verified professionals who bring expertise and reliability to every project. Our platform ensures quality service delivery through our trusted network of skilled taskers.',
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

  Widget _buildResponsiveBar({
    required double width,
    required double height,
    required List<Color> colors,
    required IconData icon,
    required double iconSize,
    required bool isTablet,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.3),
            blurRadius: isTablet ? 12 : 10,
            offset: Offset(-2, isTablet ? 6 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: iconSize,
          ),
        ],
      ),
    );
  }
}
