import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/view/business_acc/tasker_profile_page.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/task_information.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/task_model.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final ClientServices _clientServices = ClientServices();
  final TextEditingController _searchController = TextEditingController();
  final AuthenticationController _authController = AuthenticationController();
  final ProfileController _profileController = ProfileController();
  final GetStorage storage = GetStorage();
  bool _isLoading = true;
  List<UserModel> _likedTasks = [];
  List<UserModel> _filteredTasks = [];
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTaskFunction() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredTasks = _likedTasks.where((task) {
        return (task.firstName?.toLowerCase().contains(query) ?? false) ||
            (task.email?.toLowerCase().contains(query) ?? false);
      }).toList();
      savedTasksCount = _filteredTasks.length;
    });
  }

  Future<void> _loadLikedTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = await _clientServices.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in again to view your liked tasks';
        });
        return;
      }

      final likedTasks = await _clientServices.fetchUserLikedTasks();
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
        _errorMessage = 'Error loading liked tasks. Please try again.';
      });
    }
  }

  Future<void> _fetchUserIDImage() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      AuthenticatedUser? user =
          await _profileController.getAuthenticatedUser(context, userId);
      final response = await _clientServices.fetchUserIDImage(userId);

      if (response['success']) {
        setState(() {
          _user = user;
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _isLoading = false;
          _role = _user?.user?.role ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load user image. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _unlikeJob(UserModel job) async {
    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Remove from Liked Tasks?',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0272B1),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'This tasker will be removed from your liked tasks list.',
            style:
                GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Remove',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final result = await _clientServices.unlikeTask(job.id!);
      if (result['success']) {
        setState(() {
          _likedTasks.removeWhere((item) => item.id == job.id);
          _filteredTasks.removeWhere((item) => item.id == job.id);
          savedTasksCount = _filteredTasks.length;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error in _unlikeJob: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unlike task. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _assignTask(UserModel tasker) async {
    try {
      List<TaskModel> clientTasks = await _fetchClientTasks();
      if (clientTasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have no active tasks to assign.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final TaskModel? selectedTask = await showDialog<TaskModel>(
        context: context,
        builder: (context) => _TaskSelectionDialog(tasks: clientTasks),
      );

      if (selectedTask == null) return;

      final String? clientId = await _clientServices.getUserId();
      if (clientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to identify client. Please log in again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final taskController = TaskController();
      final result = await taskController.assignTask(
        selectedTask.id,
        int.parse(clientId),
        tasker.id ?? 0,
        _role,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: result.toLowerCase().contains('success')
              ? Colors.green
              : Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("Error in _assignTask: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign task.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<List<TaskModel>> _fetchClientTasks() async {
    try {
      final taskController = TaskController();
      final String? clientId = await _clientServices.getUserId();
      if (clientId == null) return [];
      return await taskController.getCreatedTasksByClient(int.parse(clientId));
    } catch (e) {
      debugPrint("Error fetching client tasks: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Liked Taskers',
          style: GoogleFonts.montserrat(
            color: Color(0xFF0272B1),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search taskers...',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF0272B1), width: 2),
                ),
              ),
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
          ),
          // Task Count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Found $savedTasksCount taskers',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          // Task List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF0272B1)));
    }

    if (_existingProfileImageUrl == null ||
        _existingIDImageUrl == null ||
        _existingProfileImageUrl!.isEmpty ||
        _existingIDImageUrl!.isEmpty) {
      return _buildMissingInformation();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLikedTasks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0272B1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
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
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No liked taskers yet',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ServiceAccMain()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0272B1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Browse Taskers',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLikedTasks,
      color: Color(0xFF0272B1),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final tasker = _filteredTasks[index];
          return _buildTaskerCard(tasker);
        },
      ),
    );
  }

  Widget _buildMissingInformation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.orange[400]),
          SizedBox(height: 16),
          Text(
            'Complete Your Profile',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Please upload your profile and ID images to continue.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
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
                await _fetchUserIDImage();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0272B1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Upload Profile',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskerCard(UserModel tasker) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: tasker.image != null && tasker.image!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(tasker.image!),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) =>
                              AssetImage('assets/images/image1.jpg'),
                        )
                      : DecorationImage(
                          image: AssetImage('assets/images/image1.jpg'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Tasker Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tasker.firstName ?? 'Unknown Tasker',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0272B1),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    tasker.email ?? 'No email',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (tasker.accStatus != null)
                    Chip(
                      label: Text(
                        tasker.accStatus!,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                      backgroundColor: Colors.green[50],
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite, color: Colors.red[400], size: 24),
                  onPressed: () => _unlikeJob(tasker),
                ),
                SizedBox(height: 8),
                IconButton(
                  icon: Icon(Icons.info_outline,
                      color: Color(0xFF0272B1), size: 24),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaskerProfilePage(tasker: tasker, isSaved: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSelectionDialog extends StatelessWidget {
  final List<TaskModel> tasks;

  const _TaskSelectionDialog({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Select a Task to Assign',
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0272B1),
        ),
        textAlign: TextAlign.center,
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 300),
        child: tasks.isEmpty
            ? Center(
                child: Text(
                  'No tasks available',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      title: Text(
                        task.title ?? 'Untitled Task',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0272B1),
                        ),
                      ),
                      subtitle: Text(
                        task.description ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: task.contactPrice != null
                          ? Text(
                              '\$${task.contactPrice}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(task),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.red[400],
            ),
          ),
        ),
      ],
    );
  }
}
