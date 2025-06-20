// import 'dart:io';
// import 'package:flutter_fe/controller/profile_controller.dart';
// import 'package:flutter_fe/model/auth_user.dart';
// import 'package:flutter_fe/service/client_service.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class FillUpClient extends StatefulWidget {
  const FillUpClient({super.key});

  @override
  State<FillUpClient> createState() => _FillUpClientState();
}

class _FillUpClientState extends State<FillUpClient> {
  int currentStep = 0;
  final GetStorage storage = GetStorage();
  String? selectedGender;
  // bool _isLoading = true;

  // final ProfileController _controller = ProfileController();
  // final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // final ClientServices _clientServices = ClientServices();

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final ImagePicker _picker = ImagePicker();

  // Future<void> _pickImageProfile() async {
  //   final XFile? pickedFile = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 80,
  //   );
  //   if (pickedFile != null) {
  //     setState(() {
  //       _selectedImage = File(pickedFile.path);
  //       _imageName = pickedFile.name;
  //     });
  //   }
  // }
  //
  // Future<void> _pickImageID() async {
  //   final XFile? pickedFile = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 80,
  //   );
  //   if (pickedFile != null) {
  //     setState(() {
  //       _selectedImageID = File(pickedFile.path);
  //       _imageNameID = pickedFile.name;
  //       _IDChanged = true;
  //     });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    // _fetchUserData();
  }

  // Future<void> _fetchUserData() async {
  //   try {
  //     int userId = int.parse(storage.read('user_id').toString());
  //     AuthenticatedUser? user =
  //         await _controller.getAuthenticatedUser(userId);
  //     if (user == null) throw Exception("User not found");
  //
  //     setState(() {
  //       _existingProfileImageUrl = user.user.image?.toString();
  //       _controller.firstNameController.text = user.user.firstName;
  //       _controller.lastNameController.text = user.user.lastName;
  //       _controller.middleNameController.text = user.user.middleName ?? '';
  //       _controller.emailController.text = user.user.email;
  //       _controller.contactNumberController.text = user.user.contact ?? '';
  //       _controller.birthdateController.text = user.user.birthdate ?? '';
  //       _controller.roleController.text = user.user.role;
  //       selectedGender =
  //           genderOptions.contains(user.user.gender) ? user.user.gender : null;
  //       _controller.genderController.text = selectedGender ?? '';
  //       _isLoading = false;
  //     });
  //     await _fetchUserIDImage(userId);
  //   } catch (e) {
  //     debugPrint("Error fetching user data: $e");
  //     setState(() => _isLoading = false);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text('Error loading user data: $e'),
  //           backgroundColor: Colors.red),
  //     );
  //   }
  // }

  // Future<void> _fetchUserIDImage(int userId) async {
  //   try {
  //     final response = await _clientServices.fetchUserIDImage(userId);
  //     if (response['success']) {
  //       setState(() {
  //         _existingIDImageUrl = response['url'];
  //         _documentValid = response['status'];
  //         _IDChanged = false;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching ID image: $e");
  //   }
  // }

  // Future<void> _saveUserWithImages() async {
  //   // Ensure both profile and ID images are provided
  //   debugPrint('Profile Image: $_selectedImage');
  //   if ((_selectedImage == null && _existingProfileImageUrl == null) ||
  //       (_selectedImageID == null && _existingIDImageUrl == null)) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text('Please provide both profile and ID images'),
  //           backgroundColor: Colors.orange),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     int userId = int.parse(storage.read('user_id').toString());
  //     if (_selectedImage != null && _selectedImageID != null) {
  //       await _controller.updateUserWithBothImages(
  //           context, userId, _selectedImage!, _selectedImageID!);
  //     } else if (_selectedImage != null) {
  //       await _controller.updateUserWithImage(context, userId, _selectedImage!);
  //     } else if (_selectedImageID != null) {
  //       await _controller.updateUserWithID(context, userId, _selectedImageID!);
  //     } else {
  //       await _controller.updateUserData(context, userId);
  //     }
  //     Navigator.pop(context, true);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text('Error saving data: $e'),
  //           backgroundColor: Colors.red),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(title: const Text('Fill Up Client')),
    //   body: _isLoading
    //       ? const Center(child: CircularProgressIndicator())
    //       : Theme(
    //           data: Theme.of(context).copyWith(
    //               colorScheme: ColorScheme.light(primary: Color(0xFF0272B1))),
    //           child: Stepper(
    //             type: StepperType.horizontal,
    //             currentStep: currentStep >= getSteps().length ? 0 : currentStep,
    //             onStepTapped: (step) => setState(() => currentStep = step),
    //             onStepContinue: () {
    //               if (currentStep == 0) {
    //                 if (_formKey.currentState!.validate()) {
    //                   setState(() => currentStep += 1);
    //                 } else {
    //                   ScaffoldMessenger.of(context).showSnackBar(
    //                     SnackBar(
    //                         content:
    //                             Text('Please complete all required fields')),
    //                   );
    //                 }
    //               } else if (currentStep == 1) {
    //                 if (_selectedImage != null ||
    //                     _existingProfileImageUrl != null) {
    //                   setState(() => currentStep += 1);
    //                 } else {
    //                   ScaffoldMessenger.of(context).showSnackBar(
    //                     SnackBar(
    //                         content: Text('Please select a profile picture')),
    //                   );
    //                 }
    //               } else if (currentStep >= getSteps().length - 1) {
    //                 if (_selectedImageID != null ||
    //                     _existingIDImageUrl != null) {
    //                   _saveUserWithImages();
    //                 } else {
    //                   setState(() => currentStep += 1);
    //                   ScaffoldMessenger.of(context).showSnackBar(
    //                     SnackBar(content: Text('Please upload an ID image')),
    //                   );
    //                 }
    //               }
    //             },
    //             onStepCancel: currentStep == 0
    //                 ? null
    //                 : () => setState(() => currentStep -= 1),
    //             steps: getSteps(),
    //             controlsBuilder: (context, details) {
    //               final isLastStep = currentStep == getSteps().length - 1;
    //               return Row(
    //                 mainAxisAlignment: MainAxisAlignment.end,
    //                 children: [
    //                   if (currentStep != 0)
    //                     ElevatedButton(
    //                       onPressed: details.onStepCancel,
    //                       child: Text("Back"),
    //                     ),
    //                   SizedBox(width: 10),
    //                   ElevatedButton(
    //                     onPressed: details.onStepContinue,
    //                     child: Text(isLastStep ? "Save Changes" : "Continue"),
    //                   ),
    //                 ],
    //               );
    //             },
    //           ),
    //         ),
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text("This page is not available")
      ),
      body: Placeholder(),
    );
  }

  // List<Step> getSteps() => [
  //       Step(
  //         state: currentStep > 0 ? StepState.complete : StepState.indexed,
  //         isActive: currentStep >= 0,
  //         title: Text(''),
  //         content: Form(
  //           key: _formKey,
  //           child: Column(
  //             children: [
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 20),
  //                 child: Text(
  //                   'Fill up the form to continue',
  //                   style: GoogleFonts.openSans(
  //                       fontSize: 20, color: Color(0xFF0272B1)),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: Column(
  //                   children: [
  //                     Padding(
  //                       padding: const EdgeInsets.only(bottom: 20),
  //                       child: Text(
  //                         'Choose a profile picture',
  //                         style: GoogleFonts.openSans(
  //                             fontSize: 20, color: Color(0xFF0272B1)),
  //                       ),
  //                     ),
  //                     Container(
  //                       width: double.infinity,
  //                       padding: EdgeInsets.all(16),
  //                       decoration: BoxDecoration(
  //                         color: Colors.grey[100],
  //                         borderRadius: BorderRadius.circular(12),
  //                         boxShadow: [
  //                           BoxShadow(
  //                               color: Colors.black.withOpacity(0.1),
  //                               blurRadius: 8,
  //                               offset: Offset(0, 2)),
  //                         ],
  //                       ),
  //                       child: Column(
  //                         children: [
  //                           Container(
  //                             width: 200,
  //                             height: 200,
  //                             decoration: BoxDecoration(
  //                               color: Colors.grey[300],
  //                               borderRadius: BorderRadius.circular(100),
  //                               border: Border.all(
  //                                   color: Color(0xFF0272B1), width: 3),
  //                               boxShadow: [
  //                                 BoxShadow(
  //                                     color: Colors.black.withOpacity(0.2),
  //                                     blurRadius: 10,
  //                                     offset: Offset(0, 4)),
  //                               ],
  //                             ),
  //                             child: ClipRRect(
  //                               borderRadius: BorderRadius.circular(100),
  //                               child: _selectedImage != null
  //                                   ? Image.file(_selectedImage!,
  //                                       fit: BoxFit.cover)
  //                                   : _existingProfileImageUrl != null &&
  //                                           _existingProfileImageUrl!.isNotEmpty
  //                                       ? Image.network(
  //                                           _existingProfileImageUrl!,
  //                                           fit: BoxFit.cover)
  //                                       : Center(
  //                                           child: Icon(Icons.person,
  //                                               size: 80,
  //                                               color: Colors.grey[600])),
  //                             ),
  //                           ),
  //                           SizedBox(height: 20),
  //                           ElevatedButton.icon(
  //                             onPressed: _pickImageProfile,
  //                             icon: Icon(Icons.edit, color: Colors.white),
  //                             label: Text("Change Profile"),
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: Color(0xFF0272B1),
  //                               foregroundColor: Colors.white,
  //                               padding: EdgeInsets.symmetric(
  //                                   horizontal: 20, vertical: 12),
  //                               shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(8)),
  //                             ),
  //                           ),
  //                           if (_imageName != null)
  //                             Padding(
  //                               padding: const EdgeInsets.only(top: 8),
  //                               child: Text("Name: $_imageName",
  //                                   style: TextStyle(
  //                                       color: Colors.grey[600],
  //                                       fontStyle: FontStyle.italic)),
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.firstNameController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       _controller.validateName(value, "First Name"),
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Color(0xFFF1F4FF),
  //                     hintText: 'First Name',
  //                     hintStyle: TextStyle(color: Colors.grey),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderSide: BorderSide(color: Colors.transparent),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide:
  //                           BorderSide(color: Color(0xFF0272B1), width: 2),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.lastNameController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       _controller.validateName(value, "Last Name"),
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Color(0xFFF1F4FF),
  //                     hintText: 'Last Name',
  //                     hintStyle: TextStyle(color: Colors.grey),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderSide: BorderSide(color: Colors.transparent),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide:
  //                           BorderSide(color: Color(0xFF0272B1), width: 2),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.middleNameController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Color(0xFFF1F4FF),
  //                     hintText: 'Middle Name',
  //                     hintStyle: TextStyle(color: Colors.grey),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderSide: BorderSide(color: Colors.transparent),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide:
  //                           BorderSide(color: Color(0xFF0272B1), width: 2),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: DropdownButtonFormField<String>(
  //                   value: selectedGender,
  //                   validator: (value) => _controller.validateGender(value),
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Color(0xFFF1F4FF),
  //                     hintText: 'Select Gender',
  //                     hintStyle: TextStyle(color: Colors.grey),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderSide: BorderSide(color: Colors.transparent),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide:
  //                           BorderSide(color: Color(0xFF0272B1), width: 2),
  //                     ),
  //                   ),
  //                   items: genderOptions
  //                       .map((gender) => DropdownMenuItem(
  //                           value: gender, child: Text(gender)))
  //                       .toList(),
  //                   onChanged: (newValue) {
  //                     setState(() {
  //                       selectedGender = newValue;
  //                       _controller.genderController.text = newValue!;
  //                     });
  //                   },
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.emailController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) => _controller.validateEmail(value),
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Color(0xFFF1F4FF),
  //                     hintText: 'Email',
  //                     hintStyle: TextStyle(color: Colors.grey),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderSide: BorderSide(color: Colors.transparent),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide:
  //                           BorderSide(color: Color(0xFF0272B1), width: 2),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.contactNumberController,
  //                   cursorColor: Color(0xFF0272B1),
  //                   validator: (value) =>
  //                       _controller.validateContactNumber(value),
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Color(0xFFF1F4FF),
  //                     hintText: 'Contact Number',
  //                     hintStyle: TextStyle(color: Colors.grey),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderSide: BorderSide(color: Colors.transparent),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide:
  //                           BorderSide(color: Color(0xFF0272B1), width: 2),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 10),
  //                 child: TextFormField(
  //                   controller: _controller.birthdateController,
  //                   keyboardType: TextInputType.datetime,
  //                   readOnly: true,
  //                   onTap: () async {
  //                     DateTime? pickedDate = await showDatePicker(
  //                       context: context,
  //                       initialDate: DateTime.now(),
  //                       firstDate: DateTime(1900),
  //                       lastDate: DateTime(2100),
  //                     );
  //                     if (pickedDate != null) {
  //                       String formattedDate =
  //                           "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
  //                       setState(() => _controller.birthdateController.text =
  //                           formattedDate);
  //                     }
  //                   },
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Color(0xFFF1F4FF),
  //                     hintText: 'Birthdate (YYYY-MM-DD)',
  //                     hintStyle: TextStyle(color: Colors.grey),
  //                     suffixIcon:
  //                         Icon(Icons.calendar_today, color: Color(0xFF0272B1)),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderSide: BorderSide(color: Colors.transparent),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                       borderSide:
  //                           BorderSide(color: Color(0xFF0272B1), width: 2),
  //                     ),
  //                   ),
  //                   validator: (value) => value == null || value.isEmpty
  //                       ? 'Please select a birthdate'
  //                       : null,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //       Step(
  //         state: currentStep > 2 ? StepState.complete : StepState.indexed,
  //         isActive: currentStep >= 2,
  //         title: Text(''),
  //         content: Padding(
  //           padding: const EdgeInsets.only(bottom: 10),
  //           child: Column(
  //             children: [
  //               Padding(
  //                 padding: const EdgeInsets.only(bottom: 20),
  //                 child: Text(
  //                   'Upload your ID for verification',
  //                   style: GoogleFonts.montserrat(
  //                       fontSize: 15, color: Color(0xFF0272B1)),
  //                 ),
  //               ),
  //               Container(
  //                 width: double.infinity,
  //                 padding: EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[100],
  //                   borderRadius: BorderRadius.circular(12),
  //                   boxShadow: [
  //                     BoxShadow(
  //                         color: Colors.black.withOpacity(0.1),
  //                         blurRadius: 8,
  //                         offset: Offset(0, 2)),
  //                   ],
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     Container(
  //                       width: 300,
  //                       height: 180,
  //                       decoration: BoxDecoration(
  //                         color: Colors.grey[300],
  //                         borderRadius: BorderRadius.circular(12),
  //                         border:
  //                             Border.all(color: Color(0xFF0272B1), width: 2),
  //                         boxShadow: [
  //                           BoxShadow(
  //                               color: Colors.black.withOpacity(0.2),
  //                               blurRadius: 10,
  //                               offset: Offset(0, 4)),
  //                         ],
  //                       ),
  //                       child: ClipRRect(
  //                         borderRadius: BorderRadius.circular(12),
  //                         child: _selectedImageID != null
  //                             ? Image.file(_selectedImageID!, fit: BoxFit.cover)
  //                             : _existingIDImageUrl != null &&
  //                                     _existingIDImageUrl!.isNotEmpty
  //                                 ? Image.network(_existingIDImageUrl!,
  //                                     fit: BoxFit.cover)
  //                                 : Center(
  //                                     child: Icon(Icons.credit_card,
  //                                         size: 80, color: Colors.grey[600])),
  //                       ),
  //                     ),
  //                     SizedBox(height: 20),
  //                     Text(
  //                       _IDChanged
  //                           ? 'Wait for 10 minutes to validate your ID'
  //                           : _documentValid
  //                               ? 'Your ID has been validated'
  //                               : 'Your ID has not been validated',
  //                       style: TextStyle(
  //                         color: _IDChanged
  //                             ? Colors.red[600]
  //                             : _documentValid
  //                                 ? Colors.green[600]
  //                                 : Colors.red[600],
  //                         fontStyle: FontStyle.normal,
  //                       ),
  //                     ),
  //                     SizedBox(height: 10),
  //                     ElevatedButton.icon(
  //                       onPressed: _pickImageID,
  //                       icon: Icon(Icons.edit, color: Colors.white),
  //                       label: Text("Change ID",
  //                           style: GoogleFonts.montserrat(
  //                               fontSize: 15,
  //                               color: Colors.white,
  //                               fontWeight: FontWeight.bold)),
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Color(0xFF0272B1),
  //                         foregroundColor: Colors.white,
  //                         padding: EdgeInsets.symmetric(
  //                             horizontal: 20, vertical: 12),
  //                         shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(8)),
  //                       ),
  //                     ),
  //                     if (_imageNameID != null)
  //                       Padding(
  //                         padding: const EdgeInsets.only(top: 8),
  //                         child: Text("Selected: $_imageNameID",
  //                             style: TextStyle(
  //                                 color: Colors.grey[600],
  //                                 fontStyle: FontStyle.italic)),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ];
}
