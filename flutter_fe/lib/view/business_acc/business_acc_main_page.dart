import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/view/chat/chat_screen.dart';
import 'package:flutter_fe/view/business_acc/home_page.dart';
import 'package:flutter_fe/view/business_acc/job_post_page.dart';
import 'package:flutter_fe/view/business_acc/likes_screen.dart';
import 'package:flutter_fe/view/business_acc/record.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BusinessAccMain extends StatefulWidget {
  const BusinessAccMain({super.key});

  @override
  _BusinessAccMainState createState() => _BusinessAccMainState();
}

class _BusinessAccMainState extends State<BusinessAccMain> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  Future<bool> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Exit Application"),
          content: const Text("Do you want to exit the NearByTask application?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("No", style: GoogleFonts.poppins(color: Color(0XFF331FB3))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Yes", style: GoogleFonts.poppins(color: Color(0XFF331FB3))),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final shouldExit = await _confirmExit();

        if (context.mounted && shouldExit) {
          // Minimize the app (move to background)
          try {
            if (Platform.isAndroid) {
              SystemNavigator.pop();  // Moves the app to the background
            } else if (Platform.isIOS) {
              exit(0);  // Completely exits the app (no background support on iOS)
            }
          } catch (e, stackTrace) {
            debugPrint("Error minimizing app: $e");
            debugPrint(stackTrace.toString());
          }
        }
      },
      child: Scaffold(
        body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            HomePage(),
            JobPostPage(),
            RecordPage(),
            ChatScreen(),
            LikesScreen(),
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 70,
          child: GNav(
            selectedIndex: _currentIndex,
            onTabChange: _onItemTapped,
            backgroundColor: Color(0xFF0272B1),
            color: Colors.white,
            activeColor: Colors.white,
            gap: 8,
            iconSize: 20,
            padding: EdgeInsets.symmetric(horizontal: 20),
            tabs: const [
              GButton(icon: FontAwesomeIcons.house, text: 'Home'),
              GButton(icon: FontAwesomeIcons.clipboardList, text: 'Post'),
              GButton(icon: FontAwesomeIcons.listCheck, text: 'Tasks'),
              GButton(icon: FontAwesomeIcons.solidMessage, text: 'Chat'),
              GButton(icon: FontAwesomeIcons.solidHeart, text: 'Likes'),
            ],
          ),
        ),
      ),
    );
  }
}
