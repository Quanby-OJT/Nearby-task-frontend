import 'dart:io';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
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

  File? _selectedImageID; // Store the selected ID image
  String? _imageNameID; // Store the selected ID image name
  String? _existingProfileImageUrl; // Store existing profile image URL
  String? _existingIDImageUrl; // Store existing ID image URL
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile =
            File(result.files.single.path!); // Store the selected file
        _fileName = result.files.single.name; // Store file name
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
      debugPrint("Fetched user data: ${user.toString()}");

      List<SpecializationModel> fetchedSpecializations =
          await jobPostService.getSpecializations();

      setState(() {
        specialization =
            fetchedSpecializations.map((spec) => spec.specialization).toList();
      });

      if (user?.tasker != null) {
        debugPrint("Fetched user data in mt table : ${user.toString()}");
        setState(() {
          _role = user!.user.role ?? 'Tasker';
          _contact = user!.user.contact ?? '';
          _wage = user.tasker!.wage.toString();
          _paySchedule = user.tasker!.payPeriod;
          _image = user!.user.image?.toString() ?? '';
          _birthday = user.user.birthdate ?? '';
          _isLoading = false;
          selectedGender = user!.user.gender;

          // Existing profile picture
          _existingProfileImageUrl = user!.user.image?.toString() ?? '';

          // Update text controllers
          _controller.contactNumberController.text = _contact;
          _controller.emailController.text = user.user.email;
          _controller.firstNameController.text = _firstname;
          _controller.middleNameController.text = _middlename ?? '';
          _controller.lastNameController.text = _lastname;
          _controller.roleController.text = _role;
          _controller.imageController.text = _image;
          _controller.birthdateController.text = _birthday;
          _controller.genderController.text = selectedGender ?? '';

          _controller.payPeriodController.text = _paySchedule;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching specializations: $error');
      debugPrintStack(stackTrace: stackTrace);
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
                        debugPrint('Creating New Tasker...');
                        try {
                          _controller.createTasker(
                            context,
                            selectedSpecialization ?? "Unknown Specialization",
                            selectedGender ?? "Unknown Gender",
                            _imageName ?? "Unknown Image",
                            _fileName ?? "Illegal File",
                            _selectedFile ?? File(""),
                            _selectedImage ?? File(""),
                          );
                        } catch (error) {
                          debugPrint('Registration error: $error');
                          debugPrintStack();
                        }
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
              // TextButton(
              //     onPressed: () {
              //       Navigator.push(context,
              //           MaterialPageRoute(builder: (context) {
              //         return SignIn();
              //       }));
              //     },
              //     child: Text(
              //       textAlign: TextAlign.right,
              //       'Already have an account',
              //       style: TextStyle(
              //           color: Colors.black, fontWeight: FontWeight.bold),
              //     )),
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
                // Specialization
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
            key:
                _certsFormKey, // Form key for validation (optional if enforcing file selection)
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text("Pick PDF"),
                ),
                _selectedFile != null
                    ? Column(
                        children: [
                          Text("Selected File: $_fileName"),
                        ],
                      )
                    : const Text("No File Selected"),
              ],
            ),
          ),
        ),
      ];
}
