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
            'Wallet',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Color(0xFFB71A4A),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
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
                        'NearByTask Credits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      _isLoading
                          ? Text(
                              'Please Wait while we calculate your NearByTask Credits',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade100),
                              textAlign: TextAlign.left,
                            )
                          : _escrowManagementController.tokenCredits.value ==
                                  0.0
                              ? Text(
                                  "No credits available. Earn more by taking tasks.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  formatCurrency(_escrowManagementController
                                      .tokenCredits.value
                                      .toDouble()),
                                  style: TextStyle(
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
                                  style: TextStyle(
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
                              style: TextStyle(
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
                          _showWithdrawDialog();
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
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to withdraw',
                                style: TextStyle(
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

            // Reviews Card
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Card(
            //     elevation: 2,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //     child: Padding(
            //       padding: const EdgeInsets.all(16.0),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Row(
            //             children: [
            //               Icon(
            //                 Icons.star_rate_rounded,
            //                 color: Colors.amber,
            //                 size: 24,
            //               ),
            //               SizedBox(width: 8),
            //               Text(
            //                 "Client Reviews",
            //                 style: GoogleFonts.montserrat(
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.bold,
            //                   color: Colors.black,
            //                 ),
            //               ),
            //             ],
            //           ),
            //           SizedBox(height: 16),
            //           if (taskerFeedback.isNotEmpty)
            //             Container(
            //               padding: EdgeInsets.all(12),
            //               decoration: BoxDecoration(
            //                 color: Color(0xFF0272B1).withOpacity(0.05),
            //                 borderRadius: BorderRadius.circular(8),
            //               ),
            //               child: Row(
            //                 children: [
            //                   Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     children: [
            //                       Text(
            //                         "Average Rating",
            //                         style: GoogleFonts.montserrat(
            //                           fontSize: 14,
            //                           fontWeight: FontWeight.w500,
            //                           color: Colors.black87,
            //                         ),
            //                       ),
            //                       SizedBox(height: 4),
            //                       Row(
            //                         children: [
            //                           Text(
            //                             _calculateAverageRating(taskerFeedback),
            //                             style: GoogleFonts.montserrat(
            //                               fontSize: 24,
            //                               fontWeight: FontWeight.bold,
            //                               color: Color(0xFF0272B1),
            //                             ),
            //                           ),
            //                           SizedBox(width: 8),
            //                           Row(
            //                             children: List.generate(
            //                               5,
            //                               (index) => Icon(
            //                                 index <
            //                                         _getAverageRatingAsInt(
            //                                             taskerFeedback)
            //                                     ? Icons.star
            //                                     : index ==
            //                                                 _getAverageRatingAsInt(
            //                                                     taskerFeedback) &&
            //                                             _hasHalfStar(
            //                                                 taskerFeedback)
            //                                         ? Icons.star_half
            //                                         : Icons.star_border,
            //                                 color: Colors.amber,
            //                                 size: 18,
            //                               ),
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                     ],
            //                   ),
            //                   Spacer(),
            //                   Column(
            //                     crossAxisAlignment: CrossAxisAlignment.end,
            //                     children: [
            //                       Text(
            //                         "${taskerFeedback.length} reviews",
            //                         style: GoogleFonts.montserrat(
            //                           fontSize: 14,
            //                           fontWeight: FontWeight.w500,
            //                           color: Colors.black87,
            //                         ),
            //                       ),
            //                       SizedBox(height: 4),
            //                       Text(
            //                         _getCompletionRate(taskerFeedback),
            //                         style: GoogleFonts.montserrat(
            //                           fontSize: 12,
            //                           color: Colors.green[700],
            //                           fontWeight: FontWeight.bold,
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           SizedBox(height: 16),
            //           Container(
            //             height: 200, // Fixed height for the review list
            //             child: taskerFeedback.isEmpty
            //                 ? Center(
            //                     child: Column(
            //                       mainAxisAlignment: MainAxisAlignment.center,
            //                       children: [
            //                         Icon(
            //                           Icons.rate_review_outlined,
            //                           size: 48,
            //                           color: Colors.grey[400],
            //                         ),
            //                         SizedBox(height: 16),
            //                         Text(
            //                           "No reviews yet",
            //                           style: GoogleFonts.montserrat(
            //                             fontSize: 16,
            //                             fontWeight: FontWeight.w500,
            //                             color: Colors.grey[600],
            //                           ),
            //                         ),
            //                         Text(
            //                           "Complete tasks to get client reviews",
            //                           style: GoogleFonts.montserrat(
            //                             fontSize: 14,
            //                             color: Colors.grey[500],
            //                           ),
            //                           textAlign: TextAlign.center,
            //                         ),
            //                       ],
            //                     ),
            //                   )
            //                 : ListView.builder(
            //                     itemCount: taskerFeedback.length,
            //                     itemBuilder: (context, index) {
            //                       final feedback = taskerFeedback[index];
            //                       return _buildReviewItem(
            //                         "${feedback.client.user?.firstName} ${feedback.client.user?.lastName}",
            //                         feedback.comment,
            //                         feedback.rating.toInt(),
            //                       );
            //                     },
            //                   ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

            // Task Status Cards - Vertical Scrolling
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Status',
                    style: TextStyle(
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

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final double availableBalance =
        _escrowManagementController.tokenCredits.value.toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Withdraw Credits',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0272B1),
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon:
                      Icon(Icons.attach_money, color: Color(0xFF0272B1)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF0272B1), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }

                  final double? amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }

                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }

                  if (amount > availableBalance) {
                    return 'Amount exceeds available balance';
                  }

                  return null;
                },
              ),
              SizedBox(height: 16),
              Text(
                'Withdrawal will be processed to your linked payment method.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final double amount = double.parse(amountController.text);

                // Process withdrawal
                _processWithdrawal(amount);

                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0272B1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Withdraw',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _processWithdrawal(double amount) {
    // Here you would call the API to process the withdrawal
    // For now we'll just show a success message and update the UI
    setState(() {
      // You might need to call your backend API here
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Withdrawal of ${formatCurrency(amount)} has been initiated'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
