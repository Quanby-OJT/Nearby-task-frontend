import 'dart:io';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/view/view_pdf/PDF_viewer.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FillUpTaskerLogin extends StatefulWidget {
  final int userId;
  const FillUpTaskerLogin({super.key, required this.userId});

  @override
  State<FillUpTaskerLogin> createState() => _FillUpTaskerLoginState();
}

class _FillUpTaskerLoginState extends State<FillUpTaskerLogin> {
  int currentStep = 0;

  // Completion flags for each step
  bool _isGeneralComplete = false;
  bool _isProfileComplete = false;
  bool _isCertsComplete = false;
  bool _isAddressComplete = false;

  final ProfileController _controller = ProfileController();
  final JobPostService jobPostService = JobPostService();
  final GetStorage storage = GetStorage();
  File? _selectedFile;
  String? _fileName;
  File? _selectedImage;
  String? _imageName;
  String? selectedGender;
  int _specializationId = 0;
  bool _documentValid = false;
  String _firstname = '';
  String _lastname = '';
  String? _middlename = '';
  String _contact = '';
  String _role = '';
  String _image = '';
  String _birthday = '';
  bool _isLoading = true;
  bool _imagesChanged = false;
  bool _pdfChanged = false;
  String _wage = '';
  String _paySchedule = '';
  String _bio = '';
  String _skills = '';
  bool _group = false;
  bool _available = false;

  String? _existingProfileImageUrl;
  String? _existingPDFUrl;
  final _generalFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _certsFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> groupTasker = ['Solo', 'Group'];
  List<String> specialization = [];
  String? selectedSpecialization;
  List<String> payPeriod = [
    "Hourly",
    "Daily",
    "Weekly",
    "Bi-Weekly",
    "Monthly"
  ];

  // Check if all conditions are met to mark all steps as complete
  bool get _allConditionsMet {
    return _generalFormKey.currentState?.validate() == true &&
        _profileFormKey.currentState?.validate() == true &&
        (_existingProfileImageUrl != null || _selectedImage != null) &&
        (_existingPDFUrl != null || _selectedFile != null) &&
        _isAddressComplete &&
        _documentValid;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        if (file.extension?.toLowerCase() == 'pdf') {
          setState(() {
            _selectedFile = File(file.path!);
            _fileName = file.name;
            _pdfChanged = true;
            // Temporarily set document as invalid until validated by backend
            _documentValid = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF file selected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a PDF file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageProfile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageName = pickedFile.name;
        _imagesChanged = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSpecialization();
  }

  Future<void> fetchSpecialization() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());
      AuthenticatedUser? user =
          await _controller.getAuthenticatedUser(context, userId);
      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        specialization =
            fetchedSpecializations.map((spec) => spec.specialization).toList();
      });

      if (user?.tasker != null) {
        setState(() {
          _firstname = user!.user.firstName;
          _lastname = user.user.lastName;
          _middlename = user.user.middleName;
          _group = user.tasker!.group ?? false;
          _available = user.tasker!.availability ?? false;

          _role = user.user.role;
          _contact = user.user.contact ?? '';
          _wage = user.tasker!.wage.toString();
          _paySchedule = user.tasker!.payPeriod;
          _image = user.user.image?.toString() ?? '';
          _birthday = user.user.birthdate ?? '';
          _isLoading = false;
          selectedGender = genderOptions.contains(user.user.gender)
              ? user.user.gender
              : 'Other';
          _bio = user.tasker!.bio;
          _skills = user.tasker!.skills;
          String userSpec = user.tasker!.specialization;
          selectedSpecialization =
              specialization.contains(userSpec) ? userSpec : null;
          _specializationId = specialization.indexOf(userSpec) + 1;
          _controller.specializationIdController.text =
              _specializationId.toString();
          _existingProfileImageUrl = user.user.image?.toString() ?? '';
          _controller.emailController.text = user.user.email;
          _controller.firstNameController.text = _firstname;
          _controller.middleNameController.text = _middlename ?? '';
          _controller.lastNameController.text = _lastname;
          _controller.roleController.text = _role;
          _controller.contactNumberController.text = _contact;
          _controller.imageController.text = _image;
          _controller.birthdateController.text = _birthday;
          _controller.genderController.text = selectedGender ?? '';
          _controller.wageController.text = _wage;
          _controller.payPeriodController.text = _paySchedule;
          _controller.bioController.text = _bio;
          _controller.skillsController.text = _skills;
          _controller.specializationController.text =
              selectedSpecialization ?? '';

          _controller.taskerGroupController.text = _group ? 'Group' : 'Solo';
          _controller.availabilityController.text =
              _available ? 'true' : 'false';

          _controller.streetAddressController.text =
              user.tasker?.address?['street_address'] ?? '';
          _controller.barangayController.text =
              user.tasker?.address?['barangay'] ?? '';
          _controller.cityController.text = user.tasker?.address?['city'] ?? '';
          _controller.provinceController.text =
              user.tasker?.address?['province'] ?? '';
          _controller.postalCodeController.text =
              user.tasker?.address?['postal_code'] ?? '';
          _controller.countryController.text =
              user.tasker?.address?['country'] ?? '';

          _fetchDocumentLink(user.tasker!.id);
        });
      }
    } catch (error) {
      debugPrint('Error fetching specializations: $error');
    }
  }

  Future<void> _fetchDocumentLink(int taskerId) async {
    try {
      final response = await _controller.getDocumentLink(taskerId);
      debugPrint('Document link response: ${response?.valid}');

      if (response == null) {
        debugPrint('Document link response is null');
        setState(() {
          _existingPDFUrl = null;
          _documentValid = false;
        });
        return;
      }

      setState(() {
        _existingPDFUrl = response.tesdaDocumentLink;
        _documentValid = response.valid ?? false;
      });
    } catch (error) {
      debugPrint('Error fetching document link: $error');
      setState(() {
        _existingPDFUrl = null;
        _documentValid = false;
      });
    }
  }

  Future<void> saveTaskerWithImages() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());

      // Check if either file needs to be uploaded
      if (_selectedFile != null || _selectedImage != null) {
        // Show loading indicator
        setState(() => _isLoading = true);

        await _controller.updateTaskerInfo(
          context,
          userId,
          _selectedFile, // Pass as nullable
          _selectedImage, // Pass as nullable
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Files uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading files: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Complete your tasker account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF0272B1),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 80, right: 80, top: 10, bottom: 10),
                  child: Text(
                    textAlign: TextAlign.center,
                    "Provide service right away, create an account now!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                SizedBox(
                  height: 550,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme:
                          ColorScheme.light(primary: Color(0xFF0272B1)),
                    ),
                    child: Stepper(
                      type: StepperType.horizontal,
                      steps: getSteps(),
                      currentStep: currentStep,
                      onStepContinue: () {
                        if (currentStep == 0) {
                          if (_generalFormKey.currentState!.validate() &&
                              (_selectedImage != null)) {
                            setState(() {
                              _isGeneralComplete = true;
                              currentStep += 1;
                            });
                          }
                        } else if (currentStep == 1) {
                          if (_profileFormKey.currentState!.validate() &&
                              (_selectedImage != null ||
                                  _existingProfileImageUrl != null)) {
                            setState(() {
                              _isProfileComplete = true;
                              currentStep += 1;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Please select a profile picture')),
                            );
                          }
                        } else if (currentStep == 2) {
                          // Address step validation
                          if (_addressFormKey.currentState!.validate() &&
                              _controller
                                  .streetAddressController.text.isNotEmpty &&
                              _controller.barangayController.text.isNotEmpty &&
                              _controller.cityController.text.isNotEmpty &&
                              _controller.provinceController.text.isNotEmpty &&
                              _controller
                                  .postalCodeController.text.isNotEmpty &&
                              _controller.countryController.text.isNotEmpty) {
                            setState(() {
                              _isAddressComplete = true;
                              currentStep += 1;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Please complete address fields')),
                            );
                          }
                        } else if (currentStep == 3) {
                          if (_documentValid || _selectedFile != null) {
                            setState(() {
                              _isCertsComplete = true;
                            });
                            saveTaskerWithImages();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Please upload a PDF document')),
                            );
                          }
                        }
                      },
                      onStepTapped: (step) =>
                          setState(() => currentStep = step),
                      onStepCancel: () {
                        if (currentStep > 0) {
                          setState(() => currentStep -= 1);
                        }
                      },
                      controlsBuilder:
                          (BuildContext context, ControlsDetails details) {
                        final isLastStep = currentStep == getSteps().length - 1;
                        return Row(
                          children: [
                            if (currentStep != 0)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0272B1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: details.onStepCancel,
                                child: Text('Back',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0272B1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: details.onStepContinue,
                              child: isLastStep
                                  ? const Text('Submit',
                                      style: TextStyle(color: Colors.white))
                                  : const Text('Next',
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  List<Step> getSteps() => [
        Step(
          state: _allConditionsMet || _isGeneralComplete
              ? StepState.complete
              : StepState.indexed,
          isActive: currentStep >= 0,
          title: const Text('Profile'),
          content: Form(
            key: _generalFormKey,
            child: Column(
              children: [
                if (_selectedImage != null || _existingProfileImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            'Select a profile picture',
                            style: GoogleFonts.openSans(
                                fontSize: 20, color: const Color(0xFF0272B1)),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                      color: const Color(0xFF0272B1), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: _selectedImage != null
                                      ? Image.file(_selectedImage!,
                                          fit: BoxFit.cover)
                                      : _existingProfileImageUrl != null &&
                                              _existingProfileImageUrl!
                                                  .isNotEmpty
                                          ? Image.network(
                                              _existingProfileImageUrl!,
                                              fit: BoxFit.cover)
                                          : const Center(
                                              child: Icon(Icons.person,
                                                  size: 80,
                                                  color: Colors.grey)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _pickImageProfile,
                                icon:
                                    const Icon(Icons.edit, color: Colors.white),
                                label: const Text("Change Profile"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0272B1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (_imageName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text("Name: $_imageName",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.firstNameController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        _controller.validateName(value, "First Name"),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'First Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.lastNameController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        _controller.validateName(value, "Last Name"),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Last Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.middleNameController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter middle name'
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Middle Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.emailController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) => _controller.validateEmail(value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Select Your Gender...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    value: selectedGender,
                    items: genderOptions
                        .map((String gender) => DropdownMenuItem<String>(
                            value: gender, child: Text(gender)))
                        .toList(),
                    onChanged: (String? newValue) => setState(() {
                      selectedGender = newValue;
                      _controller.genderController.text = newValue!;
                    }),
                    validator: (value) =>
                        value == null ? 'Please select a gender' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.contactNumberController,
                    cursorColor: const Color(0xFF0272B1),
                    validator: _controller.validateContactNumber,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Contact Number',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controller.birthdateController,
                    keyboardType: TextInputType.datetime,
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        String formattedDate =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        _controller.birthdateController.text = formattedDate;
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Birth date',
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: Color(0xFF0272B1)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tasker
        Step(
          state: _allConditionsMet || _isProfileComplete
              ? StepState.complete
              : StepState.indexed,
          isActive: currentStep >= 1,
          title: const Text('Tasker'),
          content: Form(
            key: _profileFormKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<String>(
                    value: _controller.taskerGroupController.text.isNotEmpty
                        ? _controller.taskerGroupController.text
                        : null,
                    onChanged: (String? newValue) => setState(() {
                      _controller.taskerGroupController.text = newValue!;
                    }),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Select Group *',
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    items: groupTasker
                        .map((String spec) => DropdownMenuItem<String>(
                            value: spec,
                            child: Text(spec, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Please select a group' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _controller.wageController,
                    cursorColor: const Color(0xFF0272B1),
                    validator: (value) => value!.isEmpty
                        ? "Please Indicate Your Desired Wage"
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'How Much Would You Want to be Paid?',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'How do you want to be paid?',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    value: _controller.payPeriodController.text.isNotEmpty
                        ? _controller.payPeriodController.text
                        : null,
                    items: payPeriod
                        .map((String period) => DropdownMenuItem<String>(
                            value: period, child: Text(period)))
                        .toList(),
                    onChanged: (String? newValue) => setState(
                        () => _controller.payPeriodController.text = newValue!),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please select a pay period'
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<bool>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Availability?',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF0272B1),
                          width: 2,
                        ),
                      ),
                    ),
                    value: _controller.availabilityController.text == 'true'
                        ? true
                        : _controller.availabilityController.text == 'false'
                            ? false
                            : null,
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: Text("I'm available"),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text("I'm not available"),
                      ),
                    ],
                    onChanged: (bool? newValue) {
                      setState(() {
                        _controller.availabilityController.text =
                            newValue.toString();
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select availability' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: TextFormField(
                    maxLines: 2,
                    controller: _controller.bioController,
                    cursorColor: const Color(0xFF0272B1),
                    validator: (value) => value!.isEmpty
                        ? "Indicate Your desired description."
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'How do you describe yourself as a Worker?',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    maxLines: 3,
                    controller: _controller.skillsController,
                    cursorColor: const Color(0xFF0272B1),
                    validator: (value) =>
                        value!.isEmpty ? "List of skills..." : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText:
                          'Enumerate what Skills Do you possessed at this moment.',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<String>(
                    value: selectedSpecialization,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Select Tasker Specialization *',
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    items: specialization
                        .map((String spec) => DropdownMenuItem<String>(
                            value: spec,
                            child: Text(spec, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (newValue) => setState(() {
                      selectedSpecialization = newValue;
                      _specializationId = specialization.indexOf(newValue!) + 1;
                      _controller.specializationIdController.text =
                          _specializationId.toString();
                    }),
                    validator: (value) =>
                        value == null ? 'Please select a specialization' : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Address
        Step(
          state: _allConditionsMet || _isAddressComplete
              ? StepState.complete
              : StepState.indexed,
          isActive: currentStep >= 2,
          title: const Text('Address'),
          content: Form(
            key: _addressFormKey,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controller.streetAddressController,
                  cursorColor: const Color(0xFF0272B1),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a street address'
                      : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F4FF),
                    hintText: 'Street Address',
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF0272B1), width: 2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controller.barangayController,
                  cursorColor: const Color(0xFF0272B1),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a barangay'
                      : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F4FF),
                    hintText: 'Barangay',
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF0272B1), width: 2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controller.cityController,
                  cursorColor: const Color(0xFF0272B1),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a city'
                      : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F4FF),
                    hintText: 'City/Municipality',
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF0272B1), width: 2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controller.provinceController,
                  cursorColor: const Color(0xFF0272B1),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a province'
                      : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F4FF),
                    hintText: 'Province',
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF0272B1), width: 2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controller.postalCodeController,
                  cursorColor: const Color(0xFF0272B1),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a postal code'
                      : null,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F4FF),
                    hintText: 'Postal Code',
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF0272B1), width: 2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _controller.countryController,
                  cursorColor: const Color(0xFF0272B1),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a country'
                      : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F4FF),
                    hintText: 'Country',
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF0272B1), width: 2),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        // Certs
        Step(
          state: _allConditionsMet || _isCertsComplete
              ? StepState.complete
              : StepState.indexed,
          isActive: currentStep >= 3,
          title: const Text('Certs'),
          content: Form(
            key: _certsFormKey,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Upload a PDF File',
                      style: GoogleFonts.openSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0272B1)),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF0272B1), width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: _selectedFile != null
                              ? const Icon(Icons.picture_as_pdf,
                                  size: 80, color: Colors.red)
                              : _existingPDFUrl != null &&
                                      _existingPDFUrl!.isNotEmpty
                                  ? const Icon(Icons.picture_as_pdf,
                                      size: 80, color: Colors.red)
                                  : const Icon(Icons.insert_drive_file,
                                      size: 80, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pdfChanged
                              ? 'Wait for 10 minutes to validate your document'
                              : _documentValid
                                  ? 'Your document has been validated'
                                  : 'Your document has not been validated',
                          style: TextStyle(
                            color: _pdfChanged
                                ? Colors.red[600]
                                : _documentValid
                                    ? Colors.green[600]
                                    : Colors.red[600],
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _documentValid ? null : _pickFile,
                          icon: const Icon(Icons.upload_file,
                              color: Colors.white),
                          label: const Text("Select PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0272B1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (_fileName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text("Selected File: $_fileName",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
}
