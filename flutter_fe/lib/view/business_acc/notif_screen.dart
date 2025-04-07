import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> {
  // Mock data for all notifications
  final List<Map<String, dynamic>> notifications = [];

  // Mock data for requests
  final List<Map<String, dynamic>> requestData = [
    {
      "id": 1,
      "title": "Fix Kitchen Sink",
      "status": "Pending",
      "date": "2025-04-07",
      "description": "Client requested a plumber to fix a leaking sink.",
      "clientName": "John Doe",
    },
    {
      "id": 2,
      "title": "Paint Living Room",
      "status": "Approved",
      "date": "2025-04-06",
      "description": "Painting job for a 12x15 ft living room, beige color.",
      "clientName": "Jane Smith",
    },
    {
      "id": 3,
      "title": "Garden Maintenance",
      "status": "Rejected",
      "date": "2025-04-05",
      "description": "Trim bushes and mow lawn for a small backyard.",
      "clientName": "Alice Brown",
    },
    {
      "id": 4,
      "title": "Fix Roof",
      "status": "Pending",
      "date": "2025-04-04",
      "description": "Client requested a carpenter to fix a damaged roof.",
      "clientName": "Bob Johnson",
    },
    {
      "id": 5,
      "title": "Fix Toilet",
      "status": "Pending",
      "date": "2025-04-03",
      "description": "Client requested a plumber to fix a clogged toilet.",
      "clientName": "Alice Johnson",
    },
    {
      "id": 6,
      "title": "Fix Bathroom Sink",
      "status": "Pending",
      "date": "2025-04-02",
      "description": "Client requested a plumber to fix a clogged sink.",
      "clientName": "Bob Johnson",
    },
    {
      "id": 7,
      "title": "Fix Bathroom Sink",
      "status": "Pending",
      "date": "2025-04-01",
      "description": "Client requested a plumber to fix a clogged sink.",
      "clientName": "Alice Johnson",
    },
  ];

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
  void initState() {
    super.initState();
    // _fetchRequests();
  }

  // Future<void> _fetchRequests() async {
  //   try {
  //     // Replace with your API call
  //     final response = await http.get(Uri.parse("your_api_endpoint/requests"));
  //     final List<dynamic> jsonData = jsonDecode(response.body);
  //     setState(() {
  //       requestData.clear();
  //       requestData
  //           .addAll(jsonData.map((item) => item as Map<String, dynamic>));
  //     });
  //   } catch (e) {
  //     print("Error fetching requests: $e");
  //   }
  // }

  // Method to build content based on the selected tab
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // All
        return Container(
          color: Colors.white,
          child: notifications.isEmpty
              ? _buildEmptyState("No notifications yet!")
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(notifications[index]['title'] ?? ''),
                      subtitle: Text(notifications[index]['message'] ?? ''),
                    );
                  },
                ),
        );

      case 1: // Requests
        return Container(
          color: Colors.blue[50],
          child: requestData.isEmpty
              ? _buildEmptyState("No requests available!")
              : ListView.builder(
                  itemCount: requestData.length,
                  itemBuilder: (context, index) {
                    final request = requestData[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  request["title"],
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                _buildStatusChip(request["status"]),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Client: ${request["clientName"]}",
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Date: ${request["date"]}",
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              request["description"],
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );

      case 2: // Messages
        return Container(
          color: Colors.green[50],
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, size: 60, color: Colors.green[300]),
                SizedBox(height: 16),
                Text(
                  "Messages",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Check your unread messages here.",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case 3: // Matches
        return Container(
          color: Colors.orange[50],
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 60, color: Colors.orange[300]),
                SizedBox(height: 16),
                Text(
                  "Matches",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "See your matched tasks or users here.",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case 4: // Payments
        return Container(
          color: Colors.purple[50],
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 60, color: Colors.purple[300]),
                SizedBox(height: 16),
                Text(
                  "Payments",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Track your payment status here.",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      default:
        return Container();
    }
  }

  // Reusable empty state widget
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            message,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "We'll notify you once we have new updates.",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build status chip
  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case "pending":
        chipColor = Colors.orange;
        break;
      case "approved":
        chipColor = Colors.green;
        break;
      case "rejected":
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }
    return Chip(
      label: Text(
        status,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

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
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: Row(
                children: List.generate(
                  _tabOptions.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTabIndex == index
                            ? Color(0xFF0272B1)
                            : Colors.grey.shade200,
                        foregroundColor: _selectedTabIndex == index
                            ? Colors.white
                            : Color(0xFF0272B1),
                        elevation: _selectedTabIndex == index ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          ),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }
}
