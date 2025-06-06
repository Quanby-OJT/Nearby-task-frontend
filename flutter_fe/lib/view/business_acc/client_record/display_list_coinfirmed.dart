import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/notificationController.dart';
import 'package:flutter_fe/view/business_acc/client_record/client_start.dart';
import 'package:flutter_fe/view/service_acc/tasker_record/tasker_start.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class DisplayListRecordConfirmed extends StatefulWidget {
  const DisplayListRecordConfirmed({super.key});

  @override
  State<DisplayListRecordConfirmed> createState() =>
      _DisplayListRecordConfirmedState();
}

class _DisplayListRecordConfirmedState
    extends State<DisplayListRecordConfirmed> {
  // Mock data for all notifications
  final List<Map<String, dynamic>> notifications = [];
  final NotificationController _notificationController =
      NotificationController();
  final storage = GetStorage();
  bool _isLoading = true;

  // Mock data for requests
  final List<Map<String, dynamic>> requestData = [];

  // Track the selected tab index
  final int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      int userId = storage.read("user_id");
      final response =
          await _notificationController.getConfirmedRequests(userId);

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
    return "${safeText.substring(0, maxLength)}...";
  }

  // Method to build content based on the selected tab
  Widget _buildTabContent() {
    return Container(
      color: Colors.blue[50],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : requestData.isEmpty
              ? _buildEmptyState("No confirmed tasks available!")
              : ListView.builder(
                  itemCount: requestData.length,
                  itemBuilder: (context, index) {
                    final request = requestData[index];
                    return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (request["role"] == "Tasker") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientStart(
                                    requestID: request["id"],
                                  ),
                                ),
                              ).then((value) {
                                setState(() {
                                  _isLoading = true;
                                });
                                _fetchRequests();
                              });
                            } else {
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
                                    Chip(
                                      label: Text(
                                        request["status"],
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: Colors.blue[300],
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 0),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "${request["role"]}: ${request["clientName"]}",
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
                              ],
                            ),
                          ),
                        ));
                  },
                ),
    );
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
            "Make sure to assign or create a new task.",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Confirmed Task',
          style: GoogleFonts.montserrat(
            color: Color(0xFFB71A4A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFFB71A4A)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }
}
