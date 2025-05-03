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
import 'package:flutter_fe/widgets/expense_chart.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

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

  // Monthly expense data
  List<double> monthlyExpenses = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _generateMonthlyExpenses();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _generateMonthlyExpenses() {
    monthlyExpenses =
        List.generate(12, (index) => 200 + random.nextDouble() * 800);
    setState(() {});
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
              'Record',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: Color(0xFF0272B1),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ),
        body: Column(children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'You Currently Have:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Calculating NearByTask credits...",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow.shade800),
                      ),
                    ),
                  ),
                )
              : _escrowManagementController.tokenCredits.value == 0
                  ? Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              "You don't have any NearByTask Credits to your account. Add more by depositing the amount in order to use the system.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0XFFB62C5C))),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(TextSpan(children: [
                            TextSpan(
                                style: GoogleFonts.openSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0272B1)),
                                text:
                                    '${_escrowManagementController.tokenCredits.value} NearByTask Credits'),
                          ])),
                        ),
                      ),
                    ),
          Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.only(left: 16.0, right: 16),
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
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Expenses',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Color(0xFF0272B1),
                              ),
                            ),
                            Text(
                              'Expense overview for the year',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: monthlyExpenses.isEmpty
                                  ? Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF0272B1)))
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 8.0, top: 20),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              1.5,
                                          height: 270,
                                          child: MonthlyExpensesChart(
                                            monthlyData: monthlyExpenses,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ))
                  ],
                ),
              )),
          //Client Task Progress
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
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
                              builder: (context) => DisplayListRecordPending(),
                            ),
                          ).then((value) {
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                        hoverColor: Colors.yellow.withOpacity(0.1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DisplayListRecordOngoing(),
                            ),
                          ).then((value) {
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                        borderRadius: BorderRadius.circular(20),
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
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                        hoverColor: Colors.blue.withOpacity(0.1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DisplayListRecordFinish()),
                          ).then((value) {
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: Colors.blue.withOpacity(0.1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DisplayListRecordDisputed()),
                          ).then((value) {
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                                'Disputed Task',
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
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: Colors.blue.withOpacity(0.1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DisplayListRecordDisputedSettled()),
                          ).then((value) {
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                                'Disputed Task Settled',
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
                    padding: const EdgeInsets.only(right: 0.0),
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
                                    DisplayListRecordCancel()),
                          ).then((value) {
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
                                'Cancelled Task',
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
                  Padding(
                    padding: const EdgeInsets.only(right: 0.0),
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
                            // setState(() {
                            //   _isLoading = true;
                            // });
                            _loadData();
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
        ]));
  }
}
