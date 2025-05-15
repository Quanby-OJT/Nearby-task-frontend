import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/business_acc/business_task_detail.dart';
import 'package:flutter_fe/view/business_acc/task_creation/add_task.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/client_model.dart';

class JobPostPage extends StatefulWidget {
  const JobPostPage({super.key});

  @override
  State<JobPostPage> createState() => _JobPostPageState();
}

class _JobPostPageState extends State<JobPostPage>
    with SingleTickerProviderStateMixin {
  final TaskController controller = TaskController();
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  final EscrowManagementController _escrowManagementController =
      EscrowManagementController();
  final GetStorage storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  ClientModel? clientModel;
  String? _message;
  bool _isSuccess = false;
  String? selectedTimePeriod;
  String? selectedUrgency;
  String? selectedSpecialization;
  String selectedWorkType = "Solo";
  List<String> items = ['Day/s', 'Week/s', 'Month/s', 'Year/s'];
  List<String> urgency = ['Non-Urgent', 'Urgent'];
  List<String> workTypes = ['Solo', 'Group'];
  List<String> specialization = [];
  List<TaskModel?> clientTasks = [];
  List<TaskModel?> _filteredTasks = [];
  final Map<String, String> _errors = {};
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  AuthenticatedUser? _user;
  bool _isLoading = true;
  bool _showButton = false;
  bool _isUploadDialogShown = false;
  bool _documentValid = false;

  final List<String> _tabStatuses = ["All", "Available", "More"];
  late TabController _tabController;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _currentFilter = null;
          } else if (_tabController.index == 1) {
            _currentFilter = "Available";
          }
          _filterTasks();
        });
      }
    });
    fetchSpecialization();
    _loadSkills();
    _fetchUserIDImage();
    fetchCreatedTasks();
    _searchController.addListener(_filterTasks);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSpecialization() async {
    try {
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();
      setState(() {
        specialization =
            fetchedSpecializations.map((spec) => spec.specialization).toList();
        debugPrint("Specializations: $specialization");
      });
    } catch (error, stackTrace) {
      debugPrint('Error fetching specializations: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _loadSkills() async {
    try {
      final String response =
          await rootBundle.loadString('assets/tesda_skills.json');
      final data = jsonDecode(response);
      setState(() {
        _skills = List<String>.from(data['tesda_skills']);
      });
    } catch (e, stackTrace) {
      print('Error loading skills: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String? _selectedSkill;
  List<String> _skills = [];

  Future<void> fetchCreatedTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = storage.read('user_id');
      if (userId != null) {
        final tasks = await controller.getJobsforClient(context, userId);
        debugPrint("Client Tasks this is: ${tasks.toString()}");
        setState(() {
          clientTasks = tasks;
          _filteredTasks = List.from(clientTasks);
        });
        _filterTasks();
      }
    } catch (e) {
      debugPrint("Error fetching created tasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load tasks. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: fetchCreatedTasks,
            textColor: Colors.white,
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTasks() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredTasks = clientTasks.where((task) {
        if (task == null) return false;
        bool matchesSearch =
            (task.title.toLowerCase().contains(query) ?? false) ||
                (task.description.toLowerCase().contains(query) ?? false);
        bool matchesStatus =
            _currentFilter == null || task.status == _currentFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _validateAndSubmit() {
    setState(() {
      _errors.clear();

      if (controller.jobTitleController.text.trim().isEmpty) {
        _errors['task_title'] = 'Please Indicate Your Needed Task';
      }
      if (selectedSpecialization == null) {
        _errors['specialization'] = "Please Indicate the Needed Specialization";
      }
      if (controller.jobDescriptionController.text.trim().isEmpty) {
        _errors['task_description'] = 'Please Elaborate Your Task.';
      }
      String contractPrice = controller.contactPriceController.text.trim();
      if (contractPrice.isEmpty) {
        _errors['contact_price'] = 'Indicate the Contract Price';
      } else if (double.tryParse(contractPrice) == null ||
          double.parse(contractPrice) <= 0) {
        _errors['contact_price'] =
            'Contract Price must be a valid positive number';
      }
      if (controller.jobLocationController.text.trim().isEmpty) {
        _errors['location'] =
            'Indicate Your Location where the Task will be held.';
      }
      String jobTime = controller.jobTimeController.text.trim();
      if (jobTime.isEmpty) {
        _errors['num_of_days'] = 'Indicate the Time Needed to Finish the Task';
      } else if (int.tryParse(jobTime) == null || int.parse(jobTime) <= 0) {
        _errors['num_of_days'] = 'Time Needed must be a valid positive number';
      }
      String startDate = controller.jobTaskBeginDateController.text.trim();
      if (startDate.isEmpty) {
        _errors['task_begin_date'] = 'Indicate When to Start Your Task';
      } else {
        try {
          DateTime taskBeginDate = DateTime.parse(startDate);
          if (taskBeginDate.isBefore(DateTime.now())) {
            _errors['task_begin_date'] =
                'Task start date must be in the future';
          }
        } catch (e) {
          _errors['task_begin_date'] = 'Invalid date format';
        }
      }
      if (selectedUrgency == null) {
        _errors['urgency'] =
            'Please Indicate if Your Task Needs to be finished ASAP.';
      }
      if (selectedTimePeriod == null) {
        _errors['time_period'] = "Please Indicate the Time Period.";
      }

      if (_errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix the errors before submitting'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _submitJob();
      }
    });
  }

  Future<void> _submitJob() async {
    setState(() {
      _message = "";
      _errors.clear();
      _isSuccess = false;
    });

    try {
      final result = await controller.postJob(
        selectedSpecialization ?? "",
        selectedUrgency ?? "",
        selectedTimePeriod ?? "",
        selectedWorkType,
      );

      if (result['success']) {
        Navigator.pop(context);
        setState(() {
          _message = result['message'] ?? "Successfully Posted Task.";
          _isSuccess = true;
        });

        await fetchCreatedTasks();

        controller.jobTitleController.clear();
        controller.jobDescriptionController.clear();
        controller.jobLocationController.clear();
        controller.jobTimeController.clear();
        controller.contactPriceController.clear();
        controller.jobRemarksController.clear();
        controller.jobTaskBeginDateController.clear();

        setState(() {
          selectedSpecialization = null;
          selectedUrgency = null;
          selectedTimePeriod = null;
          selectedWorkType = "Solo";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        Navigator.pop(context);
        setState(() {
          if (result.containsKey('errors') && result['errors'] is List) {
            for (var error in result['errors']) {
              if (error is Map<String, dynamic> &&
                  error.containsKey('path') &&
                  error.containsKey('msg')) {
                _errors[error['path']] = error['msg'];
              }
            }
          }
          _message = result['error'] ?? 'Failed to post task';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      debugPrint("Error submitting job: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
          _documentValid = response['status'];
          _isLoading = false;
          _showButton = _existingProfileImageUrl != null &&
              _existingIDImageUrl != null &&
              _documentValid;
        });
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToTaskDetail(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessTaskDetail(task: task, taskID: task.id),
      ),
    );
    if (result == true) {
      await fetchCreatedTasks();
    }
  }

  void _showWarningDialog() {
    if (_isUploadDialogShown) return;
    setState(() {
      _isUploadDialogShown = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE23670),
          ),
        ),
        content: Text(
          'Please upload your profile and ID images to post tasks.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isUploadDialogShown = false;
              });
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red[400],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
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
              setState(() {
                _isUploadDialogShown = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE23670),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Verify Now',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Create a New Task',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE23670),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '* Required fields',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: controller.jobTitleController,
                label: 'Task Title *',
                hint: 'Enter task title',
                errorText: _errors['task_title'],
              ),
              SizedBox(height: 16),
              _buildDropdownField(
                value: selectedSpecialization,
                items: specialization,
                hint: 'Select Specialization *',
                onChanged: (value) =>
                    setState(() => selectedSpecialization = value),
                errorText: _errors['specialization'],
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: controller.jobDescriptionController,
                label: 'Task Description *',
                hint: 'Describe your task...',
                maxLines: 4,
                errorText: _errors['task_description'],
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: controller.contactPriceController,
                label: 'Contract Price *',
                hint: 'Enter price',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _errors['contact_price'],
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: controller.jobLocationController,
                label: 'Location *',
                hint: 'Enter location',
                errorText: _errors['location'],
              ),
              SizedBox(height: 16),
              _buildDropdownField(
                value: selectedTimePeriod,
                items: items,
                hint: 'Time Period *',
                onChanged: (value) =>
                    setState(() => selectedTimePeriod = value),
                errorText: _errors['time_period'],
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: controller.jobTimeController,
                label: 'Duration *',
                hint: 'Enter duration (e.g., 5)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _errors['num_of_days'],
              ),
              SizedBox(height: 16),
              _buildDateField(
                controller: controller.jobTaskBeginDateController,
                label: 'Start Date *',
                hint: 'Select a date',
                errorText: _errors['task_begin_date'],
              ),
              SizedBox(height: 16),
              _buildDropdownField(
                value: selectedUrgency,
                items: urgency,
                hint: 'Urgency *',
                onChanged: (value) => setState(() => selectedUrgency = value),
                errorText: _errors['urgency'],
              ),
              SizedBox(height: 16),
              _buildDropdownField(
                value: selectedWorkType,
                items: workTypes,
                hint: 'Work Type *',
                onChanged: (value) => setState(() => selectedWorkType = value!),
                errorText: _errors['work_type'],
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: controller.jobRemarksController,
                label: 'Remarks',
                hint: 'Additional notes...',
                maxLines: 3,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _message = "";
                          _errors.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_showButton) {
                          _showWarningDialog();
                          return;
                        }
                        _validateAndSubmit();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE23670),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Post Task',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Filter Tasks',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB71A4A)),
                ),
              ),
              SizedBox(height: 16),
              RadioListTile<String>(
                title: Text('Task Taken',
                    style: GoogleFonts.poppins(fontSize: 14)),
                value: 'Task Taken',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value;
                    _filterTasks();
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text('Closed', style: GoogleFonts.poppins(fontSize: 14)),
                value: 'Closed',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value;
                    _filterTasks();
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title:
                    Text('On Hold', style: GoogleFonts.poppins(fontSize: 14)),
                value: 'On Hold',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value;
                    _filterTasks();
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title:
                    Text('Reported', style: GoogleFonts.poppins(fontSize: 14)),
                value: 'Reported',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value;
                    _filterTasks();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Color(0xFF0272B1),
          fontSize: 14,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: Color(0xFFE23670), width: 2),
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(color: Colors.red[400]),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  Widget _buildDropdownField({
    String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    String? errorText,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.poppins(
          color: Color(0xFF0272B1),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: Color(0xFFE23670), width: 2),
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(color: Colors.red[400]),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Color(0xFF0272B1),
          fontSize: 14,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: Color(0xFFE23670), width: 2),
        ),
        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFFE23670)),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(color: Colors.red[400]),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFFE23670),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          String formattedDate =
              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
          controller.text = formattedDate;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Task',
          style: GoogleFonts.poppins(
            color: const Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : clientTasks.isEmpty
              ? const Center(child: Text("No tasks available"))
              : Column(
                  children: [
                    // Search
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TextField(
                        controller: _searchController,
                        cursorColor: const Color(0xFFB71A4A),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Search tasks...',
                          hintStyle:
                              GoogleFonts.poppins(color: Colors.grey[400]),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[400]),
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
                            borderSide: BorderSide(
                                color: const Color(0xFFB71A4A), width: 2),
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      indicatorColor: const Color(0xFFB71A4A),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3.0,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      unselectedLabelStyle:
                          TextStyle(fontWeight: FontWeight.normal),
                      onTap: (index) {
                        if (index == 2) {
                          _showFilterModal();
                        } else {
                          setState(() {
                            if (index == 0) {
                              _currentFilter = null;
                            } else if (index == 1) _currentFilter = "Available";
                            _filterTasks();
                          });
                        }
                      },
                      tabs: _tabStatuses.map((status) {
                        return Tab(
                          child: SizedBox(
                            width: 90,
                            child: Center(
                              child: status == "More"
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          status,
                                          style: TextStyle(fontSize: 12),
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ],
                                    )
                                  : Text(
                                      status,
                                      style: TextStyle(fontSize: 12),
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_filteredTasks.length} ${_currentFilter == null ? "" : "$_currentFilter"} tasks',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFE23670)))
                          : _filteredTasks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.task_alt,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No tasks found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Create a new task to get started!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: fetchCreatedTasks,
                                  color: Color(0xFFE23670),
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(16),
                                    itemCount: _filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = _filteredTasks[index];
                                      if (task == null) {
                                        return SizedBox.shrink();
                                      }
                                      return _buildTaskCard(task);
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "addTaskBtn",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTask(),
              ),
            ),
            backgroundColor: const Color(0xFFB71A4A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusColor(TaskModel task) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: task.status == 'Pending'
                ? Colors.grey[500]
                : task.status == 'Completed'
                    ? Colors.green
                    : task.status == 'Confirmed'
                        ? Colors.green
                        : task.status == 'Dispute Settled'
                            ? Colors.green
                            : task.status == 'Ongoing'
                                ? Colors.blue
                                : task.status == 'Interested'
                                    ? Colors.blue
                                    : task.status == 'Review'
                                        ? Colors.yellow
                                        : task.status == 'Disputed'
                                            ? Colors.orange
                                            : task.status == 'Rejected'
                                                ? Colors.red
                                                : task.status == 'Declined'
                                                    ? Colors.red
                                                    : task.status == 'Cancelled'
                                                        ? Colors.red
                                                        : task.status ==
                                                                'Available'
                                                            ? Colors.green
                                                            : Colors.red,
          ),
          child: Text(
            task.status,
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

  Widget _buildTaskCard(TaskModel task) {
    String priceDisplay = "${task.contactPrice} Credits";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskDetail(task),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskStatusColor(task),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title ?? 'Untitled Task',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE23670),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.locationPin,
                color: Colors.red[400]!,
                text: (task.address?.city ?? 'N/A') +
                    ', ' +
                    (task.address?.province ?? 'N/A'),
              ),
              SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.coins,
                color: Colors.green[400]!,
                text: priceDisplay,
              ),
              SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.screwdriverWrench,
                color: Color(0xFFE23670),
                text: task.specialization ?? 'N/A',
              ),
              SizedBox(height: 8),
              _buildTaskInfoRow(
                icon: FontAwesomeIcons.clock,
                color: Colors.orange[400]!,
                text: '${task.duration ?? 'N/A'} ${task.period ?? ''}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 16,
          color: color,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
