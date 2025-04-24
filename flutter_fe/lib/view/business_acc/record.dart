import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_coinfirmed.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_finish.dart';
import 'package:flutter_fe/view/business_acc/client_record/display_list_ongoing.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this import for the chart

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
  bool isLoading = true;

  bool _isLoading = true;

  // Sample data for the monthly expenses chart
  final List<Map<String, dynamic>> monthlyExpenses = [
    {'month': 'Jan', 'amount': 300.0},
    {'month': 'Feb', 'amount': 450.0},
    {'month': 'Mar', 'amount': 320.0},
    {'month': 'Apr', 'amount': 280.0},
    {'month': 'May', 'amount': 500.0},
    {'month': 'Jun', 'amount': 350.0},
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
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
                  'NearByTask Credits',
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
                                    '₱${_escrowManagementController.tokenCredits.value} credits'),
                          ])),
                        ),
                      ),
                    ),
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
                        borderRadius: BorderRadius.circular(20),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0272B1),
                              ),
                            ),
                            SizedBox(height: 12),
                            Expanded(
                              child: _buildMonthlyExpensesChart(),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Total: ₱${_calculateTotalExpenses()}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? Text(
                                "Please Wait while we calculate your NearByTask Credits",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow.shade800),
                              )
                            : _escrowManagementController.tokenCredits.value ==
                                    0
                                ? Text(
                                    "You don't have any NearByTask Credits to your account. Add more by depositing the amount in order to use the system.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0XFFB62C5C)))
                                : Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: "You Have: ",
                                        style:
                                            GoogleFonts.roboto(fontSize: 18)),
                                    TextSpan(
                                        style: GoogleFonts.openSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                        text:
                                            '${_escrowManagementController.tokenCredits.value} NearByTask Credits'),
                                  ]))
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
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      hoverColor: Colors.yellow.withOpacity(0.1),
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
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.orange.shade300,
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
                              Icons.handyman,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
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
                                'Confirmed Task',
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
                        hoverColor: Colors.blue.withOpacity(0.1),
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
                            color: Colors.blue.withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Completed Task',
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
                        hoverColor: Colors.red.withOpacity(0.1),
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
        ]));
  }

  // Method to build the monthly expenses chart
  Widget _buildMonthlyExpensesChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxAmount() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₱${rod.toY.round()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= monthlyExpenses.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    monthlyExpenses[value.toInt()]['month'],
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    '₱${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: _getBarGroups(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  // Helper method to get the bar groups for the chart
  List<BarChartGroupData> _getBarGroups() {
    return List.generate(monthlyExpenses.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monthlyExpenses[index]['amount'],
            color: Color(0xFF0272B1).withOpacity(0.8),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  // Helper method to get the maximum amount for the Y axis
  double _getMaxAmount() {
    double max = 0;
    for (var expense in monthlyExpenses) {
      if (expense['amount'] > max) {
        max = expense['amount'];
      }
    }
    return max;
  }

  // Helper method to calculate total expenses
  String _calculateTotalExpenses() {
    double total = 0;
    for (var expense in monthlyExpenses) {
      total += expense['amount'];
    }
    return total.toStringAsFixed(2);
  }
}
