import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/task_information.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_fe/view/service_acc/task_requests_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/service/job_post_service.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  ClientServices clientServices = ClientServices();
  final TextEditingController _searchController = TextEditingController();
  final ClientServices _clientServices = ClientServices();
  final AuthenticationController _authController = AuthenticationController();
  final ProfileController _profileController = ProfileController();
  final GetStorage storage = GetStorage();
  bool _isLoading = true;
  List<UserModel> _likedTasks = [];
  List<UserModel> _filteredTasks = [];
  List<int> selectedFilters = [];
  String? _errorMessage;
  int savedTasksCount = 0;

  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  AuthenticatedUser? _user;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadLikedTasks();
    _searchController.addListener(_filterTaskFunction);
    _fetchUserIDImage();
  }

  void _filterTaskFunction() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredTasks = _likedTasks.where((task) {
        return task.firstName.toLowerCase().contains(query) ||
            task.accStatus!.toLowerCase().contains(query);
      }).toList();
    });

    _updateSavedTasks();
  }

  Future<void> _loadLikedTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = await clientServices.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in again to view your liked Tasks';
        });
        return;
      }

      // Fetch liked Tasks
      final likedTasks = await clientServices.fetchUserLikedTasks();
      debugPrint("Liked Task ${likedTasks.toString()}");
      setState(() {
        _likedTasks = likedTasks;
        _filteredTasks = List.from(_likedTasks);
        savedTasksCount = _filteredTasks.length;
        _isLoading = false;
      });
    } catch (e, st) {
      setState(() {
        _isLoading = false;
        debugPrint(e.toString());
        debugPrint(st.toString());
        _errorMessage = 'Error loading liked Tasks. Please Try Again.';
      });
    }
  }

  // Function to simulate a saved job count update
  void _updateSavedTasks() {
    setState(() {
      savedTasksCount = _filteredTasks.length;
    });
  }

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      if (userId == null) {
        debugPrint("User ID not found in storage po");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load user image. Please try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      debugPrint(user.toString());

      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _isLoading = false;

          _role = _user?.user?.role ?? '';

          debugPrint(
              "Successfully loaded user image" + _existingProfileImageUrl!);
          debugPrint("Successfully loaded ID image" + _existingIDImageUrl!);
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
    }
  }

  Widget missingInformation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Missing Information",
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FillUpClient()),
              );
              if (result == true) {
                setState(() {
                  _isLoading = true;
                });

                await _fetchUserIDImage(); // Refresh user profile and ID image data
              }
            },
            child: const Text('Upload Your Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            'Liked Tasks',
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
          Padding(
            padding: EdgeInsets.all(16.0), // Added padding
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFF1F4FF),
                hintText: 'Search Tasks...',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent, width: 0),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.blue, width: 2), // Fixed color
                ),
              ),
            ),
          ),
          if (selectedFilters.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 8,
                children: selectedFilters
                    .map((filter) => Chip(
                          label: Text('\$$filter'),
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              selectedFilters.remove(filter);
                              _filterTaskFunction();
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task result: $savedTasksCount",
                  style: GoogleFonts.montserrat(
                      fontSize: 10, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          Expanded(
            // Ensures _buildBody() takes remaining space
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_existingProfileImageUrl == null ||
        _existingIDImageUrl == null ||
        _existingProfileImageUrl!.isEmpty ||
        _existingIDImageUrl!.isEmpty) {
      return missingInformation();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            ElevatedButton(
              onPressed: _loadLikedTasks,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'You haven\'t liked any Tasks yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ServiceAccMain()),
                  (route) =>
                      false, // Removes all previous routes from the stack
                );
              },
              child: const Text('Browse Tasks'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLikedTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final job = _filteredTasks[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  int _getPriceFilter(int? price) {
    if (price == null) return 0;
    if (price <= 500) return 500;
    if (price <= 700) return 700;
    if (price <= 20000) return 20000;
    if (price <= 300000) return 30000;
    return 100000;
  }

  Widget _buildJobCard(UserModel task) {
    return Card(
      color: Color.fromARGB(255, 239, 254, 255),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Wrap the left content in Expanded
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              image: const DecorationImage(
                                image: AssetImage('assets/images/image1.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width:
                                10), // Replace Padding with SizedBox for consistency
                        Expanded(
                          // Wrap the text column in Expanded to prevent overflow
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.firstName ?? "NO data",
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF03045E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow:
                                    TextOverflow.ellipsis, // Handle long titles
                              ),
                              Row(
                                children: [
                                  if (task.accStatus != null)
                                    Flexible(
                                      // Wrap status text in Flexible
                                      child: Text(
                                        task.email,
                                        style: GoogleFonts.montserrat(
                                          color:
                                              Color.fromARGB(255, 57, 209, 11),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Color.fromARGB(255, 228, 11, 11),
                    size: 24,
                  ),
                  onPressed: () {
                    _unlikeJob(task);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(

                          builder: (context) => TaskInformation(
                              taskID: task.id as int, role: _role),

//                           builder: (context) => TaskerProfilePage(tasker: task),

                        ),
                      );
                      print(task.id);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Minimize the Row size
                      children: [
                        Text(
                          "View Details",
                          style: GoogleFonts.montserrat(
                            color: Color(0xFF03045E),
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward, color: Color(0xFF03045E)),
                      ],
                    ),
                  ),
                ),
                // Add Assign Task button
                TextButton.icon(
                  onPressed: () => _assignTask(task),
                  icon: Icon(Icons.assignment_turned_in,
                      color: Color(0xFF03045E)),
                  label: Text(
                    "Assign Task",
                    style: GoogleFonts.montserrat(
                      color: Color(0xFF03045E),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlikeJob(UserModel job) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Center(
            child: Text(
              'Remove from Saved Tasks?',
              style: GoogleFonts.montserrat(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'This tasker will be removed from your liked list.',
                    style: GoogleFonts.montserrat(
                        fontSize: 10, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(
                      Icons.cancel,
                      size: 24,
                      color: Colors.green.shade400,
                    )),
                IconButton(
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(
                    Icons.delete,
                    size: 24,
                    color: Colors.red,
                  ),
                )
              ],
            )
          ],
        ),
      );

      if (confirm == null || !confirm) return;

      // Ensure the job ID is valid
      if (job.id == null) {
        debugPrint("Error: Tasker ID is null.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unlike tasker. Invalid tasker ID.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Fetch the client ID
      final String? clientId = await clientServices.getUserId();
      if (clientId == null || clientId.isEmpty || clientId == '0') {
        debugPrint("Error: Client ID is invalid.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unlike tasker. Invalid client ID.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Process the unlike action
      final result = await clientServices.unlikeTask(job.id!);

      if (result['success']) {
        // Remove from local list
        setState(() {
          _filteredTasks.removeWhere((item) => item.id == job.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error in _unlikeJob: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unlike job. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignTask(UserModel tasker) async {
    try {
      // Create TaskController instance
      final taskController = TaskController();

      // Fetch the client's created tasks to display in the dialog
      List<TaskModel> clientTasks = await _fetchClientTasks();

      if (clientTasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have no active tasks to assign.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Filter out tasks that are already assigned to anyone
      final jobPostService = JobPostService();
      List<TaskModel> availableTasks = [];
      for (var task in clientTasks) {
        if (task.id != null) {
          bool isAssigned =
              await jobPostService.isTaskAssigned(task.id, tasker.id!);
          if (!isAssigned) {
            availableTasks.add(task);
          }
        } else {
          // Skip this task as it has an invalid ID
          debugPrint("Skipping task with null ID");
        }
      }

      if (availableTasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All your active tasks are already assigned.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show task selection dialog with filtered tasks
      final TaskModel? selectedTask = await showDialog<TaskModel>(
        context: context,
        builder: (context) => _buildTaskSelectionDialog(availableTasks),
      );

      if (selectedTask == null) return;

      // Get client ID
      final String? clientId = await clientServices.getUserId();
      if (clientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to identify client. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await taskController.assignTask(
        selectedTask.id,
        int.parse(clientId),
        tasker.id ?? 0,
        // _role,
      );

      // Show loading indicator
      final loadingOverlay = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black45,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      Overlay.of(context)?.insert(loadingOverlay);

      try {
        // Assign the task using the TaskController
        final result = await taskController.assignTask(
          selectedTask.id,
          int.parse(clientId),
          tasker.id,
        );

        // Remove loading indicator
        loadingOverlay.remove();

        // Show result with appropriate color based on success/failure
        final isSuccess = !result.toLowerCase().contains('already') &&
            !result.toLowerCase().contains('error') &&
            !result.toLowerCase().contains('failed');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        // If successful, refresh the task list
        if (isSuccess) {
          await _fetchClientTasks();

          // Also add this success to the JobPostService cache manually
          try {
            final jobPostService = JobPostService();
            jobPostService.updateAssignmentCache(
                selectedTask.id!, tasker.id!, true);
          } catch (e) {
            debugPrint("Error updating cache: $e");
          }
        }
      } finally {
        // Ensure the loading overlay is removed even if there's an error
        try {
          loadingOverlay.remove();
        } catch (e) {
          // Overlay may already be removed
        }
      }
    } catch (e) {
      debugPrint("Error in _assignTask: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<TaskModel>> _fetchClientTasks() async {
    try {
      final taskController = TaskController();
      final String? clientId = await clientServices.getUserId();
      if (clientId == null) return [];

      return await taskController.getCreatedTasksByClient(int.parse(clientId));
    } catch (e) {
      debugPrint("Error fetching client tasks: $e");
      return [];
    }
  }

  Widget _buildTaskSelectionDialog(List<TaskModel> tasks) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Center(
        child: Text(
          'Select a Task to Assign',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF03045E),
          ),
        ),
      ),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              title: Text(
                task.title ?? 'Untitled Task',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                task.description ?? 'No description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
              trailing: Text(
                '\$${task.contactPrice ?? 0}',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              onTap: () => Navigator.of(context).pop(task),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.montserrat(color: Colors.red),
          ),
        ),
      ],
    );
  }

  void _viewJobDetails(UserModel job) {
    // Navigate to a detail page for this job
    // TODO: Replace this with navigation to your detail page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job.accStatus ?? 'Job Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (job.accStatus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Company: ${job.accStatus}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (job.accStatus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Description: ${job.accStatus}'),
                ),
              if (job.accStatus != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Salary: \$${job.accStatus}'),
                ),
              // Add more job details as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement job application functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Application feature coming soon!')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
