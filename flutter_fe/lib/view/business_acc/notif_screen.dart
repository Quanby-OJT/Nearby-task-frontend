import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> {
  // Mock data - set to empty list to simulate no notifications
  final List<Map<String, dynamic>> notifications = [];

  // Track the selected tab index
  int _selectedTabIndex = 0;

  // Tab options
  final List<String> _tabOptions = [
    "All",
    "Requests",
    "Messages",
    "Matches",
    "Payments"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.montserrat(color: Color(0xFF0272B1)),
        ),
        iconTheme: IconThemeData(color: Color(0xFF0272B1)),
      ),
      body: Container(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 10.0),
                    child: Row(
                      children: List.generate(
                        _tabOptions.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedTabIndex == index
                                  ? Color(0xFF0272B1) // Selected color
                                  : Colors.grey.shade200, // Unselected color
                              foregroundColor: _selectedTabIndex == index
                                  ? Colors.white // Selected text color
                                  : Color(0xFF0272B1), // Unselected text color
                              elevation: _selectedTabIndex == index ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedTabIndex = index;
                              });
                              print("${_tabOptions[index]} Pressed");
                            },
                            child: Text(
                              _tabOptions[index],
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: _selectedTabIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Empty state indicator
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bell icon with notification badge
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 60,
                                  color: Color(0xFFADE1E5),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Nothing to display here!',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "We'll notify you once we have new notifications.",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        // This would be your notification item widget
                        return ListTile(
                          title: Text(notifications[index]['title'] ?? ''),
                          subtitle: Text(notifications[index]['message'] ?? ''),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
