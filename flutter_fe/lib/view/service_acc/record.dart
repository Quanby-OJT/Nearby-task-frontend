import 'package:flutter/material.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_coinfirmed.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_disputed_settled.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_finish.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_ongoing.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_reject.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_review.dart';
import 'package:flutter_fe/view/profile/payment_processing.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/escrow_management_controller.dart';
import 'package:intl/intl.dart';

import '../../model/tasker_feedback.dart';
import '../../service/tasker_service.dart';
import '../business_acc/client_record/display_list_disputed.dart';
import '../business_acc/client_record/display_list_pending.dart';

class RecordTaskerPage extends StatefulWidget {
  const RecordTaskerPage({super.key});

  @override
  State<RecordTaskerPage> createState() => _RecordTaskerPageState();
}

class _RecordTaskerPageState extends State<RecordTaskerPage> {
  final storage = GetStorage();
  final _escrowManagementController = EscrowManagementController();
  List<TaskerFeedback> taskerFeedback = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    getAllTaskerReviews();
  }

  Future<void> _loadData() async {
    await _escrowManagementController.fetchTokenBalance();
    setState(() => _isLoading = false);
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return format.format(amount);
  }

  Future<void> getAllTaskerReviews() async {
    try {
      final taskerId = storage.read('user_id');
      final taskerService = TaskerService();
      final taskerReviews = await taskerService.getTaskerFeedback(taskerId);
      debugPrint("Tasker Reviews: $taskerReviews");

      setState(() {
        taskerFeedback = taskerReviews;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching tasker reviews: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Wallet',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Summary Card
            Container(
              width: double.infinity,
              height: 150,
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Card(
                elevation: 4,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color(0xFFB71A4A),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      _isLoading
                          ? Text(
                              'Please Wait while we calculate your credits',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade100),
                              textAlign: TextAlign.left,
                            )
                          : _escrowManagementController.tokenCredits.value ==
                                  0.0
                              ? Text(
                                  "0.00",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  formatCurrency(_escrowManagementController
                                      .tokenCredits.value
                                      .toDouble()),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                    ],
                  ),
                ),
              ),
            ),

            // Income and Expense Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Income Card
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue[50],
                                  child: Icon(
                                    Icons.arrow_downward,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Income',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              formatCurrency(_escrowManagementController
                                  .tokenCredits.value
                                  .toDouble()),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Withdraw Button
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Show withdraw dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentProcessingPage(transferMethod: "withdraw"),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.red[50],
                                    child: Icon(
                                      Icons.arrow_upward,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Withdraw',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to withdraw',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Task Status Cards - Vertical Scrolling
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Status',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Pending Task Card
                  _buildStatusCard(
                    title: 'Pending Task',
                    color: Color(0xFFFFC107),
                    icon: Icons.pending,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordPending(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),

                  // Review Task Card
                  _buildStatusCard(
                    title: 'Review Task',
                    color: Colors.orangeAccent,
                    icon: Icons.reviews,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordReview(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),
                  _buildStatusCard(
                    title: 'Disputed Tasks',
                    color: Colors.purpleAccent,
                    icon: FontAwesomeIcons.gavel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordDisputed(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),
                  _buildStatusCard(
                    title: 'Settled Disputes',
                    color: Colors.greenAccent,
                    icon: FontAwesomeIcons.fileCircleCheck,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordDisputedSettled(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),
                  // Ongoing Task Card
                  _buildStatusCard(
                    title: 'Ongoing Task',
                    color: Colors.indigo.shade300,
                    icon: Icons.work,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordOngoing(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),

                  // Confirmed Task Card
                  _buildStatusCard(
                    title: 'Confirmed Task',
                    color: Colors.blue.shade300,
                    icon: Icons.handshake,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordConfirmed(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),

                  // Completed Task Card
                  _buildStatusCard(
                    title: 'Completed Task',
                    color: Colors.green.shade300,
                    icon: Icons.check,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordFinish(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),

                  // Rejected Task Card
                  _buildStatusCard(
                    title: 'Rejected Task',
                    color: Colors.red.shade300,
                    icon: Icons.cancel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordReject(),
                        ),
                      ).then((value) {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadData();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                // Icon with colored background
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Right arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                    backgroundColor: Color(0xFF0272B1).withOpacity(0.2),
                    radius: 16,
                    child: Text(
                      reviewer.isNotEmpty ? reviewer[0].toUpperCase() : "?",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0272B1),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reviewer,
                      style: GoogleFonts.montserrat(
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
                  style: GoogleFonts.montserrat(
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
}
