import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage3 extends StatelessWidget {
  const IntroPage3({super.key});

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
    final skillBadgeSize = isTablet ? 80.0 : (isSmallScreen ? 60.0 : 70.0);
    final centerBadgeSize = isTablet ? 120.0 : (isSmallScreen ? 80.0 : 100.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFFFF3E0),
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
                    // Custom illustration - Skills and earning theme - responsive
                    Container(
                      height: illustrationHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background decorative elements - responsive positioning
                          if (!isSmallScreen) ...[
                            Positioned(
                              top: illustrationHeight * 0.18,
                              left: isTablet ? 60 : 40,
                              child: Container(
                                width: isTablet ? 18 : 14,
                                height: isTablet ? 18 : 14,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: illustrationHeight * 0.25,
                              right: isTablet ? 50 : 30,
                              child: Container(
                                width: isTablet ? 14 : 10,
                                height: isTablet ? 14 : 10,
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: illustrationHeight * 0.25,
                              left: isTablet ? 70 : 50,
                              child: Container(
                                width: isTablet ? 12 : 8,
                                height: isTablet ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],

                          // Central skill showcase design - responsive
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top skill badges row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSkillBadge(
                                    Icons.build,
                                    Colors.orange[400]!,
                                    "Repair",
                                    skillBadgeSize,
                                    isTablet,
                                    isSmallScreen,
                                  ),
                                  SizedBox(width: isTablet ? 16 : 12),
                                  _buildSkillBadge(
                                    Icons.cleaning_services,
                                    Colors.blue[400]!,
                                    "Clean",
                                    skillBadgeSize,
                                    isTablet,
                                    isSmallScreen,
                                  ),
                                ],
                              ),

                              SizedBox(height: isTablet ? 20 : 16),

                              // Center main badge - larger - responsive
                              Container(
                                width: centerBadgeSize,
                                height: centerBadgeSize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFB71A4A),
                                      const Color(0xFFE91E63),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB71A4A)
                                          .withOpacity(0.4),
                                      blurRadius: isTablet ? 25 : 20,
                                      offset: Offset(0, isTablet ? 10 : 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: centerBadgeSize * 0.4,
                                ),
                              ),

                              SizedBox(height: isTablet ? 20 : 16),

                              // Bottom skill badges row - responsive layout
                              isSmallScreen
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _buildSkillBadge(
                                              Icons.electrical_services,
                                              Colors.purple[400]!,
                                              "Electric",
                                              skillBadgeSize,
                                              isTablet,
                                              isSmallScreen,
                                            ),
                                            SizedBox(width: 12),
                                            _buildSkillBadge(
                                              Icons.plumbing,
                                              Colors.green[400]!,
                                              "Plumb",
                                              skillBadgeSize,
                                              isTablet,
                                              isSmallScreen,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        _buildSkillBadge(
                                          Icons.palette,
                                          Colors.pink[400]!,
                                          "Paint",
                                          skillBadgeSize,
                                          isTablet,
                                          isSmallScreen,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildSkillBadge(
                                          Icons.electrical_services,
                                          Colors.purple[400]!,
                                          "Electric",
                                          skillBadgeSize,
                                          isTablet,
                                          isSmallScreen,
                                        ),
                                        SizedBox(width: isTablet ? 16 : 12),
                                        _buildSkillBadge(
                                          Icons.plumbing,
                                          Colors.green[400]!,
                                          "Plumb",
                                          skillBadgeSize,
                                          isTablet,
                                          isSmallScreen,
                                        ),
                                        SizedBox(width: isTablet ? 16 : 12),
                                        _buildSkillBadge(
                                          Icons.palette,
                                          Colors.pink[400]!,
                                          "Paint",
                                          skillBadgeSize,
                                          isTablet,
                                          isSmallScreen,
                                        ),
                                      ],
                                    ),
                            ],
                          ),

                          // Floating earning indicator - responsive
                          if (!isSmallScreen)
                            Positioned(
                              top: illustrationHeight * 0.14,
                              right: isTablet ? 80 : 60,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green[300]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.2),
                                      blurRadius: isTablet ? 10 : 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      color: Colors.green[600],
                                      size: isTablet ? 18 : 16,
                                    ),
                                    SizedBox(width: isTablet ? 6 : 4),
                                    Text(
                                      '₱500+',
                                      style: GoogleFonts.poppins(
                                        color: Colors.green[700],
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacingBetweenElements),

                    // Title - responsive
                    Text(
                      'Showcase Your Skills',
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
                        'Are you a TESDA graduate or skilled professional? Join our platform to showcase your expertise, connect with clients, and build a thriving service business. Start earning today!',
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

  Widget _buildSkillBadge(
    IconData icon,
    Color color,
    String label,
    double size,
    bool isTablet,
    bool isSmallScreen,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: isTablet ? 10 : 8,
            offset: Offset(0, isTablet ? 5 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: size * 0.34,
          ),
          SizedBox(height: isSmallScreen ? 1 : 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: isTablet ? 10 : (isSmallScreen ? 7 : 8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
