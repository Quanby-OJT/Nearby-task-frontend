import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/notificationController.dart';
import 'package:flutter_fe/view/business_acc/client_record/client_ongoing.dart';
import 'package:flutter_fe/view/notification/client_request.dart';
import 'package:flutter_fe/view/notification/display_task_status.dart';
import 'package:flutter_fe/view/service_acc/tasker_record/tasker_start.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../service/notification_service.dart';

class NotifSTaskerScreen extends StatefulWidget {
  const NotifSTaskerScreen({super.key});

  @override
  State<NotifSTaskerScreen> createState() => _NotifScreenTaskerState();
}

class _NotifScreenTaskerState extends State<NotifSTaskerScreen> {
  // Mock data for all notifications
  final List<Map<String, dynamic>> notifications = [];
  final NotificationController _notificationController =
      NotificationController();
  final storage = GetStorage();
  bool _isLoading = true;

  // Mock data for requests
  final List<Map<String, dynamic>> requestData = [];

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
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      int userId = storage.read("user_id");

      if (userId == null) {
        debugPrint("User ID is null");
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final response =
          await _notificationController.getNotificationRequests(userId);

      debugPrint(response.toString());

      if (response.containsKey("data") && response["data"] != null) {
        setState(() {
          requestData.clear();

          // If data is a single object, wrap it in a list; if it's a list, use it directly
          if (response["data"] is List) {
            requestData.addAll(
              (response["data"] as List)
                  .map((item) => item as Map<String, dynamic>)
                  .toList(),
            );
          } else {
            requestData.add(response["data"] as Map<String, dynamic>);
          }
          _isLoading = false;
        });
      } else {
        debugPrint("No data found in response");
      }
    } catch (e) {
      debugPrint("Error fetching requests: $e");
      setState(() {
        _isLoading = false;
      });
      return;
    }
  }

  String truncateText(String? text, int maxLength) {
    final safeText = text ?? "No description";
    if (safeText.length <= maxLength) return safeText;
    return safeText.substring(0, maxLength) + "...";
  }

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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : requestData.isEmpty
                  ? _buildEmptyState("No requests available!")
                  : ListView.builder(
                      itemCount: requestData.length,
                      itemBuilder: (context, index) {
                        final request = requestData[index];
                        return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                if (request["status"] == "Rejected") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DisplayTaskStatus(
                                        requestID: request["id"],
                                        role: request["role"],
                                      ),
                                    ),
                                  ).then((value) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    _fetchRequests();
                                  });
                                }

                                if (request["status"] == "Confirmed") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskerStart(
                                        requestID: request["id"],
                                      ),
                                    ),
                                  ).then((value) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    _fetchRequests();
                                  });
                                }

                                if (request["status"] == "Ongoing") {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClientOngoing(
                                        ongoingID: request["id"],
                                        role: request["role"],
                                      ),
                                    ),
                                  ).then((value) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    _fetchRequests();
                                  });
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          truncateText(
                                            request["title"] ?? "No title",
                                            20,
                                          ),
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
                                      "Client: ${request["name"]}",
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
                                      truncateText(
                                          request["remarks"] ?? "No remarks",
                                          50),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ));
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
      case "confirmed":
        chipColor = Colors.green;
        break;
      case "completed":
        chipColor = Colors.blue;
        break;
      case "rejected":
        chipColor = Colors.red;
        break;
      case "ongoing":
        chipColor = Colors.yellow;
        break;
      case "canceled":
        chipColor = Colors.grey;
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
