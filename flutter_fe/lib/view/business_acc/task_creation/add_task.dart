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
import 'package:flutter_fe/view/address/address_list.dart';
import 'package:flutter_fe/view/business_acc/task_creation/preview_task.dart';
import 'package:flutter_fe/view/business_acc/task_creation/select_related_spec.dart';
import 'package:flutter_fe/view/business_acc/task_creation/select_spec.dart';
import 'package:flutter_fe/view/custom_loading/custom_scaffold.dart';
import 'package:flutter_fe/view/verification/verification_page.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final ScrollController _scrollController = ScrollController();

  String? _message;
  String? selectedTimePeriod;
  String? selectedUrgency = "Non-Urgent";
  String? selectedSpecialization;
  String? selectedWorkType = "Solo";
  String? selectedScope = "Less than a month";
  List<String> relatedSpecializations = [];
  List<String> relatedSpecializationsIds = [];
  List<File> _photos = [];
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
  final bool _isVerifiedDocument = false;

  @override
  void initState() {
    super.initState();
    fetchSpecializations();
    _fetchUserIDImage();
    if (selectedScope == null && scopes.isNotEmpty) {
      setState(() {
        selectedScope = scopes[0];
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
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
      debugPrint('add task verification: $response');

      // Check if user has Review or Active status
      final userAccStatus = user?.user.accStatus;
      final isStatusAllowed =
          userAccStatus == 'Review' || userAccStatus == 'Active';

      if (response['success']) {
        setState(() {
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = response['url'];
          _documentValid = response['status'];
          _isLoading = false;
          _showButton = true;
        });
      } else {
        debugPrint('Failed to fetch user ID image: ${response['message']}');
        setState(() {
          _existingProfileImageUrl = user?.user.image;
          _existingIDImageUrl = null;
          _documentValid = false;
          _isLoading = false;
          // Allow task creation if user status is Review or Active
          _showButton = isStatusAllowed;
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
                MaterialPageRoute(
                    builder: (context) => const VerificationPage()),
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
      case 0:
        if (controller.jobTitleController.text.trim().isEmpty) {
          _errors['task_title'] = 'Please indicate your needed task';
          return false;
        }
        if (controller.jobDescriptionController.text.trim().isEmpty) {
          _errors['task_description'] = 'Please elaborate your task';
          return false;
        }
        if (controller.jobLocationController.text.trim().isEmpty) {
          _errors['location'] = 'Please indicate the task location';
          return false;
        }
        break;
      case 1:
        if (selectedSpecialization == null || specializationId == null) {
          _errors['specialization'] = 'Please select a specialization';
          return false;
        }
        if (relatedSpecializations.isEmpty) {
          _errors['related_specializations'] =
              'Please select at least one related specialization';
          return false;
        }
        if (selectedWorkType == null) {
          _errors['work_type'] = 'Please select a work type';
          return false;
        }
        break;
      case 2:
        if (selectedScope == null || !scopes.contains(selectedScope)) {
          _errors['scope'] = 'Please select a valid scope of work';
          return false;
        }
        if (controller.jobStartDateController.text.isEmpty) {
          _errors['start_date'] = 'Please select the start date';
          return false;
        }
        break;
      case 3:
        String price = controller.contactPriceController.text.trim();
        if (price.isEmpty) {
          _errors['contact_price'] = 'Please indicate the contract price';
          return false;
        } else if (int.tryParse(price) == null || int.parse(price) <= 0) {
          _errors['contact_price'] =
              'Contract price must be a valid positive number';
          return false;
        }
        if (selectedUrgency == null) {
          _errors['urgency'] = 'Please indicate if the task is urgent';
          return false;
        }
        break;
      case 4:
        return true;
    }
    return true;
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: controller.jobStartDateController.text.isNotEmpty
          ? DateTime.parse(
              controller.jobStartDateController.text.split(' ').first)
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFB71A4A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFB71A4A),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: controller.jobStartDateController.text.isNotEmpty
            ? TimeOfDay.fromDateTime(
                DateTime.parse(controller.jobStartDateController.text))
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFFB71A4A),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFFB71A4A),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          controller.jobStartDateController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
        });
      }
    }
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

    try {
      final result = await controller.postJob(
        selectedSpecialization ?? "",
        selectedUrgency ?? "",
        selectedScope ?? "",
        selectedWorkType ?? "",
        relatedSpecializationsIds: relatedSpecializationsIds,
        isVerifiedDocument: _isVerifiedDocument,
        photos: _photos,
        specializationId: specializationId,
        addressId: _addressID,
      );

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
          relatedSpecializations = [];
          relatedSpecializationsIds = [];
          _photos = [];
          specializationId = null;
        });

        CustomScaffold(message: _message!, color: Colors.green);
        Navigator.pop(context);
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

        CustomScaffold(message: _message!, color: Colors.red);
        Navigator.pop(context);
      }
    } catch (error) {
      debugPrint("Error submitting job: $error");
      CustomScaffold(
          message: 'An error occurred. Please try again.', color: Colors.red);
      Navigator.pop(context);
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
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
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
            suffixIcon: controller.text.isNotEmpty && errorText == null
                ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                : null,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          style: GoogleFonts.poppins(fontSize: 12),
          onChanged: (_) => setState(() {}),
          onTap: () {
            Future.delayed(Duration(milliseconds: 200), () {});
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    String? errorText,
    bool isRequired = false,
  }) {
    final effectiveItems = items ?? [];
    final effectiveValue = value != null && effectiveItems.contains(value)
        ? value
        : effectiveItems.isNotEmpty
            ? effectiveItems[0]
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$hint *' : hint,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: effectiveValue,
          decoration: InputDecoration(
            hintText: effectiveItems.isEmpty ? 'No options available' : hint,
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
            suffixIcon: effectiveValue != null && errorText == null
                ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                : null,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        ),
      ],
    );
  }

  Widget _buildMultiSelectField({
    required List<String> selectedItems,
    required List<String> items,
    required String hint,
    required Function(List<String>) onChanged,
    String? errorText,
    required bool isRequired,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SelectRelatedSpec()),
        );
        if (result != null && result is List<String>) {
          onChanged(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: errorText != null ? Colors.red : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedItems.isEmpty ? hint : selectedItems.join(', '),
                style: GoogleFonts.poppins(
                  color: selectedItems.isEmpty ? Colors.grey : Colors.black,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoField() {
    const int maxPhotos = 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Photos (Optional, up to $maxPhotos)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        _photos.isEmpty
            ? GestureDetector(
                onTap: () async {
                  final List<XFile> images = await _picker.pickMultiImage(
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  setState(() {
                    _photos = images
                        .map((image) => File(image.path))
                        .take(maxPhotos - _photos.length)
                        .toList();
                  });
                },
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      'Tap to upload photos',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._photos.asMap().entries.map((entry) {
                    int index = entry.key;
                    File photo = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              photo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photos.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_photos.length < maxPhotos)
                    GestureDetector(
                      onTap: () async {
                        final List<XFile> images = await _picker.pickMultiImage(
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 80,
                        );
                        setState(() {
                          _photos.addAll(
                            images
                                .map((image) => File(image.path))
                                .take(maxPhotos - _photos.length),
                          );
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.grey[600],
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final steps = [
      {
        'name': 'Task Basics',
        'tooltip': 'Enter title, description, and location',
        'isOptional': false
      },
      {
        'name': 'Task Details',
        'tooltip': 'Specify specialization, related skills, and work type',
        'isOptional': false
      },
      {
        'name': 'Task Timeline',
        'tooltip': 'Define scope and start date',
        'isOptional': false
      },
      {
        'name': 'Budget & Urgency',
        'tooltip': 'Set price and urgency',
        'isOptional': false
      },
      {
        'name': 'Additional Info',
        'tooltip': 'Add remarks and photos (optional)',
        'isOptional': true
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Text(
            '${_currentStep + 1} / ${steps.length}\n${steps[_currentStep]['name']}',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Color(0xFFB71A4A),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (steps[_currentStep]['isOptional'] as bool)
            Text(
              '(Optional)',
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildTitleInstruction(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSelectSpecialization({
    required String? value,
    required String hint,
    required Function(String?) onChanged,
    String? errorText,
    required bool isRequired,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SelectSpec()),
        );
        if (result != null && result is String) {
          onChanged(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: errorText != null ? Colors.red : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: GoogleFonts.poppins(
                  color: value != null ? Colors.black : Colors.grey,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
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
        controller.jobLocationController
            .text = selectedAddress.formattedAddress != null &&
                selectedAddress.formattedAddress!.isNotEmpty
            ? selectedAddress.formattedAddress!
            : '${selectedAddress.city ?? ''}, ${selectedAddress.province ?? ''}';
        _addressID = selectedAddress.id ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: false, // Prevent automatic resizing
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Create Task',
          style: GoogleFonts.poppins(
            color: Color(0xFFB71A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB71A4A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProgressBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            kToolbarHeight -
                            100, // Adjust for appbar and progress bar
                        child: PageView(
                          controller: _pageController,
                          physics: NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _currentStep = index;
                            });
                          },
                          children: [
                            // Step 1: Task Basics
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTitleInstruction(
                                          'Task Basics',
                                          'Provide the core details of your task',
                                        ),
                                        _buildTextField(
                                          controller:
                                              controller.jobTitleController,
                                          label: 'Title',
                                          hint: 'Enter task title',
                                          errorText: _errors['task_title'],
                                          isRequired: true,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Location *',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: _showAddress,
                                          child: Card(
                                            elevation: 0,
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: _errors['location'] != null
                                                  ? BorderSide(
                                                      color: Colors.red,
                                                      width: 1)
                                                  : BorderSide.none,
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      controller
                                                              .jobLocationController
                                                              .text
                                                              .isEmpty
                                                          ? 'Select an address'
                                                          : controller
                                                              .jobLocationController
                                                              .text,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        color: controller
                                                                .jobLocationController
                                                                .text
                                                                .isEmpty
                                                            ? Colors.grey
                                                            : Colors.black,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                            padding: EdgeInsets.only(
                                                top: 8, left: 16),
                                            child: Text(
                                              _errors['location']!,
                                              style: GoogleFonts.poppins(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        SizedBox(height: 16),
                                        _buildTextField(
                                          controller: controller
                                              .jobDescriptionController,
                                          label: 'Description',
                                          hint: 'Describe your task...',
                                          maxLines: 4,
                                          errorText:
                                              _errors['task_description'],
                                          isRequired: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Step 2: Task Details
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTitleInstruction(
                                          'Details',
                                          'Specify the skills and work type needed',
                                        ),
                                        _buildSelectSpecialization(
                                          value: selectedSpecialization,
                                          hint: 'Select Specialization',
                                          onChanged: (value) => setState(() {
                                            selectedSpecialization = value;
                                            specializationId =
                                                selectedSpecializations[
                                                        value!] ??
                                                    0;
                                          }),
                                          errorText: _errors['specialization'],
                                          isRequired: true,
                                        ),
                                        SizedBox(height: 16),
                                        _buildMultiSelectField(
                                          selectedItems: relatedSpecializations,
                                          items: selectedSpecializations.keys
                                              .toList(),
                                          hint:
                                              'Select Related Specializations',
                                          onChanged: (value) => setState(() {
                                            relatedSpecializations = value;
                                            relatedSpecializationsIds = value
                                                .map((e) =>
                                                    selectedSpecializations[e]!
                                                        .toString())
                                                .toList();
                                          }),
                                          errorText: _errors[
                                              'related_specializations'],
                                          isRequired: true,
                                        ),
                                        SizedBox(height: 16),
                                        _buildDropdownField(
                                          value: selectedWorkType,
                                          items: workTypes,
                                          hint: 'Work Type',
                                          onChanged: (value) => setState(
                                              () => selectedWorkType = value),
                                          errorText: _errors['work_type'],
                                          isRequired: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Step 3: Task Timeline
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTitleInstruction(
                                          'Timeline',
                                          'Define the duration and start date',
                                        ),
                                        _buildDropdownField(
                                          value: selectedScope,
                                          items: scopes,
                                          hint: 'Scope of Work',
                                          onChanged: (value) => setState(
                                              () => selectedScope = value),
                                          errorText: _errors['scope'],
                                          isRequired: true,
                                        ),
                                        SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: _selectDateTime,
                                          child: AbsorbPointer(
                                            child: _buildTextField(
                                              controller: controller
                                                  .jobStartDateController,
                                              label: 'Start Date',
                                              hint:
                                                  'Select start date and time',
                                              errorText: _errors['start_date'],
                                              isRequired: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Step 4: Budget & Urgency
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTitleInstruction(
                                          'Budget & Urgency',
                                          'Set the price and urgency level',
                                        ),
                                        _buildTextField(
                                          controller:
                                              controller.contactPriceController,
                                          label: 'Fixed Price',
                                          hint: 'Enter price',
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          errorText: _errors['contact_price'],
                                          isRequired: true,
                                        ),
                                        SizedBox(height: 16),
                                        _buildDropdownField(
                                          value: selectedUrgency,
                                          items: urgency,
                                          hint: 'Urgency',
                                          onChanged: (value) => setState(
                                              () => selectedUrgency = value),
                                          errorText: _errors['urgency'],
                                          isRequired: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Step 5: Additional Info
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTitleInstruction(
                                          'Additional Info',
                                          'Add optional remarks and photos',
                                        ),
                                        _buildTextField(
                                          controller:
                                              controller.jobRemarksController,
                                          label: 'Remarks',
                                          hint: 'Additional notes...',
                                          maxLines: 3,
                                        ),
                                        SizedBox(height: 16),
                                        _buildPhotoField(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: ElevatedButton(
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
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Back',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        if (_currentStep > 0) SizedBox(width: 8),
                        if (_currentStep == 4)
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PreviewTask(
                                      controller: controller,
                                      selectedSpecialization:
                                          selectedSpecialization,
                                      selectedUrgency: selectedUrgency,
                                      selectedWorkType: selectedWorkType,
                                      selectedScope: selectedScope,
                                      relatedSpecializations:
                                          relatedSpecializations,
                                      photos: _photos,
                                      onSubmit: _submitJob,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Skip & Preview',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        if (_currentStep == 4) SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (!_showButton) {
                                _showWarningDialog();
                                return;
                              }
                              if (_currentStep < 4) {
                                if (_validateStep(_currentStep)) {
                                  _pageController.nextPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              } else {
                                if (_validateStep(_currentStep)) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PreviewTask(
                                        controller: controller,
                                        selectedSpecialization:
                                            selectedSpecialization,
                                        selectedUrgency: selectedUrgency,
                                        selectedWorkType: selectedWorkType,
                                        selectedScope: selectedScope,
                                        relatedSpecializations:
                                            relatedSpecializations,
                                        photos: _photos,
                                        onSubmit: _submitJob,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFB71A4A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child: Text(
                              _currentStep == 4 ? 'Preview' : 'Save & Continue',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
