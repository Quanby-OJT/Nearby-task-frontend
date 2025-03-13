import 'package:flutter/material.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class NavUserScreen extends StatelessWidget implements PreferredSizeWidget {
  const NavUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Expanded(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              child: Expanded(
                  child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  print('click profile');
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ProfileScreen();
                  }));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/image1.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasker',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'Ronnie Estillero',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ))),
          Container(
              child: Row(
            children: [
              Container(
                child: TextButton(
                  onPressed: () {},
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  print('click menu');
                },
                child: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
              )
            ],
          ))
        ],
      )),
      backgroundColor: Colors.blue,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
