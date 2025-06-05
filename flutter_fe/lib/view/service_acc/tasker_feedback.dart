import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/model/tasker_feedback.dart';
import 'package:flutter_fe/view/custom_loading/custom_loading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/service/tasker_service.dart';

class TaskerFeedbackPage extends StatefulWidget{
  const TaskerFeedbackPage({super.key});

  @override
  State<TaskerFeedbackPage> createState() => _TaskerFeedbackPageState();
}

class _TaskerFeedbackPageState extends State<TaskerFeedbackPage>{
  final storage = GetStorage();
  List<TaskerFeedback> taskerFeedback = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getAllTaskerReviews();
  }

  //To be relocated to a new page.
  Future<void> getAllTaskerReviews() async {
    setState(() {
      isLoading = true;
    });
    try {
      final taskerId = storage.read('user_id');
      final taskerService = TaskerService();
      final taskerReviews = await taskerService.getTaskerFeedback(taskerId);
      debugPrint("Tasker Reviews: $taskerReviews");

      setState(() {
        taskerFeedback = taskerReviews;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching tasker reviews: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Widget _buildReviewItem(String reviewer, String comment, int rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF0272B1),
                    radius: 16,
                    child: Text(
                      reviewer.isNotEmpty ? reviewer[0].toUpperCase() : "?",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0272B1),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reviewer,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF0272B1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: List.generate(
                        5,
                            (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateAverageRating(List<TaskerFeedback> feedback) {
    if (feedback.isEmpty) return "0.0";
    double totalRating = 0.0;
    for (var f in feedback) {
      totalRating += f.rating.toDouble();
    }
    double averageRating = totalRating / feedback.length;
    return averageRating.toStringAsFixed(1);
  }

  int _getAverageRatingAsInt(List<TaskerFeedback> feedback) {
    if (feedback.isEmpty) return 0;
    double totalRating = 0.0;
    for (var f in feedback) {
      totalRating += f.rating.toDouble();
    }
    double averageRating = totalRating / feedback.length;
    return averageRating.floor();
  }

  bool _hasHalfStar(List<TaskerFeedback> feedback) {
    if (feedback.isEmpty) return false;
    double totalRating = 0.0;
    for (var f in feedback) {
      totalRating += f.rating.toDouble();
    }
    double averageRating = totalRating / feedback.length;
    return averageRating.remainder(1) >= 0.5;
  }

  String _getCompletionRate(List<TaskerFeedback> feedback) {
    if (feedback.isEmpty) return "0%";
    int completedTasks = 0;
    for (var f in feedback) {
      if (f.rating.toInt() >= 4) {
        completedTasks++;
      }
    }
    double completionRate = (completedTasks / feedback.length) * 100;
    return "${completionRate.toStringAsFixed(0)}%";
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Client's Ratings",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71A4A)
          )
        )
      ),
      body: isLoading
          ? CustomLoading()
          : taskerFeedback.isEmpty
            ? Center( // Center the "No reviews yet" message
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.commentDots,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                          "You don't have any reviews yet. You can encourage your client to review you, only if you finished the task assigned to you.",
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      overallRating(),
                      const SizedBox(height: 24),
                      ListView.builder(
                          shrinkWrap: true, // Add this
                          physics: NeverScrollableScrollPhysics(), // Add this to disable ListView's own scrolling
                          itemCount: taskerFeedback.length, // Add itemCount
                          itemBuilder: (context, index) {
                            final feedback = taskerFeedback[index];
                            return _buildReviewItem(
                              feedback.client.user?.firstName ?? "N/A",
                              feedback.comment,
                              feedback.rating.toInt(),
                            );
                          })
                    ],
                  )
                )
      ),
    );
  }

  Widget overallRating(){
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color(0xFF0272B1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _calculateAverageRating(taskerFeedback),
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0272B1),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int fullStars = _getAverageRatingAsInt(taskerFeedback);
                bool hasHalfStar = _hasHalfStar(taskerFeedback);

                if (index < fullStars) {
                  return Icon(Icons.star, color: Colors.amber, size: 28);
                } else if (index == fullStars && hasHalfStar) {
                  return Icon(Icons.star_half, color: Colors.amber, size: 28);
                } else {
                  return Icon(Icons.star_border, color: Colors.amber, size: 28);
                }
              }),
            ),
            const SizedBox(height: 16),
            Text(
              "${_getCompletionRate(taskerFeedback)} completed tasks",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        )
      )
    );
  }
}