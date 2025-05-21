import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_cancel.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_coinfirmed.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_disputed.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_disputed_settled.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_finish.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_ongoing.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_pending.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_review.dart';
import 'package:flutter_fe/view/profile/payment_processing.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'client_record/display_list_reject.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final storage = GetStorage();
  final EscrowManagementController _escrowManagementController =
      EscrowManagementController();
  final ProfileController _profileController = ProfileController();
  AuthenticatedUser? _user;
  bool _isLoading = true;

  // Sample financial data
  double totalBalance = 4500.00;
  double income = 10500.00;
  double expense = 6000.00;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true); // Set loading to true before fetching
    await _escrowManagementController.fetchTokenBalance();
    setState(() => _isLoading = false);
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      _isLoading
                          ? Text(
                              'Please Wait while we calculate your Current Amount in QTask',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade100),
                              textAlign: TextAlign.left,
                            )
                          : _escrowManagementController.tokenCredits.value ==
                                  0.0
                              ? Text(
                                  "You haven't made a deposit. To Create tasks, you must deposit first.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  '₱${_escrowManagementController.tokenCredits.value.toStringAsFixed(2)}',
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
                              return PaymentProcessingPage(transferMethod: "deposit",);
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
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => PaymentProcessingPage(transferMethod: "withdraw")
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
                    title: 'Pending',
                    color: Color(0xFFFFC107),
                    icon: Icons.pending,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordPending(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Review Task Card
                  _buildStatusCard(
                    title: 'Review',
                    color: Colors.orangeAccent,
                    icon: Icons.reviews,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordReview(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Ongoing Task Card
                  _buildStatusCard(
                    title: 'Ongoing',
                    color: Colors.indigo.shade300,
                    icon: Icons.work,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordOngoing(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Confirmed Task Card
                  _buildStatusCard(
                    title: 'Confirmed',
                    color: Colors.green.shade300,
                    icon: Icons.handshake,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordConfirmed(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Completed Task Card
                  _buildStatusCard(
                    title: 'Completed',
                    color: Colors.blue.shade300,
                    icon: Icons.check,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordFinish(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Disputed Task Card
                  _buildStatusCard(
                    title: 'Disputed',
                    color: Colors.purple.shade300,
                    icon: Icons.gavel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordDisputed(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Disputed Settled Task Card
                  _buildStatusCard(
                    title: 'Resolved Task Disputes',
                    color: Colors.teal.shade300,
                    icon: Icons.check_circle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DisplayListRecordDisputedSettled(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Cancelled Task Card
                  _buildStatusCard(
                    title: 'Cancelled',
                    color: Colors.red.shade300,
                    icon: Icons.cancel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordCancel(),
                        ),
                      ).then((value) => _loadData());
                    },
                  ),

                  // Rejected Task Card
                  _buildStatusCard(
                    title: 'Rejected',
                    color: Colors.red.shade700,
                    icon: Icons.cancel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayListRecordReject(),
                        ),
                      ).then((value) => _loadData());
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
        // Light gray background
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
                    style: GoogleFonts.poppins(
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

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Withdraw Credits',
          style: GoogleFonts.poppins(
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

                  if (amount > totalBalance) {
                    return 'Amount exceeds available balance';
                  }

                  return null;
                },
              ),
              SizedBox(height: 16),
              Text(
                'Withdrawal will be processed to your linked payment method.',
                style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(color: Colors.grey[600]),
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
              style: GoogleFonts.poppins(color: Colors.white),
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
      totalBalance -= amount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Withdrawal of \$${amount.toStringAsFixed(2)} has been initiated'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showDepositDialog() {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Deposit Credits',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71A4A),
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
                      Icon(Icons.attach_money, color: Color(0xFFB71A4A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFB71A4A), width: 2),
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

                  return null;
                },
              ),
              SizedBox(height: 16),
              Text(
                'Deposit will be processed from your linked payment method.',
                style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final double amount = double.parse(amountController.text);

                // Process deposit
                _processDeposit(amount);

                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFB71A4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Deposit',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _processDeposit(double amount) {
    // Here you would call the API to process the deposit
    // For now we'll just show a success message and update the UI
    setState(() {
      // Update UI or call API here
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Deposit of \$${amount.toStringAsFixed(2)} has been initiated'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
