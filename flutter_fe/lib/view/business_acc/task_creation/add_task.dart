import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fe/controller/escrow_management_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/controller/task_controller.dart';
import 'package:flutter_fe/model/address.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/client_service.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:flutter_fe/view/address/address.dart';
import 'package:flutter_fe/view/address/address_list.dart';
import 'package:flutter_fe/view/fill_up/fill_up_client.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  String? _message;
  String? selectedTimePeriod;
  String? selectedUrgency;
  String? selectedSpecialization;
  String? selectedWorkType = "Solo";
  String? selectedScope = "Less than a month"; // Default value
  String? selectedExperience;
  List<String> relatedSpecializations = [];
  List<int> relatedSpecializationsIds = [];
  File? _photo;
  List<String> items = ['Day/s', 'Week/s', 'Month/s', 'Year/s'];
  List<String> urgency = ['Non-Urgent', 'Urgent'];
  List<String> workTypes = ['Solo', 'Group'];
  List<String> scopes = [
    'Less than a month',
    '1 to 3 months',
    '3 to 6 months',
    '6 months to 1 year',
    'More than 1 year'
  ];
  List<String> experienceLevels = [
    'With verified document',
    'Without verified document'
  ];
  List<MapEntry<int, String>> specializations = [MapEntry(0, 'All')];
  List<SpecializationModel> fetchedSpecializations = [];
  Map<String, int> selectedSpecializations = {};
  int? specializationId;
  final Map<String, String> _errors = {};
  String? _existingProfileImageUrl;
  String? _existingIDImageUrl;
  String? _addressID;

  bool _isLoading = true;
  bool _showButton = false;
  bool _isUploadDialogShown = false;
  bool _documentValid = false;
  int _currentStep = 0;
  bool _isVerifiedDocument = false;

  @override
  void initState() {
    super.initState();
    fetchSpecializations();
    _fetchUserIDImage();
    // Ensure selectedScope is set to a valid default if null
    if (selectedScope == null && scopes.isNotEmpty) {
      setState(() {
        selectedScope = scopes[0];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchSpecializations() async {
    try {
      fetchedSpecializations = await jobPostService.getSpecializations();

      setState(() {
        specializations = [
          MapEntry(0, 'All'),
          ...fetchedSpecializations
              .where((spec) => spec.id != null)
              .map((spec) => MapEntry(spec.id!, spec.specialization)),
        ];
        selectedSpecializations = {
          for (var category in specializations) category.value: category.key
        };
      });
    } catch (error, stackTrace) {
      debugPrint('Error fetching specializations: $error');
      debugPrintStack(stackTrace: stackTrace);
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

  bool _validateStep(int step) {
    setState(() {
      _errors.clear();
    });

    switch (step) {
      case 0: // Title
        if (controller.jobTitleController.text.trim().isEmpty) {
          _errors['task_title'] = 'Please indicate your needed task';
          return false;
        }
        break;
      case 1: // Location
        if (controller.jobLocationController.text.trim().isEmpty) {
          _errors['location'] = 'Please indicate the task location';
          return false;
        }
        break;
      case 2: // Description
        if (controller.jobDescriptionController.text.trim().isEmpty) {
          _errors['task_description'] = 'Please elaborate your task';
          return false;
        }
        break;
      case 3: // Specialization
        if (selectedSpecialization == null || specializationId == null) {
          _errors['specialization'] = 'Please select a specialization';
          return false;
        }
        break;
      case 4: // Related Specializations
        if (relatedSpecializations.isEmpty) {
          _errors['related_specializations'] =
              'Please select at least one related specialization';
          return false;
        }
        break;
      case 5: // Work Type
        if (selectedWorkType == null) {
          _errors['work_type'] = 'Please select a work type';
          return false;
        }
        break;
      case 6: // Scope of Work
        if (selectedScope == null || !scopes.contains(selectedScope)) {
          _errors['scope'] = 'Please select a valid scope of work';
          return false;
        }
        break;
      case 7: // Tasker Experience
        if (selectedExperience == null) {
          _errors['experience'] = 'Please select the experience level';
          return false;
        }
        break;
      case 8: // Project Price
        String price = controller.contactPriceController.text.trim();
        if (price.isEmpty) {
          _errors['contact_price'] = 'Please indicate the contract price';
          return false;
        } else if (int.tryParse(price) == null || int.parse(price) <= 0) {
          _errors['contact_price'] =
              'Contract price must be a valid positive number';
          return false;
        }
        break;
      case 9: // Urgency
        if (selectedUrgency == null) {
          _errors['urgency'] = 'Please indicate if the task is urgent';
          return false;
        }
        break;
      case 10: // Remarks (optional)
        return true;
      case 11: // Photo (optional)
        return true;
    }
    return true;
  }

  Future<void> _submitJob() async {
    setState(() {
      _message = "";
      _errors.clear();
      _isLoading = true;
    });

    if (specializationId == null) {
      setState(() {
        _errors['specialization'] = 'Please select a specialization';
      });
      return;
    }

    if (relatedSpecializationsIds.isEmpty) {
      setState(() {
        _errors['related_specializations'] =
            'Please select at least one related specialization';
      });
      return;
    }

    if (selectedExperience == null) {
      setState(() {
        _errors['experience'] = 'Please select the experience level';
      });
      return;
    }

    if (selectedExperience == 'With verified document') {
      setState(() {
        _isVerifiedDocument = true;
      });
    }

    try {
      final result = await controller.postJob(
        selectedSpecialization ?? "",
        selectedUrgency ?? "",
        selectedScope ?? "",
        selectedWorkType ?? "",
        relatedSpecializationsIds: relatedSpecializationsIds,
        isVerifiedDocument: _isVerifiedDocument,
        photo: _photo,
        specializationId: specializationId,
        addressId: _addressID,
      );

      debugPrint("API Response for /post-job: $result");

      if (result['success']) {
        if (mounted) {
          Navigator.pop(context);
        }

        setState(() {
          _message = result['message'] ?? "Successfully Posted Task.";
        });

        controller.clearControllers();
        setState(() {
          selectedSpecialization = null;
          selectedUrgency = null;
          selectedTimePeriod = null;
          selectedWorkType = "Solo";
          selectedScope = "Less than a month";
          selectedExperience = null;
          relatedSpecializations = [];
          relatedSpecializationsIds = [];
          _photo = null;
          specializationId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    // Ensure items is not null or empty, default to an empty list if it is
    final effectiveItems = items ?? [];
    // Ensure value is valid, default to the first item if null and items are available
    final effectiveValue = value != null && effectiveItems.contains(value)
        ? value
        : effectiveItems.isNotEmpty
            ? effectiveItems[0]
            : null;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
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
      items: effectiveItems.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          if (newValue != null) {
            onChanged(newValue);
            if (hint == 'Select Specialization *') {
              selectedSpecialization = newValue;
              specializationId = selectedSpecializations[newValue] ?? 0;
            }
          }
        });
      },
      hint: effectiveItems.isEmpty
          ? Text('No options available',
              style: GoogleFonts.poppins(fontSize: 12))
          : null,
      disabledHint: effectiveItems.isEmpty
          ? Text('No options available',
              style: GoogleFonts.poppins(fontSize: 12))
          : null,
    );
  }

  Widget _buildMultiSelectField({
    required List<String> selectedItems,
    required List<String> items,
    required String hint,
    required Function(List<String>) onChanged,
    String? errorText,
  }) {
    return GestureDetector(
      onTap: () async {
        List<String> newSelection = await showDialog(
          context: context,
          builder: (context) {
            List<String> tempSelection = List.from(selectedItems);
            return AlertDialog(
              title: Text(hint, style: GoogleFonts.poppins()),
              content: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    return CheckboxListTile(
                      title: Text(item, style: GoogleFonts.poppins()),
                      value: tempSelection.contains(item),
                      onChanged: (bool? value) {
                        if (value == true) {
                          tempSelection.add(item);
                        } else {
                          tempSelection.remove(item);
                        }
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, tempSelection),
                  child: Text('Done', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
        onChanged(newSelection);
      },
      child: InputDecorator(
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
        child: Text(
          selectedItems.isEmpty
              ? 'Select specializations'
              : selectedItems.join(', '),
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Photo (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final XFile? image =
                await _picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              setState(() {
                _photo = File(image.path);
              });
            }
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _photo == null
                ? Center(
                    child: Text(
                      'Tap to upload photo',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  )
                : Image.file(_photo!, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final steps = [
      {
        'name': 'Title',
        'tooltip': 'Enter a clear task title',
        'isOptional': false
      },
      {
        'name': 'Location',
        'tooltip': 'Specify where the task will take place',
        'isOptional': false
      },
      {
        'name': 'Description',
        'tooltip': 'Describe the task in detail',
        'isOptional': false
      },
      {
        'name': 'Specialization',
        'tooltip': 'Select the main skill needed',
        'isOptional': false
      },
      {
        'name': 'Related Specs',
        'tooltip': 'Add related skills for the task',
        'isOptional': false
      },
      {
        'name': 'Work Type',
        'tooltip': 'Choose solo or group work',
        'isOptional': false
      },
      {
        'name': 'Scope',
        'tooltip': 'Define the task duration',
        'isOptional': false
      },
      {
        'name': 'Experience',
        'tooltip': 'Set required experience level',
        'isOptional': false
      },
      {'name': 'Price', 'tooltip': 'Set the task budget', 'isOptional': false},
      {
        'name': 'Urgency',
        'tooltip': 'Indicate if the task is urgent',
        'isOptional': false
      },
      {'name': 'Remarks', 'tooltip': 'Add optional notes', 'isOptional': true},
      {
        'name': 'Photo',
        'tooltip': 'Upload an optional photo',
        'isOptional': true
      },
    ];

    final visibleSteps = steps.sublist(_currentStep);
    final totalSteps = steps.length;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Text(
                '${_currentStep + 1}/$totalSteps',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71A4A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                visibleSteps[0]['name'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Color(0xFFB71A4A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (visibleSteps[0]['isOptional'] as bool)
                Text(
                  '(Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleInstruction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write the title of your task',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSampleInstruction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          'Example titles:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        Text(
          '• Fix my faucet\n• Create me a graphic\n• Fix my laptop',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _showPreviewTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${controller.jobTitleController.text}'),
            Text('Location: ${controller.jobLocationController.text}'),
            Text('Description: ${controller.jobDescriptionController.text}'),
            Text('Specialization: $selectedSpecialization'),
            Text(
                'Related Specializations: ${relatedSpecializations.join(', ')}'),
            Text('Work Type: $selectedWorkType'),
            Text('Scope: $selectedScope'),
            Text('Experience: $selectedExperience'),
            Text('Price: ${controller.contactPriceController.text}'),
            Text('Urgency: $selectedUrgency'),
            Text('Remarks: ${controller.jobRemarksController.text}'),
            if (_photo != null) ...[
              SizedBox(height: 8),
              Text('Photo: Uploaded'),
              SizedBox(height: 8),
              Image.file(_photo!, height: 100, fit: BoxFit.cover),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _submitJob(),
            child: Text('Post Task'),
          ),
        ],
      ),
    );
  }

  void _showAddress() async {
    final selectedAddress = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressList(),
      ),
    );
    if (selectedAddress != null) {
      setState(() {
        controller.jobLocationController.text =
            '${selectedAddress.city ?? ''}, ${selectedAddress.province ?? ''}';

        _addressID = selectedAddress.id ?? '';
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
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressBar(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      // Step 1: Title
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleInstruction(),
                            _buildTextField(
                              controller: controller.jobTitleController,
                              label: 'Task Title *',
                              hint: 'Enter task title',
                              errorText: _errors['task_title'],
                            ),
                            _buildSampleInstruction(),
                          ],
                        ),
                      ),
                      // Step 2: Location
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showAddress,
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: _errors['location'] != null
                                      ? BorderSide(color: Colors.red, width: 1)
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Task Location *',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              controller.jobLocationController
                                                      .text.isEmpty
                                                  ? 'Select an address'
                                                  : controller
                                                      .jobLocationController
                                                      .text,
                                              style: TextStyle(
                                                color: controller
                                                        .jobLocationController
                                                        .text
                                                        .isEmpty
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_errors['location'] != null)
                              Padding(
                                padding: EdgeInsets.only(top: 8, left: 16),
                                child: Text(
                                  _errors['location']!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Step 3: Description
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildTextField(
                          controller: controller.jobDescriptionController,
                          label: 'Task Description *',
                          hint: 'Describe your task...',
                          maxLines: 4,
                          errorText: _errors['task_description'],
                        ),
                      ),
                      // Step 4: Specialization
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildDropdownField(
                          value: selectedSpecialization,
                          items: selectedSpecializations.keys.toList(),
                          hint: 'Select Specialization *',
                          onChanged: (value) => setState(
                            () {
                              selectedSpecialization = value;
                              specializationId =
                                  selectedSpecializations[value!] ?? 0;
                            },
                          ),
                          errorText: _errors['specialization'],
                        ),
                      ),
                      // Step 5: Related Specializations
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildMultiSelectField(
                          selectedItems: relatedSpecializations,
                          items: selectedSpecializations.keys.toList(),
                          hint: 'Select Related Specializations *',
                          onChanged: (value) => setState(() {
                            relatedSpecializations = value;
                            relatedSpecializationsIds = value
                                .map((e) => selectedSpecializations[e]!)
                                .toList();
                          }),
                          errorText: _errors['related_specializations'],
                        ),
                      ),
                      // Step 6: Work Type
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildDropdownField(
                          value: selectedWorkType,
                          items: workTypes,
                          hint: 'Work Type *',
                          onChanged: (value) =>
                              setState(() => selectedWorkType = value),
                          errorText: _errors['work_type'],
                        ),
                      ),
                      // Step 7: Scope of Work
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildDropdownField(
                          value: selectedScope,
                          items: scopes,
                          hint: 'Scope of Work *',
                          onChanged: (value) =>
                              setState(() => selectedScope = value),
                          errorText: _errors['scope'],
                        ),
                      ),
                      // Step 8: Tasker Experience
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildDropdownField(
                          value: selectedExperience,
                          items: experienceLevels,
                          hint: 'Tasker Experience *',
                          onChanged: (value) =>
                              setState(() => selectedExperience = value),
                          errorText: _errors['experience'],
                        ),
                      ),
                      // Step 9: Project Price
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildTextField(
                          controller: controller.contactPriceController,
                          label: 'Fixed Price *',
                          hint: 'Enter price',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          errorText: _errors['contact_price'],
                        ),
                      ),
                      // Step 10: Urgency
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildDropdownField(
                          value: selectedUrgency,
                          items: urgency,
                          hint: 'Urgency *',
                          onChanged: (value) =>
                              setState(() => selectedUrgency = value),
                          errorText: _errors['urgency'],
                        ),
                      ),
                      // Step 11: Remarks
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildTextField(
                          controller: controller.jobRemarksController,
                          label: 'Remarks',
                          hint: 'Additional notes...',
                          maxLines: 3,
                        ),
                      ),
                      // Step 12: Photo
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildPhotoField(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        ElevatedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          if (!_showButton) {
                            _showWarningDialog();
                            return;
                          }
                          if (_currentStep < 11) {
                            if (_validateStep(_currentStep)) {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else {
                            if (_validateStep(_currentStep)) {
                              _showPreviewTask();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFB71A4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStep == 11 ? 'Preview' : 'Next',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
