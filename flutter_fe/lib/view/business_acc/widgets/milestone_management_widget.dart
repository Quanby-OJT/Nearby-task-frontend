import 'package:flutter/material.dart';
import 'package:flutter_fe/model/milestone_model.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/milestone_service.dart';
import 'package:flutter_fe/service/milestone_service_mock.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MilestoneManagementWidget extends StatefulWidget {
  final TaskModel task;
  final VoidCallback? onMilestonesChanged;

  const MilestoneManagementWidget({
    super.key,
    required this.task,
    this.onMilestonesChanged,
  });

  @override
  State<MilestoneManagementWidget> createState() =>
      _MilestoneManagementWidgetState();
}

class _MilestoneManagementWidgetState extends State<MilestoneManagementWidget> {
  // Use mock service for testing - replace with MilestoneService() when backend is ready
  final MilestoneServiceMock _milestoneService = MilestoneServiceMock();
  List<MilestoneModel> _milestones = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final milestones =
          await _milestoneService.getTaskMilestones(widget.task.id);
      setState(() {
        _milestones = milestones..sort((a, b) => a.order.compareTo(b.order));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load milestones');
    }
  }

  void _showErrorSnackBar(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showAddMilestoneDialog() async {
    final result = await showDialog<MilestoneModel>(
      context: context,
      builder: (context) => _MilestoneDialog(
        taskId: widget.task.id,
        totalTaskAmount: widget.task.contactPrice.toDouble(),
        usedAmount: _milestones.fold(
            0.0, (sum, milestone) => sum + (milestone.amount ?? 0.0)),
        nextOrder: _milestones.length + 1,
      ),
    );

    if (result != null) {
      setState(() {
        _isAdding = true;
      });

      final response = await _milestoneService.createMilestone(result);

      setState(() {
        _isAdding = false;
      });

      if (response['success']) {
        _showSuccessSnackBar('Milestone added successfully');
        _loadMilestones();
        widget.onMilestonesChanged?.call();
      } else {
        _showErrorSnackBar(response['error'] ?? 'Failed to add milestone');
      }
    }
  }

  Future<void> _showEditMilestoneDialog(MilestoneModel milestone) async {
    final result = await showDialog<MilestoneModel>(
      context: context,
      builder: (context) => _MilestoneDialog(
        taskId: widget.task.id,
        milestone: milestone,
        totalTaskAmount: widget.task.contactPrice.toDouble(),
        usedAmount: _milestones
            .where((m) => m.id != milestone.id)
            .fold(0.0, (sum, m) => sum + (m.amount ?? 0.0)),
      ),
    );

    if (result != null) {
      final response = await _milestoneService.updateMilestone(result);

      if (response['success']) {
        _showSuccessSnackBar('Milestone updated successfully');
        _loadMilestones();
        widget.onMilestonesChanged?.call();
      } else {
        _showErrorSnackBar(response['error'] ?? 'Failed to update milestone');
      }
    }
  }

  Future<void> _deleteMilestone(MilestoneModel milestone) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Milestone',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB71A4A),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${milestone.title}"?',
          style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                color: const Color(0xFFB71A4A),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23670),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _milestoneService.deleteMilestone(milestone.id!);

      if (response['success']) {
        _showSuccessSnackBar('Milestone deleted successfully');
        _loadMilestones();
        widget.onMilestonesChanged?.call();
      } else {
        _showErrorSnackBar(response['error'] ?? 'Failed to delete milestone');
      }
    }
  }

  Future<void> _updateMilestoneStatus(
      MilestoneModel milestone, String newStatus) async {
    final response =
        await _milestoneService.updateMilestoneStatus(milestone.id!, newStatus);

    if (response['success']) {
      _showSuccessSnackBar('Milestone status updated');
      _loadMilestones();
      widget.onMilestonesChanged?.call();
    } else {
      _showErrorSnackBar(
          response['error'] ?? 'Failed to update milestone status');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Task Milestones',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE23670),
                    ),
                  ),
                ),
                if (_milestones.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFE23670).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(_milestones.where((m) => m.isCompleted).length / _milestones.length * 100).round()}% Complete',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE23670),
                      ),
                    ),
                  ),
              ],
            ),
            if (_milestones.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 8 : 12),
              LinearProgressIndicator(
                value: (_milestones.where((m) => m.isCompleted).length /
                    _milestones.length),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE23670)),
                minHeight: isSmallScreen ? 4 : 6,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                '₱${NumberFormat("#,##0.00").format(_milestones.where((m) => m.isCompleted).fold(0.0, (sum, m) => sum + (m.amount ?? 0.0)))} of ₱${NumberFormat("#,##0.00").format(_milestones.fold(0.0, (sum, m) => sum + (m.amount ?? 0.0)))} completed',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: isSmallScreen ? 12 : 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAdding ? null : _showAddMilestoneDialog,
                icon: _isAdding
                    ? SizedBox(
                        width: isSmallScreen ? 14 : 16,
                        height: isSmallScreen ? 14 : 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.add,
                        color: Colors.white, size: isSmallScreen ? 18 : 20),
                label: Text(
                  _isAdding ? 'Adding...' : 'Add Milestone',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE23670),
                  padding:
                      EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE23670)),
                  ),
                ),
              )
            else if (_milestones.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline,
                        size: isSmallScreen ? 36 : 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(
                        'No milestones defined',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Break down your task into smaller milestones to track progress',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      ElevatedButton(
                        onPressed: () async {
                          await _milestoneService.seedSampleData(
                            widget.task.id,
                            widget.task.contactPrice.toDouble(),
                          );
                          _loadMilestones();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 6 : 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Add Sample Data',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _milestones
                    .map((milestone) => _buildMilestoneCard(milestone))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(MilestoneModel milestone) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isOverdue = milestone.isOverdue;
    final statusColor = _getStatusColor(milestone.status);

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(milestone.status),
                  color: statusColor,
                  size: isSmallScreen ? 16 : 20,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.title,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (milestone.dueDate != null)
                        Text(
                          'Due: ${DateFormat('MMM d, yyyy').format(milestone.dueDate!)}',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 9 : 11,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                            fontWeight:
                                isOverdue ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 2 : 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    milestone.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: isSmallScreen ? 14 : 16),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditMilestoneDialog(milestone);
                        break;
                      case 'delete':
                        _deleteMilestone(milestone);
                        break;
                      case 'mark_progress':
                        _updateMilestoneStatus(milestone, 'in_progress');
                        break;
                      case 'mark_complete':
                        _updateMilestoneStatus(milestone, 'completed');
                        break;
                      case 'mark_pending':
                        _updateMilestoneStatus(milestone, 'pending');
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: isSmallScreen ? 14 : 16),
                          SizedBox(width: 8),
                          Text('Edit',
                              style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 10 : 12)),
                        ],
                      ),
                    ),
                    if (milestone.status != 'in_progress')
                      PopupMenuItem(
                        value: 'mark_progress',
                        child: Row(
                          children: [
                            Icon(Icons.play_circle,
                                size: isSmallScreen ? 14 : 16),
                            SizedBox(width: 8),
                            Text('Mark In Progress',
                                style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 10 : 12)),
                          ],
                        ),
                      ),
                    if (milestone.status != 'completed')
                      PopupMenuItem(
                        value: 'mark_complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: isSmallScreen ? 14 : 16),
                            SizedBox(width: 8),
                            Text('Mark Complete',
                                style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 10 : 12)),
                          ],
                        ),
                      ),
                    if (milestone.status != 'pending')
                      PopupMenuItem(
                        value: 'mark_pending',
                        child: Row(
                          children: [
                            Icon(Icons.pending, size: isSmallScreen ? 14 : 16),
                            SizedBox(width: 8),
                            Text('Mark Pending',
                                style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 10 : 12)),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              size: isSmallScreen ? 14 : 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (milestone.description.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                milestone.description,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: isSmallScreen ? 6 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    milestone.amount != null
                        ? 'Amount: ₱${NumberFormat("#,##0.00").format(milestone.amount!)}'
                        : 'Amount: Not specified',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE23670),
                    ),
                  ),
                ),
                if (milestone.completedAt != null)
                  Text(
                    'Completed: ${DateFormat('MMM d, yyyy').format(milestone.completedAt!)}',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 8 : 10,
                      color: Colors.green[600],
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

class _MilestoneDialog extends StatefulWidget {
  final int taskId;
  final MilestoneModel? milestone;
  final double totalTaskAmount;
  final double usedAmount;
  final int? nextOrder;

  const _MilestoneDialog({
    required this.taskId,
    this.milestone,
    required this.totalTaskAmount,
    required this.usedAmount,
    this.nextOrder,
  });

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDueDate;
  String _selectedStatus = 'pending';

  final List<String> _statusOptions = ['pending', 'in_progress', 'completed'];

  @override
  void initState() {
    super.initState();
    if (widget.milestone != null) {
      _titleController.text = widget.milestone!.title;
      _descriptionController.text = widget.milestone!.description;
      _amountController.text = widget.milestone!.amount.toString();
      _selectedDueDate = widget.milestone!.dueDate;
      _selectedStatus = widget.milestone!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFE23670),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final milestone = MilestoneModel(
        id: widget.milestone?.id,
        taskId: widget.taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: _amountController.text.trim().isNotEmpty
            ? double.parse(_amountController.text.trim())
            : null,
        dueDate: _selectedDueDate,
        status: _selectedStatus,
        order: widget.milestone?.order ?? widget.nextOrder ?? 1,
        createdAt: widget.milestone?.createdAt,
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, milestone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isEditing = widget.milestone != null;
    final remainingAmount = widget.totalTaskAmount - widget.usedAmount;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Edit Milestone' : 'Add Milestone',
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 16 : 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE23670),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle:
                      GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE23670)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle:
                      GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE23670)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (₱) - Optional',
                  labelStyle:
                      GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE23670)),
                  ),
                  helperText:
                      'Available: ₱${NumberFormat("#,##0.00").format(remainingAmount)}',
                  helperStyle: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 9 : 11,
                      color: Colors.grey[600]),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (amount > remainingAmount) {
                      return 'Amount exceeds remaining budget';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDueDate != null
                              ? 'Due: ${DateFormat('MMM d, yyyy').format(_selectedDueDate!)}'
                              : 'Select due date (optional)',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: _selectedDueDate != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (_selectedDueDate != null)
                        InkWell(
                          onTap: () => setState(() => _selectedDueDate = null),
                          child: Icon(Icons.clear,
                              size: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ),
              if (isEditing) ...[
                SizedBox(height: isSmallScreen ? 12 : 16),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle:
                        GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFE23670)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14, color: Colors.black87),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE23670),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 8 : 12,
            ),
          ),
          child: Text(
            isEditing ? 'Update' : 'Add',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
