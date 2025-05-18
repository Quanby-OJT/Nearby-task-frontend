import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/address/address.dart';
import 'package:flutter_fe/view/address/address_list.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTask extends StatefulWidget {
  const AddTask({super.key});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> with SingleTickerProviderStateMixin {
  final TaskController controller = TaskController();
  final JobPostService jobPostService = JobPostService();
  final ClientServices _clientServices = ClientServices();
  final ProfileController _profileController = ProfileController();
  final EscrowManagementController _escrowManagementController =
      EscrowManagementController();
  final GetStorage storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  String? _message;
  String? selectedTimePeriod;
  String? selectedUrgency;
  String? selectedSpecialization;
  String selectedWorkType = "Solo";
  List<String> items = ['Day/s', 'Week/s', 'Month/s', 'Year/s'];
  List<String> urgency = ['Non-Urgent', 'Urgent'];
  List<String> workTypes = ['Solo', 'Group'];
  List<String> specialization = [];
  final Map<String, String> _errors = {};
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;

  bool _isLoading = true;
  bool _showButton = false;
  bool _isUploadDialogShown = false;
  bool _documentValid = false;

  @override
  void initState() {
    super.initState();

    fetchSpecialization();
    _loadSkills();
    _fetchUserIDImage();
  }

  @override
  void dispose() {
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
        });

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

      // Get profile image from user
      _existingProfileImageUrl = user?.user.image;
      String? accountStatus = user?.user.accStatus;

      // Check if user account status is already in Review or Approved state
      bool isVerifiedOrInReview = accountStatus == "Review" ||
          accountStatus == "Approved" ||
          accountStatus == "Verified";

      // Try to fetch ID image, but handle errors gracefully
      try {
        final response = await _clientServices.fetchUserIDImage(userId);
        if (response['success']) {
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'];
        } else {
          debugPrint("Error in ID image response: ${response['error']}");
        }
      } catch (idError) {
        debugPrint("Error fetching ID image: $idError");
        // Continue even if ID image fetch fails
      }

      // Always update the state, even if some requests failed
      setState(() {
        _isLoading = false;
        // If account is already in review or approved, allow posting tasks
        if (isVerifiedOrInReview) {
          _showButton = true;
        } else {
          // Otherwise use the standard image checks
          _showButton = _existingProfileImageUrl != null &&
              _existingIDImageUrl != null &&
              _documentValid;
        }

        debugPrint("Account status: $accountStatus, _showButton: $_showButton");
      });
    } catch (e) {
      debugPrint("Error in _fetchUserIDImage: $e");
      // Always exit loading state even if there's an error
      setState(() {
        _isLoading = false;
        _showButton = false; // Will show warning dialog when trying to submit
      });
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
            color: Color(0xFF0272B1),
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
              backgroundColor: Color(0xFF0272B1),
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
          color: Colors.black,
          fontSize: 12,
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
          borderSide: BorderSide(color: Color(0xFFB71A4A), width: 2),
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(color: Colors.red[400]),
      ),
      style: GoogleFonts.poppins(fontSize: 12),
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
          color: Colors.black,
          fontSize: 12,
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
          borderSide: BorderSide(color: Color(0xFFB71A4A), width: 2),
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(color: Colors.red[400]),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.poppins(fontSize: 12),
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
      cursorColor: Color(0xFFB71A4A),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.black,
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
          borderSide: BorderSide(color: Color(0xFFB71A4A), width: 2),
        ),
        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFFB71A4A)),
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
                  primary: Color(0xFFB71A4A),
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

  void _showAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Create Task',
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
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              controller: ScrollController(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _showAddress,
                          child: Text('Select Address'),
                        ),
                      ],
                    ),
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
                    onChanged: (value) =>
                        setState(() => selectedUrgency = value),
                    errorText: _errors['urgency'],
                  ),
                  SizedBox(height: 16),
                  _buildDropdownField(
                    value: selectedWorkType,
                    items: workTypes,
                    hint: 'Work Type *',
                    onChanged: (value) =>
                        setState(() => selectedWorkType = value!),
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
                            if (!_showButton) {
                              _showWarningDialog();
                              return;
                            }
                            _validateAndSubmit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71A4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Add Task',
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
    );
  }
}
