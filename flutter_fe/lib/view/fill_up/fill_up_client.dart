import 'dart:io';
import 'package:flutter_fe/controller/authentication_controller.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/model/auth_user.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FillUpClient extends StatefulWidget {
  const FillUpClient({super.key});

  @override
  State<FillUpClient> createState() => _FillUpClientState();
}

class _FillUpClientState extends State<FillUpClient> {
  int currentStep = 0;
  final GetStorage storage = GetStorage();
  String _firstname = '';
  String _lastname = '';
  String? _middlename = '';
  String _contact = '';
  String _role = '';
  String _image = '';
  String _birthday = '';
  bool _isLoading = true;
  String? selectedGender;
  bool _imagesChanged = false;

  final ProfileController _controller = ProfileController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _selectedFile; // Store the selected file
  String? _fileName; // Store the selected file name
  File? _selectedImage; // Store the selected profile image
  String? _imageName; // Store the selected profile image name
  File? _selectedImageID; // Store the selected ID image
  String? _imageNameID; // Store the selected ID image name
  String? _existingProfileImageUrl; // Store existing profile image URL
  String? _existingIDImageUrl; // Store existing ID image URL

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile; // Store the picked image

  // Function to pick an image from gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _selectedImage = File(pickedFile.path);
        _imageName = pickedFile.name;
        _imagesChanged = true;
      });
    }
  }

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

  Future<void> _pickImageID() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Reduce image quality to save bandwidth
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImageID = File(pickedFile.path);
        _imageNameID = pickedFile.name;
        _imagesChanged = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      int userId = int.parse(storage.read('user_id').toString());

      AuthenticatedUser? user =
          await _controller.getAuthenticatedUser(context, userId);
      debugPrint("Fetched user data: ${user.toString()}");

      if (user == null) {
        throw Exception("User not found");
      }

      setState(() {
        _firstname = user.user.firstName;
        _lastname = user.user.lastName;
        _middlename = user.user.middleName;
        _role = user.user.role;
        _contact = user.user.contact ?? '';
        _image = user.user.image?.toString() ?? '';
        _birthday = user.user.birthdate ?? '';
        _isLoading = false;
        selectedGender = user.user.gender;
        // Existing profile picture
        _existingProfileImageUrl = user.user.image?.toString() ?? '';

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
      });

      // Fetch ID image if available
      await _fetchUserIDImage(userId);
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchUserIDImage(int userId) async {
    try {
      // This would be a call to get the ID image URL from your backend
      // For now, we'll simulate it
      final response = await http.get(
        Uri.parse("${ApiService.apiUrl}/getUserDocuments/$userId?type=id"),
        headers: {
          "Authorization": "Bearer ${await AuthService.getSessionToken()}",
          "Content-Type": "application/json"
        },
      );

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response Body from the fill up client: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null && data['user']['document_url'] != null) {
          setState(() {
            _existingIDImageUrl = data['user']['document_url'];
            debugPrint("Fetched ID image URL: $_existingIDImageUrl");
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching ID image: $e");
    }
  }

  Future<void> _saveUserWithImages() async {
    if (_selectedImage != null && _selectedImageID != null) {
      try {
        int userId = int.parse(storage.read('user_id').toString());
        await _controller.updateUserWithBothImages(
            context, userId, _selectedImage!, _selectedImageID!);

        // Reset the changed flag after successful upload
        setState(() {
          _imagesChanged = false;
        });

        // Refresh user data to get updated URLs
        await _fetchUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both profile and ID images'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = storage.read("user_id");
      if (userId == null) throw Exception("User ID not found");

      // Validate all fields before updating
      String? firstNameError = _controller.validateName(
          _controller.firstNameController.text, "first name");
      String? lastNameError = _controller.validateLastName(
          _controller.lastNameController.text, "last name");
      String? emailError =
          _controller.validateEmail(_controller.emailController.text);
      String? contactError = _controller
          .validateContactNumber(_controller.contactNumberController.text);
      String? genderError =
          _controller.validateGender(_controller.genderController.text);
      String? birthdateError =
          _controller.validateBirthdate(_controller.birthdateController.text);

      if (firstNameError != null ||
          lastNameError != null ||
          emailError != null ||
          contactError != null ||
          genderError != null ||
          birthdateError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(firstNameError ??
                lastNameError ??
                emailError ??
                contactError ??
                genderError ??
                birthdateError ??
                "Please fix the errors in the form"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update user data with profile and ID images
      if (_imagesChanged) {
        await _saveUserWithImages();
      } else {
        await _controller.updateUserData(context, userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh user data after update
      await _fetchUserData();
    } catch (e) {
      debugPrint("Error updating user data: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill Up Client'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF0272B1),
                ),
              ),
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: currentStep,
                onStepTapped: (step) => setState(() => currentStep = step),
                onStepContinue: () {
                  final isLastStep = currentStep == getSteps().length - 1;
                  if (isLastStep) {
                    // Handle form submission
                    _controller.updateUserData(
                        context, int.parse(storage.read('user_id').toString()));
                  } else {
                    setState(() => currentStep += 1);
                  }
                },
                onStepCancel: currentStep == 0
                    ? null
                    : () => setState(() => currentStep -= 1),
                steps: getSteps(),
              ),
            ),
    );
  }

  List<Step> getSteps() => [
        Step(
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: currentStep >= 0,
          title: Text(''),
          content: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Fill up the form to continue',
                    style: GoogleFonts.openSans(
                        fontSize: 20, color: Color(0xFF0272B1)),
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
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Color(0xFF0272B1), width: 2))),
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
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Color(0xFF0272B1), width: 2))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<String>(
                    value: selectedGender,
                    validator: (value) => _controller.validateGender(value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Select Gender',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    items: genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGender = newValue;
                        _controller.genderController.text = newValue ?? '';
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.middleNameController,
                    cursorColor: Color(0xFF0272B1),
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'Middle Name',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Color(0xFF0272B1), width: 2))),
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
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Color(0xFF0272B1), width: 2))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.contactNumberController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        _controller.validateContactNumber(value),
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'Contact Number',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Color(0xFF0272B1), width: 2))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controller.birthdateController,
                    keyboardType: TextInputType.datetime, // Opens date keyboard
                    readOnly: true, // Prevents manual input
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900), // Adjust as needed
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        // Format date as YYYY-MM-DD
                        String formattedDate =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        // Update the controller with the formatted date
                        setState(() {
                          _controller.birthdateController.text = formattedDate;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      // labelText: 'Task Begin Date',
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Birthdate (YYYY-MM-DD)',
                      hintStyle: TextStyle(color: Colors.grey),
                      suffixIcon: Icon(Icons.calendar_today,
                          color: Color(0xFF0272B1)), // Calendar icon
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.transparent, width: 0),
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
              ],
            ),
          ),
        ),
        Step(
            state: currentStep > 1 ? StepState.complete : StepState.indexed,
            isActive: currentStep >= 1,
            title: Text(''),
            content: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Choose a profile picture',
                    style: GoogleFonts.openSans(
                        fontSize: 20, color: Color(0xFF0272B1)),
                  ),
                ),
                // Profile Image Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Image Preview
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(100),
                          border:
                              Border.all(color: Color(0xFF0272B1), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : _existingProfileImageUrl != null &&
                                      _existingProfileImageUrl!.isNotEmpty
                                  ? Image.network(
                                      _existingProfileImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
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
                                        return Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 80,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Select Profile Image Button
                      ElevatedButton.icon(
                        onPressed: _pickImageProfile,
                        icon: Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                        label: Text("Change Profile"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0272B1),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
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
                        )
                    ],
                  ),
                ),
              ],
            )),
        Step(
            state: currentStep > 2 ? StepState.complete : StepState.indexed,
            isActive: currentStep >= 2,
            title: Text(''),
            content: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Upload your ID for verification',
                    style: GoogleFonts.openSans(
                        fontSize: 20, color: Color(0xFF0272B1)),
                  ),
                ),
                // ID Image Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ID Image Preview
                      Container(
                        width: 300,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Color(0xFF0272B1), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImageID != null
                              ? Image.file(
                                  _selectedImageID!,
                                  fit: BoxFit.cover,
                                )
                              : _existingIDImageUrl != null &&
                                      _existingIDImageUrl!.isNotEmpty
                                  ? Image.network(
                                      _existingIDImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
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
                                        return Center(
                                          child: Icon(
                                            Icons.credit_card,
                                            size: 80,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.credit_card,
                                        size: 80,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Select ID Image Button
                      ElevatedButton.icon(
                        onPressed: _pickImageID,
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text("Select ID Image"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0272B1),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_selectedImageID != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Selected: ${_imageNameID ?? 'id_image.jpg'}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      SizedBox(height: 30),

                      // Save Images Button
                      if (_imagesChanged ||
                          (_existingProfileImageUrl != null &&
                              _existingIDImageUrl != null))
                        ElevatedButton.icon(
                          onPressed: _saveUserWithImages,
                          icon: Icon(Icons.save),
                          label: Text("Save Images"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )),
      ];
}
