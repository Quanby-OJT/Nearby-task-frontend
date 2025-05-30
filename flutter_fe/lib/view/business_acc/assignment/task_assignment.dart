import 'package:flutter/material.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/tasker_model.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/custom_loading/custom_scaffold.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({super.key, required this.tasker});

  final TaskerModel tasker;

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
  List<TaskModel>? _preloadedTasks;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterTasks);
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

  Future<void> _preloadClientTasks() async {
    try {
      final tasks = await _fetchClientTasks();
      if (mounted) {
        setState(() {
          _preloadedTasks = tasks;
        });
      }
    } catch (e) {
      debugPrint("Error preloading tasks: $e");
    }
  }

  Future<List<TaskModel>> _fetchClientTasks() async {
    try {
      final cachedTasks = TaskCache.getTasks();
      if (cachedTasks != null) {
        debugPrint("Using cached tasks");
        return cachedTasks;
      }

      final clientServices = ClientServices();
      final String? clientId = await clientServices.getUserId();
      if (clientId == null) {
        debugPrint("Client ID is null");
        return [];
      }

      final tasks =
          await taskController.getCreatedTasksByClient(int.parse(clientId));
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
              title: Text(
                'Assign Task: ${task.title ?? 'Task ${task.id}'}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set request expiration (days):',
                    style: GoogleFonts.poppins(),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempDateTime == null) {
                     CustomScaffold(message: 'Please select both date and time.', color: Colors.red);
                    }
                    Navigator.pop(context, {
                      'daysAvailable': tempDays,
                 
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71A4A),
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
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
        CustomScaffold(message: 'Unable to identify client. Please log in again.', color: Colors.red);
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

      CustomScaffold(message: result, color: isSuccess ? Colors.green : Colors.red);

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
      debugPrint("Error in _assignTask: $e");
      CustomScaffold(message: 'Failed to assign task: $e', color: Colors.red);
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
                                    task.title ?? 'Task ${task.id}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    task.description ?? 'No description',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _assignTask(task),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFB71A4A),
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
