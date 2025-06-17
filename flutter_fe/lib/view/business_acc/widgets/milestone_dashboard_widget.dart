import 'package:flutter/material.dart';
import 'package:flutter_fe/model/milestone_model.dart';
import 'package:flutter_fe/service/milestone_service_mock.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MilestoneDashboardWidget extends StatefulWidget {
  final int taskId;
  final double taskAmount;
  final VoidCallback? onTap;

  const MilestoneDashboardWidget({
    super.key,
    required this.taskId,
    required this.taskAmount,
    this.onTap,
  });

  @override
  State<MilestoneDashboardWidget> createState() =>
      _MilestoneDashboardWidgetState();
}

class _MilestoneDashboardWidgetState extends State<MilestoneDashboardWidget> {
  // Use mock service for testing - replace with MilestoneService() when backend is ready
  final MilestoneServiceMock _milestoneService = MilestoneServiceMock();
  List<MilestoneModel> _milestones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    try {
      final milestones =
          await _milestoneService.getTaskMilestones(widget.taskId);
      setState(() {
        _milestones = milestones..sort((a, b) => a.order.compareTo(b.order));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    if (_isLoading) {
      return Container(
        height: isSmallScreen ? 60 : 80,
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Center(
          child: SizedBox(
            width: isSmallScreen ? 16 : 20,
            height: isSmallScreen ? 16 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE23670)),
            ),
          ),
        ),
      );
    }

    if (_milestones.isEmpty) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.timeline,
                  color: Colors.grey[400], size: isSmallScreen ? 20 : 24),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Milestones',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'No milestones defined - Tap to add',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: isSmallScreen ? 14 : 16, color: Colors.grey[400]),
            ],
          ),
        ),
      );
    }

    final completedCount = _milestones.where((m) => m.isCompleted).length;
    final totalCount = _milestones.length;
    final progressPercentage = (completedCount / totalCount * 100).round();
    final completedAmount = _milestones
        .where((m) => m.isCompleted)
        .fold(0.0, (sum, m) => sum + (m.amount ?? 0.0));
    final totalAmount =
        _milestones.fold(0.0, (sum, m) => sum + (m.amount ?? 0.0));
    final overdueCount = _milestones.where((m) => m.isOverdue).length;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(Icons.timeline,
                          color: Color(0xFFE23670),
                          size: isSmallScreen ? 16 : 20),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Flexible(
                        child: Text(
                          'Milestones',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overdueCount > 0) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 4 : 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$overdueCount overdue',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 8 : 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                      ],
                      Text(
                        '$completedCount/$totalCount',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE23670),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: isSmallScreen ? 12 : 16,
                          color: Colors.grey[400]),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 6 : 8),

            // Progress bar
            LinearProgressIndicator(
              value: completedCount / totalCount,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE23670)),
              minHeight: isSmallScreen ? 3 : 4,
            ),

            SizedBox(height: isSmallScreen ? 6 : 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '$progressPercentage% Complete',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 9 : 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '₱${NumberFormat("#,##0.00").format(completedAmount)} / ₱${NumberFormat("#,##0.00").format(totalAmount)}',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 9 : 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
