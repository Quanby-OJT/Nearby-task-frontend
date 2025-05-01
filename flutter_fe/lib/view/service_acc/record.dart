import 'package:flutter/material.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_coinfirmed.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_finish.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_ongoing.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_reject.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_review.dart';

import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/escrow_management_controller.dart';
import 'package:intl/intl.dart';

import '../../model/tasker_feedback.dart';
import '../../service/tasker_service.dart';
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            'My Record',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Color(0xFF0272B1),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                        child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(children: [
                          //UI Must be improved.
                          _isLoading
                              ? Text(
                                  'Please Wait while we calculate your NearByTask Credits',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow.shade800),
                                  textAlign: TextAlign.center,
                                )
                              : _escrowManagementController
                                          .tokenCredits.value ==
                                      0.0
                                  ? Text(
                                      "You don't have any NearByTask Credits to your account. Earn More by taking more tasks.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0XFFB62C5C)))
                                  : Text.rich(TextSpan(children: [
                                      TextSpan(
                                          text: 'You Had Earned: ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                          )),
                                      TextSpan(
                                          text:
                                              '${formatCurrency(_escrowManagementController.tokenCredits.value.toDouble())} to your Existing Wallet.',
                                          style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.yellow.shade800)),
                                    ])),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rate_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Client Reviews",
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          if (taskerFeedback.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF0272B1).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Average Rating",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _calculateAverageRating(
                                                taskerFeedback),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0272B1),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (index) => Icon(
                                                index <
                                                        _getAverageRatingAsInt(
                                                            taskerFeedback)
                                                    ? Icons.star
                                                    : index ==
                                                                _getAverageRatingAsInt(
                                                                    taskerFeedback) &&
                                                            _hasHalfStar(
                                                                taskerFeedback)
                                                        ? Icons.star_half
                                                        : Icons.star_border,
                                                color: Colors.amber,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${taskerFeedback.length} reviews",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _getCompletionRate(taskerFeedback),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 10),
                          Expanded(
                            child: taskerFeedback.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "No reviews yet",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          "Complete tasks to get client reviews",
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: taskerFeedback
                                          .map((feedback) => _buildReviewItem(
                                              "${feedback.client.user?.firstName} ${feedback.client.user?.lastName}",
                                              feedback.comment,
                                              feedback.rating.toInt()))
                                          .toList(),
                                    ),
                                  ),
                          )
                        ]),
                      ),
                    )),
                  ],
                ),
              )),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
              alignment: Alignment.center,
              child: SizedBox(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.yellow.withOpacity(0.1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DisplayListRecordPending(),
                              ),
                            ).then((value) {
                              setState(() {
                                _isLoading = true;
                              });
                            });
                          },
                          child: Container(
                            width: 150, // Width of each card
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Color(0xFFFFC107),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pending Task',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Optionally, add more details like a count or icon
                                Icon(
                                  Icons.pending,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.yellow.withOpacity(0.1),
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
                            });
                          },
                          child: Container(
                            width: 150, // Width of each card
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.orangeAccent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Review Task',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Optionally, add more details like a count or icon
                                Icon(
                                  Icons.reviews,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.orange.withOpacity(0.1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DisplayListRecordOngoing(),
                              ),
                            ).then((value) {
                              setState(() {
                                _isLoading = true;
                              });
                            });
                          },
                          child: Container(
                            width: 150, // Width of each card
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.indigo.shade300,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ongoing Task',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Optionally, add more details like a count or icon
                                Icon(
                                  Icons.work,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.green.withOpacity(0.1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DisplayListRecordConfirmed()),
                            ).then((value) {
                              setState(() {
                                _isLoading = true;
                              });
                            });
                          },
                          child: Container(
                            width: 150, // Width of each card
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.blue.shade300,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Confirmed Task',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Optionally, add more details like a count or icon
                                Icon(
                                  Icons.handshake,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.green.withOpacity(0.1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DisplayListRecordFinish()),
                            ).then((value) {
                              setState(() {
                                _isLoading = true;
                              });
                            });
                          },
                          child: Container(
                            width: 150, // Width of each card
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.green.shade300,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Completed Task',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Optionally, add more details like a count or icon
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.red.withOpacity(0.1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DisplayListRecordReject()),
                            ).then((value) {
                              setState(() {
                                _isLoading = true;
                              });
                            });
                          },
                          child: Container(
                            width: 150, // Width of each card
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.red.shade300,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Rejected Task',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Optionally, add more details like a count or icon
                                Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                  size: 24,
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
            ),
          )
        ],
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
