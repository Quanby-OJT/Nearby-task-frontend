import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_fetch.dart';
import 'package:flutter_fe/view/task/task_cancelled.dart';
import 'package:flutter_fe/view/task/task_declined.dart';
import 'package:flutter_fe/view/task/task_finished.dart';
import 'package:flutter_fe/view/task/task_rejected.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TaskArchivePage extends StatefulWidget {
  final String? role;
  const TaskArchivePage({super.key, this.role});

  @override
  State<TaskArchivePage> createState() => _TaskArchivePageState();
}

class _TaskArchivePageState extends State<TaskArchivePage> {
  final TaskController controller = TaskController();
  List<TaskFetch> archivedTasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.role == 'Client') {
      _fetchArchivedTasksClient();
    } else {
      _fetchArchivedTasks();
    }
  }

  Future<void> _fetchArchivedTasksClient() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final tasks = await controller.getTaskClient(context);
      debugPrint("Fetched tasks for client: ${tasks.toString()}");
      setState(() {
        archivedTasks = tasks
            .where((task) =>
                task != null &&
                task.taskStatus != null &&
                ['Completed', 'Cancelled', 'Rejected', 'Declined', 'Archived']
                    .contains(task.taskStatus))
            .cast<TaskFetch>()
            .toList();
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching archived tasks: $e");
      debugPrintStack(stackTrace: stackTrace);
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load archived tasks. Please try again.";
      });
    }
  }

  Future<void> _fetchArchivedTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final tasks = await controller.getTask(context);
      debugPrint("Archived tasks: ${tasks.toString()}");
      setState(() {
        archivedTasks = tasks
            .where((task) =>
                task != null &&
                const ['Completed', 'Cancelled', 'Rejected', 'Declined']
                    .contains(task.taskStatus))
            .cast<TaskFetch>()
            .toList();
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching archived tasks: $e");
      debugPrintStack(stackTrace: stackTrace);
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load archived tasks. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Archived Tasks',
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71A4A)))
          : errorMessage != null
              ? _buildErrorState()
              : archivedTasks.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: widget.role == 'Client'
                          ? _fetchArchivedTasksClient
                          : _fetchArchivedTasks,
                      color: const Color(0xFFB71A4A),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: archivedTasks.length,
                        itemBuilder: (context, index) => _buildTaskCard(
                          archivedTasks[index],
                          context,
                        ),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Archived Tasks',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed or cancelled tasks will appear here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchArchivedTasks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71A4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectorModal(BuildContext context, TaskFetch task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          elevation: 8.0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Options',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModalOption(
                  context,
                  icon: Icons.archive_outlined,
                  title: 'Recover Task',
                  color: Colors.blueAccent,
                  onTap: () async {
                    try {
                      await controller.updateTaskStatus(
                          context, task.id, 'Recovered');
                      setState(() {
                        final index = archivedTasks.indexOf(task);
                        if (index != -1) {
                          final updatedTask = TaskFetch(
                            id: task.id,
                            taskStatus: 'Recovered',
                            taskDetails: task.taskDetails,
                            taskTakenId: task.taskTakenId,
                            createdAt: task.createdAt,
                            updatedAt: DateTime.now(),
                          );
                          archivedTasks[index] = updatedTask;
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task recovered successfully',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to archive task',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      debugPrint('Error archiving task: $e');
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  icon: Icons.delete_outline,
                  title: 'Delete Task',
                  color: Colors.redAccent,
                  onTap: () async {
                    try {
                      await controller.updateTaskStatus(
                          context, task.id, 'Deleted');
                      setState(() {
                        final index = archivedTasks.indexOf(task);
                        if (index != -1) {
                          final updatedTask = TaskFetch(
                            id: task.id,
                            taskStatus: 'Deleted',
                            taskDetails: task.taskDetails,
                            taskTakenId: task.taskTakenId,
                            createdAt: task.createdAt,
                            updatedAt: DateTime.now(),
                          );
                          archivedTasks[index] = updatedTask;
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task deleted successfully',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete task',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(10),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      debugPrint('Error deleting task: $e');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Light background for contrast
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskFetch task, BuildContext context) {
    // Replace with actual price logic if available
    // String priceDisplay = "${task.taskDetails?.price ?? 'N/A'} Credits";

    if (task.taskStatus == 'Deleted' || task.taskStatus == 'Recovered') {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskStatusPage(task, context),
        onLongPress: () {
          _showSelectorModal(context, task);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTaskReceived(task),
                  _buildTaskStatusColor(task),
                ],
              ),
              const SizedBox(height: 8),
              widget.role == 'Client'
                  ? _buildTaskInfoClient(task)
                  : _buildTaskInfoTasker(task),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTaskStatusPage(TaskFetch task, BuildContext context) {
    final statusPages = {
      'Completed': TaskFinished(taskInformation: task),
      'Cancelled': TaskCancelled(taskInformation: task),
      'Rejected': TaskRejected(taskInformation: task),
      'Declined': TaskDeclined(taskInformation: task),
    };

    final page = statusPages[task.taskStatus];
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ).then((_) {
        if (widget.role == 'Client') {
          _fetchArchivedTasksClient();
        } else {
          _fetchArchivedTasks();
        }
      });
    }
  }

  Widget _buildTaskInfoTasker(TaskFetch task, {double size = 40.0}) {
    final String? imageUrl = task.taskDetails?.client?.user?.image;
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
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.taskDetails?.title != null
                  ? task.taskDetails!.title.length > 25
                      ? '${task.taskDetails!.title.substring(0, 25)}...'
                      : task.taskDetails!.title
                  : 'Untitled Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "${task.taskDetails?.client?.user?.firstName ?? 'Unknown'} ${task.taskDetails?.client?.user?.lastName ?? 'Unknown'}",
              style: GoogleFonts.poppins(
                color: const Color(0xFFB71A4A),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskInfoClient(TaskFetch task, {double size = 40.0}) {
    final imageUrl = task.tasker?.user?.image ?? 'Unknown';
    final hasValidImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'Unknown';

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
                : const Icon(Icons.person, color: Colors.grey, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (task.post_task?.title.length ?? 0) > 20
                  ? '${task.post_task?.title.substring(0, 20)}...'
                  : task.post_task?.title ?? 'Untitled Task',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              "${task.tasker?.user?.firstName ?? 'Unknown'} ${task.tasker?.user?.lastName ?? 'Unknown'}",
              style: GoogleFonts.poppins(
                  color: const Color(0xFFB71A4A), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskReceived(TaskFetch task) {
    DateTime? createdDateTime;
    try {
      createdDateTime = DateTime.parse(task.createdAt.toString());
    } catch (e) {
      debugPrint('Error parsing createdAt: $e');
      return const Text('Invalid Date', style: TextStyle(fontSize: 14));
    }

    final formattedDate = DateFormat('MMM d, yyyy').format(createdDateTime);
    final now = DateTime.now().toUtc();
    final difference = now.difference(createdDateTime);

    String timeAgo;
    if (difference.inMinutes < 60) {
      final minutesAgo = difference.inMinutes;
      timeAgo = '$minutesAgo ${minutesAgo == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hoursAgo = difference.inHours;
      timeAgo = '$hoursAgo ${hoursAgo == 1 ? 'hour' : 'hours'} ago';
    } else {
      final daysAgo = difference.inDays;
      timeAgo = '$daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago';
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

  Widget _buildTaskStatusColor(TaskFetch task) {
    final statusColors = {
      'Pending': Colors.grey[500],
      'Completed': Colors.green,
      'Confirmed': Colors.green,
      'Dispute Settled': Colors.blueAccent,
      'Ongoing': Colors.blue,
      'Interested': Colors.blue,
      'Review': Colors.yellow,
      'Disputed': Colors.orange,
      'Rejected': Colors.redAccent,
      'Declined': Colors.red,
      'Cancelled': Colors.red,
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: statusColors[task.taskStatus] ?? Colors.red,
          ),
          child: Text(
            task.taskStatus ?? 'Unknown',
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
