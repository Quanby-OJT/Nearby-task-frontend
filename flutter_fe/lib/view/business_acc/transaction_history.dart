import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/transactions.dart';
import 'package:flutter_fe/view/task/task_details_screen.dart';
import 'package:flutter_fe/view/profile/payment_processing.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with TickerProviderStateMixin {
  final storage = GetStorage();
  final EscrowManagementController _escrowManagementController =
      EscrowManagementController();
  final TaskController taskController = TaskController();
  bool _isLoading = false;
  // Sample data for the ListView.builder
  List<Transactions> _transactionHistory = [];
  late AnimationController loadingController;


  // Sample financial data
  double totalBalance = 4500.00;
  double income = 10500.00;
  double expense = 6000.00;

  @override
  void initState() {
    super.initState();
    loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  @override
  void dispose() {
    loadingController.dispose();
    super.dispose();
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
            style: GoogleFonts.poppins(
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
              height: 150, // Fixed taller height
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Card(
                elevation: 4,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color(0xFFB71A4A), // Purple background color
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      _isLoading
                          ? Text(
                              '0.00',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : _escrowManagementController.tokenCredits.value ==
                                  0.0
                              ? Text(
                                  "₱ 0.00",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  '₱${_escrowManagementController.tokenCredits.value.toStringAsFixed(2)}',
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
                  // Income Card changed to Deposit Card
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Show deposit dialog
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return PaymentProcessingPage(
                                transferMethod: "deposit",
                              );
                            },
                          ));
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
                                    backgroundColor: Colors.green[50],
                                    child: Icon(
                                      Icons.arrow_downward,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Deposit',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to deposit',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[400],
                                ),
                              ),
                            ],
                          ),
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
                                      transferMethod: "withdraw")));
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0XFFE23670)
                    ),
                  ),
                  SizedBox(height: 10),
                  _isLoading
                    ? Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Add a SizedBox for spacing (20% of card width for example)
                              SizedBox(width: MediaQuery.of(context).size.width * 0.1), // Adjust the percentage as needed
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFE23670)),
                                      backgroundColor: Color(0XFFF5A1BB),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFE23670)),
                                      backgroundColor: Color(0XFFF5A1BB),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFE23670)),
                                      backgroundColor: Color(0XFFF5A1BB),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0XFFE23670)),
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
                        ? Text("You don't have any transactions Yet")
                        : ListView.builder(
                            shrinkWrap: true, // Important to make ListView scrollable within Column
                            physics: NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
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
                                      builder: (context) => TaskDetailsScreen(
                                        taskAssignment: transaction.taskAssignment,
                                        taskStatus: transaction.recordStatus,
                                        transactionDate: DateTime.parse(transaction.date),
                                      )
                                    )
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: statusColor(transaction.recordStatus),
                                    radius: 5, // Small color indicator
                                  ),
                                  title: Text(
                                    transaction.taskAssignment.task?.title ?? "N/A",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tasker: ${transaction.taskAssignment.tasker?.user?.firstName ?? ''} ${transaction.taskAssignment.tasker?.user?.middleName ?? ''} ${transaction.taskAssignment.tasker?.user?.lastName ?? ''}',
                                        style: GoogleFonts.poppins(fontSize: 12),
                                      ),
                                      Text(
                                        'Status: ${transaction.recordStatus}',
                                        style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    DateFormat('yyyy-MM-dd HH:mm a').format(DateTime.parse(transaction.date)), // Display formatted date and time
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey[600]
                                        ),
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
