import 'package:flutter/material.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskerProfilePage extends StatefulWidget {
  final UserModel tasker;

  const TaskerProfilePage({super.key, required this.tasker});

  @override
  State<TaskerProfilePage> createState() => _TaskerProfilePageState();
}

class _TaskerProfilePageState extends State<TaskerProfilePage> {
  bool _isLoading = true;
  TaskerModel? _taskerDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTaskerDetails();
  }

  Future<void> _loadTaskerDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // In a real app, you would fetch detailed tasker profile here
      // For now, we'll just use the basic user model info we already have

      // Mock loading delay
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load tasker details: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasker Profile',
          style: GoogleFonts.montserrat(
            color: Color(0xFF0272B1),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFF0272B1)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTaskerDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0272B1),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Header
                      Container(
                        color: Color(0xFFE3F2FD),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  AssetImage('assets/images/image1.jpg'),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "${widget.tasker.firstName} ${widget.tasker.lastName}",
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0272B1),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFF0272B1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.tasker.role,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatItem("4.8", "Rating"),
                                SizedBox(width: 24),
                                _buildStatItem("54", "Jobs"),
                                SizedBox(width: 24),
                                _buildStatItem("2 yrs", "Experience"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Contact Information
                      _buildSectionCard("Contact Information", [
                        _buildInfoRow(
                            Icons.email, "Email", widget.tasker.email),
                        _buildInfoRow(Icons.phone, "Phone", "+63 XXX XXX XXXX"),
                      ]),

                      // Basic Information
                      _buildSectionCard("Basic Information", [
                        _buildInfoRow(
                            Icons.badge, "ID", "#${widget.tasker.id}"),
                        _buildInfoRow(
                            Icons.location_on, "Location", "Metro Manila"),
                        _buildInfoRow(
                            Icons.work, "Specialization", "General Services"),
                      ]),

                      // Skills & Expertise
                      _buildSectionCard("Skills & Expertise", [
                        _buildSkillChip("Home Cleaning"),
                        _buildSkillChip("Gardening"),
                        _buildSkillChip("Electrical Work"),
                        _buildSkillChip("Plumbing"),
                        _buildSkillChip("Painting"),
                      ]),

                      // Action Buttons
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Like action
                                  _likeTasker();
                                },
                                icon: Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                ),
                                label: Text('Like'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0272B1),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
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
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0272B1),
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF0272B1), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Chip(
      label: Text(skill),
      backgroundColor: Color(0xFFE3F2FD),
      labelStyle: GoogleFonts.montserrat(
        color: Color(0xFF0272B1),
        fontWeight: FontWeight.w500,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _likeTasker() async {
    try {
      if (widget.tasker.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cannot like tasker: Invalid tasker ID"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ClientServices clientServices = ClientServices();
      final result = await clientServices.saveLikedTasker(widget.tasker.id!);

      if (result.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Tasker liked successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? "Failed to like tasker"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to like tasker: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
