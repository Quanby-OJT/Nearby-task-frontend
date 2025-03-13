import 'package:flutter/material.dart';
import 'package:flutter_fe/view/business_acc/chat_screen.dart';
import 'package:flutter_fe/view/business_acc/home_page.dart';
import 'package:flutter_fe/view/business_acc/initial_profile_screen.dart';
import 'package:flutter_fe/view/business_acc/job_post_page.dart';
import 'package:flutter_fe/view/business_acc/likes_screen.dart';
import 'package:flutter_fe/view/business_acc/profile_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_fe/view/nav/user_navigation.dart';

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
          JobPostPage(),
          ChatScreen(),
          LikesScreen(),
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
          //type: BottomNavigationBarType.fixed,
          tabs: const [
            GButton(
              icon: Icons.home,
              text: 'Home',
            ),
            GButton(
              icon: Icons.post_add,
              text: 'Post',
            ),
            GButton(
              icon: Icons.message,
              text: 'Chat',
            ),
            GButton(
              icon: Icons.favorite,
              text: 'Likes',
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
