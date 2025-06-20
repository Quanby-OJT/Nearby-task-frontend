import 'package:flutter/material.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/widgets/privacy_policy_popup.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskAssignmentScreen extends StatefulWidget {
  final TaskerModel tasker;
  const TaskAssignmentScreen({super.key, required this.tasker});

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final TaskController taskController = TaskController();
  final ProfileController _profileController = ProfileController();
  final storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();

  AuthenticatedUser? _user;
  String? _role;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAssigning = false;
  List<TaskModel>? _availableTasks;
  List<TaskModel>? _filteredTasks;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterTasks);

    // Show privacy policy popup after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PrivacyPolicyPopup(context: 'task_assignment');
        },
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTasks);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Future.wait([
        _loadAvailableTasks(),
      ]);

      setState(() {
        _isLoading = false;
        _filteredTasks = _availableTasks;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load data: $e";
        debugPrint("Initialization error: $e");
        debugPrintStack(stackTrace: stackTrace);
      });
    }
  }

  Future<List<TaskModel>> _fetchClientTasks() async {
    try {
      final cachedTasks = TaskCache.getTasks();
      if (cachedTasks != null) {
        debugPrint("Using cached tasks");
        return cachedTasks;
      }

      debugPrint("Fetching client tasks from the database");

      final clientServices = ClientServices();
      final String? clientId = await clientServices.getUserId();
      if (clientId == null) {
        debugPrint("Client ID is null");
        return [];
      }

      final tasks = await taskController.getCreatedTasksByClient(
          context, int.parse(clientId));
      TaskCache.setTasks(tasks);
      return tasks;
    } catch (e) {
      debugPrint("Error fetching client tasks: $e");
      return [];
    }
  }

  Future<void> _loadAvailableTasks() async {
    try {
      List<TaskModel> clientTasks = await _fetchClientTasks();
      _availableTasks =
          await _filterAvailableTasks(clientTasks, widget.tasker.id);

      debugPrint("Available tasks: ${_availableTasks?.length}");
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load tasks: $e";
      });
    }
  }

  Future<List<TaskModel>> _filterAvailableTasks(
      List<TaskModel> tasks, int taskerId) async {
    debugPrint(
        "Filtering ${tasks.length} available tasks for tasker $taskerId");
    final jobPostService = JobPostService();
    try {
      final assignmentStatuses = await Future.wait(
        tasks.map((task) async {
          try {
            final userId = await storage.read('user_id');
            debugPrint("Checking task ${task.id} for tasker $taskerId");
            return await jobPostService.hasTaskEverBeenAssignedToTasker(
                task.id, taskerId, userId! as int);
          } catch (e) {
            debugPrint("Error checking task ${task.id}: $e");
            return false;
          }
        }),
      );

      return tasks
          .asMap()
          .entries
          .where((entry) => !assignmentStatuses[entry.key])
          .map((entry) => entry.value)
          .toList();
    } catch (e) {
      debugPrint("Error in _filterAvailableTasks: $e");
      return tasks;
    }
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _availableTasks?.where((task) {
            final title = task.title.toLowerCase() ?? '';
            return title.contains(query);
          }).toList() ??
          [];
    });
  }

  Future<Map<String, dynamic>?> _showAssignmentDialog(TaskModel task) async {
    int daysAvailable = 1;
    DateTime? availableDateTime = DateTime.now();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        int tempDays = daysAvailable;
        DateTime? tempDateTime = availableDateTime;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              title: Center(
                child: Text(
                  'Assign Task: ${task.title ?? 'Task ${task.id}'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set request expiration (days):',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[800],
                    ),
                  ),
                  Slider(
                    value: tempDays.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$tempDays day${tempDays > 1 ? 's' : ''}',
                    onChanged: (value) {
                      setDialogState(() {
                        tempDays = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB71A4A),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Color(0xFFB71A4A),
                      ),
                      child: TextButton(
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context, {
                            'daysAvailable': tempDays,
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _assignTask(TaskModel selectedTask) async {
    if (_isAssigning) return;

    // Show privacy policy first
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PrivacyPolicyPopup(context: 'task_assignment');
      },
    );

    final assignmentDetails = await _showAssignmentDialog(selectedTask);
    if (assignmentDetails == null) return;

    final daysAvailable = assignmentDetails['daysAvailable'] as int;

    debugPrint("Days Available: $daysAvailable");

    setState(() {
      _isAssigning = true;
    });

    OverlayEntry? loadingOverlay;
    try {
      loadingOverlay = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black45,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
      if (mounted) Overlay.of(context).insert(loadingOverlay);

      final clientServices = ClientServices();
      final String? clientId = await clientServices.getUserId();
      if (clientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch ID image.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final result = await taskController.assignTask(
        selectedTask.id,
        int.parse(clientId),
        widget.tasker.id ?? 0,
        _role ?? 'Client',
        daysAvailable: daysAvailable,
      );

      final isSuccess = !result.toLowerCase().contains('already') &&
          !result.toLowerCase().contains('error') &&
          !result.toLowerCase().contains('failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Successfully Assigned Task.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );

      if (isSuccess) {
        final jobPostService = JobPostService();
        jobPostService.updateAssignmentCache(
            selectedTask.id, widget.tasker.id ?? 0, true, clientId);
        TaskCache.clear();
        await _loadAvailableTasks();
        setState(() {
          _filteredTasks = _availableTasks;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error occurred",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      loadingOverlay?.remove();
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Task Assignment',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks by title...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB71A4A)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFB71A4A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFB71A4A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFB71A4A), width: 2),
                ),
              ),
            ),
          ),
          // Task available
          Text("Available Tasks: ${_filteredTasks?.length ?? 0}",
              style: GoogleFonts.poppins(fontSize: 12),
              textAlign: TextAlign.center),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      )
                    : _filteredTasks == null || _filteredTasks!.isEmpty
                        ? Center(
                            child: Text(
                              'No unassigned tasks available.',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTasks!.length,
                            itemBuilder: (context, index) {
                              final task = _filteredTasks![index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    task.title.length > 20
                                        ? '${task.title.substring(0, 20)}...'
                                        : task.title ?? 'Task ${task.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    task.description ?? 'No description',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _assignTask(task),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB71A4A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: Text(
                                      'Assign',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
