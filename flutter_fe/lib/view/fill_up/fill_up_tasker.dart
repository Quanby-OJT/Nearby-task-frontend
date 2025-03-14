import 'dart:io';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/service/job_post_service.dart';

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
  bool _isSuccess = false;
  File? _selectedFile; // Store the selected file
  String? _fileName; // Store the selected file name
  File? _selectedImage; // Store the selected image
  String? _imageName; // Store the selected image name
  String? selectedGender;
  List<String> genderOptions = ["Male", "Female", "Non-Binary", "I don't Want to Say"];
  List<String> specialization = [];
  String? selectedSpecialization;

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source:
          ImageSource.gallery, // Change to ImageSource.camera for camera input
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Store the selected image
        _imageName = pickedFile.name; // Store image name
      });
    }
  }

  @override
  void initState(){
    super.initState();
    fetchSpecialization();
  }

  Future<void> fetchSpecialization() async {
    try {
      List<SpecializationModel> fetchedSpecializations = await jobPostService.getSpecializations();
      debugPrint(fetchedSpecializations.toString());
      setState(() {
        specialization = fetchedSpecializations.map((spec) => spec.specialization).toList();
      });
    } catch (error) {
      print('Error fetching specializations: $error');
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
                          _controller.createTasker(context);
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
        Step(
            state: currentStep > 0 ? StepState.complete : StepState.indexed,
            isActive: currentStep >= 0,
            title: Text('General'),
            content: Column(
              children: [
                //Wage
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.firstNameController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        value!.isEmpty ? "Please Indicate Your Desired Wage" : null,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'How Much Would You Want to be Paid?',
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
                //Duration
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: _controller.lastNameController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        value!.isEmpty ? "Last name is required" : null,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'How do you want to be Paid?',
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
                //Gender
                Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Select Your Gender...',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent)),
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
                  ),
                ),
                //Contact Number
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        value!.isEmpty ? "Please indicate your contact number" : null,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'Contact number',
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
                //Tasker Address
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        value!.isEmpty ? "Address is required" : null,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'Indicate Your Address',
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
                //Birthdate
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controller.emailController,
                    keyboardType: TextInputType.datetime, // Opens date keyboard
                    readOnly: true, // Prevents manual input
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000), // Adjust as needed
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        // Format date as YYYY-MM-DD
                        String formattedDate =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        //   controller.jobTaskBeginDateController.text = formattedDate;
                      }
                    },
                    decoration: InputDecoration(
                      // labelText: 'Task Begin Date',
                      labelStyle: TextStyle(color: Color(0xFF0272B1)),
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Birth date',
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
            )),
        Step(
            state: currentStep > 1 ? StepState.complete : StepState.indexed,
            isActive: currentStep >= 1,
            title: Text('Profile'),
            content: Column(
              children: [
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: CircleAvatar(
                      backgroundImage: FileImage(_selectedImage!),
                      radius: 70,
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _pickImage,
                  child: Text("Select profile"),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: TextFormField(
                    maxLines: 2,
                    controller: _controller.emailController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) => value!.isEmpty ? "Indicate Your desired description." : null,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'How do you describe yourself as a Worker?',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.transparent, width: 0),
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Color(0xFF0272B1), width: 2)
                        )
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    maxLines: 3,
                    controller: _controller.passwordController,
                    cursorColor: Color(0xFF0272B1),
                    validator: (value) =>
                        value!.isEmpty ? "List of skills..." : null,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF1F4FF),
                        hintText: 'Enumerate what Skills Do you possessed at this moment.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: DropdownButtonFormField<String>(
                    value: selectedSpecialization,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F4FF),
                      hintText: 'Select Tasker Specialization *',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF0272B1), width: 2),
                      ),
                    ),
                    items: specialization.map((String spec) {
                      return DropdownMenuItem<String>(
                        value: spec,
                        child: Text(
                          spec,
                          overflow: TextOverflow.ellipsis, // Ensures text does not overflow
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedSpecialization = newValue;
                      });
                    },
                  ),
                ),

                // Show Selected Image Start (if any)
              ],
            )),
        Step(
            isActive: currentStep >= 2,
            title: Text('Certs'),
            content: Column(
              children: [

                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text("Pick PDF"),
                ),
                // File Picker Button End

                // Show Selected File Start (if any)
                _selectedFile != null
                    ? Column(
                        children: [
                          Text("Selected File: $_fileName"),
                        ],
                      )
                    : Text("No File Selected"),
              ],
            )),
      ];
}
