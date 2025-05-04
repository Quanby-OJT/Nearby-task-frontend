import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyExpensesChart extends StatelessWidget {
  final List<double> monthlyData;

  MonthlyExpensesChart({Key? key, required this.monthlyData})
      : assert(monthlyData.length == 12, 'Must provide 12 months of data'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Taking up available space
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return BarChart(
            BarChartData(
              // Allow more space for the chart content
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: 1000,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 300,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              // Add extra top margin
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 1000,
                    color: Colors.transparent,
                  ),
                ],
              ),
              // Adjust the chart padding to allow more space
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      List<String> months = [
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'May',
                        'Jun',
                        'Jul',
                        'Aug',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Dec'
                      ];
                      final int index = value.toInt();
                      if (index >= 0 &&
                          index < months.length &&
                          index % 2 == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            months[index],
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Show values at intervals
                      if (value % 200 == 0) {
                        return Text(
                          '₱${value.toInt()}',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize:
                        30, // Reserve space for top titles even if not shown
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom:
                      BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                  left:
                      BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                ),
              ),
              barGroups: List.generate(
                monthlyData.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: monthlyData[index],
                      color: Color(0xFF0272B1),
                      width: 12,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 1000,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
              // Increase touch area for better interaction while scrolling
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Color(0xFF0272B1).withOpacity(0.8),
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tooltipMargin: 4, // Add margin for better visibility
                  tooltipRoundedRadius: 8,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 180,
                  tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                  tooltipHorizontalOffset: 0,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthIndex = group.x;
                    final String month = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec'
                    ][monthIndex];
                    return BarTooltipItem(
                      '$month: ₱${rod.toY.toStringAsFixed(1)}',
                      GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                mouseCursorResolver: (event, response) {
                  return response == null || !event.isInterestedForInteractions
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click;
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
