import 'package:flutter/material.dart';
import 'package:flutter_fe/view/profile/initial_profile_screen.dart';
import 'package:flutter_fe/view/service_acc/chat_screen.dart';
import 'package:flutter_fe/view/service_acc/home_page.dart';
import 'package:flutter_fe/view/service_acc/like_screen.dart';
import 'package:flutter_fe/view/service_acc/schedule_management_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class ServiceAccMain extends StatefulWidget {
  const ServiceAccMain({super.key});

  @override
  _ServiceAccMainState createState() => _ServiceAccMainState();
}

class _ServiceAccMainState extends State<ServiceAccMain> {
  int _currentIndex = 0;

  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: NavUserScreen(),
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
          ScheduleManagement(),
          ChatScreen(),
          LikeScreen(),
          InitialProfileScreen()
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
          // type: BottomNavigationBarType.fixed,
          tabs: const [
            GButton(
              icon: Icons.home,
              text: 'Home',
            ),
            GButton(
              icon: Icons.schedule,
              text: 'Schedule',
            ),
            GButton(
              icon: Icons.message,
              text: 'Chat',
            ),
            GButton(
              icon: Icons.list,
              text: 'Request',
            ),
            GButton(
              icon: Icons.person,
              text: 'Profile',
            )
          ],
        ),
      ),
    );
  }
}
