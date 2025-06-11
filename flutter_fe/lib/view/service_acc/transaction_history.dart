import 'package:flutter/material.dart';
import 'package:flutter_fe/view/profile/payment_processing.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:intl/intl.dart';
import 'package:flutter_fe/model/tasker_feedback.dart';
import 'package:flutter_fe/model/transactions.dart';
import 'package:flutter_fe/view/task/task_details_screen.dart';
import 'package:flutter_fe/controller/task_controller.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with TickerProviderStateMixin {
  final storage = GetStorage();
  final _escrowManagementController = EscrowManagementController();
  List<TaskerFeedback> taskerFeedback = [];
  List<Transactions> _transactionHistory = [];
  final TaskController taskController = TaskController();
  late AnimationController loadingController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    loadingController.repeat(reverse: true);

    try {
      await _escrowManagementController.fetchTokenBalance();
      await getTransactionHistory();
    } finally {
      if (mounted) {
        loadingController.stop();
        // Ensure the controller value is at a resting state (e.g., 0 or 1)
        loadingController.value = 0;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> getTransactionHistory() async {
    final transactionData = await taskController.getAllTransactions();

    setState(() {
      _transactionHistory = transactionData;
    });
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return format.format(amount);
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
                        'Your Total Earnings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      _isLoading
                          ? LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFE23670)),
                              backgroundColor: Color(0XFFF5A1BB),
                            )
                          : _escrowManagementController.tokenCredits.value == 0.0
                              ? Text(
                                  "₱ 0.00",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  formatCurrency(_escrowManagementController
                                      .tokenCredits.value
                                      .toDouble()),
                                  style: GoogleFonts.montserrat(
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
                              style: GoogleFonts.montserrat(
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
                              builder: (context) => PaymentProcessingPage(
                                  transferMethod: "withdraw"),
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

            // Transaction History - Vertical Scrolling
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transaction History",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      SizedBox(height: 10),
                      _isLoading
                          ? Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Add a SizedBox for spacing (20% of card width for example)
                                    SizedBox(
                                        width: MediaQuery.of(context)
                                                .size
                                                .width *
                                            0.1), // Adjust the percentage as needed
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0XFFE23670)),
                                            backgroundColor: Color(0XFFF5A1BB),
                                          ),
                                          SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0XFFE23670)),
                                            backgroundColor: Color(0XFFF5A1BB),
                                          ),
                                          SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0XFFE23670)),
                                            backgroundColor: Color(0XFFF5A1BB),
                                          ),
                                          SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0XFFE23670)),
                                            backgroundColor: Color(0XFFF5A1BB),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _transactionHistory.isEmpty
                            ? Text(
                                "You don't have any transactions yet",
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.black)
                              )
                            : ListView.builder(
                                shrinkWrap:
                                    true, // Important to make ListView scrollable within Column
                                physics:
                                    NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                                itemCount: _transactionHistory.length,
                                itemBuilder: (context, index) {
                                  final transaction = _transactionHistory[index];
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 10),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  TaskDetailsScreen(
                                                    taskAssignment: transaction
                                                        .taskAssignment,
                                                    taskStatus:
                                                        transaction.recordStatus,
                                                    transactionDate:
                                                        DateTime.parse(
                                                            transaction.date),
                                                  ))),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            statusColor(transaction.recordStatus),
                                        radius: 5, // Small color indicator
                                      ),
                                      title: Text(
                                        transaction.taskAssignment.task?.title ??
                                            "N/A",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Client: ${transaction.taskAssignment.client?.user?.firstName ?? ''} ${transaction.taskAssignment.client?.user?.middleName ?? ''} ${transaction.taskAssignment.client?.user?.lastName ?? ''}',
                                            style:
                                                GoogleFonts.poppins(fontSize: 12),
                                          ),
                                          Text(
                                            'Status: ${transaction.recordStatus}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        DateFormat('yyyy-MM-dd HH:mm a').format(
                                            DateTime.parse(transaction
                                                .date)), // Display formatted date and time
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.normal,
                                            color: Colors.grey[600]),
                                      ),
                                    ),
                                  );
                                },
                              )
                      ]
                )
            )
          ],
        ),
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Color(0XFFE7A335);
      case 'Confirmed':
        return Color(0XFF7BC0F5);
      case 'Rejected':
        return Color(0XFFD43D4D);
      case 'Cancelled':
        return Color(0XFFD43D4D);
      case 'Ongoing':
        return Color(0XFF3E9FE5);
      case 'Review':
        return Color(0XFFD6932A);
      case 'Disputed':
        return Color(0XFFD43D4D);
      case 'Completed':
        return Color(0XFF4DBF66);
      case 'Reworking':
        return Color(0XFF3E9FE5);
      case 'Expired':
        return Color(0XFFD43D4D);
      case 'Declined':
        return Color(0XFFD43D4D);
      default:
        return Color(0XFF4A4A68);
    }
  }
}
