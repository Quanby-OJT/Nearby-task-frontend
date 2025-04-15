import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/client_request.dart';
import 'package:flutter_fe/model/task_assignment.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/chat/ind_chat_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/profile_controller.dart';
import '../../model/auth_user.dart';

class ClientRequest extends StatefulWidget {
  final int? requestID;
  const ClientRequest({super.key, this.requestID});

  @override
  State<ClientRequest> createState() => _ClientRequestState();
}

class _ClientRequestState extends State<ClientRequest> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController taskController = TaskController();

  final ProfileController _userController = ProfileController();
  AuthenticatedUser? _user;
  String? _role;

  TaskModel? _taskInformation;
  ClientRequestModel? _requestInformation;
  bool _isLoading = true;
  final storage = GetStorage();
  bool _isApplying = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
    _fetchUserData();
    _updateNotif();

    debugPrint("Request ID from the widget: ${widget.requestID}");
  }

  Future<void> _updateNotif() async {
    try {
      final response = await taskController.updateNotif(
        widget.requestID ?? 0,
      );
      debugPrint("Update notification response: ${response.toString()}");
      if (!response) {
        debugPrint("Failed to update notification");
      }
    } catch (e) {
      debugPrint("Error updating notification: $e");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = storage.read("user_id");
      AuthenticatedUser? user =
          await _userController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());
      setState(() {
        _user = user;
        _role = user?.user.role;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRequestDetails() async {
    try {
      final response = await _jobPostService.fetchRequestInformation(
        widget.requestID ?? 0,
      );
      debugPrint("Fetched request details: $response");
      setState(() {
        _requestInformation = response;
      });
      await _fetchTaskDetails();
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response = await _jobPostService
          .fetchTaskInformation(_requestInformation!.task_id as int);
      setState(() {
        _taskInformation = response?.task;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        'Request Information',
        style: const TextStyle(
          color: Color(0xFF03045E),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      )),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requestInformation == null
              ? const Center(child: Text('No request information available'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "N/A",
                                          style: GoogleFonts.montserrat(
                                            color: const Color(0xFF03045E),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            if (_requestInformation!
                                                    .task_status !=
                                                null)
                                              Flexible(
                                                child: Text(
                                                  _requestInformation!
                                                      .task_status!,
                                                  style: GoogleFonts.montserrat(
                                                    color: Color.fromARGB(
                                                        255, 57, 209, 11),
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Row(
                                  spacing: 5,
                                  children: [
                                    Icon(
                                      Icons.location_pin,
                                      size: 20,
                                    ),
                                    Text(
                                      "Location",
                                      style: GoogleFonts.openSans(),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // about the client profile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: Color.fromARGB(255, 239, 254, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Tasker Profile",
                                          style: GoogleFonts.montserrat(
                                            color: const Color(0xFF03045E),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildInfoRow("Name", "Mike Smith"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Account", "Verified"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Email", "mike.smith@example.com"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Phone", "+1234567890"),
                              const SizedBox(height: 10),
                              _buildInfoRow("Status", "Active"),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),

                    _requestInformation!.task_status == "Pending"
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, right: 16.0, top: 16),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color.fromARGB(255, 203, 4, 4),
                                  ),
                                  child: TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      final String value = 'Reject';
                                      debugPrint("Reject request role: $_role");
                                      bool result =
                                          await taskController.acceptRequest(
                                              _requestInformation!
                                                  .task_taken_id!,
                                              value,
                                              _role!);
                                      debugPrint(
                                          "Reject request result: $result");
                                      if (result) {
                                        Navigator.pop(context);
                                      } else {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Reject',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, right: 16.0, top: 16),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(0xFF03045E),
                                  ),
                                  child: TextButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      debugPrint("Reject request role: $_role");
                                      final String value = 'Accept';
                                      bool result =
                                          await taskController.acceptRequest(
                                              _requestInformation!
                                                  .task_taken_id!,
                                              value,
                                              _role!);
                                      if (result) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                IndividualChatScreen(
                                              taskTitle:
                                                  _taskInformation!.title,
                                              taskTakenId: _requestInformation!
                                                  .task_taken_id,
                                              taskId: _requestInformation!
                                                  .client_id,
                                            ),
                                          ),
                                        ).then((value) {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          _fetchRequestDetails();
                                        });
                                      } else {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Accept',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _requestInformation!.task_status == "Confirmed"
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, right: 16.0, top: 16),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.yellow,
                                  ),
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Accepted',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ))
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, right: 16.0, top: 16),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color.fromARGB(255, 203, 4, 4),
                                  ),
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ))
                  ],
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
