import 'package:flutter/material.dart';
import 'package:flutter_fe/view/profile/profile_screen.dart';

class InitialProfileScreen extends StatefulWidget {
  const InitialProfileScreen({super.key});

  @override
  State<InitialProfileScreen> createState() => _InitialProfileScreenState();
}

class _InitialProfileScreenState extends State<InitialProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150', // Replace with actual profile image URL
                  ),
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'William John Malik',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Client',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          // Menu Items
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Personal Data'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return ProfileScreen();
              }));
              // Handle navigation to Personal Data
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle navigation to Settings
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt),
            title: Text('E-Statement'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle navigation to E-Statement
            },
          ),
          ListTile(
            leading: Icon(Icons.card_giftcard),
            title: Text('Referral Code'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle navigation to Referral Code
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('FAQs'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle navigation to FAQs
            },
          ),
          ListTile(
            leading: Icon(Icons.book),
            title: Text('Our Handbook'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle navigation to Handbook
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Community'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle navigation to Community
            },
          ),
        ],
      ),
    );
  }
}
