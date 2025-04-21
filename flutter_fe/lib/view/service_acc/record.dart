import 'package:flutter/material.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_coinfirmed.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_finish.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_ongoing.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_reject.dart';

import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controller/escrow_management_controller.dart';
import 'package:intl/intl.dart';

class RecordTaskerPage extends StatefulWidget {
  const RecordTaskerPage({super.key});

  @override
  State<RecordTaskerPage> createState() => _RecordTaskerPageState();
}

class _RecordTaskerPageState extends State<RecordTaskerPage> {
  final storage = GetStorage();
  final _escrowManagementController = EscrowManagementController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  Future<void> _loadData() async {
    await _escrowManagementController.fetchTokenBalance();
    setState(() => _isLoading = false);
  }
  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return format.format(amount);
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
                    width: double.infinity,
                    child: Column(
                      children: [
                        //UI Must be improved.
                        _isLoading ? Text(
                          'Please Wait while we calculate your NearByTask Credits',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow.shade800
                          ),
                          textAlign: TextAlign.center,
                        ) :
                        _escrowManagementController.tokenCredits.value == 0.0 ?
                        Text(
                          "You don't have any NearByTask Credits to your account. Earn More by taking more tasks.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0XFFB62C5C)
                          )
                        ) :
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'You Had Earned: ',
                                style: TextStyle(
                                  fontSize: 16,
                                )
                              ),
                              TextSpan(
                                text: '${formatCurrency(_escrowManagementController.tokenCredits.value.toDouble())} to your Existing Wallet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade800
                                )
                              )
                            ]
                          )
                        )
                      ],
                    ),
                  ),
                ))
              ],
            ),
          )),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: SizedBox(
              height: 250,
              child: ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                              builder: (context) => DisplayListRecordOngoing(),
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
                            color: Colors.orange.withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ongoing Task',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Optionally, add more details like a count or icon
                              Icon(
                                Icons.task,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                            color: Colors.blue.withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Confirmed Task',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Optionally, add more details like a count or icon
                              Icon(
                                Icons.task,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                            color: Colors.green.withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Completed Task',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Optionally, add more details like a count or icon
                              Icon(
                                Icons.task,
                                color: Colors.green,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                            color: Colors.red.withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Rejected Task',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Optionally, add more details like a count or icon
                              Icon(
                                Icons.task,
                                color: Colors.red,
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
        ],
      ),
    );
  }
}
