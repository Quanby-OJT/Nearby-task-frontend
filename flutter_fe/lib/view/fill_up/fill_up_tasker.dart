import 'dart:io';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FillUpTasker extends StatefulWidget {
  final int userId;
  const FillUpTasker({super.key, required this.userId});

  @override
  State<FillUpTasker> createState() => _FillUpTaskerState();
}

class _FillUpTaskerState extends State<FillUpTasker> {
  int currentStep = 0;

  final ProfileController _controller = ProfileController();
  final JobPostService jobPostService = JobPostService();
  final GetStorage storage = GetStorage();
  final bool _isSuccess = false;
  File? _selectedFile; // Store the selected file
  String? _fileName; // Store the selected file name
  File? _selectedImage; // Store the selected image
  String? _imageName; // Store the selected image name
  String? selectedGender;

  String _firstname = '';
  String _lastname = '';
  String? _middlename = '';
  String _contact = '';
  String _role = '';
  String _image = '';
  String _birthday = '';
  bool _isLoading = true;
  bool _imagesChanged = false;
  String _wage = '';
  String _paySchedule = '';
  String _bio = '';
  String _skills = '';

  String? _imageNameID; // Store the selected ID image name
  String? _existingProfileImageUrl; // Store existing profile image URL
  String? _existingPDFUrl; // Store existing ID image URL
  final _generalFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _certsFormKey = GlobalKey<FormState>();

  List<String> genderOptions = [
    "Male",
    "Female",
    "Non-Binary",
    "I don't Want to Say"
  ];
  List<String> specialization = [];
  String? selectedSpecialization;
  List<String> taskerGroup = ["Solo Tasker", "Agency"];
  List<String> payPeriod = [
    "Hourly",
    "Daily",
    "Weekly",
    "Bi-Weekly",
    "Monthly"
  ];

  //TESDA Documents
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickImageProfile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Reduce image quality to save bandwidth
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageName = pickedFile.name;
        _imagesChanged = true;
        debugPrint(_imageName!);
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
      debugPrint("Fetched user data from the fill up task: ${user.toString()}");

      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        specialization =
            fetchedSpecializations.map((spec) => spec.specialization).toList();
      });

      if (user?.tasker != null) {
        debugPrint("Fetched user data in mt table : ${user.toString()}");
        setState(() {
          _firstname = user!.user.firstName;
          _lastname = user.user.lastName;
          _middlename = user.user.middleName;
          _role = user.user.role;
          _contact = user.user.contact ?? '';
          _wage = user.tasker!.wage.toString();
          _paySchedule = user.tasker!.payPeriod;
          _image = user.user.image?.toString() ?? '';
          _birthday = user.user.birthdate ?? '';
          _isLoading = false;
          selectedGender = user.user.gender;
          _bio = user.tasker!.bio;
          _skills = user.tasker!.skills;
          int index = int.tryParse(user.tasker!.specialization) ?? -1;

          // Check if the index is within bounds
          if (index >= 0 && index <= specialization.length) {
            selectedSpecialization =
                specialization[index - 1]; // Subtract 1 for zero-based index
          } else {
            selectedSpecialization = 'Not Found'; // Fallback value
          }

          _existingProfileImageUrl = user!.user.image?.toString() ?? '';

          // Update text controllers

          _controller.emailController.text = user.user.email;
          _controller.firstNameController.text = _firstname;
          _controller.middleNameController.text = _middlename ?? '';
          _controller.lastNameController.text = _lastname;
          _controller.roleController.text = _role;

          _controller.contactNumberController.text = _contact;
          _controller.imageController.text = _image;
          _controller.birthdateController.text = _birthday;
          _controller.genderController.text = selectedGender ?? '';
          _controller.wageController.text = _wage ?? '0.00';
          _controller.payPeriodController.text = _paySchedule;
          _controller.bioController.text = _bio;
          _controller.skillsController.text = _skills;
          _controller.specializationController.text =
              selectedSpecialization ?? '';

// Fetch Document Link for tasker
          final int documentId = user.tasker!.taskerDocuments ?? 0;
          _fetchDocumentLink(documentId);
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching specializations: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

// Fetch Document Link for tasker
  Future<void> _fetchDocumentLink(int documentId) async {
    try {
      final documentLink = await _controller.getDocumentLink(documentId);
      setState(() {
        _existingPDFUrl = documentLink;
      });
    } catch (error, stackTrace) {
      debugPrint('Error fetching document link: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> saveTaskerWithImages() async {
    // Validate birthdate

    try {
      int userId = int.parse(storage.read('user_id').toString());

      // Check if this is an update or a new creation
      if (_existingPDFUrl != null &&
          _existingProfileImageUrl != null &&
          !_imagesChanged) {
        // Update without changing images
        await updateTaskerWithoutImages(userId);
      } else if (_selectedFile != null && _selectedImage != null) {
        // Create new with images
        await _controller.createTasker(
          context,
          userId,
          _selectedFile!,
          _selectedImage!,
        );
      } else if (_existingPDFUrl != null && _existingProfileImageUrl != null) {
        // Create without images (using existing URLs)
        await _controller.createTaskerNoImages(
          context,
          userId,
        );
      } else {
        // Images are required for new tasker profiles
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload both a profile image and a document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateTaskerWithoutImages(int userId) async {
    try {
      // Create user model with current data
      UserModel user = UserModel(
        id: userId,
        firstName: _controller.firstNameController.text,
        middleName: _controller.middleNameController.text.isNotEmpty
            ? _controller.middleNameController.text
            : null,
        lastName: _controller.lastNameController.text,
        email: _controller.emailController.text,
        role: _controller.roleController.text,
        birthdate: _controller.birthdateController.text,
        contact: _controller.contactNumberController.text,
        gender: _controller.genderController.text,
        image: _existingProfileImageUrl,
      );

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Call API service to update tasker profile without images
      Map<String, dynamic> result =
          await _controller.updateTaskerNoImages(context, user);

      // Close loading indicator
      Navigator.pop(context);

      if (result.containsKey("errors")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["errors"] ??
                "Failed to update profile. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home page or refresh the current page
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Complete your service account',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: const Color(0xFF0272B1),
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
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
                          ColorScheme.light(primary: Color(0xFF0272B1))),
                  child: Stepper(
                    type: StepperType.horizontal,
                    steps: getSteps(),
                    currentStep: currentStep,
                    onStepContinue: () {
                      final isLastStep = currentStep == getSteps().length - 1;

                      if (isLastStep) {
                        saveTaskerWithImages();
                      } else {
                        setState(() {
                          currentStep += 1;
                        });
                      }
                    },
                    onStepTapped: (step) => setState(() => currentStep = step),
                    onStepCancel: () {
                      currentStep == 0
                          ? null
                          : setState(() {
                              currentStep -= 1;
                            });
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: details.onStepCancel,
                              child: Text(
                                'Back',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0272B1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
        ));
  }

  List<Step> getSteps() => [
        // Step 0: General
        Step(
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 0,
          title: const Text('General'),
          content: Form(
            key: _generalFormKey, // Form key for validation
            child: Column(
              children: [
                // Wage
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
                        borderSide: const BorderSide(
                            color: Colors.transparent, width: 0),
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
                  ),
                ),
                // Pay Period
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
                          color: Color(0xFF0272B1),
                          width: 2,
                        ),
                      ),
                    ),
                    value: _controller.payPeriodController.text.isNotEmpty
                        ? _controller.payPeriodController.text
                        : null,
                    items: payPeriod.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _controller.payPeriodController.text = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a pay period';
                      }
                      return null;
                    },
                  ),
                ),
                // Gender
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
                          color: Color(0xFF0272B1),
                          width: 2,
                        ),
                      ),
                    ),
                    value: selectedGender,
                    items: genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGender = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a gender' : null,
                  ),
                ),
                // Contact Number
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.contactNumberController,
                    cursorColor: const Color(0xFF0272B1),
                    validator: (value) =>
                        _controller.validateContactNumber(value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Contact Number',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Colors.transparent, width: 0),
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
                  ),
                ),

                // Birthdate
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
                      labelStyle: const TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: const Color(0xFFF1F4FF),
                      hintText: 'Birth date',
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: Color(0xFF0272B1)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Colors.transparent, width: 0),
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
                  ),
                ),
              ],
            ),
          ),
        ),
        // Step 1: Profile
        Step(
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 1,
          title: const Text('Profile'),
          content: Form(
            key: _profileFormKey, // Form key for validation
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
                            'Choose a profile picture',
                            style: GoogleFonts.openSans(
                              fontSize: 20,
                              color: const Color(0xFF0272B1),
                            ),
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
                                offset: const Offset(0, 2),
                              ),
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
                                      offset: const Offset(0, 4),
                                    ),
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
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(Icons.person,
                                                      size: 80,
                                                      color: Colors.grey),
                                                );
                                              },
                                            )
                                          : const Center(
                                              child: Icon(Icons.person,
                                                  size: 80, color: Colors.grey),
                                            ),
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              if (_imageName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    "Name: ${_imageName ?? ''}",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Bio
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
                        borderSide: const BorderSide(
                            color: Colors.transparent, width: 0),
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
                // Skills
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
                        borderSide: const BorderSide(
                            color: Colors.transparent, width: 0),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
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
                    items: specialization.map((String spec) {
                      return DropdownMenuItem<String>(
                        value: spec,
                        child: Text(
                          spec,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedSpecialization = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a specialization' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Step 2: Certs
        Step(
          isActive: currentStep >= 2,
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
                        color: const Color(0xFF0272B1),
                      ),
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
                          offset: const Offset(0, 2),
                        ),
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
                              color: const Color(0xFF0272B1),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _selectedFile != null
                              ? const Icon(Icons.picture_as_pdf,
                                  size: 80, color: Colors.red)
                              : _existingPDFUrl != null &&
                                      _existingPDFUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _existingPDFUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Icon(Icons.insert_drive_file,
                                                size: 80, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.insert_drive_file,
                                      size: 80, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.upload_file,
                              color: Colors.white),
                          label: const Text("Select PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0272B1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (_fileName != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            "Selected File: $_fileName",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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
