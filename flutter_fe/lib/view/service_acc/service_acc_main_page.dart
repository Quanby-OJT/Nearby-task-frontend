import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/view/chat/chat_screen.dart';
import 'package:flutter_fe/view/task_user/task.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_fe/view/service_acc/home_page.dart';
import 'package:flutter_fe/view/service_acc/like_screen.dart';
import 'package:flutter_fe/view/service_acc/transaction_history.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceAccMain extends StatefulWidget {
  const ServiceAccMain({super.key});

  @override
  _ServiceAccMainState createState() => _ServiceAccMainState();
}

class _ServiceAccMainState extends State<ServiceAccMain>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animationController.forward().then((_) => _animationController.reverse());
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = [
      FontAwesomeIcons.house,
      FontAwesomeIcons.screwdriverWrench,
      FontAwesomeIcons.moneyBill1Wave,
      FontAwesomeIcons.solidMessage,
      FontAwesomeIcons.solidHeart,
    ];
    final List<String> labels = ['Home', 'Task', 'Wallet', 'Chat', 'Saved'];

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, dynamic) async {
          if (didPop) return;

          final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                    content: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.exclamation,
                          size: 50,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                          "Are You Sure you're going to quit finding tasks?",
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black),
                        ))
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("Swipe More Tasks",
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.blueAccent))),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("Quit",
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.blueAccent))),
                    ],
                  ));

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              TaskerHomePage(),
              TaskPage(),
              TransactionHistoryPage(),
              ChatScreen(),
              LikeScreen(),
            ],
          ),
          bottomNavigationBar: AnimatedBottomNavigationBar.builder(
            itemCount: icons.length,
            tabBuilder: (int index, bool isActive) {
              return ScaleTransition(
                scale: _currentIndex == index && _scaleAnimation != null
                    ? _scaleAnimation!
                    : const AlwaysStoppedAnimation(1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 24,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.white : Colors.white70,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            },
            activeIndex: _currentIndex,
            gapLocation: GapLocation.none,
            notchSmoothness: NotchSmoothness.softEdge,
            onTap: _onItemTapped,
            backgroundColor: const Color(0xFFB71A4A),
            splashColor: Colors.white24,
            height: 70,
            elevation: 8,
            leftCornerRadius: 32,
            rightCornerRadius: 32,
            splashSpeedInMilliseconds: 300,
            splashRadius: 24,
          ),
        ));
  }
}
