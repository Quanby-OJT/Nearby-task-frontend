import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/task/task_cancelled.dart';
import 'package:flutter_fe/view/task/task_confirmed.dart';
import 'package:flutter_fe/view/task/task_finished.dart';
import 'package:flutter_fe/view/task/task_ongoing.dart';
import 'package:flutter_fe/view/task/task_pending.dart';
import 'package:flutter_fe/view/task/task_review.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_fe/view/business_acc/edit_task_page.dart';

class BusinessTaskDetail extends StatefulWidget {
  final TaskModel? task;
  final String? role;

  const BusinessTaskDetail({
    super.key,
    this.task,
    this.role,
  });

  @override
  State<BusinessTaskDetail> createState() => _BusinessTaskDetailState();
}

class _BusinessTaskDetailState extends State<BusinessTaskDetail> {
  final JobPostService _jobPostService = JobPostService();
  final TaskController _taskController = TaskController();
  TaskModel? _taskInformation;
  bool _isLoading = true;
  bool _isDeleting = false;
  final storage = GetStorage();

  @override
  void initState() {
    super.initState();

    // If task was passed, use it immediately
    if (widget.task != null) {
      _taskInformation = widget.task;
      _isLoading = false;
    } else {
      _fetchTaskDetails();
    }
  }

  Future<void> _fetchTaskDetails() async {
    try {
      final response =
          await _jobPostService.fetchTaskInformation(widget.task!.id);
      setState(() {
        _taskInformation = response?.task;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching task details: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load task details: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text(
            'Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final result = await _taskController.deleteTask(widget.task!.id);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task deleted successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to delete task: ${result['error'] ?? "Unknown error"}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    TaskModel? taskToDisplay = widget.task ?? _taskInformation;

    String priceDisplay = "N/A";
    if (taskToDisplay?.contactPrice != null) {
      try {
        priceDisplay = NumberFormat("#,##0.00", "en_US")
            .format(taskToDisplay!.contactPrice.roundToDouble());
      } catch (e) {
        priceDisplay = taskToDisplay!.contactPrice.toString();
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Task Details',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        iconTheme: IconThemeData(color: Color(0xFFB71A4A)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: taskToDisplay == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskPage(task: widget.task!),
                      ),
                    );
                    if (result == true) {
                      // Task was updated, refresh the page
                      Navigator.pop(context, true);
                    }
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskToDisplay == null
              ? const Center(child: Text('No task information available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              taskToDisplay.title ?? "Untitled Task",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE23670),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Divider(height: 30),
                          _buildInfoRow("Specialization",
                              taskToDisplay.specialization ?? "N/A"),
                          _buildInfoRow("Description",
                              taskToDisplay.description ?? "N/A"),
                          _buildInfoRow("Contract Price", "₱ $priceDisplay"),
                          _buildInfoRow(
                              "Urgency", taskToDisplay.urgency ?? "N/A"),
                          _buildInfoRow(
                              "Work Type", taskToDisplay.workType ?? "N/A"),
                          _buildInfoRow(
                              "Status", taskToDisplay.status ?? "Active"),
                          _buildInfoRow(
                              "Remarks", taskToDisplay.remarks ?? "N/A"),
                          const SizedBox(height: 20),
                          Text(
                            "Tasker Applicants",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE23670),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          taskToDisplay.taskTaken == null ||
                                  taskToDisplay.taskTaken!.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    "No taskers have applied to this task.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: taskToDisplay.taskTaken!.length,
                                  itemBuilder: (context, index) {
                                    final taskFetch =
                                        taskToDisplay.taskTaken![index];

                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      color: Colors.white,
                                      margin: EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          if (taskFetch.taskStatus ==
                                              "Completed") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskFinished(
                                                        taskInformation:
                                                            taskFetch),
                                              ),
                                            );
                                          }

                                          if (taskFetch.taskStatus ==
                                              "Pending") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskPending(
                                                  taskInformation: taskFetch,
                                                ),
                                              ),
                                            ).then((value) {
                                              if (value != null) {
                                                _fetchTaskDetails();
                                              }
                                            });
                                          }

                                          if (taskFetch.taskStatus ==
                                              "Cancelled") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskCancelled(
                                                  taskInformation: taskFetch,
                                                ),
                                              ),
                                            ).then((value) {
                                              if (value != null) {
                                                _fetchTaskDetails();
                                              }
                                            });
                                          }

                                          if (taskFetch.taskStatus ==
                                              "Confirmed") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskConfirmed(
                                                        taskInformation:
                                                            taskFetch),
                                              ),
                                            ).then((value) {
                                              if (value != null) {
                                                _fetchTaskDetails();
                                              }
                                            });
                                          }

                                          if (taskFetch.taskStatus ==
                                              "Ongoing") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskOngoing(
                                                        taskInformation:
                                                            taskFetch,
                                                        role: widget.role),
                                              ),
                                            ).then((value) {
                                              if (value != null) {
                                                _fetchTaskDetails();
                                              }
                                            });
                                          }

                                          if (taskFetch.taskStatus ==
                                              "Review") {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskReview(
                                                  taskInformation: taskFetch,
                                                ),
                                              ),
                                            ).then((value) {
                                              if (value != null) {
                                                _fetchTaskDetails();
                                              }
                                            });
                                          }
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _buildTaskRecieved(taskFetch),
                                                  _buildTaskStatusColor(
                                                      taskFetch),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildTaskTaskInfo(taskFetch),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          const SizedBox(
                            height: 16,
                          ),
                          Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _isDeleting ? null : _deleteTask();
                                },
                                icon: Icon(Icons.delete, color: Colors.white),
                                label: Text(
                                  _isDeleting ? "Deleting..." : "Delete Task",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFB71A4A),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildTaskTaskInfo(TaskFetch taskFetch, {double size = 40.0}) {
    final String? imageUrl = taskFetch.tasker?.user?.imageName;
    final bool hasValidImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl != "Unknown";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: hasValidImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 24,
                  ),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskFetch.taskDetails.title != null
                  ? taskFetch.taskDetails.title.length > 25
                      ? '${taskFetch.taskDetails.title.substring(0, 25)}...'
                      : taskFetch.taskDetails.title
                  : 'Untitled Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "${taskFetch.tasker?.user?.firstName ?? 'Unknown'} ${taskFetch.tasker?.user?.lastName ?? 'Unknown'}",
              style:
                  GoogleFonts.poppins(color: Color(0xFFB71A4A), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskRecieved(TaskFetch taskFetch) {
    DateTime createdDateTime = DateTime.parse(taskFetch.createdAt.toString());

    String formattedDate = DateFormat('MMM d, yyyy').format(createdDateTime);

    DateTime now = DateTime.now().toUtc();
    Duration difference = now.difference(createdDateTime);

    String timeAgo;
    if (difference.inMinutes < 60) {
      int minutesAgo = difference.inMinutes;
      timeAgo = '$minutesAgo ${minutesAgo == 1 ? 'min' : 'mins'} ago';
    } else {
      int hoursAgo = difference.inHours;
      timeAgo = '$hoursAgo ${hoursAgo == 1 ? 'hour' : 'hours'} ago';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formattedDate, style: const TextStyle(fontSize: 14)),
        Text(
          timeAgo,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTaskStatusColor(TaskFetch taskFetch) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: taskFetch.taskStatus == 'Pending'
                ? Colors.grey[500]
                : taskFetch.taskStatus == 'Completed'
                    ? Colors.green
                    : taskFetch.taskStatus == 'Confirmed'
                        ? Colors.green
                        : taskFetch.taskStatus == 'Dispute Settled'
                            ? Colors.green
                            : taskFetch.taskStatus == 'Ongoing'
                                ? Colors.blue
                                : taskFetch.taskStatus == 'Interested'
                                    ? Colors.blue
                                    : taskFetch.taskStatus == 'Review'
                                        ? Colors.yellow
                                        : taskFetch.taskStatus == 'Disputed'
                                            ? Colors.orange
                                            : taskFetch.taskStatus == 'Rejected'
                                                ? Colors.red
                                                : taskFetch.taskStatus ==
                                                        'Declined'
                                                    ? Colors.red
                                                    : taskFetch.taskStatus ==
                                                            'Cancelled'
                                                        ? Colors.red
                                                        : Colors.red,
          ),
          child: Text(
            taskFetch.taskStatus,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8),
        Divider(height: 1),
      ],
    ),
  );
}
